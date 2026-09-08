## IceSpikeArray - 冰锥阵列
## 水流系地面AoE法术
class_name IceSpikeArray
extends AoESpell

# 冰锥阵列特有属性
@export var spike_count: int = 4  # 冰锥数量
@export var spike_interval: float = 0.5  # 冰锥生成间隔
@export var array_duration: float = 3.0  # 持续时间
@export var slow_amount: float = 0.3  # 减速30%
@export var slow_duration: float = 2.0  # 减速持续时间

func _init() -> void:
	spell_name = "冰锥阵列"
	spell_element = "water"
	spell_type = SpellType.GROUND_AOE
	damage = 20.0
	cooldown = 5.0
	mana_cost = 20.0
	aoe_radius = 150.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取施放位置
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	# 创建冰锥阵列
	_create_ice_spike_array(cast_position)

## 创建冰锥阵列
func _create_ice_spike_array(position: Vector2) -> void:
	# 创建阵列区域
	var array_area = Area2D.new()
	array_area.global_position = position
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = aoe_radius
	collision.shape = circle
	array_area.add_child(collision)
	
	# 设置碰撞层
	array_area.collision_layer = 0
	array_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(array_area)
	
	# 创建视觉效果
	_create_array_visual(array_area)
	
	# 持续造成伤害
	_process_array_damage(array_area)
	
	# 持续时间结束后销毁
	await get_tree().create_timer(array_duration).timeout
	array_area.queue_free()

## 创建阵列视觉效果
func _create_array_visual(area: Area2D) -> void:
	# 创建冰锥精灵
	for i in range(spike_count):
		var spike_sprite = Sprite2D.new()
		spike_sprite.name = "IceSpike_%d" % i
		spike_sprite.modulate = Color(0.7, 0.9, 1.0, 0.8)  # 冰蓝色
		spike_sprite.position = Vector2(randf_range(-aoe_radius, aoe_radius), randf_range(-aoe_radius, aoe_radius))
		area.add_child(spike_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.lifetime = array_duration
	particles.amount = 10
	area.add_child(particles)

## 持续造成伤害
func _process_array_damage(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < array_duration:
		# 等待冰锥生成间隔
		await get_tree().create_timer(spike_interval).timeout
		elapsed += spike_interval
		
		# 获取范围内的敌人
		var enemies = _get_enemies_in_aoe(area.global_position, aoe_radius)
		
		for enemy in enemies:
			# 应用伤害
			_apply_damage(enemy)
			
			# 应用减速效果
			if enemy.has_method("apply_status_effect"):
				enemy.apply_status_effect(
					StatusEffectSystem.EffectType.SLOW,
					slow_amount,
					slow_duration
				)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 持续+2秒
			array_duration += 2.0
			print("冰锥阵列升级: 持续时间增加")
		10:
			# Lv.10: 6个冰锥
			spike_count = 6
			print("冰锥阵列升级: 冰锥数量增加")
		15:
			# Lv.15: 冰锥爆炸
			print("冰锥阵列升级: 冰锥爆炸")