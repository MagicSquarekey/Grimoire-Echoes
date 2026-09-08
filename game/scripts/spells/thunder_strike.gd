## ThunderStrike - 雷霆一击
## 雷电系单体爆发法术
class_name ThunderStrike
extends BaseSpell

# 雷霆一击特有属性
@export var strike_damage: float = 80.0  # 打击伤害
@export var stun_duration: float = 2.0  # 麻痹持续时间
@export var strike_range: float = 300.0  # 打击范围
@export var strike_delay: float = 0.2  # 打击延迟

func _init() -> void:
	spell_name = "雷霆一击"
	spell_element = "lightning"
	spell_type = SpellType.PROJECTILE
	damage = strike_damage
	cooldown = 6.0
	mana_cost = 25.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取目标
	var strike_target = target
	if not strike_target:
		strike_target = _get_nearest_enemy()
	
	if strike_target:
		# 执行雷霆一击
		_perform_thunder_strike(strike_target)

## 获取最近的敌人
func _get_nearest_enemy() -> Node2D:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = strike_range
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, owner_node.global_position)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			enemies.append(collider)
	
	if enemies.size() == 0:
		return null
	
	# 按距离排序
	enemies.sort_custom(func(a, b): 
		return owner_node.global_position.distance_to(a.global_position) < owner_node.global_position.distance_to(b.global_position)
	)
	
	return enemies[0]

## 执行雷霆一击
func _perform_thunder_strike(target: Node2D) -> void:
	# 等待打击延迟
	await get_tree().create_timer(strike_delay).timeout
	
	# 应用伤害
	var final_damage = _calculate_damage()
	if target.has_method("take_damage"):
		target.take_damage(final_damage, owner_node)
	
	# 应用麻痹效果（必定麻痹）
	if target.has_method("apply_status_effect"):
		target.apply_status_effect(
			StatusEffectSystem.EffectType.STUN,
			0.0,
			stun_duration
		)
	
	# 创建雷电视觉效果
	_create_thunder_strike_visual(owner_node.global_position, target.global_position)

## 创建雷电视觉效果
func _create_thunder_strike_visual(from: Vector2, to: Vector2) -> void:
	# 创建主闪电精灵
	var main_lightning = Sprite2D.new()
	main_lightning.modulate = Color(1.0, 1.0, 0.5, 0.9)  # 浅黄色
	main_lightning.global_position = (from + to) / 2.0
	main_lightning.rotation = from.angle_to_point(to)
	main_lightning.scale = Vector2(1.0, 0.2)  # 压缩成线状
	get_tree().current_scene.add_child(main_lightning)
	
	# 创建分支闪电
	for i in range(3):
		var branch_lightning = Sprite2D.new()
		branch_lightning.modulate = Color(1.0, 1.0, 0.3, 0.7)  # 浅黄色
		branch_lightning.global_position = to + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		branch_lightning.rotation = randf_range(0, TAU)
		branch_lightning.scale = Vector2(0.5, 0.1)
		get_tree().current_scene.add_child(branch_lightning)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.lifetime = 0.3
	particles.amount = 15
	particles.global_position = to
	get_tree().current_scene.add_child(particles)
	
	# 延迟销毁
	await get_tree().create_timer(0.3).timeout
	main_lightning.queue_free()
	for child in get_tree().current_scene.get_children():
		if child.modulate.a < 0.5:  # 简单的清理逻辑
			child.queue_free()

## 重写法术升级
func _on_upgrade() -> void:
	strike_damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 伤害+30%
			strike_damage *= 1.3
			print("雷霆一击升级: 伤害增加")
		10:
			# Lv.10: 双重打击
			print("雷霆一击升级: 变为双重打击")
		15:
			# Lv.15: 连锁打击
			print("雷霆一击升级: 连锁打击")