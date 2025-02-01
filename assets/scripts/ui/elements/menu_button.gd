extends Button

const FOCUS_MARKER: String = "> "
const END_FOCUS_MARKER: String = " <"

@export var focus_allowed: bool = false
@export var focused : bool = false
@export var focus_on_click: bool = true
@export var focus_on_hover: bool = true
@export var use_text_marker: bool = false
@export var marker_at_end: bool = true

func _ready() -> void:
	if not focus_allowed:
		set_focus_mode(Control.FOCUS_NONE)
	focus_entered.connect(_on_focus_entered)
	if focus_on_hover:
		mouse_entered.connect(_on_focus_entered)
		mouse_exited.connect(_remove_marker)
	toggled.connect(_on_toggled)
	SignalBus.register_event("ui_focus_changed", self, "_remove_marker")


#func _input(event: InputEvent) -> void:
	#var shortcuts = get_shortcut().get_events()
	#for short in shortcuts:
		#if event.is_action_pressed(short["action"]):
			#_on_toggled(!is_pressed())


func _enter_tree() -> void:
	if focused and focus_allowed:
		grab_focus()


func _on_focus_entered() -> void:
	if focus_on_hover and focus_allowed:
		grab_focus()
	SignalBus.emit_event("ui_focus_changed")
	var game_manager = System.get_manager("game")
	game_manager.pause_game()
	if use_text_marker:
		var txt = get_text()
		if not txt.begins_with(FOCUS_MARKER):
			set_text(FOCUS_MARKER+txt+END_FOCUS_MARKER)


func _remove_marker() -> void:
	if has_focus():
		release_focus()
	if not is_pressed():
		var game_manager = System.get_manager("game")
		game_manager.resume_game()
	if use_text_marker:
		var txt = get_text()
		if txt.begins_with(FOCUS_MARKER):
			txt = txt.replace(FOCUS_MARKER, "")
			txt = txt.replace(END_FOCUS_MARKER, "")
			set_text(txt)


func _on_toggled(toggled_on: bool) -> void:
	if not focus_on_click:
		if has_focus():
			release_focus()
	var game_manager = System.get_manager("game")
	if toggled_on:
		game_manager.pause_game()
		game_manager.in_menu()
	else:
		game_manager.resume_game()
