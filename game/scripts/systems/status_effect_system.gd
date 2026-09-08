## StatusEffectSystem - 状态效果系统
## 管理和应用各种状态效果（燃烧、减速、冻结等）
class_name StatusEffectSystem
extends Node

## 状态效果类型枚举
enum EffectType {
	BURN,        # 燃烧
	SLOW,        # 减速
	FREEZE,      # 冻结
	STUN,        # 麻痹
	BLIND,       # 致盲
	CURSE,       # 诅咒
	REGEN,       # 再生
	SHIELD       # 护盾
}

## 状态效果数据
class StatusEffect:
	var type
	var value
	var duration
	var remaining_time
	var tick_interval = 1.0
	var tick_timer = 0.0
	
	func _init(_type, _value, _duration) -> void:
		type = _type
		value = _value
		duration = _duration
		remaining_time = _duration

## 当前激活的效果
var active_effects = []

## 应用状态效果
func apply_effect(type, value: float, duration: float) -> void:
	for effect in active_effects:
		if effect.type == type:
			effect.duration = maxf(effect.duration, duration)
			effect.remaining_time = effect.duration
			effect.value = maxf(effect.value, value)
			return
	
	var new_effect = StatusEffect.new(type, value, duration)
	active_effects.append(new_effect)

## 移除状态效果
func remove_effect(type) -> void:
	for i in range(active_effects.size() - 1, -1, -1):
		if active_effects[i].type == type:
			active_effects.remove_at(i)

## 检查是否有特定效果
func has_effect(type) -> bool:
	for effect in active_effects:
		if effect.type == type:
			return true
	return false

## 获取效果数值
func get_effect_value(type) -> float:
	for effect in active_effects:
		if effect.type == type:
			return effect.value
	return 0.0

## 更新所有效果
func update_effects(delta: float) -> void:
	var dt = delta * GameManager.game_speed
	
	for i in range(active_effects.size() - 1, -1, -1):
		var effect = active_effects[i]
		effect.remaining_time -= dt
		effect.tick_timer += dt
		
		if effect.tick_timer >= effect.tick_interval:
			effect.tick_timer -= effect.tick_interval
			_process_effect(effect)
		
		if effect.remaining_time <= 0:
			active_effects.remove_at(i)

## 处理单个效果
func _process_effect(effect) -> void:
	var owner_node = get_parent()
	if owner_node == null:
		return
	
	match effect.type:
		EffectType.BURN:
			if owner_node.has_method("take_damage"):
				owner_node.take_damage(effect.value)
		
		EffectType.REGEN:
			if owner_node.has_method("heal"):
				owner_node.heal(effect.value)

## 获取移动速度乘数
func get_speed_multiplier() -> float:
	if has_effect(EffectType.FREEZE):
		return 0.0
	if has_effect(EffectType.STUN):
		return 0.0
	if has_effect(EffectType.SLOW):
		return 1.0 - get_effect_value(EffectType.SLOW)
	return 1.0

## 获取攻击命中率修正
func get_accuracy_modifier() -> float:
	if has_effect(EffectType.BLIND):
		return 0.5
	return 1.0

## 获取受伤加成
func get_damage_taken_modifier() -> float:
	if has_effect(EffectType.CURSE):
		return 1.0 + get_effect_value(EffectType.CURSE)
	return 1.0

## 清除所有效果
func clear_all() -> void:
	active_effects.clear()

## 获取所有效果信息（用于UI显示）
func get_effects_info() -> Array:
	var info = []
	for effect in active_effects:
		info.append({
			"type": EffectType.keys()[effect.type],
			"value": effect.value,
			"remaining": effect.remaining_time,
			"duration": effect.duration
		})
	return info
