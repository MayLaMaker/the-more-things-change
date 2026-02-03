extends Node3D

@export var animated_skel : Skeleton3D
@export var physical_skel : Skeleton3D

func _ready():
	physical_skel.physical_bones_start_simulation()
