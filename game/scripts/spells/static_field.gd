## StaticField - 静电场
## 雷电系被动光环法术
class_name StaticField
extends BaseSpell

# 静电场特有属性
@export var field_radius: float = 100.0  # 静电场范围
@export var stun_chance: float = 0.15  # 麻痹概率15%
@export var stun_duration: float = 1.0  # 麻痹持续时间
@export var damage_per_second: float = 5.0  # 每秒伤害
@export var hit_interval: float = 1.0  # 伤害间隔

# 状态
var is_active: bool = false
var field_visual: Node2D = null

func _init() -> void:
	spell_name = "静电场"
	spell_element = "lightning"
	spell_type = SpellType.BUFF
	damage = damage_per_second
	cooldown = 0.0  # 被动光环，无冷却
	mana_cost = 0.0  # 被动光环，无法力消耗

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 激活静电场
	_activate_static_field()

## 激活静电场
func _activate_static_field() -> void:
	is_active = true
	
	# 创建视觉效果
	_create_field_visual()
	
	# 开始被动效果
	_process_field_damage()

## 创建静电场视觉效果
func _create_field_visual() -> void:
	# 创建静电场精灵
	field_visual = Sprite2D.new()
	field_visual.name = "StaticFieldVisual"
	field_visual.modulate = Color(1.0, 1.0, 0.0, 0.4)  # 黄色
	field_visual.scale = Vector2(2.0, 2.0)
	owner_node.add_child(field_visual)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "StaticFieldParticles"
	particles.emitting = true
	particles.lifetime = 1.0
	particles.amount = 10
	owner_node.add_child(particles)

## 被动效果处理
func _process_field_damage() -> void:
	while is_active:
		# 等待伤害间隔
		await get_tree().create_timer(hit_interval).timeout
		
		# 获取范围内的敌人
		var enemies = _get_enemies_in_circle(field_radius)
		
		for enemy in enemies:
			# 应用伤害
			_apply_damage(enemy)
			
			# 概率麻痹
			if randf() < stun_chance:
				if enemy.has_method("apply_status_effect"):
					enemy.apply_status_effect(
						StatusEffectSystem.EffectType.STUN,
						0.0,
						stun_duration
					)
				
				# 创建麻痹视觉效果
				_create_stun_visual(enemy.global_position)

## 获取范围内敌人
func _get_enemies_in_circle(range: float) -> Array[Node2D]:
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

## 创建麻痹视觉效果
func _create_stun_visual(position: Vector2) -> void:
	# 创建麻痹精灵
	var stun_sprite = Sprite2D.new()
	stun_sprite.modulate = Color(1.0, 1.0, 0.5, 0.8)  # 浅黄色
	stun_sprite.global_position = position
	get_tree().current_scene.add_child(stun_sprite)
	
	# 延迟销毁
	await get_tree().create_timer(0.2).timeout
	stun_sprite.queue_free()

## 停用静电场
func deactivate() -> void:
	is_active = false
	
	# 移除视觉效果
	if owner_node.has_node("StaticFieldVisual"):
		owner_node.get_node("StaticFieldVisual").queue_free()
	
	if owner_node.has_node("StaticFieldParticles"):
		owner_node.get_node("StaticFieldParticles").queue_free()

## 重写法术升级
func _on_upgrade() -> void:
	damage_per_second *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 范围+30%
			field_radius *= 1.3
			print("静电场升级: 范围增加")
		10:
			# Lv.10: 麻痹率+15%
			stun_chance += 0.15
			print("静电场升级: 麻痹概率增加")
		15:
			# Lv.15: 被动闪电
			print("静电场升级: 被动闪电")