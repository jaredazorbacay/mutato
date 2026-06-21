class_name CamoPowerUp
extends PowerUp

func apply(player: CharacterBody2D) -> void:
	player.is_camouflaged = true
	player.get_node("AnimatedSprite2D").play("potato")

func remove(player: CharacterBody2D) -> void:
	player.is_camouflaged = false
