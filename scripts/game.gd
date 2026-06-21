extends Node

@onready var player = $/root/Main/GameNode/Player
const scientist_scene = preload("res://scenes/scientist.tscn")
const GRID_SIZE = 32
#const pantry_scene = preload("res://scenes/rooms/main_laboratory.tscn")
var enemies : int 
var scene_for_rooms = []

enum TileTransform {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
	flip = TileSetAtlasSource.TRANSFORM_FLIP_H 
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scene_for_rooms =[
		preload("res://scenes/rooms/pantry.tscn"),
		#preload("res://scenes/rooms/room1.tscn"),
		#preload("res://scenes/rooms/room2.tscn"),
		#preload("res://scenes/rooms/room3.tscn"),
		#preload("res://scenes/rooms/boss_room.tscn"),
	]
	enemies = 0
	var spawn_point : Vector2i = build_level()
	player.position = spawn_point + Vector2i(100, 100)
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if enemies < 2:
		#if randf_range(0, 1) > 0.5:
			#var radius = randi_range(500,1000)
			#var scientist : CharacterBody2D = scientist_scene.instantiate()
			#var x_offset = randi_range(0, radius) * [-1, 1].pick_random()
			#var y_offset = sqrt(pow(radius, 2) - pow(x_offset, 2)) * [-1, 1].pick_random()
			#add_child(scientist)
			#scientist.global_position = player.global_position + Vector2(
				#-x_offset, -y_offset
			#)
			#enemies+=1
	pass
			
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
		var room_scene : TileMapLayer = scene_for_rooms.pick_random().instantiate()
		room_scene.z_index = -10
		currentX = randi_range(10, 30) + (room.x * room_map_grid_size)
		currentY = randi_range(0, 25) + (room.y * room_map_grid_size)
		room_scene.set_coords(room)
		room_scene.tile_position_in_world = Vector2i(currentX, currentY)
		room_scene.position = Vector2i(currentX, currentY) * GRID_SIZE
		add_child(room_scene)
		
		if room_scenes.size() > 0:
			#get last room and draw a halway
			var last_room_scene = room_scenes[-1]
			
			if (room.x > last_room_scene.map_coords.x): #new room is in right
				draw_hallway( last_room_scene.tile_position_in_world + last_room_scene.right_door, Vector2i(currentX,currentY) + room_scene.left_door, "HORIZONTAL")
				last_room_scene.open_door("right")
				room_scene.open_door("left")
			elif (room.x < last_room_scene.map_coords.x): #new room is in left
				draw_hallway(Vector2i(currentX,currentY) + room_scene.right_door,  last_room_scene.tile_position_in_world + last_room_scene.left_door, "HORIZONTAL")
				last_room_scene.open_door("left")
				room_scene.open_door("right")
			elif (room.y > last_room_scene.map_coords.y): #new room is in bottom
				draw_hallway( last_room_scene.tile_position_in_world + last_room_scene.bottom_door, Vector2i(currentX,currentY) + room_scene.top_door, "VERTICAL")
				last_room_scene.open_door("bottom")
				room_scene.open_door("top")
			else: #new room is in top
				draw_hallway( Vector2i(currentX,currentY) + room_scene.bottom_door, last_room_scene.tile_position_in_world + last_room_scene.top_door, "VERTICAL")
				last_room_scene.open_door("top")
				room_scene.open_door("bottom")
			
		#record room positions
		room_scenes.append(room_scene)
	
	#Dead ends
	for room in room_scenes:
		var available_neighbors = 	[Vector2i(room.map_coords.x+1, room.map_coords.y), 
									Vector2i(room.map_coords.x-1, room.map_coords.y),
									Vector2i(room.map_coords.x, room.map_coords.y+1),
									Vector2i(room.map_coords.x, room.map_coords.y-1)]
		available_neighbors.shuffle()
		for neighbor in available_neighbors:
			if rooms.has(neighbor):
				rooms.erase(neighbor)
				
