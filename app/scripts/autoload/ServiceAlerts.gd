extends Node

const TEST_SHOW_ANY_ALERT: bool = true

var _http: HTTPRequest

var cached_alerts := []
var last_request: int = 0

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)

func _update_alerts():
	var current_time := Time.get_unix_time_from_system()
	if current_time - last_request < 30: return
	last_request = current_time
	
	#var file = FileAccess.open("res://test_alerts_scenario.json", FileAccess.READ)
	#cached_alerts = JSON.parse_string(file.get_as_text())['entity']
	var err = _http.request("https://s3.amazonaws.com/st-service-alerts-prod/alerts_pb.json")
	if err == OK: cached_alerts = JSON.parse_string((await _http.request_completed)[3].get_string_from_utf8())['entity']

func get_relevant_alerts(route_id: String, station_name: String):
	await _update_alerts()
	
	var relevant_alerts := []
	var no_service := false
	var current_time := Time.get_unix_time_from_system()
	
	for alert in cached_alerts:
		var alert_data = alert['alert']
		if not TEST_SHOW_ANY_ALERT and alert_data['effect_detail']['translation'][0]['text'] != "DELAY":
			if alert_data['severity_level'] != "SEVERE": continue
		var active_periods = alert_data['active_period']
		var is_active: bool = false
		for period in active_periods:
			var start = period.get('start', -1)
			var end = period.get('end', 9e10)
			if current_time > start and current_time < end:
				is_active = true
				break
		if not is_active: continue
		var informed = alert_data['informed_entity']
		var should_be_informed := false
		for entity in informed:
			if not 'agency_id' in entity: continue
			var agency_prefix := str(entity['agency_id']) + "_"
			if agency_prefix + entity['route_id'] != route_id: continue
			var stop_id = entity.get('stop_id', null)
			if stop_id == null:
				should_be_informed = true
				break
			else:
				var valid_stop_ids = GlobalState.station_list[station_name]
				if valid_stop_ids.has(agency_prefix + str(stop_id)):
					should_be_informed = true
					break
		if not should_be_informed: continue
		if alert_data['effect'] == "NO_SERVICE": no_service = true
		
		relevant_alerts.append({
			'effect': alert_data['effect'],
			'text': alert_data['header_text']['translation'][0]['text']
		})
	
	return {
		'no_service': no_service,
		'relevant_alerts': relevant_alerts
	}
