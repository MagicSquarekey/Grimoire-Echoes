## TestWaveManager - 波次管理器测试
## 测试波次系统的正确性
## 注意：WaveManager 是 autoload 单例，这里通过加载脚本 new() 出独立实例，
## 不入树（避免触发 _ready 重复连接 EventBus 信号），直接调用其方法验证逻辑。
extends Node

## 软断言：失败时记录并继续，保证 run_all_tests 返回准确的通过状态
var _test_failed := false

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_test_failed = true
		print("❌ 断言失败: " + msg)

## 创建一个独立的 WaveManager 实例用于测试（统一追踪，结束时释放）
var _created_managers: Array = []

func _create_wave_manager() -> Node:
	var wm = load("res://scripts/autoload/wave_manager.gd").new()
	_created_managers.append(wm)
	return wm

## 测试波次初始化
func test_wave_initialization() -> void:
	var wm = _create_wave_manager()

	_check(wm.current_wave == 0, "初始波次应为0")
	_check(wm.wave_state == WaveManager.PREPARING, "初始状态应为PREPARING")
	_check(wm.enemies_alive == 0, "初始敌人数应为0")
	_check(wm.enemies_to_spawn == 0, "初始待生成敌人数应为0")
	print("✅ 波次初始化测试通过")

## 测试波次开始
func test_wave_start() -> void:
	var wm = _create_wave_manager()

	wm.start_wave()

	_check(wm.current_wave == 1, "第一波开始后波次应为1")
	_check(wm.wave_state == WaveManager.PREPARING, "开始后状态应为PREPARING")
	_check(wm.wave_timer == wm.preparation_time, "准备期计时器应重置为准备时长")
	print("✅ 波次开始测试通过")

## 测试 start_next_wave 别名
func test_start_next_wave_alias() -> void:
	var wm = _create_wave_manager()

	wm.start_next_wave()

	_check(wm.current_wave == 1, "start_next_wave应等效于start_wave")
	print("✅ start_next_wave别名测试通过")

## 测试重置
func test_reset() -> void:
	var wm = _create_wave_manager()

	wm.start_wave()
	wm.enemies_alive = 7
	wm.enemies_to_spawn = 5
	wm.reset()

	_check(wm.current_wave == 0, "重置后波次应为0")
	_check(wm.wave_state == WaveManager.PREPARING, "重置后状态应为PREPARING")
	_check(wm.enemies_alive == 0, "重置后敌人数应为0")
	_check(wm.enemies_to_spawn == 0, "重置后待生成敌人数应为0")
	print("✅ 波次重置测试通过")

## 测试敌人数量计算
func test_enemy_count_calculation() -> void:
	var wm = _create_wave_manager()

	# 测试不同波次的敌人数量
	wm.current_wave = 1
	var count1 = wm._calculate_enemy_count()
	_check(count1 > 0, "第1波敌人数量应大于0")

	wm.current_wave = 10
	var count10 = wm._calculate_enemy_count()
	_check(count10 > count1, "第10波敌人数量应多于第1波")

	wm.current_wave = 20
	var count20 = wm._calculate_enemy_count()
	_check(count20 > count10, "第20波敌人数量应多于第10波")
	print("✅ 敌人数量计算测试通过")

## 测试难度系数
func test_difficulty_multiplier() -> void:
	var wm = _create_wave_manager()

	wm.current_wave = 1
	var diff1 = wm.get_difficulty_multiplier()

	wm.current_wave = 10
	var diff10 = wm.get_difficulty_multiplier()

	wm.current_wave = 20
	var diff20 = wm.get_difficulty_multiplier()

	_check(diff1 < diff10, "难度应随波次增加")
	_check(diff10 < diff20, "难度应持续增加")
	print("✅ 难度系数测试通过")

