## RelicGenerator - 遗物生成器
## 根据遗物数据动态创建遗物资源
class_name RelicGenerator
extends RefCounted

## 遗物数据表（30个遗物，字典格式）
## quality: 0=普通 1=稀有 2=传说
## effect: 对应 RelicResource.RelicEffectType
const RELIC_DATA = [
	# 普通遗物（12个）
	{"id": "R1", "name": "魔力水晶", "desc": "最大法力+20%", "quality": 0, "effect": 0, "value": 0.20, "target": "max_mana", "stacks": 5},
	{"id": "R2", "name": "生命之种", "desc": "最大生命+15%", "quality": 0, "effect": 0, "value": 0.15, "target": "max_health", "stacks": 5},
	{"id": "R3", "name": "疾风之靴", "desc": "移动速度+10%", "quality": 0, "effect": 0, "value": 0.10, "target": "move_speed", "stacks": 5},
	{"id": "R4", "name": "火焰徽记", "desc": "火焰法术伤害+8%", "quality": 0, "effect": 1, "value": 0.08, "target": "fire", "stacks": 5},
	{"id": "R5", "name": "冰霜徽记", "desc": "水流法术伤害+8%", "quality": 0, "effect": 1, "value": 0.08, "target": "water", "stacks": 5},
	{"id": "R6", "name": "雷电徽记", "desc": "雷电法术伤害+8%", "quality": 0, "effect": 1, "value": 0.08, "target": "lightning", "stacks": 5},
	{"id": "R7", "name": "自然徽记", "desc": "自然法术伤害+8%", "quality": 0, "effect": 1, "value": 0.08, "target": "nature", "stacks": 5},
	{"id": "R8", "name": "暗影徽记", "desc": "暗影法术伤害+8%", "quality": 0, "effect": 1, "value": 0.08, "target": "shadow", "stacks": 5},
	{"id": "R9", "name": "风暴徽记", "desc": "风暴法术伤害+8%", "quality": 0, "effect": 1, "value": 0.08, "target": "air", "stacks": 5},
	{"id": "R10", "name": "经验宝石", "desc": "经验获取+15%", "quality": 0, "effect": 0, "value": 0.15, "target": "exp_gain", "stacks": 5},
	{"id": "R11", "name": "幸运护符", "desc": "稀有掉落率+8%", "quality": 0, "effect": 0, "value": 0.08, "target": "rare_drop_rate", "stacks": 5},
	{"id": "R12", "name": "护盾碎片", "desc": "护盾值+15%", "quality": 0, "effect": 0, "value": 0.15, "target": "shield_value", "stacks": 5},
	# 稀有遗物（12个）
	{"id": "R13", "name": "元素之心", "desc": "所有元素伤害+12%", "quality": 1, "effect": 1, "value": 0.12, "target": "all_elements", "stacks": 3},
	{"id": "R14", "name": "时间沙漏", "desc": "冷却恢复速度+15%", "quality": 1, "effect": 2, "value": 0.15, "target": "cooldown_recovery", "stacks": 3},
	{"id": "R15", "name": "生命之泉", "desc": "每秒恢复2%最大生命", "quality": 1, "effect": 5, "value": 0.02, "target": "health_regen_percent", "stacks": 3},
	{"id": "R16", "name": "暴击之眼", "desc": "暴击率+10%", "quality": 1, "effect": 4, "value": 0.10, "target": "crit_rate", "stacks": 3},
	{"id": "R17", "name": "双重施法", "desc": "15%几率法术释放两次", "quality": 1, "effect": 5, "value": 0.15, "target": "double_cast_chance", "stacks": 3},
	{"id": "R18", "name": "元素融合石", "desc": "融合法术伤害+20%", "quality": 1, "effect": 1, "value": 0.20, "target": "fusion", "stacks": 3},
	{"id": "R19", "name": "吸血之牙", "desc": "造成伤害的5%转化为生命", "quality": 1, "effect": 3, "value": 0.05, "target": "damage", "stacks": 3},
	{"id": "R20", "name": "幻影之靴", "desc": "移动速度+20%", "quality": 1, "effect": 0, "value": 0.20, "target": "move_speed", "stacks": 3},
	{"id": "R21", "name": "法力涌泉", "desc": "每秒恢复3%最大法力", "quality": 1, "effect": 5, "value": 0.03, "target": "mana_regen_percent", "stacks": 3},
	{"id": "R22", "name": "荆棘之甲", "desc": "受到近战伤害时反弹15%伤害", "quality": 1, "effect": 5, "value": 0.15, "target": "damage_reflect", "stacks": 3},
	{"id": "R23", "name": "连锁反应", "desc": "连锁法术连锁数+2", "quality": 1, "effect": 5, "value": 2.0, "target": "chain_count", "stacks": 3},
	{"id": "R24", "name": "召唤大师", "desc": "召唤物伤害和持续时间+25%", "quality": 1, "effect": 1, "value": 0.25, "target": "summon", "stacks": 3},
	# 传说遗物（6个）
	{"id": "R25", "name": "凤凰之羽", "desc": "死亡时复活一次（恢复50%生命）", "quality": 2, "effect": 5, "value": 0.50, "target": "revive_health", "stacks": 1},
	{"id": "R26", "name": "时空扭曲", "desc": "所有冷却时间-25%", "quality": 2, "effect": 2, "value": 0.25, "target": "all_cooldowns", "stacks": 1},
	{"id": "R27", "name": "元素洪流", "desc": "所有元素伤害+25%", "quality": 2, "effect": 1, "value": 0.25, "target": "all_elements", "stacks": 1},
	{"id": "R28", "name": "暗影之心", "desc": "造成伤害的8%转化为生命", "quality": 2, "effect": 3, "value": 0.08, "target": "damage", "stacks": 1},
	{"id": "R29", "name": "命运之轮", "desc": "升级时从4个选项中选择", "quality": 2, "effect": 5, "value": 0.50, "target": "upgrade_choices", "stacks": 1},
	{"id": "R30", "name": "终极法典", "desc": "所有法术等级+2", "quality": 2, "effect": 5, "value": 2.0, "target": "spell_level_bonus", "stacks": 1},
]

## 创建遗物资源
static func create_relic(relic_id: String):
	var data = _get_relic_data_by_id(relic_id)
	if data == null:
		push_warning("Relic data not found: " + relic_id)
		return null
	
	var relic = RelicResource.new()
	relic.id = data["id"]
	relic.name = data["name"]
	relic.description = data["desc"]
	relic.quality = data["quality"]
	relic.effect_type = data["effect"]
	relic.effect_value = data["value"]
	relic.effect_target = data["target"]
	relic.max_stacks = data["stacks"]
	relic.stackable = data["stacks"] > 1
	
	return relic

## 获取遗物数据
static func _get_relic_data_by_id(relic_id: String):
	for data in RELIC_DATA:
		if data["id"] == relic_id:
			return data
	return null

## 获取所有遗物数据
static func get_all_relic_data() -> Array:
	return RELIC_DATA

## 根据品质获取遗物数据
static func get_relic_data_by_quality(quality: int) -> Array:
	var result = []
	for data in RELIC_DATA:
		if data["quality"] == quality:
			result.append(data)
	return result

## 随机获取一个遗物数据
static func get_random_relic_data(quality: int = 0):
	var available = []
	for data in RELIC_DATA:
		if data["quality"] == quality:
			available.append(data)
	
	if available.size() == 0:
		return null
	
	return available[randi() % available.size()]
