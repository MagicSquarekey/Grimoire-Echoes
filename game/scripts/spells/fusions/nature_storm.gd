## NatureStorm - 自然风暴
## 自然+风暴融合：范围伤害并召唤藤蔓守卫
class_name NatureStorm
extends FusionSpell

# 自然风暴特有属性
@export var storm_radius: float = 150.0  # 风暴范围
@export var storm_duration: float = 5.0  # 持续时间
@export var damage_per_second: float = 15.0  # 每秒伤害
@export var summon_count: int = 3  # 召唤藤蔓数量
@export var summon_duration: float = 8.0  # 召唤持续时间
@export var summon_damage: float = 10.0  # 藤蔓伤害

func _init() -> void:
	spell_name = "自然风暴"
	spell_element = "fusion"
	spell_type = SpellType.AOE
	damage = 45.0
	cooldown = 10.0
	mana_cost = 40.0
	
	element1 = "nature"
	element2 = "air"
	required_spell1 = "A2"
	required_spell2 = "N4"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	_create_nature_storm(cast_position)

## 创建自然风暴
func _create_nature_storm(position: Vector2) -> void:
	var storm_area = Area2D.new()
	storm_area.global_position = position
	
	# 碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = storm_radius
	collision.shape = circle
	storm_area.add_child(collision)
	
	storm_area.collision_layer = 0
	storm_area.collision_mask = 2
	
	get_tree().current_scene.add_child(storm_area)
	
	# 视觉效果
	_create_storm_visual(storm_area)
	
	# 召唤藤蔓守卫
	_summon_vine_guards(position)
	
	# 持续效果
	_process_storm_effects(storm_area)
	
	# 销毁
	await get_tree().create_timer(storm_duration).timeout
	storm_area.queue_free()

## 创建视觉效果
func _create_storm_visual(area: Area2D) -> void:
	var sprite = Sprite2D.new()
	sprite.name = "NatureStormSprite"
	sprite.modulate = Color(0.4, 0.8, 0.3, 0.6)
	sprite.scale = Vector2(3.0, 3.0)
	area.add_child(sprite)
	
	var particles = GPUParticles2D.new()
	particles.name = "NatureStormParticles"
	particles.emitting = true
	particles.lifetime = storm_duration
	particles.amount = 20
	area.add_child(particles)

## 召唤藤蔓守卫
func _summon_vine_guards(position: Vector2) -> void:
	for i in range(summon_count):
		var vine_guard = Node2D.new()
		vine_guard.name = "VineGuard_%d" % i
		
		# 随机位置
		var angle = randf() * TAU
		var dist = randf_range(30, 80)
		vine_guard.global_position = position + Vector2(cos(angle), sin(angle)) * dist
		
		# 视觉效果
		var sprite = Sprite2D.new()
		sprite.modulate = Color(0.3, 0.7, 0.2, 0.8)
		vine_guard.add_child(sprite)
		
		# 碰撞形状
		var collision = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 20.0
		collision.shape = circle
		vine_guard.add_child(collision)
		
		get_tree().current_scene.add_child(vine_guard)
		
		# 藤蔓守卫攻击逻辑
		_process_vine_guard_attack(vine_guard)
		
		# 持续时间后销毁
		await get_tree().create_timer(summon_duration).timeout
		if is_instance_valid(vine_guard):
			vine_guard.queue_free()

## 藤蔓守卫攻击逻辑
func _process_vine_guard_attack(guard: Node2D) -> void:
	while is_instance_valid(guard):
		await get_tree().create_timer(1.0).timeout
		
		if not is_instance_valid(guard):
			break
		
		# 攻击范围内敌人
		var enemies = _get_enemies_in_range(guard.global_position, 60.0)
		for enemy in enemies:
			if enemy.has_method("take_damage"):
				enemy.take_damage(summon_damage, owner_node)

## 持续处理效果
func _process_storm_effects(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < storm_duration:
		await get_tree().create_timer(1.0).timeout
		elapsed += 1.0
		
		var enemies = _get_enemies_in_range(area.global_position, storm_radius)
		for enemy in enemies:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage_per_second, owner_node)

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	_damage_enemies_in_range(position, storm_radius)
	# 额外召唤一波藤蔓
	_summon_vine_guards(position)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	
	match spell_level:
		5:
			storm_radius *= 1.2
			print("自然风暴升级: 范围增加")
		10:
			summon_count += 1
			print("自然风暴升级: 藤蔓数量增加")
		15:
			summon_duration += 2.0
			print("自然风暴升级: 召唤持续时间增加")
