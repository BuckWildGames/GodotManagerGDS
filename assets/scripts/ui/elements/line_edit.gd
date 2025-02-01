extends LineEdit

const FOCUS_MARKER: String = "> "
const END_FOCUS_MARKER: String = " <"

@export var focused : bool = false
@export var focus_on_hover: bool = false
@export var use_text_marker: bool = false
@export var marker_at_end: bool = true

func _ready() -> void:
	focus_entered.connect(_on_focus_entered)
	if focus_on_hover:
		mouse_entered.connect(_on_focus_entered)
	SignalBus.register_event("ui_focus_changed", self, "_remove_marker")


func _enter_tree() -> void:
	if focused:
		grab_focus()


func _on_focus_entered() -> void:
	if focus_on_hover:
		grab_focus()
	SignalBus.emit_event("ui_focus_changed")
	if use_text_marker:
		var txt = get_placeholder()
		if not txt.begins_with(FOCUS_MARKER):
			set_placeholder(FOCUS_MARKER+txt+END_FOCUS_MARKER)


func _remove_marker() -> void:
	if use_text_marker:
		var txt = get_placeholder()
		if txt.begins_with(FOCUS_MARKER):
			txt = txt.replace(FOCUS_MARKER, "")
			txt = txt.replace(END_FOCUS_MARKER, "")
			set_placeholder(txt)
