extends Node3D

@export var animated_skel : Skeleton3D
@export var physical_skel : Skeleton3D

@export var linear_spring_stiffness: float = 1000
@export var linear_spring_damping: float = 2.0
@export var angular_spring_stiffness: float = 50.0
@export var angular_spring_damping: float = 2.0

var physics_bones

var current_delta:float

func _ready():
	physical_skel.physical_bones_start_simulation()
	physics_bones = physical_skel.get_children().filter(func(x): return x is PhysicalBone3D)

func _process(delta):
	pass

func _physics_process(delta):
	for b:PhysicalBone3D in physics_bones:
		var target_transform: Transform3D = animated_skel.global_transform * animated_skel.get_bone_global_pose(b.get_bone_id())
		var current_transform: Transform3D = physical_skel.global_transform * physical_skel.get_bone_global_pose(b.get_bone_id())
		
		var position_difference: Vector3 = target_transform.origin - current_transform.origin
		var force: Vector3 = hookes_law(position_difference, b.linear_velocity, linear_spring_stiffness, linear_spring_damping)
		b.linear_velocity += (force * delta)
		
		var rotation_difference: Basis = (target_transform.basis * current_transform.basis.inverse())
		var torque = hookes_law(rotation_difference.get_euler(), b.angular_velocity, angular_spring_stiffness, angular_spring_damping)
		b.angular_velocity += torque * current_delta

func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)
