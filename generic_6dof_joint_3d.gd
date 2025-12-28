extends Node3D
#Shoutout to dedm0zaj dev
@onready var _hand_rigidbody_left : RigidBody3D = $LeftHandPhysics
@onready var _hand_rigidbody_right : RigidBody3D = $RightHandPhysics

@onready var _hand_contr_left : Node3D = $XROrigin3D/LeftController/FullBodyHandPosition_L
@onready var _hand_contr_right : Node3D = $XROrigin3D/RightController/FullBodyHandPosition_R

func _ready() -> void:
	var xr_interface : XRInterface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		var vp : Viewport = get_viewport()
		vp.use_xr = true


func _physics_process(delta: float) -> void:
	_move_hand_rigidbody_to_contr(_hand_rigidbody_left, _hand_contr_left)
	_move_hand_rigidbody_to_contr(_hand_rigidbody_right, _hand_contr_right)


func _move_hand_rigidbody_to_contr(hand_rigidbody: RigidBody3D, hand_contr: Node3D) -> void:
	# 1 force hand rigidbody to hand contr
	var move_delta : Vector3 = hand_contr.global_position - hand_rigidbody.global_position
	
	var coef_force := 300.0
	hand_rigidbody.apply_central_force(move_delta * coef_force)
	
	# 2 torque hand rigidbody to hand contr
	var quat_hand_rigidbody : Quaternion = hand_rigidbody.global_transform.basis.get_rotation_quaternion()
	var quat_hand_contr : Quaternion = hand_contr.global_transform.basis.get_rotation_quaternion()
	var quat_delta : Quaternion = quat_hand_contr * (quat_hand_rigidbody.inverse())
	var rotation_delta : Vector3 = Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
	
	var coef_torque := 6.0
	hand_rigidbody.apply_torque(rotation_delta * coef_torque)
