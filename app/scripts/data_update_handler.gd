extends Node

@export var data_container: DataContainer
@export var oba_request: HTTPRequest
@export var data_timer: Timer

func do_data_refresh() -> void:
	for arrival in data_container.current_arrivals.values():
		arrival.update_cycle_flag = false
	
	var service_alerts = await ServiceAlerts.get_relevant_alerts(GlobalState.selected_route_id, GlobalState.selected_station_name)
	data_container.current_service_alerts = service_alerts
	
	oba_request.request(GlobalState.proxy_server_base_url + "/arrivals/" + GlobalState.selected_route_id,
	["Content-Type: application/json"], HTTPClient.METHOD_GET, GlobalState.selected_station_name
	)

func clear_removed_trips():
	for tripId in data_container.current_arrivals:
		var arrival: Arrival = data_container.current_arrivals[tripId]
		if arrival.update_cycle_flag == false:
			get_node(arrival.ui_item).queue_free()
			data_container.current_arrivals.erase(tripId)

func start_if_ready():
	if GlobalState.display_state == GlobalState.DisplayState.READY:
		data_timer.start()
		do_data_refresh()

func _ready() -> void:
	start_if_ready()
	GlobalState.display_state_changed.connect(start_if_ready)

func _on_oba_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var arrivals = JSON.parse_string(body.get_string_from_utf8())
		if arrivals == null: return #TODO: handle condition where arrival data is missing
		
		for arrival in arrivals:
			if arrival['distanceFromStop'] < 0: continue
			
			var this_arrival: Arrival = data_container.current_arrivals.get_or_add(arrival['tripId'], Arrival.new())
			
			this_arrival.line_number = arrival['routeShortName'].split(" ")[0]
			this_arrival.line_color = Color(GlobalState.route_metadata[arrival['routeId']]['color'])
			this_arrival.text_color = Color(GlobalState.route_metadata[arrival['routeId']]['text_color'])
			
			this_arrival.headsign_text = arrival['tripHeadsign']
			this_arrival.is_realtime = arrival['predictedArrivalTime'] != null and arrival['predictedArrivalTime'] != 0
			this_arrival.arrival_timestamp = (arrival['predictedArrivalTime' if this_arrival.is_realtime else 'scheduledArrivalTime']) / 1000
			this_arrival.update_cycle_flag = true
		
		clear_removed_trips()
		data_container.data_update_finished.emit()
