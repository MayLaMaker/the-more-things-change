extends Node3D

@export var speed := 5.0
@export var sens := 0.003
@onready var cam := $Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(e):
	if e is InputEventMouseMotion:
		rotate_y(-e.relative.x * sens)
		cam.rotate_x(-e.relative.y * sens)

func _physics_process(d):
	var b := global_transform.basis
	var v := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):	v -= b.z
	if Input.is_key_pressed(KEY_S):	v += b.z
	if Input.is_key_pressed(KEY_A):	v -= b.x
	if Input.is_key_pressed(KEY_D):	v += b.x
	if Input.is_key_pressed(KEY_Q):	v += b.y
	if Input.is_key_pressed(KEY_E):	v -= b.y
	global_position += v.normalized() * speed * d
