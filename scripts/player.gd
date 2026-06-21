extends CharacterBody2D

class_name Player

var speed = 350
var isAttacking : bool
var xDirection : String
var yDirection : String
var cooldown: float
var health : int
var max_health: int
var shield_active: bool
var shield_hits_remaining: int
var max_shield: int
var poison_whip_uses_remaining: int
var poison_whip_active: bool
var multi_whip_active: bool
var multi_whip_count: int
var is_camouflaged: bool
var lowk_time: float

signal healthChanged
signal shieldChanged

#MUTATION VALUES
const PoisonBubbles = preload("res://scenes/poison_bubbles.tscn")
const GrowthPowerUp = preload("res://scripts/powerups/growth.tres")
const ShieldPowerUp = preload("res://scripts/powerups/shield.tres")
const PoisonWhipPowerUp = preload("res://scripts/powerups/poison_whip.tres")
const MultiWhipPowerUp = preload("res://scripts/powerups/multi_whip.tres")
const CamoPowerUp = preload("res://scripts/powerups/camo.tres")
const WhipScene = preload("res://scenes/whip.tscn")

const FertilizerScene = preload("res://scenes/items/fertilizer.tscn")
const PowerUpChoiceUI = preload("res://scenes/powerup_choice_ui.tscn")

signal powerup_force_ended(powerup_name: String)

var active_powerups: Dictionary = {
	"poison": 0,
	"growth": 0,
	"shield": 0,
	"camo": 0,
	"thorns": 0,
}
var base_scale: Vector2
var base_damage: int
var damage_multiplier: float

var all_powerups: Array[String] = [
	"GrowthPowerUp",
	"ShieldPowerUp",
	"PoisonWhipPowerUp",
	"CamoPowerUp",
	"ThornsPowerUp",
]

var pending_powerup_choices: Array = []
var powerup_choice_ui: CanvasLayer

@onready var shield_node = $Shield


func _ready() -> void:
	$AnimatedSprite2D.speed_scale = 1.75
	isAttacking = false
	xDirection = ""
	yDirection = "D"
	cooldown = 0
	health = 100
	max_health = 100
	
	#PLACEHOLDERS FOR MUTATIONS
	#initialize
	poison_whip_uses_remaining = 0
	poison_whip_active = false
	multi_whip_active = false
	multi_whip_count = 4
	is_camouflaged = false
	
	base_scale = scale
	base_damage = 50
	damage_multiplier = 1.0
	
	powerup_choice_ui = PowerUpChoiceUI.instantiate()
	get_tree().root.add_child.call_deferred(powerup_choice_ui)
	powerup_choice_ui.card_selected.connect(_on_powerup_card_selected)
	
	
func get_input():
	var input_direct = Input.get_vector("left", "right", "up", "down")
	velocity = input_direct.normalized() * speed
	
	
func _process(delta: float) -> void:
	if is_camouflaged:
		return
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
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse = get_local_mouse_position()
		whip_attack(mouse.angle())

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		spawn_test_fertilizer()


func spawn_test_fertilizer() -> void:
	var fert = FertilizerScene.instantiate()
	get_parent().get_parent().add_child(fert)
	fert.global_position = global_position + Vector2(150, 0)
	
func time_to_camo():
	while lowk_time > 0:
		await get_tree().create_timer(0.5).timeout
		lowk_time -= 0.5
	
	$AnimatedSprite2D.play("potato")
	is_camouflaged = true


func whip_attack(angle) -> void:
	
	if (cooldown > 0):
		return
	cooldown = 0.1
	
	AudioController.play_whip()
	
	isAttacking = true
	var mouse = get_local_mouse_position()
	var cropped_angle = snappedf(mouse.angle(), PI/4) / (PI/4)
	cropped_angle = wrapi(int(cropped_angle), 0, 8)
	set_face_index_by_angle(cropped_angle)
	
	
	await perform_whip_swing($Whip, angle)
	
	if is_camouflaged == true:
		is_camouflaged = false
		lowk_time = 5/(active_powerups["camo"] * 0.5)
		time_to_camo()
	
	
	isAttacking = false
	run_cooldown()


