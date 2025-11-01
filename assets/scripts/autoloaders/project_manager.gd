extends "res://assets/scripts/other/project_creator.gd"

const DEFAULT_GROUPS: Dictionary = {0: {"name": "Favorites", "position": 0, "size": 0, "node": null, "hidden": false}, 1: {"name": "Ungrouped", "position": 1, "size": 0, "node": null, "hidden": false}}

enum VIEW_MODE {LIST, GROUP}

var projects: Dictionary = {}
var groups: Dictionary = {}
var view_mode: VIEW_MODE = VIEW_MODE.LIST
var project_master: Control = null
var project_container: Control = null


func _ready() -> void:
	reset_all()
	_load_data()


func setup(master: Control, container: Control) -> void:
	project_master = master
	project_container = container


func reset_all() -> void:
	projects.clear()
	groups.clear()
	for group in DEFAULT_GROUPS:
		groups[group] = {}
		for key in DEFAULT_GROUPS[group]:
			groups[group][key] = DEFAULT_GROUPS[group][key]


func set_view_mode(mode: String) -> void:
	var new_mode = mode.to_upper()
	if VIEW_MODE.has(new_mode):
		view_mode = VIEW_MODE[new_mode]
	_save_data()


func get_view_mode() -> String:
	var key = VIEW_MODE.keys()[view_mode]
	return key.to_lower()


func get_projects_dic() -> Dictionary:
	return projects.duplicate()


func get_groups_dic() -> Dictionary:
	return groups.duplicate()


func create_project(new_project: Node, title: String, description: String, path: String, version: String, engine_version: String, icon: ImageTexture = null) -> void:
	if _check_duplicate(title):
		_debugger("Project already exists: " + title)
		var id = get_project_id(title)
		if id >= 0:
			update_project(id, path)
		if new_project:
			new_project.queue_free()
		return
	var project_num = get_project_num()
	var project_count = projects.size()
	groups[1]["size"] += 1
	projects[project_num] = {"name": title, "description": description, "path": path, "version": version, "engine_version": engine_version, "icon": icon, "group": 1, "position": project_count, "favorite": false, "node": new_project, "favorite_node": null}
	_debugger("New project created: " + str(title))
	_save_data()


func remove_project(project_num: int) -> void:
	if not projects.has(project_num):
		_debugger("Project not found: " + str(project_num), true)
		return
	var group = projects[project_num]["group"]
	var pos = projects[project_num]["position"]
	var node = projects[project_num]["node"]
	var fav = projects[project_num]["favorite"]
	if fav:
		remove_project_from_favorites(project_num)
	if group > 1:
		remove_project_from_group(project_num)
	node.queue_free()
	groups[1]["size"] -= 1
	projects.erase(project_num)
	for project in projects:
		if project != project_num:
			var project_pos = projects[project]["position"]
			if project_pos > pos:
				projects[project]["position"] -= 1
	_debugger("Project removed: " + str(project_num))
	_save_data()


func move_project_front(project_num: int) -> void:
	if not projects.has(project_num):
		_debugger("Project not found: " + str(project_num), true)
		return
	var this_project = projects[project_num]["node"]
	var group = projects[project_num]["group"]
	var pos = projects[project_num]["position"]
	projects[project_num]["position"] = 0
	var fav = projects[project_num]["favorite"]
	var fav_node = projects[project_num]["favorite_node"]
	var container = project_container
	var group_container = groups[group]["node"].get_container()
	var fav_container = groups[0]["node"].get_container()
	if container != null or group_container != null:
		if view_mode == VIEW_MODE.GROUP:
			group_container.move_child(this_project, 0)
			if fav:
				fav_container.move_child(fav_node, 0)
		else:
			container.move_child(this_project, 0)
		for project in projects:
			if project != project_num:
				var project_pos = projects[project]["position"]
				if project_pos < pos:
					projects[project]["position"] += 1
		_debugger("Project moved to front: " + str(project_num))
		_save_data()
		return
	_debugger("Failed to move project to front: " + str(project_num), true)


