extends Node
@export var left_hand: Node3D
@export var right_hand: Node3D
@export var hand_speed := 2.0
func _process(delta):
	# --- Left hand movement (T/F/G/H/R/Y) ---
	var left_delta := Vector3.ZERO
	if Input.is_key_pressed(KEY_T):
		left_delta.z -= hand_speed * delta
	if Input.is_key_pressed(KEY_G):
		left_delta.z += hand_speed * delta
	if Input.is_key_pressed(KEY_F):
		left_delta.x -= hand_speed * delta
	if Input.is_key_pressed(KEY_H):
		left_delta.x += hand_speed * delta
	if Input.is_key_pressed(KEY_R):
		left_delta.y += hand_speed * delta
	if Input.is_key_pressed(KEY_Y):
		left_delta.y -= hand_speed * delta
	if left_hand:
		left_hand.translate(left_delta)
	# --- Right hand movement (I/J/K/L/U/O) ---
	var right_delta := Vector3.ZERO
	if Input.is_key_pressed(KEY_I):
		right_delta.z -= hand_speed * delta
	if Input.is_key_pressed(KEY_K):
		right_delta.z += hand_speed * delta
	if Input.is_key_pressed(KEY_J):
		right_delta.x -= hand_speed * delta
	if Input.is_key_pressed(KEY_L):
		right_delta.x += hand_speed * delta
	if Input.is_key_pressed(KEY_U):
		right_delta.y += hand_speed * delta
	if Input.is_key_pressed(KEY_O):
		right_delta.y -= hand_speed * delta
	if right_hand:
		right_hand.translate(right_delta)
