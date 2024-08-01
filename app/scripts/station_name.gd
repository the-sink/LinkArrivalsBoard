extends Label


func _ready() -> void:
	GlobalState.station_name_changed.connect(update_label)
	update_label(GlobalState.selected_station_name)

func update_label(new_name: String):
	text = new_name
