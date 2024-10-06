extends ColorRect

const SEP_STRING: String = "          "

@export var data_container: DataContainer
@export var message_scroll_container: ScrollContainer
@export var message_label: Label
@export var text_fade_anim: AnimationPlayer

var scroll_tween: Tween

func _ready() -> void:
	data_container.data_update_finished.connect(_on_data_update_finished)

func do_scroll() -> void:
	if scroll_tween:
		scroll_tween.kill()
	if not visible: return
	var max_h_scroll: float = message_label.label_settings.font.get_string_size(message_label.text).x
	scroll_tween = create_tween()
	scroll_tween.tween_interval(3.0)
	scroll_tween.tween_property(message_scroll_container, "scroll_horizontal", max_h_scroll, max_h_scroll / 100.0)
	scroll_tween.tween_interval(3.0)
	scroll_tween.tween_callback(func(): text_fade_anim.play("Fade"))

func _on_data_update_finished() -> void:
	var service_alerts = data_container.current_service_alerts
	var relevant_alerts = service_alerts['relevant_alerts']
	print(relevant_alerts)
	
	visible = len(relevant_alerts) > 0

	if visible:
		var full_message: String = " "
		for alert in relevant_alerts:
			full_message += alert['text'] + SEP_STRING
		full_message = full_message.rstrip(SEP_STRING)
		message_label.text = full_message + " "
		if not (scroll_tween and scroll_tween.is_running()): do_scroll()
