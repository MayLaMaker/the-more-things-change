extends CharacterBody3D

@onready var headset: XRCamera3D = $XROrigin3D/XRCamera3D
var speed: float = 25.0
var acceleration: float = 1.0
var input_vector: Vector2 = Vector2.ZERO

# Update stick input from signal
func _on_left_controller_input_vector_2_changed(name: String, value: Vector2) -> void:
	input_vector = value

func _physics_process(delta: float) -> void:
	var basis: Basis = headset.global_transform.basis

	var forward: Vector3 = -basis.z
	forward.y = 0
	forward = forward.normalized()

	var right: Vector3 = basis.x
	right.y = 0
	right = right.normalized()

	var target: Vector3 = (right * input_vector.x + forward * input_vector.y) * speed

	# Smooth acceleration (just like before)
	velocity.x = lerp(velocity.x, target.x, acceleration * delta)
	velocity.z = lerp(velocity.z, target.z, acceleration * delta)
	velocity.y = 0  # keep vertical locked for now

	move_and_slide()
