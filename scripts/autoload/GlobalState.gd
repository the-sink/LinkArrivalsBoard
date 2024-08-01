extends Node

signal station_name_changed(new_name: String)
signal display_state_changed()

enum DisplayState {
	WAITING_FOR_STATION_LIST,
	ENV_VAR_ERROR,
	RUNNING
}

#TODO: Request error handling

var proxy_server_base_url := "http://127.0.0.1:5000"
var selected_route_id := "40_100479"
var selected_station_name := "":
	set(val):
		selected_station_name = val
		station_name_changed.emit(val)

var current_arrivals := {}

var station_list := []
var route_metadata := {}
var display_state: DisplayState = DisplayState.WAITING_FOR_STATION_LIST:
	set(val):
		var old_state := display_state
		display_state = val
		display_state_changed.emit()

func _ready() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	
	# get stops list
	http.request(proxy_server_base_url + "/stops/" + selected_route_id)
	var stops_list_response = await http.request_completed
	station_list = JSON.parse_string(stops_list_response[3].get_string_from_utf8())
	if station_list and len(station_list) > 0:
		selected_station_name = station_list[0]
		display_state = DisplayState.RUNNING
	
	# get route metadata
	http.request(proxy_server_base_url + "/routes")
	var metadata_response = await http.request_completed
	route_metadata = JSON.parse_string(metadata_response[3].get_string_from_utf8())
