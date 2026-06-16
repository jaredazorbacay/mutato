extends Area2D

var anchor = Vector2(10.0, -10.0)
var whip_tip = Vector2(10.0, -70.0)



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func _draw():
	draw_line(anchor, whip_tip, "red", 5)
