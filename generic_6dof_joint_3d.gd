extends RigidBody3D

@export var tracked_node: Node3D
@export var follow_strength := 5000.0
@export var damping := 50.0
@export var rotation_strength := 5000.0

func _integrate_forces(state):
	if not tracked_node:
		return

	# POSITION
	var delta = tracked_node.global_position - global_position
	var force = delta * follow_strength - state.linear_velocity * damping
	state.apply_force(force)

	# ROTATION (hands only, head if needed)
	var diff = (global_basis.inverse() * tracked_node.global_basis).get_euler()
	state.apply_torque(diff * rotation_strength)
