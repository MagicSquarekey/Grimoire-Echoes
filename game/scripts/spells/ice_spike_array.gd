## IceSpikeArray - 冰锥阵列
## 水流系地面AoE法术
class_name IceSpikeArray
extends AoESpell

# 冰锥阵列特有属性
@export var spike_count: int = 4  # 冰锥数量
@export var spike_interval: float = 0.5  # 冰锥生成间隔
@export var array_duration: float = 3.0  # 持续时间
@export var slow_amount: float = 0.3  # 减速30%
@export var slow_duration: float = 2.0  # 减速持续时间

func _init() -> void:
	spell_name = "冰锥阵列"
	spell_element = "water"
	spell_type = SpellType.GROUND_AOE
	damage = 20.0
	cooldown = 5.0
	mana_cost = 0.0  # 自动战斗法术不消耗法力
	aoe_radius = 150.0

## 重写施放逻辑（target 可能是 Vector2 坐标）
func _on_cast(target = null) -> void:
	var cast_position := _resolve_cast_position(target)

	# 创建冰锥阵列
	_create_ice_spike_array(cast_position)

## 创建冰锥阵列
func _create_ice_spike_array(position: Vector2) -> void:
	# 创建阵列区域
	var array_area = Area2D.new()
	array_area.global_position = position

	# 设置碰撞层
	array_area.collision_layer = 0
	array_area.collision_mask = 2  # 敌人层

	# 添加到场景
	get_tree().current_scene.add_child(array_area)

	# 创建视觉效果
	_create_array_visual(array_area)

	# 持续造成伤害
	_process_array_damage(array_area)

	# 持续时间结束后销毁
	await get_tree().create_timer(array_duration).timeout
	if is_instance_valid(array_area):
		array_area.queue_free()

## 创建阵列视觉效果：冰锥晶簇 + 冰屑放射（water/ice 预设碎片运动）
func _create_array_visual(area: Area2D) -> void:
	var col := FxLib.color_for("ice")

	# 冰锥晶簇（菱形碎片竖立）
	for i in range(spike_count):
		var spike := Polygon2D.new()
		var h := randf_range(14.0, 26.0)
		spike.polygon = PackedVector2Array([
			Vector2(-5, 0), Vector2(0, -h), Vector2(5, 0), Vector2(0, 6)
		])
		spike.color = Color(col.r, col.g, col.b, 0.9)
		spike.position = Vector2(randf_range(-aoe_radius, aoe_radius) * 0.8, randf_range(-aoe_radius, aoe_radius) * 0.6)
		area.add_child(spike)
		# 破土而出
		spike.scale = Vector2(0.1, 0.1)
		var tw := spike.create_tween()
		tw.tween_property(spike, "scale", Vector2.ONE, 0.2) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 冰面光斑
	var glow := Sprite2D.new()
	glow.texture = load("res://assets/fx/glow_soft.png")
	glow.material = CanvasItemMaterial.new()
	glow.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.modulate = Color(col.r, col.g, col.b, 0.3)
	glow.scale = Vector2.ONE * (aoe_radius / 24.0)
	area.add_child(glow)

	# 冰屑粒子（放射后下坠）
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 14
	particles.lifetime = 0.4
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 230.0
	particles.gravity = Vector2(0, 90)
	particles.color = Color(col.r, col.g, col.b, 0.9)
	area.add_child(particles)

## 持续造成伤害
func _process_array_damage(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < array_duration:
		# 等待冰锥生成间隔
		await get_tree().create_timer(spike_interval).timeout
		elapsed += spike_interval

		# 区域可能已随场景销毁
		if not is_instance_valid(area) or not is_inside_tree():
			return

		# 获取范围内的敌人
		var enemies = _get_enemies_in_aoe(area.global_position, aoe_radius)

		for enemy in enemies:
			# 应用伤害
			_apply_damage(enemy)

			# 冰屑爆裂（ice 预设）
			FxLib.element_burst(self, enemy.global_position, "ice", 0.5)

			# 应用减速效果
			if enemy.has_method("apply_status_effect"):
				enemy.apply_status_effect(
					StatusEffectSystem.EffectType.SLOW,
					slow_amount,
					slow_duration
				)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 持续+2秒
			array_duration += 2.0
			print("冰锥阵列升级: 持续时间增加")
		10:
			# Lv.10: 6个冰锥
			spike_count = 6
			print("冰锥阵列升级: 冰锥数量增加")
		15:
			# Lv.15: 冰锥爆炸
			print("冰锥阵列升级: 冰锥爆炸")