extends Node

const DEBUGGER: bool = false

const MANAGER_GITHUB_API: String = "https://api.github.com/repos/BuckWildGames/GodotManagerGDS/releases"

func check_for_update() -> void:
	_fetch_from_github()


func _fetch_from_github() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)
	var url = MANAGER_GITHUB_API
	var error = http_request.request(url)
	if error != OK:
		_debugger("Failed to request releases", true)
		http_request.queue_free()


func _on_http_request_completed(_result, response_code, _headers, body) -> void:
	if response_code != 200:
		_debugger("Failed to fetch versions from GitHub, Response Code: " + str(response_code), true)
		return
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		_debugger("Failed to parse JSON response", true)
		return
	var releases = json.get_data()
	if not releases is Array:
		releases = [releases]
	var new_update = false
	for release in releases:
		if "tag_name" in release:
			var version_name = release["tag_name"]
			if _compare_version(version_name) == 1:
				new_update = true
				_debugger("Not Using Current Version")
				NotificationManager.show_prompt("A New Update Is Available", ["Close", "GoTo"], self, "_on_update")
	_debugger("Fetched %d versions: " % releases.size())
	if not new_update:
		_debugger("Using Current Version")
		queue_free()


func _compare_version(version_name: String) -> int:
	var version = version_name.lstrip("v")
	version = version.substr(0, 5)
	var version_array = version.split(".")
	var current_version = ConfigManager.get_version()
	var current_array = current_version.split(".")
	var return_var = 0 #0 ==, 1 >, -1 <
	if version_array[0] > current_array[0]:
		return_var = 1
	elif version_array[0] < current_array[0]:
		return_var = -1
	else:
		if version_array[1] > current_array[1]:
			return_var = 1
		elif version_array[1] < current_array[1]:
			return_var = -1
		else:
			if version_array[2] > current_array[2]:
				return_var = 1
			elif version_array[2] < current_array[2]:
				return_var = -1
	return return_var


func _on_update(option: String) -> void:
	if option == "GoTo":
		OS.shell_open("https://github.com/BuckWildGames/GodotManagerGDS/releases")
	queue_free()


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
