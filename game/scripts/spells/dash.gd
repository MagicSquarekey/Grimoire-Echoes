## Dash - 疾风步
## 风暴系位移法术
class_name Dash
extends BaseSpell

# 疾风步特有属性
@export var dash_distance: float = 200.0  # 冲刺距离
@export var dash_speed: float = 800.0  # 冲刺速度
@export var dash_damage: float = 25.0  # 冲刺伤害
@export var knockback_force: float = 200.0  # 击退力
@export var dash_width: float = 50.0  # 冲刺宽度

func _init() -> void:
	spell_name = "疾风步"
	spell_element = "air"
	spell_type = SpellType.DASH
	damage = dash_damage
	cooldown = 4.0
	mana_cost = 15.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取冲刺方向
	var dash_direction = Vector2.RIGHT
	if target:
		dash_direction = owner_node.global_position.direction_to(target.global_position)
	elif owner_node:
		dash_direction = owner_node.global_position.direction_to(get_global_mouse_position())
	
	# 执行冲刺
	_perform_dash(dash_direction)

## 执行冲刺
func _perform_dash(direction: Vector2) -> void:
	# 计算冲刺目标位置
	var start_position = owner_node.global_position
	var end_position = start_position + direction * dash_distance
	
	# 创建冲刺路径
	_create_dash_path(start_position, end_position)
	
	# 创建冲刺视觉效果
	_create_dash_visual()
	
	# 执行冲刺动画
	_animate_dash(start_position, end_position)
	
	# 处理冲刺伤害
	_process_dash_damage(start_position, end_position, direction)

## 创建冲刺路径
func _create_dash_path(start: Vector2, end: Vector2) -> void:
	# 创建冲刺区域
	var dash_area = Area2D.new()
	dash_area.global_position = (start + end) / 2.0
	dash_area.rotation = start.angle_to_point(end)
	
	# 添加碰撞形状（矩形）
	var collision = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(dash_distance, dash_width)
	collision.shape = rectangle
	dash_area.add_child(collision)
	
	# 设置碰撞层
	dash_area.collision_layer = 0
	dash_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(dash_area)
	
	# 延迟销毁
	await get_tree().create_timer(0.3).timeout
	dash_area.queue_free()

## 创建冲刺视觉效果
func _create_dash_visual() -> void:
	# 创建冲刺精灵
	var dash_sprite = Sprite2D.new()
	dash_sprite.name = "DashSprite"
	dash_sprite.modulate = Color(0.8, 0.9, 1.0, 0.6)  # 浅蓝色
	dash_sprite.scale = Vector2(2.0, 0.5)  # 长条形
	owner_node.add_child(dash_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "DashParticles"
	particles.emitting = true
	particles.lifetime = 0.3
	particles.amount = 15
	owner_node.add_child(particles)

## 执行冲刺动画
func _animate_dash(start: Vector2, end: Vector2) -> void:
	# 计算冲刺时间
	var dash_time = dash_distance / dash_speed
	
	# 创建冲刺动画
	var tween = owner_node.create_tween()
	tween.tween_property(owner_node, "global_position", end, dash_time)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	# 等待动画完成
	await tween.finished

## 处理冲刺伤害
func _process_dash_damage(start: Vector2, end: Vector2, direction: Vector2) -> void:
	# 获取冲刺路径上的敌人
	var enemies = _get_enemies_in_dash_path(start, end)
	
	for enemy in enemies:
		# 应用伤害
		_apply_damage(enemy)
		
		# 应用击退效果
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(direction, knockback_force)

## 获取冲刺路径上的敌人
func _get_enemies_in_dash_path(start: Vector2, end: Vector2) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 计算冲刺路径的中心和范围
	var center = (start + end) / 2.0
	var distance = start.distance_to(end)
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = distance / 2.0 + 50.0  # 稍微扩大范围
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, center)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			# 检查是否在冲刺路径上
			var enemy_pos = collider.global_position
			var projection = start.direction_to(end).dot(start.direction_to(enemy_pos))
			var distance_from_line = start.direction_to(end).orthogonal().dot(start.direction_to(enemy_pos))
			
			if projection >= 0 and projection <= 1 and abs(distance_from_line) < dash_width / 2.0:
				enemies.append(collider)
	
	return enemies

## 重写法术升级
func _on_upgrade() -> void:
	dash_damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 冲刺距离+30%
			dash_distance *= 1.3
			print("疾风步升级: 冲刺距离增加")
		10:
			# Lv.10: 双重冲刺
			print("疾风步升级: 变为双重冲刺")
		15:
			# Lv.15: 冲刺残影
			print("疾风步升级: 冲刺残影")