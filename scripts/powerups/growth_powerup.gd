class_name GrowthPowerUp
extends PowerUp

@export var scale_multiplier: float = 1.5
@export var damage_multiplier: float = 2.0

func apply(player: CharacterBody2D) -> void:
	player.scale = player.base_scale * scale_multiplier

func remove(player: CharacterBody2D) -> void:
	player.scale = player.base_scale
