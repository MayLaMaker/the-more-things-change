extends Node3D

var left_grip: float = 0.0
var right_grip: float = 0.0
var left_grabbing : bool = false
var right_grabbing : bool = false
var left_grabbed: RigidBody3D = null
var right_grabbed: RigidBody3D = null


@export var hand_force := 300.0
@export var hand_torque := 6.0

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
