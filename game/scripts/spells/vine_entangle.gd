## VineEntangle - 藤蔓缠绕
## 自然系控制法术
class_name VineEntangle
extends BaseSpell

# 藤蔓缠绕特有属性
@export var entangle_duration: float = 2.0  # 缠绕持续时间
@export var vine_range: float = 200.0  # 藤蔓范围
@export var vine_width: float = 50.0  # 藤蔓宽度
@export var entangle_damage: float = 10.0  # 缠绕伤害

func _init() -> void:
	spell_name = "藤蔓缠绕"
	spell_element = "nature"
	spell_type = SpellType.CONTROL
	damage = entangle_damage
	cooldown = 3.0
	mana_cost = 15.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取施放方向
	var cast_direction = Vector2.RIGHT
	if owner_node:
		cast_direction = owner_node.global_position.direction_to(get_global_mouse_position())
	
	# 创建藤蔓效果
	_create_vine_effect(cast_direction)

## 创建藤蔓效果
func _create_vine_effect(direction: Vector2) -> void:
	# 创建藤蔓区域
	var vine_area = Area2D.new()
	vine_area.global_position = owner_node.global_position
	vine_area.rotation = direction.angle()
	
	# 添加碰撞形状（矩形）
	var collision = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(vine_range, vine_width)
	collision.shape = rectangle
	collision.position = Vector2(vine_range / 2.0, 0)  # 向前偏移
	vine_area.add_child(collision)
	
	# 设置碰撞层
	vine_area.collision_layer = 0
	vine_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(vine_area)
	
	# 创建视觉效果
	_create_vine_visual(vine_area)
	
	# 处理缠绕效果
	_process_vine_damage(vine_area)
	
	# 延迟销毁
	await get_tree().create_timer(0.5).timeout
	vine_area.queue_free()

## 创建藤蔓视觉效果
func _create_vine_visual(area: Area2D) -> void:
	# 创建藤蔓精灵
	var vine_sprite = Sprite2D.new()
	vine_sprite.modulate = Color(0.2, 0.8, 0.2, 0.7)  # 绿色
	vine_sprite.scale = Vector2(2.0, 0.5)  # 长条形
	area.add_child(vine_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.lifetime = 0.5
	particles.amount = 10
	area.add_child(particles)

## 处理藤蔓伤害和缠绕
func _process_vine_damage(area: Area2D) -> void:
	# 获取范围内的敌人
	var enemies = _get_enemies_in_vine(area)
	
	for enemy in enemies:
		# 应用伤害
		_apply_damage(enemy)
		
		# 应用缠绕效果
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.ROOT,
				0.0,
				entangle_duration
			)

## 获取藤蔓范围内的敌人
func _get_enemies_in_vine(area: Area2D) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	
	# 获取重叠的物理体
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			enemies.append(body)
	
	return enemies

## 重写法术升级
func _on_upgrade() -> void:
	entangle_damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 缠绕+1秒
			entangle_duration += 1.0
			print("藤蔓缠绕升级: 缠绕时间增加")
		10:
			# Lv.10: 多段缠绕
			print("藤蔓缠绕升级: 多段缠绕")
		15:
			# Lv.15: 藤蔓爆炸
			print("藤蔓缠绕升级: 藤蔓爆炸")