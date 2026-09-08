## Tornado - 旋风
## 风暴系控制法术
class_name Tornado
extends AoESpell

# 旋风特有属性
@export var tornado_duration: float = 3.0  # 持续时间
@export var pull_force: float = 100.0  # 拉力
@export var tornado_radius: float = 120.0  # 旋风范围
@export var tornado_damage: float = 10.0  # 每秒伤害

func _init() -> void:
	spell_name = "旋风"
	spell_element = "air"
	spell_type = SpellType.AOE
	damage = tornado_damage
	cooldown = 8.0
	mana_cost = 20.0
	aoe_radius = tornado_radius

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取施放位置
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	# 创建旋风
	_create_tornado(cast_position)

## 创建旋风
func _create_tornado(position: Vector2) -> void:
	# 创建旋风区域
	var tornado_area = Area2D.new()
	tornado_area.global_position = position
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = tornado_radius
	collision.shape = circle
	tornado_area.add_child(collision)
	
	# 设置碰撞层
	tornado_area.collision_layer = 0
	tornado_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(tornado_area)
	
	# 创建视觉效果
	_create_tornado_visual(tornado_area)
	
	# 持续造成伤害和拉力效果
	_process_tornado_damage(tornado_area)
	
	# 持续时间结束后销毁
	await get_tree().create_timer(tornado_duration).timeout
	tornado_area.queue_free()

## 创建旋风视觉效果
func _create_tornado_visual(area: Area2D) -> void:
	# 创建旋风精灵
	var tornado_sprite = Sprite2D.new()
	tornado_sprite.name = "TornadoSprite"
	tornado_sprite.modulate = Color(0.8, 0.9, 1.0, 0.6)  # 浅蓝色
	tornado_sprite.scale = Vector2(2.0, 2.0)
	area.add_child(tornado_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "TornadoParticles"
	particles.emitting = true
	particles.lifetime = tornado_duration
	particles.amount = 20
	area.add_child(particles)

## 持续造成伤害和拉力效果
func _process_tornado_damage(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < tornado_duration:
		# 等待0.5秒
		await get_tree().create_timer(0.5).timeout
		elapsed += 0.5
		
		# 获取范围内的敌人
		var enemies = _get_enemies_in_aoe(area.global_position, tornado_radius)
		
		for enemy in enemies:
			# 应用伤害
			_apply_damage(enemy)
			
			# 应用拉力效果
			_apply_pull_force(area.global_position, enemy)

## 应用拉力效果
func _apply_pull_force(center: Vector2, enemy: Node2D) -> void:
	var direction = center - enemy.global_position
	var distance = direction.length()
	
	if distance > 10:  # 避免距离太近时的抖动
		# 计算拉力（距离越近，拉力越小）
		var force = pull_force * (1.0 - distance / tornado_radius)
		force = max(force, 0)
		
		# 应用拉力
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(direction.normalized(), force)

## 重写法术升级
func _on_upgrade() -> void:
	tornado_damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 持续+1秒
			tornado_duration += 1.0
			print("旋风升级: 持续时间增加")
		10:
			# Lv.10: 拉力翻倍
			pull_force *= 2.0
			print("旋风升级: 拉力翻倍")
		15:
			# Lv.15: 多旋风
			print("旋风升级: 多旋风")