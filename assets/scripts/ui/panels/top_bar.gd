extends UIState

@onready var version_label: Label = $Bar/MarginContainer/TitleBox/VersionLabel

@onready var projects_button: Button = $Bar/MarginContainer/MainButtons/ProjectsButton
@onready var engines_button: Button = $Bar/MarginContainer/MainButtons/EnginesButton
@onready var asset_lib_button: Button = $Bar/MarginContainer/MainButtons/AssetLibButton
@onready var settings_button: Button = $Bar/MarginContainer/MainButtons/SettingsButton
@onready var resize_button: Button = $ResizeButton
@onready var hide_button: Button = $Bar/MarginContainer/WindowButtons/HideButton
@onready var min_max_button: Button = $Bar/MarginContainer/WindowButtons/MinMaxButton
@onready var delay_timer: Timer = $DelayTimer

var is_pressed: bool = false
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var resizing: bool = false
var start_mouse_pos: Vector2 = Vector2.ZERO
var start_window_size: Vector2 = Vector2.ZERO
var top_size: float = 56.0
var click_delay: float = 0.1

func enter(previous : String):
	super.enter(previous)
	version_label.set_text(ConfigManager.get_version())
	call_deferred("transition" , "projects")
	_reset_buttons(1)
	_set_min_max()


func button_pressed(button: String) -> void:
	match button:
		"hide":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		"min_max":
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
				resize_button.set_visible(false)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				resize_button.set_visible(true)
		"close":
			get_tree().quit()
		"resize":
			resizing = true
			start_mouse_pos = DisplayServer.mouse_get_position()
			start_window_size = DisplayServer.window_get_size()


func button_toggled(_toggled_on: bool, button: String) -> void:
	match button:
		"projects":
			transition("projects")
			_reset_buttons(1)
		"engines":
			transition("engines")
			_reset_buttons(2)
		"assets":
			transition("assets")
			_reset_buttons(3)
		"settings":
			transition("settings")
			_reset_buttons(4)


func _reset_buttons(ignore: int) -> void:
	_set_min_max()
	projects_button.set_pressed_no_signal(ignore == 1)
	engines_button.set_pressed_no_signal(ignore == 2)
	asset_lib_button.set_pressed_no_signal(ignore == 3)
	settings_button.set_pressed_no_signal(ignore == 4)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_home"):
		var screen_size = DisplayServer.screen_get_size()
		var window_size = DisplayServer.window_get_size()
		var center_position = (screen_size - window_size) / 2
		DisplayServer.window_set_position(center_position)
	if event is InputEventMouseButton:
		if event.is_pressed() and event.get_button_index() == MOUSE_BUTTON_LEFT:
			if event.get_position().y < top_size:
				is_pressed = true
				delay_timer.start(click_delay)
				drag_offset = event.get_position()
		elif not event.is_pressed():
			is_pressed = false
			is_dragging = false
			resizing = false
	elif event is InputEventMouseMotion:
		if is_dragging:
			var new_position = DisplayServer.window_get_position() + Vector2i(event.get_relative().x, event.get_relative().y)
			DisplayServer.window_set_position(new_position)
		elif resizing:
			var mouse_position = DisplayServer.mouse_get_position()
			var new_size = start_window_size + (Vector2(mouse_position.x, mouse_position.y)  - start_mouse_pos)
			DisplayServer.window_set_size(new_size.abs())


func _set_min_max() -> void:
	var hide_minimize = ConfigManager.get_config_data("settings", "hide_minimize")
	var hide_maximize = ConfigManager.get_config_data("settings", "hide_maximize")
	if hide_minimize != null:
		hide_button.set_visible(!hide_minimize)
	if hide_maximize != null:
		min_max_button.set_visible(!hide_maximize)


func _on_delay_timer_timeout() -> void:
	if is_pressed:
		is_dragging = true
