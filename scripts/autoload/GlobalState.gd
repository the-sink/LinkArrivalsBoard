extends Node

signal station_name_changed(new_name: String)
signal display_state_changed(new_state: DisplayState, old_state: DisplayState)

enum DisplayState {
	WAITING_FOR_STATION_LIST,
	ENV_VAR_ERROR,
	RUNNING
}

var refresh_gtfs_interval_days := 3
var api_key := OS.get_environment("oba-api-key")

var selected_station_name: String = "Westlake":
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
		display_state_changed.emit(display_state, old_state)

# Collect static GTFS data for staton name -> stop ID translation dict
# Cached locally for n days (refresh_gtfs_interval_days above)

func _ready() -> void:
	if api_key.length() < 1:
		display_state = DisplayState.ENV_VAR_ERROR
		return
	
	var gtfs_config := ConfigFile.new()
	var do_gtfs_refresh = false
	var cfg_err = gtfs_config.load("user://gtfs.cfg")
	
	if cfg_err: do_gtfs_refresh = true
	else:
		var time_since_last_refresh = Time.get_unix_time_from_system() - gtfs_config.get_value("last", "gtfs_update", 0)
		do_gtfs_refresh = time_since_last_refresh > refresh_gtfs_interval_days * 24 * 60 * 60
	
	var http := HTTPRequest.new()
	add_child(http)
	
	if do_gtfs_refresh:
		http.download_file = "user://40_gtfs.zip"
		http.request("https://www.soundtransit.org/GTFS-rail/40_gtfs.zip")
		await http.request_completed
		gtfs_config.set_value("last", "gtfs_update", Time.get_unix_time_from_system())
		gtfs_config.save("user://gtfs.cfg")
	
	var zip_reader := ZIPReader.new()
	var err = zip_reader.open("user://40_gtfs.zip")
	var stops_file = zip_reader.read_file("stops.txt")
	var stops_file_contents: String = stops_file.get_string_from_utf8()
	
	http.request("https://api.pugetsound.onebusaway.org/api/where/stops-for-route/40_100479.json?key=" + api_key)
	var stops_body = (await http.request_completed)[3]
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
