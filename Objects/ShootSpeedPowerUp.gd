extends Node2D

@onready var power_up: PowerUp = $".."
@export var fasterMultiplier = 3.0

func _ready():
	power_up.power_up_callback = apply
	power_up.cleanup_callback = cleanup


func apply(player: Player):
	#print(player.proj_delay)
	player.set_proj_delay(player.proj_delay / fasterMultiplier)

func cleanup(player:Player):
	#print(player.proj_delay)
	player.set_proj_delay(player.proj_delay * fasterMultiplier)
	