				var currentX = 0
				var currentY = 0
				var neighbor_room_scene : TileMapLayer = scene_for_rooms.pick_random().instantiate()
				neighbor_room_scene.z_index = -10
				currentX = randi_range(10, 30) + (neighbor.x * room_map_grid_size)
				currentY = randi_range(0, 25) + (neighbor.y * room_map_grid_size)
				neighbor_room_scene.set_coords(neighbor)
				neighbor_room_scene.tile_position_in_world = Vector2i(currentX, currentY)
				neighbor_room_scene.position = Vector2i(currentX, currentY) * GRID_SIZE
				add_child(neighbor_room_scene)
				
				if (neighbor.x > room.map_coords.x): #new room is in right
					draw_hallway( room.tile_position_in_world + room.right_door, Vector2i(currentX,currentY) + neighbor_room_scene.left_door, "HORIZONTAL")
					room.open_door("right")
					neighbor_room_scene.open_door("left")
				elif (neighbor.x < room.map_coords.x): #new room is in left
					draw_hallway(Vector2i(currentX,currentY) + neighbor_room_scene.right_door,  room.tile_position_in_world + room.left_door, "HORIZONTAL")
					room.open_door("left")
					neighbor_room_scene.open_door("right")
				elif (neighbor.y > room.map_coords.y): #new room is in bottom
					draw_hallway( room.tile_position_in_world + room.bottom_door, Vector2i(currentX,currentY) + neighbor_room_scene.top_door, "VERTICAL")
					room.open_door("bottom")
					neighbor_room_scene.open_door("top")
				else: #new room is in top
					draw_hallway( Vector2i(currentX,currentY) + neighbor_room_scene.bottom_door, room.tile_position_in_world + room.top_door, "VERTICAL")
					room.open_door("top")
					neighbor_room_scene.open_door("bottom")
				
				print(room.map_coords, neighbor)
				
		
	return room_scenes[0].position
		
		
func draw_hallway(start_door : Vector2i, end_door : Vector2i, orientation : String):
	if orientation == "HORIZONTAL":
		var midpoint = (end_door.x - start_door.x)/ [1.5,2, 2.5].pick_random() + start_door.x
		for i in range(start_door.x + 1, midpoint + 1):
			
			#path
			$Hallway.set_cell(Vector2i(i, start_door.y + 1), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(i, start_door.y), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(i, start_door.y - 1), 1, Vector2i(2, 3))
			
			#walls
			$Hallway.set_cell(Vector2i(i, start_door.y - 2), 1, Vector2i(1, 2))
			$Hallway.set_cell(Vector2i(i, start_door.y - 3), 1, Vector2i(1, 1))
			$Hallway.set_cell(Vector2i(i, start_door.y - 4), 1, Vector2i(1, 0))
			
			$Hallway.set_cell(Vector2i(i, start_door.y + 2), 1, Vector2i(5, 2), TileTransform.ROTATE_90)
			
		for i in range(midpoint + 1, end_door.x + 1):
			$Hallway.set_cell(Vector2i(i, end_door.y + 1), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(i, end_door.y), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(i, end_door.y - 1), 1, Vector2i(2, 3))
			
			#walls
			$Hallway.set_cell(Vector2i(i - 1, end_door.y - 2), 1, Vector2i(1, 2))
			$Hallway.set_cell(Vector2i(i - 1, end_door.y - 3), 1, Vector2i(1, 1))
			$Hallway.set_cell(Vector2i(i - 1, end_door.y - 4), 1, Vector2i(1, 0))
			
			$Hallway.set_cell(Vector2i(i - 1, end_door.y + 2), 1, Vector2i(5, 2), TileTransform.ROTATE_90)
		
		if (start_door.y < end_door.y):
			for i in range(start_door.y - 1, end_door.y + 2):
				$Hallway.set_cell(Vector2i(midpoint + 1, i), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(midpoint, i), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(midpoint - 1, i), 1, Vector2i(2, 3))
				
