## MeteorStrike - 陨石坠落
## 火焰系地面AoE法术：标记目标点，延迟后陨石砸落爆炸（自动战斗版）
class_name MeteorStrike
extends AoESpell

# 陨石特有属性
@export var cast_delay: float = 1.5  # 施放延迟
@export var explosion_radius: float = 100.0  # 爆炸范围
@export var meteor_damage: float = 50.0  # 陨石伤害

func _init() -> void:
	spell_name = "陨石坠落"
	spell_element = "fire"
	spell_type = SpellType.GROUND_AOE
	damage = meteor_damage
	cooldown = 8.0
	mana_cost = 0.0  # 自动战斗法术不消耗法力
	aoe_radius = explosion_radius
	aoe_delay = cast_delay

## 重写施放逻辑（target 可能是 Vector2 坐标）
func _on_cast(target = null) -> void:
	var cast_position := _resolve_cast_position(target)

	# 标记落点（警示红圈）让延迟期有可读反馈
	_spawn_target_marker(cast_position)

	# 延迟后召唤陨石
	await get_tree().create_timer(cast_delay).timeout

	# 施法者可能已死亡/切场景
	if not is_inside_tree():
		return

	# 创建陨石效果
	_create_meteor_effect(cast_position)

## 落点警示标记
func _spawn_target_marker(pos: Vector2) -> void:
	var marker := Sprite2D.new()
	marker.texture = load("res://assets/fx/ring_glow.png")
	marker.modulate = Color(1.0, 0.35, 0.1, 0.75)
	marker.global_position = pos
	marker.scale = Vector2.ONE * (explosion_radius / 50.0)
	get_tree().current_scene.add_child(marker)
	var tw := marker.create_tween()
	tw.set_loops(int(cast_delay / 0.4) + 1)
	tw.tween_property(marker, "modulate:a", 0.25, 0.2)
	tw.tween_property(marker, "modulate:a", 0.75, 0.2)
	tw.chain().tween_callback(marker.queue_free)

## 创建陨石效果
func _create_meteor_effect(position: Vector2) -> void:
	# 创建陨石区域
	var meteor_area = Area2D.new()
	meteor_area.global_position = position

	# 设置碰撞层
	meteor_area.collision_layer = 0
	meteor_area.collision_mask = 2  # 敌人层

	# 添加到场景
	get_tree().current_scene.add_child(meteor_area)

	# 创建视觉效果
	_create_meteor_visual(meteor_area)

	# 处理伤害（直接按范围查询，不依赖重叠回调时序）
	_process_meteor_damage(meteor_area)

	# 延迟销毁
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(meteor_area):
		meteor_area.queue_free()

## 创建陨石视觉效果：橙红爆炸核心 + 火星上飘（fire 预设运动模式）
func _create_meteor_visual(area: Area2D) -> void:
	var col := FxLib.color_for("fire")

	# 爆炸核心闪光
	var core := Sprite2D.new()
	core.texture = load("res://assets/fx/glow_soft.png")
	core.material = CanvasItemMaterial.new()
	core.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	core.modulate = Color(1.0, 0.55, 0.15, 0.95)
	core.scale = Vector2.ONE * (explosion_radius / 26.0)
	area.add_child(core)
	var tw := core.create_tween()
	tw.set_parallel(true)
	tw.tween_property(core, "modulate:a", 0.0, 0.45)
	tw.tween_property(core, "scale", core.scale * 1.25, 0.45)

	# 火星上飘粒子
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.lifetime = 0.55
	particles.amount = 22
	particles.initial_velocity_min = 70.0
	particles.initial_velocity_max = 170.0
	particles.gravity = Vector2(0, -85)  # 火星上飘
	particles.scale_amount_min = 1.1
	particles.scale_amount_max = 1.6
	particles.color = Color(col.r, col.g, col.b, 0.95)
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = explosion_radius * 0.5
	area.add_child(particles)

## 处理陨石伤害
func _process_meteor_damage(area: Area2D) -> void:
	var enemies := _get_enemies_in_aoe(area.global_position, explosion_radius)
	for enemy in enemies:
		_apply_damage(enemy)
		# 火星爆裂（fire 预设）
		FxLib.element_burst(self, enemy.global_position, spell_element, 0.7)

		# 应用击退效果
		if enemy.has_method("apply_knockback"):
			var knockback_direction = area.global_position.direction_to(enemy.global_position)
			enemy.apply_knockback(knockback_direction, 200.0)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.08

	match spell_level:
		5:
			# Lv.5: 延迟缩短至1s
			cast_delay = 1.0
			aoe_delay = cast_delay
		10:
			pass  # 3连陨石
		15:
			pass  # 陨石碎片散射
