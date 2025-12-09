extends CharacterBody3D

@onready var headset: XRCamera3D = $XROrigin3D/XRCamera3D
# LeftStick Movement
@export var speed: float = 25.0
@export var acceleration: float = 1.0
var input_vector: Vector2 = Vector2.ZERO
@export var gravity: float = 9.8
@export var air_control: float = 0 # 0 = no control in air, 1 = full control
# Grabbing
var left_grabbing := false
var right_grabbing := false
@onready var left_hand: XRController3D = $XROrigin3D/LeftController
@onready var right_hand: XRController3D = $XROrigin3D/RightController
var left_prev_pos: Vector3
var right_prev_pos: Vector3
@export var can_climb: bool = true
@export var climb_strength: float = 1.0
# Both Hand Climbing
var both_hands_grabbing: bool = false
var virtual_hand_start: Vector3 = Vector3.ZERO
var virtual_hand_prev: Vector3 = Vector3.ZERO
var virtual_hand_initialized: bool = false

# Grab Functions
func _on_left_controller_button_pressed(name: String) -> void:
	if name == "grip_click":
		left_grabbing = true
		left_prev_pos = left_hand.global_transform.origin
		print("Left grip pressed")

func _on_left_controller_button_released(name: String) -> void:
	if name == "grip_click":
		left_grabbing = false
		left_prev_pos = left_hand.global_transform.origin
		print("Left grip released")

func _on_right_controller_button_pressed(name: String) -> void:
	if name == "grip_click":
		right_grabbing = true
		right_prev_pos = right_hand.global_transform.origin
		print("Right grip pressed")

func _on_right_controller_button_released(name: String) -> void:
	if name == "grip_click":
		right_grabbing = false
		right_prev_pos = right_hand.global_transform.origin
		print("Right grip released")

# Update stick input from signal
func _on_left_controller_input_vector_2_changed(name: String, value: Vector2) -> void:
	input_vector = value

func _physics_process(delta: float) -> void:
	# Determine if both hands are grabbing
	both_hands_grabbing = left_grabbing and right_grabbing

	# Initialize virtual hand if both hands start grabbing
	if both_hands_grabbing and not virtual_hand_initialized:
		virtual_hand_start = (left_prev_pos + right_prev_pos) * 0.5
		virtual_hand_prev = virtual_hand_start
		virtual_hand_initialized = true

	# Climbing logic
	if can_climb and (left_grabbing or right_grabbing):
		var climb_force := Vector3.ZERO

		if both_hands_grabbing:
			var current_midpoint = (left_hand.global_transform.origin + right_hand.global_transform.origin) * 0.5
			climb_force = virtual_hand_prev - current_midpoint
			virtual_hand_prev = current_midpoint
		else:
			if left_grabbing:
				climb_force += left_prev_pos - left_hand.global_transform.origin
				left_prev_pos = left_hand.global_transform.origin
			if right_grabbing:
				climb_force += right_prev_pos - right_hand.global_transform.origin
				right_prev_pos = right_hand.global_transform.origin

		# Apply climbing force
		velocity += (climb_force / delta) * climb_strength

	# Reset virtual hand when not both grabbing
	if not both_hands_grabbing:
		virtual_hand_initialized = false

	# Normal movement
	var basis: Basis = headset.global_transform.basis
	var forward: Vector3 = -basis.z
	forward.y = 0
	forward = forward.normalized()
	var right: Vector3 = basis.x
	right.y = 0
	right = right.normalized()

	var move_x = input_vector.x * 0.5
	var move_y = input_vector.y
	if move_y < 0:
		move_y *= 0.5
	var target: Vector3 = (right * move_x + forward * move_y) * speed

	if is_on_floor():
		velocity.x = lerp(velocity.x, target.x, acceleration * delta)
		velocity.z = lerp(velocity.z, target.z, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, target.x, acceleration * air_control * delta)
		velocity.z = lerp(velocity.z, target.z, acceleration * air_control * delta)

	# Apply gravity
	velocity.y -= gravity * delta

	move_and_slide()
