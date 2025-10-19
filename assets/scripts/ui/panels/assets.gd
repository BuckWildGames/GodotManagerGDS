extends UIState

const ASSET_SCENE: PackedScene = preload("res://assets/scenes/components/asset/asset.tscn")

@onready var empty_label: Label = $PanelContainer/MarginContainer/EmptyLabel
@onready var asset_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/AssetContainer


func _ready() -> void:
	pass
	#AssetManager.call_deferred("setup")


func enter(previous : String):
	super.enter(previous)


func button_pressed(button: String) -> void:
	match button:
		"refresh":
			pass
