## PollenBomb - 花粉炸弹
## 自然系AoE法术
class_name PollenBomb
extends AoESpell

# 花粉炸弹特有属性
@export var bomb_duration: float = 5.0  # 持续时间
@export var damage_per_second: float = 15.0  # 每秒伤害
@export var blind_chance: float = 0.2  # 致盲概率20%
@export var blind_duration: float = 2.0  # 致盲持续时间
@export var bomb_radius: float = 100.0  # 花粉范围

func _init() -> void:
	spell_name = "花粉炸弹"
	spell_element = "nature"
	spell_type = SpellType.GROUND_AOE
	damage = damage_per_second
	cooldown = 6.0
	mana_cost = 20.0
	aoe_radius = bomb_radius

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取施放位置
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	# 创建花粉炸弹
	_create_pollen_bomb(cast_position)

## 创建花粉炸弹
func _create_pollen_bomb(position: Vector2) -> void:
	# 创建花粉区域
	var pollen_area = Area2D.new()
	pollen_area.global_position = position
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = bomb_radius
	collision.shape = circle
	pollen_area.add_child(collision)
	
	# 设置碰撞层
	pollen_area.collision_layer = 0
	pollen_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(pollen_area)
	
	# 创建视觉效果
	_create_pollen_visual(pollen_area)
	
	# 持续造成伤害和致盲效果
	_process_pollen_damage(pollen_area)
	
	# 持续时间结束后销毁
	await get_tree().create_timer(bomb_duration).timeout
	pollen_area.queue_free()

## 创建花粉视觉效果
func _create_pollen_visual(area: Area2D) -> void:
	# 创建花粉精灵
	var pollen_sprite = Sprite2D.new()
	pollen_sprite.name = "PollenBombSprite"
	pollen_sprite.modulate = Color(0.8, 0.9, 0.2, 0.6)  # 黄绿色
	pollen_sprite.scale = Vector2(2.0, 2.0)
	area.add_child(pollen_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "PollenBombParticles"
	particles.emitting = true
	particles.lifetime = bomb_duration
	particles.amount = 20
	area.add_child(particles)

## 持续造成伤害和致盲效果
func _process_pollen_damage(area: Area2D) -> void:
	var elapsed = 0.0
	while elapsed < bomb_duration:
		# 等待1秒
		await get_tree().create_timer(1.0).timeout
		elapsed += 1.0
		
		# 获取范围内的敌人
		var enemies = _get_enemies_in_aoe(area.global_position, bomb_radius)
		
		for enemy in enemies:
			# 应用伤害
			_apply_damage(enemy)
			
			# 概率致盲
			if randf() < blind_chance:
				if enemy.has_method("apply_status_effect"):
					enemy.apply_status_effect(
						StatusEffectSystem.EffectType.BLIND,
						0.3,  # 命中率降低30%
						blind_duration
					)

## 重写法术升级
func _on_upgrade() -> void:
	damage_per_second *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 范围+30%
			bomb_radius *= 1.3
			aoe_radius = bomb_radius
			print("花粉炸弹升级: 范围增加")
		10:
			# Lv.10: 致盲效果增强
			blind_chance += 0.15
			print("花粉炸弹升级: 致盲概率增加")
		15:
			# Lv.15: 毒雾扩散
			print("花粉炸弹升级: 毒雾扩散")