func add_project_to_group(project_num: int, group_num: int) -> void:
	if not projects.has(project_num):
		_debugger("Project not found: " + str(project_num), true)
		return
	if not groups.has(group_num):
		_debugger("Group not found: " + str(group_num), true)
		return
	var old_group = projects[project_num]["group"]
	projects[project_num]["group"] = group_num
	groups[group_num]["size"] += 1
	groups[old_group]["size"] -= 1
	var project_node = projects[project_num]["node"]
	var group_node = groups[group_num]["node"]
	if project_node == null or group_node == null:
		_debugger("Project: %d added to group: %d. (Node not found)" % [project_num, group_num])
		_save_data()
		return
	var new_parent = group_node.get_container()
	if new_parent != null:
		var old_parent = project_node.get_parent()
		old_parent.remove_child(project_node)
		new_parent.call_deferred("add_child", project_node)
		_debugger("Project: %d added to group: %d" % [project_num, group_num])
		_save_data()
		return
	_debugger("Failed to add project: %d to group: %d" % [project_num, group_num], true)


func remove_project_from_group(project_num: int) -> void:
	if not projects.has(project_num):
		_debugger("Project not found: " + str(project_num), true)
		return
	var old_group = projects[project_num]["group"]
	if not groups.has(old_group):
		_debugger("Group not found: " + str(old_group), true)
		return
	projects[project_num]["group"] = 1
	groups[1]["size"] += 1
	groups[old_group]["size"] -= 1
	var project_node = projects[project_num]["node"]
	var group_node = groups[1]["node"]
	if project_node == null or group_node == null:
		_debugger("Project: %d removed from group: %d. (Node not found)" % [project_num, old_group])
		_save_data()
		return
	var new_parent = group_node.get_container()
	if new_parent!= null:
		var old_parent = project_node.get_parent()
		old_parent.remove_child(project_node)
		new_parent.call_deferred("add_child", project_node)
		_debugger("Project: %d removed from group: %d" % [project_num, old_group])
		_save_data()
		return
	_debugger("Failed to remove project: %d from group: %d" % [project_num, old_group], true)


func add_project_to_favorites(project_num: int) -> void:
	if project_master == null:
		_debugger("Project master not found", true)
		return
	if not projects.has(project_num):
		_debugger("Project not found: " + str(project_num), true)
		return
	var fav = true
	projects[project_num]["favorite"] = fav
	if view_mode != VIEW_MODE.GROUP:
		_debugger("Project added to favorites: %d. (Node not found)" % [project_num])
		_save_data()
		return
	var title = projects[project_num]["name"]
	var desc = projects[project_num]["description"]
	var path = projects[project_num]["path"]
	var version = projects[project_num]["version"]
	var engine_version = projects[project_num]["engine_version"]
	var icon = projects[project_num]["icon"]
	var container = groups[0]["node"].get_container()
	if container != null:
		var new_project = project_master.PROJECT.instantiate()
		container.add_child(new_project)
		new_project.setup(project_master, project_num, title, desc, path, version, engine_version, icon, fav)
		projects[project_num]["favorite_node"] = new_project
		groups[0]["size"] += 1
		_debugger("Project added to favorites: " + str(project_num))
		_save_data()
		return
	_debugger("Failed to add project to favorites: " + str(project_num), true)


func remove_project_from_favorites(project_num: int) -> void:
	if not projects.has(project_num):
		_debugger("Project not found: " + str(project_num), true)
		return
	projects[project_num]["favorite"] = false
	projects[project_num]["node"].favorite_button.set_pressed_no_signal(false)
	if view_mode != VIEW_MODE.GROUP:
		_debugger("Project removed from favorites: %d. (Node not found)" % [project_num])
		_save_data()
		return
	var favorite_node = projects[project_num]["favorite_node"]
	if favorite_node:
		favorite_node.queue_free()
		projects[project_num]["favorite_node"] = null
		groups[0]["size"] -= 1
		_debugger("Project removed from favorites: " + str(project_num))
		_save_data()
		return
	_debugger("Failed to remove project from favorites: " + str(project_num), true)


func create_group(new_group: Node) -> void:
	var group_num = get_group_num()
	var group_count = groups.size()
	groups[group_num] = {"name": "", "position": group_count, "size": 0, "node": new_group, "hidden": false}
	_debugger("Group created")
	_save_data()


