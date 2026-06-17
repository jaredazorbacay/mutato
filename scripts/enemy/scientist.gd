extends CharacterBody2D

@onready var player = $/root/Main/Player
var speed : int
var health: int

func _ready() -> void:
	speed = 200
	health = 100
	$HealthBar/ProgressBar.value = health

func take_damage(damage: int) -> void:
	health -= damage
	$HealthBar/ProgressBar.value = health
	if (health <= 0):
		queue_free()

func _physics_process(delta: float) -> void:
	if global_position.distance_to(player.global_position) < 500:
		# Calculate the direction from enemy to player
		var direction: Vector2 = global_position.direction_to(player.global_position)
		
		# Set velocity and move
		velocity = direction * speed
		move_and_slide()
