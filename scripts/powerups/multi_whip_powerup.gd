class_name MultiWhipPowerUp
extends PowerUp

@export var whip_count: int = 4

func apply(player: CharacterBody2D) -> void:
	player.multi_whip_active = true
	player.multi_whip_count = whip_count

func remove(player: CharacterBody2D) -> void:
	player.multi_whip_active = false
