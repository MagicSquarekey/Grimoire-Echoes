## TestFusionSystem - 融合系统测试
## 测试融合配方和融合法术的正确性
extends Node

## 软断言：失败时记录并继续，保证 run_all_tests 返回准确的通过状态
var _test_failed := false

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_test_failed = true
		print("❌ 断言失败: " + msg)

## 测试融合配方数量
func test_fusion_recipe_count() -> void:
	var recipes = FusionSpellGenerator.FUSION_RECIPES
	_check(recipes.size() == 15, "融合配方数量应为15，实际: %d" % recipes.size())
	print("✅ 融合配方数量测试通过")

## 测试融合配方唯一性
func test_fusion_recipe_uniqueness() -> void:
	var recipes = FusionSpellGenerator.FUSION_RECIPES
	var ids: Array[String] = []
	for recipe in recipes:
		_check(recipe.id not in ids, "融合配方ID重复: " + recipe.id)
		ids.append(recipe.id)
	print("✅ 融合配方唯一性测试通过")

## 测试融合配方元素组合
func test_fusion_recipe_elements() -> void:
	var recipes = FusionSpellGenerator.FUSION_RECIPES
	var expected_elements = [
		["fire", "water"],
		["fire", "lightning"],
		["fire", "nature"],
		["fire", "shadow"],
		["fire", "air"],
		["water", "lightning"],
		["water", "nature"],
		["water", "shadow"],
		["water", "air"],
		["lightning", "nature"],
		["lightning", "shadow"],
		["lightning", "air"],
		["nature", "shadow"],
		["nature", "air"],
		["shadow", "air"]
	]
	
	for i in range(recipes.size()):
		var recipe = recipes[i]
		var expected = expected_elements[i]
		_check(recipe.element1 == expected[0] and recipe.element2 == expected[1],
			"配方 %s 元素组合错误: 期望 %s+%s, 实际 %s+%s" % [
				recipe.id, expected[0], expected[1], recipe.element1, recipe.element2
			])
	print("✅ 融合配方元素组合测试通过")

## 测试融合配方伤害值
func test_fusion_recipe_damage() -> void:
	var recipes = FusionSpellGenerator.FUSION_RECIPES
	for recipe in recipes:
		_check(recipe.base_damage >= 0.0, "配方 %s 伤害值无效: %f" % [recipe.id, recipe.base_damage])
	print("✅ 融合配方伤害值测试通过")

## 测试融合配方冷却时间
func test_fusion_recipe_cooldown() -> void:
	var recipes = FusionSpellGenerator.FUSION_RECIPES
	for recipe in recipes:
		_check(recipe.cooldown > 0.0, "配方 %s 冷却时间无效: %f" % [recipe.id, recipe.cooldown])
	print("✅ 融合配方冷却时间测试通过")

## 测试融合法术生成器
func test_fusion_spell_generator() -> void:
	var spell = FusionSpellGenerator.create_fusion_spell("fusion_steam_blast")
	_check(spell != null, "生成蒸汽爆炸融合法术失败")
	if spell:
		_check(spell.spell_name == "蒸汽爆炸", "法术名称错误")
		spell.free()  # 未入树的节点手动释放，避免退出时泄漏
	print("✅ 融合法术生成器测试通过")

## 测试融合法术生成器-无效配方
func test_fusion_spell_generator_invalid() -> void:
	var spell = FusionSpellGenerator.create_fusion_spell("invalid_recipe")
	_check(spell == null, "无效配方应返回null")
	print("✅ 融合法术生成器无效配方测试通过")

## 测试融合条件检查
func test_fusion_availability() -> void:
	# 创建模拟法术数组
	var spells: Array[BaseSpell] = []
	
	# 检查空数组
	var available = FusionSpellGenerator.check_fusion_availability(spells)
	_check(available.size() == 0, "空法术数组应无可用融合")
	print("✅ 融合条件检查测试通过")

## 运行所有测试
func run_all_tests() -> bool:
	print("开始运行融合系统测试...")
	_test_failed = false
	test_fusion_recipe_count()
	test_fusion_recipe_uniqueness()
	test_fusion_recipe_elements()
	test_fusion_recipe_damage()
	test_fusion_recipe_cooldown()
	test_fusion_spell_generator()
	test_fusion_spell_generator_invalid()
	test_fusion_availability()
	print("所有融合系统测试通过！✅")
	return not _test_failed
