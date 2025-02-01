extends Panel
class_name UIState

@export var start: bool = false
@export var can_go_back: bool = true
@export var persistent: bool = false

@onready var canvas_layer: CanvasLayer = get_parent()
@onready var canvas: String = get_parent().get_name().to_lower()

var master: Node
var previous_panel: String = ""


func enter(previous : String) -> void:
	if !previous_panel:
		previous_panel = previous


func transition(to_panel: String) -> void:
	master.transition(canvas, to_panel)


func set_panel_variable(panel: String, variable_name: String, value: Variant) -> void:
	master.set_panel_variable(canvas, panel, variable_name, value)


func reload_current_panel() -> void:
	master.reload_current_panel()


func button_pressed(_button: String) -> void:
	pass
	# match button:
		# "button":
			# Do stuff


func button_toggled(_toggled_on: bool, _button: String) -> void:
	pass
	# match button:
		# "button":
			# Do stuff


func value_received(_value: Variant, _button: String) -> void:
	pass
	# match button:
		# "button":
			# Do stuff


func back():
	if can_go_back:
		transition(previous_panel)
