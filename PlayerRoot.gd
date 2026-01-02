extends Node3D

var left_grip: float = 0.0
var right_grip: float = 0.0
var left_grabbing := false
var right_grabbing := false

@export var hand_force := 300.0
@export var hand_torque := 6.0

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
