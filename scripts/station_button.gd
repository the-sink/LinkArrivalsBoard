extends Button

@export var station_name: String = "":
	set(val):
		station_name = val
		name = station_name
		text = station_name

func _on_pressed() -> void:
	GlobalState.selected_station_name = station_name
	get_tree().reload_current_scene()
