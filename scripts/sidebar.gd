extends ColorRect

@export var open: bool = false:
	set(val):
		if GlobalState.display_state != GlobalState.DisplayState.RUNNING: return
		if val == open: return
		open = val
		
		var tween := get_tree().create_tween()
		tween.tween_property(self, "offset_left", 0 if open else -250, 0.2)