func remove_group(group_num: int) -> void:
	if not groups.has(group_num):
		_debugger("Group not found: " + str(group_num), true)
		return
	var pos = groups[group_num]["position"]
	var group_node = groups[group_num]["node"]
	if group_node == null:
		_debugger("Group node not found: " + str(group_num), true)
		return
	var container = groups[group_num]["node"].get_container()
	if container != null:
		for child in container.get_children():
			remove_project_from_group(child.this_project)
	groups.erase(group_num)
	for group in groups:
		if groups[group]["position"] > pos:
			groups[group]["position"] -= 1
	_debugger("Group removed")
	_save_data()


func move_group(group_num: int, move_up: bool) -> void:
	if not project_container:
		_debugger("Project container not found", true)
		return
	if not groups.has(group_num):
		_debugger("Group not found: " + str(group_num), true)
		return
	var pos = groups[group_num]["position"]
	if move_up and pos > 2:
		project_container.move_child(groups[group_num]["node"], pos - 1)
		for group in groups:
			if groups[group]["position"] == pos - 1:
				groups[group]["position"] = pos
				break
		groups[group_num]["position"] = pos - 1
		_debugger("Group moved up: " + str(group_num))
	elif not move_up and pos < groups.size() - 1:
		project_container.move_child(groups[group_num]["node"], pos + 1)
		for group in groups:
			if groups[group]["position"] == pos + 1:
				groups[group]["position"] = pos
				break
		groups[group_num]["position"] = pos + 1
		_debugger("Group moved down: " + str(group_num))
	_save_data()


func rename_group(group_num: int, new_name: String) -> void:
	if not groups.has(group_num):
		_debugger("Group not found: " + str(group_num), true)
		return
	groups[group_num]["name"] = new_name
	_debugger("Group renamed: " + str(group_num))
	_save_data()


func hide_show_group(group_num: int, is_hidden: bool) -> void:
	if not groups.has(group_num):
		_debugger("Group not found: " + str(group_num), true)
		return
	groups[group_num]["hidden"] = is_hidden
	_debugger("Group hidden set: " + str(group_num) + " - " + str(is_hidden))
	_save_data()


func get_project_groups() -> Array:
	return groups.keys()


func scan_for_projects(paths: Array) -> void:
	for path in paths:
		var folders = FileManager.get_folders(path)
		if not folders.is_empty():
			for folder in folders:
				var project_path = path + "/" + folder
				import_project(project_path)
	_debugger("Scanned paths: %s for projects" % [str(paths)])


func import_project(path: String) -> bool:
	if project_master == null:
		_debugger("Project master not found", true)
		return false
	var files = FileManager.get_files(path)
	if files.is_empty():
		_debugger("Path not found: " + path, true)
		return false
	var is_project = false
	for file in files:
		if file == "project.godot":
			is_project = true
			break
	if not is_project:
		_debugger("Project file not found in path: " + path, true)
		return false
	var project_data = _get_project_data(path)
	if project_data.is_empty():
		_debugger("Failed to get project data: " + path, true)
		return false
	project_master.create_project(
		project_data["name"],
		project_data["description"],
		project_data["path"],
		project_data["version"],
		project_data["engine_version"],
		project_data["icon"]
	)
	_debugger("Project Imported: " + str(project_data["name"]))
	return true


func update_project(project_num: int, path: String, save_data: bool = false) -> void:
	if not projects.has(project_num):
		_debugger("Project not found: " + str(project_num), true)
		return
	var files = FileManager.get_files(path)
	if files.is_empty():
		_debugger("Path not found: " + path, true)
		return
	var is_project = false
	for file in files:
		if file == "project.godot":
			is_project = true
			break
	if not is_project:
		_debugger("Project file not found in path: " + path, true)
		return
	var project_data = _get_project_data(path)
	projects[project_num]["name"] = project_data["name"]
	projects[project_num]["description"] = project_data["description"]
	projects[project_num]["path"] = project_data["path"]
	projects[project_num]["version"] = project_data["version"]
	if not "x" in project_data["engine_version"]:
		if _version_is_greater(project_data["engine_version"], projects[project_num]["engine_version"]):
			projects[project_num]["engine_version"] = project_data["engine_version"]
	projects[project_num]["icon"] = project_data["icon"]
	_debugger("Project Updated: " + str(project_num))
	if save_data:
		_save_data()


