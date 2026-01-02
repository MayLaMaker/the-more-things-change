extends Node3D

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
