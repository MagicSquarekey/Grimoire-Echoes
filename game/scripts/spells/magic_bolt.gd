## MagicBolt - 奥术飞弹
## 玩家初始法术：自动朝最近敌人发射魔法弹
extends BaseSpell

const BOLT_SCRIPT = preload("res://scripts/spells/magic_bolt_projectile.gd")

## 弹幕参数
var projectile_count = 1
var spread_angle = 14.0

func _init() -> void:
	spell_name = "奥术飞弹"
	spell_element = "arcane"
	spell_type = SpellType.PROJECTILE
	damage = 14.0  # 校准：以 5 波 Boss 战 60-90 秒为基准的单体输出
	cooldown = 0.8
	mana_cost = 0.0
	max_level = 20

## 施放：朝目标方向扇形发射飞弹
## 注意：target 可能是敌人节点，也可能是坐标（SpellCaster.auto_cast 传 Vector2）
func _on_cast(target = null) -> void:
	var target_pos = null
	if target != null:
		if target is Vector2:
			target_pos = target
		elif is_instance_valid(target):
			target_pos = target.global_position
	
	var dir = Vector2.RIGHT
	if target_pos != null:
		var to_target = target_pos - global_position
		if to_target.length() > 1.0:
			dir = to_target.normalized()
	
	for i in range(projectile_count):
		var offset = (i - (projectile_count - 1) * 0.5) * deg_to_rad(spread_angle)
		var bolt = BOLT_SCRIPT.new()
		bolt.direction = dir.rotated(offset)
		bolt.damage = _calculate_damage()
		bolt.caster = owner_node
		get_tree().current_scene.add_child(bolt)
		# 必须在 add_child 之后再设置位置，否则赋值会被丢弃(出生在0,0)
		bolt.global_position = global_position

## 升级：伤害提升
func _on_upgrade() -> void:
	damage *= 1.15
