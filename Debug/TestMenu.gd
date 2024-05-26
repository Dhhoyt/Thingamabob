extends VBoxContainer

func _on_start_server_pressed():
	get_parent().start_server()

func _on_join_server_pressed():
	get_parent().join_server()
