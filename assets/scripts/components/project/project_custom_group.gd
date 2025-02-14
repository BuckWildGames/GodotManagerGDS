extends ProjectGroup

@onready var menu_button: MenuButton = $GroupVBox/Main/MenuButton

var temp_title: String = ""


func _ready() -> void:
	menu_button.get_popup().index_pressed.connect(value_received.bind("popup"))
	menu_button.get_popup().transparent_bg = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		title_node.release_focus()


func value_received(value: Variant, button: String) -> void:
	match button:
		"title_changed":
			temp_title = str(value)
		"title_saved":
			ProjectManager.rename_group(this_group, str(value))
			temp_title = ""
		"popup":
			match int(value):
				0:
					ProjectManager.move_group(this_group, true)
				1:
					ProjectManager.move_group(this_group, false)
				2:
					NotificationManager.show_prompt("Delete Group?", ["No", "Yes"], self, "_on_delete")


func _on_delete(responce: String) -> void:
	if responce == "Yes":
		ProjectManager.remove_group(this_group)
		queue_free()


func _on_title_focus_exited() -> void:
	ProjectManager.rename_group(this_group, temp_title)
	temp_title = ""
