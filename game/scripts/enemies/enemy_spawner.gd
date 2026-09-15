## EnemySpawner - 敌人生成器
## 职责：
##   1. 波次计划（build_wave_plan 静态纯函数：1-15 波脚本化 + 无限模式动态生成）
##   2. 执行生成：屏外环带出生点、虫群环形包抄、猎犬狼群包、兽人混编推进
##   3. 精英/Boss 标记（make_elite / make_boss 见 enemy_base.gd）
extends Node

class_name EnemySpawner

# 敌人场景预加载
var enemy_scenes = {
	"shadow_servant": preload("res://scenes/enemies/shadow_servant.tscn"),
	"skeleton_mage": preload("res://scenes/enemies/skeleton_mage.tscn"),
	"swarm_bug": preload("res://scenes/enemies/swarm_bug.tscn"),
	"orc_warrior": preload("res://scenes/enemies/orc_warrior.tscn"),
	"demon_hound": preload("res://scenes/enemies/demon_hound.tscn")
}

# 敌人ID映射（用于动态生成）
var enemy_id_map = {
	"shadow_servant": "E1",
	"skeleton_mage": "E5",
	"swarm_bug": "E11",
	"orc_warrior": "E20",
	"demon_hound": "E21"
}

# Boss 使用的场景与外观缩放
const BOSS_BASE_TYPE := "orc_warrior"
const BOSS_SCALE := 2.2

# 屏幕半尺寸（1920x1080），出生点位于屏外环带
const SCREEN_HALF := Vector2(960, 540)

# 当前波次的生成队列（begin_wave 时构建，spawn_next_batch 逐批消费）
var _spawn_queue: Array = []
var _difficulty := 1.0
var _elite_at: Dictionary = {}      # 扁平序号 -> 精英
var _bounty_at: Dictionary = {}     # 扁平序号 -> 悬赏目标（事件波）
var _flat_index := 0

# Boss 连战模式（GameController 开局时同步自 GameManager.game_mode；
# 用静态变量保证 build_wave_plan 在无场景树环境下也可测试）
static var boss_rush_mode := false

func _ready() -> void:
	add_to_group("enemy_spawner")

## ============================================================
## 波次计划（静态纯函数：可在无场景树环境下调用，单元测试依赖此特性）
## ============================================================

