extends Node3D
var walking = false # if it is walking
@export var angular_spring_stiffness: float = 4000.0
@export var angular_spring_damping: float = 80.0
@export var max_angular_force: float = 9999.0
var physics_bones = [] # all physical bones
# turn it into ragdoll
@export var ragdoll_mode := false
@export var pose_skel : Skeleton3D
@export var physical_skel : Skeleton3D
@onready var animated_skel : Skeleton3D = $Animated/Armature/Skeleton3D
@onready var camera_pivot = $CameraPivot
@onready var animation_tree = $Animated/AnimationTree
@onready var physical_bone_body : PhysicalBone3D = $"Physical/Armature/Skeleton3D/Physical Bone Body"
var current_delta:float
func _ready():
	physical_skel.physical_bones_start_simulation()# activate ragdoll
	physics_bones = physical_skel.get_children().filter(func(x): return x is PhysicalBone3D) # get all the physical bones
func _physics_process(delta):
	current_delta = delta
	#play walking animation/idle
	if walking:animation_tree.set("parameters/walking/blend_amount",1)
	else:animation_tree.set("parameters/walking/blend_amount",0)
	#rotate the character toward the camera direction
	animated_skel.rotation.y = camera_pivot.rotation.y
func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)
func _on_skeleton_3d_skeleton_updated() -> void:
	for b:PhysicalBone3D in physics_bones:
		var target_transform: Transform3D = pose_skel.global_transform * pose_skel.get_bone_global_pose(b.get_bone_id())
		var current_transform: Transform3D = physical_skel.global_transform * physical_skel.get_bone_global_pose(b.get_bone_id())
		var rotation_difference: Basis = (target_transform.basis * current_transform.basis.inverse())
		var torque = hookes_law(rotation_difference.get_euler(), b.angular_velocity, angular_spring_stiffness, angular_spring_damping)
		torque = torque.limit_length(max_angular_force)
		b.angular_velocity += torque * current_delta
