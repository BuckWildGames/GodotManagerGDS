@tool
extends EditorPlugin

const VersionControlDock = preload("assets/version_control_dock.tscn")

var dock: Control

func _enter_tree():
	dock = VersionControlDock.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, dock)


func _exit_tree():
	if dock:
		remove_control_from_docks(dock)
		dock.free()
