extends UIState

@onready var version_label: Label = $MarginContainer/TitleBox/VersionLabel

@onready var projects_button: Button = $MarginContainer/MainButtons/ProjectsButton
@onready var engines_button: Button = $MarginContainer/MainButtons/EnginesButton
@onready var asset_lib_button: Button = $MarginContainer/MainButtons/AssetLibButton
@onready var settings_button: Button = $MarginContainer/MainButtons/SettingsButton


func enter(previous : String):
	super.enter(previous)
	version_label.set_text(ConfigManager.get_version())
	call_deferred("transition" , "projects")
	_reset_buttons(1)


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


func button_toggled(_toggled_on: bool, button: String) -> void:
	match button:
		"projects":
			transition("projects")
			_reset_buttons(1)
		"engines":
			transition("engines")
			_reset_buttons(2)
		"assets":
			_reset_buttons(3)
		"settings":
			_reset_buttons(4)


func _reset_buttons(ignore: int) -> void:
	projects_button.set_pressed_no_signal(ignore == 1)
	engines_button.set_pressed_no_signal(ignore == 2)
	asset_lib_button.set_pressed_no_signal(ignore == 3)
	settings_button.set_pressed_no_signal(ignore == 4)
