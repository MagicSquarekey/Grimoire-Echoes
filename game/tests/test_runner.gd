## TestRunner - 测试运行器
## 运行所有单元测试
## 用法: godot --headless --path <项目> -s res://tests/test_runner.gd
extends SceneTree

var test_results: Array[Dictionary] = []

func _initialize() -> void:
	print("=".repeat(60))
	print("秘法回响 (Grimoire Echoes) - 测试套件")
	print("=".repeat(60))

	# 等待第一帧，确保场景树与 autoload 完全就绪（否则测试节点 get_tree() 为 null）
	await process_frame
	await _run_all_tests()
	_print_test_results()

func _run_all_tests() -> void:
	# 运行伤害计算器测试
	print("\n[1/5] 运行伤害计算器测试...")
	var damage_test = load("res://tests/unit/test_damage_calculator.gd").new()
	get_root().add_child(damage_test)
	var damage_ok: bool = damage_test.run_all_tests()
	test_results.append({"name": "伤害计算器", "status": "passed" if damage_ok else "failed"})
	damage_test.free()

	# 运行融合系统测试
	print("\n[2/5] 运行融合系统测试...")
	var fusion_test = load("res://tests/unit/test_fusion_system.gd").new()
	get_root().add_child(fusion_test)
	var fusion_ok: bool = fusion_test.run_all_tests()
	test_results.append({"name": "融合系统", "status": "passed" if fusion_ok else "failed"})
	fusion_test.free()

	# 运行玩家属性测试
	print("\n[3/5] 运行玩家属性测试...")
	var stats_test = load("res://tests/unit/test_player_stats.gd").new()
	get_root().add_child(stats_test)  # 入树，测试内才能使用 get_tree()
	var stats_ok: bool = await stats_test.run_all_tests()
	test_results.append({"name": "玩家属性", "status": "passed" if stats_ok else "failed"})
	stats_test.free()

	# 运行波次管理器测试
	print("\n[4/5] 运行波次管理器测试...")
	var wave_test = load("res://tests/unit/test_wave_manager.gd").new()
	get_root().add_child(wave_test)
	var wave_ok: bool = wave_test.run_all_tests()
	test_results.append({"name": "波次管理器", "status": "passed" if wave_ok else "failed"})
	wave_test.free()

	# 运行EventBus测试
	print("\n[5/5] 运行EventBus测试...")
	var eventbus_ok: bool = _run_eventbus_tests()
	test_results.append({"name": "EventBus", "status": "passed" if eventbus_ok else "failed"})

func _run_eventbus_tests() -> bool:
	# -s 模式下脚本编译早于 autoload 注册，须运行时从树根获取
	var event_bus = get_root().get_node_or_null("EventBus")
	if event_bus == null:
		print("❌ EventBus autoload 未注册")
		return false
	# 测试信号是否存在
	var required_signals = [
		"game_state_changed", "wave_started", "enemy_killed",
		"player_level_up", "spell_cast", "game_started",
		"game_over", "show_toast", "wave_completed",
	]
	for signal_name in required_signals:
		assert(event_bus.has_signal(signal_name), signal_name + "信号不存在")
		if not event_bus.has_signal(signal_name):
			return false
	print("✅ EventBus信号测试通过")
	return true

func _print_test_results() -> void:
	print("\n" + "=".repeat(60))
	print("测试结果汇总")
	print("=".repeat(60))

	var passed = 0
	var failed = 0

	for result in test_results:
		if result["status"] == "passed":
			print("✅ %s" % result["name"])
			passed += 1
		else:
			print("❌ %s" % result["name"])
			failed += 1

	print("=".repeat(60))
	print("通过: %d / %d" % [passed, test_results.size()])

	if failed == 0:
		print("🎉 所有测试通过！")
	else:
		print("⚠️ 有 %d 个测试失败" % failed)

	print("=".repeat(60))

	# 退出（失败时返回非零退出码）
	quit(0 if failed == 0 else 1)
