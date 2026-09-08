## ShadowStorm - 暗影风暴
## 暗影+风暴融合：吸取生命并击退
class_name ShadowStorm
extends FusionSpell

# 暗影风暴特有属性
@export var storm_radius: float = 140.0  # 风暴范围
@export var storm_duration: float = 5.0  # 持续时间
@export var damage_per_second: float = 12.0  # 每秒伤害
@export var life_steal_percent: float = 0.15  # 生命偷取15%
@export var knockback_force: float = 160.0  # 击退力

func _init() -> void:
	spell_name = "暗影风暴"
	spell_element = "fusion"
	spell_type = SpellType.AOE
	damage = 40.0
	cooldown = 8.0
	mana_cost = 32.0
	
	element1 = "shadow"
	element2 = "air"
	required_spell1 = "D3"
	required_spell2 = "A2"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	_create_shadow_storm(cast_position)

## 创建暗影风暴
func _create_shadow_storm(position: Vector2) -> void:
	var storm_area = Area2D.new()
	storm_area.global_position = position
	
	# 碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = storm_radius
	collision.shape = circle
	storm_area.add_child(collision)
	
	storm_area.collision_layer = 0
	storm_area.collision_mask = 2
	
	get_tree().current_scene.add_child(storm_area)
	
	# 视觉效果
	_create_storm_visual(storm_area)
	
	# 持续效果
	_process_storm_effects(storm_area)
	
	# 销毁
	await get_tree().create_timer(storm_duration).timeout
	storm_area.queue_free()

## 创建视觉效果
func _create_storm_visual(area: Area2D) -> void:
	var sprite = Sprite2D.new()
	sprite.name = "ShadowStormSprite"
	sprite.modulate = Color(0.3, 0.3, 0.5, 0.6)
	sprite.scale = Vector2(2.8, 2.8)
	area.add_child(sprite)
	
	var particles = GPUParticles2D.new()
	particles.name = "ShadowStormParticles"
	particles.emitting = true
	particles.lifetime = storm_duration
	particles.amount = 25
	area.add_child(particles)

## 持续处理效果
func _process_storm_effects(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < storm_duration:
		await get_tree().create_timer(0.5).timeout
		elapsed += 0.5
		
		var enemies = _get_enemies_in_range(area.global_position, storm_radius)
		var total_damage = 0.0
		
		for enemy in enemies:
			# 造成伤害
			if enemy.has_method("take_damage"):
				var dmg = damage_per_second * 0.5
				enemy.take_damage(dmg, owner_node)
				total_damage += dmg
			
			# 击退效果
			if enemy is CharacterBody2D:
				var direction = (enemy.global_position - area.global_position).normalized()
				enemy.velocity += direction * knockback_force * 0.3
		
		# 生命偷取
		if owner_node and total_damage > 0 and owner_node.has_method("heal"):
			var heal_amount = total_damage * life_steal_percent
			owner_node.heal(heal_amount)

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	_damage_enemies_in_range(position, storm_radius)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	
	match spell_level:
		5:
			storm_radius *= 1.2
			print("暗影风暴升级: 范围增加")
		10:
			life_steal_percent += 0.05
			print("暗影风暴升级: 生命偷取增加")
		15:
			storm_duration += 1.0
			print("暗影风暴升级: 持续时间增加")
