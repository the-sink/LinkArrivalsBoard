extends ColorRect

@onready var route_list_container: HBoxContainer = $MainPanel/Steps/RouteList/HBoxContainer
@onready var station_list_container: HBoxContainer = $MainPanel/Steps/StationList/HBoxContainer
@onready var continue_button: Button = $MainPanel/Steps/Continue

var already_loaded: bool = false

func display_state_changed() -> void:
	var current_state = GlobalState.display_state
	if not (current_state == GlobalState.DisplayState.WAITING_HAS_META or current_state == GlobalState.DisplayState.READY): return
	
	if already_loaded: return
	already_loaded = true
	
	for item in route_list_container.get_children():
		item.queue_free()
	
	for route in GlobalState.route_metadata.keys():
		var metadata = GlobalState.route_metadata[route]
		var button = preload("res://route_button.tscn").instantiate()
		button.short_name = metadata['short_name']
		button.long_name = metadata['long_name']
		button.color = metadata['color']
		button.update_displayed_info()
		button.button_pressed = GlobalState.selected_route_id == route
		route_list_container.add_child(button)
		button.pressed.connect(func():
			GlobalState.selected_route_id = route
			for item in route_list_container.get_children():
				if not item == button: item.button_pressed = false
		)
	
	route_list_container.get_child(0).grab_focus()

func update_station_list():
	#TODO: not correct, station_list should change depending on the selected route
	for item in station_list_container.get_children():
		item.queue_free()
	for station_name in GlobalState.station_list:
		var button = preload("res://station_button.tscn").instantiate()
		button.text = "  " + station_name + "  "
		button.button_pressed = GlobalState.selected_station_name == station_name
		station_list_container.add_child(button)
		button.pressed.connect(func():
			GlobalState.selected_station_name = station_name
			for item in station_list_container.get_children():
				if not item == button: item.button_pressed = false
		)

func _ready() -> void:
	GlobalState.display_state_changed.connect(display_state_changed)
	GlobalState.station_list_changed.connect(update_station_list)
	display_state_changed()
	update_station_list()


func _on_continue_pressed() -> void:
	if GlobalState.selected_route_id.is_empty() or GlobalState.selected_station_name.is_empty(): return
	
	get_tree().change_scene_to_file("res://arrivals.tscn")
