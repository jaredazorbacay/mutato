extends CharacterBody2D


@onready var player = $/root/Main/GameNode/Player
var speed : int
var health: int
var slash_damage: int
var cooldown: float
var attacking: bool   # Added to prevent overlapping melee attacks
var hasFertilizer = false
var fertilizer_scene = preload("res://scenes/items/fertilizer.tscn")
var facing_direction: Vector2
var is_poisoned: bool
const PoisonPulseShader = preload("res://scenes/poison_pulse.gdshader")

@export var deathParticle : PackedScene
@onready var stuck_timer = $StuckTimer

func _ready() -> void:
	speed = 175
	health = 100
	cooldown = 0
	slash_damage = 10
	attacking = false
	$HealthBar/ProgressBar.value = health

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
	
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	var attack_range := 50
	var distance_from_player = 10000
	if player:
		distance_from_player = global_position.distance_to(player.global_position)
	
	if  distance_from_player < 1000 and not player.is_camouflaged:
		var direction: Vector2 = global_position.direction_to(player.global_position)
		var cropped_angle = snappedf(direction.angle(), PI/4) / (PI/4)
		cropped_angle = wrapi(int(cropped_angle), 0, 8)
		
		if !attacking:
			if distance_from_player > attack_range:
				var run_anim = "run" + str(int(cropped_angle/2))
				if $AnimatedSprite2D.animation != run_anim:
					$AnimatedSprite2D.play(run_anim)

				velocity = direction.normalized() * speed
				move_and_slide()
				
			#elif distance_from_player <= attack_range and cooldown <= 0::
				#var can_attack := true
				#var slash_anim = "slash" + str(int(cropped_angle/2))
				#if $AnimatedSprite2D.animation != slash_anim:
					#$AnimatedSprite2D.play(slash_anim)
				#velocity = Vector2.ZERO
				#velocity = direction.normalized() * -speed
			elif distance_from_player <= attack_range and cooldown <= 0:
				# Trigger the slash attack
				saber_attack(cropped_angle, direction)
				
func saber_attack(cropped_angle: int, direction: Vector2) -> void:
	attacking = true
	cooldown = 0.4 # Cooldown time between attacks (seconds)
	
	# Stop movement and play the attack animation
	velocity = Vector2.ZERO
	var slash_anim = "slash" + str(int(cropped_angle/2))
	$AnimatedSprite2D.play(slash_anim)
	
	# Optional: Wait a tiny fraction of a second for the animation swing to connect
	await get_tree().create_timer(0.1).timeout
	
	# Double check player is still valid and within range when the hit lands
	if player and global_position.distance_to(player.global_position) <= 100:
		if player.has_method("take_damage"):
			player.take_damage(slash_damage)
			# AudioController.play_saber_hit() # Add sound if you have one!

	# Wait for the slash animation to finish before allowing movement again
	await get_tree().create_timer(0.3).timeout
	attacking = false
	
	# Start processing the attack cooldown
	run_cooldown()
	
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
	
func run_cooldown():
	while (cooldown > 0):
		await get_tree().create_timer(0.5).timeout
		cooldown -= 0.5
		
func drops():
	if hasFertilizer:
		var fertilizer_object = fertilizer_scene.instantiate()
		get_tree().current_scene.add_child(fertilizer_object)
		fertilizer_object.position = global_position
