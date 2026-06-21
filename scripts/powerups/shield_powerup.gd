class_name ShieldPowerUp
extends PowerUp

@export var hits_to_absorb: int = 25

func apply(player: CharacterBody2D) -> void:
	player.shield_hits_remaining = hits_to_absorb
	player.shield_node.visible = true

func remove(player: CharacterBody2D) -> void:
	player.shield_node.visible = false
