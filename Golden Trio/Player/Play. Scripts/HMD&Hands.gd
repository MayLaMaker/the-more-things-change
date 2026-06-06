extends XROrigin3D
@export var HMD_target: Node3D
@export var HMD_Target_ON := false
@export var controller_target_l: Node3D
@export var controller_target_r: Node3D
@export var HMD : Node3D
@export var controller_l: XRController3D
@export var controller_r: XRController3D
func _process(delta: float) -> void:
	controller_target_l.global_position = controller_l.global_position
	controller_target_l.global_transform = controller_l.global_transform
	controller_target_r.global_position = controller_r.global_position
	controller_target_r.global_transform = controller_r.global_transform  
	if HMD_Target_ON:
		HMD_target.global_position = HMD.global_position
