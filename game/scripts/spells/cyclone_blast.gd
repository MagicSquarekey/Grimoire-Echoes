## CycloneBlast - 气旋爆破
## 风暴系AoE法术
class_name CycloneBlast
extends AoESpell

# 气旋爆破特有属性
@export var blast_radius: float = 150.0  # 爆破范围
@export var blast_damage: float = 30.0  # 爆破伤害
@export var knockback_force: float = 300.0  # 击退力
@export var blast_delay: float = 0.2  # 爆破延迟

func _init() -> void:
	spell_name = "气旋爆破"
	spell_element = "air"
	spell_type = SpellType.AOE
	damage = blast_damage
	cooldown = 6.0
	mana_cost = 20.0
	aoe_radius = blast_radius

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取施放位置
	var cast_position = owner_node.global_position if owner_node else Vector2.ZERO
	
	# 创建气旋爆破效果
	_create_cyclone_blast(cast_position)

## 创建气旋爆破效果
func _create_cyclone_blast(position: Vector2) -> void:
	# 等待爆破延迟
	await get_tree().create_timer(blast_delay).timeout
	
	# 创建爆破区域
	var blast_area = Area2D.new()
	blast_area.global_position = position
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = blast_radius
	collision.shape = circle
	blast_area.add_child(collision)
	
	# 设置碰撞层
	blast_area.collision_layer = 0
	blast_area.collision_mask = 2  # 敌人层
	
	# 添加到场景
	get_tree().current_scene.add_child(blast_area)
	
	# 创建视觉效果
	_create_blast_visual(blast_area)
	
	# 处理伤害和击退效果
	_process_blast_damage(blast_area)
	
	# 延迟销毁
	await get_tree().create_timer(0.3).timeout
	blast_area.queue_free()

## 创建爆破视觉效果
func _create_blast_visual(area: Area2D) -> void:
	# 创建爆破精灵
	var blast_sprite = Sprite2D.new()
	blast_sprite.name = "CycloneBlastSprite"
	blast_sprite.modulate = Color(0.8, 0.9, 1.0, 0.7)  # 浅蓝色
	blast_sprite.scale = Vector2(2.0, 2.0)
	area.add_child(blast_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "CycloneBlastParticles"
	particles.emitting = true
	particles.one_shot = true
	particles.lifetime = 0.3
	particles.amount = 20
	area.add_child(particles)

## 处理爆破伤害和击退效果
func _process_blast_damage(area: Area2D) -> void:
	# 获取范围内的敌人
	var enemies = _get_enemies_in_aoe(area.global_position, blast_radius)
	
	for enemy in enemies:
		# 应用伤害
		_apply_damage(enemy)
		
		# 应用击退效果
		var knockback_direction = area.global_position.direction_to(enemy.global_position)
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(knockback_direction, knockback_force)

## 重写法术升级
func _on_upgrade() -> void:
	blast_damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 范围+30%
			blast_radius *= 1.3
			aoe_radius = blast_radius
			print("气旋爆破升级: 范围增加")
		10:
			# Lv.10: 击退+50%
			knockback_force *= 1.5
			print("气旋爆破升级: 击退力增加")
		15:
			# Lv.15: 气旋链
			print("气旋爆破升级: 气旋链")