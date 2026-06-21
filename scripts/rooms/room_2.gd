extends TileMapLayer

var right_door: Vector2i
var left_door: Vector2i
var top_door: Vector2i
var bottom_door: Vector2i

var right_door_open: bool
var left_door_open: bool
var top_door_open: bool
var bottom_door_open: bool
var spawn_points = []

# position in world blocks
var map_coords: Vector2i

#position in tiles
var tile_position_in_world: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	right_door = Vector2i(14,6)
	left_door = Vector2i(0, 6)
	top_door = Vector2i(7,0)
	bottom_door = Vector2i(7, 15)
	
	add_spawn_zone(1,13,1,12)
	add_spawn_zone(2,12,5,6)
	add_spawn_zone(2,13,9,11)
	add_spawn_zone(1,13, 14,15)

func set_coords(coords: Vector2i):
	map_coords = coords
	
func open_door(direction : String):
	get_node(direction + "_door").queue_free()
	
func spawn_enemies(count, level):
	var enemies_scene = [
		preload("res://scenes/scientist.tscn"),
		preload("res://scenes/saber_scientist.tscn"),
	]
	
	spawn_points.shuffle()
	for i in count:
		var location = spawn_points.pick_random()
		var enemy = enemies_scene.pick_random().instantiate()
		enemy.z_index = 10
		add_child(enemy)
		enemy.global_position = global_position + Vector2(
			location.x * 32, location.y *32
		)
		spawn_points.erase(location)
	
	var location = spawn_points.pick_random()
	var enemy = enemies_scene.pick_random().instantiate()
	enemy.hasFertilizer = true
	enemy.z_index = 10
	add_child(enemy)
	enemy.global_position = global_position + Vector2(
		location.x * 32, location.y *32
	)
	spawn_points.erase(location)
	
func add_spawn_zone(initX, finX, initY, finY):
	for x in range(initX, finX):
		for y in range(initY, finY):
			spawn_points.append(Vector2i(x,y))
