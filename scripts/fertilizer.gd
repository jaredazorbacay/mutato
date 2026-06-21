extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("show_powerup_choices"):
		body.show_powerup_choices()
		queue_free()
