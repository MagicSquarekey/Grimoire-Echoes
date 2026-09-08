## FrostShock - 冰雷爆裂
## 水流+雷电融合：冻结敌人并传导伤害
class_name FrostShock
extends FusionSpell

# 冰雷爆裂特有属性
@export var chain_count: int = 4  # 连锁数量
@export var chain_range: float = 120.0  # 连锁范围
@export var freeze_duration: float = 2.0  # 冻结持续时间
@export var chain_damage_reduction: float = 0.25  # 连锁伤害递减

func _init() -> void:
	spell_name = "冰雷爆裂"
	spell_element = "fusion"
	spell_type = SpellType.CHAIN
	damage = 42.0
	cooldown = 6.0
	mana_cost = 26.0
	
	element1 = "water"
	element2 = "lightning"
	required_spell1 = "W1"
	required_spell2 = "L1"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_target = target
	if not cast_target:
		cast_target = _get_nearest_enemy()
	
	if cast_target:
		_trigger_frost_shock(cast_target)

## 获取最近的敌人
func _get_nearest_enemy() -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var shape = CircleShape2D.new()
	shape.radius = 400.0
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, owner_node.global_position if owner_node else global_position)
	query.collision_mask = 2
	
	var results = space_state.intersect_shape(query)
	var enemies: Array[Node2D] = []
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			enemies.append(collider)
	
	if enemies.is_empty():
		return null
	
	enemies.sort_custom(func(a, b):
		return owner_node.global_position.distance_to(a.global_position) < owner_node.global_position.distance_to(b.global_position)
	)
	return enemies[0]

## 触发冰雷爆裂
func _trigger_frost_shock(initial_target: Node2D) -> void:
	var current_target = initial_target
	var current_damage = damage
	var hit_targets: Array[Node2D] = []
	
	for i in range(chain_count + 1):
		if not is_instance_valid(current_target):
			break
		
		hit_targets.append(current_target)
		
		# 应用伤害
		if current_target.has_method("take_damage"):
			current_target.take_damage(current_damage, owner_node)
		
		# 应用冻结效果
		if current_target.has_method("apply_status_effect"):
			current_target.apply_status_effect(
				StatusEffectSystem.EffectType.FREEZE,
				1.0,
				freeze_duration
			)
		
		# 创建冰雷效果
		_create_frost_shock_visual(current_target.global_position)
		
		# 获取下一个连锁目标
		var next_target = _get_next_chain_target(current_target.global_position, hit_targets)
		if next_target:
			current_target = next_target
			current_damage *= (1.0 - chain_damage_reduction)
		else:
			break

## 获取下一个连锁目标
func _get_next_chain_target(from: Vector2, exclude: Array[Node2D]) -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var shape = CircleShape2D.new()
	shape.radius = chain_range
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, from)
	query.collision_mask = 2
	
	var results = space_state.intersect_shape(query)
	var enemies: Array[Node2D] = []
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies") and collider not in exclude:
			enemies.append(collider)
	
	if enemies.is_empty():
		return null
	
	return enemies[randi() % enemies.size()]

## 创建冰雷视觉效果
func _create_frost_shock_visual(position: Vector2) -> void:
	var sprite = Sprite2D.new()
	sprite.modulate = Color(0.3, 0.6, 1.0, 0.8)
	sprite.global_position = position
	sprite.scale = Vector2(1.5, 1.5)
	get_tree().current_scene.add_child(sprite)
	
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(sprite):
		sprite.queue_free()

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	var enemies = _get_enemies_in_range(position, chain_range)
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage * 0.5, owner_node)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	
	match spell_level:
		5:
			chain_count += 1
			print("冰雷爆裂升级: 连锁数量增加")
		10:
			freeze_duration += 0.5
			print("冰雷爆裂升级: 冻结时间增加")
		15:
			chain_range *= 1.3
			print("冰雷爆裂升级: 连锁范围增加")
