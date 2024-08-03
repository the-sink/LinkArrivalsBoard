extends Button

@export var short_name: String = ""
@export var long_name: String = ""
@export var color: Color = Color.WHITE

func update_displayed_info() -> void:
	$Information.text = "[b]" + short_name + "[/b]\n" + long_name
	$ColorRect.color = color
