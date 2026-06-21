class_name PowerUp
extends Resource

@export var powerup_name: String = ""
@export var level: int = 0

# Activate power up
func apply(player: CharacterBody2D) -> void:
	pass

# Deactivate power up
func remove(player: CharacterBody2D) -> void:
	pass
