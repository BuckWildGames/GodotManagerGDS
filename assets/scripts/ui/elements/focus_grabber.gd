extends HSlider

const FOCUS_MARKER: String = ">"
const END_FOCUS_MARKER: String = " <"

@export var focus_allowed: bool = false
@export var focused : bool = false
@export var affected_text : Label
@export var focus_on_click: bool = true
@export var focus_on_hover: bool = false
@export var use_text_marker: bool = false
@export var marker_at_end: bool = true

func _ready() -> void:
	if not focus_allowed:
		set_focus_mode(Control.FOCUS_NONE)
	focus_entered.connect(_on_focus_entered)
	if focus_on_hover:
		mouse_entered.connect(_on_focus_entered)
	#pressed.connect(_on_pressed)
	SignalBus.register_event("ui_focus_changed", self, "_remove_marker")


func _enter_tree() -> void:
	if focused and focus_allowed:
		grab_focus()


func _on_focus_entered() -> void:
	if focus_on_hover and focus_allowed:
		grab_focus()
	SignalBus.emit_event("ui_focus_changed")
	if use_text_marker:
		var txt = affected_text.get_text()
		if not txt.begins_with(FOCUS_MARKER):
			affected_text.set_text(FOCUS_MARKER +txt +END_FOCUS_MARKER)


func _remove_marker() -> void:
	if use_text_marker:
		var txt = affected_text.get_text()
		if txt.begins_with(FOCUS_MARKER):
			txt = txt.replace(FOCUS_MARKER, "")
			txt = txt.replace(END_FOCUS_MARKER, "")
			affected_text.set_text(txt)


func _on_pressed() -> void:
	if not focus_on_click:
		if has_focus():
			release_focus()