## 1-15 波脚本化曲线（压迫感设计）：
##   前 3 波缓冲期(10-16只)；第 4 波猎犬包+数量上台阶；第 5 波首个 Boss；
##   第 8 波兽人登场；间隔 0.5s → 0.2s 递减；总量约为旧配置 1.5 倍
static func _build_wave_table() -> Array:
	return [
		{"wave": 1, "spawn_interval": 0.50, "events": [
			{"type": "shadow_servant", "count": 10, "formation": "scatter"}]},
		{"wave": 2, "spawn_interval": 0.46, "events": [
			{"type": "shadow_servant", "count": 14, "formation": "scatter"}]},
		{"wave": 3, "spawn_interval": 0.42, "events": [
			{"type": "shadow_servant", "count": 10, "formation": "scatter"},
			{"type": "swarm_bug", "count": 6, "formation": "ring"}]},
		{"wave": 4, "spawn_interval": 0.40, "events": [
			{"type": "shadow_servant", "count": 16, "formation": "scatter"},
			{"type": "demon_hound", "count": 6, "formation": "pack"}]},
		{"wave": 5, "spawn_interval": 0.38, "is_boss": true, "events": [
			{"type": "shadow_servant", "count": 14, "formation": "scatter"},
			{"type": "demon_hound", "count": 5, "formation": "pack"},
			{"type": "boss", "count": 1, "formation": "single"}]},
		{"wave": 6, "spawn_interval": 0.36, "events": [
			{"type": "shadow_servant", "count": 20, "formation": "scatter"},
			{"type": "skeleton_mage", "count": 4, "formation": "scatter"},
			{"type": "swarm_bug", "count": 10, "formation": "ring"}]},
		{"wave": 7, "spawn_interval": 0.34, "events": [
			{"type": "shadow_servant", "count": 22, "formation": "scatter"},
			{"type": "skeleton_mage", "count": 5, "formation": "scatter"},
			{"type": "demon_hound", "count": 6, "formation": "pack"},
			{"type": "swarm_bug", "count": 8, "formation": "ring"}]},
		{"wave": 8, "spawn_interval": 0.31, "events": [
			{"type": "orc_warrior", "count": 3, "formation": "scatter"},
			{"type": "shadow_servant", "count": 24, "formation": "scatter"},
			{"type": "skeleton_mage", "count": 5, "formation": "scatter"},
			{"type": "swarm_bug", "count": 12, "formation": "ring"}]},
		{"wave": 9, "spawn_interval": 0.29, "events": [
			{"type": "orc_warrior", "count": 4, "formation": "scatter"},
			{"type": "shadow_servant", "count": 26, "formation": "scatter"},
			{"type": "skeleton_mage", "count": 6, "formation": "scatter"},
			{"type": "demon_hound", "count": 6, "formation": "pack"}]},
		{"wave": 10, "spawn_interval": 0.27, "is_boss": true, "events": [
			{"type": "orc_warrior", "count": 3, "formation": "scatter"},
			{"type": "shadow_servant", "count": 26, "formation": "scatter"},
			{"type": "skeleton_mage", "count": 6, "formation": "scatter"},
			{"type": "swarm_bug", "count": 12, "formation": "ring"},
			{"type": "boss", "count": 1, "formation": "single"}]},
		{"wave": 11, "spawn_interval": 0.25, "events": [
			{"type": "orc_warrior", "count": 5, "formation": "scatter"},
			{"type": "shadow_servant", "count": 30, "formation": "scatter"},
			{"type": "skeleton_mage", "count": 8, "formation": "scatter"},
			{"type": "demon_hound", "count": 8, "formation": "pack"},
			{"type": "swarm_bug", "count": 12, "formation": "ring"}]},
		{"wave": 12, "spawn_interval": 0.24, "events": [
			{"type": "orc_warrior", "count": 5, "formation": "scatter"},
			{"type": "shadow_servant", "count": 32, "formation": "scatter"},
			{"type": "skeleton_mage", "count": 9, "formation": "scatter"},
			{"type": "demon_hound", "count": 6, "formation": "pack"},
			{"type": "swarm_bug", "count": 14, "formation": "ring"}]},
		{"wave": 13, "spawn_interval": 0.23, "events": [
			{"type": "orc_warrior", "count": 6, "formation": "scatter"},
			{"type": "shadow_servant", "count": 34, "formation": "scatter"},
			{"type": "skeleton_mage", "count": 10, "formation": "scatter"},
			{"type": "demon_hound", "count": 8, "formation": "pack"},
			{"type": "swarm_bug", "count": 14, "formation": "ring"}]},
		{"wave": 14, "spawn_interval": 0.22, "events": [
			{"type": "orc_warrior", "count": 6, "formation": "scatter"},
			{"type": "shadow_servant", "count": 36, "formation": "scatter"},
			{"type": "skeleton_mage", "count": 11, "formation": "scatter"},
			{"type": "demon_hound", "count": 6, "formation": "pack"},
			{"type": "swarm_bug", "count": 16, "formation": "ring"}]},
		{"wave": 15, "spawn_interval": 0.20, "is_boss": true, "events": [
			{"type": "orc_warrior", "count": 4, "formation": "scatter"},
			{"type": "shadow_servant", "count": 32, "formation": "scatter"},
			{"type": "skeleton_mage", "count": 10, "formation": "scatter"},
			{"type": "demon_hound", "count": 6, "formation": "pack"},
			{"type": "swarm_bug", "count": 16, "formation": "ring"},
			{"type": "boss", "count": 1, "formation": "single"}]},
	]

static var _wave_table: Array = []

## 根据波次生成计划：events（生成批次）、spawn_interval、is_boss、elite_count、total
static func build_wave_plan(wave: int) -> Dictionary:
	wave = maxi(wave, 1)  # 防御：负索引会取到表尾配置
	if boss_rush_mode:
		return _build_boss_rush_plan(wave)

	if _wave_table.is_empty():
		_wave_table = _build_wave_table()

	var row: Dictionary
	if wave <= _wave_table.size():
		row = _wave_table[wave - 1]
	else:
		row = _generate_infinite_wave_config(wave)

	var events: Array = row["events"].duplicate(true)
	var total := 0
	var regular_types: Array = []
	for e in events:
		total += int(e["count"])
		if e["type"] != "boss" and not (e["type"] in regular_types):
			regular_types.append(e["type"])

	# 精英：5 波起每波 1-2 只，10 波起 2 只，无限模式继续加码（上限4）
	var elite_count := 0
	if wave >= 5:
		elite_count = 2 if wave >= 10 else 1
	if wave > 15:
		elite_count = mini(4, 2 + (wave - 15) / 5)

	return {
		"wave": wave,
		"events": events,
		"spawn_interval": row["spawn_interval"],
		"is_boss": row.get("is_boss", false),
		"elite_count": elite_count,
		"regular_types": regular_types,
		"total": total
	}

