## LifeSiphon - 生命虹吸
## 暗影系范围法术
class_name LifeSiphon
extends AoESpell

# 生命虹吸特有属性
@export var siphon_percent: float = 0.03  # 吸取3%最大生命值
@export var siphon_radius: float = 150.0  # 虹吸范围
@export var siphon_duration: float = 1.0  # 虹吸持续时间
@export var siphon_interval: float = 0.5  # 虹吸间隔

func _init() -> void:
	spell_name = "生命虹吸"
	spell_element = "shadow"
	spell_type = SpellType.AOE
	damage = 0  # 本身无伤害，只有吸取
	cooldown = 8.0
	mana_cost = 25.0
	aoe_radius = siphon_radius

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取施放位置
	var cast_position = owner_node.global_position if owner_node else Vector2.ZERO
	
	# 创建生命虹吸效果
	_create_life_siphon_effect(cast_position)

## 创建生命虹吸效果
func _create_life_siphon_effect(position: Vector2) -> void:
	# 创建虹吸区域
	var siphon_area = Area2D.new()
	siphon_area.global_position = position
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = siphon_radius
	collision.shape = circle
	siphon_area.add_child(collision)
	
	# 设置碰撞层
	siphon_area.collision_layer = 0
	siphon_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(siphon_area)
	
	# 创建视觉效果
	_create_siphon_visual(siphon_area)
	
	# 持续吸取生命
	_process_siphon_damage(siphon_area)
	
	# 持续时间结束后销毁
	await get_tree().create_timer(siphon_duration).timeout
	siphon_area.queue_free()

## 创建虹吸视觉效果
func _create_siphon_visual(area: Area2D) -> void:
	# 创建虹吸精灵
	var siphon_sprite = Sprite2D.new()
	siphon_sprite.name = "LifeSiphonSprite"
	siphon_sprite.modulate = Color(0.5, 0.0, 0.5, 0.6)  # 深紫色
	siphon_sprite.scale = Vector2(2.0, 2.0)
	area.add_child(siphon_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "LifeSiphonParticles"
	particles.emitting = true
	particles.lifetime = siphon_duration
	particles.amount = 15
	area.add_child(particles)

## 持续吸取生命
func _process_siphon_damage(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < siphon_duration:
		# 等待虹吸间隔
		await get_tree().create_timer(siphon_interval).timeout
		elapsed += siphon_interval
		
		# 获取范围内的敌人
		var enemies = _get_enemies_in_aoe(area.global_position, siphon_radius)
		
		for enemy in enemies:
			# 计算吸取量
			if enemy.has_method("get_max_health"):
				var max_health = enemy.get_max_health()
				var siphon_amount = max_health * siphon_percent
				
				# 应用吸取伤害
				if enemy.has_method("take_damage"):
					enemy.take_damage(siphon_amount, owner_node)
				
				# 为玩家恢复生命
				if owner_node and owner_node.has_method("heal"):
					owner_node.heal(siphon_amount)
				
				# 创建吸取视觉效果
				_create_siphon_line(area.global_position, enemy.global_position)

## 创建吸取连线视觉效果
func _create_siphon_line(from: Vector2, to: Vector2) -> void:
	# 创建吸取精灵
	var siphon_line = Sprite2D.new()
	siphon_line.modulate = Color(0.5, 0.0, 0.5, 0.7)  # 深紫色
	siphon_line.global_position = (from + to) / 2.0
	siphon_line.rotation = from.angle_to_point(to)
	siphon_line.scale = Vector2(1.0, 0.1)  # 压缩成线状
	get_tree().current_scene.add_child(siphon_line)
	
	# 延迟销毁
	await get_tree().create_timer(0.1).timeout
	siphon_line.queue_free()

## 重写法术升级
func _on_upgrade() -> void:
	siphon_percent *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 范围+30%
			siphon_radius *= 1.3
			aoe_radius = siphon_radius
			print("生命虹吸升级: 范围增加")
		10:
			# Lv.10: 吸取+2%
			siphon_percent += 0.02
			print("生命虹吸升级: 吸取量增加")
		15:
			# Lv.15: 暗影领域
			print("生命虹吸升级: 暗影领域")