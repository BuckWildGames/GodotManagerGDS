extends UIState

const PATH_BUTTON: PackedScene = preload("res://assets/scenes/components/settings/path_button.tscn")

@onready var engine_button: Button = $SettingsButtonPanel/SettingsButtons/EngineButton
@onready var projects_button: Button = $SettingsButtonPanel/SettingsButtons/ProjectsButton
@onready var other_button: Button = $SettingsButtonPanel/SettingsButtons/OtherButton

@onready var engine_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer
@onready var projects_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/ProjectsContainer
@onready var other_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/OtherContainer

@onready var path_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/ProjectsContainer/ProjectLocationsBox/PathContainer

@onready var install_path: LineEdit = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/InstallPathInputBox/InstallPath
@onready var fetch_times_button: OptionButton = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/FetchEngineBox/FetchTimes
@onready var latest_version_button: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/FetchEngineBox/LatestVersion
@onready var default_engine_button: OptionButton = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/DefaultEngineInputBox/DefaultEngine
@onready var select_folder_dialog: FileDialog = $SelectFolderDialog

@onready var skip_intro_button: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/OtherContainer/SkipIntro
@onready var start_admin_button: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/OtherContainer/AdminBox/Buttons/StartAdminButton

@onready var default_project_view_button: OptionButton = $PanelContainer/MarginContainer/ScrollContainer/ProjectsContainer/DefaulViewBox/DefaultProjectView
@onready var quit_edit_button: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/ProjectsContainer/DefaulViewBox/QuitEdit


var path: String = ""
var is_project_path: bool = false


func _ready() -> void:
	_change_tab(1)
	_load_settings(true)


func enter(previous : String):
	super.enter(previous)
	_get_engine_versions()
	_load_settings()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		install_path.call_deferred("release_focus")


func button_pressed(button: String) -> void:
	match button:
		"browse_install":
			select_folder_dialog.show()
			is_project_path = false
		"browse_project":
			select_folder_dialog.show()
			is_project_path = true
		"open_install":
			SettingsManager.open_folder(path)
		"clear_data":
			NotificationManager.show_prompt("Clear Project Data?\nThis Will Remove All Projects And Groups.", ["No", "Yes"], self, "_on_clear")
		"run_admin":
			if SettingsManager.run_as_admin():
				get_tree().quit()
			else:
				NotificationManager.show_prompt("Failed To Run As Admin", ["OK"], null, "")


func button_toggled(toggled_on: bool, button: String) -> void:
	match button:
		"engine":
			_change_tab(1)
		"projects":
			_change_tab(2)
		"other":
			_change_tab(3)
		"latest_version":
			ConfigManager.set_config_data("settings", "latest_version", toggled_on)
		"quit_edit":
			ConfigManager.set_config_data("settings", "quit_edit", toggled_on)
		"intro_video":
			ConfigManager.set_config_data("settings", "intro_video", toggled_on)
		"run_admin":
			ConfigManager.set_config_data("settings", "run_admin", toggled_on)


func value_received(value: Variant, button: String) -> void:
	match button:
		"path_selected":
			if is_project_path:
				_add_project_path(str(value))
			else:
				path = str(value)
				install_path.set_text(path)
				install_path.set_caret_column(install_path.get_text().length())
				ConfigManager.set_config_data("settings", "install_path", path)
		"path_changed":
			path = str(value)
		"path_submitted":
			path = str(value)
			install_path.set_text(path)
			install_path.set_caret_column(install_path.get_text().length())
			ConfigManager.set_config_data("settings", "install_path", path)
		"fetch_time":
			ConfigManager.set_config_data("settings", "fetch_time", int(value))
		"default_engine":
			ConfigManager.set_config_data("settings", "default_engine", default_engine_button.get_item_text(int(value)))
		"default_view":
			ConfigManager.set_config_data("settings", "default_view", int(value))


func _add_project_path(new_path: String) -> void:
	var i = PATH_BUTTON.instantiate()
	path_container.add_child(i)
	i.set_text(new_path)
	i.pressed.connect(_delete_path_pressed.bind(new_path, i))
	var folders = ConfigManager.get_config_data("settings", "project_folders")
	if folders != null:
		if not folders.has(new_path):
			folders.append(new_path)
	else:
		folders = [new_path]
	ConfigManager.set_config_data("settings", "project_folders", folders)


func _delete_path_pressed(old_path: String, node: Node) -> void:
	var folders = ConfigManager.get_config_data("settings", "project_folders")
	if folders != null:
		if folders.has(old_path):
			folders.erase(old_path)
			ConfigManager.set_config_data("settings", "project_folders", folders)
	node.queue_free()


func _change_tab(tab: int) -> void:
	engine_button.set_pressed_no_signal(tab == 1)
	engine_container.set_visible(tab == 1)
	projects_button.set_pressed_no_signal(tab == 2)
	projects_container.set_visible(tab == 2)
	other_button.set_pressed_no_signal(tab == 3)
	other_container.set_visible(tab == 3)


func _get_engine_versions() -> void:
	default_engine_button.clear()
	var versions = EngineManager.get_installed_versions()
	for version in versions:
		default_engine_button.add_item(version)


func _clear_path_container() -> void:
	for child in path_container.get_children():
		child.queue_free()


func _on_clear(option: String) -> void:
	if option == "Yes":
		FileManager.delete_file("user://", "data.json", false)
		ProjectManager.reset_all()


func _load_settings(startup: bool = false) -> void:
	var settings = ConfigManager.get_config_category("settings")
	if settings.is_empty():
		SettingsManager.init_settings()
		return
	if settings.has("run_admin"):
		start_admin_button.set_pressed_no_signal(settings["run_admin"])
		if startup and settings["run_admin"]:
			if SettingsManager.run_as_admin():
				get_tree().quit()
	if settings.has("install_path"):
		path = settings["install_path"]
		install_path.set_text(path)
	if settings.has("fetch_time"):
		fetch_times_button.select(settings["fetch_time"])
	if settings.has("latest_version"):
		latest_version_button.set_pressed_no_signal(settings["latest_version"])
	if settings.has("intro_video"):
		skip_intro_button.set_pressed_no_signal(settings["intro_video"])
	if settings.has("quit_edit"):
		quit_edit_button.set_pressed_no_signal(settings["quit_edit"])
	if settings.has("default_engine"):
		for index in default_engine_button.get_item_count():
			if default_engine_button.get_item_text(index) == settings["default_engine"]:
				default_engine_button.select(index)
	if settings.has("default_view"):
		default_project_view_button.select(settings["default_view"])
	if settings.has("project_folders"):
		_clear_path_container()
		for folder in settings["project_folders"]:
			_add_project_path(folder)
