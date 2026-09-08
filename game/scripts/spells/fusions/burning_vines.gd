## BurningVines - 焚烧藤蔓
## 火焰+自然融合：燃烧藤蔓，缠绕敌人并造成持续燃烧
class_name BurningVines
extends FusionSpell

# 焚烧藤蔓特有属性
@export var entangle_radius: float = 100.0  # 缠绕范围
@export var entangle_duration: float = 3.0  # 缠绕持续时间
@export var burn_damage_per_second: float = 12.0  # 每秒燃烧伤害
@export var burn_duration: float = 4.0  # 燃烧持续时间
@export var vine_count: int = 5  # 藤蔓数量

func _init() -> void:
	spell_name = "焚烧藤蔓"
	spell_element = "fusion"
	spell_type = SpellType.AOE
	damage = 35.0
	cooldown = 7.0
	mana_cost = 30.0
	
	# 融合属性
	element1 = "fire"
	element2 = "nature"
	required_spell1 = "N1"
	required_spell2 = "F2"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	# 创建焚烧藤蔓效果
	_create_burning_vines(cast_position)

## 创建焚烧藤蔓效果
func _create_burning_vines(position: Vector2) -> void:
	# 获取范围内的敌人
	var enemies = _get_enemies_in_range(position, entangle_radius)
	
	for enemy in enemies:
		# 应用缠绕效果（减速+无法移动）
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.SLOW,
				0.8,  # 减速80%
				entangle_duration
			)
		
		# 应用燃烧伤害
		_apply_burn_damage(enemy)
		
		# 应用初始伤害
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, owner_node)
	
	# 创建藤蔓视觉效果
	_create_vine_visuals(position, enemies.size())

## 应用燃烧伤害
func _apply_burn_damage(enemy: Node2D) -> void:
	var elapsed = 0.0
	while elapsed < burn_duration:
		await get_tree().create_timer(1.0).timeout
		elapsed += 1.0
		
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(burn_damage_per_second, owner_node)
		else:
			break

## 创建藤蔓视觉效果
func _create_vine_visuals(position: Vector2, count: int) -> void:
	for i in range(min(count, vine_count)):
		var vine = Sprite2D.new()
		vine.modulate = Color(0.6, 0.3, 0.1, 0.8)  # 燃烧藤蔓色
		vine.global_position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		vine.rotation = randf() * TAU
		get_tree().current_scene.add_child(vine)
		
		# 延迟销毁
		await get_tree().create_timer(entangle_duration + burn_duration).timeout
		if is_instance_valid(vine):
			vine.queue_free()

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	_damage_enemies_in_range(position, entangle_radius)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	burn_damage_per_second *= 1.1
	
	match spell_level:
		5:
			entangle_radius *= 1.2
			print("焚烧藤蔓升级: 范围增加")
		10:
			burn_duration += 1.0
			print("焚烧藤蔓升级: 燃烧时间增加")
		15:
			vine_count += 3
			print("焚烧藤蔓升级: 藤蔓数量增加")
