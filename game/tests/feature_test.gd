## feature_test.gd - 新功能纯逻辑测试（场景方式运行，autoload 完整）
## 运行：godot --headless --path . res://tests/feature_test_scene.tscn
## 覆盖：Boss 连战波次计划 / 事件波调度 / 重投资价曲线
extends Node

var failures: Array = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if cond:
		print("  ✓ %s" % label)
	else:
		failures.append(label)
		print("  ✗ %s" % label)

func _ready() -> void:
	print("=== 新功能逻辑测试 ===")

	# ---------- 1. Boss 连战波次计划 ----------
	print("[Boss Rush 波次计划]")
	EnemySpawner.boss_rush_mode = true

	var p1 := EnemySpawner.build_wave_plan(1)
	check(int(p1["total"]) == 1, "第 1 战 1 只 Boss（实际 %s）" % p1["total"])
	check(bool(p1["is_boss"]), "第 1 战标记为 Boss 波")
	var only_boss := true
	for e in p1["events"]:
		if e["type"] != "boss":
			only_boss = false
	check(only_boss, "连战计划只含 Boss 事件")
	check(int(p1["elite_count"]) == 0, "连战无精英")

	var p4 := EnemySpawner.build_wave_plan(4)
	check(int(p4["total"]) == 2, "第 4 战 2 只 Boss（实际 %s）" % p4["total"])

	var p10 := EnemySpawner.build_wave_plan(10)
	check(int(p10["total"]) == 4, "第 10 战 4 只 Boss（封顶，实际 %s）" % p10["total"])

	EnemySpawner.boss_rush_mode = false

	# ---------- 2. 标准波次计划回归 ----------
	print("[标准波次计划回归]")
	var n1 := EnemySpawner.build_wave_plan(1)
	check(int(n1["total"]) == 10, "标准第 1 波 10 只（实际 %s）" % n1["total"])
	check(not bool(n1["is_boss"]), "标准第 1 波非 Boss 波")
	var n5 := EnemySpawner.build_wave_plan(5)
	check(bool(n5["is_boss"]), "标准第 5 波为 Boss 波")
	var n16 := EnemySpawner.build_wave_plan(16)
	check(int(n16["total"]) > 0, "无限模式第 16 波有敌人（实际 %s）" % n16["total"])

	# ---------- 3. 新敌人类型接入 ----------
	print("[新敌人类型]")
	var new_types := ["gargoyle", "bone_archer", "shadow_assassin", "plague_spitter", "storm_wisp",
			"ember_crab", "grave_cleric", "aegis_golem", "bat_swarm", "zombie_shambler",
			"cursed_knight", "ember_lord"]
	var scripted_types := {}
	for w in range(1, 16):
		for e in EnemySpawner.build_wave_plan(w)["events"]:
			scripted_types[e["type"]] = true
	for t in new_types:
		check(scripted_types.has(t), "1-15 波脚本化里出现 %s" % t)

	var infinite_types := {}
	for w in [16, 20, 26, 33]:
		for e in EnemySpawner.build_wave_plan(w)["events"]:
			infinite_types[e["type"]] = true
	check(infinite_types.has("ember_lord"), "无限模式 20 波后出现元素领主")
	check(infinite_types.has("cursed_knight"), "无限模式持续出暗影骑士")

	# 阵型字段必须合法：写错的阵型会被 match 默认分支静默降级成 scatter，肉眼看不出来
	var valid_formations := ["scatter", "ring", "pack", "single", "flight"]
	var bad_formation := ""
	for w in range(1, 31):
		for e in EnemySpawner.build_wave_plan(w)["events"]:
			if not (e["formation"] in valid_formations):
				bad_formation = "第%d波 %s -> %s" % [w, e["type"], e["formation"]]
	check(bad_formation == "", "全部波次阵型合法（异常：%s）" % bad_formation)

	# ---------- 4. 事件波调度 ----------
	print("[事件波调度]")
	check(String(WaveManager.event_id_for_wave(1)) == "", "第 1 波无事件")
	check(String(WaveManager.event_id_for_wave(2)) == "", "第 2 波无事件")
	check(String(WaveManager.event_id_for_wave(3)) == "treasure", "第 3 波=宝箱")
	check(String(WaveManager.event_id_for_wave(5)) == "", "第 5 波(Boss)无事件")
	check(String(WaveManager.event_id_for_wave(8)) == "altar", "第 8 波=祭坛")
	check(String(WaveManager.event_id_for_wave(13)) == "bounty", "第 13 波=悬赏")
	check(String(WaveManager.event_id_for_wave(18)) == "treasure", "第 18 波轮回宝箱")
	check(String(WaveManager.event_id_for_wave(3, true)) == "", "连战模式无事件波")

	# ---------- 4. 重投资价曲线 ----------
	print("[重投资价]")
	check(UpgradePanel.reroll_cost(0) == 20, "首次重投 20 金币")
	check(UpgradePanel.reroll_cost(1) == 40, "第二次 40 金币")
	check(UpgradePanel.reroll_cost(2) == 80, "第三次 80 金币")
	check(UpgradePanel.reroll_cost(4) == 320, "第五次 320 金币")

	# ---------- 5. 支援/状态机制实机验证（需要真实物理帧，放最后） ----------
	print("[支援与状态机制]")
	await _test_support_mechanics()

	# ---------- 汇总 ----------
	print("===============================")
	if failures.is_empty():
		print("全部通过：%d 项检查 ✓" % checks)
		get_tree().quit(0)
	else:
		print("失败 %d/%d 项：" % [failures.size(), checks])
		for f in failures:
			print("  - " + f)
		get_tree().quit(1)

