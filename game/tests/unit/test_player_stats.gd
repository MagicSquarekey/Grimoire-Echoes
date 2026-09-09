## TestPlayerStats - 玩家属性测试
## 测试玩家属性系统的正确性
extends Node

## 软断言：失败时记录并继续，保证 run_all_tests 返回准确的通过状态
var _test_failed := false

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_test_failed = true
		print("❌ 断言失败: " + msg)

## 统一创建并追踪 PlayerStats 实例，结束时统一释放避免泄漏
var _created_stats: Array = []
var _leveled_up := false

func _on_test_level_up(_new_level: int) -> void:
	_leveled_up = true

func _new_stats() -> PlayerStats:
	var s = PlayerStats.new()
	_created_stats.append(s)
	return s

## 测试属性初始化
func test_stats_initialization() -> void:
	var stats = _new_stats()
	
	# 等待_ready执行
	await get_tree().create_timer(0.1).timeout
	
	_check(stats.current_health == stats.max_health, "初始生命值应等于最大生命值")
	_check(stats.current_mana == stats.max_mana, "初始法力值应等于最大法力值")
	_check(stats.current_level == 1, "初始等级应为1")
	print("✅ 属性初始化测试通过")

## 测试受伤
func test_take_damage() -> void:
	var stats = _new_stats()
	await get_tree().create_timer(0.1).timeout
	
	var initial_health = stats.current_health
	stats.take_damage(10.0)
	
	_check(stats.current_health < initial_health, "受伤后生命值应减少")
	print("✅ 受伤测试通过")

## 测试治疗
func test_heal() -> void:
	var stats = _new_stats()
	await get_tree().create_timer(0.1).timeout
	
	stats.take_damage(50.0)
	var damaged_health = stats.current_health
	stats.heal(20.0)
	
	_check(stats.current_health > damaged_health, "治疗后生命值应增加")
	_check(stats.current_health <= stats.max_health, "治疗不应超过最大生命值")
	print("✅ 治疗法术测试通过")

## 测试法力消耗
func test_mana_consume() -> void:
	var stats = _new_stats()
	await get_tree().create_timer(0.1).timeout
	
	var initial_mana = stats.current_mana
	var success = stats.consume_mana(30.0)
	
	_check(success, "法力消耗应成功")
	_check(stats.current_mana == initial_mana - 30.0, "法力值应减少30")
	print("✅ 法力消耗测试通过")

## 测试法力不足
func test_mana_insufficient() -> void:
	var stats = _new_stats()
	await get_tree().create_timer(0.1).timeout
	
	var success = stats.consume_mana(9999.0)
	
	_check(not success, "法力不足时应返回false")
	print("✅ 法力不足测试通过")

## 测试经验值增加
func test_exp_gain() -> void:
	var stats = _new_stats()
	await get_tree().create_timer(0.1).timeout
	
	stats.add_exp(100.0)
	
	_check(stats.current_exp > 0, "经验值应增加")
	print("✅ 经验值增加测试通过")

## 测试等级提升
func test_level_up() -> void:
	var stats = _new_stats()
	await get_tree().create_timer(0.1).timeout
	
	# 连接升级信号（lambda 按值捕获局部变量，须用成员变量才能在闭包外观察到变化）
	_leveled_up = false
	stats.level_up.connect(_on_test_level_up)

	# 给大量经验值
	stats.add_exp(10000.0)

	_check(_leveled_up, "大量经验值应触发升级")
	_check(stats.current_level > 1, "经验值足够时等级应大于1")
	print("✅ 等级提升测试通过")

## 测试暴击率
func test_crit_rate() -> void:
	var stats = _new_stats()
	await get_tree().create_timer(0.1).timeout
	
	var crit_rate = stats.get_crit_rate()
	_check(crit_rate >= 0.0 and crit_rate <= 1.0, "暴击率应在0-1之间")
	
	stats.crit_rate_bonus = 0.5
	var new_crit_rate = stats.get_crit_rate()
	_check(new_crit_rate > crit_rate, "暴击率加成应增加暴击率")
	print("✅ 暴击率测试通过")

## 测试属性保存和加载
func test_save_load() -> void:
	var stats = _new_stats()
	await get_tree().create_timer(0.1).timeout
	
	# 修改属性
	stats.current_health = 50.0
	stats.current_mana = 30.0
	stats.current_level = 5
	stats.gold = 100
	
	# 保存
	var save_data = stats.get_stats_dict()
	
	# 创建新实例并加载
	var new_stats = _new_stats()
	await get_tree().create_timer(0.1).timeout
	new_stats.load_stats_dict(save_data)
	
	_check(new_stats.current_health == 50.0, "加载后生命值应为50")
	_check(new_stats.current_mana == 30.0, "加载后法力值应为30")
	_check(new_stats.current_level == 5, "加载后等级应为5")
	_check(new_stats.gold == 100, "加载后金币应为100")
	print("✅ 属性保存加载测试通过")

## 运行所有测试
func run_all_tests() -> bool:
	print("开始运行玩家属性测试...")
	_test_failed = false
	await test_stats_initialization()
	await test_take_damage()
	await test_heal()
	await test_mana_consume()
	await test_mana_insufficient()
	await test_exp_gain()
	await test_level_up()
	await test_crit_rate()
	await test_save_load()
	for s in _created_stats:
		if is_instance_valid(s):
			s.free()
	print("所有玩家属性测试通过！✅")
	return not _test_failed
