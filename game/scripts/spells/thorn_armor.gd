## ThornArmor - 荆棘甲
## 自然系防御法术
class_name ThornArmor
extends BuffSpell

# 荆棘甲特有属性
@export var reflect_percent: float = 0.2  # 反弹20%伤害
@export var armor_duration: float = 6.0  # 持续时间
@export var reflect_damage_type: String = "melee"  # 反弹近战伤害

func _init() -> void:
	spell_name = "荆棘甲"
	spell_element = "nature"
	spell_type = SpellType.SHIELD
	damage = 0
	cooldown = 12.0
	mana_cost = 20.0
	buff_type = "shield"
	buff_duration = armor_duration

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 应用荆棘甲效果
	_apply_thorn_armor(target if target else owner_node)

## 应用荆棘甲效果
func _apply_thorn_armor(target: Node2D) -> void:
	# 播放荆棘甲视觉效果
	_play_thorn_armor_visual(target)
	
	# 开始荆棘甲持续时间
	is_active = true
	active_timer = armor_duration
	
	# 监听受到的伤害事件
	_monitor_damage_events(target)

## 播放荆棘甲视觉效果
func _play_thorn_armor_visual(target: Node2D) -> void:
	# 创建荆棘甲精灵
	var armor_sprite = Sprite2D.new()
	armor_sprite.name = "ThornArmorSprite"
	armor_sprite.modulate = Color(0.4, 0.8, 0.2, 0.6)  # 绿色
	armor_sprite.scale = Vector2(1.5, 1.5)
	target.add_child(armor_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "ThornArmorParticles"
	particles.emitting = true
	particles.lifetime = armor_duration
	particles.amount = 10
	target.add_child(particles)

## 监听伤害事件
func _monitor_damage_events(target: Node2D) -> void:
	# 连接伤害信号（如果存在）
	if target.has_signal("damage_received"):
		target.damage_received.connect(_on_damage_received.bind(target))

## 收到伤害时的处理
func _on_damage_received(damage: float, damage_source: Node2D, target: Node2D) -> void:
	# 检查是否为近战伤害
	if _is_melee_damage(damage_source):
		# 反弹伤害
		var reflect_damage = damage * reflect_percent
		
		if damage_source.has_method("take_damage"):
			damage_source.take_damage(reflect_damage, target)
		
		# 创建反弹视觉效果
		_create_reflect_visual(target.global_position, damage_source.global_position)

## 判断是否为近战伤害
func _is_melee_damage(source: Node2D) -> bool:
	# 简单判断：如果来源在近距离，则认为是近战伤害
	if source and owner_node:
		var distance = owner_node.global_position.distance_to(source.global_position)
		return distance < 100.0
	return false

## 创建反弹视觉效果
func _create_reflect_visual(from: Vector2, to: Vector2) -> void:
	# 创建反弹精灵
	var reflect_sprite = Sprite2D.new()
	reflect_sprite.modulate = Color(0.4, 0.8, 0.2, 0.7)  # 绿色
	reflect_sprite.global_position = (from + to) / 2.0
	reflect_sprite.rotation = from.angle_to_point(to)
	reflect_sprite.scale = Vector2(1.0, 0.1)  # 压缩成线状
	get_tree().current_scene.add_child(reflect_sprite)
	
	# 延迟销毁
	await get_tree().create_timer(0.1).timeout
	reflect_sprite.queue_free()

## 重写法术升级
func _on_upgrade() -> void:
	reflect_percent *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 反弹+15%
			reflect_percent += 0.15
			print("荆棘甲升级: 反弹伤害增加")
		10:
			# Lv.10: 反弹+40%
			reflect_percent += 0.4
			print("荆棘甲升级: 反弹伤害大幅增加")
		15:
			# Lv.15: 荆棘领域
			print("荆棘甲升级: 荆棘领域")