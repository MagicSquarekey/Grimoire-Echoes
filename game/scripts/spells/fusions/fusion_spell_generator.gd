## FusionSpellGenerator - 融合法术生成器
## 根据融合配方动态创建融合法术
class_name FusionSpellGenerator
extends RefCounted

## 融合配方数据
class FusionRecipeData:
	var id: String
	var name: String
	var description: String
	var element1: String
	var element2: String
	var required_spell1: String
	var required_spell2: String
	var base_damage: float
	var cooldown: float
	var mana_cost: float
	var fusion_type: String  # 特殊效果类型
	
	func _init(
		_id: String,
		_name: String,
		_description: String,
		_element1: String,
		_element2: String,
		_required_spell1: String,
		_required_spell2: String,
		_base_damage: float,
		_cooldown: float,
		_mana_cost: float,
		_fusion_type: String
	) -> void:
		id = _id
		name = _name
		description = _description
		element1 = _element1
		element2 = _element2
		required_spell1 = _required_spell1
		required_spell2 = _required_spell2
		base_damage = _base_damage
		cooldown = _cooldown
		mana_cost = _mana_cost
		fusion_type = _fusion_type

## 融合配方表
const FUSION_RECIPES: Array[FusionRecipeData] = [
	# 🔥+💧 = 蒸汽爆炸
	FusionRecipeData.new(
		"fusion_steam_blast",
		"蒸汽爆炸",
		"高温蒸汽，持续伤害+降低视野",
		"fire", "water",
		"F1", "W1",
		40.0, 6.0, 25.0,
		"aoe_damage"
	),
	# 🔥+⚡ = 雷火交加
	FusionRecipeData.new(
		"fusion_thunderfire",
		"雷火交加",
		"雷火弹，连锁电火花",
		"fire", "lightning",
		"F1", "L1",
		45.0, 5.0, 25.0,
		"chain_lightning"
	),
	# 🔥+🌿 = 焚烧藤蔓
	FusionRecipeData.new(
		"fusion_burning_vines",
		"焚烧藤蔓",
		"燃烧藤蔓，缠绕敌人并造成持续燃烧",
		"fire", "nature",
		"F2", "N1",
		35.0, 7.0, 30.0,
		"entangle_burn"
	),
	# 🔥+🌑 = 暗焰爆弹
	FusionRecipeData.new(
		"fusion_dark_flame",
		"暗焰爆弹",
		"暗影火焰弹，吸取生命并造成燃烧",
		"fire", "shadow",
		"F1", "D1",
		40.0, 6.0, 28.0,
		"lifesteal_burn"
	),
	# 🔥+🌬️ = 火焰旋风
	FusionRecipeData.new(
		"fusion_fire_tornado",
		"火焰旋风",
		"火焰旋风，将敌人拉入并燃烧",
		"fire", "air",
		"F2", "A2",
		50.0, 8.0, 35.0,
		"pull_burn"
	),
	# 💧+⚡ = 冰雷爆裂
	FusionRecipeData.new(
		"fusion_frost_shock",
		"冰雷爆裂",
		"冰冻闪电，冻结敌人并传导伤害",
		"water", "lightning",
		"W1", "L1",
		42.0, 6.0, 26.0,
		"freeze_chain"
	),
	# 💧+🌿 = 生命之泉
	FusionRecipeData.new(
		"fusion_life_spring",
		"生命之泉",
		"治愈之泉，持续治疗队友并减速敌人",
		"water", "nature",
		"W1", "N2",
		0.0, 10.0, 30.0,
		"heal_slow"
	),
	# 💧+🌑 = 暗影潮汐
	FusionRecipeData.new(
		"fusion_shadow_tide",
		"暗影潮汐",
		"暗影水波，吸取生命并减速",
		"water", "shadow",
		"W1", "D1",
		35.0, 7.0, 28.0,
		"lifesteal_slow"
	),
	# 💧+🌬️ = 暴风雪
	FusionRecipeData.new(
		"fusion_blizzard",
		"暴风雪",
		"暴风雪，持续冰冻伤害并击退",
		"water", "air",
		"W3", "A2",
		30.0, 8.0, 32.0,
		"freeze_knockback"
	),
	# ⚡+🌿 = 雷霆荆棘
	FusionRecipeData.new(
		"fusion_thunder_thorns",
		"雷霆荆棘",
		"带电荆棘，缠绕敌人并持续放电",
		"lightning", "nature",
		"L1", "N1",
		38.0, 6.0, 27.0,
		"entangle_stun"
	),
	# ⚡+🌑 = 暗影闪电
	FusionRecipeData.new(
		"fusion_shadow_lightning",
		"暗影闪电",
		"暗影闪电，吸取生命并麻痹",
		"lightning", "shadow",
		"L1", "D1",
		40.0, 6.0, 28.0,
		"lifesteal_stun"
	),
	# ⚡+🌬️ = 风暴之眼
	FusionRecipeData.new(
		"fusion_storm_eye",
		"风暴之眼",
		"角色周围召唤风暴，持续击退并麻痹",
		"lightning", "air",
		"L2", "A2",
		35.0, 9.0, 35.0,
		"knockback_stun"
	),
	# 🌿+🌑 = 暗影荆棘
	FusionRecipeData.new(
		"fusion_shadow_thorns",
		"暗影荆棘",
		"暗影荆棘，缠绕敌人并吸取生命",
		"nature", "shadow",
		"N1", "D1",
		30.0, 7.0, 25.0,
		"entangle_lifesteal"
	),
	# 🌿+🌬️ = 自然风暴
	FusionRecipeData.new(
		"fusion_nature_storm",
		"自然风暴",
		"自然风暴，造成范围伤害并召唤藤蔓守卫",
		"nature", "air",
		"A2", "N4",
		45.0, 10.0, 40.0,
		"aoe_summon"
	),
	# 🌑+🌬️ = 暗影风暴
	FusionRecipeData.new(
		"fusion_shadow_storm",
		"暗影风暴",
		"暗影风暴，吸取生命并击退",
		"shadow", "air",
		"D3", "A2",
		40.0, 8.0, 32.0,
		"lifesteal_knockback"
	)
]