				if (![i, i+1, i-1].has(start_door.y)): $Hallway.set_cell(Vector2i(midpoint - 2, i), 1, Vector2i(0, 2), TileTransform.ROTATE_180)
				if (![i, i+1, i-1].has(end_door.y)): $Hallway.set_cell(Vector2i(midpoint + 2, i), 1, Vector2i(0, 2))
			
			#CornerWalls
			$Hallway.set_cell(Vector2i(midpoint+1, start_door.y - 2), 1, Vector2i(1, 2))
			$Hallway.set_cell(Vector2i(midpoint+1, start_door.y - 3), 1, Vector2i(1, 1))
			$Hallway.set_cell(Vector2i(midpoint+1, start_door.y - 4), 1, Vector2i(1, 0))
			
			$Hallway.set_cell(Vector2i(midpoint + 2, start_door.y -2), 1, Vector2i(0, 2))
			$Hallway.set_cell(Vector2i(midpoint + 2, start_door.y -3), 1, Vector2i(0, 2))
			$Hallway.set_cell(Vector2i(midpoint + 2, start_door.y -4), 1, Vector2i(0, 1))
			
			$Hallway.set_cell(Vector2i(midpoint - 2, start_door.y +2), 1, Vector2i(5, 1), TileTransform.ROTATE_90)
			
			$Hallway.set_cell(Vector2i(midpoint+2, end_door.y - 2), 1, Vector2i(1, 2))
			$Hallway.set_cell(Vector2i(midpoint+2, end_door.y - 3), 1, Vector2i(1, 1))
			
			$Hallway.set_cell(Vector2i(midpoint - 1, end_door.y + 2), 1, Vector2i(5, 2), TileTransform.ROTATE_90)
			$Hallway.set_cell(Vector2i(midpoint - 2, end_door.y + 2), 1, Vector2i(0, 2), TileTransform.ROTATE_180)
		elif (start_door.y > end_door.y) :
			for i in range(end_door.y - 1, start_door.y + 2):
				$Hallway.set_cell(Vector2i(midpoint + 1, i), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(midpoint, i), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(midpoint - 1, i), 1, Vector2i(2, 3))
				
				if (![i, i+1, i-1].has(start_door.y)): $Hallway.set_cell(Vector2i(midpoint - 2, i), 1, Vector2i(0, 2), TileTransform.ROTATE_180)
				if (![i, i+1, i-1].has(end_door.y)): $Hallway.set_cell(Vector2i(midpoint + 2, i), 1, Vector2i(0, 2))
			
			#CornerWalls
			$Hallway.set_cell(Vector2i(midpoint-2, start_door.y - 2), 1, Vector2i(1, 2))
			$Hallway.set_cell(Vector2i(midpoint-2, start_door.y - 3), 1, Vector2i(1, 1))
			
			$Hallway.set_cell(Vector2i(midpoint-1, end_door.y - 2), 1, Vector2i(1, 2))
			$Hallway.set_cell(Vector2i(midpoint-1, end_door.y - 3), 1, Vector2i(1, 1))
			$Hallway.set_cell(Vector2i(midpoint-1, end_door.y - 4), 1, Vector2i(1, 0))
			
			$Hallway.set_cell(Vector2i(midpoint - 2, end_door.y -2), 1, Vector2i(0, 2), TileTransform.ROTATE_180)
			$Hallway.set_cell(Vector2i(midpoint - 2, end_door.y -3), 1, Vector2i(0, 2), TileTransform.ROTATE_180)
			$Hallway.set_cell(Vector2i(midpoint - 2, end_door.y -4), 1, Vector2i(0, 1), TileTransform.flip)
			
