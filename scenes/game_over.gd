extends Node2D

func _ready() -> void:
	$CanvasLayer/Panel/VBoxContainer/Label.show()
	$CanvasLayer/Panel/VBoxContainer/Label/AnimationPlayer.play("died")
	get_tree().paused = false

func _on_retry_pressed() -> void:
	AudioController.stop_bgm()
	AudioController.play_mbgm()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
