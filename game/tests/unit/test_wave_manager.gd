## TestWaveManager - 波次管理器测试
## 测试波次系统的正确性
extends Node

## 测试波次初始化
func test_wave_initialization() -> void:
	var wm = WaveManager.new()
	
	assert(wm.current_wave == 0, "初始波次应为0")
	assert(wm.wave_state == wm.WaveState.PREPARING, "初始状态应为PREPARING")
	assert(wm.enemies_alive == 0, "初始敌人数应为0")
	print("✅ 波次初始化测试通过")

## 测试波次开始
func test_wave_start() -> void:
	var wm = WaveManager.new()
	
	wm.start_wave()
	
	assert(wm.current_wave == 1, "第一波开始后波次应为1")
	assert(wm.wave_state == wm.WaveState.PREPARING, "开始后状态应为PREPARING")
	print("✅ 波次开始测试通过")

## 测试敌人数量计算
func test_enemy_count_calculation() -> void:
	var wm = WaveManager.new()
	
	# 测试不同波次的敌人数量
	wm.current_wave = 1
	var count1 = wm._calculate_enemy_count()
	assert(count1 > 0, "第1波敌人数量应大于0")
	
	wm.current_wave = 10
	var count10 = wm._calculate_enemy_count()
	assert(count10 > count1, "第10波敌人数量应多于第1波")
	
	wm.current_wave = 20
	var count20 = wm._calculate_enemy_count()
	assert(count20 > count10, "第20波敌人数量应多于第10波")
	print("✅ 敌人数量计算测试通过")

## 测试难度系数
func test_difficulty_multiplier() -> void:
	var wm = WaveManager.new()
	
	wm.current_wave = 1
	var diff1 = wm.get_difficulty_multiplier()
	
	wm.current_wave = 10
	var diff10 = wm.get_difficulty_multiplier()
	
	wm.current_wave = 20
	var diff20 = wm.get_difficulty_multiplier()
	
	assert(diff1 < diff10, "难度应随波次增加")
	assert(diff10 < diff20, "难度应持续增加")
	print("✅ 难度系数测试通过")

## 测试波次信息
func test_wave_info() -> void:
	var wm = WaveManager.new()
	wm.current_wave = 5
	wm.enemies_alive = 10
	
	var info = wm.get_wave_info()
	
	assert(info["wave"] == 5, "波次信息应为5")
	assert(info["enemies_alive"] == 10, "敌人数信息应为10")
	print("✅ 波次信息测试通过")

## 测试Boss波次检测
func test_boss_wave_detection() -> void:
	var wm = WaveManager.new()
	
	# 测试大Boss波次（每20波）
	wm.current_wave = 20
	assert(wm.current_wave % wm.boss_wave_interval == 0, "第20波应为大Boss波次")
	
	# 测试小Boss波次（每5波）
	wm.current_wave = 10
	assert(wm.current_wave % wm.mini_boss_interval == 0, "第10波应为小Boss波次")
	
	# 测试普通波次
	wm.current_wave = 7
	assert(wm.current_wave % wm.boss_wave_interval != 0, "第7波不应为大Boss波次")
	assert(wm.current_wave % wm.mini_boss_interval != 0, "第7波不应为小Boss波次")
	print("✅ Boss波次检测测试通过")

## 运行所有测试
func run_all_tests() -> void:
	print("开始运行波次管理器测试...")
	test_wave_initialization()
	test_wave_start()
	test_enemy_count_calculation()
	test_difficulty_multiplier()
	test_wave_info()
	test_boss_wave_detection()
	print("所有波次管理器测试通过！✅")
