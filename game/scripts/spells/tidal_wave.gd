## TidalWave - 潮汐冲击
## 水流系冲击波法术
class_name TidalWave
extends BaseSpell

# 潮汐冲击特有属性
@export var wave_angle: float = 90.0  # 扇形角度
@export var wave_distance: float = 250.0  # 冲击距离
@export var knockback_force: float = 300.0  # 击退力
@export var wave_speed: float = 400.0  # 水浪速度

func _init() -> void:
	spell_name = "潮汐冲击"
	spell_element = "water"
	spell_type = SpellType.WAVE
	damage = 35.0
	cooldown = 3.0
	mana_cost = 15.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取施放方向
	var cast_direction = Vector2.RIGHT
	if owner_node:
		cast_direction = owner_node.global_position.direction_to(get_global_mouse_position())
	
	# 创建水浪效果
	_create_wave_effect(cast_direction)

## 创建水浪效果
func _create_wave_effect(direction: Vector2) -> void:
	# 创建水浪区域
	var wave_area = Area2D.new()
	wave_area.global_position = owner_node.global_position
	wave_area.rotation = direction.angle()
	
	# 添加碰撞形状（扇形）
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = wave_distance
	collision.shape = circle
	wave_area.add_child(collision)
	
	# 设置碰撞层
	wave_area.collision_layer = 0
	wave_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(wave_area)
	
	# 创建视觉效果
	_create_wave_visual(wave_area)
	
	# 处理伤害和击退
	_process_wave_damage(wave_area, direction)
	
	# 延迟销毁
	await get_tree().create_timer(0.3).timeout
	wave_area.queue_free()

## 创建水浪视觉效果
func _create_wave_visual(area: Area2D) -> void:
	# 创建水浪精灵
	var wave_sprite = Sprite2D.new()
	wave_sprite.modulate = Color(0.3, 0.7, 1.0, 0.7)  # 浅蓝色
	wave_sprite.scale = Vector2(2.0, 1.0)  # 扁平化
	area.add_child(wave_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.lifetime = 0.3
	particles.amount = 15
	area.add_child(particles)

## 处理水浪伤害和击退
func _process_wave_damage(area: Area2D, direction: Vector2) -> void:
	# 获取范围内的敌人
	var enemies = _get_enemies_in_fan(area.global_position, wave_distance, wave_angle, direction)
	
	for enemy in enemies:
		# 应用伤害
		_apply_damage(enemy)
		
		# 应用击退效果
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(direction, knockback_force)
		
		# 应用减速效果
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.SLOW,
				0.3,  # 30%减速
				2.0
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
	damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 扇形+30%
			wave_angle *= 1.3
			print("潮汐冲击升级: 扇形角度增加")
		10:
			# Lv.10: 双重冲击
			print("潮汐冲击升级: 变为双重冲击")
		15:
			# Lv.15: 冲击波范围化
			print("潮汐冲击升级: 冲击波范围化")