## FireShield - 火焰屏障
## 火焰系环绕法术
class_name FireShield
extends BaseSpell

# 火焰屏障特有属性
@export var shield_duration: float = 5.0  # 持续时间
@export var damage_per_second: float = 10.0  # 每秒伤害
@export var shield_radius: float = 80.0  # 护盾范围
@export var hit_cooldown: float = 0.5  # 对同一敌人的伤害冷却

# 状态
var is_active: bool = false
var active_timer: float = 0.0
var hit_targets: Dictionary = {}  # 记录已命中目标和冷却时间

func _init() -> void:
	spell_name = "火焰屏障"
	spell_element = "fire"
	spell_type = SpellType.BUFF
	damage = damage_per_second
	cooldown = 12.0
	mana_cost = 25.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 激活火焰屏障
	_activate_shield()

## 激活护盾
func _activate_shield() -> void:
	is_active = true
	active_timer = shield_duration
	
	# 创建视觉效果
	_create_shield_visual()
	
	# 开始持续伤害
	_process_damage_loop()

## 创建护盾视觉效果
func _create_shield_visual() -> void:
	# 创建护盾精灵
	var shield_sprite = Sprite2D.new()
	shield_sprite.name = "FireShieldSprite"
	shield_sprite.modulate = Color(1.0, 0.3, 0.0, 0.6)  # 橙红色
	shield_sprite.scale = Vector2(2.0, 2.0)  # 放大以覆盖范围
	owner_node.add_child(shield_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "FireShieldParticles"
	particles.emitting = true
	particles.lifetime = 1.0
	particles.amount = 15
	particles.process_material = _create_fire_particles_material()
	owner_node.add_child(particles)

## 创建火焰粒子材质
func _create_fire_particles_material() -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_axis = Vector3(0, 0, 0)
	material.emission_ring_height = 0.0
	material.emission_ring_inner_radius = shield_radius * 0.8
	material.emission_ring_radius = shield_radius
	return material

## 持续伤害循环
func _process_damage_loop() -> void:
	while is_active and active_timer > 0:
		# 获取范围内的敌人
		var enemies = _get_enemies_in_range(shield_radius)
		
		for enemy in enemies:
			# 检查伤害冷却
			var enemy_id = enemy.get_instance_id()
			var current_time = Time.get_ticks_msec() / 1000.0
			
			if not hit_targets.has(enemy_id) or current_time - hit_targets[enemy_id] >= hit_cooldown:
				# 应用伤害
				_apply_damage(enemy)
				
				# 应用燃烧效果
				if enemy.has_method("apply_status_effect"):
					enemy.apply_status_effect(
						StatusEffectSystem.EffectType.BURN,
						damage_per_second * 0.2,  # 20%伤害/秒
						2.0
					)
				
				# 更新冷却时间
				hit_targets[enemy_id] = current_time
		
		# 等待下一帧
		await get_tree().process_frame

## 获取范围内敌人
func _get_enemies_in_range(range: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = range
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, owner_node.global_position)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			enemies.append(collider)
	
	return enemies

## 更新状态
func _process(delta: float) -> void:
	# 先调用父类的冷却更新
	super._process(delta)
	
	# 更新护盾持续时间
	if is_active:
		active_timer -= delta
		if active_timer <= 0:
			_deactivate_shield()

## 停用护盾
func _deactivate_shield() -> void:
	is_active = false
	hit_targets.clear()
	
	# 移除视觉效果
	if owner_node.has_node("FireShieldSprite"):
		owner_node.get_node("FireShieldSprite").queue_free()
	
	if owner_node.has_node("FireShieldParticles"):
		owner_node.get_node("FireShieldParticles").queue_free()

## 重写法术升级
func _on_upgrade() -> void:
	damage_per_second *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 持续+2秒
			shield_duration += 2.0
			print("火焰屏障升级: 持续时间增加")
		10:
			# Lv.10: 接触伤害翻倍
			damage_per_second *= 2.0
			print("火焰屏障升级: 接触伤害翻倍")
		15:
			# Lv.15: 护盾吸收伤害
			print("火焰屏障升级: 护盾吸收伤害")