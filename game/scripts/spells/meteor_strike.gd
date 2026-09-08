## MeteorStrike - 陨石坠落
## 火焰系地面AoE法术
class_name MeteorStrike
extends AoESpell

# 陨石特有属性
@export var cast_delay: float = 1.5  # 施放延迟
@export var explosion_radius: float = 100.0  # 爆炸范围
@export var meteor_damage: float = 50.0  # 陨石伤害

func _init() -> void:
	spell_name = "陨石坠落"
	spell_element = "fire"
	spell_type = SpellType.GROUND_AOE
	damage = meteor_damage
	cooldown = 8.0
	mana_cost = 30.0
	aoe_radius = explosion_radius
	aoe_delay = cast_delay

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取施放位置
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	# 延迟后召唤陨石
	await get_tree().create_timer(cast_delay).timeout
	
	# 创建陨石效果
	_create_meteor_effect(cast_position)

## 创建陨石效果
func _create_meteor_effect(position: Vector2) -> void:
	# 创建陨石区域
	var meteor_area = Area2D.new()
	meteor_area.global_position = position
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = explosion_radius
	collision.shape = circle
	meteor_area.add_child(collision)
	
	# 设置碰撞层
	meteor_area.collision_layer = 0
	meteor_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(meteor_area)
	
	# 创建视觉效果
	_create_meteor_visual(meteor_area)
	
	# 处理伤害
	_process_meteor_damage(meteor_area)
	
	# 延迟销毁
	await get_tree().create_timer(0.5).timeout
	meteor_area.queue_free()

## 创建陨石视觉效果
func _create_meteor_visual(area: Area2D) -> void:
	# 创建陨石精灵
	var sprite = Sprite2D.new()
	sprite.modulate = Color(1.0, 0.5, 0.0, 0.8)  # 橙红色
	area.add_child(sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.lifetime = 0.5
	particles.amount = 20
	area.add_child(particles)

## 处理陨石伤害
func _process_meteor_damage(area: Area2D) -> void:
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			_apply_damage(body)
			
			# 应用击退效果
			if body.has_method("apply_knockback"):
				var knockback_direction = area.global_position.direction_to(body.global_position)
				body.apply_knockback(knockback_direction, 200.0)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 延迟缩短至1s
			cast_delay = 1.0
			aoe_delay = cast_delay
			print("陨石坠落升级: 施放延迟缩短")
		10:
			# Lv.10: 3连陨石
			print("陨石坠落升级: 变为3连陨石")
		15:
			# Lv.15: 陨石碎片散射
			print("陨石坠落升级: 陨石碎片散射")