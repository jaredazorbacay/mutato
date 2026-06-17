extends CharacterBody2D

var direction
var speed = 300.0
var fired = false


func fire(direct, spd):
	direction = direct
	speed = spd
	fired = true
	$AnimatedSprite2D.play()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if (fired):
		velocity = direction.normalized() * speed
		move_and_slide()
		if scale.x < 2:
			scale.x += 0.9 * delta
			scale.y += 0.9 * delta
