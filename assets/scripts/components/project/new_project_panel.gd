extends Control

const PATH_BAD: CompressedTexture2D = preload("res://assets/icons/icon_status_error.svg")
const PATH_NOT_OK: CompressedTexture2D = preload("res://assets/icons/icon_status_warning.svg")
const PATH_OK: CompressedTexture2D = preload("res://assets/icons/icon_status_success.svg")


@onready var project_name: LineEdit = $MarginContainer/VBoxContainer/ProjectName
@onready var project_path: LineEdit = $MarginContainer/VBoxContainer/ProjectPathInputBox/ProjectPath
@onready var path_dialog: FileDialog = $PathDialog
@onready var path_info: TextureRect = $MarginContainer/VBoxContainer/ProjectPathInputBox/PathInfo
@onready var create_folder_button: CheckButton = $MarginContainer/VBoxContainer/ProjectPathBox/CreateFolderButton
@onready var version_control_button: CheckButton = $MarginContainer/VBoxContainer/VersionControlButton
@onready var engine_version_button: OptionButton = $MarginContainer/VBoxContainer/EngineVersionButton
@onready var engine_renderer_button: OptionButton = $MarginContainer/VBoxContainer/EngineRendererButton

var master: Control = null
var title: String = ""
var path: String = ""
var description: String = ""
var engine_version: String = ""

var renderer: String = ""
var create_folder: bool = true
var version_control: bool = true

var can_create: bool = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		project_name.call_deferred("release_focus")
		project_path.call_deferred("release_focus")


func setup(new_master: Control = null) -> void:
	if !new_master == null:
		master = new_master
	title = "New Project"
	path = "Unknown Path"
	project_path.set_text(path)
	description = "No Description"
	engine_version = ConfigManager.get_config_data("settings", "default_engine")
	_setup_engine_button()
	_setup_renderer_button()
	renderer = engine_renderer_button.get_item_text(0)
	engine_renderer_button.select(0)
	create_folder = true
	version_control = true
	create_folder_button.set_pressed_no_signal(true)
	version_control_button.set_pressed_no_signal(true)
	path_dialog.hide()
	get_parent().show()
	show()


func button_pressed(button: String) -> void:
	match button:
		"cancel":
			get_parent().hide()
			hide()
		"browse":
			path_dialog.show()
		"save":
			if not master:
				return
			if can_create and title != "":
				if ProjectManager.create_project_folder(title, description, path, engine_version, renderer, create_folder, version_control):
					master.create_project(title, description, path, "0.0.0", engine_version)
					get_parent().hide()
					hide()
					NotificationManager.notify("Project Created", 2.0, true)
					var index = EngineManager.get_version_index(engine_version)
					EngineManager.run_project_in_editor(index, path)
					var pos = ProjectManager.get_projects_dic().size() - 1
					ProjectManager.move_project_front(pos)
					NotificationManager.notify("Opening Editor", 2.0, true)
					var quit = ConfigManager.get_config_data("settings", "quit_edit")
					if quit:
						await get_tree().create_timer(2.0).timeout
						get_tree().quit()
				else:
					NotificationManager.notify("Failed To Create Project", 3.0, true)


func button_toggled(toggled_on: bool, button: String) -> void:
	match button:
		"create_folder":
			create_folder = toggled_on
			_check_path(true)
		"version_control":
			version_control = toggled_on


func value_received(value: Variant, button: String) -> void:
	match button:
		"title_changed":
			var old_title = title
			title = str(value)
			if create_folder:
				path = path.replace(_convert_title(old_title), _convert_title(title))
				project_path.set_text(path)
				project_path.set_caret_column(project_path.get_text().length())
		"path_selected":
			path = str(value)
			_check_path(true)
		"path_changed":
			path = str(value)
			_check_path(false)
		"path_submitted":
			path = str(value)
			_check_path(true)
			project_path.set_text(path)
			project_path.set_caret_column(project_path.get_text().length())
		"desc_changed":
			description = str(value)
		"version_changed":
			engine_version = engine_version_button.get_item_text(int(value))
			_setup_renderer_button()
		"renderer_changed":
			renderer = engine_renderer_button.get_item_text(int(value))


func _setup_engine_button() -> void:
	engine_version_button.clear()
	var index = 0
	var selected_index = 0
	for engine in EngineManager.get_installed_versions():
		engine_version_button.add_item(engine, index)
		if engine == engine_version:
			selected_index = index
		index += 1
	engine_version_button.select(selected_index)


func _setup_renderer_button() -> void:
	engine_renderer_button.clear()
	if "4." in engine_version:
		engine_renderer_button.add_item("Forward Plus")
		engine_renderer_button.add_item("Mobile")
		engine_renderer_button.add_item("GL Compatibility")
	else:
		engine_renderer_button.add_item("OpenGL ES 3.0")
		engine_renderer_button.add_item("OpenGL ES 2.0")


func _check_path(update: bool) -> void:
	var dir = DirAccess.open(path)
	if not dir: 
		path_info.set_texture(PATH_BAD)
		path_info.set_tooltip_text("Path Not Valid")
		can_create = false
		return
	var is_project = _check_if_project_exists(path)
	if create_folder:
		is_project = _check_if_project_exists(path + "/" + _convert_title(title))
	if not is_project:
		if not create_folder:
			if not path.contains(_convert_title(title)):
				path_info.set_texture(PATH_NOT_OK)
				path_info.set_tooltip_text("Path Destination Doesn't Match Title")
		else:
			if not path.contains(_convert_title(title)):
				path = path + "/" + _convert_title(title)
			path_info.set_texture(PATH_OK)
			path_info.set_tooltip_text("Path Valid")
		can_create = true
	else:
		path_info.set_texture(PATH_BAD)
		path_info.set_tooltip_text("Path Destination Is Existing Project")
		can_create = false
	if update:
		project_path.set_text(path)
		project_path.set_caret_column(project_path.get_text().length())


func _check_if_project_exists(new_path: String) -> bool:
	var dir = DirAccess.open(new_path)
	if dir:
		var files = dir.get_files()
		for file in files:
			if file == "project.godot":
				return true
	return false


func _convert_title(text: String) -> String:
	var new_title = text.replace(" ", "-")
	return new_title.to_lower()
