extends Node


@export var output: AudioStreamPlayer3D
@export var input_threshhold: float = 0.05
@onready var input: AudioStreamPlayer = $Input
@onready var player: CharacterBody3D = $".."

var effect: AudioEffectCapture
var playback: AudioStreamGeneratorPlayback
var index: int
var receive_buffer: PackedFloat32Array = PackedFloat32Array()

func _ready():
	output.play()

func setup_audio():
	if player.is_local_authority():
		input.stream = AudioStreamMicrophone.new()
		input.play()
		index = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(index, 0)
	
	
	playback = output.get_stream_playback()

func _process(delta):
	if player.is_local_authority():
		process_mic()
	process_voice()

func process_mic():

	var sterio_data: PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	
	if sterio_data.size() > 0:
		
		var data = PackedFloat32Array()
		data.resize(sterio_data.size())
		var max_amplitude = 0
		
		for i in range(sterio_data.size()):
			var value = (sterio_data[i].x + sterio_data[i].y) / 2
			max_amplitude = max(value, max_amplitude)
			data[i] = value
		if max_amplitude < input_threshhold:
			return
		send_data.rpc(data)

func process_voice():
	if receive_buffer.size() <= 0:
		return
	
	for i in range(min(playback.get_frames_available(), receive_buffer.size())):
		playback.push_frame(Vector2(receive_buffer[0], receive_buffer[0]))
		receive_buffer.remove_at(0)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func send_data(data: PackedFloat32Array):
	receive_buffer.append_array(data)
