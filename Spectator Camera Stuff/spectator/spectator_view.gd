extends Control

@onready var stabilized_camera : Camera3D = $Frame/FirstPersonContainer/FirstPersonViewport/StabilizedCamera3D

func _on_fov_slider_value_changed(value):
	stabilized_camera.fov = value
