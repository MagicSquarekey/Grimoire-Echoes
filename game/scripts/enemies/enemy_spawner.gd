## EnemySpawner - 敌人生成器
extends Node

# 敌人场景预加载
var enemy_scenes = {
	"shadow_servant": preload("res://scenes/enemies/shadow_servant.tscn"),
	"skeleton_mage": preload("res://scenes/enemies/skeleton_mage.tscn"),
	"swarm_bug": preload("res://scenes/enemies/swarm_bug.tscn")
}

# 敌人ID映射（用于动态生成）
var enemy_id_map = {
	"shadow_servant": "E1",
	"skeleton_mage": "E5",
	"swarm_bug": "E11"
}

# 波次配置
var wave_configs = []

func _ready() -> void:
	_init_wave_configs()

## 初始化波次配置
func _init_wave_configs() -> void:
	# 波次1-5: 教学波
	for i in range(1, 6):
		wave_configs.append({
			"wave": i,
			"enemies": [
				{"type": "shadow_servant", "count": 8 + i * 2}
			],
			"spawn_interval": 0.5
		})
	
	# 波次6-10: 成长波
	for i in range(6, 11):
		wave_configs.append({
			"wave": i,
			"enemies": [
				{"type": "shadow_servant", "count": 15 + i * 2},
				{"type": "skeleton_mage", "count": 3}
			],
			"spawn_interval": 0.4
		})
	
	# 波次11-15: 挑战波
	for i in range(11, 16):
		wave_configs.append({
			"wave": i,
			"enemies": [
				{"type": "shadow_servant", "count": 20 + i * 2},
				{"type": "skeleton_mage", "count": 5},
				{"type": "swarm_bug", "count": 10}
			],
			"spawn_interval": 0.3
		})

## 根据波次获取配置
func get_wave_config(wave: int) -> Dictionary:
	if wave <= wave_configs.size():
		return wave_configs[wave - 1]
	
	# 无限模式：动态生成配置
	return _generate_infinite_wave_config(wave)

## 生成无限波次配置
func _generate_infinite_wave_config(wave: int) -> Dictionary:
	var base_count = 20 + wave * 3
	var enemy_types = ["shadow_servant", "skeleton_mage", "swarm_bug"]
	
	return {
		"wave": wave,
		"enemies": [
			{"type": "shadow_servant", "count": int(base_count * 0.5)},
			{"type": "skeleton_mage", "count": int(base_count * 0.3)},
			{"type": "swarm_bug", "count": int(base_count * 0.2)}
		],
		"spawn_interval": max(0.2, 0.5 - wave * 0.01)
	}

## 生成一波敌人
func spawn_wave(wave: int) -> Array[EnemyBase]:
	var config = get_wave_config(wave)
	var spawned_enemies: Array[EnemyBase] = []
	var difficulty = 1.0 + wave * 0.1  # 难度系数
	
	for enemy_config in config.get("enemies", []):
		var enemy_type = enemy_config.get("type", "")
		var count = enemy_config.get("count", 0)
		
		for i in count:
			var enemy = _spawn_enemy(enemy_type, difficulty)
			if enemy:
				spawned_enemies.append(enemy)
	
	return spawned_enemies

## 生成单个敌人
func _spawn_enemy(enemy_type: String, difficulty: float) -> EnemyBase:
	# 首先尝试使用预加载场景
	if enemy_scenes.has(enemy_type):
		var scene = enemy_scenes[enemy_type]
		var enemy = scene.instantiate() as EnemyBase
		
		if enemy:
			# 设置难度
			enemy.set_difficulty(difficulty)
			
			# 添加到场景（先记位置，add后赋值避免丢失）
			var spawn_pos = _get_random_spawn_position()
			get_tree().current_scene.add_child(enemy)
			enemy.global_position = spawn_pos
		
		return enemy
	
	# 如果没有预加载场景，使用敌人生成器动态创建
	var enemy_id = enemy_id_map.get(enemy_type, "")
	if enemy_id == "":
		# 尝试直接使用enemy_type作为enemy_id
		enemy_id = enemy_type
	
	var resource = EnemyGenerator.create_enemy_resource(enemy_id)
	if resource == null:
		push_error("无法创建敌人资源: " + enemy_type)
		return null
	
	# 创建敌人实例（这里需要实际的敌人场景，暂时返回null）
	# 在实际项目中，应该有一个通用的敌人场景，然后根据资源配置
	push_warning("动态创建敌人尚未实现: " + enemy_type)
	return null

## 开始下一波
func start_next_wave() -> void:
	WaveManager.start_wave()

## 获取随机生成位置
func _get_random_spawn_position() -> Vector2:
	# 在玩家周围400-600像素范围内生成
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return Vector2(960, 540)  # 屏幕中心
	
	var angle = randf() * TAU
	var distance = randf_range(400, 600)
	
	return player.global_position + Vector2(cos(angle), sin(angle)) * distance