## 无限模式（16 波起）：数量与种类随波次持续加码，间隔逼近 0.15s 下限
static func _generate_infinite_wave_config(wave: int) -> Dictionary:
	var extra := wave - 15
	var grow := func(base: int, per_wave: float, cap: int) -> int:
		return mini(cap, base + int(float(extra) * per_wave))
	return {
		"spawn_interval": maxf(0.15, 0.20 - extra * 0.005),
		"is_boss": wave % 5 == 0,
		"events": [
			{"type": "shadow_servant", "count": grow.call(34, 2.0, 80), "formation": "scatter"},
			{"type": "skeleton_mage", "count": grow.call(10, 0.8, 30), "formation": "scatter"},
			{"type": "orc_warrior", "count": grow.call(4, 0.5, 16), "formation": "scatter"},
			{"type": "demon_hound", "count": grow.call(6, 0.6, 18), "formation": "pack"},
			{"type": "swarm_bug", "count": grow.call(16, 0.8, 24), "formation": "ring"},
		] + ([{"type": "boss", "count": 1, "formation": "single"}] if wave % 5 == 0 else [])
	}

## Boss 连战计划：每波只有 Boss，数量每 3 波 +1（1,1,1,2,2,2,3…上限4），
## 无小怪、无精英；难度仍走 WaveManager 的波次难度系数
static func _build_boss_rush_plan(wave: int) -> Dictionary:
	var boss_count := mini(1 + (wave - 1) / 3, 4)
	return {
		"wave": wave,
		"events": [{"type": "boss", "count": boss_count, "formation": "single"}],
		"spawn_interval": 1.2,
		"is_boss": true,
		"elite_count": 0,
		"regular_types": [],
		"total": boss_count
	}

## ============================================================
## 生成执行
## ============================================================

## WaveManager 在每波生成阶段开始时调用：构建生成队列
func begin_wave(plan: Dictionary, difficulty: float) -> void:
	_difficulty = difficulty
	_flat_index = 0
	_elite_at.clear()
	_bounty_at.clear()
	_spawn_queue = plan.get("events", []).duplicate(true)

	# 精英分配：把 elite_count 只精英均匀散布到普通怪的扁平序号上
	var elite_count := int(plan.get("elite_count", 0))
	var regular_slots: Array[int] = []
	for e in _spawn_queue:
		if e["type"] == "boss":
			continue
		for i in int(e["count"]):
			regular_slots.append(_flat_index + i)
		_flat_index += int(e["count"])
	regular_slots.shuffle()
	for i in mini(elite_count, regular_slots.size()):
		_elite_at[regular_slots[i]] = true
	_flat_index = 0

	# 悬赏目标（事件波）：从未成为精英的普通怪里挑一只，奖励再翻倍
	if plan.get("event", "") == "bounty":
		var free_slots := regular_slots.filter(func(i): return not _elite_at.has(i))
		if not free_slots.is_empty():
			_bounty_at[free_slots[randi() % free_slots.size()]] = true

## 生成下一批（一个事件整批生成：环形包抄/狼群包必须同时落地）。
## 返回本批生成的敌人数，队列空返回 0。
func spawn_next_batch() -> int:
	if _spawn_queue.is_empty():
		return 0
	var event: Dictionary = _spawn_queue.pop_front()
	var count := int(event.get("count", 0))
	var formation: String = event.get("formation", "scatter")
	var type: String = event.get("type", "")

	var spawned := 0
	for i in count:
		var pos: Vector2
		match formation:
			"ring":
				# 虫群环形包抄：等距围一圈，从屏外合围
				var ang := TAU * float(i) / float(count) + randf_range(-0.06, 0.06)
				pos = _offscreen_pos(ang, randf_range(1.22, 1.30))
			"pack":
				# 猎犬狼群包：同侧小扇区集群涌入
				var spread := 0.55
				if i == 0:
					_pack_base_angle = randf() * TAU
				var a := _pack_base_angle + randf_range(-spread * 0.5, spread * 0.5)
				pos = _offscreen_pos(a, randf_range(1.18, 1.35))
			"single":
				pos = _offscreen_pos(randf() * TAU, 1.25)
			_:
				pos = _offscreen_pos(randf() * TAU)

		var enemy := _instantiate(type, pos)
		if enemy:
			spawned += 1
	return spawned

