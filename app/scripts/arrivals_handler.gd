extends ScrollContainer

@export var oba_request: HTTPRequest
@export var container: VBoxContainer
@export var no_arrivals_text: Label

@export_category("Timers")
@export var time_delta_timer: Timer
@export var data_timer: Timer

@export_category("Service Alerts Content")
@export var service_alert_container: ColorRect
@export var service_alert_text: Label
@export var no_service_warning: ColorRect
@export var no_service_anim: AnimationPlayer

@onready var arrival_template := preload("res://arrival_template.tscn")

#TODO: Data refresh error handling

func start_if_ready():
	if GlobalState.display_state == GlobalState.DisplayState.READY:
		time_delta_timer.start()
		data_timer.start()
		do_data_refresh()

func _ready() -> void:
	GlobalState.current_arrivals = {}
	start_if_ready()
	GlobalState.display_state_changed.connect(start_if_ready)

func clear_removed_trips():
	for tripId in GlobalState.current_arrivals:
		var arrival: Arrival = GlobalState.current_arrivals[tripId]
		if arrival.update_cycle_flag == false:
			get_node(arrival.ui_item).queue_free()
			GlobalState.current_arrivals.erase(tripId)
	
	no_arrivals_text.visible = GlobalState.current_arrivals.size() < 1

func do_data_refresh() -> void:
	for arrival in GlobalState.current_arrivals.values():
		arrival.update_cycle_flag = false
		
	oba_request.request(GlobalState.proxy_server_base_url + "/arrivals/" + GlobalState.selected_route_id,
	["Content-Type: application/json"], HTTPClient.METHOD_GET, GlobalState.selected_station_name
	)
	
	var service_alerts = await ServiceAlerts.get_relevant_alerts()
	var relevant_alerts = service_alerts['relevant_alerts']
	visible = not service_alerts['no_service']
	no_service_warning.visible = not visible
	if no_service_warning.visible: no_service_anim.play("WarningIconFade")
	else: no_service_anim.stop()
	
	service_alert_container.visible = len(relevant_alerts) > 0
	if service_alert_container.visible:
		service_alert_text.text = relevant_alerts[0]['text']

func do_time_delta_refresh() -> void:
	var current_time: int = Time.get_unix_time_from_system()
	var sort_array: Array[int] = []
	
	for arrival in GlobalState.current_arrivals.values():
		var ui_item: Control = get_node(arrival.ui_item)
		
		var arrival_time: int = arrival.arrival_timestamp
		var time_delta: int = arrival_time - current_time
		var time_delta_minutes: int = time_delta / 60
		
		sort_array.append(time_delta_minutes)
		ui_item.arrival_time_minutes = time_delta_minutes
	
	sort_array.sort()
	
	for arrival in GlobalState.current_arrivals.values():
		var ui_item: Control = get_node(arrival.ui_item)
		var pos: int = sort_array.find(ui_item.arrival_time_minutes)
		container.move_child(ui_item, sort_array.find(ui_item.arrival_time_minutes))

func _on_oba_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var arrivals = JSON.parse_string(body.get_string_from_utf8())
		if arrivals == null: return
		
		for arrival in arrivals:
			if arrival['distanceFromStop'] < 0: continue
			
			var this_arrival: Arrival = GlobalState.current_arrivals.get_or_add(arrival['tripId'], Arrival.new())
			var ui_item: Control
			
			if this_arrival.ui_item.is_empty():
				ui_item = arrival_template.instantiate()
				container.add_child(ui_item)
				await get_tree().process_frame
				this_arrival.ui_item = ui_item.get_path()
			else:
				ui_item = get_node(this_arrival.ui_item)
			
			this_arrival.line_number = arrival['routeShortName'].split(" ")[0]
			this_arrival.line_color = Color(GlobalState.route_metadata[arrival['routeId']]['color'])
			this_arrival.text_color = Color(GlobalState.route_metadata[arrival['routeId']]['text_color'])
			
			this_arrival.headsign_text = arrival['tripHeadsign']
			this_arrival.is_realtime = arrival['predictedArrivalTime'] != null and arrival['predictedArrivalTime'] != 0
			this_arrival.arrival_timestamp = (arrival['predictedArrivalTime' if this_arrival.is_realtime else 'scheduledArrivalTime']) / 1000
			this_arrival.update_cycle_flag = true
			
			ui_item.line_number = this_arrival.line_number
			ui_item.line_color = this_arrival.line_color
			ui_item.text_color = this_arrival.text_color
			ui_item.headsign_text = this_arrival.headsign_text
			ui_item.is_realtime = this_arrival.is_realtime
	
	clear_removed_trips()
	do_time_delta_refresh()
