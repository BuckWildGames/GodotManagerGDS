extends Node

const DEBUGGER: bool = false

const BASE_GROUP: PackedScene = preload("res://assets/scenes/components/project/project_base_group.tscn")
const CUSTOM_GROUP: PackedScene = preload("res://assets/scenes/components/project/project_custom_group.tscn")
const PROJECT: PackedScene = preload("res://assets/scenes/components/project/project.tscn")

enum VIEW_MODE {LIST, GROUP}

var projects: Dictionary = {}
var groups: Dictionary = {0: {"name": "Favorites", "position": 0, "size": 0, "node": null}, 1: {"name": "Ungrouped", "position": 1, "size": 0, "node": null}}
var view_mode: VIEW_MODE = VIEW_MODE.LIST
var project_master: Control = null
var project_container: Control = null


func setup(master: Control, container: Control) -> void:
	project_master = master
	project_container = container


func save_data() -> void:
	var data = {"projects": projects, "groups": groups, "view": view_mode}
	FileManager.save_data("user://", "data.json", data, true)


func load_data() -> void:
	var data = FileManager.load_data("user://", "data.json")
	if not data.is_empty():
		projects = data["projects"].duplicate()
		groups = data["groups"].duplicate()
		view_mode = data["view"]


func set_view_mode(mode: String) -> void:
	var new_mode = mode.to_upper()
	if VIEW_MODE.has(new_mode):
		view_mode = VIEW_MODE[new_mode]


func get_view_mode() -> String:
	var key = VIEW_MODE.keys()[view_mode]
	return key.to_lower()


func get_projects_dic() -> Dictionary:
	return projects.duplicate()


func get_groups_dic() -> Dictionary:
	return groups.duplicate()


func create_project(title: String, description: String, path: String, version: String, engine_version: String, icon: CompressedTexture2D = null) -> void:
	var project_count = projects.size()
	var container = project_container
	if view_mode == VIEW_MODE.GROUP:
		container = groups[1]["node"].get_container()
	if container != null:
		var project_pos = container.get_child_count()
		var new_project = PROJECT.instantiate()
		container.add_child(new_project)
		new_project.setup(project_master, project_count, title, description, path, version, engine_version, icon, false)
		groups[1]["size"] += 1
		projects[project_count] = {"name": title, "description": description, "path": path, "version": version, "engine_version": engine_version, "icon": icon, "group": 1, "position": project_count, "group_position": project_pos, "favorite": false, "node": new_project, "favorite_node": null}
		_debugger("New project created: " + str(title))
		return
	_debugger("Failed to create project: "  + str(title), true)


func remove_project(project_num: int) -> void:
	if not projects.has(project_num):
		_debugger("Project not found: " + str(project_num), true)
		return
	var group = projects[project_num]["group"]
	var pos = projects[project_num]["position"]
	var group_pos = projects[project_num]["group_position"]
	groups[group]["size"] -= 1
	projects.erase(project_num)
	for project in projects:
		if project != project_num:
			var project_pos = projects[project]["position"]
			if project_pos > pos:
				projects[project]["position"] -= 1
			var project_group = projects[project]["group"]
			var project_group_pos = projects[project]["group_position"]
			if group == project_group:
				if project_group_pos > group_pos:
					projects[project]["group_position"] -= 1
	_debugger("Project removed: " + str(project_num))


