extends CharacterBody3D

@export var speed: float = 5.0
@export var sprint_multiplier: float = 1.5
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8
@export var mouse_sens: float = 0.2

var stand_camera_height: float = 0.6
@export var crouch_camera_height: float = 0.5
@export var stand_capsule_height: float = 1.0
@export var crouch_capsule_height: float = 0.5
@export var crouch_speed_multiplier: float = 0.5
var current_capsule_height: float = 0.0
var target_capsule_height: float = 0.0
@export var bob_frequency_base: float = 8.0
@export var bob_amplitude_walk: float = 0.05
@export var bob_amplitude_sprint: float = 0.12
@export var bob_side_amplitude_walk: float = 0.03
@export var bob_side_amplitude_sprint: float = 0.08
@export var bob_lerp_speed: float = 10.0

var is_crouching: bool = false
var current_speed: float = 0.0
var bob_timer: float = 0.0

@onready var camera_node: Camera3D = $"Camera3D"
@onready var weapon: Node3D = $"Camera3D/Weapon"
@onready var stand_up_checker: RayCast3D = $StandUpChecker
@onready var collision_shape: CollisionShape3D = $"CollisionShape3D"
@onready var health_component = $Health

func _ready():
	health_component.died.connect(on_player_died)
	health_component.health_changed.connect(on_player_health_changed)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if weapon:
		weapon.set_meta("original_pos", weapon.position)
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var capsule = collision_shape.shape as CapsuleShape3D
		capsule.height = stand_capsule_height
		current_capsule_height = stand_capsule_height
		
func _input(event):
	_process_look(event)
	if Input.is_action_pressed("exit"):
		get_tree().quit()

func _physics_process(delta):
	_process_crouch()
	_process_movement(delta)
	_process_height(delta)
	_process_weapon_bob(delta)

func take_hit_from_enemy():
	health_component.take_damage(10)

func on_player_died():
	print("A játékos meghalt!")
	#queue_free()

func on_player_health_changed(new_health):
	print("Játékos élete: ", new_health)

func _process_look(event):
	if event is InputEventMouseMotion:
		var mouse_motion = event.relative
		rotation.y = rotation.y - deg_to_rad(mouse_motion.x * mouse_sens)
		camera_node.rotation.x = clamp(camera_node.rotation.x - deg_to_rad(mouse_motion.y * mouse_sens), deg_to_rad(-89), deg_to_rad(89))

func _process_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var target_speed = speed
	if is_crouching:
		target_speed *= crouch_speed_multiplier
	elif Input.is_action_pressed("sprint"):
		target_speed *= sprint_multiplier

	current_speed = lerp(current_speed, target_speed, delta * 10)

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") and not is_crouching:
		velocity.y = jump_velocity

	move_and_slide()

func _process_crouch():
	if Input.is_action_pressed("crouch"):
		is_crouching = true
	else:
		if not stand_up_checker.is_colliding():
			is_crouching = false
		else:
			is_crouching = true
			
func _process_height(delta):
	var target_camera_height = stand_camera_height
	target_capsule_height = stand_capsule_height
	
	if is_crouching:
		target_camera_height = crouch_camera_height
		target_capsule_height = crouch_capsule_height
	
	camera_node.position.y = lerp(camera_node.position.y, target_camera_height, delta * bob_lerp_speed)
	
	if current_capsule_height != target_capsule_height:
		var old_height = current_capsule_height
		current_capsule_height = lerp(current_capsule_height, target_capsule_height, delta * bob_lerp_speed)
		
		if collision_shape and collision_shape.shape is CapsuleShape3D:
			var capsule = collision_shape.shape as CapsuleShape3D
			capsule.height = current_capsule_height
			
		if is_on_floor():
			var height_change = old_height - current_capsule_height
			position.y -= height_change / 2.0
			
func _process_weapon_bob(delta):
	var horizontal_velocity = Vector2(velocity.x, velocity.z).length()
	var weapon_pos_target = weapon.get_meta("original_pos")

	if is_on_floor() and horizontal_velocity > 0.1:
		var bob_frequency = bob_frequency_base * (horizontal_velocity / speed)
		bob_timer += delta * bob_frequency

		var bob_amp = bob_amplitude_walk
		var bob_side_amp = bob_side_amplitude_walk
		if horizontal_velocity > speed * 1.2:
			bob_amp = bob_amplitude_sprint
			bob_side_amp = bob_side_amplitude_sprint

		var bob_offset_y = sin(bob_timer) * bob_amp
		var bob_offset_x = sin(bob_timer * 0.5) * bob_side_amp
		
		weapon_pos_target += Vector3(bob_offset_x, bob_offset_y, 0)
	else:
		bob_timer = 0.0

	weapon.position = weapon.position.lerp(weapon_pos_target, delta * bob_lerp_speed)
