## FusionSpell - 融合法术基类
## 所有融合法术的基础实现
class_name FusionSpell
extends BaseSpell

# 融合属性
@export var fusion_recipe_id = ""
@export var element1 = ""
@export var element2 = ""
@export var required_spell1 = ""
@export var required_spell2 = ""

# 融合等级计算
var fusion_level = 0:
	get:
		return spell_level

# 融合加成计算
var fusion_bonus = 0.0:
	get:
		if fusion_level <= 10:
			return 0.0
		elif fusion_level <= 20:
			return 0.20
		elif fusion_level <= 30:
			return 0.40
		else:
			return 0.60

# 融合被动解锁
var fusion_passive_unlocked = false:
	get:
		return fusion_level >= 21

# 融合源法术引用
var spell1 = null
var spell2 = null

func _init() -> void:
	spell_name = "融合法术"
	spell_element = "fusion"
	spell_type = SpellType.PROJECTILE
	damage = 50.0
	cooldown = 5.0
	mana_cost = 30.0

## 初始化融合法术
func setup_fusion(recipe_id: String, element_1: String, element_2: String, spell_1, spell_2) -> void:
	fusion_recipe_id = recipe_id
	element1 = element_1
	element2 = element_2
	spell1 = spell_1
	spell2 = spell_2
	
	_update_fusion_attributes()

## 更新融合属性
func _update_fusion_attributes() -> void:
	if spell1 and spell2:
		var base_dmg = (spell1.damage + spell2.damage) / 2.0
		damage = base_dmg * (1.0 + fusion_bonus)
		
		var base_cd = (spell1.cooldown + spell2.cooldown) / 2.0
		cooldown = base_cd * 0.8
		
		var base_mc = (spell1.mana_cost + spell2.mana_cost) * 0.6
		mana_cost = base_mc

## 重写施放逻辑
func _on_cast(target = null) -> void:
	_execute_fusion_cast(target)

## 执行融合施法逻辑（子类重写）
func _execute_fusion_cast(target = null) -> void:
	_create_fusion_projectile(target)

## 创建融合投射物
func _create_fusion_projectile(target) -> void:
	var projectile = Node2D.new()
	projectile.global_position = global_position
	
	var sprite = Sprite2D.new()
	sprite.modulate = _get_fusion_color()
	projectile.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	collision.shape = circle
	projectile.add_child(collision)
	
	get_tree().current_scene.add_child(projectile)
	
	_move_fusion_projectile(projectile, target)

## 获取融合颜色
func _get_fusion_color() -> Color:
	match element1 + "_" + element2:
		"fire_water": return Color(0.8, 0.4, 0.2)
		"fire_lightning": return Color(1.0, 0.6, 0.0)
		"fire_nature": return Color(0.8, 0.3, 0.1)
		"fire_shadow": return Color(0.5, 0.1, 0.3)
		"fire_air": return Color(1.0, 0.4, 0.0)
		"water_lightning": return Color(0.3, 0.6, 1.0)
		"water_nature": return Color(0.2, 0.8, 0.4)
		"water_shadow": return Color(0.3, 0.2, 0.5)
		"water_air": return Color(0.6, 0.8, 1.0)
		"lightning_nature": return Color(0.4, 0.8, 0.2)
		"lightning_shadow": return Color(0.4, 0.2, 0.6)
		"lightning_air": return Color(0.6, 0.8, 1.0)
		"nature_shadow": return Color(0.2, 0.4, 0.3)
		"nature_air": return Color(0.4, 0.8, 0.3)
		"shadow_air": return Color(0.3, 0.3, 0.5)
		_: return Color(1.0, 1.0, 1.0)

## 移动融合投射物
func _move_fusion_projectile(projectile: Node2D, target) -> void:
	var target_position = Vector2.ZERO
	if target:
		target_position = target.global_position
	elif owner_node:
		target_position = owner_node.global_position + Vector2(200, 0)
	
	var tween = projectile.create_tween()
	tween.tween_property(projectile, "global_position", target_position, 0.5)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	await tween.finished
	
	_trigger_fusion_effect(projectile.global_position)
	projectile.queue_free()

## 触发融合效果（子类重写）
func _trigger_fusion_effect(position: Vector2) -> void:
	_damage_enemies_in_range(position, 100.0)

## 范围伤害
func _damage_enemies_in_range(center: Vector2, radius: float) -> void:
	var enemies = _get_enemies_in_range(center, radius)
	for enemy in enemies:
		_apply_damage(enemy)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	
	match spell_level:
		5:
			print(spell_name + "升级: 融合效果增强")
		10:
			print(spell_name + "升级: 融合效果大幅增强")
		15:
			print(spell_name + "升级: 解锁融合被动")
