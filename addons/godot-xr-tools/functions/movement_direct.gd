@tool
class_name XRToolsMovementDirect
extends XRToolsMovementProvider

## XR Tools Direct Movement with Acceleration and Friction
##
## Provides VR-ready direct movement using XRToolsPlayerBody.
## Supports acceleration and friction for smoother motion.

@export var order: int = 10

# Movement settings
@export var max_speed: float = 3.0
@export var acceleration: float = 12.5
@export var friction: float = 4.5

# Input action for movement
@export var input_action: String = "primary"

# Controller reference
@onready var _controller := XRHelpers.get_xr_controller(self)

# Add XRTools support
func is_xr_class(name: String) -> bool:
	return name == "XRToolsMovementDirect" or super(name)

# Physics movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if controller inactive
	if !_controller.get_is_active():
		return

	# Get input vector with deadzone
	var dz_input = XRToolsUserSettings.get_adjusted_vector2(_controller, input_action)

	# Desired velocity based on input
	var target_velocity = Vector2(dz_input.x, dz_input.y) * max_speed

	# Accelerate towards target
	var dv = target_velocity - player_body.ground_control_velocity
	if dv.length() > 0:
		player_body.ground_control_velocity += dv.normalized() * acceleration * _delta
		if player_body.ground_control_velocity.length() > max_speed:
			player_body.ground_control_velocity = player_body.ground_control_velocity.normalized() * max_speed

	# Apply friction if no input
	if dz_input.length() < 0.01:
		player_body.ground_control_velocity = player_body.ground_control_velocity.move_toward(Vector2.ZERO, friction * _delta)

	# Apply movement to player body
	var forward_dir = player_body.camera_node.global_transform.basis.z.slide(Vector3.UP).normalized()
	var right_dir = player_body.camera_node.global_transform.basis.x.slide(Vector3.UP).normalized()
	var move_vector = (-forward_dir * player_body.ground_control_velocity.y + right_dir * player_body.ground_control_velocity.x) * XRServer.world_scale

	player_body.velocity.x = move_vector.x
	player_body.velocity.z = move_vector.z

	# Move the body
	player_body.move_and_slide()

# Configuration warnings
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()
	if !_controller:
		warnings.append("Must be under an XRController3D node")
	return warnings

# Find left XRToolsMovementDirect
static func find_left(node: Node) -> XRToolsMovementDirect:
	return XRTools.find_xr_child(XRHelpers.get_left_controller(node), "*", "XRToolsMovementDirect") as XRToolsMovementDirect

# Find right XRToolsMovementDirect
static func find_right(node: Node) -> XRToolsMovementDirect:
	return XRTools.find_xr_child(XRHelpers.get_right_controller(node), "*", "XRToolsMovementDirect") as XRToolsMovementDirect
