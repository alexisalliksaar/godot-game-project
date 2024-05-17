extends Marker2D

class_name Spawner

var timer: Timer
var spawner_data: Array[Spawnpoints.SpawnerData]
signal spawned_enemy(enemy)
signal enemy_died(enemy)

func _ready():
	pass # Replace with function body.

func spawn_enemy():
	var curr_data: Spawnpoints.SpawnerData = spawner_data.pop_front()
	var enemy: Enemy = curr_data.enemy.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = global_position
	enemy.enemy_died.connect(func(): enemy_died.emit(enemy), ConnectFlags.CONNECT_ONE_SHOT)
	reset_timer(curr_data.time)
	spawned_enemy.emit(enemy)
	return
	
func reset_timer(previous = 0.0):
	if len(spawner_data) > 0:
		var waitTime = spawner_data[0].time - previous
		if waitTime <= 0:
			waitTime = 0.01
		timer.wait_time = waitTime
		timer.start()
	return
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func setup(p_spawner_data: Array[Spawnpoints.SpawnerData]):
	if timer == null:
		timer = Timer.new()
		add_child(timer)
		timer.one_shot = true
		timer.autostart = false
		timer.timeout.connect(spawn_enemy)
	else:
		timer.stop()
	
	spawner_data = p_spawner_data
	spawner_data.sort_custom(sort_spawn_data)
	reset_timer()

func stop_timers():
	if timer != null:
		timer.stop()

func sort_spawn_data(a:Spawnpoints.SpawnerData, b:Spawnpoints.SpawnerData):
	# return true if b is after a
	if a.time < b.time:
		return true
	return false


	
	
