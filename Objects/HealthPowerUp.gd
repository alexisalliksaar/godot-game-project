extends Node2D

@onready var power_up: PowerUp = $".."

func _ready():
	power_up.power_up_callback = apply
	#power_up.cleanup_callback = cleanup


func apply(player: Player):
	
	player.add_life()

	
