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

# --- Movement ---
@export var speed: float = 25.0
@export var acceleration: float = 1.0
var input_vector: Vector2 = Vector2.ZERO
@export var gravity: float = 9.8
@export var air_control: float = 0

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

# --- Desktop XR Emulation ---
@export var desktop_debug := false

func enable_desktop_xr_emulation():
	# Move headset with mouse
	set_process(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ready():
	var xr := XRServer.get_primary_interface()
	if xr == null or not xr.is_initialized():
		desktop_debug = true
		enable_desktop_xr_emulation()  # This drives headset & controller nodes and emits input signals


# --- Grab Check ---
func can_grab(hand_cast: ShapeCast3D, L1: ShapeCast3D, L2: ShapeCast3D) -> bool:
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
			# Only check collision when starting grab
			if can_grab(left_hand_grab_cast, left_L1, left_L2):
				left_grabbing = true
				left_prev_pos = left_hand.global_transform.origin
		elif value <= 0.0:
			left_grabbing = false

func _on_right_controller_input_float_changed(name: String, value: float) -> void:
	if name == "grip":
		right_grip = value
		if value > 0.0 and not right_grabbing:
			# Only check collision when starting grab
			if can_grab(right_hand_grab_cast, right_L1, right_L2):
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

	# Leaving two-hand grab → reset remaining hand
	if was_both and not both_hands_grabbing:
		if left_grabbing:
			left_prev_pos = left_hand.global_transform.origin
		if right_grabbing:
			right_prev_pos = right_hand.global_transform.origin
		virtual_hand_initialized = false

	# Initialize virtual hand if both hands start grabbing
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

	# Reset virtual hand when not both grabbing
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