## 假玩家：只记录受到的每一次伤害（含来源），用于断言敌方结算
class MockPlayer:
	extends CharacterBody2D
	var hits: Array[Dictionary] = []

	func _ready() -> void:
		add_to_group("player")
		# Area2D 的 body_entered 只对带碰撞形状的 Body 触发，
		# 没有形状时冲击波类断言会静默漏判
		var circle := CircleShape2D.new()
		circle.radius = 18.0
		var shape := CollisionShape2D.new()
		shape.shape = circle
		add_child(shape)

	func take_damage(damage: float, attacker = null) -> void:
		hits.append({"damage": damage, "attacker": attacker})

func _wait(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await get_tree().physics_frame

## 从某个来源收到的总伤害
func _damage_from(player: MockPlayer, source) -> float:
	var total := 0.0
	for hit in player.hits:
		if hit["attacker"] == source:
			total += float(hit["damage"])
	return total

func _test_support_mechanics() -> void:
	var root := get_tree().current_scene

	# 假玩家放在远处：敌我双方都朝它跑，彼此相对距离保持稳定
	var mock := MockPlayer.new()
	mock.global_position = Vector2(1500, 0)
	root.add_child.call_deferred(mock)
	await get_tree().physics_frame

	# --- 治疗：墓园牧师每 3s(首发 1.5s) 给半径内友军回 5% 上限 ---
	var cleric: EnemyBase = load("res://scenes/enemies/grave_cleric.tscn").instantiate()
	cleric.global_position = Vector2.ZERO
	root.add_child(cleric)
	var wounded: EnemyBase = load("res://scenes/enemies/shadow_servant.tscn").instantiate()
	wounded.global_position = Vector2(60, 0)
	root.add_child(wounded)
	wounded.current_health = 10.0
	await _wait(2.2)
	check(wounded.current_health > 10.0,
			"墓园牧师治疗了受伤友军（10 → %.1f）" % wounded.current_health)
	check(cleric.attack_damage == 0.0, "墓园牧师不输出伤害")

	# --- 护盾：圣盾石像光环挂吸收盾，且盾先于生命承伤 ---
	var golem: EnemyBase = load("res://scenes/enemies/aegis_golem.tscn").instantiate()
	golem.global_position = Vector2(0, 200)
	root.add_child(golem)
	var protected: EnemyBase = load("res://scenes/enemies/shadow_servant.tscn").instantiate()
	protected.global_position = Vector2(60, 200)
	root.add_child(protected)
	protected.current_health = 12.0
	await _wait(1.6)
	check(protected.shield_hp > 0.0, "圣盾石像给友军挂了吸收盾（盾 %.1f）" % protected.shield_hp)
	var hp_before: float = protected.current_health
	var shield_before: float = protected.shield_hp
	protected.take_damage(5.0, null)
	check(is_equal_approx(protected.current_health, hp_before),
			"护盾吸收期间生命不掉（盾 %.1f → %.1f）" % [shield_before, protected.shield_hp])
	check(is_equal_approx(protected.shield_hp, shield_before - 5.0), "护盾按吸收量递减")

	# --- 瘟疫：叠层上限 5，一跳 = 层数 × 单跳伤害 ---
	var dot := PlagueDot.attach_from(self)
	check(dot != null, "瘟疫结算器可惰性创建")
	for i in 8:
		dot.add_stack(3.0, 3.0, 1)
	mock.hits.clear()
	await _wait(1.0)
	var poisoned := _damage_from(mock, dot)
	check(is_equal_approx(poisoned, 15.0),
			"瘟疫按 5 层上限结算一跳（实际 %.1f，期望 15.0）" % poisoned)

	# --- 冲击波：扩散环只命中玩家一次 ---
	# 瘟疫结算器是全场单例且仍在按跳掉血，会混进本段的命中计数，先摘掉
	var lingering_dot := get_tree().get_first_node_in_group(PlagueDot.GROUP)
	if lingering_dot != null:
		lingering_dot.free()
	mock.hits.clear()
	ShockwaveRing.spawn(self, mock.global_position, 220.0, 22.0, Color(1, 1, 1), 0.2, "fire")
	await _wait(0.6)
	# 冲击波命中后即自毁，hits 里的 attacker 到断言时已是释放实例，
	# 无法再按类型筛；改为断言"这段时间内玩家只挨了一次 22 点"
	var wave_hits: int = mock.hits.size()
	var wave_damage := 0.0
	for hit in mock.hits:
		wave_damage += float(hit["damage"])
	check(wave_hits == 1 and is_equal_approx(wave_damage, 22.0),
			"冲击波对玩家只结算一次伤害（命中 %d 次，共 %.1f）" % [wave_hits, wave_damage])

	cleric.free()
	wounded.free()
	golem.free()
	protected.free()
	mock.free()
