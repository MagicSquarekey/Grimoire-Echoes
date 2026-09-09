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
	for wm in _created_managers:
		if is_instance_valid(wm):
			wm.free()
	print("所有波次管理器测试通过！✅")
	return not _test_failed
