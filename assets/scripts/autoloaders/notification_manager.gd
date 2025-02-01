extends Node

const DEBUGGER: bool = false

# Notification UI settings
enum PanelPosition {LEFT, CENTER, RIGHT}
var panel_position: PanelPosition = PanelPosition.RIGHT
var notification_margin: Vector2 = Vector2(20, 75)
var notification_width: float = 300.0
var notification_height: float = 50.0
var prompt_margin: Vector2 = Vector2(50, 50)
var prompt_width: float = 500.0
var prompt_height: float = 200.0
var default_margin: Vector2 = Vector2(40, 40)
var default_alpha: float = 0.8

var canvas_layer: CanvasLayer
var active_notifications: Array = []
var prompt_active: bool = false


# Initialize the UI system
func _ready() -> void:
	call_deferred("_get_canvas")


func connect_notification_to_signal(_signal_name: String, _text: String, _timeout: float, _clickable: bool = false) -> void:
	pass
	#SignalBus.register_event(signal_name, self, "notify", [text, timeout, clickable], true)


# Display a notification
func notify(text: String, timeout: float, clickable: bool = false, target: Object = null, callback_name: String = "", font_size: int = 16) -> void:
	if canvas_layer:
		var panel = _create_notification_panel(text, font_size)
		canvas_layer.add_child(panel)
		_position_notification(panel)
		if timeout > 0:
			var timer = _create_timer(timeout)
			panel.add_child(timer)
			timer.timeout.connect(_on_notification_timeout.bind(panel))
			timer.start()
		elif not clickable:
			clickable = true
		if clickable:
			panel.gui_input.connect(_on_notification_pressed.bind(panel, target, callback_name))
		active_notifications.append(panel)
		canvas_layer.show()
		_debugger("Notification created: " +text)


# Show the prompt with a question and options, including a timeout and default option
func show_prompt(question: String, options: Array[String], target: Object, callback_name: String, timeout: float = -1.0, default_option: String = "", font_size: int = 16) -> void:
	if canvas_layer:
		var prompt = _create_prompt(question, options, target, callback_name, font_size)
		# Start a timer if timeout is set
		if timeout > 0:
			var timer = _create_timer(timeout)
			prompt.add_child(timer)
			timer.timeout.connect(_on_prompt_timeout.bind(default_option, prompt, target, callback_name))
			timer.start()
		canvas_layer.show()
		prompt_active = true
		_debugger("Prompt created: " +question)


func has_active_prompt() -> bool:
	return prompt_active


func _get_canvas() -> void:
	var ui = System.get_manager("ui")
	if not ui:
		_debugger("UI Manager not found")
		return
	var canvas = ui.get_canvas("notification")
	if not canvas:
		_debugger("Notification canvas not found")
		return
	canvas_layer = canvas
	#canvas_layer = CanvasLayer.new()
	#add_child(canvas_layer) #get_tree().get_root().


# Create a notification panel
func _create_notification_panel(text: String, font_size: int) -> Control:
	var panel = PanelContainer.new()
	var colour = panel.get_modulate()
	colour.a = default_alpha
	panel.set_modulate(colour)
	panel.set_custom_minimum_size(Vector2(notification_width, notification_height))
	var label = Label.new()
	panel.add_child(label)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.set_text(_insert_line_breaks(text, notification_width, font_size))
	#label.set_autowrap_mode(TextServer.AUTOWRAP_WORD)
	label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
	label.add_theme_font_size_override("font_size", font_size)
	return panel


# Position the notification panel
func _position_notification(panel: Control, list_position: int = active_notifications.size()) -> void:
	var screen_size = get_viewport().get_canvas_transform().get_origin() + get_viewport().get_visible_rect().size
	var panel_size = panel.get_size()
	var panel_x = 0.0
	match panel_position:
		PanelPosition.LEFT:
			panel_x = notification_margin.x
			panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		PanelPosition.CENTER:
			panel_x = (screen_size.x - panel_size.x) / 2
			panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
		PanelPosition.RIGHT:
			panel_x = screen_size.x - panel_size.x - notification_margin.x
			panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	var panel_pos = Vector2(panel_x, notification_margin.y)
	panel.set_position(panel_pos + Vector2(0, list_position * (panel.get_size().y + 10)))


