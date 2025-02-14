extends Node

const DEFAULT_ICON: CompressedTexture2D = preload("res://icon.svg")

@onready var icon: TextureRect = $EngineContainer/Icon
@onready var title_label: Label = $EngineContainer/Info/Title
@onready var source_label: Label = $EngineContainer/Info/Source

@onready var download_button: Button = $EngineContainer/ButtonContainer/DownloadButton
@onready var uninstall_button: Button = $EngineContainer/ButtonContainer/UninstallButton
@onready var default_button: Button = $EngineContainer/ButtonContainer/DefaultButton

@onready var delay_timer: Timer = $DelayTimer

var master: Control = null
var this_engine: int = -1
var is_installed: bool = false

var click_delay: float = 1.0
var clicked: bool = false

func setup(new_master: Control, engine: int, new_title: String, source: String, installed: bool, default: bool) -> void:
	if not is_node_ready():
		await ready
	master = new_master
	this_engine = engine
	is_installed = installed
	title_label.set_text(new_title)
	source_label.set_text("Source: " + source)
	source_label.set_tooltip_text(source)
	download_button.set_visible(!installed)
	uninstall_button.set_visible(installed)
	default_button.set_visible(installed)
	default_button.set_pressed_no_signal(default)


func button_pressed(button: String) -> void:
	match button:
		"run":
			if clicked:
				if is_installed:
					EngineManager.run_engine(this_engine)
				else:
					NotificationManager.show_prompt("Download And Install Version?", ["No", "Yes"], self, "_on_install")
			else:
				clicked = true
				delay_timer.start(click_delay)
		"download":
			NotificationManager.show_prompt("Download And Install Version?", ["No", "Yes"], self, "_on_install")
		"uninstall":
			NotificationManager.show_prompt("Uninstall Version?", ["No", "Yes"], self, "_on_uninstall")


func _on_default_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		ConfigManager.set_config_data("settings", "default_engine", title_label.get_text())
		master.reset_default_engine(self)
	else:
		default_button.set_pressed_no_signal(true)


func _on_install(option: String) -> void:
	if option == "Yes":
		NotificationManager.notify("Downloading And Installing...", 10.0, true)
		var complete = EngineManager.install_version(this_engine)
		if not complete:
			NotificationManager.show_prompt("Failed To Install, Verify Install Path.", ["OK"], self, "")


func _on_uninstall(option: String) -> void:
	if option == "Yes":
		NotificationManager.notify("Uninstalling...", 10.0, true)
		var complete = EngineManager.uninstall_version(this_engine)
		if not complete:
			NotificationManager.show_prompt("Failed To Uninstall, Verify Install Path.", ["OK"], self, "")


func _on_delay_timer_timeout() -> void:
	clicked = false
