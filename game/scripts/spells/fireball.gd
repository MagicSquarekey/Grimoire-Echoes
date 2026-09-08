## Fireball - 火球术
## 火焰系基础投射物法术
extends BaseSpell

# 火球特有属性
@export var explosion_radius: float = 50.0
@export var burn_damage: float = 5.0
@export var burn_duration: float = 3.0

# 投射物场景（延迟加载，避免缺失文件导致编译错误）
var projectile_scene: PackedScene = null

func _init() -> void:
	spell_name = "火球术"
	spell_element = "fire"
	spell_type = SpellType.PROJECTILE
	damage = 25.0
	cooldown = 1.2
	mana_cost = 10.0
	aoe_radius = 0.0

## 重写投射物创建
func _create_projectile() -> Node2D:
	if projectile_scene == null:
		# 回退：使用通用投射物
		var bolt = Node2D.new()
		return bolt
	var projectile = projectile_scene.instantiate()
	return projectile

## 重写法术升级
func _on_upgrade() -> void:
	# 基础伤害增长
	damage *= 1.08
	
	# 质变点效果
	match spell_level:
		5:
			# Lv.5: 爆炸范围+30%
			explosion_radius *= 1.3
			print("火球术升级: 爆炸范围增加30%")
		10:
			# Lv.10: 2连发（在投射物脚本中实现）
			print("火球术升级: 变为2连发")
		15:
			# Lv.15: 追踪弹（在投射物脚本中实现）
			print("火球术升级: 变为追踪弹")
		20:
			# Lv.20: 爆炸产生火焰余烬
			print("火球术升级: 爆炸产生火焰余烬")
