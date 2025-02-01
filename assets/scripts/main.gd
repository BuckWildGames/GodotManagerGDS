extends Node

@export var game_manager: Node
@export var ui_manager: Node
@export var main_container_node: Node


func _enter_tree() -> void:
	System.game_manager = game_manager
	System.ui_manager = ui_manager
	#System.main_container_node = main_container_node


# Default colour: 2b2b2b
# Default highlight colour: 699ce8

# My main colour: 2b2b2b
# My colour highlight: 009ebf
