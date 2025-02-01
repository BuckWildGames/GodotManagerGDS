extends Node

const DEBUGGER: bool = false
const FORWARD_SIGNALS: bool = false
const SIGNAL_KEYWORD: String = "system"

# System states
enum SystemState {
	LOADING,
	MAIN_MENU,
	IN_MENU,
	IN_GAME,
	PAUSED
}

# Current system state
var current_state: SystemState = SystemState.MAIN_MENU

# System variables
var current_scene: PackedScene = null
var current_scene_name: String = ""
var globals: Dictionary = {}


# Container node to manage scenes
var game_manager: Node = null
var ui_manager: Node = null
var main_container_node: Node = null

signal system_saved()
signal system_loaded()
signal system_reset()


func _ready() -> void:
	if game_manager == null:
		_debugger("Game Manager not found.")
	if ui_manager == null:
		_debugger("UI Manager not found.")
	if main_container_node == null:
		_debugger("Main Container node not found, default to Game Manager.")
	if FORWARD_SIGNALS:
		_forward_to_signal_bus()


func get_manager(manager_name: String) -> Node:
	manager_name = manager_name.to_lower()
	if "game" in manager_name:
		return game_manager
	elif "ui" in manager_name:
		return ui_manager
	return null


func set_state(state: String) -> void:
	state = state.to_upper()
	if not SystemState.keys().has(state):
		_debugger("System state not found")
		return
	var num = SystemState.keys().find(state)
	current_state = SystemState.values()[num]
	_debugger("System state changed: " +state)


func get_state() -> String:
	var string = SystemState.keys()[current_state]
	return str(string)


func save_system() -> void:
	# Put save stuff here
	#var data = {"levels_complete": get_global("levels_complete")}
	#FileManager.save_data("user://", "save.json", data, true)
	system_saved.emit()
	_debugger("System saved")


func load_system() -> void:
	# Put load stuff here
	#var data = FileManager.load_data("user://", "save.json")
	#if data:
		#set_global("levels_complete", data["levels_complete"])
	system_loaded.emit()
	_debugger("System loaded")


func reset_system() -> void:
	if current_state == SystemState.IN_GAME:
		if game_manager:
			game_manager.game_ended.emit()
	current_state = SystemState.IN_MENU
	system_reset.emit()
	_debugger("System reset")
	get_tree().reload_current_scene()


func quit_system() -> void:
	_debugger("System quit")
	get_tree().quit()


func set_current_scene(scene: PackedScene, scene_name: String) -> void:
	current_scene = scene
	current_scene_name = scene_name
	_debugger("Current scene set: " +str(scene_name))


func get_current_scene() -> PackedScene:
	return current_scene


func get_current_scene_name() -> String:
	return current_scene_name


func reload_current_scene() -> void:
	if current_scene:
		remove_scene_from_container(current_scene_name)
		add_scene_to_container(current_scene)


func set_global(global_name: String, global_var: Variant) -> void:
	globals[global_name] = global_var
	_debugger("Set global: " +str(global_name) +", " +str(global_var))


func get_global(global_name: String) -> Variant:
	if !globals.has(global_name):
		return
	var global_var = globals[global_name]
	_debugger("Get global: " +str(global_name) +", " +str(global_var))
	return global_var


func erase_global(global_name: String) -> void:
	if globals.has(global_name):
		globals.erase(global_name)
		_debugger("Erased global: " +str(global_name))


func clear_globals() -> void:
	globals.clear()
	_debugger("Cleared globals")


func transition_to_scene(scene_pack: PackedScene, scene_name: String, container_path: String = "") -> void:
	if ui_manager:
		ui_manager.fade_out()
		await ui_manager.ui_faded_out
		remove_scene_from_container(get_current_scene_name(), container_path)
		add_scene_to_container(scene_pack, container_path)
		set_current_scene(scene_pack, scene_name)
		ui_manager.fade_in()
	else:
		_debugger("Ui Manager not found")


func add_scene_to_container(scene_pack: PackedScene, container_path: String = "") -> void:
	var new_scene = scene_pack.instantiate()
	if new_scene:
		var container_node = _get_container(container_path)
		if container_node:
			container_node.add_child(new_scene)
		else:
			new_scene.queue_free()
	else:
		_debugger("Invalid scene pack: " +str(scene_pack))


func remove_scene_from_container(scene_name: String, container_path: String = "") -> void:
	var container_node = _get_container(container_path)
	if container_node:
		for child in container_node.get_children():
			if child.get_name() == scene_name:
				container_node.remove_child(child)
				child.queue_free()  # Optionally free the scene from memory
				_debugger("Removed scene: " +str(scene_name))
				return
		_debugger("Invalid scene name: " +str(scene_name))


func set_scene_visible_in_container(scene_name: String, is_visible: bool, container_path: String = "") -> void:
	var container_node = _get_container(container_path)
	if container_node:
		for child in container_node.get_children():
			if child.get_name() == scene_name:
				child.set_visible_in_tree(is_visible)
				_debugger("Set scene visible: " +str(scene_name) +", " +str(is_visible))
				return
		_debugger("Invalid scene name: " +str(scene_name))


func clear_container(container_path: String = "") -> void:
	var container_node = _get_container(container_path)
	if container_node:
		for child in container_node.get_children():
			child.queue_free()
		_debugger("Cleared container node: " +container_node.get_name())


func get_vars(node: Node) -> Dictionary:
	var vars = {}
	if node:
		for property in node.get_property_list():
			if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				vars[property["name"]] = node.get(property["name"])
	return vars


func set_vars(node: Node, vars: Dictionary) -> void:
	if node and vars != {}:
		for property in vars.keys():
			node.set(property, vars[property])


func _get_container(container_path: String) -> Node:
	var container_node = null
	if container_path == "":
		if main_container_node:
			container_node = main_container_node
		elif game_manager:
			container_node = game_manager
	else:
		var container = get_node(container_path)
		if container:
			container_node = container
		else:
			_debugger("Invalid container path: " +str(container_path))
	return container_node


func _forward_to_signal_bus() -> void:
	var list = get_signal_list()
	for this_signal in list:
		var signal_name = this_signal["name"]
		if SIGNAL_KEYWORD in signal_name:
			pass
			#connect(signal_name, SignalBus.forward_event.bind(signal_name))
			#_debugger("Signal forwarded: " +str(signal_name))


func _debugger(debug_message: String) -> void:
	DebugManager.log_debug(debug_message, str(get_script().get_path()))
	# Check if script is debug
	if DEBUGGER == true:
		# Check if os debug on
		if OS.is_debug_build():
			# Print message
			print_debug(debug_message)
