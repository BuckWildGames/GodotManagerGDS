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
		#_call_all_connections("mouse_entered")
		target_button.notification(NOTIFICATION_MOUSE_ENTER)
		target_button.mouse_entered.emit()

func _on_mouse_exited():
	if target_button:
		#_call_all_connections("mouse_exited")
		target_button.notification(NOTIFICATION_MOUSE_EXIT)
		target_button.mouse_exited.emit()

func _gui_input(event):
	if target_button:
		if event is InputEventMouseMotion:
			#_call_all_connections("gui_input")
			target_button.gui_input.emit(event)
		elif event is InputEventMouseButton:
			var mask = target_button.get_button_mask()
			if event.get_button_index() == mask:
				if event.is_pressed():
					if emit_on_hold or not is_pressed:
						#_call_all_connections("button_down")
						target_button.button_down.emit()
						if target_button.is_toggle_mode():
							#_call_all_connections("toggled")
							target_button.toggled.emit(!target_button.is_pressed())
						else:
							#_call_all_connections("pressed")
							target_button.pressed.emit()
						is_pressed = true
				else:
					#_call_all_connections("button_up")
					target_button.button_up.emit()
					is_pressed = false


func _call_all_connections(signal_name: String) -> void:
	if target_button:
		if target_button.has_signal(signal_name):
			var connections = target_button.get_signal_connection_list(signal_name)
			for connection in connections:
				connection["callable"].call()
