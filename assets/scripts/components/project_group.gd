extends Control
class_name ProjectGroup

@export var hide_empty: bool = true

@onready var group_container: VBoxContainer = $GroupVBox/GroupContainer
@onready var title_node = $GroupVBox/Main/Title

var master: Control = null
var this_group: int = -1
var title: String = ""


func setup(new_master: Control, group: int, new_title: String = "") -> void:
	master = new_master
	this_group = group
	title = new_title
	title_node.set_text(title)


func get_container() -> Container:
	return group_container


func _on_hide_button_pressed() -> void:
	if not group_container:
		return
	if group_container.get_child_count() <= 0:
		NotificationManager.notify("Group Empty", 2.0, true)
		return
	group_container.set_visible(!group_container.is_visible())


func _on_group_button_pressed() -> void:
	if master:
		pass


func _process(_delta: float) -> void:
	if not hide_empty:
		set_process(false)
		return
	if group_container.get_child_count() <= 0:
		if is_visible():
			set_visible(false)
	elif !is_visible():
		set_visible(true)
		
