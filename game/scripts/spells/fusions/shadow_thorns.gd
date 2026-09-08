## ShadowThorns - 暗影荆棘
## 自然+暗影融合：缠绕敌人并吸取生命
class_name ShadowThorns
extends FusionSpell

# 暗影荆棘特有属性
@export var entangle_radius: float = 110.0  # 缠绕范围
@export var entangle_duration: float = 3.0  # 缠绕持续时间
@export var life_steal_per_second: float = 6.0  # 每秒吸取生命
@export var thorn_damage_per_second: float = 8.0  # 每秒荆棘伤害
@export var slow_amount: float = 0.5  # 减速50%

func _init() -> void:
	spell_name = "暗影荆棘"
	spell_element = "fusion"
	spell_type = SpellType.CONTROL
	damage = 30.0
	cooldown = 7.0
	mana_cost = 25.0
	
	element1 = "nature"
	element2 = "shadow"
	required_spell1 = "N1"
	required_spell2 = "D1"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	_create_shadow_thorns(cast_position)

## 创建暗影荆棘
func _create_shadow_thorns(position: Vector2) -> void:
	var enemies = _get_enemies_in_range(position, entangle_radius)
	
	for enemy in enemies:
		# 应用缠绕（减速）
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.SLOW,
				slow_amount,
				entangle_duration
			)
		
		# 应用初始伤害
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, owner_node)
		
		# 持续吸取生命
		_process_drain(enemy)
	
	# 创建视觉效果
	_create_thorn_visuals(position, enemies.size())

## 持续吸取生命
func _process_drain(enemy: Node2D) -> void:
	var elapsed = 0.0
	while elapsed < entangle_duration:
		await get_tree().create_timer(1.0).timeout
		elapsed += 1.0
		
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			# 造成伤害
			enemy.take_damage(thorn_damage_per_second, owner_node)
			
			# 吸取生命
			if owner_node and owner_node.has_method("heal"):
				owner_node.heal(life_steal_per_second)
		else:
			break

## 创建荆棘视觉效果
func _create_thorn_visuals(position: Vector2, count: int) -> void:
	for i in range(min(count, 5)):
		var thorn = Sprite2D.new()
		thorn.modulate = Color(0.2, 0.4, 0.3, 0.7)
		thorn.global_position = position + Vector2(randf_range(-35, 35), randf_range(-35, 35))
		thorn.rotation = randf() * TAU
		get_tree().current_scene.add_child(thorn)
		
		await get_tree().create_timer(entangle_duration).timeout
		if is_instance_valid(thorn):
			thorn.queue_free()

## 重写融合效果触发
func _trigger_fusion_effect(position: Vector2) -> void:
	_damage_enemies_in_range(position, entangle_radius)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.1
	
	match spell_level:
		5:
			entangle_radius *= 1.2
			print("暗影荆棘升级: 范围增加")
		10:
			life_steal_per_second += 2.0
			print("暗影荆棘升级: 吸取生命增加")
		15:
			entangle_duration += 1.0
			print("暗影荆棘升级: 缠绕时间增加")
