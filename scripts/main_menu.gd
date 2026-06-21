extends Node2D



func _ready() -> void:
	AudioController.play_mbgm()
	$CanvasLayer2.show()
	$CanvasLayer2/AnimationPlayer.play("fade_in")

func _on_start_pressed() -> void:
	AudioController.stop_mbgm()
	AudioController.play_bgm()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	


func _on_quit_pressed() -> void:
	get_tree().quit()
