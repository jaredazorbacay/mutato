extends Node

const card_scene =  preload("res://scenes/UI/mutation_cards.tscn")
const MUTATIONS = [0, 1, 2]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func trigger_powerup():
	var card = card_scene.instantiate()
	for node in card.get_children():
		node.mutation_id = MUTATIONS.pick_random()
	add_child(card)
	
	card.position = $GameNode/Player/Camera2D.global_position
	card.z_index = 100
	
	$GameNode.set_process_mode(ProcessMode.PROCESS_MODE_DISABLED)
