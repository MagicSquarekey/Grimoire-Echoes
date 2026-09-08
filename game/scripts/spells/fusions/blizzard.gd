## Blizzard - 暴风雪
## 水流+风暴融合：持续冰冻伤害并击退
class_name Blizzard
extends FusionSpell

# 暴风雪特有属性
@export var blizzard_radius: float = 160.0  # 暴风雪范围
@export var blizzard_duration: float = 5.0  # 持续时间
@export var freeze_damage_per_second: float = 10.0  # 每秒冰冻伤害
@export var knockback_force: float = 150.0  # 击退力
@export var freeze_chance: float = 0.3  # 冻结概率

func _init() -> void:
	spell_name = "暴风雪"
	spell_element = "fusion"
	spell_type = SpellType.AOE
	damage = 30.0
	cooldown = 8.0
	mana_cost = 32.0
	
	element1 = "water"
	element2 = "air"
	required_spell1 = "W3"
	required_spell2 = "A2"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	_create_blizzard(cast_position)

## 创建暴风雪
func _create_blizzard(position: Vector2) -> void:
	var blizzard_area = Area2D.new()
	blizzard_area.global_position = position
	
	# 碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = blizzard_radius
	collision.shape = circle
	blizzard_area.add_child(collision)
	
	blizzard_area.collision_layer = 0
	blizzard_area.collision_mask = 2
	
	get_tree().current_scene.add_child(blizzard_area)
	
	# 视觉效果
	_create_blizzard_visual(blizzard_area)
	
	# 持续效果
	_process_blizzard_effects(blizzard_area)
	
	# 销毁
	await get_tree().create_timer(blizzard_duration).timeout
	blizzard_area.queue_free()

## 创建视觉效果
func _create_blizzard_visual(area: Area2D) -> void:
	var sprite = Sprite2D.new()
	sprite.name = "BlizzardSprite"
	sprite.modulate = Color(0.6, 0.8, 1.0, 0.6)
	sprite.scale = Vector2(3.0, 3.0)
	area.add_child(sprite)
	
	var particles = GPUParticles2D.new()
	particles.name = "BlizzardParticles"
	particles.emitting = true
	particles.lifetime = blizzard_duration
	particles.amount = 25
	area.add_child(particles)

## 持续处理效果
func _process_blizzard_effects(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < blizzard_duration:
		await get_tree().create_timer(0.5).timeout
		elapsed += 0.5
		
		var enemies = _get_enemies_in_range(area.global_position, blizzard_radius)
		for enemy in enemies:
			# 冰冻伤害
			if enemy.has_method("take_damage"):
				enemy.take_damage(freeze_damage_per_second * 0.5, owner_node)
			
			# 击退效果
			if enemy is CharacterBody2D:
				var direction = (enemy.global_position - area.global_position).normalized()
				enemy.velocity += direction * knockback_force * 0.3
			
			# 随机冻结
			if enemy.has_method("apply_status_effect") and randf() < freeze_chance:
				enemy.apply_status_effect(
					StatusEffectSystem.EffectType.FREEZE,
					1.0,
					1.5
				)

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	_damage_enemies_in_range(position, blizzard_radius)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	
	match spell_level:
		5:
			blizzard_radius *= 1.2
			print("暴风雪升级: 范围增加")
		10:
			blizzard_duration += 1.0
			print("暴风雪升级: 持续时间增加")
		15:
			freeze_chance += 0.2
			print("暴风雪升级: 冻结概率增加")
