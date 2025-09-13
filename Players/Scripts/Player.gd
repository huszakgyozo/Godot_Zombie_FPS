extends CharacterBody3D

@onready var camera: Camera3D = $Camera3D
@onready var weapon: Node3D = $Camera3D/Weapon
@onready var stand_up_checker: RayCast3D = $StandUpChecker
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var health = $Health
@onready var grab_raycast: RayCast3D = $Camera3D/Grab
@export var speed := 5.0
@export var sprint_multiplier := 1.5
@export var jump_velocity := 4.5
@export var gravity := 9.8
@export var mouse_sens := 0.2
@export var stand_camera_height := 0.6
@export var crouch_camera_height := 0.5
@export var stand_capsule_height := 1.0
@export var crouch_capsule_height := 0.5
@export var crouch_speed_multiplier := 0.5
@export var bob_frequency_base := 8.0
@export var bob_amplitude_walk := 0.05
@export var bob_amplitude_sprint := 0.12
@export var bob_side_amplitude_walk := 0.03
@export var bob_side_amplitude_sprint := 0.08
@export var bob_lerp_speed := 10.0
@export var hold_distance: float = 2.0
@export var hold_smooth_speed: float = 10.0
var is_crouching: bool = false
var current_speed := 0.0
var current_capsule_height := 1.0
var target_capsule_height := 1.0
var bob_timer := 0.0
var target_pos_default :Vector3
var held_object = null
var vertical_offset: float = 0.0

func _ready():
	health.died.connect(_on_player_died)
	health.health_changed.connect(_on_health_changed)
	if collider.shape is CapsuleShape3D:
		(collider.shape as CapsuleShape3D).height = stand_capsule_height
		current_capsule_height = stand_capsule_height
	if weapon:
		target_pos_default = weapon.position
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if Input.is_action_just_pressed("toggle_cursor"):
		var mode = Input.get_mouse_mode()
		if mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if Input.is_action_just_pressed("grab"):
		if held_object:
			drop_object()
		else:
			pick_up_object()
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_rotate_camera(event.relative)

func _physics_process(delta: float):
	_process_crouch()
	_process_movement(delta)
	_process_height(delta)
	_process_weapon_bob(delta)
	_process_held_object(delta)

func _rotate_camera(mouse_delta: Vector2):
	rotation.y -= deg_to_rad(mouse_delta.x * mouse_sens)
	camera.rotation.x = clamp(
		camera.rotation.x - deg_to_rad(mouse_delta.y * mouse_sens),
		deg_to_rad(-89),
		deg_to_rad(89)
	)

func _process_movement(delta: float):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_speed = speed
	if is_crouching:
		target_speed *= crouch_speed_multiplier
	elif Input.is_action_pressed("sprint"):
		target_speed *= sprint_multiplier
	current_speed = lerp(current_speed, target_speed, delta * 10.0)
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") and not is_crouching:
		velocity.y = jump_velocity
	move_and_slide()

func _process_crouch():
	is_crouching = Input.is_action_pressed("crouch") or stand_up_checker.is_colliding()

func _process_height(delta: float):
	var target_cam_height = 0.0
	if is_crouching:
		target_cam_height = crouch_camera_height
	else:
		target_cam_height = stand_camera_height
	target_capsule_height = 0.0
	if is_crouching:
		target_capsule_height = crouch_capsule_height
	else:
		target_capsule_height = stand_capsule_height
	camera.position.y = lerp(camera.position.y, target_cam_height, delta * bob_lerp_speed)
	if current_capsule_height != target_capsule_height and collider.shape is CapsuleShape3D:
		var old_height = current_capsule_height
		current_capsule_height = lerp(current_capsule_height, target_capsule_height, delta * bob_lerp_speed)
		var capsule = collider.shape as CapsuleShape3D
		capsule.height = current_capsule_height
		if is_on_floor():
			var height_change = old_height - current_capsule_height
			position.y -= height_change / 2.0

func _process_weapon_bob(delta: float):
	var horiz_vel = Vector2(velocity.x, velocity.z).length()
	var target_pos=target_pos_default
	if is_on_floor() and horiz_vel > 0.1:
		var bob_freq = bob_frequency_base * (horiz_vel / speed)
		bob_timer += delta * bob_freq
		var amp_y = bob_amplitude_walk
		var amp_x = bob_side_amplitude_walk
		if horiz_vel > speed * 1.2:
			amp_y = bob_amplitude_sprint
			amp_x = bob_side_amplitude_sprint
		target_pos += Vector3(sin(bob_timer * 0.5) * amp_x, sin(bob_timer) * amp_y, 0)
	elif not is_on_floor():
		bob_timer += delta * bob_frequency_base
		var amp_jump_x = bob_side_amplitude_walk * 2.0
		var amp_jump_y = bob_amplitude_walk * 5.0
		target_pos += Vector3(sin(bob_timer) * amp_jump_x, sin(bob_timer) * amp_jump_y, 0)
	else:
		bob_timer = 0.0
	weapon.position = weapon.position.lerp(target_pos, delta * bob_lerp_speed)

func pick_up_object():
	if not grab_raycast.is_colliding() or held_object != null:
		return
	var obj_collider = grab_raycast.get_collider()
	if obj_collider is RigidBody3D:
		held_object = obj_collider
		held_object.gravity_scale=0
	elif obj_collider is StaticBody3D:
		held_object = obj_collider.get_parent()

func drop_object():
	if held_object is RigidBody3D:
		held_object.gravity_scale=1
	held_object = null
	
func _process_held_object(delta):
	if held_object:
		var target_pos = camera.global_transform.origin + camera.global_transform.basis.z * -hold_distance
		if Input.is_action_pressed("grab_move_up"):
			vertical_offset += 1.5 * delta
		elif Input.is_action_pressed("grab_move_down"):
			vertical_offset -= 1.5 * delta
		target_pos.y += vertical_offset
		held_object.global_transform.origin = held_object.global_transform.origin.lerp(target_pos, delta * hold_smooth_speed)

func _on_player_died():
	print("A játékos meghalt!")

func _on_health_changed(new_health: int):
	print("Életerő:", new_health)

func take_hit_from_enemy(damage: float):
	health.take_damage(damage)
