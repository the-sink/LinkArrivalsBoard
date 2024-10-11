extends HBoxContainer

@onready var line_number_panel: Panel = $LineNumber
@onready var line_number_label: Label = $LineNumber/Label
@onready var headsign_label: Label = $Headsign
@onready var realtime_icon: Control = $Realtime
@onready var realtime_anim: AnimationPlayer = $Realtime/AnimationPlayer
@onready var arrival_time_label: Label = $ArrivalTime

@export var line_number: String = "0":
	set(val):
		line_number = val
		line_number_label.text = line_number
@export var line_color: Color = Color.BLACK:
	set(val):
		line_color = val
		line_number_panel.self_modulate = line_color
@export var text_color: Color = Color.WHITE:
	set(val):
		text_color = val
		line_number_label.self_modulate = text_color
@export var headsign_text: String = "Unknown":
	set(val):
		if val.begins_with("Lynnwood"): val = "Lynnwood" # keep only "Lynnwood", like the actual signs do... not sure if the API has this conversion anywhere
		headsign_text = val
		headsign_label.text = headsign_text
@export var is_realtime: bool = false:
	set(val):
		is_realtime = val
		realtime_icon.visible = is_realtime
		if realtime_icon.visible: realtime_anim.play("SignalEffect")
		else: realtime_anim.stop()
@export var arrival_time_minutes: int = 0:
	set(val):
		arrival_time_minutes = val
		arrival_time_label.text = str(arrival_time_minutes) + " min" if arrival_time_minutes > 0 else "Now"
