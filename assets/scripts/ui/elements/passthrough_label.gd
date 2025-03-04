extends Label

@export var target_button: Button = null
@export var emit_on_hold: bool = false

var is_pressed: bool = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_gui_input)

func _on_mouse_entered():
	if target_button:
		target_button.mouse_entered.emit()
		target_button.queue_redraw()

func _on_mouse_exited():
	if target_button:
		target_button.mouse_exited.emit()
		target_button.queue_redraw()

func _gui_input(event):
	if target_button:
		if event is InputEventMouseMotion:
			target_button.gui_input.emit(event)
		elif event is InputEventMouseButton:
			var mask = target_button.get_button_mask()
			if event.get_button_index() == mask:
				if event.is_pressed():
					if emit_on_hold or not is_pressed:
						target_button.button_down.emit()
						if target_button.is_toggle_mode():
							target_button.toggled.emit(!target_button.is_pressed())
						else:
							target_button.pressed.emit()
						is_pressed = true
				else:
					target_button.button_up.emit()
					is_pressed = false
		target_button.queue_redraw()
