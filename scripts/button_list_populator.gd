extends ScrollContainer

@export var container: VBoxContainer

var already_run := false

func populate():
	if not GlobalState.display_state == GlobalState.DisplayState.RUNNING: return
	if already_run: return
	already_run = true
	
	for station_name in GlobalState.station_list.keys():
		var button: Button = preload("res://station_button.tscn").instantiate()
		button.station_name = station_name
		container.add_child(button)

func _ready() -> void:
	populate()
	GlobalState.display_state_changed.connect(populate)
