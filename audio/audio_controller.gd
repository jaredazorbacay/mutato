extends Node

@export var mute: bool = false


func _ready() -> void:
	if not mute:
		$MBGM.play() 
		pass

func play_bgm() -> void:
	if not mute:
		$BGM.play() 

func play_mbgm() -> void:
	if not mute:
		$MBGM.play()

func stop_mbgm() -> void:
	if not mute:
		$MBGM.stop()

func play_whip():
	if not mute:
		$WhipSound.play()

func play_hit():
	if not mute:
		$HitSound.play()

func play_death():
	if not mute:
		$DeathSound.play()
