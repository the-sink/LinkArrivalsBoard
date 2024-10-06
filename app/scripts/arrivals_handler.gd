extends ScrollContainer

@export var data_container: DataContainer
@export var arrivals_list_container: VBoxContainer
@export var time_delta_timer: Timer

@export_category("Status Nodes")
@export var no_arrivals_text: Label
@export var loading_spinner: TextureRect
@export var spinner_anim: AnimationPlayer

@onready var arrival_template := preload("res://arrival_template.tscn")

func _ready() -> void:
	loading_spinner.visible = true
	spinner_anim.play("Spin")
	
	data_container.data_update_finished.connect(_on_data_update_finished)

	#var service_alerts = data_container.current_service_alerts
	#var relevant_alerts = service_alerts['relevant_alerts']
	#
	#service_alert_container.visible = len(relevant_alerts) > 0
	#if service_alert_container.visible:
		#service_alert_text.text = relevant_alerts[0]['text']

func do_time_delta_refresh() -> void:
	var current_time: int = Time.get_unix_time_from_system()
	var sort_array: Array[int] = []
	
	for arrival in data_container.current_arrivals.values():
		var ui_item: Control = get_node(arrival.ui_item)
		
		var arrival_time: int = arrival.arrival_timestamp
		var time_delta: int = arrival_time - current_time
		var time_delta_minutes: int = time_delta / 60
		
		sort_array.append(time_delta_minutes)
		ui_item.arrival_time_minutes = time_delta_minutes
	
	sort_array.sort()
	
	for arrival in data_container.current_arrivals.values():
		var ui_item: Control = get_node(arrival.ui_item)
		var pos: int = sort_array.find(ui_item.arrival_time_minutes)
		arrivals_list_container.move_child(ui_item, pos)

func _on_data_update_finished() -> void:
	loading_spinner.visible = false
	spinner_anim.active = false
	visible = not data_container.current_service_alerts['no_service']
	
	var arrivals = data_container.current_arrivals
	
	no_arrivals_text.visible = arrivals.size() < 1
	for arrival in arrivals:
		if arrival['distanceFromStop'] < 0: continue
		
		var this_arrival: Arrival = arrivals.get_or_add(arrival['tripId'], Arrival.new())
		var ui_item: Control
		
		if this_arrival.ui_item.is_empty():
			ui_item = arrival_template.instantiate()
			arrivals_list_container.add_child(ui_item)
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

	do_time_delta_refresh()
