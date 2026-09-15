## WaveManager - 波次管理器（单例）
## 管理无限波次模式的波次状态机；敌人构成/间隔由 EnemySpawner.build_wave_plan 提供，
## 实际生成执行委托给场景中的 EnemySpawner（无生成器时回退旧路径）
extends Node

# 波次状态常量
const PREPARING = 0
const SPAWNING = 1
const FIGHTING = 2
const BOSS_FIGHT = 3
const WAVE_COMPLETE = 4
const MILESTONE = 5
const SHOP_BREAK = 6  # 波次间隙：商店营业中，等待玩家购买/跳过后开下一波

# 当前状态
var current_wave = 0
var wave_state = PREPARING
var wave_timer = 0.0
var spawn_timer = 0.0
var enemies_alive = 0
var enemies_to_spawn = 0

# 波次配置
var preparation_time = 2.5
var wave_duration = 30.0

# Boss波次配置
var boss_wave_interval = 20
var mini_boss_interval = 5

# 当前波次计划（EnemySpawner.build_wave_plan 产物）
var current_plan = {}

# 性能红线：同屏存活敌人软上限，达到后暂停出怪（分帧节流），低于后恢复
var spawn_soft_cap = 80

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.shop_closed.connect(_on_shop_closed)

## 重置波次状态（新游戏或继续游戏时调用）
func reset() -> void:
	current_wave = 0
	wave_state = PREPARING
	wave_timer = 0.0
	spawn_timer = 0.0
	enemies_alive = 0
	enemies_to_spawn = 0
	current_plan = {}

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
		SHOP_BREAK:
			pass  # 商店营业中：树已暂停，等待 EventBus.shop_closed 触发下一波

## 开始下一波（供GameController调用）
func start_next_wave() -> void:
	start_wave()

## 开始新波次
func start_wave() -> void:
	current_wave += 1
	current_plan = EnemySpawner.build_wave_plan(current_wave)
	# 事件波标记（宝箱/祭坛/悬赏），GameController 与 EnemySpawner 读取
	current_plan["event"] = event_id_for_wave(current_wave, EnemySpawner.boss_rush_mode)
	wave_state = PREPARING
	wave_timer = preparation_time

	EventBus.wave_started.emit(current_wave)

## 事件波调度（纯函数：可在无场景树环境下测试）
## 标准模式第 3 波起，每逢 wave%5==3 触发，类型按 15 波轮换避免连在同一事件上
static func event_id_for_wave(wave: int, boss_rush: bool = false) -> String:
	if boss_rush or wave < 3:
		return ""
	match wave % 15:
		3: return "treasure"
		8: return "altar"
		13: return "bounty"
		_: return ""

## 该波是否为 Boss 波（每 5 波一只 Boss）
func is_boss_wave(wave: int) -> bool:
	return wave % mini_boss_interval == 0

## 准备阶段处理
func _process_preparing(delta: float) -> void:
	wave_timer -= delta * GameManager.game_speed
	if wave_timer <= 0:
		wave_state = SPAWNING
		enemies_to_spawn = _calculate_enemy_count()
		spawn_timer = 0.0
		var spawner = _find_spawner()
		if spawner:
			spawner.begin_wave(current_plan, get_difficulty_multiplier())

## 生成阶段处理
func _process_spawning(delta: float) -> void:
	# 性能红线：同屏存活达到软上限时暂停出怪，待玩家消化后再继续
	if enemies_alive >= spawn_soft_cap:
		return

	spawn_timer -= delta * GameManager.game_speed
	if spawn_timer <= 0 and enemies_to_spawn > 0:
		var batch = 0
		var spawner = _find_spawner()
		if spawner:
			batch = spawner.spawn_next_batch()
		else:
			_spawn_enemy()  # 回退路径：只生成基础近战
			batch = 1
		batch = maxi(batch, 1)  # 防呆：单批至少消耗1个配额
		enemies_to_spawn -= batch
		enemies_alive += batch
		# 整批（环形包抄/狼群包）按人数展开间隔，保持整体节奏
		spawn_timer = _get_spawn_interval() * batch

	if enemies_to_spawn <= 0:
		wave_state = BOSS_FIGHT if current_plan.get("is_boss", false) else FIGHTING

## 战斗阶段处理
func _process_fighting(delta: float) -> void:
	if enemies_alive <= 0:
		wave_state = WAVE_COMPLETE

## Boss战处理
func _process_boss_fight(delta: float) -> void:
	if enemies_alive <= 0:
		wave_state = WAVE_COMPLETE

## 波次完成处理：广播完成后进入商店间隙（买强化 / 直接跳过开下一波）
func _process_wave_complete(delta: float) -> void:
	EventBus.wave_completed.emit(current_wave)
	_enter_shop_break()

## 进入商店间隙：有商店则开门营业（show_shop 内部暂停游戏），
## 无商店环境（无 UI 测试等）直接推进下一波，不破坏原有时序
func _enter_shop_break() -> void:
	wave_state = SHOP_BREAK
	var shop = _find_shop()
	if shop and shop.has_method("show_shop"):
		shop.show_shop()
	else:
		start_wave()

## 商店关闭（购买完毕或跳过）→ 恢复并开始下一波
func _on_shop_closed() -> void:
	if wave_state == SHOP_BREAK:
		start_wave()

## 查找场景中的商店（shop.gd 加入 shop_ui 组）
func _find_shop() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group("shop_ui")

## 查找场景中的生成器（EnemySpawner 在 _ready 中加入 enemy_spawner 组）
func _find_spawner() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group("enemy_spawner")

## 计算当前波次敌人数量（来自波次计划；波次变化时重建计划）
func _calculate_enemy_count() -> int:
	if current_plan.is_empty() or current_plan.get("wave", -1) != current_wave:
		current_plan = EnemySpawner.build_wave_plan(current_wave)
	return current_plan.get("total", 0)

## 获取生成间隔（来自波次计划）
func _get_spawn_interval() -> float:
	if current_plan.is_empty() or current_plan.get("wave", -1) != current_wave:
		current_plan = EnemySpawner.build_wave_plan(current_wave)
	return current_plan.get("spawn_interval", 0.5)

## 生成敌人（回退路径：找不到 EnemySpawner 时仅生成基础近战）
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
		FxLib.spawn_portal(enemy, spawn_pos)
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
		"difficulty": get_difficulty_multiplier(),
		"is_boss": current_plan.get("is_boss", false)
	}
