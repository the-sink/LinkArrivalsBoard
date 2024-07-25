extends Node

signal station_name_changed(new_name: String)
signal display_state_changed()

enum DisplayState {
	WAITING_FOR_STATION_LIST,
	ENV_VAR_ERROR,
	RUNNING
}

var api_key := OS.get_environment("oba_api_key")

var selected_station_name := "Westlake":
	set(val):
		selected_station_name = val
		station_name_changed.emit(val)

var current_arrivals := {}
var line_color_cache := {}

var station_list := {}:
	set(val):
		if val != null:
			station_list = val
			display_state = DisplayState.RUNNING
var display_state: DisplayState = DisplayState.WAITING_FOR_STATION_LIST:
	set(val):
		var old_state := display_state
		display_state = val
		display_state_changed.emit()

# Use static GTFS data for staton name -> stop ID translation dict
# Cached locally for n days (refresh_gtfs_interval_days above)

func _ready() -> void:
	if api_key.is_empty():
		display_state = DisplayState.ENV_VAR_ERROR
		return

	var http := HTTPRequest.new()
	add_child(http)
	
	var stops_file_contents: String = await GTFS.get_gtfs_file("stops")
	
	http.request("https://api.pugetsound.onebusaway.org/api/where/stops-for-route/40_100479.json?key=" + api_key)
	var stops_body = (await http.request_completed)
	stops_body = stops_body[3]
	var stops_data = JSON.parse_string(stops_body.get_string_from_utf8())['data']
	var stop_list: Array = stops_data['entry']['stopIds']
	
	var new_station_list := {}
	for line in stops_file_contents.split("\n"):
		var items = line.split(",")
		if items.size() <= 1: break
		if not "40_" + items[0] in stop_list: continue
		var name_list = new_station_list.get_or_add(items[1], [])
		name_list.append(items[0])
	station_list = new_station_list
