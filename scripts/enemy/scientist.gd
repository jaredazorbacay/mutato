extends CharacterBody2D


@onready var player = $/root/Main/GameNode/Player
var speed : int
var health: int
var bullet_damage: int
var cooldown: float
var shooting: bool
var bullet_scene = preload("res://scenes/scientist_bullet.tscn")
var fertilizer_scene = preload("res://scenes/items/fertilizer.tscn")
var is_poisoned: bool
var facing_direction: Vector2
var hasFertilizer = false

const PoisonPulseShader = preload("res://scenes/poison_pulse.gdshader")

@export var deathParticle : PackedScene

func _ready() -> void:
	speed = 100
	health = 100
	cooldown = 0
	bullet_damage = 5
	shooting = false
	$HealthBar/ProgressBar.value = health
	
	#MUTATIONS PLACEHOLDER
	is_poisoned = false
	facing_direction = Vector2.DOWN

func take_damage(damage: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	var final_damage = damage
	
	if attacker_position != Vector2.ZERO:
		var direction_to_attacker = global_position.direction_to(attacker_position)
		var dot = facing_direction.dot(direction_to_attacker)
		if dot < -0.3:
			final_damage *= 2.0
			print("BACKSTAB! damage: ", final_damage)
	
	health -= final_damage
	$HealthBar/ProgressBar.value = health
	$Hitflashanim.play("hit")
	
	Explode()
	
	if (health <= 0):
		drops()
		AudioController.play_death()
		queue_free()
	else:
		AudioController.play_hit()
	
func Explode():
	var _particle = deathParticle.instantiate();
	_particle.position = global_position
	_particle.rotation = global_rotation
	_particle.emitting = true
	get_tree().current_scene.add_child(_particle)
		
		

func _physics_process(delta: float) -> void:
	var avoiding = false
	var distance_from_player = 10001
	if player and not player.is_camouflaged:
		distance_from_player = global_position.distance_to(player.global_position)
	
	if  distance_from_player < 1000:
		var direction: Vector2 = global_position.direction_to(player.global_position)
		facing_direction = direction
		var cropped_angle = snappedf(direction.angle(), PI/4) / (PI/4)
		cropped_angle = wrapi(int(cropped_angle), 0, 8)
		if (cooldown <=0 and distance_from_player < 650):
			cooldown = 2
			shooting = true
			$AnimatedSprite2D.animation = "fire" + str(cropped_angle/2)
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.frame = 0
			await get_tree().create_timer(0.1).timeout
			
			shoot(direction, 500, global_position, cropped_angle/2, 3)
			run_cooldown()
		elif (distance_from_player > 550 and !shooting):
			$AnimatedSprite2D.play()
			velocity = direction.normalized() * speed
			move_and_slide()
		elif (distance_from_player < 400 and !shooting):
			avoiding = true
			$AnimatedSprite2D.play()
			velocity = direction.normalized() * -speed
			move_and_slide()
		else:
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.frame = 1
		
		if (!shooting):
			var direction_run = cropped_angle/2
			if (!avoiding):
				$AnimatedSprite2D.animation = "run" + str(direction_run)
			else:
				match direction_run:
					0: direction_run = 2
					1: direction_run = 3
					2: direction_run = 0
					3: direction_run = 1
				$AnimatedSprite2D.animation = "run" + str(direction_run)

func shoot(direction, speed, position, quadrant, count):
	for i in count:
		var bullet : CharacterBody2D = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		if direction.angle() < 0:
			bullet.z_index = -1
		bullet.global_position = position
		bullet.fire(direction, speed, bullet_damage, quadrant)
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(0.5).timeout
	shooting = false

func run_cooldown():
	while (cooldown > 0):
		await get_tree().create_timer(0.5).timeout
		cooldown -= 0.5

#MUTATION FUNCTIONS
func apply_poison(damage_per_tick: int, tick_count: int, tick_interval: float) -> void:
	if is_poisoned:
		return
	is_poisoned = true
	
	var poison_material = ShaderMaterial.new()
	poison_material.shader = PoisonPulseShader
	$AnimatedSprite2D.material = poison_material
	
	for i in tick_count:
		await get_tree().create_timer(tick_interval).timeout
		
		health -= damage_per_tick
		$HealthBar/ProgressBar.value = health
		
		if health <= 0:
			AudioController.play_death()
			queue_free()
			return
	
	is_poisoned = false
	$AnimatedSprite2D.material = null

func drops():
	if hasFertilizer:
		var fertilizer_object = fertilizer_scene.instantiate()
		get_tree().current_scene.add_child(fertilizer_object)
		fertilizer_object.position = global_position
