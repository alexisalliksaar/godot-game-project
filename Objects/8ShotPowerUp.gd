extends Node2D

@onready var power_up: PowerUp = $".."

func _ready():
	power_up.power_up_callback = apply
	power_up.cleanup_callback = cleanup


func apply(player: Player):
	#print(player.proj_delay)
	player.set_8_shot_true(self)

func cleanup(player:Player):
	#print(player.proj_delay)
	player.set_8_shot_false(self)
	