			$Hallway.set_cell(Vector2i(midpoint + 2, end_door.y +2), 1, Vector2i(5, 2), TileTransform.ROTATE_90)
			$Hallway.set_cell(Vector2i(midpoint + 1, start_door.y +2), 1, Vector2i(5, 2), TileTransform.ROTATE_90)
			$Hallway.set_cell(Vector2i(midpoint + 2, start_door.y +2), 1, Vector2i(0, 2))
	else:
		var midpoint = (end_door.y - start_door.y)/[1.5,2, 2.5].pick_random() + start_door.y
		for i in range(start_door.y, midpoint + 1):
			$Hallway.set_cell(Vector2i(start_door.x + 1, i), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(start_door.x, i), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(start_door.x - 1, i), 1, Vector2i(2, 3))
			
			#walls
			$Hallway.set_cell(Vector2i(start_door.x - 2, i+1), 1, Vector2i(0, 2), TileTransform.ROTATE_180)
			$Hallway.set_cell(Vector2i(start_door.x + 2, i+1), 1, Vector2i(0, 2))
			
		for i in range(midpoint + 1, end_door.y):
			$Hallway.set_cell(Vector2i(end_door.x + 1, i), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(end_door.x, i), 1, Vector2i(2, 3))
			$Hallway.set_cell(Vector2i(end_door.x - 1, i), 1, Vector2i(2, 3))
			
			#walls
			$Hallway.set_cell(Vector2i(end_door.x - 2, i-2), 1, Vector2i(0, 2), TileTransform.ROTATE_180)
			$Hallway.set_cell(Vector2i(end_door.x + 2, i-2), 1, Vector2i(0, 2))
		
		if (start_door.x < end_door.x):
			for i in range(start_door.x - 1, end_door.x + 2):
				$Hallway.set_cell(Vector2i(i, midpoint + 1), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(i, midpoint), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(i, midpoint - 1), 1, Vector2i(2, 3))
				
				#walls
				if (![i, i+1, i-1].has(start_door.x)):
					$Hallway.set_cell(Vector2i(i, midpoint - 2), 1, Vector2i(1, 2))
					$Hallway.set_cell(Vector2i(i, midpoint - 3), 1, Vector2i(1, 1))
				if (![i, i+1, i-1].has(end_door.x)): $Hallway.set_cell(Vector2i(i, midpoint + 2), 1, Vector2i(5, 2), TileTransform.ROTATE_90)
				
			#CornerWalls
			$Hallway.set_cell(Vector2i(end_door.x +2, midpoint - 3), 1, Vector2i(0, 2))
			$Hallway.set_cell(Vector2i(end_door.x +2, midpoint - 2), 1, Vector2i(0, 2))
			
			$Hallway.set_cell(Vector2i(start_door.x -2, midpoint + 2), 1, Vector2i(0, 2), TileTransform.ROTATE_180)
					
		elif (start_door.x > end_door.x):
			for i in range(end_door.x - 1, start_door.x + 2):
				$Hallway.set_cell(Vector2i(i, midpoint + 1), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(i, midpoint), 1, Vector2i(2, 3))
				$Hallway.set_cell(Vector2i(i, midpoint - 1), 1, Vector2i(2, 3))
				
				if (![i, i+1, i-1].has(start_door.x)):
					$Hallway.set_cell(Vector2i(i, midpoint - 2), 1, Vector2i(1, 2))
					$Hallway.set_cell(Vector2i(i, midpoint - 3), 1, Vector2i(1, 1))
				if (![i, i+1, i-1].has(end_door.x)): $Hallway.set_cell(Vector2i(i, midpoint + 2), 1, Vector2i(5, 2), TileTransform.ROTATE_90)
			
			#CornerWalls
			$Hallway.set_cell(Vector2i(end_door.x -2, midpoint - 3), 1, Vector2i(0, 2),TileTransform.ROTATE_180)
			$Hallway.set_cell(Vector2i(end_door.x -2, midpoint - 2), 1, Vector2i(0, 2),TileTransform.ROTATE_180)
			
			$Hallway.set_cell(Vector2i(start_door.x +2, midpoint + 2), 1, Vector2i(0, 2))