func perform_whip_swing(whip_node: Node2D, angle: float) -> void:
	whip_node.rotation = angle
	
	if angle > 0:
		whip_node.z_index = 1
	else:
		whip_node.z_index = -1
	
	if poison_whip_active:
		whip_node.get_node("AnimatedSprite2D").play("whip_poison")
	else:
		whip_node.get_node("AnimatedSprite2D").play("whip")
	
	await get_tree().create_timer(0.2).timeout
	
	if poison_whip_active:
		var bubbles = PoisonBubbles.instantiate()
		get_parent().add_child(bubbles)
		bubbles.global_position = whip_node.get_node("Area2D/CollisionShape2D").global_position
		bubbles.emitting = true
	
	var bodies: Array = whip_node.get_node("Area2D").get_overlapping_bodies()
	for body in bodies:
		var damage = (base_damage * damage_multiplier) + (base_damage * (active_powerups["camo"]/3) if is_camouflaged else 1)
		body.take_damage(damage, global_position)
		if poison_whip_active:
			body.apply_poison(3 + (2*active_powerups["poison"]), 3 + (0.5*active_powerups["poison"]), 1.0 / (active_powerups["poison"]/2))


func take_damage(damage: int) -> void:
	if shield_hits_remaining > damage:
		shield_hits_remaining -= damage
		shieldChanged.emit()
		return
	elif shield_hits_remaining > 0:
		shield_hits_remaining = 0
		shield_node.visible = false
		shieldChanged.emit()
		regen_shield()
		return
	$Camera2D.apply_shake(100)
	health -= damage
	healthChanged.emit()
	if (health <= 0):
		queue_free()
	

func activate_powerup(powerup: String) -> void:
	match powerup:
		"PoisonWhipPowerUp": 
			active_powerups["poison"] +=1
			poison_whip_active = true
		"ShieldPowerUp":
			active_powerups["shield"] +=1
			shield_node.visible = true
			max_shield = 25 + (active_powerups["shield"] * 10)
			shield_hits_remaining = 25 + (active_powerups["shield"] * 10)
			shieldChanged.emit()
		"GrowthPowerUp":
			active_powerups["growth"] +=1
			print (1/float(active_powerups["growth"]) )
			max_health += 25
			health += 25
			healthChanged.emit()
			scale = Vector2(1 + (1- (1/float(active_powerups["growth"] + 1))),1 + (1- (1/float(active_powerups["growth"] + 1))))
			base_damage += 10
			speed -= speed/10
		"CamoPowerUp":
			active_powerups["camo"] +=1
			is_camouflaged = true
			$AnimatedSprite2D.play("potato")
			pass
		"ThornsPowerUp":
			
			pass
		
	pass

func recalculate_damage_multiplier() -> void:
	damage_multiplier = 1.0
	for powerup_name in active_powerups:
		var powerup = active_powerups[powerup_name]
		if "damage_multiplier" in powerup:
			damage_multiplier *= powerup.damage_multiplier
			
func regen_shield():
	await get_tree().create_timer(10 + (30/(active_powerups["shield"] + 1))).timeout
	shield_hits_remaining = max_shield
	shield_node.visible = true
	shieldChanged.emit()
#MUTATION FUNCTIONS
func show_powerup_choices() -> void:
	var choices = all_powerups.duplicate()
	choices.shuffle()
	choices = choices.slice(0, 3)
	
	get_tree().paused = true
	pending_powerup_choices = choices
	
	var names: Array = []
	for p in choices:
		names.append(p)
	powerup_choice_ui.show_choices(names)

func _on_powerup_card_selected(index: int) -> void:
	var chosen = pending_powerup_choices[index]
	get_tree().paused = false
	activate_powerup(chosen)

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
