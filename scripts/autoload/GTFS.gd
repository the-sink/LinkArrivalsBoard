extends Node

var refresh_gtfs_interval_days := 3
var url := "https://www.soundtransit.org/GTFS-rail/40_gtfs.zip"

var cached_gtfs_zip_reader: ZIPReader

#TODO: Re-check (and re-download if needed) while app is running, if running for prolonged periods
# (currently it will only check and re-download GTFS data on startup)

func _download_gtfs_zip(http: HTTPRequest) -> void:
	http.download_file = "user://40_gtfs.zip"
	http.request(url)
	await http.request_completed
	http.download_file = ""

func _ensure_gtfs_available() -> void:
	if cached_gtfs_zip_reader != null: return
	
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
		await _download_gtfs_zip(http)
		gtfs_config.set_value("last", "gtfs_update", Time.get_unix_time_from_system())
		gtfs_config.save("user://gtfs.cfg")
	
	var zip_reader := ZIPReader.new()
	var res = zip_reader.open("user://40_gtfs.zip")
	cached_gtfs_zip_reader = zip_reader

func get_gtfs_file(name: String) -> String:
	await _ensure_gtfs_available()
	if not name.ends_with(".txt"): name += ".txt"
	if not cached_gtfs_zip_reader.file_exists(name): return ""
	
	var file = cached_gtfs_zip_reader.read_file(name)
	var file_contents: String = file.get_string_from_utf8()
	return file_contents