func _create_prompt(question: String, options: Array[String], target: Object, callback_name: String, font_size: int) -> Control:
	# Get screen size
	var screen_size = get_viewport().get_canvas_transform().get_origin() + get_viewport().get_visible_rect().size
	# Minimum size for the prompt panel
	var min_panel_size = Vector2(prompt_width, prompt_height)
	# Create a full-screen overlay
	var overlay = Panel.new()
	canvas_layer.add_child(overlay)
	var colour = overlay.get_modulate()
	colour.a = default_alpha
	overlay.set_modulate(colour)
	overlay.set_custom_minimum_size(screen_size)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Create a centered prompt panel
	var prompt_panel = PanelContainer.new()
	overlay.add_child(prompt_panel)
	prompt_panel.set_custom_minimum_size(min_panel_size)
	prompt_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# Create a margin
	var margin = MarginContainer.new()
	prompt_panel.add_child(margin)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.set_custom_minimum_size(min_panel_size)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Create a vertical container to hold the question and buttons
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	vbox.add_theme_constant_override("separation", 32)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.set_alignment(BoxContainer.ALIGNMENT_CENTER)
	vbox.set_custom_minimum_size(min_panel_size)
	# Add question label
	var question_label = Label.new()
	vbox.add_child(question_label)
	question_label.set_text(_insert_line_breaks(question, screen_size.x, font_size))
	#question_label.set_autowrap_mode(TextServer.AUTOWRAP_WORD)
	question_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	question_label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
	question_label.add_theme_font_size_override("font_size", font_size + 8)
	question_label.set_custom_minimum_size(Vector2(question_label.get_combined_minimum_size().x + default_margin.x, question_label.get_combined_minimum_size().y + default_margin.y))
	# Add button container
	var button_container = HBoxContainer.new()
	vbox.add_child(button_container)
	button_container.add_theme_constant_override("separation", 16)
	button_container.set_alignment(BoxContainer.ALIGNMENT_CENTER)
	button_container.set_custom_minimum_size(Vector2(min_panel_size.x + default_margin.x, font_size + default_margin.y))
	# Create buttons for each option
	for option in options:
		var button = Button.new()
		button_container.add_child(button)
		button.set_text(option)
		button.add_theme_font_size_override("font_size", font_size)
		button.set_custom_minimum_size(Vector2(button.get_combined_minimum_size().x + default_margin.x, font_size + default_margin.y))
		button.pressed.connect(_on_option_button_pressed.bind(option, overlay, target, callback_name))
		if option == options.back():
			button.grab_focus()
	# Recenter panel
	var pos = Vector2(screen_size.x - prompt_panel.get_combined_minimum_size().x, screen_size.y - prompt_panel.get_combined_minimum_size().y)
	prompt_panel.set_position(pos / 2)
	return overlay


func _create_timer(timeout: float) -> Timer:
	var timer = Timer.new()
	timer.set_wait_time(timeout)
	timer.set_one_shot(true)
	return timer


func _reorder_notifications() -> void:
	for panel in active_notifications:
		var num = active_notifications.find(panel)
		_position_notification(panel, num)


func _insert_line_breaks(text: String, max_width: float, font_size: float) -> String:
	# Estimate the average width of a character as half the font size
	var char_width = font_size * 0.5
	# Calculate the maximum number of characters that can fit on a line
	var max_chars_per_line = int(max_width / char_width)
	var formatted_text = ""
	# Split the text into existing lines
	var lines = text.split("\n")
	for line in lines:
		var words = line.split(" ")
		var current_line = ""
		for word in words:
			var test_line
			if current_line.is_empty():
				test_line = word
			else:
				test_line = current_line + " " + word
			if test_line.length() > max_chars_per_line:
				# Add the current line to the formatted text and start a new line
				formatted_text += current_line + "\n"
				current_line = word
			else:
				current_line = test_line
		# Add the last line of the current section
		formatted_text += current_line + "\n"
	# Remove any trailing newline
	return formatted_text.strip_edges()


# Hide and remove the notification
func _hide_notification(panel: Control) -> void:
	if active_notifications.has(panel):
		active_notifications.erase(panel)
	_reorder_notifications()
	panel.queue_free()


# Handle notification click
func _on_notification_pressed(event: InputEvent, panel: Control, target: Object = null, callback_name: String = "") -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_debugger("Notification pressed")
		_hide_notification(panel)
		if target and callback_name != "":
			target.call(callback_name)


# Handle timer timeout to hide the notification
func _on_notification_timeout(panel: Control) -> void:
	_hide_notification(panel)


# Handle button press in the prompt
func _on_option_button_pressed(option: String, prompt: Control, target: Object, callback_name: String) -> void:
	_debugger("Prompt option selected: " +option)
	prompt.queue_free()
	prompt_active = false
	if target and callback_name != "":
		target.callv(callback_name, [option])


# Handle prompt timeout
func _on_prompt_timeout(default_option: String, prompt: Control, target: Object, callback_name: String) -> void:
	_debugger("Prompt timed out")
	if default_option == "":
		prompt.queue_free()
		return
	_on_option_button_pressed(default_option, prompt, target, callback_name)


func _debugger(debug_message: String) -> void:
	DebugManager.log_debug(debug_message, str(get_script().get_path()))
	# Check if script is debug
	if DEBUGGER == true:
		# Check if os debug on
		if OS.is_debug_build():
			# Print message
			print_debug(debug_message)
