@tool
extends Control

const VERSION: String = "1.3"

const CLICK_DELAY: float = 0.5

@onready var major_spin: SpinBox = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Major/SpinBox
@onready var minor_spin: SpinBox = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Minor/SpinBox
@onready var patch_spin: SpinBox = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Patch/SpinBox
@onready var version_label: Label = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/VersionLabel
@onready var auto_update_check: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/CheckBox
@onready var auto_commit_check: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/CheckBox2
@onready var commit_button: Button = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Button
@onready var commit_message: TextEdit = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/TextEdit
@onready var commit_label: Label = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Label
@onready var reset_button: Button = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Button2

var config_file: ConfigFile = null
var config_path: String = "res://addons/version_control/version_config.cfg"

var version: Dictionary = {"major": 0, "minor": 0, "patch": 0}
var last_commit: String = "None"

var timer: Timer = null
var clicked: bool = false

func _ready() -> void:
	timer = Timer.new()
	timer.set_one_shot(true)
	add_child(timer)
	_connect_signals()
	config_file = ConfigFile.new()
	_load_config()
	_update_version_from_project()
	if auto_update_check.is_pressed():
		_auto_increment_patch()


func _exit_tree() -> void:
	if auto_commit_check.is_pressed():
		_commit_to_git("auto commit")


func _connect_signals() -> void:
	major_spin.value_changed.connect(_on_version_changed.bind("major"))
	minor_spin.value_changed.connect(_on_version_changed.bind("minor"))
	patch_spin.value_changed.connect(_on_version_changed.bind("patch"))
	commit_button.pressed.connect(_on_commit_pressed)
	auto_update_check.toggled.connect(_on_auto_check_toggled)
	auto_commit_check.toggled.connect(_on_auto_check_toggled)
	reset_button.pressed.connect(_on_reset_pressed)
	timer.timeout.connect(_on_timer_timeout)


func _load_config() -> void:
	var err = config_file.load(config_path)
	if err == OK and config_file.has_section("config"):
		auto_update_check.set_pressed_no_signal(config_file.get_value("config", "auto_patch", false))
		auto_commit_check.set_pressed_no_signal(config_file.get_value("config", "auto_commit", false))
		last_commit = config_file.get_value("config", "last_commit", last_commit)
		commit_label.set_text("Last Commit: %s" % last_commit)
		print("loaded version control config")
	else:
		_save_config()


func _save_config() -> void:
	config_file.set_value("config", "auto_patch", auto_update_check.is_pressed())
	config_file.set_value("config", "auto_commit", auto_commit_check.is_pressed())
	config_file.set_value("config", "last_commit", last_commit)
	var err = config_file.save(config_path)
	if not err == OK:
		push_error("Failed to save config")
		return
	print("Saved version control config")


func _clear_config() -> void:
	config_file.clear()
	var err = config_file.save(config_path)
	if not err == OK:
		push_error("Failed to save config")
		return
	print("Cleared version control config")


func _update_version_from_project() -> void:
	var project_settings = _get_project_settings()
	var version_parts = project_settings.version.split(".")
	if not version_parts.size() == 3:
		push_error("Failed to get project version")
		return
	version.major = version_parts[0].to_int()
	version.minor = version_parts[1].to_int()
	version.patch = version_parts[2].to_int()
	_update_spin_boxes()


func _save_version_to_project() -> void:
	ProjectSettings.set_setting("application/config/version", _get_version_string())
	ProjectSettings.save()


func _get_project_settings() -> Dictionary:
	var project_name = ProjectSettings.get_setting("application/config/name")
	var project_version = ProjectSettings.get_setting("application/config/version")
	return {"name": project_name, "version": project_version}


func _commit_to_git(commit_msg: String) -> void:
	var old_commit = last_commit
	last_commit = _get_version_string()
	_save_config()
	EditorInterface.save_all_scenes()
	var output = []
	var exit_code = OS.execute("git", ["add", "."], output)
	if exit_code != 0:
		push_error("Failed to stage files with git")
		return
	exit_code = OS.execute("git", ["commit", "-m", _get_version_string(), "-m", commit_msg], output)
	if exit_code == 0:
		commit_label.set_text("Last Commit: %s" % last_commit)
		commit_message.clear()
		print("Successfully committed changes: ", commit_msg)
		print("Use GitHub Desktop or alternative to push changes")
	else:
		last_commit = old_commit
		_save_config()
		push_error("Failed to commit changes: " + str(output))


func _get_version_string() -> String:
	return "%d.%d.%d" % [version.major, version.minor, version.patch]


func _get_last_commit_dict() -> Dictionary:
	var array = last_commit.split(".")
	if not array.size() == 3:
		return version
	return {"major": array[0].to_int(), "minor": array[1].to_int(), "patch": array[2].to_int()}


func _is_newer() -> bool:
	if last_commit == "None":
		return true
	var last_version = _get_last_commit_dict()
	if version.major > last_version.major:
		return true
	elif version.major < last_version.major:
		return false
	if version.minor > last_version.minor:
		return true
	elif version.minor < last_version.minor:
		return false
	if version.patch > last_version.patch:
		return true
	return false


func _increment_major() -> void:
	version.major += 1
	version.minor = 0
	version.patch = 0
	_update_spin_boxes()


func _increment_minor() -> void:
	version.minor += 1
	version.patch = 0
	_update_spin_boxes()


func _increment_patch() -> void:
	version.patch += 1
	_update_spin_boxes()


func _auto_increment_patch() -> void:
	_increment_patch()
	_save_version_to_project()


func _update_spin_boxes() -> void:
	major_spin.set_value_no_signal(version.major)
	minor_spin.set_value_no_signal(version.minor)
	patch_spin.set_value_no_signal(version.patch)
	version_label.set_text("Version: %s" % _get_version_string())


func _reset() -> void:
	print("Resetting version control...")
	print("Current version: %s, Last commit: %s" % [_get_version_string(), last_commit])
	version = {"major": 0, "minor": 0, "patch": 0}
	last_commit = "None"
	commit_label.set_text("Last Commit: %s" % last_commit)
	_update_spin_boxes()
	commit_message.clear()
	auto_update_check.set_pressed_no_signal(false)
	auto_commit_check.set_pressed_no_signal(false)
	_save_version_to_project()
	_clear_config()
	print("Reset version control")


func _on_timer_timeout() -> void:
	clicked = false


func _on_version_changed(value: float, type: String) -> void:
	match type:
		"major":
			if value > version.major:
				_increment_major()
			else:
				version.major = value
				_update_spin_boxes()
		"minor":
			if value > version.minor:
				_increment_minor()
			else:
				version.minor = value
				_update_spin_boxes()
		"patch":
			if value > version.patch:
				_increment_patch()
			else:
				version.patch = value
				_update_spin_boxes()
	_save_version_to_project()


func _on_commit_pressed() -> void:
	if not clicked:
		print("Commit pressed, double press to commit")
		timer.start(CLICK_DELAY)
		clicked = true
		return
	if _is_newer():
		_commit_to_git(commit_message.get_text())
	else:
		push_error("Version must be newer than last commit")


func _on_auto_check_toggled(_is_toggled: bool) -> void:
	await get_tree().process_frame
	_save_config()


func _on_reset_pressed() -> void:
	if not clicked:
		print("Reset pressed, double press to reset")
		timer.start(CLICK_DELAY)
		clicked = true
		return
	_reset()
