extends Node

@export var mute: bool = false


func _ready() -> void:
	if not mute:
		$BGM.play() 
		pass


#func _process(delta: float) -> void:
	#pass
	
func play_whip():
	if not mute:
		$WhipSound.play()

func play_hit():
	if not mute:
		$HitSound.play()

func play_death():
	if not mute:
		$DeathSound.play()
