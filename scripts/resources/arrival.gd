class_name Arrival
extends Resource

@export var line_number: String
@export var line_color: Color = Color.BLACK
@export var headsign_text: String
@export var is_realtime: bool = false
@export var arrival_timestamp: int
@export var ui_item: NodePath

@export var update_cycle_flag: bool = false
