extends CharacterBody3D

# --- Nodes ---
@onready var headset: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_hand: XRController3D = $XROrigin3D/LeftController
@onready var right_hand: XRController3D = $XROrigin3D/RightController
@onready var left_hand_grab_cast: ShapeCast3D = $XROrigin3D/LeftController/GrabRegionL
@onready var right_hand_grab_cast: ShapeCast3D = $XROrigin3D/RightController/GrabRegionR
@onready var left_L1: ShapeCast3D = $XROrigin3D/LeftController/GrabRegionL/Can_GrabRegion_L1
@onready var left_L2: ShapeCast3D = $XROrigin3D/LeftController/GrabRegionL/Can_GrabRegion_L2
@onready var right_L1: ShapeCast3D = $XROrigin3D/RightController/GrabRegionR/Can_GrabRegion_R1
@onready var right_L2: ShapeCast3D = $XROrigin3D/RightController/GrabRegionR/Can_GrabRegion_R2
@onready var skeleton: Skeleton3D = $"XROrigin3D/Female Test/Armature/Skeleton3D"
@onready var Body_Origin: Node3D = $"XROrigin3D/Female Test"
# --- Movement ---
@export var speed: float = 10.0
@export var acceleration: float = 1.0
var input_vector: Vector2 = Vector2.ZERO
@export var gravity: float = 9.8
@export var air_control: float = 0
@export var head_bone_name: String = "Head"

# --- Climbing ---
var left_grabbing := false
var right_grabbing := false
var left_prev_pos: Vector3
var right_prev_pos: Vector3
@export var can_climb: bool = true
@export var climb_strength: float = 1.0
var grip_effect: float = 0.0
@export var grip_sliderate: float = 10

var left_grip: float = 0.0
var right_grip: float = 0.0

# Both-hand climbing
var both_hands_grabbing: bool = false
var virtual_hand_start: Vector3 = Vector3.ZERO
var virtual_hand_prev: Vector3 = Vector3.ZERO
var virtual_hand_initialized: bool = false

# --- Head Bobbing ---
@export var head_bob_enabled: bool = true
@export var bob_amount: float = 0.01
@export var bob_speed: float = 5.0
var bob_time: float = 0.0
var base_head_y: float = 0.0
var head_offset: Vector3 = Vector3.ZERO

# --- Desktop XR Emulation ---
@export var desktop_debug := false
var mouse_delta := Vector2.ZERO
var left_hand_speed := 2.0
var right_hand_speed := 2.0
var headset_speed := 2.0
var rotation_speed := 0.002

func _ready():
	var xr := XRServer.get_primary_interface()
	if xr == null or not xr.is_initialized():
		desktop_debug = true
		Desktop_Mode()

