## FlameWave - 烈焰波
## 火焰系扇形法术：朝目标方向喷出锥形火浪，伤害+点燃（自动战斗版）
class_name FlameWave
extends BaseSpell

# 烈焰波特有属性
@export var wave_angle: float = 60.0  # 扇形角度
@export var wave_distance: float = 200.0  # 扇形距离
@export var burn_damage: float = 8.0  # 燃烧伤害
@export var burn_duration: float = 3.0  # 燃烧持续时间

func _init() -> void:
	spell_name = "烈焰波"
	spell_element = "fire"
	spell_type = SpellType.FAN
	damage = 30.0
	cooldown = 2.5
	mana_cost = 0.0  # 自动战斗法术不消耗法力

## 重写施放逻辑（target 可能是 Vector2 坐标）
func _on_cast(target = null) -> void:
	var dir := _cast_direction(target)
	var enemies := _get_enemies_in_fan(global_position, wave_distance, wave_angle, dir)

	for enemy in enemies:
		# 应用伤害
		_apply_damage(enemy)

		# 火星爆裂（fire 预设：橙红上飘）
		FxLib.element_burst(self, enemy.global_position, spell_element, 0.6)

		# 应用燃烧效果
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.BURN,
				burn_damage,
				burn_duration
			)

	# 锥形火浪视觉
	_spawn_cone_visual(dir)

## 施法方向：目标 → 最近敌人 → 面前
func _cast_direction(target = null) -> Vector2:
	var target_pos := Vector2.ZERO
	if target is Vector2:
		target_pos = target
	elif target is Node2D and is_instance_valid(target):
		target_pos = target.global_position
	else:
		var nearest: Node2D = null
		var best := INF
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.get("is_alive"):
				var d: float = global_position.distance_to(e.global_position)
				if d < best:
					best = d
					nearest = e
		target_pos = nearest.global_position if nearest else global_position + Vector2(100, 0)
	var to_target := target_pos - global_position
	return to_target.normalized() if to_target.length() > 1.0 else Vector2.RIGHT

## 锥形火浪视觉：扇形折线前推 + 火星上飘粒子
func _spawn_cone_visual(dir: Vector2) -> void:
	var col := FxLib.color_for("fire")
	var host := get_tree().current_scene
	if host == null:
		return

	var base_rot := dir.angle()
	var wave := Node2D.new()
	wave.rotation = base_rot
	wave.global_position = global_position
	host.add_child(wave)

	# 扇形火幕
	var fan := Line2D.new()
	fan.material = CanvasItemMaterial.new()
	fan.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fan.width = 26.0
	fan.modulate = Color(1.0, 0.55, 0.15, 0.8)
	var pts := PackedVector2Array()
	var half := deg_to_rad(wave_angle) * 0.5
	for i in range(6):
		var a := -half + (half * 2.0) * float(i) / 5.0  # 弧度制：-half → +half 均匀扫过
		pts.append(Vector2(cos(a), sin(a)) * wave_distance * (0.9 + 0.1 * float(i) / 5.0))
	fan.points = pts
	wave.add_child(fan)

	# 火星粒子（上飘）
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.lifetime = 0.45
	particles.amount = 16
	particles.initial_velocity_min = 90.0
	particles.initial_velocity_max = 200.0
	particles.gravity = Vector2(0, -85)
	particles.color = Color(col.r, col.g, col.b, 0.95)
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = wave_distance * 0.35
	particles.position = Vector2(wave_distance * 0.4, 0)
	wave.add_child(particles)

	var tw := wave.create_tween()
	tw.set_parallel(true)
	tw.tween_property(fan, "position", dir.rotated(-base_rot) * (wave_distance * 0.5), 0.28)
	tw.tween_property(wave, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(wave.queue_free)

## 获取扇形范围内的敌人
func _get_enemies_in_fan(center: Vector2, distance: float, angle: float, cast_direction: Vector2) -> Array[Node2D]:
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
			var angle_to_enemy = rad_to_deg(cast_direction.angle_to(enemy_direction))

			if abs(angle_to_enemy) <= angle / 2.0:
				enemies.append(collider)

	return enemies

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.08

	match spell_level:
		5:
			# Lv.5: 扇形角度+40%
			wave_angle *= 1.4
		10:
			pass  # 击退效果
		15:
			# Lv.15: 燃烧时间翻倍
			burn_duration *= 2.0
