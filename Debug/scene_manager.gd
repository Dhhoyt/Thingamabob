extends Node

@export var lobby: PackedScene

func start_server():
	get_children()[0].queue_free()
	var l = lobby.instantiate()
	add_child(l)
	l.create_game()

func join_server(address: String):
	get_children()[0].queue_free()
	var l = lobby.instantiate()
	add_child(l)
	l.join_game(address)
