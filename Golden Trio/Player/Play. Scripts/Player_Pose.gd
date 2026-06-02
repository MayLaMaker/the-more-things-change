extends Node
@export var head: Camera3D
@export var hand_left: Node3D
@export var hand_right: Node3D
@export var leg_left: Node3D
@export var leg_right: Node3D
@export var headset_speed := 2.0
@export var hand_speed := 2.0
@export var skeleton: Skeleton3D
@export var Body_Origin: Node3D
func _process(delta):
	var left_delta := Vector3.ZERO # --- Left hand movement (T/F/G/H/R/Y) ---
	if Input.is_key_pressed(KEY_T):left_delta.z -= hand_speed * delta
	if Input.is_key_pressed(KEY_G):left_delta.z += hand_speed * delta
	if Input.is_key_pressed(KEY_F):left_delta.x -= hand_speed * delta
	if Input.is_key_pressed(KEY_H):left_delta.x += hand_speed * delta
	if Input.is_key_pressed(KEY_R):left_delta.y += hand_speed * delta
	if Input.is_key_pressed(KEY_Y):left_delta.y -= hand_speed * delta
	if hand_left:hand_left.translate(left_delta)
	var right_delta := Vector3.ZERO # --- Right hand movement (I/J/K/L/U/O) ---
	if Input.is_key_pressed(KEY_I):right_delta.z -= hand_speed * delta
	if Input.is_key_pressed(KEY_K):right_delta.z += hand_speed * delta
	if Input.is_key_pressed(KEY_J):right_delta.x -= hand_speed * delta
	if Input.is_key_pressed(KEY_L):right_delta.x += hand_speed * delta
	if Input.is_key_pressed(KEY_U):right_delta.y += hand_speed * delta
	if Input.is_key_pressed(KEY_O):right_delta.y -= hand_speed * delta
	if hand_right:
		hand_right.translate(right_delta)
	var headset_delta := Vector3.ZERO # --- Head movement ---
	if Input.is_key_pressed(KEY_UP):headset_delta.z -= headset_speed * delta
	if Input.is_key_pressed(KEY_DOWN):headset_delta.z += headset_speed * delta
	if Input.is_key_pressed(KEY_LEFT):headset_delta.x -= headset_speed * delta
	if Input.is_key_pressed(KEY_RIGHT):headset_delta.x += headset_speed * delta
	if Input.is_key_pressed(KEY_N):headset_delta.y += headset_speed * delta
	if Input.is_key_pressed(KEY_M):headset_delta.y -= headset_speed * delta
	head.translate(headset_delta)
	var spine_id := skeleton.find_bone("Spine") # Spine rotation from hand positions (XZ → Yaw)
	if spine_id != -1:
		var left_pos := hand_left.global_transform.origin
		var right_pos := hand_right.global_transform.origin
		var body_pos := Body_Origin.global_transform.origin
		# Hand direction (XZ)
		var hand_dir := right_pos - left_pos
		hand_dir.y = 0.0
		if hand_dir.length() < 0.001:
			return
		hand_dir = hand_dir.normalized()
		var body_forward := -head.global_transform.basis.z # Body forward (from headset)
		body_forward.y = 0.0
		body_forward = body_forward.normalized()
		var yaw := body_forward.signed_angle_to(hand_dir, Vector3.UP) + PI * 0.5 # Signed angle around Y
		var spine_pose := skeleton.get_bone_global_pose(spine_id) # Apply to spine
		spine_pose.basis = Basis(Vector3.UP, yaw)
		skeleton.set_bone_global_pose_override(
			spine_id,
			spine_pose,
			1.0,
			true)
