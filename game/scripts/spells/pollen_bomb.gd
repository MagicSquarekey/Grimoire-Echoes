## PollenBomb - 花粉炸弹
## 自然系AoE法术
class_name PollenBomb
extends AoESpell

# 花粉炸弹特有属性
@export var bomb_duration: float = 5.0  # 持续时间
@export var damage_per_second: float = 15.0  # 每秒伤害
@export var blind_chance: float = 0.2  # 致盲概率20%
@export var blind_duration: float = 2.0  # 致盲持续时间
@export var bomb_radius: float = 100.0  # 花粉范围

func _init() -> void:
	spell_name = "花粉炸弹"
	spell_element = "nature"
	spell_type = SpellType.GROUND_AOE
	damage = damage_per_second
	cooldown = 6.0
	mana_cost = 0.0  # 自动战斗法术不消耗法力
	aoe_radius = bomb_radius

## 重写施放逻辑（target 可能是 Vector2 坐标）
func _on_cast(target = null) -> void:
	var cast_position := _resolve_cast_position(target)

	# 创建花粉炸弹
	_create_pollen_bomb(cast_position)

## 创建花粉炸弹
func _create_pollen_bomb(position: Vector2) -> void:
	# 创建花粉区域
	var pollen_area = Area2D.new()
	pollen_area.global_position = position

	# 设置碰撞层
	pollen_area.collision_layer = 0
	pollen_area.collision_mask = 2  # 敌人层

	# 添加到场景
	get_tree().current_scene.add_child(pollen_area)

	# 创建视觉效果
	_create_pollen_visual(pollen_area)

	# 持续造成伤害和致盲效果
	_process_pollen_damage(pollen_area)

	# 持续时间结束后销毁
	await get_tree().create_timer(bomb_duration).timeout
	if is_instance_valid(pollen_area):
		pollen_area.queue_free()

## 创建花粉视觉效果：绿色毒云 + 叶片旋转飘落（nature 预设运动模式）
func _create_pollen_visual(area: Area2D) -> void:
	var col := FxLib.color_for("nature")

	# 花粉云（柔光斑，脉动）
	var cloud := Sprite2D.new()
	cloud.texture = load("res://assets/fx/glow_soft.png")
	cloud.material = CanvasItemMaterial.new()
	cloud.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	cloud.modulate = Color(col.r, col.g, col.b, 0.4)
	cloud.scale = Vector2.ONE * (bomb_radius / 22.0)
	area.add_child(cloud)
	var tw := cloud.create_tween()
	tw.set_loops()
	tw.tween_property(cloud, "modulate:a", 0.25, 0.7)
	tw.tween_property(cloud, "modulate:a", 0.45, 0.7)

	# 叶片粒子：旋转+下坠飘落
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 14
	particles.lifetime = 1.4
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 90.0
	particles.gravity = Vector2(0, 52)
	particles.angular_velocity_min = -260.0
	particles.angular_velocity_max = 260.0
	particles.scale_amount_min = 0.9
	particles.scale_amount_max = 1.3
	particles.color = Color(col.r, col.g, col.b, 0.9)
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = bomb_radius * 0.7
	area.add_child(particles)

## 持续造成伤害和致盲效果
func _process_pollen_damage(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < bomb_duration:
		# 等待1秒
		await get_tree().create_timer(1.0).timeout
		elapsed += 1.0

		# 区域可能已随场景销毁
		if not is_instance_valid(area) or not is_inside_tree():
			return

		# 获取范围内的敌人
		var enemies = _get_enemies_in_aoe(area.global_position, bomb_radius)

		for enemy in enemies:
			# 应用伤害
			_apply_damage(enemy)

			# 叶片爆裂（nature 预设）
			FxLib.element_burst(self, enemy.global_position, spell_element, 0.4)

			# 概率致盲
			if randf() < blind_chance:
				if enemy.has_method("apply_status_effect"):
					enemy.apply_status_effect(
						StatusEffectSystem.EffectType.BLIND,
						0.3,  # 命中率降低30%
						blind_duration
					)

## 重写法术升级
func _on_upgrade() -> void:
	damage_per_second *= 1.08
	damage = damage_per_second  # 同步到基类伤害字段（结算走 damage）
	
	match spell_level:
		5:
			# Lv.5: 范围+30%
			bomb_radius *= 1.3
			aoe_radius = bomb_radius
			print("花粉炸弹升级: 范围增加")
		10:
			# Lv.10: 致盲效果增强
			blind_chance += 0.15
			print("花粉炸弹升级: 致盲概率增加")
		15:
			# Lv.15: 毒雾扩散
			print("花粉炸弹升级: 毒雾扩散")