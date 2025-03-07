extends Node

const DEFAULT_ICON: CompressedTexture2D = preload("res://icon.svg")
const MISSING_ICON: CompressedTexture2D = preload("res://assets/icons/missing_icon.svg")
const CS_ICON: CompressedTexture2D = preload("res://assets/icons/icon_ft_csharp.svg")

@onready var project_button: Button = $ProjectButton
@onready var menu_button: MenuButton = $ProjectContainer/ButtonContainer/MenuButton
@onready var groups_button: MenuButton = $GroupsButton
@onready var favorite_button: Button = $ProjectContainer/ButtonContainer/FavoriteButton
@onready var delete_button: Button = $ProjectContainer/ButtonContainer/DeleteButton

@onready var icon: TextureRect = $ProjectContainer/Icon
@onready var title_label: Label = $ProjectContainer/Info/Title
@onready var description: Label = $ProjectContainer/Info/Description
@onready var path_label: Label = $ProjectContainer/Info/PathContainer/Path
@onready var type_texture: TextureRect = $ProjectContainer/TypeTexture
@onready var version_label: Label = $ProjectContainer/Version
@onready var engine_version_label: Label = $ProjectContainer/EngineContainer/EngineVersion

@onready var edit_panel: Panel = $EditPanel
@onready var line_edit: LineEdit = $EditPanel/Box/LineEdit

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
var temp_engine: String = ""


func _ready() -> void:
	group_popup = groups_button.get_popup()
	group_popup.transparent_bg = true
	group_popup.index_pressed.connect(value_received.bind("group"))
	menu_button.get_popup().index_pressed.connect(value_received.bind("popup"))
	menu_button.get_popup().transparent_bg = true
	menu_button.get_popup().set_item_icon_max_width(4, 16)
	menu_button.get_popup().set_item_tooltip(0, "Edit")
	menu_button.get_popup().set_item_tooltip(1, "Play")
	menu_button.get_popup().set_item_tooltip(2, "Add To Group")
	menu_button.get_popup().set_item_tooltip(3, "Remove From Group")
	menu_button.get_popup().set_item_tooltip(4, "Change Engine Version")
	menu_button.get_popup().set_item_tooltip(5, "Remove / Delete")


func setup(new_master: Control, project: int, new_title: String, new_desc: String, new_path: String, new_version: String, new_engine: String, new_icon: ImageTexture, is_favorite: bool) -> void:
	if not is_node_ready():
		await ready
	master = new_master
	this_project = project
	path = new_path
	title_label.set_text(new_title)
	description.set_text(new_desc)
	description.set_tooltip_text(new_desc)
	path_label.set_text(new_path)
	path_label.set_tooltip_text(new_path)
	version_label.set_text(new_version)
	engine_version = new_engine
	temp_engine = new_engine
	line_edit.set_text(new_engine)
	if "C#" in engine_version:
		type_texture.set_texture(CS_ICON)
	engine_version_label.set_text(engine_version)
	if new_icon == null:
		icon.set_texture(DEFAULT_ICON)
	else:
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
						ProjectManager.move_project_front(this_project)
						NotificationManager.notify("Opening Editor", 2.0, true)
						var quit = ConfigManager.get_config_data("settings", "quit_edit")
						if quit:
							await get_tree().create_timer(2.0).timeout
							get_tree().quit()
					else:
						NotificationManager.show_prompt("Failed To Open Project, Verify Engine Installation.", ["OK"], self, "")
				1:# Play
					var index = EngineManager.get_version_index(engine_version)
					var complete = EngineManager.run_project(index, path)
					if complete:
						ProjectManager.move_project_front(this_project)
						NotificationManager.notify("Running Project", 2.0, true)
					else:
						NotificationManager.show_prompt("Failed To Open Project, Verify Engine Installation.", ["OK"], self, "")
				2:# Add to group
					_get_groups()
					groups_button.show_popup()
				3:# Remove from group
					ProjectManager.remove_project_from_group(this_project)
				4:# Change engine version
					edit_panel.set_visible(true)
				5:# Delete
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
				master.create_group()
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
			var complete = EngineManager.run_project_in_editor(index, path)
			if complete:
				ProjectManager.move_project_front(this_project)
				NotificationManager.notify("Opening Editor", 2.0, true)
				var quit = ConfigManager.get_config_data("settings", "quit_edit")
				if quit:
					await get_tree().create_timer(2.0).timeout
					get_tree().quit()
			else:
				NotificationManager.show_prompt("Failed To Open Project, Verify Engine Installation.", ["OK"], self, "")
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


func _on_line_edit_text_changed(new_text: String) -> void:
		temp_engine = new_text


func _on_confirm_button_pressed() -> void:
	if "4." in temp_engine or "3." in temp_engine:
		engine_version = temp_engine
		engine_version_label.set_text(engine_version)
		ProjectManager.change_project_engine_version(this_project, engine_version)
		edit_panel.set_visible(false)
	else:
		NotificationManager.notify("Engine Version Not Valid", 2.0, true)


func _on_delete(option: String) -> void:
	match option:
		"Remove":
			ProjectManager.remove_project(this_project)
		"Delete":
			var folder_path = path.replace("/" + _convert_title(title_label.get_text()), "")
			if FileManager.delete_folder(folder_path, _convert_title(title_label.get_text()), true):
				ProjectManager.remove_project(this_project)
			else:
				NotificationManager.show_prompt("Failed To Delete Project, Verify Project Location.", ["OK"], self, "")


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


func _convert_title(text: String) -> String:
	var new_title = text.replace(" ", "-")
	return new_title.to_lower()


func _on_delay_timer_timeout() -> void:
	clicked = false
