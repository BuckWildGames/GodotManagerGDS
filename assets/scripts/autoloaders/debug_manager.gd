extends Node

const FORWARD_SIGNALS: bool = false
const SIGNAL_KEYWORD: String = "reported"

# Define the signal to notify when an error or debug message occurs
signal error_reported(error_message: String, details: Dictionary)
signal debug_reported(message: String)

# Store logs for debugging
var error_logs: Array = []
var debug_logs: Array = []


func _init() -> void:
	var path = "user://error_log.txt"
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_line("Errors:")
	file.close()
	path = "user://debug_log.txt"
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_line("Debugger:")
	file.close()


func _ready() -> void:
	if FORWARD_SIGNALS:
		_forward_to_signal_bus()


# Log error messages and emit an error signal
func log_error(error_message: String, script_caller: String, details: Dictionary = {}) -> void:
	error_logs.append({"error_message": error_message, "script_caller": script_caller, "details": details})
	error_reported.emit(error_message +"\n" +script_caller, details)
	_print_error(error_message, details, script_caller)


# Log debug messages and emit a debug signal
func log_debug(message: String, script_caller: String) -> void:
	debug_logs.append({"message": message, "script_caller": script_caller})
	debug_reported.emit(message +"\n" +script_caller)
	_print_debug(message, script_caller)


# Function to print errors with more context
func _print_error(error_message: String, details: Dictionary, script_caller: String) -> void:
	# You can format and print more detailed error information here
	print("ERROR: ", error_message, details, "\n", script_caller)
	# Optionally, you can write it to a file, for example, a log file:
	var path = "user://error_log.txt"
	var file = FileAccess.open(path, FileAccess.READ_WRITE)
	file.seek_end()
	file.store_line(error_message +str(details) +"\n" +script_caller)
	file.close()


# Function to print debug messages
func _print_debug(debug_message: String, script_caller: String) -> void:
	# You can format and print more detailed debug information here
	print("DEBUG: ", debug_message, "\n", script_caller)
	# Optionally, write it to a debug log file:
	var path = "user://debug_log.txt"
	var file = FileAccess.open(path, FileAccess.READ_WRITE)
	file.seek_end()
	file.store_line(debug_message +"\n" +script_caller)
	file.close()


func _forward_to_signal_bus() -> void:
	var list = get_signal_list()
	for this_signal in list:
		var signal_name = this_signal["name"]
		if SIGNAL_KEYWORD in signal_name:
			pass
			#connect(signal_name, SignalBus.forward_event.bind(signal_name))
			#log_debug("Signal forwarded: " +str(signal_name), get_script().get_path())
