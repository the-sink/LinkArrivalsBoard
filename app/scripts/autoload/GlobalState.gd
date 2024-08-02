extends Node

signal route_id_changed(new_id: String)
signal station_name_changed(new_name: String)
signal display_state_changed()
signal station_list_changed()

enum DisplayState {
	WAITING,
	WAITING_HAS_META,
	HTTP_ERROR,
	READY
}

@onready var config := ConfigFile.new()

var proxy_server_base_url := "http://127.0.0.1:5000"
var selected_route_id := "":
	set(val):
		if val == selected_route_id: return
		selected_route_id = val
		config.set_value('config', 'route_id', val)
		config.save('user://config.cfg')
		route_id_changed.emit(val)
var selected_station_name := "":
	set(val):
		if val == selected_route_id: return
		selected_station_name = val
		config.set_value('config', 'station_name', val)
		config.save('user://config.cfg')
		station_name_changed.emit(val)

var current_arrivals := {}

var station_list := []:
	set(val):
		station_list = val
		station_list_changed.emit()
var route_metadata := {}
var display_state: DisplayState = DisplayState.WAITING:
	set(val):
		display_state = val
		display_state_changed.emit()
var error_information: String = ""


func _ready() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	
	# get route metadata
	var metadata_response = await Util.make_request(http, proxy_server_base_url + "/routes")
	if not metadata_response: return
	route_metadata = JSON.parse_string(metadata_response['body'].get_string_from_utf8())

	display_state = DisplayState.WAITING_HAS_META

	route_id_changed.connect(func(_new_id: String):
		display_state = DisplayState.WAITING_HAS_META
		
		# get stops list
		var stops_list_response = await Util.make_request(http, proxy_server_base_url + "/stops/" + selected_route_id)
		if not stops_list_response: return
		station_list = JSON.parse_string(stops_list_response['body'].get_string_from_utf8())
		
		# if there is data, set the display to the ready state
		if station_list and len(station_list) > 0:
			selected_station_name = station_list[0]
			display_state = DisplayState.READY
	)
	
	# load config
	var load_status = config.load('user://config.cfg')
	if load_status == OK:
		selected_route_id = config.get_value('config', 'route_id', '')
		selected_station_name = config.get_value('config', 'station_name', '')
	
	# send to setup if we're in station view on startup, but are missing information
	if get_tree().current_scene.name == "StationView":
		if selected_route_id.is_empty() or selected_station_name.is_empty():
			get_tree().call_deferred("change_scene_to_file", "res://setup.tscn")
