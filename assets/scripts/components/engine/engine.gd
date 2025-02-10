extends Node

const DEFAULT_ICON: CompressedTexture2D = preload("res://icon.svg")
const MISSING_ICON: CompressedTexture2D = preload("res://assets/icons/missing_icon.svg")

@onready var icon: TextureRect = $EngineContainer/Icon
@onready var title_label: Label = $EngineContainer/Info/Title
@onready var source_label: Label = $EngineContainer/Info/Source

@onready var download_button: Button = $EngineContainer/ButtonContainer/DownloadButton
@onready var uninstall_button: Button = $EngineContainer/ButtonContainer/UninstallButton
@onready var default_button: Button = $EngineContainer/ButtonContainer/DefaultButton

var master: Control = null
var this_engine: int = -1


func setup(new_master: Control, engine: int, new_title: String, source: String, installed: bool) -> void:
	if not is_node_ready():
		await ready
	master = new_master
	this_engine = engine
	title_label.set_text(new_title)
	source_label.set_text("Source: " + source)
	download_button.set_visible(!installed)
	uninstall_button.set_visible(installed)
	default_button.set_visible(installed)


func button_pressed(button: String) -> void:
	match button:
		"download":
			var complete = EngineManager.install_version(this_engine)
			if not complete:
				NotificationManager.show_prompt("Failed To Install, Verify Install Path.", ["OK"], self, "")
		"uninstall":
			EngineManager.uninstall_version(this_engine)
		"default":
			pass
