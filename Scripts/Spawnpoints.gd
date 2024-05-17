extends Node2D
class_name Spawnpoints

@export var level_data: LevelData
@export var spawner_step: float = 0.5
@export var power_up_chance: float = 0.05

var enemy_dict = {
	Enums.EnemyType.REGULAR: { 
		"scene": preload("res://Objects/enemy.tscn"),
		"group_i": 0
		},
	Enums.EnemyType.FLYING: {
		"scene": preload("res://Objects/FlyingEnemy.tscn"),
		"group_i": 1
		},
	Enums.EnemyType.FAST: {
		"scene": preload("res://Objects/fastEnemy.tscn"),
		"group_i": 0
		},
	Enums.EnemyType.SLOW: {
		"scene": preload("res://Objects/slowEnemy.tscn"),
		"group_i": 0
		}
	}
var power_up_dict = {
	Enums.PowerUp.HEALTH: {
		"scene": preload("res://Objects/health_power_up.tscn"),
		"weight": 0.3
		},
	Enums.PowerUp.SHOOT_SPEED: {
		"scene": preload("res://Objects/shoot_speed_power_up.tscn"),
		"weight": 0.3
		},
	Enums.PowerUp.SHOOT_8: {
		"scene": preload("res://Objects/8_shot_power_up.tscn"),
		"weight": 0.5
		}
} 

@onready var end_timer = $EndTimer
@onready var start_timer = $StartTimer
@onready var hud = $"../HUD"


var spawnPoints: Array
var waves: Array[WaveData]
var curr_wave: WaveData
var wave_ended: bool = false
var enemy_count: int = 0
var level_dur: float = 0
var curr_wave_start_time:float = 0
var level_completion_perc:float = 0
var curr_enemies = []

var power_ups = []
var power_up_weights = []

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#spawnPoints = find_children(".*", "Marker2D")
	var children = get_children()
	spawnPoints = Array() as Array[Array]
	for child in children:
		var markers: Array = Array()
		if child is Node2D:
			find_children_recursively(child, markers)
			spawnPoints.push_back(markers)
		for marker in markers:
			if marker.has_signal("spawned_enemy"):
				marker.spawned_enemy.connect(on_enemy_spawned)
				marker.enemy_died.connect(on_enemy_died)
	
	for waveData in level_data.waves:
		waves.push_back(waveData)
		level_dur += waveData.duration
	
	
	end_timer.timeout.connect(func(): start_wave())
	start_timer.timeout.connect(func(): wave_ended = true)
	
	var curr_weight = 0.0

	for key in power_up_dict:
		curr_weight += power_up_dict[key]["weight"]
		power_ups.append(key)
		power_up_weights.append(curr_weight)
	print(power_up_weights)
	
	start_wave()
	return
	
func on_enemy_spawned(enemy):
	enemy_count += 1
	curr_enemies.push_front(enemy)

func on_enemy_died(enemy):
	enemy_count -= 1
	curr_enemies.erase(enemy)
	
	if randf_range(0.0, 1.0) < power_up_chance:
		var rand = randf_range(0.0, 1.0)
		var selected_power = null
		for i in range(len(power_ups)):
			if rand <= power_up_weights[i]:
				selected_power = power_ups[i]
				break
		if selected_power != null:
			var power_up: PowerUp = power_up_dict[selected_power]["scene"].instantiate()
			get_parent().call_deferred("add_child", power_up)
			power_up.global_position = enemy.global_position
	

var next_wave_queued = false
func _process(delta):
	if (! wave_ended):
		level_completion_perc += delta
		hud.set_level_completed_duration(level_completion_perc/level_dur)
	elif (enemy_count <= 0 and ! next_wave_queued):
		end_wave()
	return

func restart_wave():
	clear_curr_enemies()
	start_wave()

func clear_curr_enemies():
	for group in spawnPoints:
		for spawner in group:
			spawner.stop_timers()
	for enemy in curr_enemies:
		enemy.queue_free()

