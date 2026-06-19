extends Node

@onready var player = $/root/Main/Player
const scientist_scene = preload("res://scenes/scientist.tscn")
const pantry_scene = preload("res://scenes/rooms/pantry.tscn")
const GRID_SIZE = 32
#const pantry_scene = preload("res://scenes/rooms/main_laboratory.tscn")
var enemies : int 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemies = 0
	var spawn_point : Vector2i = build_level()
	print(spawn_point)
	player.position = spawn_point + Vector2i(100, 100)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if enemies < 2:
		if randf_range(0, 1) > 0.5:
			var radius = randi_range(500,1000)
			var scientist : CharacterBody2D = scientist_scene.instantiate()
			var x_offset = randi_range(0, radius) * [-1, 1].pick_random()
			var y_offset = sqrt(pow(radius, 2) - pow(x_offset, 2)) * [-1, 1].pick_random()
			get_tree().current_scene.add_child(scientist)
			scientist.global_position = player.global_position + Vector2(
				-x_offset, -y_offset
			)
			enemies+=1
			
func build_level() -> Vector2i:
	var room_map_grid_size = 50 
	var room_map_grid_dimension : Vector2i = Vector2i(5, 5)
	var rooms = []
	var room_sequence = []
	var current_room : Vector2i
	var isStuck = false #if there is still a path to a different room
	for i in room_map_grid_dimension.x:
		for j in room_map_grid_dimension.y:
			rooms.append(Vector2i(i,j))
	
	current_room = rooms.pick_random()
	room_sequence.append(current_room)
	rooms.erase(current_room)
	
	while !isStuck:
		var room_found = false
		var available_neighbors = 	[Vector2i(current_room.x+1, current_room.y), 
									Vector2i(current_room.x-1, current_room.y),
									Vector2i(current_room.x, current_room.y+1),
									Vector2i(current_room.x, current_room.y-1)]
		available_neighbors.shuffle()
		for neighbor in available_neighbors:
			if rooms.has(neighbor):
				current_room = neighbor
				room_sequence.append(current_room)
				rooms.erase(current_room)
				room_found = true
				break
		
		isStuck = !room_found
	
	var room_scenes = []
	for room in room_sequence:
		var currentX = 0
		var currentY = 0
		var room_scene : TileMapLayer = pantry_scene.instantiate()
		room_scene.z_index = -10
		currentX = randi_range(0, 25) + (room.x * room_map_grid_size)
		currentY = randi_range(0, 25) + (room.y * room_map_grid_size)
		room_scene.set_coords(room)
		room_scene.tile_position_in_world = Vector2i(currentX, currentY)
		room_scene.position = Vector2i(currentX, currentY) * GRID_SIZE
		get_tree().current_scene.add_child(room_scene)
		
		if room_scenes.size() > 0:
			#get last room and draw a halway
			var last_room_scene = room_scenes[-1]
			
			if (room.x > last_room_scene.map_coords.x): #new room is in right
				draw_hallway( last_room_scene.tile_position_in_world + last_room_scene.right_door, Vector2i(currentX,currentY) + room_scene.left_door, "HORIZONTAL")
			elif (room.x < last_room_scene.map_coords.x):
				draw_hallway(Vector2i(currentX,currentY) + room_scene.right_door,  last_room_scene.tile_position_in_world + last_room_scene.left_door, "HORIZONTAL")
			elif (room.y > last_room_scene.map_coords.y):
				draw_hallway( last_room_scene.tile_position_in_world + last_room_scene.bottom_door, Vector2i(currentX,currentY) + room_scene.top_door, "VERTICAL")
			else:
				draw_hallway( Vector2i(currentX,currentY) + room_scene.bottom_door, last_room_scene.tile_position_in_world + last_room_scene.top_door, "VERTICAL")
			
		#record room positions
		room_scenes.append(room_scene)
	return room_scenes[0].position
		
		
func draw_hallway(start_door : Vector2i, end_door : Vector2i, orientation : String):
	if orientation == "HORIZONTAL":
		var midpoint = (end_door.x - start_door.x)/ [1.5,2, 2.5].pick_random() + start_door.x
		for i in range(start_door.x, midpoint + 1):
			$Hallway.set_cell(Vector2i(i, start_door.y + 1), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(i, start_door.y), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(i, start_door.y - 1), 1, Vector2i(2, 3))
			
		for i in range(midpoint + 1, end_door.x):
			$Hallway.set_cell(Vector2i(i, end_door.y + 1), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(i, end_door.y), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(i, end_door.y - 1), 1, Vector2i(2, 3))
		
		if (start_door.y < end_door.y):
			for i in range(start_door.y - 1, end_door.y + 2):
				$Hallway.set_cell(Vector2i(midpoint + 1, i), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(midpoint, i), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(midpoint - 1, i), 1, Vector2i(2, 3))
		else:
			for i in range(end_door.y - 1, start_door.y + 2):
				$Hallway.set_cell(Vector2i(midpoint + 1, i), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(midpoint, i), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(midpoint - 1, i), 1, Vector2i(2, 3))
	else:
		var midpoint = (end_door.y - start_door.y)/[1.5,2, 2.5].pick_random() + start_door.y
		for i in range(start_door.y, midpoint + 1):
			$Hallway.set_cell(Vector2i(start_door.x + 1, i), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(start_door.x, i), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(start_door.x - 1, i), 1, Vector2i(2, 3))
			
		for i in range(midpoint + 1, end_door.y):
			$Hallway.set_cell(Vector2i(end_door.x + 1, i), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(end_door.x, i), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(end_door.x - 1, i), 1, Vector2i(2, 3))
		
		if (start_door.x < end_door.x):
			for i in range(start_door.x - 1, end_door.x + 2):
				$Hallway.set_cell(Vector2i(i, midpoint + 1), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(i, midpoint), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(i, midpoint - 1), 1, Vector2i(2, 3))
		else:
			for i in range(end_door.x - 1, start_door.x + 2):
				$Hallway.set_cell(Vector2i(i, midpoint + 1), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(i, midpoint), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(i, midpoint - 1), 1, Vector2i(2, 3))
