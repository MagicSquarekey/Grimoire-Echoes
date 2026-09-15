## BaseSpell - 法术基类
## 所有法术的基类，定义法术的基本属性和行为
class_name BaseSpell
extends Node2D

# 法术属性
@export var spell_name = ""
@export var spell_element = ""
@export var spell_level = 1
@export var max_level = 20
@export var damage = 25.0
@export var cooldown = 1.0
@export var mana_cost = 10.0
@export var cast_range = 500.0
@export var aoe_radius = 0.0

# 法术类型枚举
enum SpellType {
	PROJECTILE,  # 投射物
	AOE,         # 范围
	BUFF,        # 增益
	SUMMON,      # 召唤
	CONTROL,     # 控制
	CHAIN,       # 连锁
	MARK,        # 标记
	DASH,        # 冲刺
	MELEE,       # 近战
	SHIELD,      # 护盾
	RING,        # 环绕
	FAN,         # 扇形
	WAVE,        # 波浪
	GROUND_AOE   # 地面范围
}
@export var spell_type = SpellType.PROJECTILE

# 状态
var current_cooldown = 0.0
var is_casting = false
var owner_node = null

# 信号
signal spell_cast()
signal spell_hit(target, damage)
signal spell_cooldown_started()
signal spell_cooldown_ended()

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# 更新冷却
	if current_cooldown > 0:
		current_cooldown -= delta
		if current_cooldown <= 0:
			current_cooldown = 0
			spell_cooldown_ended.emit()

## 施放法术
func cast(target = null) -> bool:
	# 检查冷却
	if current_cooldown > 0:
		return false

	# 场景切换保护：宿主场景缺失时跳过本次施放（不消耗资源、不进冷却）
	var tree := get_tree()
	if tree == null or tree.current_scene == null or not is_inside_tree():
		return false

	# 检查法力消耗
	var player_stats = _get_owner_stats()
	if player_stats and player_stats.current_mana < mana_cost:
		return false
	
	# 消耗法力
	if player_stats:
		player_stats.consume_mana(mana_cost)
	
	# 执行施放逻辑
	_on_cast(target)
	
	# 设置冷却
	current_cooldown = cooldown
	spell_cast.emit()
	spell_cooldown_started.emit()
	
	return true

## 法术施放逻辑（子类重写）
func _on_cast(target = null) -> void:
	match spell_type:
		SpellType.PROJECTILE:
			_cast_projectile(target)
		SpellType.AOE:
			_cast_aoe()
		SpellType.BUFF:
			_cast_buff()
		SpellType.SUMMON:
			_cast_summon()
		SpellType.CONTROL:
			_cast_control(target)
		_:
			_cast_projectile(target)

## 施放投射物
func _cast_projectile(target = null) -> void:
	var projectile = _create_projectile()
	if projectile:
		projectile.global_position = global_position
		if target:
			projectile.rotation = global_position.angle_to_point(target.global_position)
		get_tree().current_scene.add_child(projectile)

## 施放AoE
func _cast_aoe() -> void:
	var enemies = _get_enemies_in_range(global_position, aoe_radius)
	for enemy in enemies:
		_apply_damage(enemy)

## 施放增益
func _cast_buff() -> void:
	pass

## 施放召唤
func _cast_summon() -> void:
	pass

## 施放控制
func _cast_control(target = null) -> void:
	if target:
		_apply_control(target)

## 创建投射物（子类重写）
func _create_projectile():
	return null

## 获取范围内敌人（中心点 + 半径）
func _get_enemies_in_range(center: Vector2, radius: float) -> Array:
	var enemies = []
	var space_state = get_world_2d().direct_space_state
	
	var shape = CircleShape2D.new()
	shape.radius = radius
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, center)
	query.collision_mask = 2
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			enemies.append(collider)
	
	return enemies

## 应用伤害
func _apply_damage(target) -> void:
	if target.has_method("take_damage"):
		var final_damage = _calculate_damage()
		target.take_damage(final_damage, self)
		spell_hit.emit(target, final_damage)

## 应用控制效果
func _apply_control(target) -> void:
	pass

## 计算伤害
func _calculate_damage() -> float:
	var player_stats = _get_owner_stats()
	var base_damage = damage * _get_level_multiplier()

	if player_stats:
		base_damage *= player_stats.get_attack_multiplier()
		# 全局伤害加成（商店「伤害提升」等）真实生效
		base_damage *= (1.0 + player_stats.attack_damage_bonus)

	if player_stats and player_stats.element_affinity == spell_element:
		base_damage *= (1.0 + player_stats.element_damage_bonus)

	if player_stats and randf() < player_stats.get_crit_rate():
		base_damage *= player_stats.get_crit_damage()

	return base_damage

## 获取等级倍率
func _get_level_multiplier() -> float:
	var base_multiplier = 1.0 + (spell_level - 1) * 0.08
	
	if spell_level >= 5:
		base_multiplier += 0.15
	if spell_level >= 10:
		base_multiplier += 0.30
	if spell_level >= 15:
		base_multiplier += 0.50
	if spell_level >= 20:
		base_multiplier += 0.80
	
	return base_multiplier

## 获取所有者属性
func _get_owner_stats():
	if owner_node and owner_node.has_node("PlayerStats"):
		return owner_node.get_node("PlayerStats")
	return null

## 升级法术
func upgrade_spell() -> bool:
	if spell_level < max_level:
		spell_level += 1
		_on_upgrade()
		return true
	return false

## 法术升级逻辑（子类重写）
func _on_upgrade() -> void:
	damage *= 1.08

## 获取法术信息
func get_spell_info() -> Dictionary:
	return {
		"name": spell_name,
		"element": spell_element,
		"level": spell_level,
		"damage": damage * _get_level_multiplier(),
		"cooldown": cooldown,
		"mana_cost": mana_cost,
		"type": SpellType.keys()[spell_type]
	}
