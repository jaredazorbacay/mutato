extends CharacterBody2D

class_name Player

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
var multi_whip_active: bool
var multi_whip_count: int
var is_camouflaged: bool

signal healthChanged

#MUTATION VALUES
const PoisonBubbles = preload("res://scenes/poison_bubbles.tscn")
const GrowthPowerUp = preload("res://scripts/powerups/growth.tres")
const ShieldPowerUp = preload("res://scripts/powerups/shield.tres")
const PoisonWhipPowerUp = preload("res://scripts/powerups/poison_whip.tres")
const MultiWhipPowerUp = preload("res://scripts/powerups/multi_whip.tres")
const CamoPowerUp = preload("res://scripts/powerups/camo.tres")
const WhipScene = preload("res://scenes/whip.tscn")

const FertilizerScene = preload("res://scenes/fertilizer.tscn")
const PowerUpChoiceUI = preload("res://scenes/powerup_choice_ui.tscn")

signal powerup_force_ended(powerup_name: String)

var active_powerups: Dictionary = {}
var base_scale: Vector2
var base_damage: int
var damage_multiplier: float

var all_powerups: Array[PowerUp] = [
	GrowthPowerUp,
	ShieldPowerUp,
	PoisonWhipPowerUp,
	MultiWhipPowerUp,
	CamoPowerUp
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
	get_parent().add_child(fert)
	fert.global_position = global_position + Vector2(150, 0)


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
	
	if poison_whip_active:
		poison_whip_uses_remaining -= 1
		if poison_whip_uses_remaining <= 0:
			var pw = active_powerups.get("poison_whip")
			if pw:
				active_powerups.erase("poison_whip")
				pw.remove(self)
				recalculate_damage_multiplier()
				powerup_force_ended.emit("poison_whip")
	
	if multi_whip_active:
		var angle_step = TAU / multi_whip_count
		for i in multi_whip_count:
			var swing_angle = angle + (angle_step * i)
			var whip_node = $Whip if i == 0 else WhipScene.instantiate()
			if i != 0:
				add_child(whip_node)
			perform_whip_swing(whip_node, swing_angle)
			if i != 0:
				await get_tree().create_timer(0.5).timeout
				whip_node.queue_free()
	else:
		await perform_whip_swing($Whip, angle)
	
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
		var damage = base_damage * damage_multiplier
		body.take_damage(damage, global_position)
		if poison_whip_active:
			body.apply_poison(2, 3, 1.0)


func take_damage(damage: int) -> void:
	if active_powerups.has("shield"):
		shield_hits_remaining -= 1
		if shield_hits_remaining <= 0:
			var shield_powerup = active_powerups["shield"]
			active_powerups.erase("shield")
			shield_powerup.remove(self)
			recalculate_damage_multiplier()
			powerup_force_ended.emit("shield")
		return
	
	health -= damage
	healthChanged.emit()
	if (health <= 0):
		queue_free()
	

func activate_powerup(powerup: PowerUp) -> void:
	if active_powerups.has(powerup.powerup_name):
		return
	
	active_powerups[powerup.powerup_name] = powerup
	powerup.apply(self)
	recalculate_damage_multiplier()
	
	var timer = get_tree().create_timer(powerup.duration)
	var ended_early = false
	
	var on_force_end = func(name):
		if name == powerup.powerup_name:
			ended_early = true
	powerup_force_ended.connect(on_force_end)
	
	await timer.timeout
	
	powerup_force_ended.disconnect(on_force_end)
	
	if active_powerups.has(powerup.powerup_name):
		active_powerups.erase(powerup.powerup_name)
		powerup.remove(self)
		recalculate_damage_multiplier()

func recalculate_damage_multiplier() -> void:
	damage_multiplier = 1.0
	for powerup_name in active_powerups:
		var powerup = active_powerups[powerup_name]
		if "damage_multiplier" in powerup:
			damage_multiplier *= powerup.damage_multiplier

#MUTATION FUNCTIONS
func show_powerup_choices() -> void:
	var choices = all_powerups.duplicate()
	choices.shuffle()
	choices = choices.slice(0, 3)
	
	get_tree().paused = true
	pending_powerup_choices = choices
	
	var names: Array = []
	for p in choices:
		names.append(p.powerup_name)
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