func start_wave():
	level_completion_perc = curr_wave_start_time
	enemy_count = 0
	curr_enemies = []
	curr_wave = waves[0]
	wave_ended = false
	next_wave_queued = false
	
	var spawner_datas = intialize_spawner_datas()
	generate_random_spawner_data(spawner_datas)
	
	set_spawner_datas(spawner_datas)
	
	start_timer.wait_time = curr_wave.duration
	start_timer.start()
	
	print("start_wave")
	return
	
func end_wave():
	next_wave_queued = true
	curr_wave_start_time += curr_wave.duration 
	print("end_wave")
	waves.pop_front()
	if len(waves) > 0:
		end_timer.wait_time = curr_wave.break_after
		end_timer.start()
	else:
		hud.game_end(true)

func generate_random_spawner_data(spawner_datas):
	for wave_enemy_data in curr_wave.enemies:
		var group_i = enemy_dict[wave_enemy_data.enemy]["group_i"]
		var enemy_scene = enemy_dict[wave_enemy_data.enemy]["scene"]
		for i in range(wave_enemy_data.enemy_count):
			var spawner_i = randi_range(0, len(spawnPoints[group_i]) - 1)
			var time = snappedf(
				randf_range(
				curr_wave.duration * wave_enemy_data.time_start_percent,
				curr_wave.duration * wave_enemy_data.time_end_percent
				), spawner_step)
			var spawner_data: SpawnerData = SpawnerData.new()
			spawner_data.enemy = enemy_scene
			spawner_data.time = time
			spawner_datas[group_i][spawner_i].push_back(spawner_data)
			
	for groups in spawner_datas:
		for spawner_data in groups:
			spawner_data.sort_custom(sort_spawn_data)
	
	for group in spawner_datas: # group - Array<Array<SpawnerData>>
		for spawner_datas_i in range(len(group)):
			var prev_time = -1
			for spawner_data_j in range(len(group[spawner_datas_i]) - 1, -1, -1):
				var curr_time = group[spawner_datas_i][spawner_data_j].time
				if curr_time == prev_time:
					reposition_duplicates(group, spawner_datas_i, group[spawner_datas_i].pop_at(spawner_data_j))
				prev_time = curr_time
				
	return
	
func reposition_duplicates(group, spawner_i , respositioned_el):
	var indexes = []
	for i in range(spawner_i, len(group)):
		indexes.append(i)
	for i in range(0, spawner_i):
		indexes.append(i)
	var replaced = false
	while true:
		var time1 = respositioned_el.time
		for i in indexes:
			if replaced:
				break
			for j in range(len(group[i]) + 1):
				if j == len(group[i]) or group[i][j].time > time1:
					group[i].insert(j, respositioned_el)
					replaced = true
					break
				if group[i][j].time == time1:
					break
		if replaced: 
			break
		respositioned_el.time += spawner_step
		if respositioned_el.time > curr_wave.duration:
			respositioned_el.time = 0.0
	
	return

func sort_spawn_data(a:SpawnerData, b:SpawnerData):
	# return true if b is after a
	if a.time < b.time:
		return true
	return false

func intialize_spawner_datas():
	var spawner_datas = []
	for spawn_group in spawnPoints:
		var group_data = []
		spawner_datas.push_back(group_data)
		for spawner in spawn_group:
			group_data.push_back([] as Array[SpawnerData])
	return spawner_datas

func set_spawner_datas(spawner_datas):
	for i in range(len(spawnPoints)):
		for j in range(len(spawnPoints[i])):
			if spawnPoints[i][j].has_method("setup"):
				#print(len(spawner_datas[i][j]))
				spawnPoints[i][j].setup(spawner_datas[i][j])
	

func find_children_recursively(node: Node2D, arr: Array):
	if node is Spawner:
		arr.push_back(node)
		return
	for child in node.get_children():
		if child is Node2D:
			find_children_recursively(child, arr)

	
class SpawnerData:
	var enemy: PackedScene
	var time: float
	
