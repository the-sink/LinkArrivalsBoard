extends Label

@export var no_service_indicator: Control
@export var no_service_anim: AnimationPlayer
@export var data_container: DataContainer

func _ready() -> void:
	GlobalState.station_name_changed.connect(update_label)
	update_label(GlobalState.selected_station_name)
	
	data_container.data_update_finished.connect(update_no_service_indicator)

func update_no_service_indicator() -> void:
	no_service_indicator.visible = data_container.current_service_alerts['no_service']
	if no_service_indicator.visible: no_service_anim.play("WarningIconFade")
	else: no_service_anim.stop()

func update_label(new_name: String) -> void:
	text = new_name
