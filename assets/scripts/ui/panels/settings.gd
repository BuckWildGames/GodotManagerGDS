extends UIState

const UPDATER: Script = preload("res://assets/scripts/other/updater.gd")
const PATH_BUTTON: PackedScene = preload("res://assets/scenes/components/settings/path_button.tscn")

@onready var engine_button: Button = $SettingsButtonPanel/SettingsButtons/EngineButton
@onready var projects_button: Button = $SettingsButtonPanel/SettingsButtons/ProjectsButton
@onready var other_button: Button = $SettingsButtonPanel/SettingsButtons/OtherButton

@onready var engine_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer
@onready var projects_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/ProjectsContainer
@onready var other_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/OtherContainer

@onready var path_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/ProjectsContainer/ProjectLocationsBox/PathContainer
@onready var template_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/ProjectsContainer/ProjectTemplatesBox/PathContainer

@onready var install_path: LineEdit = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/InstallPathInputBox/InstallPath
@onready var fetch_times_button: OptionButton = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/FetchEngineBox/FetchTimes
@onready var latest_version_button: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/FetchEngineBox/LatestVersion
@onready var run_console_button: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/DefaultEngineInputBox/RunConsole
@onready var default_engine_button: OptionButton = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/DefaultEngineInputBox/DefaultEngine
@onready var select_folder_dialog: FileDialog = $SelectFolderDialog

@onready var skip_intro_button: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/OtherContainer/SkipIntro
@onready var hide_minimize_button: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/OtherContainer/TopBarBox/Button/HideMinimize
@onready var hide_maximize_button: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/OtherContainer/TopBarBox/Button/HideMaximize
@onready var start_admin_button: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/OtherContainer/AdminBox/Buttons/StartAdminButton

@onready var default_project_view_button: OptionButton = $PanelContainer/MarginContainer/ScrollContainer/ProjectsContainer/DefaulViewBox/DefaultProjectView
@onready var quit_edit_button: CheckBox = $PanelContainer/MarginContainer/ScrollContainer/ProjectsContainer/DefaulViewBox/QuitEdit


var path: String = ""
var is_project_path: bool = false
var is_template: bool = false


func _ready() -> void:
	_change_tab(1)
	_load_settings(true)
	var updater = UPDATER.new()
	SettingsManager.add_child(updater)
	updater.check_for_update()


func enter(previous : String):
	super.enter(previous)
	_get_engine_versions()
	_load_settings()


func exit() -> void:
	ConfigManager.force_save()


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
			is_template = false
		"browse_template_project":
			select_folder_dialog.show()
			is_project_path = true
			is_template = true
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
		"run_console":
			ConfigManager.set_config_data("settings", "run_console", toggled_on)
		"quit_edit":
			ConfigManager.set_config_data("settings", "quit_edit", toggled_on)
		"intro_video":
			ConfigManager.set_config_data("settings", "intro_video", toggled_on)
		"hide_minimize":
			ConfigManager.set_config_data("settings", "hide_minimize", toggled_on)
		"hide_maximize":
			ConfigManager.set_config_data("settings", "hide_maximize", toggled_on)
		"run_admin":
			ConfigManager.set_config_data("settings", "run_admin", toggled_on)


func value_received(value: Variant, button: String) -> void:
	match button:
		"path_selected":
			if is_project_path:
				_add_project_path(str(value), is_template)
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


func _add_project_path(new_path: String, template: bool = false) -> void:
	var setting = "project_folders"
	if template:
		setting = "template_projects"
	var i = PATH_BUTTON.instantiate()
	if template:
		template_container.add_child(i)
	else:
		path_container.add_child(i)
	i.set_text(new_path)
	i.pressed.connect(_delete_path_pressed.bind(new_path, i, template))
	var folders = ConfigManager.get_config_data("settings", setting)
	if folders != null:
		if not folders.has(new_path):
			folders.append(new_path)
	else:
		folders = [new_path]
	ConfigManager.set_config_data("settings", setting, folders)


func _delete_path_pressed(old_path: String, node: Node, template: bool) -> void:
	var setting = "project_folders"
	if template:
		setting = "template_projects"
	var folders = ConfigManager.get_config_data("settings", setting)
	if folders != null:
		if folders.has(old_path):
			folders.erase(old_path)
			ConfigManager.set_config_data("settings", setting, folders)
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
	default_engine_button.add_item("None")
	var versions = EngineManager.get_installed_versions()
	for version in versions:
		default_engine_button.add_item(version)
	default_engine_button.select(0)


func _clear_path_container(template: bool = false) -> void:
	var container = path_container
	if template:
		container = template_container
	for child in container.get_children():
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
	if settings.has("run_console"):
		run_console_button.set_pressed_no_signal(settings["run_console"])
	if settings.has("intro_video"):
		skip_intro_button.set_pressed_no_signal(settings["intro_video"])
	if settings.has("hide_minimize"):
		hide_minimize_button.set_pressed_no_signal(settings["hide_minimize"])
	if settings.has("hide_maximize"):
		hide_maximize_button.set_pressed_no_signal(settings["hide_maximize"])
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
	if settings.has("template_projects"):
		_clear_path_container(true)
		for folder in settings["template_projects"]:
			_add_project_path(folder, true)
