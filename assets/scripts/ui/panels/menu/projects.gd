extends UIState

@onready var empty_label: Label = $PanelContainer/MarginContainer/EmptyLabel
@onready var project_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/ProjectContainer

@onready var list_view_button: Button = $ViewButtonPanel/ViewButtons/ListViewButton
@onready var group_view_button: Button = $ViewButtonPanel/ViewButtons/GroupViewButton

@onready var create_new_project: PanelContainer = $DialogContainer/CreateNewProject
@onready var import_project_dialog: FileDialog = $DialogContainer/ImportProjectDialog


func _ready() -> void:
	_clear_project_container()
	ProjectManager.setup(self, project_container)
	if ProjectManager.get_view_mode() == "group":
		_add_groups()
	_add_projects()


func button_pressed(button: String) -> void:
	match button:
		"new_project":
			create_new_project.setup()
		"import":
			import_project_dialog.setup()
		"scan":
			ProjectManager.scan_for_projects([])


func button_toggled(toggled_on: bool, button: String) -> void:
	match button:
		"list_view":
			if toggled_on and ProjectManager.get_view_mode() == "group":
				ProjectManager.set_view_mode("list")
				group_view_button.set_pressed_no_signal(false)
				_clear_project_container()
				_add_projects()
			else:
				list_view_button.set_pressed_no_signal(true)
		"group_view":
			if toggled_on and ProjectManager.get_view_mode() == "list":
				ProjectManager.set_view_mode("group")
				list_view_button.set_pressed_no_signal(false)
				_clear_project_container()
				_add_groups()
				_add_projects()
			else:
				group_view_button.set_pressed_no_signal(true)


func _process(_delta: float) -> void:
	if not project_container:
		return
	var count = 0
	if ProjectManager.get_view_mode() == "group":
		count = 2
	if project_container.get_child_count() < count:
		if !empty_label.is_visible():
			empty_label.set_visible(true)
	elif empty_label.is_visible():
		empty_label.set_visible(false)


func _add_groups() -> void:
	if not project_container:
		return
	var groups = ProjectManager.get_groups_dic()
	for group in groups:
		var title = groups[group]["name"]
		var new_group = null
		if group < 2:
			new_group = ProjectManager.BASE_GROUP.instantiate()
		else:
			new_group = ProjectManager.CUSTOM_GROUP.instantiate()
		project_container.add_child(new_group)
		new_group.setup(self, group, title)
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
			var new_project = ProjectManager.PROJECT.instantiate()
			container.add_child(new_project)
			new_project.setup(self, project, title, desc, path, version, engine_version, icon, fav)
			ProjectManager.projects[project]["node"] = new_project
		if fav:
			container = groups[0]["node"].get_container()
			if container != null:
				var new_project = ProjectManager.PROJECT.instantiate()
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
			pos = projects[project]["group_position"]
			if fav:
				var fav_container = groups[0]["node"].get_container()
				pos = projects[project]["position"]
				if fav_container != null:
					fav_container.move_child(fav_node, pos)
		if container != null:
			container.move_child(child, pos)


func _clear_project_container() -> void:
	for child in project_container.get_children():
		child.queue_free()
