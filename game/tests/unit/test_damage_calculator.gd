## TestDamageCalculator - 伤害计算器测试
## 测试伤害计算系统的正确性
extends Node

## 测试基础伤害计算
func test_basic_damage_calculation() -> void:
	var result = DamageCalculator.calculate(
		100.0,  # 基础伤害
		1.0,    # 攻击力倍率
		0.0,    # 元素加成
		0.0,    # 暴击率
		1.5,    # 暴击伤害
		0.0,    # 防御
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert(result.final_damage == 100.0, "基础伤害计算错误")
	assert(result.is_critical == false, "暴击判定错误")
	print("✅ 基础伤害计算测试通过")

## 测试暴击伤害
func test_critical_damage() -> void:
	var result = DamageCalculator.calculate(
		100.0,  # 基础伤害
		1.0,    # 攻击力倍率
		0.0,    # 元素加成
		1.0,    # 暴击率（100%暴击）
		2.0,    # 暴击伤害
		0.0,    # 防御
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert(result.final_damage == 200.0, "暴击伤害计算错误")
	assert(result.is_critical == true, "暴击判定错误")
	print("✅ 暴击伤害测试通过")

## 测试防御减伤
func test_defense_reduction() -> void:
	var result = DamageCalculator.calculate(
		100.0,  # 基础伤害
		1.0,    # 攻击力倍率
		0.0,    # 元素加成
		0.0,    # 暴击率
		1.5,    # 暴击伤害
		50.0,   # 防御
		DamageCalculator.DamageType.PHYSICAL
	)
	
	# 防御公式：伤害 * (100 / (100 + 防御))
	# 100 * (100 / 150) = 66.67
	assert(abs(result.final_damage - 66.67) < 0.1, "防御减伤计算错误")
	print("✅ 防御减伤测试通过")

## 测试元素伤害
func test_elemental_damage() -> void:
	var result = DamageCalculator.calculate(
		100.0,  # 基础伤害
		1.0,    # 攻击力倍率
		0.5,    # 元素加成（+50%）
		0.0,    # 暴击率
		1.5,    # 暴击伤害
		0.0,    # 防御
		DamageCalculator.DamageType.ELEMENTAL
	)
	
	assert(result.final_damage == 150.0, "元素伤害计算错误")
	print("✅ 元素伤害测试通过")

## 测试等级倍率
func test_level_multiplier() -> void:
	var multiplier = DamageCalculator._get_level_multiplier(5)
	assert(multiplier == 1.55, "Lv.5等级倍率错误")  # 1.0 + 4*0.08 + 0.15
	
	multiplier = DamageCalculator._get_level_multiplier(10)
	assert(multiplier == 2.50, "Lv.10等级倍率错误")  # 1.0 + 9*0.08 + 0.15 + 0.30
	
	multiplier = DamageCalculator._get_level_multiplier(15)
	assert(multiplier == 4.00, "Lv.15等级倍率错误")  # 1.0 + 14*0.08 + 0.15 + 0.30 + 0.50
	
	print("✅ 等级倍率测试通过")

## 运行所有测试
func run_all_tests() -> void:
	print("开始运行伤害计算器测试...")
	test_basic_damage_calculation()
	test_critical_damage()
	test_defense_reduction()
	test_elemental_damage()
	test_level_multiplier()
	print("所有伤害计算器测试通过！✅")
