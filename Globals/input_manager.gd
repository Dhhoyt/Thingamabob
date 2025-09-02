extends Node

signal input_frame(i: FrameInput)

var unreconciled_inputs: Array = [] # Inputs that have not been reconciled yet
var unsent_inputs: Array = [] # Inputs that have not been sent to the server yet

var mouse_offset: Vector2 = Vector2.ZERO # How far the mouse moved since the last frame

class FrameInput:
	var movement: Vector2 # Movement vector based on input
	var jumping: bool # Whether the jump action is pressed
	var heading: Vector2 # Direction the player has moved since the last frame
	var delta: float # Time since the last frame
	var timestamp: float # Timestamp of the input for reconciliation
	func _init(p_movement: Vector2, p_jumping: bool, p_heading: Vector2, p_delta: float, p_timestamp: float):
		self.movement = p_movement
		self.jumping = p_jumping
		self.heading = p_heading
		self.delta = p_delta
		self.timestamp = p_timestamp

func _physics_process(delta: float) -> void:
	var movement = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var jumping = Input.is_action_pressed("ui_accept")
	var frame_input = FrameInput.new(movement, jumping, mouse_offset, delta, Time.get_ticks_msec())
	unreconciled_inputs.append(frame_input)
	unsent_inputs.append(frame_input)

func get_unsent_inputs() -> Array:
	var temp = unsent_inputs.duplicate()
	unsent_inputs.clear()
	return temp

func handle_reconciliation(most_recent_timestamp: int) -> void:
	unreconciled_inputs = unreconciled_inputs.filter(func(input): input.timestamp > most_recent_timestamp)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_offset += event.relative * Settings.mouse_sensitivity
