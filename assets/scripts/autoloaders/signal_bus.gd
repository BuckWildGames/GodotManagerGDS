extends Node

const DEBUGGER: bool = false

# Declare custom signals for reporting events
signal event_triggered(event_name: String, args: Array)

# Store registered events and their listeners (optional, for manual control)
var events: Dictionary = {}


# Register an event listener
func register_event(event_name: String, target: Object, callback_name: String, binds: Array = [], overwrite: bool = false) -> void:
	if not events.has(event_name):
		events[event_name] = []
	if not _check_duplicate(event_name, target, callback_name):
		events[event_name].append({"target": target, "callback": callback_name, "binds": binds, "overwrite": overwrite})
	else:
		_debugger("Event already registered. event_name: " +str(event_name))


# Emit an event (trigger the signal)
func emit_event(event_name: String, args: Array = []) -> void:
	event_triggered.emit(event_name, args)
	if events.has(event_name):
		var this_args = []
		for listener in events[event_name]:
			if listener.target and listener.target.has_method(listener.callback):
				if listener.overwrite:
					this_args = listener.binds
				else:
					this_args = args.duplicate()
					this_args.append_array(listener.binds)
				listener.target.callv(listener.callback, this_args)
			else:
				_debugger("Listener method not found or target invalid. event_name: " +str(event_name) +". listener: " +str(listener))
	else:
		_debugger("Event has no listeners. event_name: " +str(event_name))


func forward_event(arg0 = null, arg1 = null, arg2 = null, arg3 = null, arg4 = null) -> void:
	var event_name = ""
	var args = []
	for arg in 5:
		match arg:
			0:
				if arg0 != null:
					args.append(arg0)
				else:
					event_name = arg1
					break
			1:
				if arg1 != null:
					args.append(arg1)
				else:
					args.erase(arg0)
					event_name = arg0
					break
			2:
				if arg2 != null:
					args.append(arg2)
				else:
					args.erase(arg1)
					event_name = arg1
					break
			3:
				if arg3 != null:
					args.append(arg3)
				else:
					args.erase(arg2)
					event_name = arg2
					break
			4:
				if arg4 != null:
					event_name = arg4
				else:
					args.erase(arg3)
					event_name = arg3
					break
	emit_event(event_name, args)


# Remove a listener from an event
func unregister_event(event_name: String, target: Object, callback_name: String) -> void:
	if events.has(event_name):
		events[event_name] = events[event_name].filter(
			func(listener):
				return not (listener.target == target and listener.callback == callback_name)
		)


func _check_duplicate(event_name: String, target: Object, method_name: String) -> bool:
	for event in events[event_name]:
		if event.target == target and event.callback == method_name:
			return true
	return false


func _debugger(debug_message) -> void:
	DebugManager.log_debug(debug_message, str(get_script().get_path()))
	# Check if script is debug
	if DEBUGGER == true:
		# Check if os debug on
		if OS.is_debug_build():
			# Print message
			print_debug(debug_message)
