## SteamBlast - 蒸汽爆炸
## 火焰+水流融合：高温蒸汽，持续伤害+降低视野
class_name SteamBlast
extends FusionSpell

# 蒸汽爆炸特有属性
@export var steam_radius: float = 120.0  # 蒸汽范围
@export var steam_duration: float = 4.0  # 持续时间
@export var steam_damage_per_second: float = 15.0  # 每秒伤害
@export var vision_reduction: float = 0.3  # 视野降低30%
@export var slow_amount: float = 0.2  # 减速20%

func _init() -> void:
	spell_name = "蒸汽爆炸"
	spell_element = "fusion"
	spell_type = SpellType.AOE
	damage = 40.0
	cooldown = 6.0
	mana_cost = 25.0
	
	# 融合属性
	element1 = "fire"
	element2 = "water"
	required_spell1 = "F1"
	required_spell2 = "W1"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	# 获取施放位置
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	# 创建蒸汽爆炸效果
	_create_steam_blast(cast_position)

## 创建蒸汽爆炸效果
func _create_steam_blast(position: Vector2) -> void:
	# 创建蒸汽区域
	var steam_area = Area2D.new()
	steam_area.global_position = position
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = steam_radius
	collision.shape = circle
	steam_area.add_child(collision)
	
	# 设置碰撞层
	steam_area.collision_layer = 0
	steam_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(steam_area)
	
	# 创建视觉效果
	_create_steam_visual(steam_area)
	
	# 持续造成伤害和效果
	_process_steam_damage(steam_area)
	
	# 持续时间结束后销毁
	await get_tree().create_timer(steam_duration).timeout
	steam_area.queue_free()

## 创建蒸汽视觉效果
func _create_steam_visual(area: Area2D) -> void:
	# 创建蒸汽精灵
	var steam_sprite = Sprite2D.new()
	steam_sprite.name = "SteamBlastSprite"
	steam_sprite.modulate = Color(0.8, 0.8, 0.9, 0.6)  # 蒸汽色
	steam_sprite.scale = Vector2(2.0, 2.0)
	area.add_child(steam_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "SteamBlastParticles"
	particles.emitting = true
	particles.lifetime = steam_duration
	particles.amount = 20
	area.add_child(particles)

## 持续造成伤害和效果
func _process_steam_damage(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < steam_duration:
		# 等待1秒
		await get_tree().create_timer(1.0).timeout
		elapsed += 1.0
		
		# 获取范围内的敌人
		var enemies = _get_enemies_in_range(area.global_position, steam_radius)
		
		for enemy in enemies:
			# 应用蒸汽伤害
			if enemy.has_method("take_damage"):
				enemy.take_damage(steam_damage_per_second, owner_node)
			
			# 应用减速效果
			if enemy.has_method("apply_status_effect"):
				enemy.apply_status_effect(
					StatusEffectSystem.EffectType.SLOW,
					slow_amount,
					2.0
				)
			
			# 应用视野降低效果（如果敌人有此方法）
			if enemy.has_method("apply_vision_reduction"):
				enemy.apply_vision_reduction(vision_reduction, 2.0)

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	# 蒸汽爆炸的融合效果：范围伤害+减速
	_damage_enemies_in_range(position, steam_radius)

## 重写法术升级
func _on_upgrade() -> void:
	steam_damage_per_second *= 1.1
	
	match spell_level:
		5:
			# Lv.5: 范围+20%
			steam_radius *= 1.2
			print("蒸汽爆炸升级: 范围增加")
		10:
			# Lv.10: 伤害+50%
			steam_damage_per_second *= 1.5
			print("蒸汽爆炸升级: 伤害增加")
		15:
			# Lv.15: 解锁蒸汽领域
			print("蒸汽爆炸升级: 解锁蒸汽领域")