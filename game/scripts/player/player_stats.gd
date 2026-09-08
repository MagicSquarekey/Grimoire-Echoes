## PlayerStats - 玩家属性管理
## 管理玩家的所有属性和状态
class_name PlayerStats
extends Node2D

# 基础属性
@export var max_health = 100.0
@export var max_mana = 100.0
@export var base_attack = 1.0
@export var base_defense = 1.0
@export var move_speed = 200.0
@export var crit_rate = 0.05
@export var crit_damage = 1.5

# 当前状态
var current_health = 100.0
var current_mana = 100.0
var current_level = 1
var current_exp = 0.0
var gold = 0

# 加成属性
var health_bonus = 0.0
var mana_bonus = 0.0
var attack_bonus = 0.0
var attack_damage_bonus = 0.0
var defense_bonus = 0.0
var speed_bonus = 0.0
var move_speed_bonus = 0.0
var crit_rate_bonus = 0.0
var crit_damage_bonus = 0.0
var life_steal = 0.0
var cooldown_reduction = 0.0

# 元素亲和
var element_affinity = ""
var element_damage_bonus = 0.0

# 拾取磁石加成
var magnet_bonus = 0.0

# 信号
signal health_changed(old_value, new_value)
signal mana_changed(old_value, new_value)
signal level_up(new_level)
signal died()
signal exp_changed(new_exp)

func _ready() -> void:
	current_health = max_health
	current_mana = max_mana

func get_max_health() -> float:
	return max_health * (1.0 + health_bonus)

func get_max_mana() -> float:
	return max_mana * (1.0 + mana_bonus)

func get_attack_multiplier() -> float:
	return base_attack * (1.0 + attack_bonus)

func get_defense_multiplier() -> float:
	return base_defense * (1.0 + defense_bonus)

func get_move_speed() -> float:
	return move_speed * (1.0 + speed_bonus)

func get_crit_rate() -> float:
	return min(crit_rate + crit_rate_bonus, 1.0)

func get_crit_damage() -> float:
	return crit_damage + crit_damage_bonus

func take_damage(amount: float) -> void:
	# 防御减伤：base_defense=1.0表示无减伤，加成部分转为减伤比例(上限80%)
	var reduction = clampf(get_defense_multiplier() - 1.0, 0.0, 0.8)
	var actual_damage = amount * (1.0 - reduction)
	var old_health = current_health
	current_health = max(0, current_health - actual_damage)
	health_changed.emit(old_health, current_health)
	
	if current_health <= 0:
		died.emit()

func heal(amount: float) -> void:
	var old_health = current_health
	current_health = min(get_max_health(), current_health + amount)
	health_changed.emit(old_health, current_health)

func consume_mana(amount: float) -> bool:
	if current_mana >= amount:
		var old_mana = current_mana
		current_mana -= amount
		mana_changed.emit(old_mana, current_mana)
		return true
	return false

func restore_mana(amount: float) -> void:
	var old_mana = current_mana
	current_mana = min(get_max_mana(), current_mana + amount)
	mana_changed.emit(old_mana, current_mana)

func add_exp(amount: float) -> void:
	current_exp += amount
	exp_changed.emit(current_exp)
	_check_level_up()

func _check_level_up() -> void:
	var required_exp = _get_required_exp(current_level)
	while current_exp >= required_exp:
		current_exp -= required_exp
		current_level += 1
		level_up.emit(current_level)
		required_exp = _get_required_exp(current_level)

func _get_required_exp(level: int) -> float:
	return 50.0 * level * (1.0 + level * 0.12)

func get_required_exp() -> float:
	return _get_required_exp(current_level)

func add_gold(amount = 1) -> void:
	gold += amount

func get_stats_dict() -> Dictionary:
	return {
		"max_health": max_health,
		"max_mana": max_mana,
		"base_attack": base_attack,
		"base_defense": base_defense,
		"move_speed": move_speed,
		"crit_rate": crit_rate,
		"crit_damage": crit_damage,
		"current_health": current_health,
		"current_mana": current_mana,
		"current_level": current_level,
		"current_exp": current_exp,
		"gold": gold,
		"element_affinity": element_affinity
	}

func load_stats_dict(data: Dictionary) -> void:
	max_health = data.get("max_health", 100.0)
	max_mana = data.get("max_mana", 100.0)
	base_attack = data.get("base_attack", 1.0)
	base_defense = data.get("base_defense", 1.0)
	move_speed = data.get("move_speed", 200.0)
	crit_rate = data.get("crit_rate", 0.05)
	crit_damage = data.get("crit_damage", 1.5)
	current_health = data.get("current_health", max_health)
	current_mana = data.get("current_mana", max_mana)
	current_level = data.get("current_level", 1)
	current_exp = data.get("current_exp", 0.0)
	gold = data.get("gold", 0)
	element_affinity = data.get("element_affinity", "")