func move_project_front(project_num: int) -> void:
	if not projects.has(project_num):
		_debugger("Project not found: " + str(project_num), true)
		return
	var this_project = projects[project_num]["node"]
	var group = projects[project_num]["group"]
	var pos = projects[project_num]["position"]
	var fav = projects[project_num]["favorite"]
	var container = project_container
	var group_container = groups[group]["node"].get_container()
	var fav_container = groups[0]["node"].get_container()
	var group_pos = projects[project_num]["group_position"]
	if container != null or group_container != null:
		if view_mode == VIEW_MODE.GROUP:
			container.move_child(this_project, 0)
			if fav:
				fav_container.move_child(this_project, 0)
		else:
			group_container.move_child(this_project, 0)
		for project in projects:
			if project != this_project:
				var project_pos = projects[project]["position"]
				if project_pos < pos:
					projects[project]["position"] += 1
				var project_group = projects[project]["group"]
				var project_group_pos = projects[project]["group_position"]
				if group == project_group:
					if project_group_pos < group_pos:
						projects[project]["group_position"] += 1
		_debugger("Project moved to front: " + str(project_num))
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
	var old_group_pos = projects[project_num]["group_position"]
	projects[project_num]["group"] = group_num
	projects[project_num]["group_position"] = groups[group_num]["size"]
	groups[group_num]["size"] += 1
	groups[old_group]["size"] -= 1
	for project in projects:
		if projects[project]["group"] == old_group:
			if projects[project]["group_position"] > old_group_pos:
				projects[project]["group_position"] -= 1
	var project_node = projects[project_num]["node"]
	var group_node = groups[group_num]["node"]
	if project_node == null or group_node == null:
		_debugger("Project: %d added to group: %d. (Node not found)" % [project_num, group_num])
		return
	var new_parent = group_node.get_container()
	if new_parent != null:
		var old_parent = project_node.get_parent()
		old_parent.remove_child(project_node)
		new_parent.call_deferred("add_child", project_node)
		_debugger("Project: %d added to group: %d" % [project_num, group_num])
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
	var pos = projects[project_num]["group_position"]
	projects[project_num ]["group_position"] = groups[1]["size"]
	groups[1]["size"] += 1
	groups[old_group]["size"] -= 1
	for project in projects:
		if projects[project]["group"] == old_group:
			if projects[project]["group_position"] > pos:
				projects[project]["group_position"] -= 1
	var project_node = projects[project_num]["node"]
	var group_node = groups[1]["node"]
	if project_node == null or group_node == null:
		_debugger("Project: %d removed from group: %d. (Node not found)" % [project_num, old_group])
		return
	var new_parent = group_node.get_container()
	if new_parent!= null:
		var old_parent = project_node.get_parent()
		old_parent.remove_child(project_node)
		new_parent.call_deferred("add_child", project_node)
		_debugger("Project: %d removed from group: %d" % [project_num, old_group])
		return
	_debugger("Failed to remove project: %d from group: %d" % [project_num, old_group], true)


func add_project_to_favorites(project_num: int) -> void:
	if not projects.has(project_num):
		_debugger("Project not found: " + str(project_num), true)
		return
	var fav = true
	projects[project_num]["favorite"] = fav
	if view_mode != VIEW_MODE.GROUP:
		_debugger("Project added to favorites: %d. (Node not found)" % [project_num])
		return
	var title = projects[project_num]["name"]
	var desc = projects[project_num]["description"]
	var path = projects[project_num]["path"]
	var version = projects[project_num]["version"]
	var engine_version = projects[project_num]["engine_version"]
	var icon = projects[project_num]["icon"]
	var container = groups[0]["node"].get_container()
	if container != null:
		var new_project = PROJECT.instantiate()
		container.add_child(new_project)
		new_project.setup(project_master, project_num, title, desc, path, version, engine_version, icon, fav)
		projects[project_num]["favorite_node"] = new_project
		_debugger("Project added to favorites: " + str(project_num))
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
		return
	var favorite_node = projects[project_num]["favorite_node"]
	if favorite_node:
		favorite_node.queue_free()
		projects[project_num]["favorite_node"] = null
		_debugger("Project removed from favorites: " + str(project_num))
		return
	_debugger("Failed to remove project from favorites: " + str(project_num), true)


func create_group() -> void:
	if not project_container:
		_debugger("Project container not found", true)
		return
	var group_count = groups.size()
	var title = ""
	var new_group = null
	if view_mode == VIEW_MODE.GROUP:
		new_group = CUSTOM_GROUP.instantiate()
		project_container.add_child(new_group)
		new_group.setup(project_master, group_count, title)
	groups[group_count] = {"name": "", "position": group_count, "size": 0, "node": new_group}
	_debugger("Group created")


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


func move_group(group_num: int, move_up: bool) -> void:
	if not project_container:
		_debugger("Project container not found", true)
		return
	if not groups.has(group_num):
		_debugger("Group not found: " + str(group_num), true)
		return
	var pos = groups[group_num]["position"]
	if move_up and pos > 2:
		groups[group_num]["position"] = pos - 1
		project_container.move_child(groups[group_num]["node"], pos - 1)
		for group in groups:
			if groups[group]["position"] == pos - 1:
				groups[group]["position"] = pos
				break
		_debugger("Group moved up: " + str(group_num))
	elif not move_up and pos < groups.size() - 1:
		groups[group_num]["position"] = pos + 1
		project_container.move_child(groups[group_num]["node"], pos + 1)
		for group in groups:
			if groups[group]["position"] == pos + 1:
				groups[group]["position"] = pos
				break
			_debugger("Group moved down: " + str(group_num))


func rename_group(group_num: int, new_name: String) -> void:
	if not groups.has(group_num):
		_debugger("Group not found: " + str(group_num), true)
		return
	groups[group_num]["name"] = new_name
	_debugger("Group renamed: " + str(group_num))


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
	var is_project = false
	var files = FileManager.get_files(path)
	if not files.is_empty():
		for file in files:
			if file == "project.godot":
				is_project = true
				break
		if is_project:
			var project_data = _get_project_data(path)
			create_project(
				project_data["name"],
				project_data["description"],
				project_data["path"],
				project_data["version"],
				project_data["engine_version"],
				project_data["icon"]
			)
			_debugger("Project Imported: " + str(project_data["name"]))
			return true
		_debugger("Project file not found in path: " + path, true)
	return false


