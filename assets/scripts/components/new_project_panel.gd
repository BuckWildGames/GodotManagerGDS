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
		project_name.release_focus()
		project_path.call_deferred("release_focus")


func setup() -> void:
	title = "New Project"
	path = "Unknown Path"
	project_path.set_text(path)
	description = "No Description"
	engine_version = "4.3"
	renderer = "Forward Plus"
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
			if can_create and title != "":
				if ProjectManager.create_project_folder(title, description, path, engine_version, renderer, create_folder, version_control):
					ProjectManager.create_project(title, description, path, "0.0.0", engine_version)
					get_parent().hide()
					hide()


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
			engine_version = engine_version_button.get_item_text(value)
		"renderer_changed":
			renderer = engine_renderer_button.get_item_text(value)


func _check_path(update: bool) -> void:
	print(path)
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
