## WaterBolt - 水弹
## 水流系基础投射物法术
class_name WaterBolt
extends BaseSpell

# 水弹特有属性
@export var slow_amount: float = 0.3  # 减速30%
@export var slow_duration: float = 3.0  # 减速持续3秒

# 投射物场景
var projectile_scene: PackedScene = preload("res://scenes/spells/projectile.tscn")

func _init() -> void:
	spell_name = "水弹"
	spell_element = "water"
	spell_type = SpellType.PROJECTILE
	damage = 15.0
	cooldown = 0.8
	mana_cost = 8.0

## 重写投射物创建
func _create_projectile() -> Node2D:
	var projectile = projectile_scene.instantiate()
	if projectile.has_method("setup"):
		projectile.setup(
			_calculate_damage(),
			400.0,  # 速度
			owner_node.global_position.direction_to(get_global_mouse_position()),
			"water",
			0,  # 穿透
			0,  # 击退
			spell_level,
			owner_node
		)
	return projectile

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 减速+15%
			slow_amount += 0.15
			print("水弹升级: 减速效果增加")
		10:
			# Lv.10: 3连发
			print("水弹升级: 变为3连发")
		15:
			# Lv.15: 冰冻效果
			print("水弹升级: 附加冰冻效果")
