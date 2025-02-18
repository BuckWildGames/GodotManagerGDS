extends Node

const DEBUGGER: bool = false

func create_project_folder(title: String, description: String, path: String, engine: String, renderer: String, create_folder: bool, create_git: bool, template: int = -1) -> bool:
	if ProjectManager._check_duplicate(title):
		_debugger("Project already exists: " + title)
		return false
	if not DirAccess.dir_exists_absolute(path):
		if not create_folder:
			_debugger("Path not found: " + path)
			return false
		DirAccess.make_dir_recursive_absolute(path)
	_set_project_template(template, path)
	var project_file_path = path + "/project.godot"
	if "3." in engine:
		var complete = _create_godot_3x_project_file(project_file_path, title, description, renderer)
		if not complete:
			_debugger("Failed to create project file", true)
			return false
		complete = FileManager.copy_file("res://assets/files", path, "icon.png")
		if not complete:
			_debugger("Failed to copy icon.png", true)
			return false
		var env = preload("res://assets/files/default_env.tres")
		complete = FileManager.save_resource(path, "default_env.tres", env)
		#complete = FileManager.copy_file("res://assets/files", path, "default_env.tres")
		if not complete:
			_debugger("Failed to copy default_env.tres", true)
			return false
	elif "4." in engine:
		var complete = _create_godot_4x_project_file(project_file_path, title, description, engine, renderer)
		if not complete:
			_debugger("Failed to create project file", true)
			return false
		complete = FileManager.copy_file("res://", path, "icon.svg")
		if not complete:
			_debugger("Failed to copy icon.svg", true)
			return false
	if create_git:
		var complete = FileManager.copy_file("res://assets/files", path, ".gitattributes")
		if not complete:
			_debugger("Failed to copy .gitattributes", true)
			return false
		complete = FileManager.copy_file("res://assets/files", path, ".gitignore")
		if not complete:
			_debugger("Failed to copy .gitignore", true)
			return false
	_debugger("Project successfully created at:" + path)
	return true

# Not finished!!!!!!!!!!!!!!
func _set_project_template(template: int, path: String) -> void:
	if template == -1:
		return
	var folders = []
	for folder in folders:
		DirAccess.make_dir_recursive_absolute(path + "/" + folder)


func _create_godot_3x_project_file(project_file_path: String, title: String, description: String, renderer: String) -> bool:
	var config_version = 4
	var config = ConfigFile.new()
	config.set_value("", "config_version", config_version)
	config.set_value("application", "config/name", title)
	config.set_value("application", "config/description", description)
	config.set_value("application", "config/icon", "res://icon.png")
	if "GLES2" in renderer:
		config.set_value("rendering", "quality/driver/driver_name", "GLES2")
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
	_debugger("Created 3x project file")
	return true


func _create_godot_4x_project_file(project_file_path: String, title: String, description: String, engine: String, renderer: String) -> bool:
	var config_version = 5
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
		var config_version = config.get_value("", "config_version", -1)
		match config_version:
			4: 
				return "3.x"
			5: 
				return "4.x"
	return "Unknown Version"


func _get_icon(config: ConfigFile, path: String) -> String:
	if config.has_section("header"):
		if config.has_section_key("application", "config/icon"):
			var icon_path = config.get_value("application", "config/icon")
			icon_path = icon_path.replace("res://", "")
			return path + icon_path
	return path + "/icon.svg"


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
