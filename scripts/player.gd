extends CharacterBody2D

var speed = 350
var isAttacking : bool
var xDirection : String
var yDirection : String
var cooldown: float
var health : int
var shield_active: bool
var shield_hits_remaining: int
var poison_whip_uses_remaining: int
var poison_whip_active: bool

const PoisonBubbles = preload("res://scenes/poison_bubbles.tscn")


func _ready() -> void:
	$AnimatedSprite2D.speed_scale = 1.75
	isAttacking = false
	xDirection = ""
	yDirection = "D"
	cooldown = 0
	health = 100
	
	#PLACEHOLDERS FOR MUTATIONS
	#initialize
	poison_whip_uses_remaining = 0
	poison_whip_active = false
	
	#mutation functions
	activate_shield()
	activate_poison_whip()
	
	
func get_input():
	var input_direct = Input.get_vector("left", "right", "up", "down")
	velocity = input_direct.normalized() * speed
	
	
func _process(delta: float) -> void:

	#//Movement based direction
	if (!isAttacking and velocity.length() !=0):
		if velocity.x > 0:
			xDirection = "R"
		elif velocity.x < 0:
			xDirection = "L"
		else: xDirection = ""
		
		if velocity.y > 0:
			yDirection = "D"
		elif velocity.y < 0:
			yDirection = "U"
		else: yDirection = ""
	
	$AnimatedSprite2D.animation =  "run" + yDirection + xDirection
	if velocity.length() !=0:
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.frame = 1
	

func _physics_process(_delta):
	get_input()
	move_and_slide()
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse = get_local_mouse_position()
		whip_attack(mouse.angle())
		

func whip_attack(angle) -> void:
	
	if (cooldown > 0):
		return
	cooldown = 0.1
	$Whip.rotation = angle
	
	AudioController.play_whip()
	
	isAttacking = true
	#//mouse-based direction	
	var mouse = get_local_mouse_position()
	var cropped_angle = snappedf(mouse.angle(), PI/4) / (PI/4)
	cropped_angle = wrapi(int(cropped_angle), 0, 8)
	set_face_index_by_angle(cropped_angle)
	
	if angle > 0:
		$Whip.z_index = 1
	else:
		$Whip.z_index = -1
	
	#POISON WHIP TESTING HERE
	if poison_whip_active:
		$Whip/AnimatedSprite2D.play("whip_poison")
	else:
		$Whip/AnimatedSprite2D.play("whip")
	
	
	#$Whip/AnimatedSprite2D.play("whip")

	await get_tree().create_timer(0.2).timeout

	if poison_whip_active:
		var bubbles = PoisonBubbles.instantiate()
		get_parent().add_child(bubbles)
		bubbles.global_position = $Whip/Area2D/CollisionShape2D.global_position
		bubbles.emitting = true

	var bodies: Array = $Whip/Area2D.get_overlapping_bodies()
	for body in bodies:
		body.take_damage(50)
		if poison_whip_active:
			body.apply_poison(2, 3, 1.0)

	if poison_whip_active:
		poison_whip_uses_remaining -= 1
		if poison_whip_uses_remaining <= 0:
			poison_whip_active = false
	
	isAttacking = false
	run_cooldown()


func take_damage(damage: int) -> void:
	if shield_active:
		shield_hits_remaining -= 1
		if shield_hits_remaining <= 0:
			shield_active = false
			$Shield.visible = false
		return
	
	health -= damage
	if (health <= 0):
		queue_free()
	

#MUTATION FUNCTIONS
func activate_poison_whip() -> void:
	poison_whip_active = true
	poison_whip_uses_remaining = 20

func activate_shield() -> void:
	shield_active = true
	shield_hits_remaining = 25
	$Shield.visible = true


#********* UTILS **********#
func set_face_index_by_angle(angle) -> void:
	
	match angle:
		0:
			xDirection = "R"
			yDirection = ""
		1:
			xDirection = "R"
			yDirection = "D"
		2:
			xDirection = ""
			yDirection = "D"
		3:
			xDirection = "L"
			yDirection = "D"
		4:
			xDirection = "L"
			yDirection = ""
		5:
			xDirection = "L"
			yDirection = "U"
		6:
			xDirection = ""
			yDirection = "U"
		7:
			xDirection = "R"
			yDirection = "U"

func run_cooldown():
	while (cooldown > 0):
		await get_tree().create_timer(0.5).timeout
		cooldown -= 0.5
