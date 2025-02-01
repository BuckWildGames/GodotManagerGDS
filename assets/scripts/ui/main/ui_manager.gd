extends Node

const DEBUGGER: bool = false
const FORWARD_SIGNALS: bool = true
const SIGNAL_KEYWORD: String = "ui"

@export var canvas_layers: Array [CanvasLayer]
@export_range (0, 10) var starting_layer: int = 0
@export var default_fade_time: float = 1.0

var current_canvas: String = "menu"
var current_panel: String = "title"
var canvass: Dictionary = {}
var panels: Dictionary = {}
var fade_colour_rect: ColorRect = null
var fade_canvas: CanvasLayer = null

signal ui_faded_out()
signal ui_faded_in()


func _ready() -> void:
	for canvas in canvas_layers:
		_get_panels(canvas)
	fade_colour_rect = _create_rect()
	if FORWARD_SIGNALS:
		_forward_to_signal_bus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		panels[current_canvas][current_panel].back()


func transition(to_canvas: String, to_panel: String) -> void:
	if not canvass.has(to_canvas):
		_debugger("Canvas not found")
		return
	if not panels[to_canvas].has(to_panel):
		_debugger("Panel not found")
		return
	if not panels[current_canvas][current_panel].persistent:
		canvass[current_canvas].remove_child(panels[current_canvas][current_panel])
	canvass[to_canvas].add_child(panels[to_canvas][to_panel])
	canvass[to_canvas].move_child(panels[to_canvas][to_panel], 0)
	#panels[current_canvas][current_panel].hide()
	#panels[to_canvas][to_panel].show()
	panels[to_canvas][to_panel].enter(current_panel)
	current_panel = to_panel
	if current_canvas != to_canvas:
		canvass[current_canvas].hide()
		canvass[to_canvas].show()
		current_canvas = to_canvas


func fade_out(fade_time: float = default_fade_time) -> void:
	if not fade_colour_rect:
		_debugger("fade color rect is not set")
		return
	for canvas in canvass:
		canvass[canvas].set_visible(false)
	fade_canvas.set_visible(true)
	fade_colour_rect.set_visible(true)
	var colour = Color.BLACK
	colour.a = 1.0
	var tween = fade_colour_rect.create_tween()
	tween.tween_property(fade_colour_rect, "color", colour, fade_time)
	tween.tween_callback(ui_faded_out.emit)


func fade_in(fade_time: float = default_fade_time) -> void:
	if not fade_colour_rect:
		_debugger("fade color rect is not set")
		return
	for canvas in canvass:
		canvass[canvas].set_visible(true)
	fade_colour_rect.set_visible(true)
	var colour = Color.BLACK
	colour.a = 0.0
	var tween = fade_colour_rect.create_tween()
	tween.tween_property(fade_colour_rect, "color", colour, fade_time)
	tween.tween_callback(ui_faded_in.emit)
	fade_colour_rect.set_visible(false)


func perform_fade(fade_time: float = default_fade_time) -> void:
	if not fade_colour_rect:
		_debugger("fade color rect is not set")
		return
	fade_out(fade_time)
	await ui_faded_out
	fade_in(fade_time)


func set_panel_variable(canvas: String, panel: String, variable_name: String, value: Variant) -> void:
	if not canvass.has(canvas):
		_debugger("Canvas not found")
		return
	if not panels[canvas].has(panel):
		_debugger("Panel not found")
		return
	var target: Node = panels[canvas][panel]
	target.set(variable_name, value)


func enter(at_title: bool = true) -> void:
	if at_title:
		transition("menu", "title")
	else:
		transition("menu", "menu")


func reload_current_panel() -> void:
	var previous_panel = panels[current_canvas][current_panel].previous_panel
	panels[current_canvas][current_panel].enter(previous_panel)


func get_canvas(canvas_name: String) -> CanvasLayer:
	canvas_name = canvas_name.to_lower()
	if not canvass.has(canvas_name):
		return null
	return canvass[canvas_name]


func _get_panels(canvas: CanvasLayer) -> void:
	if canvas != null:
		var canvas_name = canvas.get_name().to_lower()
		if not canvass.has(canvas_name):
			canvass[canvas_name] = canvas
		var starting_canvas = canvas == canvas_layers[starting_layer]
		if not starting_canvas:
			canvas.hide()
		else:
			current_canvas = canvas_name
			canvas.show()
		for child : Node in canvas.get_children():
			if child is UIState:
				var child_name = child.get_name().to_lower()
				if not panels.has(canvas_name):
					panels[canvas_name] = {}
				panels[canvas_name][child_name] = child
				child.show()
				child.master = self
				if not child.start or not starting_canvas:
					canvas.remove_child(child)
					#child.hide()
				else:
					current_panel = child_name


func _create_rect() -> ColorRect:
	var rect = ColorRect.new()
	if rect:
		var keys = canvass.keys()
		var canvas = canvass[keys[keys.size() - 1]]
		if canvas:
			fade_canvas = canvas
			canvas.add_child(rect)
			rect.set_visible(false)
			rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			rect.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
			var colour = Color.BLACK
			colour.a = 0.0
			rect.set_color(colour)
		else:
			rect.queue_free()
			rect = null
	return rect


func _exit_tree() -> void:
	for canvas in panels:
		for panel in panels[canvas]:
			panels[canvas][panel].queue_free()


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
