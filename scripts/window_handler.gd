extends Control

@export var sidebar: ColorRect

func _ready() -> void:
	if not OS.has_feature("editor"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _on_gui_input(event: InputEvent) -> void:
	var swipe_open: bool = false
	var swipe_close: bool = false
	if event is InputEventScreenDrag:
		swipe_open = event.velocity.x > 300
		swipe_close = event.velocity.x < -300
	elif event is InputEventMouseButton:
		swipe_open = event.button_index == MOUSE_BUTTON_WHEEL_LEFT
		swipe_close = event.button_index == MOUSE_BUTTON_WHEEL_RIGHT
		
	if not (swipe_open or swipe_close): return
	sidebar.open = swipe_open

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_menu"):
		sidebar.open = !sidebar.open
