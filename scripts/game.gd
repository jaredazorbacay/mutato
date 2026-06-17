extends Node

@onready var player = $/root/Main/Player
const scientist_scene = preload("res://scenes/scientist.tscn")
#const pantry_scene = preload("res://scenes/rooms/pantry.tscn")
const pantry_scene = preload("res://scenes/rooms/main_laboratory.tscn")
var enemies : int 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemies = 0
	build_level()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if enemies < 2:
		if randf_range(0, 1) > 0.5:
			var radius = randi_range(500,1000)
			var scientist : CharacterBody2D = scientist_scene.instantiate()
			var x_offset = randi_range(0, radius) * [-1, 1].pick_random()
			var y_offset = sqrt(pow(radius, 2) - pow(x_offset, 2)) * [-1, 1].pick_random()
			print(y_offset)
			get_tree().current_scene.add_child(scientist)
			scientist.global_position = player.global_position + Vector2(
				-x_offset, -y_offset
			)
			enemies+=1
			

func build_level():
	var pantry : TileMapLayer = pantry_scene.instantiate()
	pantry.z_index = -10
	get_tree().current_scene.add_child(pantry)
