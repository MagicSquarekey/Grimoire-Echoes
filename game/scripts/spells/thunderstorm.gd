## Thunderstorm - 雷暴领域
## 雷电系持续AoE法术
class_name Thunderstorm
extends AoESpell

# 雷暴领域特有属性
@export var storm_duration: float = 4.0  # 持续时间
@export var strike_interval: float = 0.8  # 打击间隔
@export var strike_damage: float = 15.0  # 每次打击伤害
@export var storm_radius: float = 120.0  # 雷暴范围
@export var stun_chance: float = 0.15  # 麻痹概率15%

func _init() -> void:
	spell_name = "雷暴领域"
	spell_element = "lightning"
	spell_type = SpellType.GROUND_AOE
	damage = strike_damage
	cooldown = 10.0
	mana_cost = 25.0
	aoe_radius = storm_radius

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取施放位置
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	# 创建雷暴领域
	_create_thunderstorm(cast_position)

## 创建雷暴领域
func _create_thunderstorm(position: Vector2) -> void:
	# 创建雷暴区域
	var storm_area = Area2D.new()
	storm_area.global_position = position
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = storm_radius
	collision.shape = circle
	storm_area.add_child(collision)
	
	# 设置碰撞层
	storm_area.collision_layer = 0
	storm_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(storm_area)
	
	# 创建视觉效果
	_create_storm_visual(storm_area)
	
	# 持续打击敌人
	_process_storm_damage(storm_area)
	
	# 持续时间结束后销毁
	await get_tree().create_timer(storm_duration).timeout
	storm_area.queue_free()

## 创建雷暴视觉效果
func _create_storm_visual(area: Area2D) -> void:
	# 创建雷暴精灵
	var storm_sprite = Sprite2D.new()
	storm_sprite.name = "ThunderstormSprite"
	storm_sprite.modulate = Color(1.0, 1.0, 0.0, 0.6)  # 黄色
	storm_sprite.scale = Vector2(2.0, 2.0)
	area.add_child(storm_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "ThunderstormParticles"
	particles.emitting = true
	particles.lifetime = storm_duration
	particles.amount = 20
	area.add_child(particles)

## 持续打击敌人
func _process_storm_damage(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < storm_duration:
		# 等待打击间隔
		await get_tree().create_timer(strike_interval).timeout
		elapsed += strike_interval
		
		# 获取范围内的敌人
		var enemies = _get_enemies_in_aoe(area.global_position, storm_radius)
		
		if enemies.size() > 0:
			# 随机选择一个敌人进行打击
			var random_enemy = enemies[randi() % enemies.size()]
			
			# 应用伤害
			_apply_damage(random_enemy)
			
			# 概率麻痹
			if randf() < stun_chance:
				if random_enemy.has_method("apply_status_effect"):
					random_enemy.apply_status_effect(
						StatusEffectSystem.EffectType.STUN,
						0.0,
						1.0  # 麻痹1秒
					)
			
			# 创建闪电视觉效果
			_create_lightning_visual(area.global_position, random_enemy.global_position)

## 创建闪电视觉效果
func _create_lightning_visual(from: Vector2, to: Vector2) -> void:
	# 创建闪电精灵
	var lightning_sprite = Sprite2D.new()
	lightning_sprite.modulate = Color(1.0, 1.0, 0.5, 0.8)  # 浅黄色
	lightning_sprite.global_position = (from + to) / 2.0
	lightning_sprite.rotation = from.angle_to_point(to)
	lightning_sprite.scale = Vector2(1.0, 0.1)  # 压缩成线状
	get_tree().current_scene.add_child(lightning_sprite)
	
	# 延迟销毁
	await get_tree().create_timer(0.1).timeout
	lightning_sprite.queue_free()

## 重写法术升级
func _on_upgrade() -> void:
	strike_damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 持续+2秒
			storm_duration += 2.0
			print("雷暴领域升级: 持续时间增加")
		10:
			# Lv.10: 打击频率翻倍
			strike_interval /= 2.0
			print("雷暴领域升级: 打击频率翻倍")
		15:
			# Lv.15: 雷暴追踪
			print("雷暴领域升级: 雷暴追踪")