extends CharacterBody2D

class_name Enemy

@export var health: float = 2.0
@export var movement_speed: float = 75.0
@export var path_update_frame_count: int = 30
@export var hurt_color: Color = Color(1.2, 1.2, 1.2, 1.0)
@export var hurt_light_duration: float = 0.10

@onready var player: Player = get_tree().current_scene.get_node("Player")
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

signal enemy_died

var current_path_update_point: float
var timer: Timer
# Called when the node enters the scene tree for the first time.
func _ready():
	current_path_update_point = 0
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.autostart = false
	timer.wait_time = hurt_light_duration
	timer.timeout.connect(func(): animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0))
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_nav_target():
	navigation_agent.target_position = player.global_position

func _physics_process(delta):
	
	var direction = to_local(navigation_agent.get_next_path_position()).normalized()
	velocity = direction * movement_speed
	move_and_slide()
	current_path_update_point += 1
	if current_path_update_point >= path_update_frame_count:
		current_path_update_point = 0
		set_nav_target()
	

func damage(damageAmount):
	health -= damageAmount
	if health <= 0:
		if health < 0:
			print("bug")
		enemy_died.emit()
		queue_free()
		return
	animated_sprite.modulate = hurt_color
	timer.start()
