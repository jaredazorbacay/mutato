extends CharacterBody2D

var direction
var speed = 300.0
var fired = false


func fire(direct, spd):
	print(direct)
	direction = direct
	speed = spd
	fired = true

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if (fired):
		velocity = direction.normalized() * speed
		move_and_slide()
