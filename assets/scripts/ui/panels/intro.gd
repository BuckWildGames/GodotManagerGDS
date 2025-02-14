extends UIState


func enter(previous : String):
	super.enter(previous)
	var skip = ConfigManager.get_config_data("settings", "intro_video")
	if skip:
		call_deferred("transition" , "topbar")
