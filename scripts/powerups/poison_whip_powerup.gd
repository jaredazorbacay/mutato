class_name PoisonWhipPowerUp
extends PowerUp

@export var max_uses: int = 20

func apply(player: CharacterBody2D) -> void:
	player.poison_whip_active = true
	player.poison_whip_uses_remaining = max_uses

func remove(player: CharacterBody2D) -> void:
	player.poison_whip_active = false
