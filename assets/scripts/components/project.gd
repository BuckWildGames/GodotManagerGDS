extends Node

const DEFAULT_ICON: CompressedTexture2D = preload("res://assets/icons/default_project_icon.png")

@onready var menu_button: MenuButton = $ProjectContainer/ButtonContainer/MenuButton
@onready var groups_button: MenuButton = $GroupsButton
@onready var favorite_button: Button = $ProjectContainer/ButtonContainer/FavoriteButton

@onready var icon: TextureRect = $ProjectContainer/Icon
@onready var title_label: Label = $ProjectContainer/Info/Title
@onready var description: Label = $ProjectContainer/Info/Description
@onready var path_label: Label = $ProjectContainer/Info/Path
@onready var version_label: Label = $ProjectContainer/Version
@onready var engine_version_label: Label = $ProjectContainer/EngineVersion

var group_popup: PopupMenu = null
var master: Control = null
var this_project: int = -1
var this_group: int = -1
var path: String = ""
var engine_version: String = ""


func _ready() -> void:
	group_popup = groups_button.get_popup()
	group_popup.index_pressed.connect(value_received.bind("group"))
	menu_button.get_popup().index_pressed.connect(value_received.bind("popup"))


func setup(new_master: Control, project: int, new_title: String, new_desc: String, new_path: String, new_version: String, new_engine: String, new_icon: CompressedTexture2D, is_favorite: bool) -> void:
	master = new_master
	this_project = project
	path = new_path
	title_label.set_text(new_title)
	description.set_text(new_desc)
	path_label.set_text(new_path)
	version_label.set_text(new_version)
	engine_version = new_engine
	engine_version_label.set_text("Godot: " + engine_version)
	if new_icon == null:
		new_icon = DEFAULT_ICON
	icon.set_texture(new_icon)
	favorite_button.set_pressed_no_signal(is_favorite)


func value_received(value: Variant, button: String) -> void:
	if not master:
		return
	match button:
		"popup":
			match int(value):
				0:
					ProjectManager.open_project_in_editor(path, engine_version)
				1:
					ProjectManager.run_project(path, engine_version)
				2:
					_get_groups()
					groups_button.show_popup()
				3:
					ProjectManager.remove_project_from_group(this_project)
				4:
					NotificationManager.show_prompt(
						"Do you want to Remove project from manager\nor Delete project and move to trash?",
						["Cancel", "Remove", "Delete"],
						self,
						"_on_delete"
					)
		"group":
			if int(value) > 0:
				ProjectManager.add_project_to_group(this_project, int(value) + 1)
			else:
				ProjectManager.create_group()
				ProjectManager.add_project_to_group(this_project, ProjectManager.get_project_groups().size() - 1)


func _get_groups() -> void:
	if not master:
		return
	if not group_popup:
		return
	group_popup.clear()
	group_popup.add_item("New Group", 0)
	var groups = ProjectManager.get_project_groups()
	for group in groups:
		if group > 1:
			group_popup.add_item(master.groups[group]["name"], group)


func _on_project_button_pressed() -> void:
	if master and path != "":
		pass


func _on_favorite_button_toggled(toggled_on: bool) -> void:
	if not master:
		return
	if toggled_on:
		ProjectManager.add_project_to_favorites(this_project)
	else:
		ProjectManager.remove_project_from_favorites(this_project)


func _on_delete(option: String) -> void:
	match option:
		"Remove":
			ProjectManager.remove_project(this_project)
			queue_free()
		"Delete":
			pass
