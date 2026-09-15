## TidalWave - 潮汐冲击
## 水流系扇形冲击波：朝目标方向推出一道水浪，伤害+击退+减速（自动战斗版）
class_name TidalWave
extends BaseSpell

# 潮汐冲击特有属性
@export var wave_angle: float = 90.0  # 扇形角度
@export var wave_distance: float = 250.0  # 冲击距离
@export var knockback_force: float = 300.0  # 击退力

func _init() -> void:
	spell_name = "潮汐冲击"
	spell_element = "water"
	spell_type = SpellType.WAVE
	damage = 35.0
	cooldown = 3.0
	mana_cost = 0.0  # 自动战斗法术不消耗法力

## 重写施放逻辑（target 可能是 Vector2 坐标）
func _on_cast(target = null) -> void:
	var cast_direction := _cast_direction(target)
	_create_wave_effect(cast_direction)

## 施法方向：目标 → 最近敌人 → 面前
func _cast_direction(target = null) -> Vector2:
	var target_pos := Vector2.ZERO
	if target is Vector2:
		target_pos = target
	elif target is Node2D and is_instance_valid(target):
		target_pos = target.global_position
	elif owner_node is Node2D:
		var nearest := _nearest_enemy((owner_node as Node2D).global_position)
		target_pos = nearest.global_position if nearest else (owner_node as Node2D).global_position + Vector2(100, 0)
	var origin: Vector2 = owner_node.global_position if owner_node is Node2D else global_position
	var to_target := target_pos - origin
	return to_target.normalized() if to_target.length() > 1.0 else Vector2.RIGHT

func _nearest_enemy(from: Vector2) -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.get("is_alive"):
			var d: float = from.distance_to(e.global_position)
			if d < best:
				best = d
				nearest = e
	return nearest

## 创建水浪效果
func _create_wave_effect(direction: Vector2) -> void:
	var origin: Vector2 = owner_node.global_position if owner_node is Node2D else global_position
	# 创建水浪区域
	var wave_area = Area2D.new()
	wave_area.global_position = origin
	wave_area.rotation = direction.angle()

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
	if is_instance_valid(wave_area):
		wave_area.queue_free()

## 创建水浪视觉效果：扇形水幕 + 青白水花粒子（水元素预设配色）
func _create_wave_visual(area: Area2D) -> void:
	var preset := FxLib.preset_for("water")
	var col: Color = preset["color"]

	# 扇形水幕（多段折线，加法混合）
	var fan := Line2D.new()
	fan.material = CanvasItemMaterial.new()
	fan.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fan.width = 34.0
	fan.modulate = Color(col.r, col.g, col.b, 0.75)
	var pts := PackedVector2Array()
	var half := deg_to_rad(wave_angle) * 0.5
	for i in range(7):
		var a := -half + (half * 2.0) * float(i) / 6.0  # 弧度制：-half → +half 均匀扫过
		pts.append(Vector2(cos(a), sin(a)) * wave_distance * (0.9 + 0.1 * float(i) / 6.0))
	fan.points = pts
	area.add_child(fan)

	# 水花粒子（一次性，放射状）
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.lifetime = 0.35
	particles.amount = 16
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 240.0
	particles.gravity = Vector2(0, 80)
	particles.color = Color(col.r, col.g, col.b, 0.9)
	particles.position = Vector2(wave_distance * 0.5, 0)
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = wave_distance * 0.28
	area.add_child(particles)

	# 水浪扩散动画：水幕向前推并淡出
	var tw := area.create_tween()
	tw.set_parallel(true)
	tw.tween_property(fan, "position", Vector2(wave_distance * 0.55, 0.0), 0.3)
	tw.tween_property(fan, "modulate:a", 0.0, 0.3)
	tw.tween_property(particles, "modulate:a", 0.0, 0.3)

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
		# 水花爆裂（水元素预设：青白碎片放射）
		FxLib.element_burst(self, enemy.global_position, spell_element, 0.7)

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
		10:
			pass  # 双重冲击
		15:
			pass  # 冲击波范围化
