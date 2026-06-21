extends ProgressBar

@onready var player = $/root/Main/GameNode/Player


func _ready():
	player.shieldChanged.connect(update)
	visible = false

func update():
	visible = true
	max_value = player.max_shield
	value = player.shield_hits_remaining
	$Label.text = str(int(value)) + "/" + str(int(max_value))
