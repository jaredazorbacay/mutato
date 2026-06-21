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
	right_door = Vector2i(14,5)
	left_door = Vector2i(0, 6)
	top_door = Vector2i(7,0)
	bottom_door = Vector2i(7, 15)
	
	add_spawn_zone(1,13,1,7)
	add_spawn_zone(7,13,13,14)
	add_spawn_zone(1,10,10,11)

func set_coords(coords: Vector2i):
	map_coords = coords
	
func open_door(direction : String):
	get_node(direction + "_door").queue_free()

func spawn_enemies(count, level):
	const scientist_scene = preload("res://scenes/scientist.tscn")
	spawn_points.shuffle()
	print(spawn_points)
	for i in count:
		var location = spawn_points.pick_random()
		var enemy = scientist_scene.instantiate()
		enemy.z_index = 10
		add_child(enemy)
		enemy.global_position = global_position + Vector2(
			location.x * 32, location.y *32
		)
		spawn_points.erase(location)
	
	var location = spawn_points.pick_random()
	var enemy = scientist_scene.instantiate()
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
