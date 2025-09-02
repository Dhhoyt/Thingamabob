extends Node

var state: Dictionary

var game_world: Node
var player_node: Node
var object_node: Node

class ConstructInstance:
	var id: int
	var type: int
	var parameters: Dictionary
	func _init(n: Node) -> void:
		assert(n.is_in_group("construct"), "Tried creating ConstructInfo on a non-construct")
		self.id = int(n.name)
		self.type = n.type
		self.parameters = n.get_parameters()
	
	func _to_string() -> String:
		return "(Construct Instance id: %d, type: %s, parameters %s" % [id, type, str(parameters)]

func _process(delta: float) -> void:
	pass

func recurse_construct(construct: Node, root: bool = true) -> Array:
	var info_dict: Dictionary = {}
	var structure: Dictionary = {}
	for child in construct.get_children():
		if not child.is_in_group("construct"):
			continue
		var child_res = recurse_construct(child, false)
		info_dict.merge(child_res[0])
		structure.merge(child_res[1])
	if root:
		return [info_dict, structure]
	else:
		var info: ConstructInstance = ConstructInstance.new(construct)
		info_dict[info.id] = {"id": info.id, "type": info.type, "parameters": info.parameters}
		return [info_dict, {info.id: structure}]

func calculate_state_state():
	var new_state: Dictionary
	var new_object_state = recurse_construct(object_node)
	new_state["object_state"] = new_object_state[0]
	new_state["object_structure"] = new_object_state[1]
	state = new_state
	receive_state.rpc_id(53785932, new_state)
	print(state)

@rpc("authority", "call_remote", "reliable", 0)
func receive_state(received_state: Dictionary):
	var object_state = received_state.get("object_state", {})
	var object_structure = received_state.get("object_structure", {})
		
	# Apply the structure recursively starting from root
	apply_structure_recursive(object_node, object_structure, object_state)

func apply_structure_recursive(parent_node: Node, structure: Dictionary, object_state: Dictionary):
	
	# Get all existing construct children
	var existing_constructs: Dictionary = {}
	for child in parent_node.get_children():
		if child.is_in_group("construct"):
			var child_id = int(child.name)
			existing_constructs[child_id] = child
	
	# Process each object in the structure
	for object_id in structure:
		var object_id_int = int(object_id)
		var child_structure = structure[object_id]
		var object_info = object_state.get(object_id_int, {})
		
		var construct_node: Node = null
		
		# Check if object already exists
		if existing_constructs.has(object_id_int):
			construct_node = existing_constructs[object_id_int]
			# Apply parameters to existing object
			if object_info.has("parameters"):
				construct_node.apply_parameters(object_info["parameters"])
		else:
			# Create new object from construct registry
			if object_info.has("type"):
				var construct_scene = ConstructRegistry.get_construct(object_info["type"])
				if construct_scene:
					construct_node = construct_scene.scene.instantiate()
					construct_node.name = str(object_id_int)
					parent_node.add_child(construct_node)
					# Apply parameters to new object
					if object_info.has("parameters"):
						construct_node.apply_parameters(object_info["parameters"])
				else:
					continue
			else:
				continue
		
		# Only recurse if we have a valid construct_node
		if construct_node != null:
			# Recursively apply child structure
			if child_structure is Dictionary and not child_structure.is_empty():
				apply_structure_recursive(construct_node, child_structure, object_state)
	
	# Remove objects that are no longer in the structure at this level
	for existing_id in existing_constructs:
		# Check both string and int versions of the key since structure keys might be either
		var id_exists = structure.has(str(existing_id)) or structure.has(existing_id)
		if not id_exists:
			existing_constructs[existing_id].queue_free()