## 根据配方ID创建融合法术
static func create_fusion_spell(recipe_id: String) -> FusionSpell:
	var recipe = _get_recipe_by_id(recipe_id)
	if recipe == null:
		push_warning("Fusion recipe not found: " + recipe_id)
		return null
	
	# 根据融合类型创建不同的融合法术
	match recipe.fusion_type:
		"aoe_damage":
			return _create_aoe_damage_fusion(recipe)
		"chain_lightning":
			return _create_chain_lightning_fusion(recipe)
		"entangle_burn":
			return _create_entangle_burn_fusion(recipe)
		"lifesteal_burn":
			return _create_lifesteal_burn_fusion(recipe)
		"pull_burn":
			return _create_pull_burn_fusion(recipe)
		"freeze_chain":
			return _create_freeze_chain_fusion(recipe)
		"heal_slow":
			return _create_heal_slow_fusion(recipe)
		"lifesteal_slow":
			return _create_lifesteal_slow_fusion(recipe)
		"freeze_knockback":
			return _create_freeze_knockback_fusion(recipe)
		"entangle_stun":
			return _create_entangle_stun_fusion(recipe)
		"lifesteal_stun":
			return _create_lifesteal_stun_fusion(recipe)
		"knockback_stun":
			return _create_knockback_stun_fusion(recipe)
		"entangle_lifesteal":
			return _create_entangle_lifesteal_fusion(recipe)
		"aoe_summon":
			return _create_aoe_summon_fusion(recipe)
		"lifesteal_knockback":
			return _create_lifesteal_knockback_fusion(recipe)
		_:
			return _create_generic_fusion(recipe)

## 获取配方
static func _get_recipe_by_id(recipe_id: String) -> FusionRecipeData:
	for recipe in FUSION_RECIPES:
		if recipe.id == recipe_id:
			return recipe
	return null

## 创建通用融合法术
static func _create_generic_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = FusionSpell.new()
	spell.spell_name = recipe.name
	spell.damage = recipe.base_damage
	spell.cooldown = recipe.cooldown
	spell.mana_cost = recipe.mana_cost
	spell.fusion_recipe_id = recipe.id
	spell.element1 = recipe.element1
	spell.element2 = recipe.element2
	spell.required_spell1 = recipe.required_spell1
	spell.required_spell2 = recipe.required_spell2
	return spell

## 创建AoE伤害融合法术
static func _create_aoe_damage_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.AOE
	return spell

## 创建连锁闪电融合法术
static func _create_chain_lightning_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.CHAIN
	return spell

## 创建缠绕燃烧融合法术
static func _create_entangle_burn_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.CONTROL
	return spell

## 创建吸取燃烧融合法术
static func _create_lifesteal_burn_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.PROJECTILE
	return spell

## 创建拉扯燃烧融合法术
static func _create_pull_burn_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.AOE
	return spell

## 创建冻结连锁融合法术
static func _create_freeze_chain_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.CHAIN
	return spell

## 创建治疗减速融合法术
static func _create_heal_slow_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.BUFF
	return spell

## 创建吸取减速融合法术
static func _create_lifesteal_slow_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.PROJECTILE
	return spell

## 创建冻结击退融合法术
static func _create_freeze_knockback_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.AOE
	return spell

## 创建缠绕麻痹融合法术
static func _create_entangle_stun_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.CONTROL
	return spell

## 创建吸取麻痹融合法术
static func _create_lifesteal_stun_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.PROJECTILE
	return spell

## 创建击退麻痹融合法术
static func _create_knockback_stun_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.AOE
	return spell

## 创建缠绕吸取融合法术
static func _create_entangle_lifesteal_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.CONTROL
	return spell

## 创建AoE召唤融合法术
static func _create_aoe_summon_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.SUMMON
	return spell

## 创建吸取击退融合法术
static func _create_lifesteal_knockback_fusion(recipe: FusionRecipeData) -> FusionSpell:
	var spell = _create_generic_fusion(recipe)
	spell.spell_type = BaseSpell.SpellType.AOE
	return spell

## 获取所有融合配方
static func get_all_recipes() -> Array[FusionRecipeData]:
	return FUSION_RECIPES

## 根据元素获取融合配方
static func get_recipes_by_elements(element1: String, element2: String) -> Array[FusionRecipeData]:
	var recipes: Array[FusionRecipeData] = []
	for recipe in FUSION_RECIPES:
		if (recipe.element1 == element1 and recipe.element2 == element2) or \
		   (recipe.element1 == element2 and recipe.element2 == element1):
			recipes.append(recipe)
	return recipes

## 检查融合条件
static func check_fusion_availability(spells: Array[BaseSpell]) -> Array[FusionRecipeData]:
	var available: Array[FusionRecipeData] = []
	
	# 获取当前装备的法术ID
	var equipped_spell_ids: Array[String] = []
	for spell in spells:
		if spell:
			equipped_spell_ids.append(spell.id if spell.has_method("get_id") else "")
	
	# 检查每个配方
	for recipe in FUSION_RECIPES:
		# 检查是否满足条件
		if recipe.required_spell1 in equipped_spell_ids and recipe.required_spell2 in equipped_spell_ids:
			available.append(recipe)
	
	return available