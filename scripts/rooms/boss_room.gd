extends TileMapLayer

var right_door: Vector2i
var left_door: Vector2i
var top_door: Vector2i
var bottom_door: Vector2i

var right_door_open: bool
var left_door_open: bool
var top_door_open: bool
var bottom_door_open: bool

# position in world blocks
var map_coords: Vector2i

#position in tiles
var tile_position_in_world: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	right_door = Vector2i(14,5)
	left_door = Vector2i(0, 6)
	top_door = Vector2i(7,0)
	bottom_door = Vector2i(7, 15)

func set_coords(coords: Vector2i):
	map_coords = coords
	
func open_door(direction : String):
	get_node(direction + "_door").queue_free()
	
func spawn_boss(level):
	var enemies_scene = preload("res://scenes/boss.tscn")
	
	
	var location = Vector2i (6,8)
	var enemy = enemies_scene.instantiate()
	enemy.z_index = 10
	enemy.set_level(level)
	add_child(enemy)
	enemy.global_position = global_position + Vector2(
		location.x * 32, location.y *32
	)
	return enemy
