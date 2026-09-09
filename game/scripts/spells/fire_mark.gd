## FireMark - 火焰印记
## 火焰系标记法术
class_name FireMark
extends BaseSpell

# 火焰印记特有属性
@export var mark_count: int = 3  # 标记敌人数量
@export var mark_duration: float = 6.0  # 标记持续时间
@export var damage_increase: float = 0.5  # 火焰伤害增加50%
@export var explosion_damage: float = 40.0  # 引爆伤害
@export var explosion_radius: float = 100.0  # 引爆范围

# 标记状态
var marked_enemies: Array[Node2D] = []

func _init() -> void:
	spell_name = "火焰印记"
	spell_element = "fire"
	spell_type = SpellType.MARK
	damage = 0  # 标记本身无伤害
	cooldown = 6.0
	mana_cost = 20.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取最近的敌人进行标记
	var enemies = _get_nearest_enemies(mark_count)
	
	for enemy in enemies:
		# 应用标记
		_apply_mark(enemy)

## 获取最近的敌人
func _get_nearest_enemies(count: int) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = 300.0  # 标记范围
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, owner_node.global_position)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			enemies.append(collider)
	
	# 按距离排序
	enemies.sort_custom(func(a, b): 
		return owner_node.global_position.distance_to(a.global_position) < owner_node.global_position.distance_to(b.global_position)
	)
	
	# 返回最近的敌人
	return enemies.slice(0, count)

## 应用标记
func _apply_mark(enemy: Node2D) -> void:
	# 添加到标记列表
	if not enemy in marked_enemies:
		marked_enemies.append(enemy)
		
		# 应用标记视觉效果
		_mark_visual_effect(enemy)
		
		# 应用伤害增加效果
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.CURSE,
				damage_increase,
				mark_duration
			)
		
		# 标记结束时引爆
		_schedule_explosion(enemy)

## 标记视觉效果
func _mark_visual_effect(enemy: Node2D) -> void:
	# 创建标记精灵
	var mark_sprite = Sprite2D.new()
	mark_sprite.name = "FireMarkSprite"
	mark_sprite.modulate = Color(1.0, 0.2, 0.0, 0.8)  # 红色
	mark_sprite.scale = Vector2(0.5, 0.5)
	enemy.add_child(mark_sprite)

## 定时引爆
func _schedule_explosion(enemy: Node2D) -> void:
	# 等待标记持续时间
	await get_tree().create_timer(mark_duration).timeout
	
	# 检查敌人是否仍然存在
	if is_instance_valid(enemy) and enemy in marked_enemies:
		# 执行引爆
		_explode(enemy)
		
		# 从标记列表中移除
		marked_enemies.erase(enemy)

## 执行引爆
func _explode(enemy: Node2D) -> void:
	# 获取爆炸范围内的敌人
	var enemies = _get_enemies_in_circle(explosion_radius, enemy.global_position)
	
	for target in enemies:
		# 应用引爆伤害
		if target.has_method("take_damage"):
			target.take_damage(explosion_damage, owner_node)
		
		# 应用燃烧效果
		if target.has_method("apply_status_effect"):
			target.apply_status_effect(
				StatusEffectSystem.EffectType.BURN,
				explosion_damage * 0.2,  # 20%伤害/秒
				3.0
			)
	
	# 创建爆炸视觉效果
	_create_explosion_visual(enemy.global_position)

## 获取范围内敌人
func _get_enemies_in_circle(range: float, center: Vector2) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = range
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, center)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			enemies.append(collider)
	
	return enemies

## 创建爆炸视觉效果
func _create_explosion_visual(position: Vector2) -> void:
	# 创建爆炸精灵
	var explosion_sprite = Sprite2D.new()
	explosion_sprite.modulate = Color(1.0, 0.5, 0.0, 0.8)  # 橙红色
	explosion_sprite.global_position = position
	get_tree().current_scene.add_child(explosion_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.lifetime = 0.5
	particles.amount = 20
	particles.global_position = position
	get_tree().current_scene.add_child(particles)
	
	# 延迟销毁
	await get_tree().create_timer(0.5).timeout
	explosion_sprite.queue_free()
	particles.queue_free()

## 清除所有标记
func clear_marks() -> void:
	for enemy in marked_enemies:
		if is_instance_valid(enemy):
			# 移除标记视觉效果
			if enemy.has_node("FireMarkSprite"):
				enemy.get_node("FireMarkSprite").queue_free()
	
	marked_enemies.clear()

## 重写法术升级
func _on_upgrade() -> void:
	damage_increase *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 标记数+2
			mark_count += 2
			print("火焰印记升级: 标记数量增加")
		10:
			# Lv.10: 引爆伤害翻倍
			explosion_damage *= 2.0
			print("火焰印记升级: 引爆伤害翻倍")
		15:
			# Lv.15: 连锁标记
			print("火焰印记升级: 连锁标记")