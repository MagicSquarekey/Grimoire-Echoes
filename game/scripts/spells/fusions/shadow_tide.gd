## ShadowTide - 暗影潮汐
## 水流+暗影融合：暗影水波，吸取生命并减速
class_name ShadowTide
extends FusionSpell

# 暗影潮汐特有属性
@export var wave_radius: float = 130.0  # 波浪范围
@export var wave_speed: float = 300.0  # 波浪速度
@export var life_steal_percent: float = 0.20  # 生命偷取20%
@export var slow_amount: float = 0.35  # 减速35%
@export var slow_duration: float = 3.0  # 减速持续时间

func _init() -> void:
	spell_name = "暗影潮汐"
	spell_element = "fusion"
	spell_type = SpellType.AOE
	damage = 35.0
	cooldown = 7.0
	mana_cost = 28.0
	
	element1 = "water"
	element2 = "shadow"
	required_spell1 = "W1"
	required_spell2 = "D1"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_position = Vector2.ZERO
	if owner_node:
		cast_position = owner_node.global_position
	
	_create_shadow_tide(cast_position)

## 创建暗影潮汐
func _create_shadow_tide(position: Vector2) -> void:
	# 创建潮汐波
	var tide_area = Area2D.new()
	tide_area.global_position = position
	
	# 碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = wave_radius
	collision.shape = circle
	tide_area.add_child(collision)
	
	tide_area.collision_layer = 0
	tide_area.collision_mask = 2
	
	# 添加到场景
	get_tree().current_scene.add_child(tide_area)
	
	# 创建视觉效果
	_create_tide_visual(tide_area)
	
	# 处理效果
	_process_tide_effects(tide_area)
	
	# 销毁
	await get_tree().create_timer(2.0).timeout
	tide_area.queue_free()

## 创建视觉效果
func _create_tide_visual(area: Area2D) -> void:
	var sprite = Sprite2D.new()
	sprite.name = "ShadowTideSprite"
	sprite.modulate = Color(0.3, 0.2, 0.5, 0.7)
	sprite.scale = Vector2(2.5, 2.5)
	area.add_child(sprite)
	
	var particles = GPUParticles2D.new()
	particles.name = "ShadowTideParticles"
	particles.emitting = true
	particles.lifetime = 2.0
	particles.amount = 20
	area.add_child(particles)

## 处理效果
func _process_tide_effects(area: Area2D) -> void:
	var enemies = _get_enemies_in_range(area.global_position, wave_radius)
	var total_damage = 0.0
	
	for enemy in enemies:
		# 应用伤害
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, owner_node)
			total_damage += damage
		
		# 应用减速
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.SLOW,
				slow_amount,
				slow_duration
			)
	
	# 生命偷取
	if owner_node and total_damage > 0 and owner_node.has_method("heal"):
		var heal_amount = total_damage * life_steal_percent
		owner_node.heal(heal_amount)

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	_damage_enemies_in_range(position, wave_radius)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	
	match spell_level:
		5:
			wave_radius *= 1.2
			print("暗影潮汐升级: 范围增加")
		10:
			life_steal_percent += 0.05
			print("暗影潮汐升级: 生命偷取增加")
		15:
			slow_amount += 0.1
			print("暗影潮汐升级: 减速效果增强")
