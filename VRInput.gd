extends BaseNetInput
class_name VRInput

var movement: Vector3 = Vector3.ZERO
var head_velocity: Vector3 = Vector3.ZERO
var head_position: Vector3 = Vector3.ZERO
var head_rotation: Quaternion = Quaternion.IDENTITY
var left_hand_velocity: Vector3 = Vector3.ZERO
var left_hand_position: Vector3 = Vector3.ZERO
var left_hand_rotation: Quaternion = Quaternion.IDENTITY
var right_hand_velocity: Vector3 = Vector3.ZERO
var right_hand_position: Vector3 = Vector3.ZERO
var right_hand_rotation: Quaternion = Quaternion.IDENTITY

func _gather():
	movement = Vector3(
		Input.get_axis("move_west", "move_east"),
		0,
		Input.get_axis("move_north", "move_south")
	)
	#TODO: head_velocity, head_position, left_hand_velocity, left_hand_position, right_hand_velocity, right_hand_position
