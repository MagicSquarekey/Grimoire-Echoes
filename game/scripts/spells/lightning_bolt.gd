## LightningBolt - 闪电箭
## 雷电系投射物法术
class_name LightningBolt
extends BaseSpell

# 闪电箭特有属性
@export var chain_count: int = 2  # 弹射数量
@export var chain_range: float = 150.0  # 弹射范围
@export var chain_damage_reduction: float = 0.2  # 弹射伤害递减20%
@export var chain_delay: float = 0.1  # 弹射延迟

# 投射物场景
var projectile_scene: PackedScene = preload("res://scenes/spells/projectile.tscn")

func _init() -> void:
	spell_name = "闪电箭"
	spell_element = "lightning"
	spell_type = SpellType.PROJECTILE
	damage = 20.0
	cooldown = 1.0
	mana_cost = 12.0

## 重写投射物创建
func _create_projectile() -> Node2D:
	var projectile = projectile_scene.instantiate()
	if projectile.has_method("setup"):
		projectile.setup(
			_calculate_damage(),
			400.0,  # 速度
			owner_node.global_position.direction_to(get_global_mouse_position()),
			"lightning",
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
			# Lv.5: 弹射+2
			chain_count += 2
			print("闪电箭升级: 弹射数量增加")
		10:
			# Lv.10: 弹射无递减
			chain_damage_reduction = 0.0
			print("闪电箭升级: 弹射无递减")
		15:
			# Lv.15: 闪电链扩散
			print("闪电箭升级: 闪电链扩散")