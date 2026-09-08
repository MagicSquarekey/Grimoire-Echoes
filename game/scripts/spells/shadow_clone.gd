## ShadowClone - 暗影分身
## 暗影系召唤法术
class_name ShadowClone
extends SummonSpell

# 暗影分身特有属性
@export var clone_damage: float = 15.0  # 分身伤害
@export var clone_duration: float = 12.0  # 持续时间
@export var clone_attack_range: float = 100.0  # 攻击范围
@export var clone_attack_interval: float = 0.8  # 攻击间隔

func _init() -> void:
	spell_name = "暗影分身"
	spell_element = "shadow"
	spell_type = SpellType.SUMMON
	damage = clone_damage
	cooldown = 18.0
	mana_cost = 25.0
	summon_duration = clone_duration
	summon_count = 1

## 重写召唤逻辑
func _summon_units(position: Vector2) -> void:
	# 创建暗影分身实例
	var clone = _create_shadow_clone(position)
	if clone:
		summoned_units.append(clone)
		
		# 连接死亡信号
		if clone.has_signal("died"):
			clone.died.connect(_on_summon_died.bind(clone))

## 创建暗影分身
func _create_shadow_clone(position: Vector2) -> Node2D:
	# 创建分身节点
	var clone = Node2D.new()
	clone.global_position = position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	clone.name = "ShadowClone"
	
	# 添加视觉效果
	var clone_sprite = Sprite2D.new()
	clone_sprite.modulate = Color(0.2, 0.0, 0.3, 0.7)  # 暗紫色
	clone.add_child(clone_sprite)
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 25.0
	collision.shape = circle
	clone.add_child(collision)
	
	# 添加到场景
	get_tree().current_scene.add_child(clone)
	
	# 开始分身AI
	_process_clone_ai(clone)
	
	# 定时销毁
	await get_tree().create_timer(clone_duration).timeout
	if is_instance_valid(clone):
		clone.queue_free()
	
	return clone

## 分身AI处理
func _process_clone_ai(clone: Node2D) -> void:
	while is_instance_valid(clone):
		# 等待攻击间隔
		await get_tree().create_timer(clone_attack_interval).timeout
		
		# 获取攻击范围内的敌人
		var enemies = _get_enemies_in_range(clone.global_position, clone_attack_range)
		
		if enemies.size() > 0:
			# 选择最近的敌人攻击
			var target = enemies[0]
			_attack_enemy(clone, target)

## 获取范围内敌人
func _get_enemies_in_range(center: Vector2, range: float) -> Array[Node2D]:
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
	
	# 按距离排序
	enemies.sort_custom(func(a, b): 
		return center.distance_to(a.global_position) < center.distance_to(b.global_position)
	)
	
	return enemies

## 攻击敌人
func _attack_enemy(clone: Node2D, enemy: Node2D) -> void:
	# 应用伤害
	if enemy.has_method("take_damage"):
		enemy.take_damage(clone_damage, owner_node)
	
	# 创建攻击视觉效果
	_create_attack_visual(clone.global_position, enemy.global_position)

## 创建攻击视觉效果
func _create_attack_visual(from: Vector2, to: Vector2) -> void:
	# 创建攻击精灵
	var attack_sprite = Sprite2D.new()
	attack_sprite.modulate = Color(0.2, 0.0, 0.3, 0.7)  # 暗紫色
	attack_sprite.global_position = (from + to) / 2.0
	attack_sprite.rotation = from.angle_to_point(to)
	attack_sprite.scale = Vector2(1.0, 0.1)  # 压缩成线状
	get_tree().current_scene.add_child(attack_sprite)
	
	# 延迟销毁
	await get_tree().create_timer(0.1).timeout
	attack_sprite.queue_free()

## 重写法术升级
func _on_upgrade() -> void:
	clone_damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 持续+3秒
			clone_duration += 3.0
			summon_duration = clone_duration
			print("暗影分身升级: 持续时间增加")
		10:
			# Lv.10: 分身攻击翻倍
			clone_damage *= 2.0
			print("暗影分身升级: 攻击力翻倍")
		15:
			# Lv.15: 分身复制法术
			print("暗影分身升级: 分身复制法术")