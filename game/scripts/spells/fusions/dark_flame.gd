## DarkFlame - 暗焰爆弹
## 火焰+暗影融合：暗影火焰弹，吸取生命并造成燃烧
class_name DarkFlame
extends FusionSpell

# 暗焰爆弹特有属性
@export var projectile_speed: float = 350.0  # 投射物速度
@export var explosion_radius: float = 70.0  # 爆炸范围
@export var life_steal_percent: float = 0.15  # 生命偷取15%
@export var burn_damage: float = 8.0  # 燃烧伤害
@export var burn_duration: float = 3.0  # 燃烧持续时间

func _init() -> void:
	spell_name = "暗焰爆弹"
	spell_element = "fusion"
	spell_type = SpellType.PROJECTILE
	damage = 40.0
	cooldown = 6.0
	mana_cost = 28.0
	
	# 融合属性
	element1 = "fire"
	element2 = "shadow"
	required_spell1 = "F1"
	required_spell2 = "D1"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_target = target
	if not cast_target:
		cast_target = _get_nearest_enemy()
	
	if cast_target:
		_create_dark_flame_projectile(cast_target)

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

## 创建暗焰投射物
func _create_dark_flame_projectile(target: Node2D) -> void:
	var projectile = Node2D.new()
	projectile.global_position = global_position
	
	# 视觉效果
	var sprite = Sprite2D.new()
	sprite.modulate = Color(0.5, 0.1, 0.3, 0.9)  # 暗焰色
	projectile.add_child(sprite)
	
	# 碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12.0
	collision.shape = circle
	projectile.add_child(collision)
	
	# 添加到场景
	get_tree().current_scene.add_child(projectile)
	
	# 移动到目标
	var tween = projectile.create_tween()
	tween.tween_property(projectile, "global_position", target.global_position, 0.4)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	await tween.finished
	
	# 触发爆炸
	_trigger_dark_flame_explosion(projectile.global_position)
	projectile.queue_free()

## 触发暗焰爆炸
func _trigger_dark_flame_explosion(position: Vector2) -> void:
	var enemies = _get_enemies_in_range(position, explosion_radius)
	var total_damage = 0.0
	
	for enemy in enemies:
		# 应用伤害
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, owner_node)
			total_damage += damage
		
		# 应用燃烧效果
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.BURN,
				burn_damage,
				burn_duration
			)
	
	# 生命偷取
	if owner_node and total_damage > 0 and owner_node.has_method("heal"):
		var heal_amount = total_damage * life_steal_percent
		owner_node.heal(heal_amount)

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	_trigger_dark_flame_explosion(position)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	
	match spell_level:
		5:
			life_steal_percent += 0.05
			print("暗焰爆弹升级: 生命偷取增加")
		10:
			explosion_radius *= 1.3
			print("暗焰爆弹升级: 爆炸范围增加")
		15:
			burn_duration += 1.0
			print("暗焰爆弹升级: 燃烧时间增加")