func create_project_folder(title: String, description: String, path: String, engine: String, renderer: String, create_folder: bool, create_git: bool) -> bool:
	if not DirAccess.dir_exists_absolute(path):
		if not create_folder:
			_debugger("Path not found: " + path)
			return false
		DirAccess.make_dir_recursive_absolute(path)
	var folders = [".godot"]
	for folder in folders:
		DirAccess.make_dir_recursive_absolute(path + "/" + folder)
	var project_file_path = path + "/project.godot"
	if "3." in engine:
		var _config_version = 4
		_debugger("No godot 3X yet")
		return false
	elif "4." in engine:
		var config_version = 5
		var complete = _create_godot_4x_project_file(config_version, project_file_path, title, description, engine, renderer)
		if not complete:
			_debugger("Failed to create project file", true)
			return false
		complete = FileManager.copy_file("res://", path, "icon.svg")
		if not complete:
			_debugger("Failed to copy icon.svg", true)
			return false
		if create_git:
			complete = FileManager.copy_file("res://", path, ".gitattributes")
			if not complete:
				_debugger("Failed to copy .gitattributes", true)
				return false
			complete = FileManager.copy_file("res://", path, ".gitignore")
			if not complete:
				_debugger("Failed to copy .gitignore", true)
				return false
	_debugger("Project successfully created at:" + path)
	return true


func _create_godot_4x_project_file(config_version: int, project_file_path: String, title: String, description: String, engine: String, renderer: String) -> bool:
	var config = ConfigFile.new()
	config.set_value("", "config_version", config_version)
	config.set_value("application", "config/name", title)
	config.set_value("application", "config/description", description)
	config.set_value("application", "config/features", PackedStringArray([engine, renderer]))
	config.set_value("application", "config/icon", "res://icon.svg")
	if "Mobile" in renderer:
		config.set_value("rendering", "renderer/rendering_method", "mobile")
	if "Compatibility" in renderer:
		config.set_value("rendering", "renderer/rendering_method", "gl_compatibility")
		config.set_value("rendering", "renderer/rendering_method.mobile", "gl_compatibility")
	var error = config.save(project_file_path)
	if error != OK:
		_debugger("Failed to save project file", true)
		return false
	var file = FileAccess.open(project_file_path, FileAccess.READ_WRITE)
	if file:
		var content = file.get_as_text()
		file.seek(0)
		file.store_string("; Engine configuration file.\n; It's best edited using the editor UI and not directly,\n; since the parameters that go here are not all obvious.\n;\n; Format:\n;   [section] ; section goes between []\n;   param=value ; assign values to parameters\n\n")
		file.store_string(content)
	file.close()
	_debugger("Created 4x project file")
	return true


func _get_project_data(project_path: String) -> Dictionary:
	var data = {}
	var config = ConfigFile.new()
	if config.load(project_path + "/project.godot") == OK:
		var project_name = config.get_value("application", "config/name", "Unnamed Project")
		var project_description = config.get_value("application", "config/description", "No Description")
		var project_version = config.get_value("application", "config/version", "Version Unknown")
		var version = _get_godot_version(config)
		var icon_path = _get_icon(config, project_path)
		var icon_texture = null
		if FileAccess.file_exists(icon_path):
			icon_texture = load(icon_path)
		data = {
			"name": project_name,
			"description": project_description,
			"version": project_version,
			"path": project_path,
			"engine_version": version,
			"icon": icon_texture
		}
	return data


func _get_godot_version(config: ConfigFile) -> String:
	if config.has_section(""):
		if config.has_section_key("application", "config/features"):
			return config.get_value("application", "config/features")[0]
		var config_version = config.get_value("global", "config_version", -1)
		match config_version:
			5: return "4.x (Unknown Minor Version)"
			4: return "3.x (Unknown Minor Version)"
	return "Unknown Version"


func _get_icon(config: ConfigFile, path: String) -> String:
	if config.has_section("header"):
		if config.has_section_key("application", "config/icon"):
			return config.get_value("application", "config/icon")
	return path + "/icon.png"


func _debugger(debug_message: String, error: bool = false) -> void:
	if error:
		DebugManager.log_error(debug_message, str(get_script().get_path()))
	else:
		DebugManager.log_debug(debug_message, str(get_script().get_path()))
	# Check if script is debug
	if DEBUGGER == true:
		# Check if os debug on
		if OS.is_debug_build():
			# Print message
			print_debug(debug_message)
