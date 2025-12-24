extends SkeletonIK3D

func _ready() -> void:
	var left_hand_offset := Transform3D(Basis(Vector3(0,1,0), deg2rad(90)), Vector3.ZERO)
	start()

func _process(delta: float) -> void:
	pass
