extends CharacterBody3D

@onready var health_component = $Health
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@export var speed: float = 1.0
@export var rotation_speed: float = 5.0
@export var aggro_distance: float = 15.0
@export var max_search_time: float = 5.0
var state_machine: AnimationNodeStateMachinePlayback
var animation: AnimationTree
var player: Node3D
var last_shot_position: Vector3 = Vector3.ZERO
var heard_shot: bool = false
var search_time: float = 0.0
var idle_time: float = 0.0
var player_weapon
var die=false
var can_attack: bool = true

func _ready():
	player = get_tree().get_root().find_child("Player", true, false)
	if player:
		player_weapon = player.find_child("Weapon")
		if player_weapon:
			player_weapon.give_damage.connect(on_player_gave_damage)
			player_weapon.connect("shot_fired", Callable(self, "_on_shot_fired"))
	health_component.died.connect(on_zombi_died)
	health_component.health_changed.connect(on_zombi_health_changed)
	animation = $AnimationTree
	state_machine = animation["parameters/playback"]
	animation.animation_finished.connect(_on_animation_finished)

func on_zombi_health_changed(new_health):
	print("Zombi élete: ", new_health)
	
func _deal_damage():
	var sqr_distance_to_player = global_position.distance_squared_to(player.global_position)
	if sqr_distance_to_player <= 4.0:
		if player.has_method("take_hit_from_enemy"):
			player.take_hit_from_enemy(10)

func _on_animation_finished(anim_name: StringName):
	if anim_name == "attack":
		can_attack = true
		

func on_player_gave_damage(obj: Node3D, damage: float, _point: Vector3):
	if obj == self:
		health_component.take_damage(damage)
		print_debug("Játékos sebzést adott: ",damage)

func on_zombi_died():
	state_machine.travel("back_fall")
	die = true
	$CollisionShape3D.queue_free()

func _on_shot_fired(shot_pos: Vector3):
	last_shot_position = shot_pos
	heard_shot = true
	search_time = 0.0

func _physics_process(delta: float):
	if !die:
		if player == null:
			return
		var target_position: Vector3
		var has_target: bool = false
		var sqr_distance_to_player = global_position.distance_squared_to(player.global_position)
		if sqr_distance_to_player <= aggro_distance * aggro_distance:
			target_position = player.global_position
			has_target = true
			heard_shot = false
			if sqr_distance_to_player < 3:
				if can_attack:
					state_machine.travel("attack")
					can_attack = false
				else:
					can_attack = true
			else:
				state_machine.travel("move")

		elif heard_shot:
			target_position = last_shot_position
			has_target = true
			search_time += delta
			if search_time > max_search_time:
				heard_shot = false
				search_time = 0.0
		if not has_target and not heard_shot:
			_idle_patrol(delta)
			return
		if agent.target_position != target_position:
			agent.set_target_position(target_position)
		var next_point = agent.get_next_path_position()
		if next_point == Vector3.ZERO:
			velocity = Vector3.ZERO
			return
		var direction = (next_point - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		var target_dir = (target_position - global_position).normalized()
		if target_dir.length() > 0:
			var target_yaw = atan2(target_dir.x, target_dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)
		if heard_shot and global_position.distance_squared_to(last_shot_position) < 1.0 * 1.0:
			heard_shot = false
			search_time = 0.0

func _idle_patrol(delta: float):
	idle_time += delta
	var radius = 2.0
	var speed_factor = 0.5
	var x = sin(idle_time * speed_factor) * radius
	var z = sin(idle_time * speed_factor * 2) * radius / 2.0
	var patrol_target = global_position + Vector3(x, 0, z)
	var direction = (patrol_target - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	var target_yaw = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)
