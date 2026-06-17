extends CharacterBody2D


@onready var player = $/root/Main/Player
var speed : int
var health: int
var cooldown: float
var shooting: bool
var bullet_scene = preload("res://scenes/scientist_bullet.tscn")

func _ready() -> void:
	speed = 200
	health = 100
	cooldown = 0
	shooting = false
	$HealthBar/ProgressBar.value = health

func take_damage(damage: int) -> void:
	health -= damage
	$HealthBar/ProgressBar.value = health
	if (health <= 0):
		queue_free()

func _physics_process(delta: float) -> void:
	var distance_from_player = global_position.distance_to(player.global_position)
	if  distance_from_player < 1000:
		var direction: Vector2 = global_position.direction_to(player.global_position)
		var cropped_angle = snappedf(direction.angle(), PI/4) / (PI/4)
		cropped_angle = wrapi(int(cropped_angle), 0, 8)
		if (!shooting):
			$AnimatedSprite2D.animation = "run" + str(cropped_angle/2)
		if (cooldown <=0 and distance_from_player < 650):
			cooldown = 2
			shooting = true
			$AnimatedSprite2D.animation = "fire" + str(cropped_angle/2)
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.frame = 0
			await get_tree().create_timer(0.1).timeout
			
			shoot(direction, 500, global_position)
			run_cooldown()
		elif (distance_from_player > 400 and shooting == false):
			$AnimatedSprite2D.play()
			velocity = direction.normalized() * speed
			move_and_slide()
		else:
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.frame = 1


func shoot(direction, speed, position):
	var bullet : CharacterBody2D = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	if direction.angle() < 0:
		bullet.z_index = -1
	bullet.global_position = position
	bullet.fire(direction, speed)
	await get_tree().create_timer(0.5).timeout
	shooting = false

func run_cooldown():
	while (cooldown > 0):
		await get_tree().create_timer(0.5).timeout
		cooldown -= 0.5
