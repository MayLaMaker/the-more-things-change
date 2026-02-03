extends Node3D

var left_grip: float = 0.0
var right_grip: float = 0.0
var left_grabbing : bool = false
var right_grabbing : bool = false
var left_grabbed: RigidBody3D = null
var right_grabbed: RigidBody3D = null

var mouse_delta: Vector2 = Vector2.ZERO

@export var rotation_speed := 20
@export var headset_speed := 3 
@export var hand_speed := 3
@export var desktop_debug := true

@export var hand_force := 300.0
@export var hand_torque := 6.0

@export var height_min := 0.5
@export var height_max := 2

@onready var skeleton: Skeleton3D = $CharacterBody/CollisionShape3D/SherryGodotModel/Pose/Armature/Skeleton3D

@onready var headset: XRCamera3D = $CharacterBody/XROrigin3D/XRCamera3D
@onready var collision_shape_node: CollisionShape3D = $CharacterBody/CollisionShape3D
@onready var capsule_shape: CapsuleShape3D = collision_shape_node.shape as CapsuleShape3D

@onready var left_joint: Generic6DOFJoint3D = $"LeftHandPhysics/6DOFLeft"
@onready var right_joint: Generic6DOFJoint3D = $"RightHandPhysics/6DOFRight"
@onready var body: RigidBody3D = $CharacterBody
@onready var left_hand := HandPhysics.new(
	$LeftHandPhysics,
	$CharacterBody/XROrigin3D/LeftController/FullBodyHandPosition_L
)
@onready var right_hand := HandPhysics.new(
	$RightHandPhysics,
	$CharacterBody/XROrigin3D/RightController/FullBodyHandPosition_R
)

func Can_Grab(hand_cast: ShapeCast3D, L1: ShapeCast3D, L2: ShapeCast3D) -> bool:
	if not hand_cast or not hand_cast.is_colliding():
		return false
	if (L1 and L1.is_colliding()) or (L2 and L2.is_colliding()):
		return false
	return true

func _physics_process(delta: float) -> void:
	var total_force := left_hand.update(hand_force, hand_torque)
	total_force += right_hand.update(hand_force, hand_torque)
	body.apply_central_force(-total_force)

	# Update grabs
	_check_left_grab()
	_check_right_grab()

	if left_grip > 0.0 and left_grabbed:
		left_joint.node_a = $LeftHandPhysics.get_path()
		left_joint.node_b = left_grabbed.get_path()
	else:
		left_joint.node_a = NodePath()
		left_joint.node_b = NodePath()

	if right_grip > 0.0 and right_grabbed:
		right_joint.node_a = $RightHandPhysics.get_path()
		right_joint.node_b = right_grabbed.get_path()
	else:
		right_joint.node_a = NodePath()
		right_joint.node_b = NodePath()

	if headset == null or collision_shape_node.shape == null:
		return

	var capsule_shape := collision_shape_node.shape as CapsuleShape3D

	# Adjust capsule height using new names
	var hmd_y := headset.transform.origin.y
	capsule_shape.height = clamp(hmd_y, height_min, height_max)

	# Move collision shape to follow HMD
	var new_pos := Vector3(headset.transform.origin.x, capsule_shape.height / 2.0, headset.transform.origin.z)
	collision_shape_node.position = new_pos
	
class HandPhysics:
	var rb: RigidBody3D
	var target: Node3D

	func _init(r: RigidBody3D, t: Node3D):
		rb = r
		target = t

	func update(force_coef: float, torque_coef: float) -> Vector3:
		var delta := target.global_position - rb.global_position
		var force := delta * force_coef
		rb.apply_central_force(force)

		var qd := target.global_transform.basis.get_rotation_quaternion() \
			* rb.global_transform.basis.get_rotation_quaternion().inverse()
		rb.apply_torque(Vector3(qd.x, qd.y, qd.z) * qd.w * torque_coef)

		return force

func _on_left_controller_input_float_changed(name: String, value: float) -> void:
	if name == "grip":
		left_grip = value
		if value > 0.0 and not left_grabbing:
			if Can_Grab:
				left_grabbing = true
		elif value <= 0.0:
			left_grabbing = false
	
func _on_right_controller_input_float_changed(name: String, value: float) -> void:
	if name == "grip":
		right_grip = value
		if value > 0.0 and not right_grabbing:
			if Can_Grab:
				right_grabbing = true
		elif value <= 0.0:
			right_grabbing = false

func _on_left_controller_input_vector_2_changed(name: String, value: Vector2) -> void:
	pass # Replace with function body.

func _check_left_grab() -> void:
	if left_grip <= 0.0:
		left_grabbed = null
		return

	if $LeftHandPhysics/GrabRegionL.is_colliding():
		var collider = $LeftHandPhysics/GrabRegionL.get_collider(0)
		if collider is RigidBody3D and collider != left_hand.rb and collider != right_hand.rb:
			left_grabbed = collider
			print("Left grabbed:", left_grabbed.name)

