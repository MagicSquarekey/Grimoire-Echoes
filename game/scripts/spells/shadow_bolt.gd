## ShadowBolt - 暗影弹
## 暗影系投射物法术
class_name ShadowBolt
extends BaseSpell

# 暗影弹特有属性
@export var life_steal_percent: float = 0.05  # 吸取5%当前生命值
@export var bolt_speed: float = 350.0  # 暗影弹速度
@export var bolt_damage: float = 15.0  # 暗影弹伤害

# 投射物场景
var projectile_scene: PackedScene = preload("res://scenes/spells/projectile.tscn")

func _init() -> void:
	spell_name = "暗影弹"
	spell_element = "shadow"
	spell_type = SpellType.PROJECTILE
	damage = bolt_damage
	cooldown = 1.5
	mana_cost = 12.0

## 重写投射物创建
func _create_projectile() -> Node2D:
	var projectile = projectile_scene.instantiate()
	if projectile.has_method("setup"):
		projectile.setup(
			_calculate_damage(),
			bolt_speed,
			owner_node.global_position.direction_to(get_global_mouse_position()),
			"shadow",
			0,  # 穿透
			0,  # 击退
			spell_level,
			owner_node
		)
	return projectile

## 重写法术升级
func _on_upgrade() -> void:
	bolt_damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 吸取+3%
			life_steal_percent += 0.03
			print("暗影弹升级: 吸取效果增加")
		10:
			# Lv.10: 双暗影弹
			print("暗影弹升级: 变为双暗影弹")
		15:
			# Lv.15: 暗影分裂
			print("暗影弹升级: 暗影分裂")