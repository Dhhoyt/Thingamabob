extends RigidBody3D

var type = 2

func get_parameters() -> Dictionary:
	return {"pos": position}

func apply_parameters(params: Dictionary) -> void:
	position = params["pos"]
