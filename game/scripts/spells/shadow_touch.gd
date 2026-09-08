## ShadowTouch - 暗影之触
## 暗影系近战法术
class_name ShadowTouch
extends BaseSpell

# 暗影之触特有属性
@export var touch_range: float = 150.0  # 触手范围
@export var touch_angle: float = 90.0  # 触手角度
@export var damage_reduction: float = 0.2  # 攻击力降低20%
@export var reduction_duration: float = 4.0  # 降低持续时间
@export var touch_damage: float = 30.0  # 触手伤害

func _init() -> void:
	spell_name = "暗影之触"
	spell_element = "shadow"
	spell_type = SpellType.MELEE
	damage = touch_damage
	cooldown = 3.0
	mana_cost = 15.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取施放方向
	var cast_direction = Vector2.RIGHT
	if owner_node:
		cast_direction = owner_node.global_position.direction_to(get_global_mouse_position())
	
	# 创建暗影触手效果
	_create_shadow_touch_effect(cast_direction)

## 创建暗影触手效果
func _create_shadow_touch_effect(direction: Vector2) -> void:
	# 创建触手区域
	var touch_area = Area2D.new()
	touch_area.global_position = owner_node.global_position
	touch_area.rotation = direction.angle()
	
	# 添加碰撞形状（扇形）
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = touch_range
	collision.shape = circle
	touch_area.add_child(collision)
	
	# 设置碰撞层
	touch_area.collision_layer = 0
	touch_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(touch_area)
	
	# 创建视觉效果
	_create_touch_visual(touch_area)
	
	# 处理伤害和减益效果
	_process_touch_damage(touch_area, direction)
	
	# 延迟销毁
	await get_tree().create_timer(0.3).timeout
	touch_area.queue_free()

## 创建触手视觉效果
func _create_touch_visual(area: Area2D) -> void:
	# 创建触手精灵
	var touch_sprite = Sprite2D.new()
	touch_sprite.modulate = Color(0.3, 0.0, 0.5, 0.7)  # 深紫色
	touch_sprite.scale = Vector2(2.0, 1.0)  # 长条形
	area.add_child(touch_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.lifetime = 0.3
	particles.amount = 15
	area.add_child(particles)

## 处理触手伤害和减益效果
func _process_touch_damage(area: Area2D, direction: Vector2) -> void:
	# 获取范围内的敌人
	var enemies = _get_enemies_in_fan(area.global_position, touch_range, touch_angle, direction)
	
	for enemy in enemies:
		# 应用伤害
		_apply_damage(enemy)
		
		# 应用攻击力降低效果
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.ATTACK_DOWN,
				damage_reduction,
				reduction_duration
			)

## 获取扇形范围内的敌人
func _get_enemies_in_fan(center: Vector2, distance: float, angle: float, direction: Vector2) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = distance
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, center)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			# 检查是否在扇形角度内
			var enemy_direction = center.direction_to(collider.global_position)
			var angle_to_enemy = rad_to_deg(direction.angle_to(enemy_direction))
			
			if abs(angle_to_enemy) <= angle / 2.0:
				enemies.append(collider)
	
	return enemies

## 重写法术升级
func _on_upgrade() -> void:
	touch_damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 攻击降低+10%
			damage_reduction += 0.1
			print("暗影之触升级: 攻击力降低增加")
		10:
			# Lv.10: 双触手
			print("暗影之触升级: 变为双触手")
		15:
			# Lv.15: 暗影爆发
			print("暗影之触升级: 暗影爆发")