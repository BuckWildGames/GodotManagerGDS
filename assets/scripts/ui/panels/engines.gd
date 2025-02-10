extends UIState

const ENGINE_SCENE: PackedScene = preload("res://assets/scenes/components/engine/engine.tscn")

@onready var empty_label: Label = $PanelContainer/MarginContainer/EmptyLabel
@onready var installed_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/Installed/GroupContainer
@onready var available_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/NotInstalled/GroupContainer

@onready var import_engine_dialog: FileDialog = $DialogContainer/ImportEngineDialog


func _ready() -> void:
	EngineManager.available_versions_changed.connect(_reset_engines)
	EngineManager.installed_versions_changed.connect(_reset_engines)
	EngineManager.setup()


func button_pressed(button: String) -> void:
	match button:
		"import":
			pass
		"scan":
			pass
		"refresh":
			pass


func _process(_delta: float) -> void:
	if not installed_container or not available_container:
		return
	if installed_container.get_child_count() <= 0 and available_container.get_child_count() <= 0:
		if not empty_label.is_visible():
			empty_label.set_visible(true)
	elif empty_label.is_visible():
		empty_label.set_visible(false)


func _reset_engines() -> void:
	_clear_engine_containers()
	_add_engines()


func _add_engines() -> void:
	if not installed_container or not available_container:
		return
	var available = EngineManager.get_available_versions()
	var installed = EngineManager.get_installed_versions()
	for engine in range(available.size()):
		var i = ENGINE_SCENE.instantiate()
		var title = available[engine]["name"]
		var source = available[engine]["url"]
		var is_installed = false
		if installed.has(title):
			installed_container.add_child(i)
			is_installed = true
		else:
			available_container.add_child(i)
		i.setup(self, engine, title, source, is_installed)


func _clear_engine_containers() -> void:
	if not installed_container or not available_container:
		return
	for child in installed_container.get_children():
		child.queue_free()
	for child in available_container.get_children():
		child.queue_free()
