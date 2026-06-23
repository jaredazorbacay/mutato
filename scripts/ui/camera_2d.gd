extends Camera2D

@export var shake_strength: float = 0.0
@export var shake_decay_rate: float = 5.0

@onready var noise: FastNoiseLite = FastNoiseLite.new()

const Dead_Zone = 160

var time: float = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var _target = event.position - get_viewport().size * 0.5
		if _target.length() < Dead_Zone:
			self.position = Vector2(0,0)
		else:
			self.position = _target.normalized() * (_target.length() - Dead_Zone) *0.5
 
func _process(delta: float) -> void:
	if shake_strength > 0.0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay_rate * delta)

		time += delta * 50.0
		var offset_x = noise.get_noise_2d(time, 0.0) * shake_strength
		var offset_y = noise.get_noise_2d(0.0, time) * shake_strength

		offset = Vector2(offset_x, offset_y)
	else:
		offset = Vector2.ZERO

func apply_shake(amount: float) -> void:
	shake_strength += amount
