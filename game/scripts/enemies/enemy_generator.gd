## EnemyGenerator - 敌人生成器
## 根据敌人数据动态创建敌人资源
class_name EnemyGenerator
extends RefCounted

## 敌人数据表（字典格式，常量表达式）
## type: 0=NORMAL 1=RANGED 2=SPECIAL 3=SWARM 4=ELITE 5=BOSS
const ENEMY_DATA = [
	# 普通敌人 - 近战型
	{"id": "E1", "name": "暗影仆从", "desc": "直线追踪玩家，接触后近战攻击", "type": 0, "element": "shadow", "hp": 30.0, "dmg": 8.0, "speed": 120.0, "exp": 10, "gold": 1, "range": 50.0, "cooldown": 1.0, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E2", "name": "骷髅战士", "desc": "追踪玩家，死亡后分裂为2个小骷髅（尚未实现：无对应场景）", "type": 0, "element": "shadow", "hp": 50.0, "dmg": 12.0, "speed": 100.0, "exp": 15, "gold": 2, "range": 50.0, "cooldown": 1.0, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E3", "name": "石像鬼", "desc": "飞行单位，无视地形与身体阻挡；逼近后定身蓄力0.45s再直线俯冲撕咬", "type": 0, "element": "shadow", "hp": 80.0, "dmg": 18.0, "speed": 105.0, "exp": 20, "gold": 3, "range": 46.0, "cooldown": 1.0, "chase": 340.0, "abilities": ["俯冲"], "boss": false},
	{"id": "E4", "name": "暗影刺客", "desc": "极快突进到玩家身前重击1.5倍伤害，随后闪现退回240px外，3s一轮", "type": 0, "element": "shadow", "hp": 28.0, "dmg": 15.0, "speed": 210.0, "exp": 12, "gold": 2, "range": 44.0, "cooldown": 3.0, "chase": 340.0, "abilities": ["突进", "闪现脱离"], "boss": false},
	{"id": "E16", "name": "兽人勇士", "desc": "重甲近战：血厚、速度慢、伤害高，受击退只吃25%", "type": 0, "element": "fire", "hp": 120.0, "dmg": 18.0, "speed": 70.0, "exp": 30, "gold": 5, "range": 70.0, "cooldown": 1.2, "chase": 300.0, "abilities": ["击退抵抗"], "boss": false},
	{"id": "E17", "name": "恶魔猎犬", "desc": "极快冲锋怪，4-6只同侧狼群包(pack)涌入", "type": 0, "element": "shadow", "hp": 30.0, "dmg": 10.0, "speed": 240.0, "exp": 8, "gold": 1, "range": 45.0, "cooldown": 0.8, "chase": 320.0, "abilities": ["冲锋"], "boss": false},
	# 普通敌人 - 远程型
	{"id": "E5", "name": "骷髅法师", "desc": "保持距离，每2秒发射一枚暗影弹", "type": 1, "element": "shadow", "hp": 20.0, "dmg": 10.0, "speed": 60.0, "exp": 12, "gold": 2, "range": 200.0, "cooldown": 2.0, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E6", "name": "毒蛛女巫", "desc": "保持距离发射毒弹，命中叠加瘟疫（每0.75s一跳、最多5层）", "type": 1, "element": "nature", "hp": 25.0, "dmg": 6.0, "speed": 70.0, "exp": 15, "gold": 2, "range": 230.0, "cooldown": 1.9, "chase": 280.0, "abilities": ["中毒DoT"], "boss": false},
	{"id": "E7", "name": "雷电精灵", "desc": "浮空绕行，闪电串连最多2只导体友军后合并为一次高伤放电", "type": 1, "element": "lightning", "hp": 18.0, "dmg": 10.0, "speed": 130.0, "exp": 12, "gold": 2, "range": 260.0, "cooldown": 2.2, "chase": 320.0, "abilities": ["连锁闪电"], "boss": false},
	{"id": "E18", "name": "白骨射手", "desc": "远程物理：站桩放箭保持距离，被贴身时边射边退", "type": 1, "element": "air", "hp": 22.0, "dmg": 9.0, "speed": 95.0, "exp": 14, "gold": 2, "range": 270.0, "cooldown": 1.6, "chase": 300.0, "abilities": ["风筝"], "boss": false},
	# 普通敌人 - 特殊型
	{"id": "E8", "name": "自爆虫", "desc": "冲脸后点燃引信1.15s（地面预警环+高频闪橙），到时原地引爆；提前击杀可免爆", "type": 2, "element": "fire", "hp": 18.0, "dmg": 30.0, "speed": 150.0, "exp": 8, "gold": 1, "range": 78.0, "cooldown": 1.15, "chase": 320.0, "abilities": ["预警自爆"], "boss": false},
	{"id": "E9", "name": "治疗者", "desc": "不攻击玩家；每3秒治疗半径190内所有受伤友军5%生命上限，优先击杀目标", "type": 2, "element": "nature", "hp": 45.0, "dmg": 0.0, "speed": 105.0, "exp": 18, "gold": 3, "range": 190.0, "cooldown": 3.0, "chase": 360.0, "abilities": ["群体治疗"], "boss": false},
	{"id": "E10", "name": "护盾守卫", "desc": "缓慢重装；每4秒为半径175内友军挂吸收盾（单只上限=生命上限25%），盾先于生命承伤", "type": 2, "element": "water", "hp": 150.0, "dmg": 10.0, "speed": 62.0, "exp": 22, "gold": 4, "range": 175.0, "cooldown": 4.0, "chase": 320.0, "abilities": ["护盾光环"], "boss": false},
	# 普通敌人 - 群体型
	{"id": "E11", "name": "虫群", "desc": "大量出现，单个弱但数量多", "type": 3, "element": "nature", "hp": 10.0, "dmg": 3.0, "speed": 140.0, "exp": 5, "gold": 1, "range": 30.0, "cooldown": 1.0, "chase": 300.0, "abilities": [], "boss": false},
	{"id": "E12", "name": "蝙蝠群", "desc": "大量出现，会飞行；航线带正弦摆动，以 flight 阵型从空中宽扇区俯冲入场", "type": 3, "element": "air", "hp": 8.0, "dmg": 4.0, "speed": 165.0, "exp": 5, "gold": 1, "range": 34.0, "cooldown": 0.8, "chase": 320.0, "abilities": ["飞行", "摆动航线"], "boss": false},
	{"id": "E13", "name": "僵尸潮", "desc": "大量出现，移动慢但生命高；被击倒1.3s后以35%生命再爬起来一次（只结算一次击杀）", "type": 3, "element": "shadow", "hp": 45.0, "dmg": 7.0, "speed": 55.0, "exp": 8, "gold": 1, "range": 62.0, "cooldown": 1.5, "chase": 300.0, "abilities": ["假死复活"], "boss": false},
	# 精英敌人（天生精英：EnemySpawner 的随机精英槽不会再给它们叠 make_elite 倍率）
	{"id": "E14", "name": "暗影骑士", "desc": "精英近战；每5秒以自身放一道暗影冲击波环（0.6s紫色预警，扩散期间只命中一次）", "type": 4, "element": "shadow", "hp": 200.0, "dmg": 25.0, "speed": 100.0, "exp": 50, "gold": 10, "range": 66.0, "cooldown": 1.2, "chase": 380.0, "abilities": ["暗影冲击波"], "boss": false},
	{"id": "E15", "name": "元素领主", "desc": "精英法术；每3.4秒随机挑一种元素（火/水/雷/影）在玩家脚下预警后炸一圈AoE", "type": 4, "element": "fire", "hp": 250.0, "dmg": 30.0, "speed": 95.0, "exp": 60, "gold": 12, "range": 380.0, "cooldown": 3.4, "chase": 400.0, "abilities": ["随机元素AoE"], "boss": false},
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