## 测试波次信息
func test_wave_info() -> void:
	var wm = _create_wave_manager()
	wm.current_wave = 5
	wm.enemies_alive = 10

	var info = wm.get_wave_info()

	_check(info["wave"] == 5, "波次信息应为5")
	_check(info["enemies_alive"] == 10, "敌人数信息应为10")
	_check(info.has("state"), "波次信息应包含state")
	_check(info.has("difficulty"), "波次信息应包含difficulty")
	print("✅ 波次信息测试通过")

## 测试Boss波次检测
func test_boss_wave_detection() -> void:
	var wm = _create_wave_manager()

	# 测试大Boss波次（每20波）
	wm.current_wave = 20
	_check(wm.current_wave % wm.boss_wave_interval == 0, "第20波应为大Boss波次")

	# 测试小Boss波次（每5波）
	wm.current_wave = 10
	_check(wm.current_wave % wm.mini_boss_interval == 0, "第10波应为小Boss波次")

	# 测试普通波次
	wm.current_wave = 7
	_check(wm.current_wave % wm.boss_wave_interval != 0, "第7波不应为大Boss波次")
	_check(wm.current_wave % wm.mini_boss_interval != 0, "第7波不应为小Boss波次")
	print("✅ Boss波次检测测试通过")

## 测试准备期结束 → 进入生成状态
func test_preparing_to_spawning_transition() -> void:
	var wm = _create_wave_manager()

	wm.start_wave()
	# 直接推进准备期计时（避免依赖 _process 与场景树）
	wm._process_preparing(wm.preparation_time + 1.0)

	_check(wm.wave_state == WaveManager.SPAWNING, "准备期结束后应进入SPAWNING状态")
	_check(wm.enemies_to_spawn == wm._calculate_enemy_count(), "待生成数量应为该波敌人总数")
	print("✅ 准备期→生成期转换测试通过")

## 测试新波次曲线：前3波缓冲期、第4波上台阶、间隔递减
func test_wave_plan_curve() -> void:
	var plan1 = EnemySpawner.build_wave_plan(1)
	var plan3 = EnemySpawner.build_wave_plan(3)
	var plan4 = EnemySpawner.build_wave_plan(4)
	var plan10 = EnemySpawner.build_wave_plan(10)

	_check(plan1["total"] >= 8 and plan1["total"] <= 16, "第1波应为缓冲期数量(8-16只)，实际 %d" % plan1["total"])
	_check(plan3["total"] <= 16, "第3波仍应为缓冲期(≤16只)，实际 %d" % plan3["total"])
	_check(plan4["total"] > plan3["total"], "第4波数量应明显上台阶")
	_check(plan10["total"] > plan4["total"], "第10波数量应多于第4波")

	# spawn_interval：第1波0.5 → 第10波约0.22 → 后期不低于0.15
	_check(absf(plan1["spawn_interval"] - 0.5) < 0.001, "第1波间隔应为0.5s")
	_check(plan10["spawn_interval"] <= 0.3, "第10波间隔应≤0.3s，实际 %.2f" % plan10["spawn_interval"])
	var plan30 = EnemySpawner.build_wave_plan(30)
	_check(plan30["spawn_interval"] >= 0.15, "后期间隔不应低于0.15s下限")

	# 总量提升：1-15 波总量应约为旧配置(445)的1.4倍以上
	var sum := 0
	for w in range(1, 16):
		sum += int(EnemySpawner.build_wave_plan(w)["total"])
	_check(sum >= 620, "1-15波总数量应≥620(旧配置约445的1.4倍)，实际 %d" % sum)
	print("✅ 新波次曲线测试通过 (1-15波总量=%d)" % sum)

