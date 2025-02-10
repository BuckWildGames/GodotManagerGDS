extends Node

const DEBUGGER: bool = false

const GODOT_GITHUB_API: String = "https://api.github.com/repos/godotengine/godot/releases"
const CACHE_FILE: String = "cache.json"

var install_dir: String = ""
var use_latest: bool = false
var cache_expiry: int = 86400 # 24 hours

var available_versions: Array = []
var installed_versions: Array = []

signal available_versions_changed()
signal installed_versions_changed()

func setup() -> void:
	check_installed_versions()
	fetch_available_versions()


func set_install_dir(new_dir: String) -> void:
	install_dir = new_dir


func set_use_latest(use: bool) -> void:
	use_latest = use


func set_cache_expiry(new_expiry: int) -> void: # Expects int days
	cache_expiry = new_expiry * 86400 # 24 hours


func get_available_versions() -> Array:
	return available_versions.duplicate()


func get_installed_versions() -> Array:
	return installed_versions.duplicate()


func check_installed_versions() -> void:
	installed_versions.clear()
	var versions = FileManager.get_folders(install_dir)
	if versions.is_empty():
		_debugger("Install dir is empty")
		return
	for version in versions:
		var is_engine = false
		var files = FileManager.get_files(install_dir + "/" + version)
		for file in files:
			if "Godot" in file and ".exe" in file:
				is_engine = true
		if is_engine:
			installed_versions.append(version)


func import_installed_version(path: String) -> void:
	var is_engine = false
	var version_name = ""
	var files = FileManager.get_files(path)
	for file in files:
		if "Godot" in file and ".exe" in file:
			version_name = file.replace(".exe", "")
			version_name = version_name.replace("_console", "")
			is_engine = true
	if is_engine:
		installed_versions.append(version_name)


func fetch_available_versions(use_cache: bool = true) -> void:
	if use_cache and _is_cache_valid():
		_load_from_cache()
	else:
		_fetch_from_github()


func get_version_index(version_name: String) -> int:
	for i in range(available_versions.size()):
		if version_name in available_versions[i]["name"]:
			return i
	return -1  # Return -1 if not found


func install_version(index: int) -> bool:
	if install_dir == "":
		_debugger("Invalid install dir", true)
		return false
	if index < 0 or index >= available_versions.size():
		_debugger("Invalid version index: " + str(index), true)
		return false
	var version = available_versions[index]
	var version_name = version["name"]
	var download_url = version["url"]
	var zip_path = install_dir + "/" + version_name + ".zip"
	var extracted_path = install_dir + "/" + version_name + "/"
	if installed_versions.has(version_name):
		_debugger("Version %s is already installed" % [version_name])
		return false
	var http_download = HTTPRequest.new()
	add_child(http_download)
	_debugger("Downloading: %s from: %s" % [version_name, download_url])
	var error = http_download.request(download_url)
	if error != OK:
		_debugger("Failed to send request to download: " + str(version_name), true)
		return false
	http_download.request_completed.connect(_on_download_completed.bind(zip_path, extracted_path, version_name))
	return true


func uninstall_version(index: int) -> bool:
	if index < 0 or index >= available_versions.size():
		_debugger("Invalid version index for uninstallation: " + str(index), true)
		return false
	var version_name = available_versions[index]["name"]
	if not installed_versions.has(version_name):
		_debugger("Version %s is not installed" % [version_name])
		return false
	FileManager.delete_folder(install_dir, version_name, false)
	installed_versions.erase(version_name)
	_debugger("Version uninstalled: " + version_name)
	installed_versions_changed.emit()
	return true


func run_project(index: int, project_path: String) -> bool:
	if index < 0 or index >= available_versions.size():
		_debugger("Invalid version index for running project: " + str(index), true)
		return false
	var version_name = available_versions[index]["name"]
	if not installed_versions.has(version_name):
		_debugger("Version %s is not installed" % [version_name])
		return false
	var godot_exe = _get_runnable_path(index)
	if FileAccess.file_exists(godot_exe):
		OS.create_process(godot_exe, [project_path])
		_debugger("Running project in Godot version: " + version_name)
	else:
		_debugger("Executable not found for: " + version_name, true)
		return false
	return true


func run_project_in_editor(index: int, project_path: String) -> bool:
	if index < 0 or index >= available_versions.size():
		_debugger("Invalid version index for running editor: " + str(index), true)
		return false
	var version_name = available_versions[index]["name"]
	if not installed_versions.has(version_name):
		_debugger("Version %s is not installed" % [version_name])
		return false
	var godot_exe = _get_runnable_path(index)
	if FileAccess.file_exists(godot_exe):
		OS.create_process(godot_exe, ["-e", project_path])
		_debugger("Running editor in Godot version: " + version_name)
	else:
		_debugger("Executable not found for: " + version_name, true)
		return false
	return true


