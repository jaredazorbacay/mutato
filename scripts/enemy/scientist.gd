extends CharacterBody2D


@onready var player = $/root/Main/Player
var speed : int
var health: int
var bullet_damage: int
var cooldown: float
var shooting: bool
var bullet_scene = preload("res://scenes/scientist_bullet.tscn")
var is_poisoned: bool

const PoisonPulseShader = preload("res://scenes/poison_pulse.gdshader")

@export var deathParticle : PackedScene

func _ready() -> void:
	speed = 100
	health = 100
	cooldown = 0
	bullet_damage = 1
	shooting = false
	$HealthBar/ProgressBar.value = health
	
	#MUTATIONS PLACEHOLDER
	is_poisoned = false

func take_damage(damage: int) -> void:
	health -= damage
	$HealthBar/ProgressBar.value = health
	$Hitflashanim.play("hit")
	
	Explode()
	
	if (health <= 0):
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
	if player:
		distance_from_player = global_position.distance_to(player.global_position)
	
	if  distance_from_player < 1000:
		var direction: Vector2 = global_position.direction_to(player.global_position)
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
