extends Label

func update_clock() -> void:
	var time_dict := Time.get_time_dict_from_system()
	var hour = time_dict['hour'] % 12
	var minute = time_dict['minute']
	var pm = time_dict['hour'] > 11
	
	if hour == 0: hour = 12
	text = "%d:%02d %s" % [hour, minute, "PM" if pm else "AM"]

func _ready() -> void:
	update_clock()
