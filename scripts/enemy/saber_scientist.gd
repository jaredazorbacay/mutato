extends CharacterBody2D


@onready var player = $/root/Main/Player
var speed : int
var health: int
var slash_damage: int
var cooldown: float
var attacking: bool   # Added to prevent overlapping melee attacks

@export var deathParticle : PackedScene
@onready var stuck_timer = $StuckTimer

func _ready() -> void:
	speed = 100
	health = 100
	cooldown = 0
	slash_damage = 2
	attacking = false
	$HealthBar/ProgressBar.value = health

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
	
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	var attack_range := 50
	var distance_from_player = 10000
	if player:
		distance_from_player = global_position.distance_to(player.global_position)
	
	if  distance_from_player < 1000:
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
	cooldown = 1.5 # Cooldown time between attacks (seconds)
	
	# Stop movement and play the attack animation
	velocity = Vector2.ZERO
	var slash_anim = "slash" + str(int(cropped_angle/2))
	$AnimatedSprite2D.play(slash_anim)
	
	# Optional: Wait a tiny fraction of a second for the animation swing to connect
	await get_tree().create_timer(0.1).timeout
	
	# Double check player is still valid and within range when the hit lands
	if player and global_position.distance_to(player.global_position) <= 65:
		if player.has_method("take_damage"):
			player.take_damage(slash_damage)
			# AudioController.play_saber_hit() # Add sound if you have one!

	# Wait for the slash animation to finish before allowing movement again
	await get_tree().create_timer(0.4).timeout
	attacking = false
	
	# Start processing the attack cooldown
	run_cooldown()
	
func run_cooldown():
	while (cooldown > 0):
		await get_tree().create_timer(0.5).timeout
		cooldown -= 0.5
