## ThunderThorns - 雷霆荆棘
## 雷电+自然融合：带电荆棘，缠绕敌人并持续放电
class_name ThunderThorns
extends FusionSpell

# 雷霆荆棘特有属性
@export var entangle_radius: float = 100.0  # 缠绕范围
@export var entangle_duration: float = 3.5  # 缠绕持续时间
@export var shock_damage_per_second: float = 14.0  # 每秒放电伤害
@export var stun_chance: float = 0.25  # 麻痹概率
@export var thorn_count: int = 6  # 荆棘数量

func _init() -> void:
	spell_name = "雷霆荆棘"
	spell_element = "fusion"
	spell_type = SpellType.CONTROL
	damage = 38.0
	cooldown = 6.0
	mana_cost = 27.0
	
	element1 = "lightning"
	element2 = "nature"
	required_spell1 = "L1"
	required_spell2 = "N1"

## 重写融合施法逻辑
func _execute_fusion_cast(target: Node2D = null) -> void:
	var cast_position = Vector2.ZERO
	if target:
		cast_position = target.global_position
	elif owner_node:
		cast_position = owner_node.global_position
	
	_create_thunder_thorns(cast_position)

## 创建雷霆荆棘
func _create_thunder_thorns(position: Vector2) -> void:
	var enemies = _get_enemies_in_range(position, entangle_radius)
	
	for enemy in enemies:
		# 应用缠绕（减速）
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.SLOW,
				0.7,  # 减速70%
				entangle_duration
			)
		
		# 应用初始伤害
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, owner_node)
		
		# 持续放电效果
		_process_shock_damage(enemy)
	
	# 创建视觉效果
	_create_thorn_visuals(position, enemies.size())

## 持续放电伤害
func _process_shock_damage(enemy: Node2D) -> void:
	var elapsed = 0.0
	while elapsed < entangle_duration:
		await get_tree().create_timer(1.0).timeout
		elapsed += 1.0
		
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(shock_damage_per_second, owner_node)
			
			# 随机麻痹
			if enemy.has_method("apply_status_effect") and randf() < stun_chance:
				enemy.apply_status_effect(
					StatusEffectSystem.EffectType.STUN,
					1.0,
					0.5
				)
		else:
			break

## 创建荆棘视觉效果
func _create_thorn_visuals(position: Vector2, count: int) -> void:
	for i in range(min(count, thorn_count)):
		var thorn = Sprite2D.new()
		thorn.modulate = Color(0.4, 0.8, 0.2, 0.7)
		thorn.global_position = position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
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
			print("雷霆荆棘升级: 范围增加")
		10:
			stun_chance += 0.1
			print("雷霆荆棘升级: 麻痹概率增加")
		15:
			entangle_duration += 1.0
			print("雷霆荆棘升级: 缠绕时间增加")
