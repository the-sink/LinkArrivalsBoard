extends Control

@export var arrivals_scroll_container: ScrollContainer

var scroll_speed := 500.0

var elapsed_time: float = 0.0
var last_mouse_motion: float = 0.0

@onready var is_mobile: bool = OS.has_feature("mobile")

var mouse_visible: float = true:
	set(val):
		if mouse_visible != val:
			mouse_visible = val
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if mouse_visible else Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if not is_mobile: arrivals_scroll_container.scroll_vertical += Input.get_axis("scroll_up", "scroll_down") * scroll_speed * delta
	elapsed_time += delta
	if elapsed_time - last_mouse_motion > 5: mouse_visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_setup"):
		get_tree().change_scene_to_file("res://setup.tscn")
	elif event is InputEventMouseMotion:
		last_mouse_motion = elapsed_time
		mouse_visible = true


func _on_setup_button_pressed() -> void:
	get_tree().change_scene_to_file("res://setup.tscn")