## 测试新怪物波次出场与阵型标记
func test_wave_plan_composition() -> void:
	var plan4 = EnemySpawner.build_wave_plan(4)
	var has_hound := false
	for e in plan4["events"]:
		if e["type"] == "demon_hound":
			has_hound = true
			_check(e["formation"] == "pack", "猎犬应为狼群包(pack)阵型")
			_check(e["count"] >= 4 and e["count"] <= 6, "猎犬应4-6只一包")
	_check(has_hound, "第4波应出现恶魔猎犬")

	var plan8 = EnemySpawner.build_wave_plan(8)
	var has_orc := false
	for e in plan8["events"]:
		if e["type"] == "orc_warrior":
			has_orc = true
	_check(has_orc, "第8波应出现兽人勇士")

	var has_ring := false
	for w in [3, 6, 11]:
		for e in EnemySpawner.build_wave_plan(w)["events"]:
			if e["type"] == "swarm_bug" and e["formation"] == "ring":
				has_ring = true
	_check(has_ring, "虫群应存在环形包抄(ring)阵型")
	print("✅ 波次构成（新怪物/阵型）测试通过")

## 测试Boss波与精英数量规则
func test_boss_and_elite_plan() -> void:
	for w in [5, 10, 15, 20]:
		var plan = EnemySpawner.build_wave_plan(w)
		_check(plan["is_boss"], "第%d波应为Boss波" % w)
		var has_boss := false
		for e in plan["events"]:
			if e["type"] == "boss":
				has_boss = true
		_check(has_boss, "第%d波事件中应含boss" % w)

	for w in [1, 2, 3, 4]:
		_check(EnemySpawner.build_wave_plan(w)["elite_count"] == 0, "第%d波不应有精英" % w)
	_check(EnemySpawner.build_wave_plan(5)["elite_count"] >= 1, "第5波起应有精英")
	_check(EnemySpawner.build_wave_plan(10)["elite_count"] >= 2, "第10波起精英应≥2只")
	_check(EnemySpawner.build_wave_plan(7)["is_boss"] == false, "第7波不应是Boss波")
	print("✅ Boss波与精英规则测试通过")

## 测试无限模式持续加码
func test_infinite_wave_growth() -> void:
	var plan16 = EnemySpawner.build_wave_plan(16)
	var plan25 = EnemySpawner.build_wave_plan(25)
	var plan40 = EnemySpawner.build_wave_plan(40)

	_check(plan25["total"] > plan16["total"], "无限模式数量应随波次增长")
	_check(plan40["total"] > plan25["total"], "无限模式数量应持续增长")
	_check(plan40["spawn_interval"] >= 0.15, "无限模式间隔不应低于0.15s下限")
	_check(plan25["elite_count"] >= plan16["elite_count"], "无限模式精英数不应减少")
	# Boss 每 5 波
	for w in [25, 30, 40]:
		_check(EnemySpawner.build_wave_plan(w)["is_boss"], "第%d波应为Boss波" % w)
	_check(EnemySpawner.build_wave_plan(23)["is_boss"] == false, "第23波不应是Boss波")
	print("✅ 无限模式成长测试通过")

## 测试 is_boss_wave 助手
func test_is_boss_wave_helper() -> void:
	var wm = _create_wave_manager()
	_check(wm.is_boss_wave(5), "is_boss_wave(5)应为真")
	_check(wm.is_boss_wave(10), "is_boss_wave(10)应为真")
	_check(not wm.is_boss_wave(7), "is_boss_wave(7)应为假")
	print("✅ is_boss_wave助手测试通过")

## 运行所有测试
func run_all_tests() -> bool:
	print("开始运行波次管理器测试...")
	_test_failed = false
	test_wave_initialization()
	test_wave_start()
	test_start_next_wave_alias()
	test_reset()
	test_enemy_count_calculation()
	test_difficulty_multiplier()
	test_wave_info()
	test_boss_wave_detection()
	test_preparing_to_spawning_transition()
	test_wave_plan_curve()
	test_wave_plan_composition()
	test_boss_and_elite_plan()
	test_infinite_wave_growth()
	test_is_boss_wave_helper()
	for wm in _created_managers:
		if is_instance_valid(wm):
			wm.free()
	print("所有波次管理器测试通过！✅")
	return not _test_failed
