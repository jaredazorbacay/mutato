extends CharacterBody2D

@onready var player = $/root/Main/Player
var direction
var speed : float
var fired = false
var damage : int

func fire(direct, spd, dmg, quadrant):
	direction = direct
	speed = spd
	fired = true
	damage = dmg
	$AnimatedSprite2D.play()
	match quadrant:
		0:
			move_local_x(20)
			move_local_y(25)
		1:
			move_local_x(20)
			move_local_y(50)
		2:
			move_local_x(-20)
			move_local_y(25)
		3: 
			move_local_x(-20)
			move_local_y(-10)
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if (fired):
		velocity = direction.normalized() * speed
		move_and_slide()
		if scale.x < 2:
			scale.x += 0.9 * delta
			scale.y += 0.9 * delta
			
	if get_slide_collision_count() > 0:
		explode()
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if (collider.name == player.name):
				player.take_damage(damage)
				break
func explode():
	queue_free()
	
