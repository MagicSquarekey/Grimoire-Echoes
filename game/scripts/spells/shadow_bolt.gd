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
	mana_cost = 0.0  # 自动战斗法术不消耗法力

## 重写施放：朝目标方向发射（不依赖鼠标——auto_cast 传目标坐标）
func _on_cast(target = null) -> void:
	var target_pos := Vector2.ZERO
	if target is Vector2:
		target_pos = target
	elif target is Node2D and is_instance_valid(target):
		target_pos = target.global_position
	else:
		target_pos = global_position + Vector2(100, 0)
	var dir := global_position.direction_to(target_pos)
	if dir.length_squared() < 0.5:
		dir = Vector2.RIGHT

	_cast_projectile_targeted(dir)

## 朝指定方向发射暗影弹
func _cast_projectile_targeted(dir: Vector2) -> void:
	var projectile = projectile_scene.instantiate()
	if projectile:
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position + dir * 14.0
		projectile.setup(
			_calculate_damage(),
			bolt_speed,
			dir,
			spell_element,
			0,  # 穿透
			0,  # 击退
			spell_level,
			owner_node
		)

## 重写法术升级
func _on_upgrade() -> void:
	bolt_damage *= 1.08
	damage = bolt_damage  # 同步到基类伤害字段（结算走 damage）
	
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