## Thunderfire - 雷火交加
## 火焰+雷电融合：雷火弹，电火花连锁伤害
class_name Thunderfire
extends FusionSpell

# 雷火交加特有属性
@export var chain_count: int = 3  # 连锁数量
@export var chain_range: float = 100.0  # 连锁范围
@export var chain_damage_reduction: float = 0.3  # 连锁伤害递减30%
@export var explosion_radius: float = 80.0  # 爆炸范围

func _init() -> void:
	spell_name = "雷火交加"
	spell_element = "fusion"
	spell_type = SpellType.PROJECTILE
	damage = 45.0
	cooldown = 5.0
	mana_cost = 25.0
	
	# 融合属性
	element1 = "fire"
	element2 = "lightning"
	required_spell1 = "F1"
	required_spell2 = "L1"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	# 获取目标
	var cast_target = target
	if not cast_target:
		cast_target = _get_nearest_enemy()
	
	if cast_target:
		# 创建雷火弹
		_create_thunderfire_projectile(cast_target)

## 获取最近的敌人
func _get_nearest_enemy() -> Node2D:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = 300.0
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, owner_node.global_position)
	query.collision_mask = 2
	
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

## 创建雷火弹
func _create_thunderfire_projectile(target: Node2D) -> void:
	# 创建投射物节点
	var projectile = Node2D.new()
	projectile.global_position = global_position
	
	# 添加视觉效果
	var sprite = Sprite2D.new()
	sprite.modulate = Color(1.0, 0.5, 0.0)  # 橙黄色
	projectile.add_child(sprite)
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 15.0
	collision.shape = circle
	projectile.add_child(collision)
	
	# 添加到场景
	get_tree().current_scene.add_child(projectile)
	
	# 移动投射物到目标
	var tween = projectile.create_tween()
	tween.tween_property(projectile, "global_position", target.global_position, 0.3)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	await tween.finished
	
	# 触发爆炸
	_trigger_thunderfire_explosion(projectile.global_position)
	
	# 销毁投射物
	projectile.queue_free()

## 触发雷火爆炸
func _trigger_thunderfire_explosion(position: Vector2) -> void:
	# 获取爆炸范围内的敌人
	var enemies = _get_enemies_in_range(position, explosion_radius)
	
	# 应用初始伤害
	for enemy in enemies:
		_apply_damage(enemy)
		
		# 应用燃烧效果
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.BURN,
				damage * 0.2,
				3.0
			)
	
	# 创建连锁闪电
	_chain_lightning(position, enemies, damage)

## 创建连锁闪电
func _chain_lightning(from: Vector2, initial_targets: Array[Node2D], initial_damage: float) -> void:
	var current_targets = initial_targets.duplicate()
	var current_damage = initial_damage
	
	for i in range(chain_count):
		if current_targets.size() == 0:
			break
		
		# 选择第一个目标
		var target = current_targets[0]
		current_targets.erase(target)
		
		# 应用连锁伤害
		var chain_damage = current_damage * (1.0 - chain_damage_reduction * i)
		if target.has_method("take_damage"):
			target.take_damage(chain_damage, owner_node)
		
		# 创建闪电效果
		_create_chain_lightning_visual(from, target.global_position)
		
		# 获取下一个连锁目标
		var next_targets = _get_enemies_in_range(target.global_position, chain_range)
		current_targets = next_targets.filter(func(e): return e != target)
		
		from = target.global_position
		current_damage = chain_damage

## 创建连锁闪电视觉效果
func _create_chain_lightning_visual(from: Vector2, to: Vector2) -> void:
	# 创建闪电精灵
	var lightning = Sprite2D.new()
	lightning.modulate = Color(1.0, 1.0, 0.5, 0.8)
	lightning.global_position = (from + to) / 2.0
	lightning.rotation = from.angle_to_point(to)
	lightning.scale = Vector2(1.0, 0.1)
	get_tree().current_scene.add_child(lightning)
	
	# 延迟销毁
	await get_tree().create_timer(0.1).timeout
	lightning.queue_free()

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	# 雷火交加的融合效果：范围爆炸+连锁闪电
	_trigger_thunderfire_explosion(position)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	
	match spell_level:
		5:
			# Lv.5: 连锁+1
			chain_count += 1
			print("雷火交加升级: 连锁数量增加")
		10:
			# Lv.10: 爆炸范围+30%
			explosion_radius *= 1.3
			print("雷火交加升级: 爆炸范围增加")
		15:
			# Lv.15: 解锁雷火领域
			print("雷火交加升级: 解锁雷火领域")