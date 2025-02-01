extends UIState

@onready var version_label: Label = $MarginContainer/TitleBox/VersionLabel


func enter(previous : String):
	super.enter(previous)
	version_label.set_text(ConfigManager.get_version())
	call_deferred("transition" , "projects")


func button_pressed(button: String) -> void:
	match button:
		"hide":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		"min_max":
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"close":
			get_tree().quit()
