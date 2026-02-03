extends RigidBody3D

func get_center_of_mass_world() -> Vector3:
	return global_transform.origin + global_transform.basis * center_of_mass

func apply_hand_force(world_point: Vector3, force: Vector3) -> void:
	var local_point := world_point - global_transform.origin
	apply_force(force, local_point)
