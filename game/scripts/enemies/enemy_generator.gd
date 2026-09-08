## EnemyGenerator - 敌人生成器
## 根据敌人数据动态创建敌人资源
class_name EnemyGenerator
extends RefCounted

## 敌人数据表（字典格式，常量表达式）
## type: 0=NORMAL 1=RANGED 2=SPECIAL 3=SWARM 4=ELITE 5=BOSS
const ENEMY_DATA = [
	# 普通敌人 - 近战型
	{"id": "E1", "name": "暗影仆从", "desc": "直线追踪玩家，接触后近战攻击", "type": 0, "element": "shadow", "hp": 30.0, "dmg": 8.0, "speed": 120.0, "exp": 10, "gold": 1, "range": 50.0, "cooldown": 1.0, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E2", "name": "骷髅战士", "desc": "追踪玩家，死亡后分裂为2个小骷髅", "type": 0, "element": "shadow", "hp": 50.0, "dmg": 12.0, "speed": 100.0, "exp": 15, "gold": 2, "range": 50.0, "cooldown": 1.0, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E3", "name": "石像鬼", "desc": "追踪玩家，攻击时静止1秒", "type": 0, "element": "shadow", "hp": 80.0, "dmg": 18.0, "speed": 80.0, "exp": 20, "gold": 3, "range": 50.0, "cooldown": 1.0, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E4", "name": "暗影刺客", "desc": "快速追踪玩家，攻击后后退", "type": 0, "element": "shadow", "hp": 25.0, "dmg": 15.0, "speed": 150.0, "exp": 12, "gold": 2, "range": 50.0, "cooldown": 1.0, "chase": 300.0, "abilities": [], "boss": false},
	# 普通敌人 - 远程型
	{"id": "E5", "name": "骷髅法师", "desc": "保持距离，每2秒发射一枚暗影弹", "type": 1, "element": "shadow", "hp": 20.0, "dmg": 10.0, "speed": 60.0, "exp": 12, "gold": 2, "range": 200.0, "cooldown": 2.0, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E6", "name": "毒蛛女巫", "desc": "保持距离，发射毒弹，命中后持续掉血", "type": 1, "element": "nature", "hp": 25.0, "dmg": 6.0, "speed": 60.0, "exp": 15, "gold": 2, "range": 200.0, "cooldown": 1.5, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E7", "name": "雷电精灵", "desc": "保持距离，发射连锁闪电，连锁2个目标", "type": 1, "element": "lightning", "hp": 15.0, "dmg": 8.0, "speed": 130.0, "exp": 12, "gold": 2, "range": 250.0, "cooldown": 1.8, "chase": 300.0, "abilities": [], "boss": false},
	# 普通敌人 - 特殊型
	{"id": "E8", "name": "自爆虫", "desc": "快速追踪玩家，接近后3秒自爆", "type": 2, "element": "fire", "hp": 15.0, "dmg": 30.0, "speed": 140.0, "exp": 8, "gold": 1, "range": 50.0, "cooldown": 3.0, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E9", "name": "治疗者", "desc": "追踪队友，每3秒治疗附近敌人5%生命", "type": 2, "element": "nature", "hp": 30.0, "dmg": 0.0, "speed": 100.0, "exp": 15, "gold": 2, "range": 100.0, "cooldown": 3.0, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E10", "name": "护盾守卫", "desc": "追踪玩家，为周围敌人提供护盾", "type": 2, "element": "water", "hp": 40.0, "dmg": 5.0, "speed": 80.0, "exp": 18, "gold": 3, "range": 100.0, "cooldown": 2.0, "chase": 300.0, "abilities": [], "boss": false},
	# 普通敌人 - 群体型
	{"id": "E11", "name": "虫群", "desc": "大量出现，单个弱但数量多", "type": 3, "element": "nature", "hp": 10.0, "dmg": 3.0, "speed": 140.0, "exp": 5, "gold": 1, "range": 30.0, "cooldown": 1.0, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E12", "name": "蝙蝠群", "desc": "大量出现，会飞行，从空中攻击", "type": 3, "element": "air", "hp": 8.0, "dmg": 4.0, "speed": 150.0, "exp": 5, "gold": 1, "range": 30.0, "cooldown": 0.8, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E13", "name": "僵尸潮", "desc": "大量出现，移动慢但生命高", "type": 3, "element": "shadow", "hp": 25.0, "dmg": 6.0, "speed": 60.0, "exp": 8, "gold": 1, "range": 50.0, "cooldown": 1.5, "chase": 300.0, "abilities": [], "boss": false},
	# 精英敌人
	{"id": "E14", "name": "暗影骑士", "desc": "追踪玩家，每5秒释放暗影冲击波", "type": 4, "element": "shadow", "hp": 200.0, "dmg": 25.0, "speed": 100.0, "exp": 50, "gold": 10, "range": 80.0, "cooldown": 1.2, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E15", "name": "元素领主", "desc": "追踪玩家，每4秒释放对应元素AoE", "type": 4, "element": "fire", "hp": 250.0, "dmg": 30.0, "speed": 100.0, "exp": 60, "gold": 12, "range": 80.0, "cooldown": 1.5, "chase": 300.0, "abilities": [], "boss": false},
	# Boss
	{"id": "B1", "name": "熔岩巨人", "desc": "波次20/40/60出现的Boss", "type": 5, "element": "fire", "hp": 2000.0, "dmg": 25.0, "speed": 80.0, "exp": 200, "gold": 50, "range": 100.0, "cooldown": 2.0, "chase": 500.0, "abilities": ["踩踏", "熔岩弹", "岩浆池", "召唤"], "boss": true},
	{"id": "B2", "name": "暗影君主", "desc": "波次30/60/90出现的Boss", "type": 5, "element": "shadow", "hp": 3500.0, "dmg": 30.0, "speed": 120.0, "exp": 300, "gold": 80, "range": 100.0, "cooldown": 1.5, "chase": 600.0, "abilities": ["暗影传送", "暗影弹幕", "暗影旋风", "召唤仆从", "暗影波"], "boss": true},
	{"id": "B3", "name": "元素之王", "desc": "波次50/100/150出现的最终Boss", "type": 5, "element": "fire", "hp": 5000.0, "dmg": 35.0, "speed": 100.0, "exp": 500, "gold": 100, "range": 100.0, "cooldown": 1.0, "chase": 700.0, "abilities": ["火焰形态", "水流形态", "雷电形态", "暗影形态", "元素融合"], "boss": true},
]

## 创建敌人资源
static func create_enemy_resource(enemy_id: String):
	var data = _get_enemy_data_by_id(enemy_id)
	if data == null:
		push_warning("Enemy data not found: " + enemy_id)
		return null
	
	var resource = EnemyResource.new()
	resource.id = data["id"]
	resource.name = data["name"]
	resource.description = data["desc"]
	resource.type = data["type"]
	resource.element = data["element"]
	resource.max_health = data["hp"]
	resource.base_damage = data["dmg"]
	resource.move_speed = data["speed"]
	resource.exp_value = data["exp"]
	resource.gold_value = data["gold"]
	resource.attack_range = data["range"]
	resource.attack_cooldown = data["cooldown"]
	resource.chase_range = data["chase"]
	resource.is_boss = data["boss"]
	
	return resource

## 获取敌人数据
static func _get_enemy_data_by_id(enemy_id: String):
	for data in ENEMY_DATA:
		if data["id"] == enemy_id:
			return data
	return null

## 获取所有敌人数据
static func get_all_enemy_data() -> Array:
	return ENEMY_DATA

## 根据类型获取敌人数据
static func get_enemy_data_by_type(type: int) -> Array:
	var result = []
	for data in ENEMY_DATA:
		if data["type"] == type:
			result.append(data)
	return result

## 获取普通敌人数据
static func get_normal_enemy_data() -> Array:
	return get_enemy_data_by_type(0)

## 获取精英敌人数据
static func get_elite_enemy_data() -> Array:
	return get_enemy_data_by_type(4)

## 获取Boss数据
static func get_boss_data() -> Array:
	return get_enemy_data_by_type(5)

## 随机获取一个敌人数据
static func get_random_enemy_data(type: int = 0):
	var available = []
	for data in ENEMY_DATA:
		if data["type"] == type:
			available.append(data)
	
	if available.size() == 0:
		return null
	
	return available[randi() % available.size()]
