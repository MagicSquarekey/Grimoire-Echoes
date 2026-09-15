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

	# ---------- 3. 事件波调度 ----------
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
