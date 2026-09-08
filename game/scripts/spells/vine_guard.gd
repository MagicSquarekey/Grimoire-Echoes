## VineGuard - 藤蔓守卫
## 自然系召唤法术
class_name VineGuard
extends SummonSpell

# 藤蔓守卫特有属性
@export var guard_damage: float = 20.0  # 守卫伤害
@export var guard_duration: float = 15.0  # 持续时间
@export var guard_range: float = 150.0  # 攻击范围
@export var guard_attack_interval: float = 1.0  # 攻击间隔

func _init() -> void:
	spell_name = "藤蔓守卫"
	spell_element = "nature"
	spell_type = SpellType.SUMMON
	damage = guard_damage
	cooldown = 20.0
	mana_cost = 30.0
	summon_duration = guard_duration
	summon_count = 1

## 重写召唤逻辑
func _summon_units(position: Vector2) -> void:
	# 创建藤蔓守卫实例
	var guard = _create_vine_guard(position)
	if guard:
		summoned_units.append(guard)
		
		# 连接死亡信号
		if guard.has_signal("died"):
			guard.died.connect(_on_summon_died.bind(guard))

## 创建藤蔓守卫
func _create_vine_guard(position: Vector2) -> Node2D:
	# 创建守卫节点
	var guard = Node2D.new()
	guard.global_position = position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	guard.name = "VineGuard"
	
	# 添加视觉效果
	var guard_sprite = Sprite2D.new()
	guard_sprite.modulate = Color(0.2, 0.8, 0.2, 0.8)  # 绿色
	guard.add_child(guard_sprite)
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30.0
	collision.shape = circle
	guard.add_child(collision)
	
	# 添加到场景
	get_tree().current_scene.add_child(guard)
	
	# 开始守卫AI
	_process_guard_ai(guard)
	
	# 定时销毁
	await get_tree().create_timer(guard_duration).timeout
	if is_instance_valid(guard):
		guard.queue_free()
	
	return guard

## 守卫AI处理
func _process_guard_ai(guard: Node2D) -> void:
	while is_instance_valid(guard):
		# 等待攻击间隔
		await get_tree().create_timer(guard_attack_interval).timeout
		
		# 获取攻击范围内的敌人
		var enemies = _get_enemies_in_range(guard.global_position, guard_range)
		
		if enemies.size() > 0:
			# 选择最近的敌人攻击
			var target = enemies[0]
			_attack_enemy(guard, target)

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
func _attack_enemy(guard: Node2D, enemy: Node2D) -> void:
	# 应用伤害
	if enemy.has_method("take_damage"):
		enemy.take_damage(guard_damage, owner_node)
	
	# 创建攻击视觉效果
	_create_attack_visual(guard.global_position, enemy.global_position)

## 创建攻击视觉效果
func _create_attack_visual(from: Vector2, to: Vector2) -> void:
	# 创建攻击精灵
	var attack_sprite = Sprite2D.new()
	attack_sprite.modulate = Color(0.2, 0.8, 0.2, 0.7)  # 绿色
	attack_sprite.global_position = (from + to) / 2.0
	attack_sprite.rotation = from.angle_to_point(to)
	attack_sprite.scale = Vector2(1.0, 0.1)  # 压缩成线状
	get_tree().current_scene.add_child(attack_sprite)
	
	# 延迟销毁
	await get_tree().create_timer(0.1).timeout
	attack_sprite.queue_free()

## 重写法术升级
func _on_upgrade() -> void:
	guard_damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 持续+5秒
			guard_duration += 5.0
			summon_duration = guard_duration
			print("藤蔓守卫升级: 持续时间增加")
		10:
			# Lv.10: 守卫攻击翻倍
			guard_damage *= 2.0
			print("藤蔓守卫升级: 攻击力翻倍")
		15:
			# Lv.15: 守卫分裂
			print("藤蔓守卫升级: 守卫分裂")