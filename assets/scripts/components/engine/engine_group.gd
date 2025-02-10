extends Control

@export var hide_empty: bool = true

@onready var group_container: VBoxContainer = $GroupContainer


func _on_hide_button_pressed() -> void:
	if not group_container:
		return
	if group_container.get_child_count() <= 0:
		NotificationManager.notify("Group Empty", 2.0, true)
		return
	group_container.set_visible(!group_container.is_visible())


func _process(_delta: float) -> void:
	if not hide_empty:
		set_process(false)
		return
	if group_container.get_child_count() <= 0:
		if is_visible():
			set_visible(false)
	elif !is_visible():
		set_visible(true)
		
