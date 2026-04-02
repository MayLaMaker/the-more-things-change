extends Skeleton3D

@export_range(0.0, 1.0) var physics_interpolation: float = 0.5

@export var physics_skeleton: Skeleton3D
@export var animated_skeleton: Skeleton3D

func update_blend_ragdoll():
	for i in range(0, get_bone_count()):
		var animated_transform: Transform3D = animated_skeleton.global_transform * animated_skeleton.get_bone_global_pose(i) ## UNKNOWN_IF_TRUE
		var physics_transform: Transform3D = physics_skeleton.global_transform * physics_skeleton.get_bone_global_pose(i) ## UNKNOWN_IF_TRUE
		self.set_bone_global_pose(i, self.global_transform.affine_inverse() * animated_transform.interpolate_with(physics_transform, physics_interpolation), 1.0, true) ## UNKNOWN_IF_TRUE
