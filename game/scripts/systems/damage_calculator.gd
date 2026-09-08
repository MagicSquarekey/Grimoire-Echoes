## DamageCalculator - 伤害计算器
class_name DamageCalculator
extends RefCounted

## 伤害类型常量
const PHYSICAL = 0
const ELEMENTAL = 1
const TRUE_DAMAGE = 2
const DOT = 3

## 计算最终伤害
static func calculate(base_damage, attack_multiplier = 1.0, element_bonus = 0.0, crit_rate = 0.0, crit_damage = 1.5, defense = 0.0, damage_type = PHYSICAL) -> Dictionary:
    var damage = base_damage * attack_multiplier
    damage *= (1.0 + element_bonus)
    
    var is_critical = randf() < crit_rate
    if is_critical:
        damage *= crit_damage
    
    if damage_type == PHYSICAL and defense > 0:
        damage = damage * (100.0 / (100.0 + defense))
    
    if damage_type == TRUE_DAMAGE:
        damage = base_damage
    
    return {
        "final_damage": maxf(damage, 0.0),
        "is_critical": is_critical,
        "damage_type": damage_type
    }

## 计算法术伤害
static func calculate_spell_damage(base_damage, spell_level, attack_multiplier = 1.0, element_bonus = 0.0, crit_rate = 0.0, crit_damage = 1.5) -> Dictionary:
    var level_multiplier = _get_level_multiplier(spell_level)
    var scaled_damage = base_damage * level_multiplier
    return calculate(scaled_damage, attack_multiplier, element_bonus, crit_rate, crit_damage, 0.0, ELEMENTAL)

## 获取等级倍率
static func _get_level_multiplier(level: int) -> float:
    var multiplier = 1.0 + (level - 1) * 0.08
    if level >= 5: multiplier += 0.15
    if level >= 10: multiplier += 0.30
    if level >= 15: multiplier += 0.50
    if level >= 20: multiplier += 0.80
    return multiplier

## 计算DoT伤害
static func calculate_dot(base_damage, duration, tick_interval = 1.0) -> float:
    return base_damage * (duration / tick_interval)

## 计算范围伤害衰减
static func calculate_aoe_falloff(base_damage, distance, max_radius, falloff_start = 0.5) -> float:
    if distance <= max_radius * falloff_start:
        return base_damage
    var falloff_factor = 1.0 - ((distance - max_radius * falloff_start) / (max_radius * (1.0 - falloff_start)))
    return base_damage * maxf(falloff_factor, 0.3)

## 计算连锁伤害递减
static func calculate_chain_damage(base_damage, chain_count, decay_per_hit = 0.2) -> Array:
    var damages = []
    var current_damage = base_damage
    for i in range(chain_count + 1):
        damages.append(current_damage)
        current_damage *= (1.0 - decay_per_hit)
    return damages

## 计算吸血量
static func calculate_life_steal(damage_dealt, life_steal_percent) -> float:
    return damage_dealt * life_steal_percent

## 格式化伤害显示
static func format_damage(damage, is_critical) -> String:
    var text = str(int(damage))
    if is_critical:
        text += "!"
    return text
