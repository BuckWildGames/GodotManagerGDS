extends FileDialog

var path: String = ""


func setup() -> void:
	get_parent().show()
	show()


func _on_dir_selected(dir: String) -> void:
	path = dir


func _on_confirmed() -> void:
	var complete = ProjectManager.import_project(path)
	if complete:
		get_parent().hide()
		hide()
		NotificationManager.notify("Project Imported", 2.0, true)
	else:
		NotificationManager.notify("Project Not Found", 3.0, true)


func _on_canceled() -> void:
	get_parent().hide()
	hide()
