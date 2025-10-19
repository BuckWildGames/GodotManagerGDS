extends UIState

const ENGINE_SCENE: PackedScene = preload("res://assets/scenes/components/engine/engine.tscn")

@onready var empty_label: Label = $PanelContainer/MarginContainer/EmptyLabel
@onready var installed_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/InstalledContainer/Installed/GroupContainer
@onready var available_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/EngineContainer/NotInstalledContainer/NotInstalled/GroupContainer

@onready var import_engine_dialog: FileDialog = $DialogContainer/ImportEngineDialog


func _ready() -> void:
	EngineManager.available_versions_changed.connect(_reset_engines)
	EngineManager.installed_versions_changed.connect(_reset_engines)
	EngineManager.call_deferred("setup")


func enter(previous : String):
	super.enter(previous)
	EngineManager.load_settings()
	call_deferred("_reset_engines", false)


func button_pressed(button: String) -> void:
	match button:
		"import":
			pass
		"scan":
			EngineManager.get_installed_versions()
			NotificationManager.notify("Scanning For Installed Versions", 2.0, true)
		"refresh":
			EngineManager.fetch_available_versions(false)
			NotificationManager.notify("Fetching Available Versions", 2.0, true)


func reset_default_engine(ignore: Node) -> void:
	if not installed_container:
		return
	for engine in installed_container.get_children():
		if not engine == ignore:
			engine.default_button.set_pressed_no_signal(false)


func _process(_delta: float) -> void:
	if not installed_container or not available_container:
		return
	if installed_container.get_child_count() <= 0 and available_container.get_child_count() <= 0:
		if not empty_label.is_visible():
			empty_label.set_visible(true)
	elif empty_label.is_visible():
		empty_label.set_visible(false)


func _reset_engines(notify: bool = true) -> void:
	_clear_engine_containers()
	_add_engines()
	if is_visible_in_tree() and notify:
		NotificationManager.notify("Engine List Updated", 2.0, true)


func _add_engines() -> void:
	if not installed_container or not available_container:
		return
	var available = EngineManager.get_available_versions()
	var installed = EngineManager.get_installed_versions()
	var default = ConfigManager.get_config_data("settings", "default_engine")
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
		var is_default = false
		if default != null:
			if default == title:
				is_default = true
		i.setup(self, engine, title, source, is_installed, is_default)


func _clear_engine_containers() -> void:
	if not installed_container or not available_container:
		return
	for child in installed_container.get_children():
		child.queue_free()
	for child in available_container.get_children():
		child.queue_free()
