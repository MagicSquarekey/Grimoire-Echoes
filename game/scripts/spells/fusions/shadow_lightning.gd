## ShadowLightning - 暗影闪电
## 雷电+暗影融合：吸取生命并麻痹
class_name ShadowLightning
extends FusionSpell

# 暗影闪电特有属性
@export var projectile_speed: float = 400.0  # 投射物速度
@export var life_steal_percent: float = 0.18  # 生命偷取18%
@export var stun_duration: float = 1.0  # 麻痹持续时间
@export var chain_count: int = 2  # 连锁数量
@export var chain_range: float = 100.0  # 连锁范围

func _init() -> void:
	spell_name = "暗影闪电"
	spell_element = "fusion"
	spell_type = SpellType.PROJECTILE
	damage = 40.0
	cooldown = 6.0
	mana_cost = 28.0
	
	element1 = "lightning"
	element2 = "shadow"
	required_spell1 = "L1"
	required_spell2 = "D1"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_target = target
	if not cast_target:
		cast_target = _get_nearest_enemy()
	
	if cast_target:
		_create_shadow_lightning_projectile(cast_target)

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

## 创建暗影闪电投射物
func _create_shadow_lightning_projectile(target: Node2D) -> void:
	var projectile = Node2D.new()
	projectile.global_position = global_position
	
	var sprite = Sprite2D.new()
	sprite.modulate = Color(0.4, 0.2, 0.6, 0.9)
	projectile.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10.0
	collision.shape = circle
	projectile.add_child(collision)
	
	get_tree().current_scene.add_child(projectile)
	
	# 移动到目标
	var tween = projectile.create_tween()
	tween.tween_property(projectile, "global_position", target.global_position, 0.3)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	await tween.finished
	
	# 触发效果
	_trigger_shadow_lightning_effect(projectile.global_position)
	projectile.queue_free()

## 触发暗影闪电效果
func _trigger_shadow_lightning_effect(position: Vector2) -> void:
	var enemies = _get_enemies_in_range(position, chain_range + 50)
	var total_damage = 0.0
	var hit_count = 0
	
	for enemy in enemies:
		if hit_count >= chain_count + 1:
			break
		
		# 应用伤害
		var chain_damage = damage * pow(0.8, hit_count)
		if enemy.has_method("take_damage"):
			enemy.take_damage(chain_damage, owner_node)
			total_damage += chain_damage
		
		# 应用麻痹
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.STUN,
				1.0,
				stun_duration
			)
		
		# 创建闪电效果
		_create_lightning_visual(enemy.global_position)
		
		hit_count += 1
	
	# 生命偷取
	if owner_node and total_damage > 0 and owner_node.has_method("heal"):
		var heal_amount = total_damage * life_steal_percent
		owner_node.heal(heal_amount)

## 创建闪电视觉效果
func _create_lightning_visual(position: Vector2) -> void:
	var sprite = Sprite2D.new()
	sprite.modulate = Color(0.4, 0.2, 0.6, 0.8)
	sprite.global_position = position
	sprite.scale = Vector2(1.2, 1.2)
	get_tree().current_scene.add_child(sprite)
	
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(sprite):
		sprite.queue_free()

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	_trigger_shadow_lightning_effect(position)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	
	match spell_level:
		5:
			chain_count += 1
			print("暗影闪电升级: 连锁数量增加")
		10:
			life_steal_percent += 0.05
			print("暗影闪电升级: 生命偷取增加")
		15:
			stun_duration += 0.5
			print("暗影闪电升级: 麻痹时间增加")
