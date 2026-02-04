extends Node3D
@export var physical_skel: Skeleton3D
func _ready():
	physical_skel.physical_bones_start_simulation()

## --- Disable Parent/Child Bone Collisions ---
	call_deferred("_disable_parent_child_collisions")
func _disable_parent_child_collisions():
	var bones: Dictionary = {}
	
	# find all PhysicalBone3D nodes under the skeleton
	for node in physical_skel.get_children():
		if node is PhysicalBone3D:
			var bid: int = node.get_bone_id()
			if bid >= 0:
				bones[bid] = node

	# for each physical bone, disable collisions with its parent
	for key in bones.keys():
		var bid: int = int(key)  # explicitly cast to int
		var parent_idx: int = physical_skel.get_bone_parent(bid)
		
		if parent_idx == -1:
			continue
		
		if bones.has(parent_idx):
			var child_body: PhysicalBone3D = bones[bid]
			var parent_body: PhysicalBone3D = bones[parent_idx]

			child_body.add_collision_exception_with(parent_body)
			parent_body.add_collision_exception_with(child_body)
