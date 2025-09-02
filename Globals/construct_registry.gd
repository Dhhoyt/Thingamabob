extends Node

const primitive_path: String = "res://Primitives/"

var primitives: Dictionary = {}

class ConstructScene:
	var id: int
	var name: String
	var scene: PackedScene
	
	func _init(i: int, n: String, s: PackedScene) -> void:
		self.id = i
		self.name = n
		self.scene = s
	
	func _to_string() -> String:
		return "(Construct Scene id: %d, name: %s, scene %s" % [id, name, str(scene)]

func _ready() -> void:
	collect_primitives()
	print(primitives)

func get_construct(id: int) -> ConstructScene:
	print("Getting " + str(id))
	return primitives.get(id)

func collect_primitives() -> void:
	primitives = {}
	var dir = DirAccess.open(primitive_path)
	if not dir:
		print("An error occurred when trying to load primitives")
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			print("Found directory: " + file_name)
			continue
		if file_name.get_extension() == "tscn":
			var full_path = primitive_path.path_join(file_name)
			var info = file_name.split("_")
			var id = int(info[1])
			primitives[id] = ConstructScene.new(id, info[0], load(full_path))
		file_name = dir.get_next()
