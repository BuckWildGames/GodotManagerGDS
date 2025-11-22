extends FileDialog

var path: String = ""


func setup() -> void:
	get_parent().show()
	show()


func _on_dir_selected(dir: String) -> void:
	path = dir


func _on_confirmed() -> void:
	EngineManager.import_installed_version(path)
	get_parent().hide()
	hide()


func _on_canceled() -> void:
	get_parent().hide()
	hide()
