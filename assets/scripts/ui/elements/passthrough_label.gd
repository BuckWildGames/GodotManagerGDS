extends Label

@export var target_button: Button = null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_gui_input)

func _on_mouse_entered():
	if target_button:
		target_button.mouse_entered.emit()

func _on_mouse_exited():
	if target_button:
		target_button.mouse_exited.emit()

func _gui_input(event):
	if target_button:
		if event is InputEventMouseMotion:
			target_button.gui_input.emit(event)
		elif event is InputEventMouseButton:
			var mask = target_button.get_button_mask()
			if event.get_button_index() == mask:
				if event.is_pressed():
					target_button.button_down.emit()
					if target_button.is_toggle_mode():
						target_button.toggled.emit(!target_button.is_pressed())
					else:
						target_button.pressed.emit()
				else:
					target_button.button_up.emit()
