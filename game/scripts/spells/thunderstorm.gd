## Thunderstorm - 雷暴领域
## 雷电系持续AoE法术
class_name Thunderstorm
extends AoESpell

# 雷暴领域特有属性
@export var storm_duration: float = 4.0  # 持续时间
@export var strike_interval: float = 0.8  # 打击间隔
@export var strike_damage: float = 15.0  # 每次打击伤害
@export var storm_radius: float = 120.0  # 雷暴范围
@export var stun_chance: float = 0.15  # 麻痹概率15%

func _init() -> void:
	spell_name = "雷暴领域"
	spell_element = "lightning"
	spell_type = SpellType.GROUND_AOE
	damage = strike_damage
	cooldown = 10.0
	mana_cost = 0.0  # 自动战斗法术不消耗法力
	aoe_radius = storm_radius

## 重写施放逻辑（target 可能是 Vector2 坐标）
func _on_cast(target = null) -> void:
	var cast_position := _resolve_cast_position(target)

	# 创建雷暴领域
	_create_thunderstorm(cast_position)

## 创建雷暴领域
func _create_thunderstorm(position: Vector2) -> void:
	# 创建雷暴区域
	var storm_area = Area2D.new()
	storm_area.global_position = position

	# 设置碰撞层
	storm_area.collision_layer = 0
	storm_area.collision_mask = 2  # 敌人层

	# 添加到场景
	get_tree().current_scene.add_child(storm_area)

	# 创建视觉效果
	_create_storm_visual(storm_area)

	# 持续打击敌人
	_process_storm_damage(storm_area)

	# 持续时间结束后销毁
	await get_tree().create_timer(storm_duration).timeout
	if is_instance_valid(storm_area):
		storm_area.queue_free()

## 创建雷暴视觉效果：领域电云光斑 + 电弧粒子（lightning 预设）
func _create_storm_visual(area: Area2D) -> void:
	var col := FxLib.color_for("lightning")

	# 领域电云（柔光斑脉动）
	var cloud := Sprite2D.new()
	cloud.texture = load("res://assets/fx/glow_soft.png")
	cloud.material = CanvasItemMaterial.new()
	cloud.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	cloud.modulate = Color(col.r, col.g, col.b, 0.35)
	cloud.scale = Vector2.ONE * (storm_radius / 24.0)
	area.add_child(cloud)
	var tw := cloud.create_tween()
	tw.set_loops()
	tw.tween_property(cloud, "modulate:a", 0.18, 0.35)
	tw.tween_property(cloud, "modulate:a", 0.4, 0.35)

	# 抖动电花粒子（短寿命高阻尼 → 闪烁感）
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 12
	particles.lifetime = 0.3
	particles.initial_velocity_min = 170.0
	particles.initial_velocity_max = 270.0
	particles.damping_min = 420.0
	particles.damping_max = 420.0
	particles.color = Color(col.r, col.g, col.b, 0.95)
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = storm_radius * 0.6
	area.add_child(particles)

## 持续打击敌人
func _process_storm_damage(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < storm_duration:
		# 等待打击间隔
		await get_tree().create_timer(strike_interval).timeout
		elapsed += strike_interval

		# 区域可能已随场景销毁
		if not is_instance_valid(area) or not is_inside_tree():
			return

		# 获取范围内的敌人
		var enemies = _get_enemies_in_aoe(area.global_position, storm_radius)

		if enemies.size() > 0:
			# 随机选择一个敌人进行打击
			var random_enemy = enemies[randi() % enemies.size()]

			# 应用伤害
			_apply_damage(random_enemy)

			# 概率麻痹
			if randf() < stun_chance:
				if random_enemy.has_method("apply_status_effect"):
					random_enemy.apply_status_effect(
						StatusEffectSystem.EffectType.STUN,
						0.0,
						1.0  # 麻痹1秒
					)

			# 创建落雷视觉效果
			_create_lightning_visual(area.global_position + Vector2(0, -160), random_enemy.global_position)

## 创建落雷视觉效果：天降锯齿闪线 + 命中闪爆（lightning 预设）
func _create_lightning_visual(from: Vector2, to: Vector2) -> void:
	var preset := FxLib.preset_for("lightning")
	var col: Color = preset["color"]

	var bolt := Line2D.new()
	bolt.material = CanvasItemMaterial.new()
	bolt.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	bolt.width = 6.0
	bolt.modulate = Color(col.r, col.g, col.b, 0.95)
	bolt.joint_mode = Line2D.LINE_JOINT_ROUND
	var seg := maxi(4, int(from.distance_to(to) / 30.0))
	var pts := PackedVector2Array()
	var dir := (to - from) / float(seg)
	var normal := dir.normalized().orthogonal()
	for i in range(seg + 1):
		var p := dir * float(i)
		if i > 0 and i < seg:
			p += normal * randf_range(-14.0, 14.0)
		pts.append(p)
	bolt.points = pts
	bolt.global_position = from
	get_tree().current_scene.add_child(bolt)

	var tw := bolt.create_tween()
	for _i in range(3):
		tw.tween_callback(_jitter_bolt.bind(bolt))
		tw.tween_interval(0.03)
	tw.tween_property(bolt, "modulate:a", 0.0, 0.04)
	tw.tween_callback(bolt.queue_free)

	# 命中闪爆
	FxLib.element_burst(self, to, spell_element, 0.6)

## 闪电锯齿重抖一帧
func _jitter_bolt(bolt: Line2D) -> void:
	if not is_instance_valid(bolt) or bolt.points.size() < 3:
		return
	var pts := bolt.points
	for i in range(1, pts.size() - 1):
		pts[i] += Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
	bolt.points = pts

## 重写法术升级
func _on_upgrade() -> void:
	strike_damage *= 1.08
	damage = strike_damage  # 同步到基类伤害字段（结算走 damage）

	match spell_level:
		5:
			# Lv.5: 持续+2秒
			storm_duration += 2.0
		10:
			# Lv.10: 打击频率翻倍
			strike_interval /= 2.0
		15:
			pass  # 雷暴追踪