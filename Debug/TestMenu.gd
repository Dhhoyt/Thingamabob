extends VBoxContainer

@onready var port_box: TextEdit = $Port
@onready var address_box: TextEdit = $Address
@onready var name_box: TextEdit = $Name
@onready var tick_rate_box: TextEdit = $TickRate

func _on_start_server_pressed():
	set_tick_rate()
	get_parent().start_server()

func _on_join_server_pressed():
	set_tick_rate()
	get_parent().join_server($Address.text)

func set_tick_rate():
	var new_rate = tick_rate_box.text.to_int()
	ProjectSettings.set_setting("physics/common/physics_ticks_per_second", new_rate)