func change_project_engine_version(project_num: int, new_version: String) -> void:
	if not projects.has(project_num):
		_debugger("Project not found: " + str(project_num), true)
		return
	var path = projects[project_num]["path"]
	if not await _update_engine_version(path, new_version):
		_debugger("Failed to update project engine version")
		return
	projects[project_num]["engine_version"] = new_version
	_debugger("Project engine version changed: " + str(project_num))
	_save_data()


func get_project_num() -> int:
	var count = projects.size()
	for num in count:
		if not projects.has(num):
			return num
	return count


func get_group_num() -> int:
	var count = groups.size()
	for num in count:
		if not groups.has(num):
			return num
	return count


func get_project_id(project_name: String) -> int:
	for project in projects:
		if projects[project]["name"] == project_name:
			return project
	return -1


func get_project_data(project_path: String) -> Dictionary:
	return _get_project_data(project_path)


func _check_duplicate(project_name: String) -> bool:
	for project in projects:
		if project_name == projects[project]["name"]:
			return true
	return false


func _version_string_to_array(version_string: String) -> Array:
	var major = version_string.substr(0, 1)
	var minor = version_string.substr(3, 1)
	var patch = "0"
	if version_string.length() > 3:
		patch = version_string.substr(5, 1)
	if major.is_valid_int() and minor.is_valid_int() and patch.is_valid_int():
		return [major.to_int(), minor.to_int(), patch.to_int()]
	return []


func _version_is_greater(version_check: String, version_compare: String) -> bool:
	var version_check_array = _version_string_to_array(version_check)
	var version_compare_array = _version_string_to_array(version_compare)
	for num in version_check_array.size():
		var check_num = version_check_array[num]
		var compare_num = version_compare_array[num]
		if check_num > compare_num:
			return true
	return false


func _save_data() -> void:
	var data = {"projects": projects, "groups": groups, "view": view_mode}
	FileManager.save_data("user://", "data.json", data, true)


func _load_data() -> void:
	var data = FileManager.load_data("user://", "data.json")
	if not data.is_empty():
		var loaded_projects = data["projects"].duplicate()
		for project in loaded_projects:
			projects[project.to_int()] = loaded_projects[project]
			# Remove later
			if projects[project.to_int()].has("group_position"):
				projects[project.to_int()].erase("group_position")
			# 
			if projects[project.to_int()].has("icon") and not projects[project.to_int()]["icon"] == null:
				projects[project.to_int()]["icon"] = str_to_var(projects[project.to_int()]["icon"])
			if projects[project.to_int()].has("node") and not projects[project.to_int()]["node"] == null:
				projects[project.to_int()]["node"] = str_to_var(projects[project.to_int()]["node"])
			if projects[project.to_int()].has("favorite_node") and not projects[project.to_int()]["favorite_node"] == null:
				projects[project.to_int()]["favorite_node"] = str_to_var(projects[project.to_int()]["favorite_node"])
			for property in projects[project.to_int()]:
				if projects[project.to_int()][property] is float:
					projects[project.to_int()][property] = int(projects[project.to_int()][property])
			update_project(project.to_int(), projects[project.to_int()]["path"])
		var loaded_groups = data["groups"].duplicate()
		for group in loaded_groups:
			groups[group.to_int()] = loaded_groups[group]
			if groups[group.to_int()].has("node") and not groups[group.to_int()]["node"] == null:
				groups[group.to_int()]["node"] = str_to_var(groups[group.to_int()]["node"])
			for property in groups[group.to_int()]:
				if groups[group.to_int()][property] is float:
					groups[group.to_int()][property] = int(groups[group.to_int()][property])
		var loaded_mode = data["view"]
		var new_view = ConfigManager.get_config_data("settings", "default_view")
		if new_view != null:
			match new_view:
				0:
					view_mode = loaded_mode
				1:
					view_mode = VIEW_MODE.LIST
				2:
					view_mode = VIEW_MODE.GROUP
