## ChainLightning - 连锁闪电
## 雷电系连锁法术
class_name ChainLightning
extends BaseSpell

# 连锁闪电特有属性
@export var max_chain_count: int = 5  # 最大弹射数量
@export var chain_range: float = 200.0  # 弹射范围
@export var chain_damage_reduction: float = 0.2  # 弹射伤害递减20%
@export var chain_delay: float = 0.15  # 弹射延迟

# 已弹射目标
var chain_targets: Array[Node2D] = []

func _init() -> void:
	spell_name = "连锁闪电"
	spell_element = "lightning"
	spell_type = SpellType.CHAIN
	damage = 25.0
	cooldown = 4.0
	mana_cost = 18.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 清空弹射目标列表
	chain_targets.clear()
	
	# 获取初始目标
	var initial_target = target
	if not initial_target:
		initial_target = _get_nearest_enemy()
	
	if initial_target:
		# 开始连锁闪电
		_chain_lightning(initial_target, _calculate_damage())

## 获取最近的敌人
func _get_nearest_enemy() -> Node2D:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = 300.0  # 搜索范围
	
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

## 连锁闪电
func _chain_lightning(target: Node2D, current_damage: float) -> void:
	# 标记目标已弹射
	chain_targets.append(target)
	
	# 应用伤害
	if target.has_method("take_damage"):
		target.take_damage(current_damage, owner_node)
	
	# 创建闪电视觉效果
	_create_chain_visual(owner_node.global_position if chain_targets.size() == 1 else chain_targets[-2].global_position, target.global_position)
	
	# 检查是否达到最大弹射数量
	if chain_targets.size() >= max_chain_count:
		return
	
	# 获取下一个弹射目标
	var next_target = _get_chain_target(target)
	if next_target:
		# 等待弹射延迟
		await get_tree().create_timer(chain_delay).timeout
		
		# 计算弹射后的伤害
		var next_damage = current_damage * (1.0 - chain_damage_reduction)
		
		# 继续连锁
		_chain_lightning(next_target, next_damage)

## 获取连锁目标
func _get_chain_target(from: Node2D) -> Node2D:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = chain_range
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, from.global_position)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies") and not collider in chain_targets:
			enemies.append(collider)
	
	if enemies.size() == 0:
		return null
	
	# 按距离排序
	enemies.sort_custom(func(a, b): 
		return from.global_position.distance_to(a.global_position) < from.global_position.distance_to(b.global_position)
	)
	
	return enemies[0]

## 创建连锁视觉效果
func _create_chain_visual(from: Vector2, to: Vector2) -> void:
	# 创建闪电精灵
	var lightning_sprite = Sprite2D.new()
	lightning_sprite.modulate = Color(1.0, 1.0, 0.5, 0.8)  # 浅黄色
	lightning_sprite.global_position = (from + to) / 2.0
	lightning_sprite.rotation = from.angle_to_point(to)
	lightning_sprite.scale = Vector2(1.0, 0.1)  # 压缩成线状
	get_tree().current_scene.add_child(lightning_sprite)
	
	# 延迟销毁
	await get_tree().create_timer(0.1).timeout
	lightning_sprite.queue_free()

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 弹射+3
			max_chain_count += 3
			print("连锁闪电升级: 弹射数量增加")
		10:
			# Lv.10: 无伤害递减
			chain_damage_reduction = 0.0
			print("连锁闪电升级: 弹射无递减")
		15:
			# Lv.15: 全屏弹射
			chain_range = 500.0
			print("连锁闪电升级: 弹射范围增加")