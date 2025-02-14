extends Node

const DEFAULT_ICON: CompressedTexture2D = preload("res://icon.svg")
const MISSING_ICON: CompressedTexture2D = preload("res://assets/icons/missing_icon.svg")

@onready var project_button: Button = $ProjectButton
@onready var menu_button: MenuButton = $ProjectContainer/ButtonContainer/MenuButton
@onready var groups_button: MenuButton = $GroupsButton
@onready var favorite_button: Button = $ProjectContainer/ButtonContainer/FavoriteButton
@onready var delete_button: Button = $ProjectContainer/ButtonContainer/DeleteButton

@onready var icon: TextureRect = $ProjectContainer/Icon
@onready var title_label: Label = $ProjectContainer/Info/Title
@onready var description: Label = $ProjectContainer/Info/Description
@onready var path_label: Label = $ProjectContainer/Info/Path
@onready var version_label: Label = $ProjectContainer/Version
@onready var engine_version_label: Label = $ProjectContainer/EngineVersion

@onready var delay_timer: Timer = $DelayTimer

var group_popup: PopupMenu = null
var master: Control = null
var this_project: int = -1
var this_group: int = -1
var path: String = ""
var engine_version: String = ""

var missing: bool = false
var click_delay: float = 1.0
var clicked: bool = false


func _ready() -> void:
	group_popup = groups_button.get_popup()
	group_popup.index_pressed.connect(value_received.bind("group"))
	menu_button.get_popup().index_pressed.connect(value_received.bind("popup"))


func setup(new_master: Control, project: int, new_title: String, new_desc: String, new_path: String, new_version: String, new_engine: String, new_icon: CompressedTexture2D, is_favorite: bool) -> void:
	if not is_node_ready():
		await ready
	master = new_master
	this_project = project
	path = new_path
	title_label.set_text(new_title)
	description.set_text(new_desc)
	description.set_tooltip_text(new_desc)
	path_label.set_text("Path: " + new_path)
	path_label.set_tooltip_text(new_path)
	version_label.set_text(new_version)
	engine_version = new_engine
	engine_version_label.set_text("Godot: " + engine_version)
	if new_icon == null:
		new_icon = DEFAULT_ICON
	icon.set_texture(new_icon)
	favorite_button.set_pressed_no_signal(is_favorite)
	_check_if_missing()


func value_received(value: Variant, button: String) -> void:
	if not master:
		return
	match button:
		"popup":
			match int(value):
				0:# Edit
					var index = EngineManager.get_version_index(engine_version)
					var complete = EngineManager.run_project_in_editor(index, path)
					if complete:
						NotificationManager.notify("Opening Editor", 2.0, true)
					else:
						NotificationManager.show_prompt("Failed To Open Project, Verify Engine Installation.", ["OK"], self, "")
				1:# Play
					var index = EngineManager.get_version_index(engine_version)
					var complete = EngineManager.run_project(index, path)
					if complete:
						NotificationManager.notify("Running Project", 2.0, true)
					else:
						NotificationManager.show_prompt("Failed To Open Project, Verify Engine Installation.", ["OK"], self, "")
				2:# Add to group
					_get_groups()
					groups_button.show_popup()
				3:# Remove from group
					ProjectManager.remove_project_from_group(this_project)
				4:# Delete
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
			group_popup.add_item(ProjectManager.groups[group]["name"], group)


func _on_project_button_pressed() -> void:
	if master and path != "":
		if clicked:
			var index = EngineManager.get_version_index(engine_version)
			EngineManager.run_project_in_editor(index, path)
			NotificationManager.notify("Opening Editor", 2.0, true)
		else:
			clicked = true
			delay_timer.start(click_delay)


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
			var folder_path = path.replace("/" + title_label.get_text(), "")
			FileManager.delete_folder(folder_path, title_label.get_text(), true)


func _check_if_missing() -> void:
	var files = FileManager.get_files(path)
	if files.is_empty():
		missing = true
		icon.set_texture(MISSING_ICON)
		version_label.set_text("Project Missing")
		favorite_button.set_visible(false)
		menu_button.set_visible(false)
		project_button.set_disabled(true)
		delete_button.set_visible(true)


func _on_delay_timer_timeout() -> void:
	clicked = false
