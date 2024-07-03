extends Node
class_name LuaRunner

@export_multiline var lua_script: String

var default_signals: PackedStringArray = PackedStringArray()
var api: LuaAPI = LuaAPI.new()
var signals = {}

func _enter_tree():
	var synch = MultiplayerSynchronizer.new()
	synch.root_path = NodePath("..")
	var rep_config = SceneReplicationConfig.new()
	rep_config.add_property(NodePath(":transform"))
	synch.replication_config = rep_config
	add_child(synch)
	var inter = TickInterpolator.new()
	inter.root = self
	const inter_props = [":transform"]
	for i in get_property_list():
		if i['name'] in inter_props:
			inter.properties.append(i['name'])
	inter.process_settings()
	add_child(inter)

	# Start Lua Stuff
	api.bind_libraries(["math"])
	for i in self.get_signal_list():
		default_signals.append(i["name"])
	api.push_variant("print", func(x): print(x))
	var result = api.do_string(lua_script)
	api.push_variant("add_user_signal", func(name): self.add_user_signal(name, [{"name": "args", "type": TYPE_ARRAY}]))
	if api.function_exists("init"):
		api.call_function("init", [])
	api.push_variant("add_user_signal", null)

func _ready():
	if is_multiplayer_authority():
		self.api.push_variant("get_child", func(x): return self.get_child(x))
		self.api.push_variant("connect", func(node, name, callable): node.lua_connect_signal(name, callable))
		if self.api.function_exists("ready"):
			self.api.call_function("ready", [])
		self.api.push_variant("set_position", func(x, y, z): self.position = Vector3(x,y,z))

func _physics_process(delta):
	if is_multiplayer_authority():
		if self.api.function_exists("process"):
			self.api.call_function("process", [])

func lua_connect_signal(name: String, callable: Callable):
	if name in default_signals:
		# Because default signals may have multiple args
		# and since there is no varargs in gdscript, 
		# we gotta do this. *sigh*
		var da_func = func(arg0 :Variant=null,
			arg1 :Variant=null,
			arg2 :Variant=null,
			arg3 :Variant=null,
			arg4 :Variant=null,
			arg5 :Variant=null,
			arg6 :Variant=null,
			arg7 :Variant=null,
			arg8 :Variant=null,
			arg9 :Variant=null) -> void:
			var values := [arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9]
			values = values.filter(func(value:Variant) -> bool: return value != null)
			callable.call(values)
		self.connect(name, da_func)
	else:
		print(self.default_signals)
		self.connect(name, callable)

#Lua API wrappers
func pull_variant(Name: String) -> Variant:
	return api.pull_variant(Name)

func push_variant(Name: String, vari: Variant) -> LuaError:
	return api.push_variant(Name, vari)

func resume(Args: Array) -> Variant:
	return api.resume(Args)

func do_file(FilePath: String, Args: Array = [])-> Variant:
	return api.do_file(FilePath, Args)

func do_string(Code: String, Args: Array = []) -> Variant:
	return api.do_string(Code, Args)

func call_function(LuaFunctionName: String, Args: Array) -> Variant:
	return api.call_function(LuaFunctionName, Args)

func function_exists(LuaFunctionName: String) -> bool:
	return api.function_exists(LuaFunctionName)

func get_registry_value(Name: String) -> Variant:
	return api.get_registry_value(Name)

func set_registry_value(Name: String, vari) -> Variant:
	return api.set_registry_value(Name, vari)
