## TestRunner - 测试运行器
## 运行所有单元测试
extends SceneTree

func _init() -> void:
	print("=" * 60)
	print("秘法回响 (Grimoire Echoes) - 测试套件")
	print("=" * 60)
	
	_run_all_tests()

func _run_all_tests() -> void:
	var test_results: Array[Dictionary] = []
	
	# 运行伤害计算器测试
	print("\n[1/5] 运行伤害计算器测试...")
	var damage_test = load("res://tests/unit/test_damage_calculator.gd").new()
	damage_test.run_all_tests()
	test_results.append({"name": "伤害计算器", "status": "passed"})
	
	# 运行融合系统测试
	print("\n[2/5] 运行融合系统测试...")
	var fusion_test = load("res://tests/unit/test_fusion_system.gd").new()
	fusion_test.run_all_tests()
	test_results.append({"name": "融合系统", "status": "passed"})
	
	# 运行玩家属性测试
	print("\n[3/5] 运行玩家属性测试...")
	var stats_test = load("res://tests/unit/test_player_stats.gd").new()
	await stats_test.run_all_tests()
	test_results.append({"name": "玩家属性", "status": "passed"})
	
	# 运行波次管理器测试
	print("\n[4/5] 运行波次管理器测试...")
	var wave_test = load("res://tests/unit/test_wave_manager.gd").new()
	wave_test.run_all_tests()
	test_results.append({"name": "波次管理器", "status": "passed"})
	
	# 运行EventBus测试
	print("\n[5/5] 运行EventBus测试...")
	_run_eventbus_tests()
	test_results.append({"name": "EventBus", "status": "passed"})
	
	# 输出测试结果
	_print_test_results(test_results)

func _run_eventbus_tests() -> void:
	# 测试信号是否存在
	assert(EventBus.has_signal("game_state_changed"), "game_state_changed信号不存在")
	assert(EventBus.has_signal("wave_started"), "wave_started信号不存在")
	assert(EventBus.has_signal("enemy_killed"), "enemy_killed信号不存在")
	assert(EventBus.has_signal("player_level_up"), "player_level_up信号不存在")
	assert(EventBus.has_signal("spell_cast"), "spell_cast信号不存在")
	assert(EventBus.has_signal("game_started"), "game_started信号不存在")
	assert(EventBus.has_signal("game_over"), "game_over信号不存在")
	assert(EventBus.has_signal("show_toast"), "show_toast信号不存在")
	print("✅ EventBus信号测试通过")

func _print_test_results(results: Array[Dictionary]) -> void:
	print("\n" + "=" * 60)
	print("测试结果汇总")
	print("=" * 60)
	
	var passed = 0
	var failed = 0
	
	for result in results:
		if result["status"] == "passed":
			print("✅ %s" % result["name"])
			passed += 1
		else:
			print("❌ %s" % result["name"])
			failed += 1
	
	print("=" * 60)
	print("通过: %d / %d" % [passed, results.size()])
	
	if failed == 0:
		print("🎉 所有测试通过！")
	else:
		print("⚠️ 有 %d 个测试失败" % failed)
	
	print("=" * 60)
	
	# 退出
	quit()
