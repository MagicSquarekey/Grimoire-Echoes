## CombatManager - 战斗管理器
extends Node

## 信号
signal damage_dealt(attacker, target, damage, is_critical)
signal target_killed(target, killer)

## 连击系统
var combo_count = 0
var combo_timer = 0.0
var combo_timeout = 2.0
var combo_multiplier = 1.0

## 伤害数字场景
var damage_number_scene = preload("res://scenes/ui/damage_number.tscn")

## 初始化
func _ready() -> void:
    EventBus.enemy_killed.connect(_on_enemy_killed)

## 处理战斗帧
func _process(delta: float) -> void:
    if combo_count > 0:
        combo_timer -= delta * GameManager.game_speed
        if combo_timer <= 0:
            _reset_combo()

## 造成伤害
func deal_damage(attacker, target, base_damage, attack_multiplier = 1.0, element_bonus = 0.0, crit_rate = 0.0, crit_damage = 1.5, damage_type = DamageCalculator.PHYSICAL):
    if not is_instance_valid(target) or not target.has_method("take_damage"):
        return null
    
    var result = DamageCalculator.calculate(base_damage, attack_multiplier, element_bonus, crit_rate, crit_damage, 0.0, damage_type)
    
    result.final_damage *= combo_multiplier
    target.take_damage(result.final_damage, attacker)
    _show_damage_number(target.global_position + Vector2(0, -30), result.final_damage, result.is_critical)
    _increment_combo()
    damage_dealt.emit(attacker, target, result.final_damage, result.is_critical)
    
    return result

## 显示伤害数字
func _show_damage_number(position: Vector2, damage: float, is_critical: bool) -> void:
    var number = damage_number_scene.instantiate()
    if number:
        number.setup(damage, is_critical)
        get_tree().current_scene.add_child(number)
        # add_child之后再定位，否则赋值丢失
        number.global_position = position

## 增加连击
func _increment_combo() -> void:
    combo_count += 1
    combo_timer = combo_timeout
    
    # 更新连击倍率（每10连击+10%伤害）
    combo_multiplier = 1.0 + (combo_count / 10) * 0.1

## 重置连击
func _reset_combo() -> void:
    combo_count = 0
    combo_multiplier = 1.0

## 敌人被击杀回调
func _on_enemy_killed(enemy_name: String, exp_reward: int, gold_reward: int) -> void:
    # 连击奖励
    if combo_count >= 10:
        EventBus.show_toast.emit("连击 x%d! 伤害+%.0f%%" % [combo_count, (combo_multiplier - 1.0) * 100], 1.0)

## 获取当前连击数
func get_combo_count() -> int:
    return combo_count

## 获取连击倍率
func get_combo_multiplier() -> float:
    return combo_multiplier

## 获取战斗统计
func get_combat_stats() -> Dictionary:
    return {
        "combo": combo_count,
        "combo_multiplier": combo_multiplier,
        "combo_timer": combo_timer
    }
