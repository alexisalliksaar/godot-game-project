extends CanvasLayer
class_name UiController

@onready var level_duration_completed = $Control/LevelDuration/LevelDurationCompleted
@onready var heart_container = $Control/PanelContainer/GridContainer
@onready var end_panel = $Control/EndPanel
@onready var player_feedback = $Control/EndPanel/PlayerFeedback
@onready var end_button = $Control/EndPanel/EndButton
@export_file("*.tscn") var next_scene
@onready var player_hurt_flash = $Control/PlayerHurtFlash
@export var hurt_color: Color = Color(1.0, 0.0, 0.0, 0.2)
@export var hurt_duration = 0.15
var default_hurt_color
var heart_ui_scene = preload("res://Objects/heart_ui.tscn")

var win: bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	set_level_completed_duration(0.0)
	end_panel.visible = false
	player_hurt_flash.visible = false
	default_hurt_color = Color(hurt_color.r, hurt_color.g, hurt_color.b, 0.0)
	player_hurt_flash.color = default_hurt_color
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if hurt_timer < hurt_duration:
		hurt_timer += delta
		player_hurt_flash.color = lerp(hurt_color, default_hurt_color, hurt_timer / hurt_duration)
	else:
		player_hurt_flash.visible = false
	return

func game_end(win1: bool):
	win = win1
	if win:
		player_feedback.text = "Level Complete"
		end_button.text = "Next Level"
	else:
		player_feedback.text = "Level Failed"
		end_button.text = "Restart Level"
	end_panel.visible = true

func remove_life_ui():
	var hearts = heart_container.get_children()
	if len(hearts) > 0:
		var removed = hearts[len(hearts)-1]
		heart_container.remove_child(removed)
		removed.queue_free()
	player_damaged()

func add_life_ui():
	var heartScene = heart_ui_scene.instantiate()
	heart_container.add_child(heartScene)

func set_level_completed_duration(perc:float):
	level_duration_completed.anchor_right = perc


func _on_end_button_pressed():
	if win:
		var scene = load(next_scene)
		get_tree().change_scene_to_packed(scene)
	else:
		get_tree().reload_current_scene()
	return

var hurt_timer = 0
func player_damaged():
	player_hurt_flash.visible = true
	player_hurt_flash.color = hurt_color
	hurt_timer = 0
	
