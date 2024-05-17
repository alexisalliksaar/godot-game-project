extends CharacterBody2D

class_name Player

enum AnimState {IDLE_FRONT, IDLE_BACK, WALK_FRONT, WALK_BACK}
const SPEED = 110.0

var anim_state: AnimState = AnimState.IDLE_FRONT
var prev_anim_state: AnimState = AnimState.IDLE_BACK

@export var proj_delay: float = 1.0
@export var proj_damage: float = 1.0

@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var signal_spawner = $SignalSpawner
@onready var hud = $"../HUD"
@onready var spawnpoints = $"../Spawnpoints"
@onready var player_start_position = $"../PlayerStartPosition"

var health: int = 3
var timer: Timer
var can_shoot: bool = true
var projectile_scene = preload("res://Objects/projectile.tscn") 
var shoot_8: bool = false
var all_shoot_dirs = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, -1), Vector2(0, 1),
 Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]

func _ready():
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.autostart = false
	timer.wait_time = proj_delay
	timer.timeout.connect(func(): can_shoot = true)
	
	for i in range(len(all_shoot_dirs)):
		all_shoot_dirs[i] = all_shoot_dirs[i].normalized()

#func shoot_timer_timeout():
#	can_shoot = true

func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction_x = Input.get_axis("move_input_left", "move_input_right")
	var direction_y = Input.get_axis("move_input_up", "move_input_down")
	if direction_x != 0 or direction_y != 0:
		var dir = Vector2(direction_x, direction_y).normalized()
		direction_x = dir.x
		direction_y = dir.y
	
	if direction_x:
		velocity.x = direction_x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if direction_y:
		velocity.y = direction_y * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	solve_anim_state(velocity.x, velocity.y)
	animate(velocity.x)
	
	move_and_slide()

#func _unhandled_input(event):
#	if event is InputEventKey:
#		if event.is_action()
func _process(delta):
	if can_shoot:
		var shoot_x = Input.get_axis("shoot_input_left", "shoot_input_right")
		var shoot_y = Input.get_axis("shoot_input_up", "shoot_input_down")
		if shoot_x != 0 or shoot_y != 0:
			if shoot_8:
				for dir in all_shoot_dirs:
					instantiate_projectile(dir)
			else:
				var dir = Vector2(shoot_x, shoot_y).normalized()
				instantiate_projectile(dir)
			
			timer.start()
			can_shoot = false
			
	return

func instantiate_projectile(dir: Vector2):
	var projectile: Projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = signal_spawner.global_position
	projectile.setup(dir, proj_damage)
	return

func solve_anim_state(vel_x, vel_y):
	if vel_x == 0 and vel_y == 0:
		if anim_state == AnimState.WALK_BACK:
			anim_state = AnimState.IDLE_BACK
		elif anim_state == AnimState.WALK_FRONT:
			anim_state = AnimState.IDLE_FRONT
		return
	if vel_y < 0:
		anim_state = AnimState.WALK_BACK
	#elif vel_y > 0:
	#	anim_state = AnimState.WALK_FRONT
	else:
		anim_state = AnimState.WALK_FRONT

func animate(vel_x):
	if anim_state != prev_anim_state:
		prev_anim_state = anim_state
		match anim_state:
			AnimState.IDLE_FRONT: 
				player_sprite.play("Idle_front")
			AnimState.IDLE_BACK: 
				player_sprite.play("Idle_back")
			AnimState.WALK_FRONT: 
				player_sprite.play("Walk_front")
			AnimState.WALK_BACK: 
				player_sprite.play("Walk_back")
			
	if vel_x > 0:
		player_sprite.flip_h = true
	elif vel_x < 0:
		player_sprite.flip_h = false
	


func _on_area_2d_body_entered(body):
	if body.has_method("damage"):
		health -= 1
		hud.remove_life_ui()
		if health > 0:
			spawnpoints.restart_wave()
			global_position = player_start_position.global_position
		else:
			spawnpoints.clear_curr_enemies()
			spawnpoints.set_process(false)
			hud.game_end(false)
			queue_free()
			
		
		
	pass # Replace with function body.


func _on_area_2d_area_entered(area):
	if area.has_method("on_apply_power_up"):
		area = area as PowerUp
		if area.player_used:
			return
		area.on_apply_power_up(self)
		if area.power_up_duration > 0:
			var power_up_timer: Timer = Timer.new()
			add_child(power_up_timer)
			power_up_timer.one_shot = true
			power_up_timer.autostart = false
			power_up_timer.wait_time = area.power_up_duration
		
			power_up_timer.timeout.connect(on_power_up_cleanup.bind(power_up_timer, area))
			power_up_timer.start()
		else:
			area.queue_free()
		
func on_power_up_cleanup(timer1: Timer, area: PowerUp):
	area.cleanup_callback.call(self)
	timer1.queue_free()
	area.queue_free()
	
func set_proj_delay(value):
	proj_delay = value
	timer.wait_time = proj_delay

func add_life():
	health += 1
	hud.add_life_ui()

var shoot_8_lock
func set_8_shot_true(locker=null):
	shoot_8_lock = locker
	shoot_8 = true

func set_8_shot_false(key=null):
	if key != shoot_8_lock:
		return
	shoot_8 = false
