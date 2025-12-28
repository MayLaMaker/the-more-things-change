extends RigidBody3D

# --- Nodes ---
@onready var headset: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_hand: XRController3D = $XROrigin3D/LeftController
@onready var right_hand: XRController3D = $XROrigin3D/RightController
@onready var left_hand_grab_cast: ShapeCast3D = $XROrigin3D/LeftController/GrabRegionL
@onready var right_hand_grab_cast: ShapeCast3D = $XROrigin3D/RightController/GrabRegionR
@onready var left_L1: ShapeCast3D = $XROrigin3D/LeftController/GrabRegionL/Can_GrabRegion_L1
@onready var left_L2: ShapeCast3D = $XROrigin3D/LeftController/GrabRegionL/Can_GrabRegion_L2
@onready var right_L1: ShapeCast3D = $XROrigin3D/RightController/GrabRegionR/Can_GrabRegion_R1
@onready var right_L2: ShapeCast3D = $XROrigin3D/RightController/GrabRegionR/Can_GrabRegion_R2
@onready var skeleton: Skeleton3D = $"XROrigin3D/Female Test/Armature/Skeleton3D"
@onready var Body_Origin: Node3D = $"XROrigin3D/Female Test"
# --- Movement ---
@export var speed: float = 10.0
@export var acceleration: float = 1.0
var input_vector: Vector2 = Vector2.ZERO
@export var gravity: float = 9.8
@export var air_control: float = 0
@export var head_bone_name: String = "Head"

# --- Climbing ---
var left_grabbing := false
var right_grabbing := false
var left_prev_pos: Vector3
var right_prev_pos: Vector3
@export var can_climb: bool = true
@export var climb_strength: float = 1.0
var grip_effect: float = 0.0
@export var grip_sliderate: float = 10

var left_grip: float = 0.0
var right_grip: float = 0.0

# Both-hand climbing
var both_hands_grabbing: bool = false
var virtual_hand_start: Vector3 = Vector3.ZERO
var virtual_hand_prev: Vector3 = Vector3.ZERO
var virtual_hand_initialized: bool = false

# --- Head Bobbing ---
@export var head_bob_enabled: bool = true
@export var bob_amount: float = 0.01
@export var bob_speed: float = 5.0
var bob_time: float = 0.0
var base_head_y: float = 0.0
var head_offset: Vector3 = Vector3.ZERO

# --- Desktop XR Emulation ---
@export var desktop_debug := false
var mouse_delta := Vector2.ZERO
var left_hand_speed := 2.0
var right_hand_speed := 2.0
var headset_speed := 2.0
var rotation_speed := 0.002

func _ready():
	var xr := XRServer.get_primary_interface()
	if xr == null or not xr.is_initialized():
		desktop_debug = true
		Desktop_Mode()

func Desktop_Mode():
	set_process(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if desktop_debug and event is InputEventMouseMotion:
		mouse_delta = event.relative

# --- Grab Check ---
func Can_Grab(hand_cast: ShapeCast3D, L1: ShapeCast3D, L2: ShapeCast3D) -> bool:
	if not hand_cast or not hand_cast.is_colliding():
		return false
	if (L1 and L1.is_colliding()) or (L2 and L2.is_colliding()):
		return false
	return true

# --- Grab Functions (analog grip) ---
func _on_left_controller_input_float_changed(name: String, value: float) -> void:
	if name == "grip":
		left_grip = value
		if value > 0.0 and not left_grabbing:
			if Can_Grab(left_hand_grab_cast, left_L1, left_L2):
				left_grabbing = true
				left_prev_pos = left_hand.global_transform.origin
		elif value <= 0.0:
			left_grabbing = false

func _on_right_controller_input_float_changed(name: String, value: float) -> void:
	if name == "grip":
		right_grip = value
		if value > 0.0 and not right_grabbing:
			if Can_Grab(right_hand_grab_cast, right_L1, right_L2):
				right_grabbing = true
				right_prev_pos = right_hand.global_transform.origin
		elif value <= 0.0:
			right_grabbing = false

# --- Movement Input ---
func _on_left_controller_input_vector_2_changed(name: String, value: Vector2) -> void:
	input_vector = value

# --- Physics ---
func _physics_process(delta: float) -> void:
	# Track transition out of two-hand grab
	var was_both := both_hands_grabbing
	both_hands_grabbing = left_grabbing and right_grabbing

	if was_both and not both_hands_grabbing:
		if left_grabbing:
			left_prev_pos = left_hand.global_transform.origin
		if right_grabbing:
			right_prev_pos = right_hand.global_transform.origin
		virtual_hand_initialized = false

	if both_hands_grabbing and not virtual_hand_initialized:
		virtual_hand_start = (left_prev_pos + right_prev_pos) * 0.5
		virtual_hand_prev = virtual_hand_start
		virtual_hand_initialized = true

	# --- Climbing Logic ---
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

	if not both_hands_grabbing:
		virtual_hand_initialized = false
