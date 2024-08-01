extends ColorRect

@export var open: bool = false:
	set(val):
		if val == open: return
		open = val
		
		var tween := get_tree().create_tween()
		tween.tween_property(self, "offset_left", 0 if open else -250, 0.2)
		
		if open:
			$ShutdownButton.grab_focus()
