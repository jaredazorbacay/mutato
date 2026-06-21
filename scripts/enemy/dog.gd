extends CharacterBody2D

@export var speed: float
@export var detection_range: float
@export var attack_cooldown: float
@export var max_health: int 
@export var deathParticle: PackedScene



var health: int
var facing_direction: Vector2 
var can_attack: bool
var hasFertilizer = false
var fertilizer_scene = preload("res://scenes/items/fertilizer.tscn")
var is_poisoned: bool
const PoisonPulseShader = preload("res://scenes/poison_pulse.gdshader")
var damage

@onready var player = $/root/Main/GameNode/Player

func _ready() -> void:
	speed = 200
	detection_range = 300
	attack_cooldown = 1.2
	facing_direction = Vector2.DOWN
	can_attack = true
	$HealthBar/ProgressBar.max_value = max_health
	$HealthBar/ProgressBar.value = health
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
		target.take_damage(damage)

	if "is_camouflaged" in target and target.is_camouflaged:
		target.powerup_force_ended.emit("camo")

	$AttackCoolDown.start()


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
		drops()
		AudioController.play_death()
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

func drops():
	if hasFertilizer:
		var fertilizer_object = fertilizer_scene.instantiate()
		get_tree().current_scene.add_child(fertilizer_object)
		fertilizer_object.position = global_position
		
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
	
func set_level(lvl):
	max_health = 50 + (15 * lvl)
	health = 50 + (15 * lvl)
	$HealthBar/ProgressBar.max_value = max_health
	$HealthBar/ProgressBar.value = health
	damage = 2 + (1 * lvl)
	pass
	
func take_damage_lowk(dmg):
	health -= dmg
	$HealthBar/ProgressBar.value = health
	if health <= 0:
		drops()
		AudioController.play_death()
		queue_free()
