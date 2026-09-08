## LifeSpring - 生命之泉
## 水流+自然融合：治愈之泉，持续治疗队友并减速敌人
class_name LifeSpring
extends FusionSpell

# 生命之泉特有属性
@export var heal_radius: float = 150.0  # 治疗范围
@export var heal_duration: float = 6.0  # 持续时间
@export var heal_per_second: float = 8.0  # 每秒治疗量
@export var enemy_slow_amount: float = 0.4  # 敌人减速40%
@export var enemy_damage_per_second: float = 5.0  # 每秒对敌人伤害

func _init() -> void:
	spell_name = "生命之泉"
	spell_element = "fusion"
	spell_type = SpellType.BUFF
	damage = 0.0
	cooldown = 10.0
	mana_cost = 30.0
	
	element1 = "water"
	element2 = "nature"
	required_spell1 = "W1"
	required_spell2 = "N2"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_position = Vector2.ZERO
	if owner_node:
		cast_position = owner_node.global_position
	
	_create_life_spring(cast_position)

## 创建生命之泉
func _create_life_spring(position: Vector2) -> void:
	# 创建治疗区域
	var spring_area = Area2D.new()
	spring_area.global_position = position
	
	# 碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = heal_radius
	collision.shape = circle
	spring_area.add_child(collision)
	
	# 设置碰撞层
	spring_area.collision_layer = 0
	spring_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(spring_area)
	
	# 创建视觉效果
	_create_spring_visual(spring_area)
	
	# 持续效果
	_process_spring_effects(spring_area)
	
	# 持续时间结束后销毁
	await get_tree().create_timer(heal_duration).timeout
	spring_area.queue_free()

## 创建视觉效果
func _create_spring_visual(area: Area2D) -> void:
	var sprite = Sprite2D.new()
	sprite.name = "LifeSpringSprite"
	sprite.modulate = Color(0.2, 0.8, 0.4, 0.5)
	sprite.scale = Vector2(3.0, 3.0)
	area.add_child(sprite)
	
	var particles = GPUParticles2D.new()
	particles.name = "LifeSpringParticles"
	particles.emitting = true
	particles.lifetime = heal_duration
	particles.amount = 15
	area.add_child(particles)

## 持续处理效果
func _process_spring_effects(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < heal_duration:
		await get_tree().create_timer(1.0).timeout
		elapsed += 1.0
		
		# 治疗玩家
		if owner_node and owner_node.has_method("heal"):
			owner_node.heal(heal_per_second)
		
		# 对敌人造成效果
		var enemies = _get_enemies_in_range(area.global_position, heal_radius)
		for enemy in enemies:
			# 减速敌人
			if enemy.has_method("apply_status_effect"):
				enemy.apply_status_effect(
					StatusEffectSystem.EffectType.SLOW,
					enemy_slow_amount,
					2.0
				)
			
			# 对敌人造成伤害
			if enemy.has_method("take_damage"):
				enemy.take_damage(enemy_damage_per_second, owner_node)

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	# 生命之泉的融合效果：立即治疗
	if owner_node and owner_node.has_method("heal"):
		owner_node.heal(heal_per_second * 3)

## 重写法术升级
func _on_upgrade() -> void:
	heal_per_second *= 1.1
	
	match spell_level:
		5:
			heal_radius *= 1.2
			print("生命之泉升级: 范围增加")
		10:
			heal_duration += 1.0
			print("生命之泉升级: 持续时间增加")
		15:
			enemy_slow_amount += 0.1
			print("生命之泉升级: 减速效果增强")
