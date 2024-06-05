extends CharacterBody3D

@export var walking_speed: float = 5
@export var crouching_speed: float = 2.5
@export var sprint_speed: float = 10.0
@export var deceleration: float = 20
@export var jump_velocity: float = 5.0
@export var sensitivity: float = 0.01
@export var stamina_recovery_rate: float = 1
@export var stamina_depletion_rate: float = 1
@export var stamina_waiting_period: float = 1
@export var camera_animation_period: float = 0.16
@export var camera_standing_height: float = 0.666
@export var camera_crouching_height: float = -0.333

var sprinting: bool = false
var stamina: float = 1

var crouched = false
var stamina_waiting: float = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_vector: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")

@onready var camera: Camera3D = $Camera
@onready var head: CollisionShape3D = $Head
@onready var uncrouch_check: Area3D = $UncrouchCheck
@onready var input: PCInput = $Input
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
@onready var audio_manager = $"Audio Manager"

var peer_id = 0

func is_local_authority():
	return input.get_multiplayer_authority() == multiplayer.get_unique_id()

func _ready():
	await get_tree().process_frame
	
	peer_id = str(name).to_int()
	set_multiplayer_authority(1)
	input.set_multiplayer_authority(peer_id)
	rollback_synchronizer.process_settings()
	
	if is_local_authority():
		camera.current = true
	audio_manager.setup_audio()
	

func _rollback_tick(delta, tick, is_fresh):
	up_direction =- gravity_vector
	_force_update_is_on_floor()
	if not is_on_floor():
		velocity += gravity_vector.normalized() * delta * gravity
	
	var linear_velocity: Vector3 = velocity - velocity.project(gravity_vector)
	var orthonormal_basis = gravity_orthonormal_basis()
	var input_dir = input.input_dir

	var looking_basis = Basis(Vector3.DOWN, input.looking_angle.x)
	var tilt = Basis(Vector3.LEFT, input.looking_angle.y)

	global_transform.basis =  orthonormal_basis * looking_basis
	camera.global_transform.basis = global_transform.basis * tilt
	var direction = (orthonormal_basis * looking_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if !sprinting:
		if stamina_waiting == 0:
			stamina += stamina_recovery_rate * delta
			stamina = min(stamina, 1)
		stamina_waiting -= delta
		stamina_waiting = max(stamina_waiting, 0)

	var max_speed = get_max_speed(delta)
	velocity += direction * (max_speed * deceleration) * delta
	velocity -= linear_velocity * deceleration * delta
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	
func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity = Vector3.ZERO
	move_and_slide()
	velocity = old_velocity

func get_max_speed(delta: float) -> float:
	if Input.is_action_pressed("player_crouch"):
		sprinting = false
		if not crouched:
			var crouch_tween = get_tree().create_tween()
			crouch_tween.tween_property(camera, "position", Vector3(0, camera_crouching_height, 0), camera_animation_period)
			crouch_tween.tween_callback(func(): head.disabled = true)
			crouch_tween.play()
		crouched = true
		return crouching_speed
	if crouched and not colliding_with_not_self():
		var crouch_tween = get_tree().create_tween()
		crouch_tween.tween_property(camera, "position", Vector3(0, camera_standing_height, 0), camera_animation_period)
		head.disabled = false
		crouch_tween.play()
		crouched = false
	if stamina != 0 && Input.is_action_pressed("player_sprint"):
		sprinting = true
		stamina_waiting = stamina_waiting_period
		stamina -= stamina_depletion_rate * delta
		stamina = max(stamina, 0.0)
		return sprint_speed
	else:
		sprinting = false
		return walking_speed

func colliding_with_not_self() -> bool:
	var bodies = uncrouch_check.get_overlapping_bodies()
	for i in bodies:
		if i != self:
			return true
	return false
	
func gravity_orthonormal_basis() -> Basis:
	var x_proj = Vector3.RIGHT - Vector3.RIGHT.project(gravity_vector)
	var y_proj = Vector3.UP - Vector3.UP.project(gravity_vector)
	var z_proj = Vector3.BACK - Vector3.BACK.project(gravity_vector)
	var a = Vector3.ZERO
	var b = Vector3.ZERO
	if x_proj == Vector3.ZERO or x_proj == z_proj:
		a = z_proj
		b = y_proj
	elif z_proj == Vector3.ZERO:
		a = x_proj
		b = y_proj
	else:
		a = x_proj
		b = z_proj
	b = b - b.project(a)#The Gram–Schmidt process
	return Basis(a.normalized(), -gravity_vector.normalized(), b.normalized())
