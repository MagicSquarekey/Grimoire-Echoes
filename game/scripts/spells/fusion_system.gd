## FusionSystem - 元素融合系统
## 管理元素融合配方和融合法术
class_name FusionSystem
extends Node

## 融合配方表（15种组合，字典格式）
const FUSION_RECIPES = [
	{"id": "fusion_steam_blast", "name": "蒸汽爆炸", "desc": "高温蒸汽，持续伤害+降低视野", "e1": "fire", "e2": "water", "spells": ["F1", "W1"]},
	{"id": "fusion_thunderfire", "name": "雷火交加", "desc": "雷火弹，连锁电火花", "e1": "fire", "e2": "lightning", "spells": ["F1", "L1"]},
	{"id": "fusion_burning_vines", "name": "焚烧藤蔓", "desc": "燃烧藤蔓，缠绕敌人并造成持续燃烧", "e1": "fire", "e2": "nature", "spells": ["N1", "F2"]},
	{"id": "fusion_dark_flame", "name": "暗焰爆弹", "desc": "暗影火焰弹，吸取生命并造成燃烧", "e1": "fire", "e2": "shadow", "spells": ["D1", "F1"]},
	{"id": "fusion_fire_tornado", "name": "火焰旋风", "desc": "火焰旋风，将敌人拉入并燃烧", "e1": "fire", "e2": "air", "spells": ["F2", "A2"]},
	{"id": "fusion_frost_shock", "name": "冰雷爆裂", "desc": "冰冻闪电，冻结敌人并传导伤害", "e1": "water", "e2": "lightning", "spells": ["W1", "L1"]},
	{"id": "fusion_life_spring", "name": "生命之泉", "desc": "治愈之泉，持续治疗队友并减速敌人", "e1": "water", "e2": "nature", "spells": ["N2", "W1"]},
	{"id": "fusion_shadow_tide", "name": "暗影潮汐", "desc": "暗影水波，吸取生命并减速", "e1": "water", "e2": "shadow", "spells": ["D1", "W1"]},
	{"id": "fusion_blizzard", "name": "暴风雪", "desc": "暴风雪，持续冰冻伤害并击退", "e1": "water", "e2": "air", "spells": ["W3", "A2"]},
	{"id": "fusion_thunder_thorns", "name": "雷霆荆棘", "desc": "带电荆棘，缠绕敌人并持续放电", "e1": "lightning", "e2": "nature", "spells": ["N1", "L1"]},
	{"id": "fusion_shadow_lightning", "name": "暗影闪电", "desc": "暗影闪电，吸取生命并麻痹", "e1": "lightning", "e2": "shadow", "spells": ["D1", "L1"]},
	{"id": "fusion_storm_eye", "name": "风暴之眼", "desc": "角色周围召唤风暴，持续击退并麻痹", "e1": "lightning", "e2": "air", "spells": ["L2", "A2"]},
	{"id": "fusion_shadow_thorns", "name": "暗影荆棘", "desc": "暗影荆棘，缠绕敌人并吸取生命", "e1": "nature", "e2": "shadow", "spells": ["N1", "D1"]},
	{"id": "fusion_nature_storm", "name": "自然风暴", "desc": "自然风暴，造成范围伤害并召唤藤蔓守卫", "e1": "nature", "e2": "air", "spells": ["A2", "N4"]},
	{"id": "fusion_shadow_storm", "name": "暗影风暴", "desc": "暗影风暴，吸取生命并击退", "e1": "shadow", "e2": "air", "spells": ["D3", "A2"]},
]

## 融合法术脚本缓存
var _fusion_spell_scripts = {
	"fusion_steam_blast": preload("res://scripts/spells/fusions/steam_blast.gd"),
	"fusion_thunderfire": preload("res://scripts/spells/fusions/thunderfire.gd"),
	"fusion_burning_vines": preload("res://scripts/spells/fusions/burning_vines.gd"),
	"fusion_dark_flame": preload("res://scripts/spells/fusions/dark_flame.gd"),
	"fusion_fire_tornado": preload("res://scripts/spells/fusions/fire_tornado.gd"),
	"fusion_frost_shock": preload("res://scripts/spells/fusions/frost_shock.gd"),
	"fusion_life_spring": preload("res://scripts/spells/fusions/life_spring.gd"),
	"fusion_shadow_tide": preload("res://scripts/spells/fusions/shadow_tide.gd"),
	"fusion_blizzard": preload("res://scripts/spells/fusions/blizzard.gd"),
	"fusion_thunder_thorns": preload("res://scripts/spells/fusions/thunder_thorns.gd"),
	"fusion_shadow_lightning": preload("res://scripts/spells/fusions/shadow_lightning.gd"),
	"fusion_storm_eye": preload("res://scripts/spells/fusions/storm_eye.gd"),
	"fusion_shadow_thorns": preload("res://scripts/spells/fusions/shadow_thorns.gd"),
	"fusion_nature_storm": preload("res://scripts/spells/fusions/nature_storm.gd"),
	"fusion_shadow_storm": preload("res://scripts/spells/fusions/shadow_storm.gd"),
}

## 已解锁的融合
var unlocked_fusions = []

## 当前激活的融合
var active_fusion = null

## 检查是否满足融合条件
func check_fusion_availability(spells) -> Array:
	var available = []
	
	# 获取当前装备的法术ID
	var equipped_spell_ids = []
	for spell in spells:
		if spell:
			equipped_spell_ids.append(spell.id if spell.has_method("get_id") else "")
	
	# 检查每个配方
	for recipe in FUSION_RECIPES:
		if recipe["id"] in unlocked_fusions:
			continue
		
		var has_required = true
		for required_spell in recipe["spells"]:
			if required_spell not in equipped_spell_ids:
				has_required = false
				break
		
		if has_required:
			available.append(recipe)
	
	return available

## 激活融合法术
func activate_fusion(fusion_id: String) -> bool:
	var recipe = _get_recipe_by_id(fusion_id)
	if recipe == null:
		return false
	
	var fusion_spell = _create_fusion_spell(fusion_id)
	if fusion_spell == null:
		push_warning("Failed to create fusion spell: " + fusion_id)
		return false
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.add_child(fusion_spell)
		active_fusion = fusion_spell
	
	unlocked_fusions.append(fusion_id)
	EventBus.spell_fusion_unlocked.emit(fusion_id)
	return true

## 根据配方ID创建融合法术实例
func _create_fusion_spell(fusion_id: String):
	if not _fusion_spell_scripts.has(fusion_id):
		return null
	
	var script = _fusion_spell_scripts[fusion_id]
	if script == null:
		return null
	
	var spell = script.new()
	var recipe = _get_recipe_by_id(fusion_id)
	if recipe:
		spell.fusion_recipe_id = fusion_id
		spell.element1 = recipe["e1"]
		spell.element2 = recipe["e2"]
		spell.required_spell1 = recipe["spells"][0]
		spell.required_spell2 = recipe["spells"][1]
	
	return spell

## 获取配方
func _get_recipe_by_id(fusion_id: String):
	for recipe in FUSION_RECIPES:
		if recipe["id"] == fusion_id:
			return recipe
	return null

## 获取所有配方
func get_all_recipes() -> Array:
	return FUSION_RECIPES

## 获取已解锁配方
func get_unlocked_recipes() -> Array:
	var recipes = []
	for recipe in FUSION_RECIPES:
		if recipe["id"] in unlocked_fusions:
			recipes.append(recipe)
	return recipes

## 清除融合状态
func clear_fusion() -> void:
	if active_fusion and is_instance_valid(active_fusion):
		active_fusion.queue_free()
	active_fusion = null