func run_engine(index) -> bool:
	if index < 0 or index >= available_versions.size():
		_debugger("Invalid version index for running: " + str(index), true)
		return false
	var version_name = available_versions[index]["name"]
	if not installed_versions.has(version_name):
		_debugger("Version %s is not installed" % [version_name])
		return false
	var godot_exe = _get_runnable_path(index)
	if FileAccess.file_exists(godot_exe):
		OS.create_process(godot_exe, [])
		_debugger("Running Godot version: " + version_name)
	else:
		_debugger("Executable not found for: " + version_name, true)
		return false
	return true


func _is_cache_valid() -> bool:
	var cache = FileManager.load_data("user://", CACHE_FILE)
	if not cache.is_empty():
		if "timestamp" in cache and "versions" in cache:
			var now = Time.get_unix_time_from_system()
			return now - cache["timestamp"] < cache_expiry
	return false


func _load_from_cache() -> void:
	var cache = FileManager.load_data("user://", CACHE_FILE)
	if not cache.is_empty():
		if "versions" in cache:
			available_versions = cache["versions"]
			_debugger("Loaded %d versions from cache." % [available_versions.size()])
		available_versions_changed.emit()


func _fetch_from_github() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)
	var url = GODOT_GITHUB_API
	if use_latest:
		url = url + "/latest"
	var error = http_request.request(url)
	if error != OK:
		_debugger("Failed to request Godot versions", true)
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
	available_versions.clear()
	for release in releases:
		if "tag_name" in release:
			var version_name = release["tag_name"]
			var assets = release.get("assets", [])
			var done = [false, false]
			for asset in assets:
				var download_url = asset.get("browser_download_url", "")
				if download_url.ends_with(".zip"):
					if "win64.exe" in download_url:
						available_versions.append({"name": version_name, "url": download_url})
						done[0] = true
					if "mono_win64" in download_url:
						available_versions.append({"name": version_name + "-mono", "url": download_url})
						done[1] = true
					if done[0] == true and done[1] == true:
						break
	_debugger("Fetched %d versions" % [available_versions.size()])
	_save_to_cache()
	available_versions_changed.emit()


func _save_to_cache() -> void:
	var cache = {"timestamp": Time.get_unix_time_from_system(), "versions": available_versions}
	FileManager.save_data("user://", CACHE_FILE, cache, true)


func _on_download_completed(_result, response_code, _headers, body, zip_path, extracted_path, version_name) -> void:
	if response_code != 200:
		_debugger("Failed to download: %s Response Code: %s" % [version_name, response_code], true)
		return
	var file = FileAccess.open(zip_path, FileAccess.WRITE)
	if not file:
		_debugger("Failed to create zip file at: " + str(zip_path), true)
		return
	file.store_buffer(body)
	file.close()
	_debugger("Downloaded: %s to: %s" % [version_name, zip_path])
	_unzip_file(zip_path, extracted_path, version_name)


func _unzip_file(zip_path: String, extract_to: String, version_name: String) -> void:
	var zip_reader = ZIPReader.new()
	var error = zip_reader.open(zip_path)
	if error != OK:
		_debugger("Failed to open zip file: " + str(zip_path), true)
		return
	error = zip_reader.extract_all(extract_to)
	zip_reader.close()
	if error != OK:
		_debugger("Failed to extract zip for: " + str(version_name), true)
		return
	installed_versions.append(version_name)
	_debugger("Extracted: %s to: %s" %[version_name, extract_to])
	var path = zip_path.replace("/" + version_name + ".zip", "")
	var file_name = version_name + ".zip"
	FileManager.delete_file(path, file_name, false)
	installed_versions_changed.emit()


func _get_runnable_path(index: int) -> String:
	var version_name = available_versions[index]["name"]
	var extracted_path = install_dir + "/" + version_name
	var godot_exe = extracted_path + "/"
	var target_file
	if OS.has_feature("windows"):
		target_file = ".exe"
	elif OS.has_feature("macos"):
		target_file = ".app/Contents/MacOS/Godot"
	elif OS.has_feature("linux"):
		target_file = ".x86_64"  # Adjust for 32-bit if necessary
	var files = FileManager.get_files(extracted_path)
	if files == null:
		_debugger("Failed to get files in: " + extracted_path, true)
	for file in files:
		if not "console" in file and target_file in file:
			godot_exe += file
			break
	return godot_exe


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