func _check_right_grab() -> void:
	if right_grip <= 0.0:
		right_grabbed = null
		return

	if $RightHandPhysics/GrabRegionR.is_colliding():
		var collider = $RightHandPhysics/GrabRegionR.get_collider(0)
		if collider is RigidBody3D and collider != left_hand.rb and collider != right_hand.rb:
			right_grabbed = collider
			print("Right grabbed:", right_grabbed.name)

func _process(delta: float) -> void:
	# --- Spine rotation from hand positions (XZ → Yaw) ---
	var spine_id := skeleton.find_bone("Spine")
	if spine_id == -1:
		return

	var left_pos := left_hand.target.global_transform.origin
	var right_pos := right_hand.target.global_transform.origin

	# Hand direction (XZ only)
	var hand_dir := right_pos - left_pos
	hand_dir.y = 0.0
	if hand_dir.length() < 0.001:
		return
	hand_dir = hand_dir.normalized()

	# Body forward (from headset)
	var body_forward := skeleton.global_transform.basis.z
	body_forward.y = 0.0
	body_forward = body_forward.normalized()

	# Signed yaw angle
	var yaw := body_forward.signed_angle_to(hand_dir, Vector3.UP) + PI * 0.5

	# Apply to spine
	var spine_pose := skeleton.get_bone_global_pose(spine_id)
	spine_pose.basis = Basis(Vector3.UP, yaw)

	skeleton.set_bone_global_pose_override(
		spine_id,
		spine_pose,
		1.0,
		true
	)
	
	# --- Head rotation (HMD) ---
	var head_id = skeleton.find_bone("Head")
	if head_id != -1:
		var hmd_pose = skeleton.get_bone_global_pose(head_id)
		hmd_pose.basis = Basis(Vector3.UP, PI) * headset.global_transform.basis  # FIX: rotate 180 degrees
		var correction = Basis(Vector3.UP, PI)  # model 180° offset
		hmd_pose.basis = headset.global_transform.basis * correction
		skeleton.set_bone_global_pose_override(head_id, hmd_pose, 1.0, true)
		
	# --- Desktop Debug ---
	if not desktop_debug:
		return
	# --- Mouse look (HMD rotation) --- (Doesn't work, likely due to Spec. Cam)
	rotate_y(-mouse_delta.x * rotation_speed)
	headset.rotate_x(-mouse_delta.y * rotation_speed)
	mouse_delta = Vector2.ZERO

	# --- Fake joystick input ---
	var move_vec := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): move_vec.y += 1.0
	if Input.is_key_pressed(KEY_S): move_vec.y -= 1.0
	if Input.is_key_pressed(KEY_D): move_vec.x += 1.0
	if Input.is_key_pressed(KEY_A): move_vec.x -= 1.0

	_on_left_controller_input_vector_2_changed("joystick", move_vec.normalized())

	# --- Fake grip input ---
	_on_left_controller_input_float_changed(
		"grip",
		1.0 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 0.0
	)
	_on_right_controller_input_float_changed(
		"grip",
		1.0 if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else 0.0
	)
	# --- Headset ---
	var headset_delta := Vector3.ZERO
	if Input.is_key_pressed(KEY_UP): headset_delta.z -= headset_speed * delta
	if Input.is_key_pressed(KEY_DOWN): headset_delta.z += headset_speed * delta
	if Input.is_key_pressed(KEY_LEFT): headset_delta.x -= headset_speed * delta
	if Input.is_key_pressed(KEY_RIGHT): headset_delta.x += headset_speed * delta
	if Input.is_key_pressed(KEY_N): headset_delta.y += headset_speed * delta
	if Input.is_key_pressed(KEY_M): headset_delta.y -= headset_speed * delta
	headset.translate(headset_delta)
	
	# --- Left hand --- (Keys Will break later, change keys if so) 
	var left_delta := Vector3.ZERO
	if Input.is_key_pressed(KEY_H): left_delta.z -= hand_speed * delta  # forward (-Z)
	if Input.is_key_pressed(KEY_F): left_delta.z += hand_speed * delta  # backward (+Z)
	if Input.is_key_pressed(KEY_Y): left_delta.x -= hand_speed * delta  # left (-X)
	if Input.is_key_pressed(KEY_R): left_delta.x += hand_speed * delta  # right (+X)
	if Input.is_key_pressed(KEY_T): left_delta.y += hand_speed * delta  # up (+Y)
	if Input.is_key_pressed(KEY_G): left_delta.y -= hand_speed * delta  # down (-Y)
	left_hand.target.translate(left_delta)

	# --- Right hand ---
	var right_delta := Vector3.ZERO
	if Input.is_key_pressed(KEY_J): right_delta.z -= hand_speed * delta  # forward (-Z)
	if Input.is_key_pressed(KEY_L): right_delta.z += hand_speed * delta  # backward (+Z)
	if Input.is_key_pressed(KEY_O): right_delta.x -= hand_speed * delta  # left (-X)
	if Input.is_key_pressed(KEY_U): right_delta.x += hand_speed * delta  # right (+X)
	if Input.is_key_pressed(KEY_I): right_delta.y += hand_speed * delta  # up (+Y)
	if Input.is_key_pressed(KEY_K): right_delta.y -= hand_speed * delta  # down (-Y)
	right_hand.target.translate(right_delta)
