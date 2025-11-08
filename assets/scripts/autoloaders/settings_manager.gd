extends Node

const DEBUGGER: bool = false


func init_settings() -> void:
	ConfigManager.set_config_data("settings", "run_admin", false)
	ConfigManager.set_config_data("settings", "install_path", "")
	ConfigManager.set_config_data("settings", "fetch_time", 1)
	ConfigManager.set_config_data("settings", "latest_version", false)
	ConfigManager.set_config_data("settings", "run_console", false)
	ConfigManager.set_config_data("settings", "intro_video", false)
	ConfigManager.set_config_data("settings", "default_engine", "")
	ConfigManager.set_config_data("settings", "quit_edit", false)
	ConfigManager.set_config_data("settings", "default_view", 0)
	ConfigManager.set_config_data("settings", "project_folders", [])
	ConfigManager.set_config_data("settings", "template_projects", [])


func open_folder(path: String):
	if path.is_empty():
		return
	if OS.has_feature("windows"):
		OS.shell_open(path)
	elif OS.has_feature("macos"):
		OS.shell_open("open " + path)
	elif OS.has_feature("linux"):
		OS.shell_open("xdg-open " + path)
		_debugger("Unsupported platform", true)


func run_as_admin() -> bool:
	var platform = ""
	var script_path = ""
	var temp_path = ""
	if OS.has_feature("windows"):
		platform = "Windows"
		script_path = "res://assets/admin/run_as_admin.bat"
	elif OS.has_feature("macos"):
		platform = "Mac"
		script_path = "res://assets/admin/run_as_admin.command"
	elif OS.has_feature("linux"):
		platform = "Linux"
		script_path = "res://assets/admin/run_as_admin.sh"
	else:
		_debugger("Unsupported platform", true)
		return false
	var script_file = FileAccess.open(script_path, FileAccess.READ)
	if script_file == null:
		_debugger("Failed to load script file", true)
		return false
	var script_content = script_file.get_as_text()
	script_file.close()
	if platform == "Windows":
		temp_path = OS.get_environment("TEMP") + "/run_as_admin.bat"
	elif platform == "Mac" or platform == "Linux":
		temp_path = "/tmp/run_as_admin.sh"
	var temp_file = FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		_debugger("Failed to create temporary file", true)
		return false
	temp_file.store_string(script_content)
	temp_file.close()
	if platform != "Windows":
		OS.execute("chmod", ["+x", temp_path])
	if _is_elevated():
		_debugger("Already running as admin/root. No relaunch needed.")
		return false
	_debugger("Relaunching the program as admin/root...")
	var executable_path = OS.get_executable_path()
	var result = OS.execute(temp_path, [executable_path], [], true)
	if result != 0:
		_debugger("Failed to relaunch the program with admin/root privileges.", true)
		return false
	else:
		_debugger("Program has been relaunched as admin/root.")
	return true


func _is_elevated() -> bool:
	if OS.has_feature("windows"):
		var result = OS.execute("cmd", ["/c", "NET SESSION"], [], true)
		return result == 0
	elif OS.has_feature("macos") or OS.has_feature("linux"):
		var result = OS.execute("id", ["-u"], [], true)
		return result == 0
	else:
		_debugger("Unsupported platform for elevation check.", true)
		return false


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
