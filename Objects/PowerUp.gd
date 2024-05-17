extends Area2D

class_name PowerUp

var power_up_callback: Callable
var cleanup_callback: Callable

@onready var blinking_timer = $BlinkingTimer
@onready var delete_timer = $DeleteTimer
@onready var change_blink_bool_timer = $ChangeBlinkBoolTimer

@export var blink_color: Color = Color(1.0, 1.0, 1.0, 0.5)
@export var delete_dur: float = 6.0
@export var blink_start_dur: float = 4.0
@export var blink_amount = 4

@export var power_up_duration: float = 5.0

var one_blink_time:float = 0
var blinking = false
var falling = true
var curr_blink_time = 0
var def_modulate = Color(1.0, 1.0, 1.0, 1.0)
var player_used = false


func _ready():
	blinking_timer.wait_time = blink_start_dur
	blinking_timer.start()
	delete_timer.wait_time = delete_dur
	delete_timer.start()
	change_blink_bool_timer.wait_time = (delete_dur - blink_start_dur) / blink_amount
	one_blink_time = (delete_dur - blink_start_dur) / blink_amount
	return


func _process(delta):
	if blinking:
		curr_blink_time += delta
		if falling:
			modulate = lerp(def_modulate, blink_color, curr_blink_time / one_blink_time)
		else:
			modulate = lerp(blink_color, def_modulate, curr_blink_time / one_blink_time)
			
	pass

func _on_body_entered(body):
	'''print("powerup")
	if callback.is_valid() and cleanup_callback.is_valid():
		var player:Player = body as Player
		callback.call(player)
		var timer: Timer = Timer.new()
		player.add_child(timer)
		timer.one_shot = true
		timer.autostart = true
		timer.wait_time = power_up_duration
		var on_cleanup_cb: Callable = on_cleanup
		on_cleanup_cb.bind(player, timer)
		timer.timeout.connect(on_cleanup_cb)
		queue_free()'''
	return

func on_apply_power_up(player: Player):
	if power_up_callback.is_valid():
		power_up_callback.call(player)
		player_entered()

func on_cleanup(player: Player, timer: Timer):
	if cleanup_callback.is_valid():
		cleanup_callback.call(player)
		timer.queue_free()


func _on_delete_timer_timeout():
	if !player_used:
		queue_free()


func _on_blinking_timer_timeout():
	blinking = true
	change_blink_bool_timer.start()


func _on_change_blink_bool_timer_timeout():
	falling = !falling
	curr_blink_time = 0

func player_entered():
	player_used = true
	hide()
	set_process(false)
	set_physics_process(false)
