extends FileDialog

var path: String = ""


func setup() -> void:
	get_parent().show()
	show()


func _on_dir_selected(dir: String) -> void:
	path = dir


func _on_confirmed() -> void:
	if ProjectManager.import_project(path):
		get_parent().hide()
		hide()
	else:
		NotificationManager.notify("Project Not Found", 3.0, true)


func _on_canceled() -> void:
	get_parent().hide()
	hide()
