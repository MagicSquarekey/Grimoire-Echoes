## Fireball - 火球术
## 火焰系投射物法术：朝目标发射火球，命中爆炸并点燃（自动战斗版，无鼠标依赖）
extends BaseSpell

const PROJ_SCENE := preload("res://scenes/spells/projectile.tscn")

# 火球特有属性
@export var explosion_radius: float = 50.0
@export var burn_damage: float = 5.0
@export var burn_duration: float = 3.0
@export var bolt_speed: float = 430.0

func _init() -> void:
	spell_name = "火球术"
	spell_element = "fire"
	spell_type = SpellType.PROJECTILE
	damage = 25.0
	cooldown = 1.2
	mana_cost = 0.0  # 自动战斗法术不消耗法力（与奥术飞弹一致）
	aoe_radius = 0.0

## 施放：朝目标方向发射火球
func _on_cast(target = null) -> void:
	var dir := _cast_direction(target)
	var projectile := PROJ_SCENE.instantiate()
	if projectile == null:
		return
	get_tree().current_scene.add_child(projectile)
	# 出生点略微前移，避免直接贴脸命中施法者身旁
	projectile.global_position = global_position + dir * 14.0
	projectile.setup(_calculate_damage(), bolt_speed, dir, spell_element, 0, 60.0, spell_level, owner_node)
	if projectile.has_node("Sprite2D"):
		var body := projectile.get_node("Sprite2D") as Sprite2D
		body.texture = load("res://assets/fx/spark.png")
		body.scale = Vector2(1.5, 1.5)
		body.modulate = Color(1.0, 0.62, 0.2)

## 施法方向：目标坐标 → 目标节点 → 最近敌人 → 面前
func _cast_direction(target = null) -> Vector2:
	var target_pos := Vector2.ZERO
	if target is Vector2:
		target_pos = target
	elif target is Node2D and is_instance_valid(target):
		target_pos = target.global_position
	elif owner_node is Node2D:
		var enemies := get_tree().get_nodes_in_group("enemies")
		var nearest: Node2D = null
		var best := INF
		for e in enemies:
			if is_instance_valid(e) and e.get("is_alive"):
				var d: float = (owner_node as Node2D).global_position.distance_to(e.global_position)
				if d < best:
					best = d
					nearest = e
		target_pos = nearest.global_position if nearest else (owner_node as Node2D).global_position + Vector2(100, 0)
	var to_target := target_pos - global_position
	return to_target.normalized() if to_target.length() > 1.0 else Vector2.RIGHT

## 重写法术升级
func _on_upgrade() -> void:
	# 基础伤害增长
	damage *= 1.08

	# 质变点效果
	match spell_level:
		5:
			# Lv.5: 爆炸范围+30%
			explosion_radius *= 1.3
		10:
			pass  # 2连发（投射物层实现）
		15:
			pass  # 追踪弹
		20:
			pass  # 爆炸余烬
