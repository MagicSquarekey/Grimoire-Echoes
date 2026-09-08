## WaveManager - 波次管理器（单例）
## 管理无限波次模式的敌人生成和波次状态
extends Node

# 波次状态常量
const PREPARING = 0
const SPAWNING = 1
const FIGHTING = 2
const BOSS_FIGHT = 3
const WAVE_COMPLETE = 4
const MILESTONE = 5

# 当前状态
var current_wave = 0
var wave_state = PREPARING
var wave_timer = 0.0
var spawn_timer = 0.0
var enemies_alive = 0
var enemies_to_spawn = 0

# 波次配置
var preparation_time = 5.0
var wave_duration = 30.0

# Boss波次配置
var boss_wave_interval = 20
var mini_boss_interval = 5

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)

## 重置波次状态（新游戏或继续游戏时调用）
func reset() -> void:
	current_wave = 0
	wave_state = PREPARING
	wave_timer = 0.0
	spawn_timer = 0.0
	enemies_alive = 0
	enemies_to_spawn = 0

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	match wave_state:
		PREPARING:
			_process_preparing(delta)
		SPAWNING:
			_process_spawning(delta)
		FIGHTING:
			_process_fighting(delta)
		BOSS_FIGHT:
			_process_boss_fight(delta)
		WAVE_COMPLETE:
			_process_wave_complete(delta)
		MILESTONE:
			_process_milestone(delta)

## 开始下一波（供GameController调用）
func start_next_wave() -> void:
	start_wave()

## 开始新波次
func start_wave() -> void:
	current_wave += 1
	wave_state = PREPARING
	wave_timer = preparation_time
	
	EventBus.wave_started.emit(current_wave)
	
	if current_wave % boss_wave_interval == 0:
		print("警告：大Boss波次！")
	elif current_wave % mini_boss_interval == 0:
		print("警告：小Boss波次！")

## 准备阶段处理
func _process_preparing(delta: float) -> void:
	wave_timer -= delta * GameManager.game_speed
	if wave_timer <= 0:
		wave_state = SPAWNING
		enemies_to_spawn = _calculate_enemy_count()
		spawn_timer = 0.0

## 生成阶段处理
func _process_spawning(delta: float) -> void:
	spawn_timer -= delta * GameManager.game_speed
	if spawn_timer <= 0 and enemies_to_spawn > 0:
		_spawn_enemy()
		enemies_to_spawn -= 1
		spawn_timer = _get_spawn_interval()
	
	if enemies_to_spawn <= 0:
		wave_state = FIGHTING

## 战斗阶段处理
func _process_fighting(delta: float) -> void:
	if enemies_alive <= 0:
		wave_state = WAVE_COMPLETE

## Boss战处理
func _process_boss_fight(delta: float) -> void:
	if enemies_alive <= 0:
		wave_state = WAVE_COMPLETE

## 波次完成处理
func _process_wave_complete(delta: float) -> void:
	EventBus.wave_completed.emit(current_wave)
	if current_wave % 10 == 0:
		wave_state = MILESTONE
	else:
		start_wave()

## 里程碑处理
func _process_milestone(delta: float) -> void:
	# 里程碑只停留一帧，显示提示后立即开始下一波
	start_wave()

## 计算当前波次敌人数量
func _calculate_enemy_count() -> int:
	var base_count = 10
	var wave_bonus = current_wave * 2
	return base_count + wave_bonus

## 获取生成间隔
func _get_spawn_interval() -> float:
	return 0.5

## 生成敌人
func _spawn_enemy() -> void:
	var enemy_scene = preload("res://scenes/enemies/shadow_servant.tscn")
	var enemy = enemy_scene.instantiate()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var angle = randf() * TAU
		var distance = randf_range(400, 600)
		enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	else:
		enemy.global_position = Vector2(960, 540)
	
	var difficulty = 1.0 + current_wave * 0.1
	if enemy.has_method("set_difficulty"):
		enemy.set_difficulty(difficulty)
	
	var scene_root = get_tree().current_scene
	if scene_root and is_instance_valid(scene_root):
		# 记住目标位置，add_child之后再赋值(否则丢失出生在0,0)
		var spawn_pos = enemy.global_position
		scene_root.add_child(enemy)
		enemy.global_position = spawn_pos
		enemies_alive += 1
	else:
		enemy.queue_free()

## 敌人被击杀回调
func _on_enemy_killed(enemy_type: String, exp_reward: int, gold_reward: int) -> void:
	enemies_alive -= 1
	GameManager.add_kill()

## 获取难度系数
func get_difficulty_multiplier() -> float:
	return 1.0 + current_wave * 0.1

## 获取当前波次信息
func get_wave_info() -> Dictionary:
	return {
		"wave": current_wave,
		"state": wave_state,
		"enemies_alive": enemies_alive,
		"difficulty": get_difficulty_multiplier()
	}
