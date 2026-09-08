## WindBlade - 风刃
## 风暴系投射物法术
class_name WindBlade
extends BaseSpell

# 风刃特有属性
@export var pierce_count: int = 3  # 穿透数量
@export var blade_speed: float = 500.0  # 风刃速度
@export var blade_damage: float = 18.0  # 风刃伤害

# 投射物场景
var projectile_scene: PackedScene = preload("res://scenes/spells/projectile.tscn")

func _init() -> void:
	spell_name = "风刃"
	spell_element = "air"
	spell_type = SpellType.PROJECTILE
	damage = blade_damage
	cooldown = 0.6
	mana_cost = 8.0

## 重写投射物创建
func _create_projectile() -> Node2D:
	var projectile = projectile_scene.instantiate()
	if projectile.has_method("setup"):
		projectile.setup(
			_calculate_damage(),
			blade_speed,
			owner_node.global_position.direction_to(get_global_mouse_position()),
			"air",
			pierce_count,  # 穿透
			0,  # 击退
			spell_level,
			owner_node
		)
	return projectile

## 重写法术升级
func _on_upgrade() -> void:
	blade_damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 穿透+2
			pierce_count += 2
			print("风刃升级: 穿透数量增加")
		10:
			# Lv.10: 穿透+5
			pierce_count += 5
			print("风刃升级: 穿透数量大幅增加")
		15:
			# Lv.15: 风刃分裂
			print("风刃升级: 风刃分裂")