func Desktop_Mode():
	set_process(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if desktop_debug and event is InputEventMouseMotion:
		mouse_delta = event.relative

# --- Grab Check ---
func Can_Grab(hand_cast: ShapeCast3D, L1: ShapeCast3D, L2: ShapeCast3D) -> bool:
	if not hand_cast or not hand_cast.is_colliding():
		return false
	if (L1 and L1.is_colliding()) or (L2 and L2.is_colliding()):
		return false
	return true

# --- Grab Functions (analog grip) ---
func _on_left_controller_input_float_changed(name: String, value: float) -> void:
	if name == "grip":
		left_grip = value
		if value > 0.0 and not left_grabbing:
			if Can_Grab(left_hand_grab_cast, left_L1, left_L2):
				left_grabbing = true
				left_prev_pos = left_hand.global_transform.origin
		elif value <= 0.0:
			left_grabbing = false

func _on_right_controller_input_float_changed(name: String, value: float) -> void:
	if name == "grip":
		right_grip = value
		if value > 0.0 and not right_grabbing:
			if Can_Grab(right_hand_grab_cast, right_L1, right_L2):
				right_grabbing = true
				right_prev_pos = right_hand.global_transform.origin
		elif value <= 0.0:
			right_grabbing = false

# --- Movement Input ---
func _on_left_controller_input_vector_2_changed(name: String, value: Vector2) -> void:
	input_vector = value

# --- Physics ---
func _physics_process(delta: float) -> void:
	# Track transition out of two-hand grab
	var was_both := both_hands_grabbing
	both_hands_grabbing = left_grabbing and right_grabbing

	if was_both and not both_hands_grabbing:
		if left_grabbing:
			left_prev_pos = left_hand.global_transform.origin
		if right_grabbing:
			right_prev_pos = right_hand.global_transform.origin
		virtual_hand_initialized = false

	if both_hands_grabbing and not virtual_hand_initialized:
		virtual_hand_start = (left_prev_pos + right_prev_pos) * 0.5
		virtual_hand_prev = virtual_hand_start
		virtual_hand_initialized = true

	# --- Climbing Logic ---
	if can_climb and (left_grabbing or right_grabbing):
		var climb_force := Vector3.ZERO

		if both_hands_grabbing:
			var current_midpoint = (left_hand.global_transform.origin + right_hand.global_transform.origin) * 0.5
			climb_force = virtual_hand_prev - current_midpoint
			virtual_hand_prev = current_midpoint
		else:
			if left_grabbing:
				climb_force += left_prev_pos - left_hand.global_transform.origin
				left_prev_pos = left_hand.global_transform.origin
			if right_grabbing:
				climb_force += right_prev_pos - right_hand.global_transform.origin
				right_prev_pos = right_hand.global_transform.origin

		velocity += (climb_force / delta) * climb_strength

	if not both_hands_grabbing:
		virtual_hand_initialized = false

	# --- Normal Movement ---
	var basis: Basis = headset.global_transform.basis
	var forward: Vector3 = -basis.z
	forward.y = 0
	forward = forward.normalized()
	var right: Vector3 = basis.x
	right.y = 0
	right = right.normalized()

	var move_x = input_vector.x * 0.5
	var move_y = input_vector.y
	if move_y < 0:
		move_y *= 0.5
	var target: Vector3 = (right * move_x + forward * move_y) * speed

	if is_on_floor():
		velocity.x = lerp(velocity.x, target.x, acceleration * delta)
		velocity.z = lerp(velocity.z, target.z, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, target.x, acceleration * air_control * delta)
		velocity.z = lerp(velocity.z, target.z, acceleration * air_control * delta)

	# --- Grab Sliding (smooth) ---
	if left_grabbing or right_grabbing:
		var target_grip = max(left_grip, right_grip)
		grip_effect = lerp(grip_effect, target_grip, 0.1)
		velocity.y -= gravity * (1.0 - grip_effect) * grip_sliderate * delta
	else:
		grip_effect = lerp(grip_effect, 0.0, 0.1)
		velocity.y -= gravity * delta

	move_and_slide()

func _process(delta):
# --- Desktop Input (non-VR) (DELETE for VR TESTING) ---
	if not desktop_debug:
		return

	# --- Mouse look ---
	rotate_y(-mouse_delta.x * rotation_speed)
	headset.rotate_x(-mouse_delta.y * rotation_speed)
	mouse_delta = Vector2.ZERO

	# --- WASD movement ---
	var move_vec := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		move_vec.y += 1
	if Input.is_key_pressed(KEY_S):
		move_vec.y -= 1
	if Input.is_key_pressed(KEY_D):
		move_vec.x += 1
	if Input.is_key_pressed(KEY_A):
		move_vec.x -= 1
	_on_left_controller_input_vector_2_changed("joystick", move_vec)

	# --- Grip simulation ---
	_on_left_controller_input_float_changed("grip", 1.0 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 0.0)
	_on_right_controller_input_float_changed("grip", 1.0 if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else 0.0)

	# --- Left hand movement (T/F/G/H/R/Y) ---
	var left_delta := Vector3.ZERO
	if Input.is_key_pressed(KEY_T):
		left_delta.z -= left_hand_speed * delta
	if Input.is_key_pressed(KEY_G):
		left_delta.z += left_hand_speed * delta
	if Input.is_key_pressed(KEY_F):
		left_delta.x -= left_hand_speed * delta
	if Input.is_key_pressed(KEY_H):
		left_delta.x += left_hand_speed * delta
	if Input.is_key_pressed(KEY_R):
		left_delta.y += left_hand_speed * delta
	if Input.is_key_pressed(KEY_Y):
		left_delta.y -= left_hand_speed * delta
	left_hand.translate(left_delta)

	# --- Right hand movement (I/J/K/L/U/O) ---
	var right_delta := Vector3.ZERO
	if Input.is_key_pressed(KEY_I):
		right_delta.z -= right_hand_speed * delta
	if Input.is_key_pressed(KEY_K):
		right_delta.z += right_hand_speed * delta
	if Input.is_key_pressed(KEY_J):
		right_delta.x -= right_hand_speed * delta
	if Input.is_key_pressed(KEY_L):
		right_delta.x += right_hand_speed * delta
	if Input.is_key_pressed(KEY_O):
		right_delta.y += right_hand_speed * delta
	if Input.is_key_pressed(KEY_U):
		right_delta.y -= right_hand_speed * delta
	right_hand.translate(right_delta)

	# --- Headset movement ---
	var headset_delta := Vector3.ZERO
	if Input.is_key_pressed(KEY_UP):
		headset_delta.z -= headset_speed * delta
	if Input.is_key_pressed(KEY_DOWN):
		headset_delta.z += headset_speed * delta
	if Input.is_key_pressed(KEY_LEFT):
		headset_delta.x -= headset_speed * delta
	if Input.is_key_pressed(KEY_RIGHT):
		headset_delta.x += headset_speed * delta
	if Input.is_key_pressed(KEY_N):
		headset_delta.y += headset_speed * delta
	if Input.is_key_pressed(KEY_M):
		headset_delta.y -= headset_speed * delta
	headset.translate(headset_delta)
	# --- (DELETE for VR TESTING) --- 


# Full Body Position
	var hmd_pos: Vector3 = headset.global_transform.origin
	var transform: Transform3D = $"XROrigin3D/Female Test/Armature".global_transform

	transform.origin.x = hmd_pos.x
	transform.origin.z = hmd_pos.z

	$"XROrigin3D/Female Test/Armature".global_transform = transform

# Spine rotation from hand positions (XZ → Yaw)
	var spine_id := skeleton.find_bone("Spine")
	if spine_id != -1:
		var left_pos := left_hand.global_transform.origin
		var right_pos := right_hand.global_transform.origin
		var body_pos := Body_Origin.global_transform.origin
		# Hand direction (XZ)
		var hand_dir := right_pos - left_pos
		hand_dir.y = 0.0
		if hand_dir.length() < 0.001:
			return
		hand_dir = hand_dir.normalized()

		# Body forward (from headset)
		var body_forward := -headset.global_transform.basis.z
		body_forward.y = 0.0
		body_forward = body_forward.normalized()

		# Signed angle around Y
		var yaw := body_forward.signed_angle_to(hand_dir, Vector3.UP) + PI * 0.5

		# Apply to spine
		var spine_pose := skeleton.get_bone_global_pose(spine_id)
		spine_pose.basis = Basis(Vector3.UP, yaw)
		skeleton.set_bone_global_pose_override(
			spine_id,
			spine_pose,
			1.0,
			true)
