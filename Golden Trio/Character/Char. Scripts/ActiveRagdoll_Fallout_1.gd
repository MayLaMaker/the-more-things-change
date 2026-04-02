extends Node

func _on_skeleton_3d_skeleton_updated() -> void:
	
	if ragdoll_skeleton:
		return
	
	# rotate the physical bones toward the animated bones rotations using hookes law
	for bone:PhysicalBone3D in physics_bones:
		if bone.ragdoll_bone:
			continue
			
		var bone_id = bone.get_bone_id()

		# Get local space transforms
		var animation_transform: Transform3D = anim_skeleton_3d.global_transform * anim_skeleton_3d.get_bone_global_pose(bone_id)
		var physics_transform: Transform3D = self.global_transform * get_bone_global_pose(bone_id)


		# check angle of bone
		check_root_bone()
		
		# Conpute differences in local space
		var position_difference := animation_transform.origin - physics_transform.origin
		var rotation_difference := animation_transform.basis * physics_transform.basis.inverse()
		
		var force := MathManager.hookes_law(position_difference, bone.linear_velocity, linear_spring_stiffness, linear_spring_damping)
		force = force.limit_length(max_linear_force)
		bone.linear_velocity += (force * bone.current_bone_strength * force_strength) * current_delta
		
		var torque := MathManager.hookes_law(rotation_difference.get_euler() , bone.angular_velocity, angular_spring_stiffness, angular_spring_damping)
		torque = torque.limit_length(max_angular_force)
		bone.angular_velocity += (torque * bone.current_bone_strength * force_strength) * current_delta
