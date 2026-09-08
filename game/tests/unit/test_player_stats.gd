## TestPlayerStats - 玩家属性测试
## 测试玩家属性系统的正确性
extends Node

## 测试属性初始化
func test_stats_initialization() -> void:
	var stats = PlayerStats.new()
	
	# 等待_ready执行
	await get_tree().create_timer(0.1).timeout
	
	assert(stats.current_health == stats.max_health, "初始生命值应等于最大生命值")
	assert(stats.current_mana == stats.max_mana, "初始法力值应等于最大法力值")
	assert(stats.current_level == 1, "初始等级应为1")
	print("✅ 属性初始化测试通过")

## 测试受伤
func test_take_damage() -> void:
	var stats = PlayerStats.new()
	await get_tree().create_timer(0.1).timeout
	
	var initial_health = stats.current_health
	stats.take_damage(10.0)
	
	assert(stats.current_health < initial_health, "受伤后生命值应减少")
	print("✅ 受伤测试通过")

## 测试治疗
func test_heal() -> void:
	var stats = PlayerStats.new()
	await get_tree().create_timer(0.1).timeout
	
	stats.take_damage(50.0)
	var damaged_health = stats.current_health
	stats.heal(20.0)
	
	assert(stats.current_health > damaged_health, "治疗后生命值应增加")
	assert(stats.current_health <= stats.max_health, "治疗不应超过最大生命值")
	print("✅ 治疗法术测试通过")

## 测试法力消耗
func test_mana_consume() -> void:
	var stats = PlayerStats.new()
	await get_tree().create_timer(0.1).timeout
	
	var initial_mana = stats.current_mana
	var success = stats.consume_mana(30.0)
	
	assert(success, "法力消耗应成功")
	assert(stats.current_mana == initial_mana - 30.0, "法力值应减少30")
	print("✅ 法力消耗测试通过")

## 测试法力不足
func test_mana_insufficient() -> void:
	var stats = PlayerStats.new()
	await get_tree().create_timer(0.1).timeout
	
	var success = stats.consume_mana(9999.0)
	
	assert(not success, "法力不足时应返回false")
	print("✅ 法力不足测试通过")

## 测试经验值增加
func test_exp_gain() -> void:
	var stats = PlayerStats.new()
	await get_tree().create_timer(0.1).timeout
	
	stats.add_exp(100.0)
	
	assert(stats.current_exp > 0, "经验值应增加")
	print("✅ 经验值增加测试通过")

## 测试等级提升
func test_level_up() -> void:
	var stats = PlayerStats.new()
	await get_tree().create_timer(0.1).timeout
	
	# 连接升级信号
	var leveled_up = false
	stats.level_up.connect(func(level): leveled_up = true)
	
	# 给大量经验值
	stats.add_exp(10000.0)
	
	assert(leveled_up, "大量经验值应触发升级")
	print("✅ 等级提升测试通过")

## 测试暴击率
func test_crit_rate() -> void:
	var stats = PlayerStats.new()
	await get_tree().create_timer(0.1).timeout
	
	var crit_rate = stats.get_crit_rate()
	assert(crit_rate >= 0.0 and crit_rate <= 1.0, "暴击率应在0-1之间")
	
	stats.crit_rate_bonus = 0.5
	var new_crit_rate = stats.get_crit_rate()
	assert(new_crit_rate > crit_rate, "暴击率加成应增加暴击率")
	print("✅ 暴击率测试通过")

## 测试属性保存和加载
func test_save_load() -> void:
	var stats = PlayerStats.new()
	await get_tree().create_timer(0.1).timeout
	
	# 修改属性
	stats.current_health = 50.0
	stats.current_mana = 30.0
	stats.current_level = 5
	stats.gold = 100
	
	# 保存
	var save_data = stats.get_stats_dict()
	
	# 创建新实例并加载
	var new_stats = PlayerStats.new()
	await get_tree().create_timer(0.1).timeout
	new_stats.load_stats_dict(save_data)
	
	assert(new_stats.current_health == 50.0, "加载后生命值应为50")
	assert(new_stats.current_mana == 30.0, "加载后法力值应为30")
	assert(new_stats.current_level == 5, "加载后等级应为5")
	assert(new_stats.gold == 100, "加载后金币应为100")
	print("✅ 属性保存加载测试通过")

## 运行所有测试
func run_all_tests() -> void:
	print("开始运行玩家属性测试...")
	await test_stats_initialization()
	await test_take_damage()
	await test_heal()
	await test_mana_consume()
	await test_mana_insufficient()
	await test_exp_gain()
	await test_level_up()
	await test_crit_rate()
	await test_save_load()
	print("所有玩家属性测试通过！✅")