var _pack_base_angle := 0.0

## 实例化单个敌人（含精英/Boss 标记）
func _instantiate(type: String, pos: Vector2) -> EnemyBase:
	var scene_key := type
	if type == "boss":
		scene_key = BOSS_BASE_TYPE
	if not enemy_scenes.has(scene_key):
		push_warning("未知敌人类型: " + type)
		return null

	var enemy = enemy_scenes[scene_key].instantiate() as EnemyBase
	if enemy == null:
		return null

	var scene_root = get_tree().current_scene
	if scene_root == null:
		enemy.free()
		return null

	scene_root.add_child(enemy)
	enemy.global_position = pos
	enemy.set_difficulty(_difficulty)

	var is_elite_slot: bool = _elite_at.has(_flat_index)
	var is_bounty_slot: bool = _bounty_at.has(_flat_index)
	_flat_index += 1
	if type == "boss":
		var boss_scale := BOSS_SCALE
		if boss_rush_mode:
			# 连战模式 Boss 体型随波次缓慢成长（封顶 3.0）
			boss_scale = clampf(BOSS_SCALE + 0.1 * float(WaveManager.current_wave - 1), BOSS_SCALE, 3.0)
		enemy.make_boss(boss_scale)
		if boss_rush_mode:
			# 连战开局减压：首战血量为标准的 35%，随战次线性升满（第 ~9 战起 100%），
			# 给 1 级玩家留出生存与成长空间
			var ease_mult := minf(0.35 + 0.08 * float(WaveManager.current_wave - 1), 1.0)
			enemy.max_health *= ease_mult
			enemy.current_health = enemy.max_health
	elif is_elite_slot:
		enemy.make_elite()

	# 悬赏目标：精英基础之上奖励再翻倍 + 橙金配色 + 更大体型
	if is_bounty_slot and not enemy.is_boss:
		if not enemy.is_elite:
			enemy.make_elite()
		enemy.exp_reward *= 2
		enemy.gold_reward *= 2
		enemy.modulate = Color(1.0, 0.62, 0.15)
		enemy._apply_body_scale_mult(1.15)

	# 出生传送门（纯视觉）：普通怪暗紫 / 精英金 / Boss 暗红
	var portal_color := Color(0.62, 0.35, 0.95)
	if enemy.is_boss:
		portal_color = Color(0.9, 0.2, 0.15)
	elif enemy.is_elite:
		portal_color = Color(1.0, 0.8, 0.2)
	FxLib.spawn_portal(enemy, pos, portal_color)
	return enemy

## 屏外环带出生点：把单位方向角映射到恰好屏幕外
## （视口矩形按 margin 倍外扩处，margin>1 保证任何方向都在画面外）
func _offscreen_pos(angle: float, margin: float = -1.0) -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	var origin: Vector2 = player.global_position if player else Vector2(960, 540)
	var dir := Vector2.from_angle(angle)
	if margin < 0.0:
		margin = randf_range(1.18, 1.38)
	# 求 t 使 max(|dir.x*t|/960, |dir.y*t|/540) == margin
	var denom := maxf(absf(dir.x) / SCREEN_HALF.x, absf(dir.y) / SCREEN_HALF.y)
	if denom < 0.000001:
		denom = 1.0 / maxf(SCREEN_HALF.x, SCREEN_HALF.y)
	return origin + dir * (margin / denom)

## 波次配置（兼容旧接口）
func get_wave_config(wave: int) -> Dictionary:
	return build_wave_plan(wave)

## 开始下一波
func start_next_wave() -> void:
	WaveManager.start_wave()

## 随机生成位置（兼容旧接口：现为屏外环带随机点）
func _get_random_spawn_position() -> Vector2:
	return _offscreen_pos(randf() * TAU)
