extends BaseNetInput
class_name PCInput

var input_dir: Vector2 = Vector2.ZERO
var looking_angle: Vector2
var jumped: bool = false

var sensitivity = 0.01

var api: LuaAPI = LuaAPI.new()

func _gather():
	input_dir = Input.get_vector("player_left", "player_right", "player_forward", "player_backward")
	jumped = Input.is_action_just_pressed("player_jump")

func _input(event):
	if event is InputEventMouseMotion:
		looking_angle += event.relative * sensitivity
		looking_angle.y = clamp(looking_angle.y, -PI/2, PI/2)
