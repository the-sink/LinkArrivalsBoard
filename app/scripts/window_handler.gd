extends Control

@export var arrivals_scroll_container: ScrollContainer

var scroll_speed := 500.0

func _ready() -> void:
	if not OS.has_feature("editor") and not OS.has_feature("wasm"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(delta: float) -> void:
	arrivals_scroll_container.scroll_vertical += Input.get_axis("scroll_up", "scroll_down") * scroll_speed * delta

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_setup"):
		get_tree().change_scene_to_file("res://setup.tscn")


func _on_setup_button_pressed() -> void:
	get_tree().change_scene_to_file("res://setup.tscn")
