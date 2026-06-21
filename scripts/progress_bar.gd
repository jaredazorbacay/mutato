extends ProgressBar
 
@onready var player = $/root/Main/GameNode/Player

func _ready():
	player.healthChanged.connect(update)
	update()

func update():
	max_value = player.max_health
	value = player.health
	
	$Label.text = str(player.health) + "/" + str(player.max_health)
