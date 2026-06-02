extends Node3D
@export var angular_spring_stiffness: float = 400.0 # spring stuff
@export var angular_spring_damping: float = 8.0
@export var max_angular_force: float = 9999.0
var physics_bones = [] # all physical bones
@export var physical_skel : Skeleton3D # turn it into ragdoll
@export var animated_skel : Skeleton3D
var current_delta:float
func _ready():
	physical_skel.physical_bones_start_simulation()# activate ragdoll
	call_deferred("_disable_parent_child_collisions")
	physics_bones = physical_skel.get_children().filter(func(x): return x is PhysicalBone3D) # get all the physical bones
func _physics_process(delta):
	current_delta = delta
func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)
func _on_skeleton_3d_skeleton_updated() -> void:
	for b:PhysicalBone3D in physics_bones: # rotate the physical bones toward the animated bones rotations using hookes law
		var target_transform: Transform3D = animated_skel.global_transform * animated_skel.get_bone_global_pose(b.get_bone_id())
		var current_transform: Transform3D = physical_skel.global_transform * physical_skel.get_bone_global_pose(b.get_bone_id())
		var rotation_difference: Basis = (target_transform.basis * current_transform.basis.inverse())
		var torque = hookes_law(rotation_difference.get_euler(), b.angular_velocity, angular_spring_stiffness, angular_spring_damping)
		torque = torque.limit_length(max_angular_force)
		b.angular_velocity += torque * current_delta
		var position_difference: Vector3 = target_transform.origin - current_transform.origin
		var force: Vector3 = hookes_law(position_difference, b.linear_velocity, linear_spring_stiffness, linear_spring_damping)
		b.linear_velocity += (force * current_delta)
@export var linear_spring_stiffness: float = 400.0
@export var linear_spring_damping: float = 8.0
func _disable_parent_child_collisions():
	var bones: Dictionary = {}
	for node in physical_skel.get_children(): # find all PhysicalBone3D nodes under the skeleton
		if node is PhysicalBone3D:
			var bid: int = node.get_bone_id()
			if bid >= 0:bones[bid] = node
	for key in bones.keys(): # for each physical bone, disable collisions with its parent
		var bid: int = int(key)  # explicitly cast to int
		var parent_idx: int = physical_skel.get_bone_parent(bid)
		if parent_idx == -1:continue
		if bones.has(parent_idx):
			var child_body: PhysicalBone3D = bones[bid]
			var parent_body: PhysicalBone3D = bones[parent_idx]
			child_body.add_collision_exception_with(parent_body)
			parent_body.add_collision_exception_with(child_body)
