extends UIState

const BASE_GROUP: PackedScene = preload("res://assets/scenes/components/project/project_base_group.tscn")
const CUSTOM_GROUP: PackedScene = preload("res://assets/scenes/components/project/project_custom_group.tscn")
const PROJECT: PackedScene = preload("res://assets/scenes/components/project/project.tscn")

@onready var empty_label: Label = $PanelContainer/MarginContainer/EmptyLabel
@onready var project_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/ProjectContainer

@onready var list_view_button: Button = $ViewButtonPanel/ViewButtons/ListViewButton
@onready var group_view_button: Button = $ViewButtonPanel/ViewButtons/GroupViewButton

@onready var create_new_project: PanelContainer = $DialogContainer/CreateNewProject
@onready var import_project_dialog: FileDialog = $DialogContainer/ImportProjectDialog


func _ready() -> void:
	ProjectManager.call_deferred("setup", self, project_container)


func enter(previous : String):
	super.enter(previous)
	if is_node_ready():
		call_deferred("_init_projects")
	EngineManager.load_settings()


func button_pressed(button: String) -> void:
	match button:
		"new_project":
			create_new_project.setup(self)
		"import":
			import_project_dialog.setup()
		"scan":
			var folders = ConfigManager.get_config_data("settings", "project_folders")
			if folders != null:
				ProjectManager.scan_for_projects(folders)
				NotificationManager.notify("Scanned For Projects", 2.0, true)
			else:
				NotificationManager.notify("No Project Folders Set", 3.0, true)


func button_toggled(toggled_on: bool, button: String) -> void:
	match button:
		"list_view":
			if toggled_on and ProjectManager.get_view_mode() == "group":
				ProjectManager.set_view_mode("list")
				_init_projects()
		"group_view":
			if toggled_on and ProjectManager.get_view_mode() == "list":
				ProjectManager.set_view_mode("group")
				_init_projects()


func create_project(title: String, description: String, path: String, version: String, engine_version: String, icon: ImageTexture = null) -> void:
	var container = project_container
	if ProjectManager.get_view_mode() == "group":
		var groups = ProjectManager.get_groups_dic()
		container = groups[1]["node"].get_container()
	if container != null:
		var project_num = ProjectManager.get_project_num()
		var new_project = PROJECT.instantiate()
		container.add_child(new_project)
		new_project.setup(self, project_num, title, description, path, version, engine_version, icon, false)
		ProjectManager.create_project(new_project, title, description, path, version, engine_version, icon)


func create_group() -> void:
	if not project_container:
		return
	var group_num = ProjectManager.get_group_num()
	var title = ""
	var new_group = null
	if ProjectManager.get_view_mode() == "group":
		new_group = CUSTOM_GROUP.instantiate()
		project_container.add_child(new_group)
		new_group.setup(self, group_num, false, title)
	ProjectManager.create_group(new_group)


func _process(_delta: float) -> void:
	if not project_container:
		return
	var show_label = false
	if ProjectManager.get_view_mode() == "group":
		if _check_groups_empty():
			show_label = true
	else:
		if project_container.get_child_count() <= 0:
			show_label = true
	if show_label:
		if not empty_label.is_visible():
			empty_label.set_visible(true)
	elif empty_label.is_visible():
		empty_label.set_visible(false)


func _init_projects() -> void:
	_clear_project_container()
	if ProjectManager.get_view_mode() == "group":
		_add_groups()
		_set_buttons(true)
	else:
		_set_buttons(false)
	_add_projects()


func _set_buttons(group: bool) -> void:
	list_view_button.set_pressed_no_signal(!group)
	group_view_button.set_pressed_no_signal(group)


func _check_groups_empty() -> bool:
	for group in project_container.get_children():
		var container = group.get_container()
		if container.get_child_count() > 0:
			return false
	return true


func _add_groups() -> void:
	if not project_container:
		return
	var groups = ProjectManager.get_groups_dic()
	for group in groups:
		var title = groups[group]["name"]
		var is_hidden = groups[group]["hidden"]
		var new_group = null
		if group < 2:
			new_group = BASE_GROUP.instantiate()
		else:
			new_group = CUSTOM_GROUP.instantiate()
		project_container.add_child(new_group)
		new_group.setup(self, group, is_hidden, title)
		ProjectManager.groups[group]["node"] = new_group
	_reorder_groups()


func _reorder_groups() -> void:
	var groups = ProjectManager.get_groups_dic()
	for group in groups:
		var child = groups[group]["node"]
		var pos = groups[group]["position"]
		project_container.move_child(child, pos)


func _add_projects() -> void:
	var projects = ProjectManager.get_projects_dic()
	var groups = ProjectManager.get_groups_dic()
	for project in projects:
		var title = projects[project]["name"]
		var desc = projects[project]["description"]
		var path = projects[project]["path"]
		var version = projects[project]["version"]
		var engine_version = projects[project]["engine_version"]
		var group = projects[project]["group"]
		var icon = projects[project]["icon"]
		var fav = projects[project]["favorite"]
		var container = project_container
		if ProjectManager.get_view_mode() == "group":
			container = groups[group]["node"].get_container()
		if container != null:
			var new_project = PROJECT.instantiate()
			container.add_child(new_project)
			new_project.setup(self, project, title, desc, path, version, engine_version, icon, fav)
			ProjectManager.projects[project]["node"] = new_project
		if fav and ProjectManager.get_view_mode() == "group":
			container = groups[0]["node"].get_container()
			if container != null:
				var new_project = PROJECT.instantiate()
				container.add_child(new_project)
				new_project.setup(self, project, title, desc, path, version, engine_version, icon, fav)
				ProjectManager.projects[project]["favorite_node"] = new_project
	_reorder_projects()


func _reorder_projects() -> void:
	var projects = ProjectManager.get_projects_dic()
	var groups = ProjectManager.get_groups_dic()
	for project in projects:
		var child = projects[project]["node"]
		var group = projects[project]["group"]
		var pos = projects[project]["position"]
		var fav = projects[project]["favorite"]
		var fav_node = projects[project]["favorite_node"]
		var container = project_container
		if ProjectManager.get_view_mode() == "group":
			container = groups[group]["node"].get_container()
			pos = clamp(pos, 0, groups[group]["size"])
			if fav:
				var fav_container = groups[0]["node"].get_container()
				if fav_container != null:
					var fav_pos = clamp(pos, 0, groups[0]["size"])
					fav_container.move_child(fav_node, fav_pos)
		if container != null:
			container.move_child(child, pos)


func _clear_project_container() -> void:
	if not project_container:
		return
	for child in project_container.get_children():
		child.queue_free()
