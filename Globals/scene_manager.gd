extends Node

const GAME_SCENE: PackedScene = preload("res://GameWorld.tscn")

var current_scene: Node = null

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(-1)

func enter_game() -> void:
	_deferred_enter_game.call_deferred()

func _deferred_enter_game() -> void:
	current_scene.free()
	current_scene = GAME_SCENE.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
