extends CharacterBody2D

@export var speed: float
@export var detection_range: float
@export var attack_cooldown: float
@export var max_health: int 
@export var deathParticle: PackedScene


var health: int
var facing_direction: Vector2 
var can_attack: bool

@onready var player = $/root/Main/GameNode/Player

func _ready() -> void:
	speed = 90
	detection_range = 150.0
	attack_cooldown = 1.2
	max_health = 50
	facing_direction = Vector2.DOWN
	can_attack = true
	
	health = max_health
	$AnimatedSprite2D.play("run0")

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var distance_from_player = global_position.distance_to(player.global_position)
	var direction: Vector2 = global_position.direction_to(player.global_position)

	if distance_from_player < detection_range:
		facing_direction = direction
		velocity = direction * speed
		_update_facing_animation(direction)
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()

	move_and_slide()

func _update_facing_animation(direction: Vector2) -> void:
	if direction.x >= 0:
		if $AnimatedSprite2D.animation != "run0":
			$AnimatedSprite2D.play("run0")
	else:
		if $AnimatedSprite2D.animation != "run2":
			$AnimatedSprite2D.play("run2")
	if direction.y >= 0:
		if $AnimatedSprite2D.animation != "run3":
			$AnimatedSprite2D.play("run3")
	else:
		if $AnimatedSprite2D.animation != "run1":
			$AnimatedSprite2D.play("run1")

func _on_attack_area_body_entered(body: Node2D) -> void:
	if not can_attack:
		return
	if body != player:
		return

	attack_player(body)

func attack_player(target: CharacterBody2D) -> void:
	can_attack = false

	if target.has_method("take_damage"):
		target.take_damage(10)

	if "is_camouflaged" in target and target.is_camouflaged:
		target.powerup_force_ended.emit("camo")

	$AttackCooldownTimer.start()


func _on_attack_cool_down_timeout() -> void:
	can_attack = true

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

	if health <= 0:
		AudioController.play_death()
		get_node("/root/Main").dogs -= 1
		queue_free()
	else:
		AudioController.play_hit()

func Explode() -> void:
	if deathParticle == null:
		return
	var _particle = deathParticle.instantiate()
	_particle.position = global_position
	_particle.rotation = global_rotation
	_particle.emitting = true
	get_tree().current_scene.add_child(_particle)
