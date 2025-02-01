extends Node

const DEBUGGER: bool = false

var version: String = "0.0.0"
var runtime: float = 0.0

var is_updating_runtime: bool = true

var config_data: Dictionary = {
	"Version": {"first_version": version, "last_version": version},
	"Runtime": {"total_runtime": runtime, "last_runtime": runtime, "longest_runtime": runtime},
	"User": {},
	"Settings": {}, 
	"Other": {}
}


func get_version() -> String:
	return _get_current_version()


# Set config data (cat must be 0-2) or will fail
func set_config_data(category: String, data_name: String , data: Variant) -> bool:
	var complete = false
	category = category.capitalize()
	if config_data.has(category):
		config_data[category][data_name] = data
		complete = true
	return complete


func get_config_data(category: String, data_name: String) -> Variant:
	var value = null
	category = category.capitalize()
	if config_data.has(category) and config_data[category].has(data_name):
		value = config_data[category][data_name]
	return value


func erase_config_data(category: String, data_name: String) -> bool:
	var complete = false
	category = category.capitalize()
	if config_data.has(category) and config_data[category].has(data_name):
		config_data[category].erase(data_name)
		complete = true
	return complete


func get_config_category(category: String) -> Variant:
	var value = null
	category = category.capitalize()
	if config_data.has(category):
		value = config_data[category].duplicate(true)
	return value


# Clear config data (cat must be 0-2) or will fail
func clear_config_category(category: String) -> bool:
	var complete = false
	category = category.capitalize()
	if config_data.has(category):
		config_data[category].clear()
		complete = true
	return complete


# Get the current runtime in hours, minutes, and seconds
func get_formatted_runtime() -> String:
	var time = runtime + config_data["Runtime"]["total_runtime"]
	var hours = int(time / 3600)
	var minutes = int(float(int(time) % 3600) / 60)
	var seconds = int(time) % 60
	return str(hours) + ":" + str(minutes) + ":" + str(seconds)


# Set auto update runtime
func set_is_updating_runtime(is_updating: bool) -> void:
	is_updating_runtime = is_updating


# Manual call of update runtime (returns -1 if not set)
func update_runtime(delta: float) -> float:
	if not is_updating_runtime:
		runtime += 1.0 * delta
		return runtime
	return -1.0


func _process(delta: float) -> void:
	# Check if should process
	if is_updating_runtime:
		runtime += 1.0 * delta


func _get_current_version() -> String:
	var project_version = ProjectSettings.get_setting("application/config/version")
	if not project_version:
		return version
	return project_version


func _compare_runtime(play_time: float) -> bool:
	if runtime > play_time:
		return true
	return false


func _update_data() -> void:
	# Set last version
	config_data["Version"]["last_version"] = _get_current_version()
	# Set total runtime
	config_data["Runtime"]["total_runtime"] += runtime
	# Set session
	config_data["Runtime"]["last_runtime"] = runtime
	# Compare runtime
	if _compare_runtime(config_data["Runtime"]["longest_runtime"]):
		config_data["Runtime"]["longest_runtime"] = runtime


func _save_data() -> bool:
	# Set debug
	var debug: String = "_save_data(). "
	# Set return var
	var complete = false
	# Update 
	_update_data()
	# Create new config file
	var config = ConfigFile.new()
	# Set values.
	for section in config_data.keys():
		for key in config_data[section].keys():
			config.set_value(section, key, config_data[section][key])
	# Save file
	var error = config.save("user://config.cfg")
	# Check error
	if error == OK:
		# Set complete
		complete = true
		# Set debug
		debug += "Complete. "
	else:
		# Set debug
		debug += "Failed. "
	# Close config
	config = null
	# Send to debug
	_debugger(debug)
	# Return var
	return complete


func _load_data() -> bool:
	# Set debug
	var debug: String = "_load_data(). "
	# Set return var
	var complete = false
	# Create new config file
	var config = ConfigFile.new()
	# Load data from a file.
	var error = config.load("user://config.cfg")
	# Check error
	if error == OK:
		# Convert the config file settings to a dictionary
		for section in config.get_sections():
			for key in config.get_section_keys(section):
				config_data[section][key] = config.get_value(section, key)
		# Set complete
		complete = true
		# Set debug
		debug += "Complete. "
	else:
		# Set debug
		debug += "Failed. "
	# Close config
	config = null
	# Send to debug
	_debugger(debug)
	# Return var
	return complete


func _debugger(debug_message: String) -> void:
	DebugManager.log_debug(debug_message, str(get_script().get_path()))
	# Check if script is debug
	if DEBUGGER:
		# Check if os debug on
		if OS.is_debug_build():
			# Print message
			print_debug(debug_message)


func _enter_tree() -> void:
	# Load data
	_load_data()


func _exit_tree() -> void:
	# Load data
	_save_data()
