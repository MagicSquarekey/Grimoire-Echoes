## FireTornado - 火焰旋风
## 火焰+风暴融合：火焰旋风，将敌人拉入并燃烧
class_name FireTornado
extends FusionSpell

# 火焰旋风特有属性
@export var tornado_radius: float = 120.0  # 旋风范围
@export var tornado_duration: float = 5.0  # 持续时间
@export var pull_force: float = 200.0  # 拉扯力
@export var burn_damage_per_second: float = 10.0  # 每秒燃烧伤害
@export var rotation_speed: float = 3.0  # 旋转速度

func _init() -> void:
	spell_name = "火焰旋风"
	spell_element = "fusion"
	spell_type = SpellType.AOE
	damage = 50.0
	cooldown = 8.0
	mana_cost = 35.0
	
	# 融合属性
	element1 = "fire"
	element2 = "air"
	required_spell1 = "F2"
	required_spell2 = "A2"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	_create_fire_tornado(cast_position)

## 创建火焰旋风
func _create_fire_tornado(position: Vector2) -> void:
	# 创建旋风区域
	var tornado_area = Area2D.new()
	tornado_area.global_position = position
	
	# 碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = tornado_radius
	collision.shape = circle
	tornado_area.add_child(collision)
	
	# 设置碰撞层
	tornado_area.collision_layer = 0
	tornado_area.collision_mask = 2
	
	# 添加到场景
	get_tree().current_scene.add_child(tornado_area)
	
	# 创建视觉效果
	_create_tornado_visual(tornado_area)
	
	# 持续效果
	_process_tornado_effects(tornado_area)
	
	# 持续时间结束后销毁
	await get_tree().create_timer(tornado_duration).timeout
	tornado_area.queue_free()

## 创建旋风视觉效果
func _create_tornado_visual(area: Area2D) -> void:
	var sprite = Sprite2D.new()
	sprite.name = "FireTornadoSprite"
	sprite.modulate = Color(1.0, 0.4, 0.0, 0.7)
	sprite.scale = Vector2(2.5, 2.5)
	area.add_child(sprite)
	
	# 粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "FireTornadoParticles"
	particles.emitting = true
	particles.lifetime = tornado_duration
	particles.amount = 30
	area.add_child(particles)

## 持续处理旋风效果
func _process_tornado_effects(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < tornado_duration:
		await get_tree().create_timer(0.5).timeout
		elapsed += 0.5
		
		var enemies = _get_enemies_in_range(area.global_position, tornado_radius)
		for enemy in enemies:
			# 拉扯敌人向中心
			if enemy is CharacterBody2D:
				var direction = (area.global_position - enemy.global_position).normalized()
				enemy.velocity += direction * pull_force * 0.5
			
			# 应用燃烧伤害
			if enemy.has_method("take_damage"):
				enemy.take_damage(burn_damage_per_second * 0.5, owner_node)
			
			# 应用减速
			if enemy.has_method("apply_status_effect"):
				enemy.apply_status_effect(
					StatusEffectSystem.EffectType.SLOW,
					0.3,
					1.0
				)

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	_damage_enemies_in_range(position, tornado_radius)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	
	match spell_level:
		5:
			tornado_radius *= 1.2
			print("火焰旋风升级: 范围增加")
		10:
			tornado_duration += 1.0
			print("火焰旋风升级: 持续时间增加")
		15:
			pull_force *= 1.5
			print("火焰旋风升级: 拉扯力增强")
