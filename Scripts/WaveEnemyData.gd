extends Resource

class_name WaveEnemyData

@export var enemy: Enums.EnemyType
@export var enemy_count: int = 30
@export_range(0.0, 1.0, 0.1) var time_start_percent: float = 0.0
@export_range(0.0, 1.0, 0.1) var time_end_percent: float = 1.0

#func _init(p_enemy = Enums.EnemyType.REGULAR, p_enemy_count = 10, p_group_index = 0):
#	enemy = p_enemy
#	enemy_count = p_enemy_count
#	group_index = p_group_index
