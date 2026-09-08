## SpellManager - 法术管理器（单例）
extends Node

# 法术槽位
var spell_slots = []
var max_spell_slots = 4
var fusion_slot = null

# 法术冷却管理
var cooldowns = {}

func _ready() -> void:
	spell_slots.resize(max_spell_slots)
	spell_slots.fill(null)

## 添加法术到槽位
func add_spell(spell, slot = -1) -> bool:
	if slot == -1:
		# 找到第一个空槽位
		for i in max_spell_slots:
			if spell_slots[i] == null:
				slot = i
				break
	
	if slot >= 0 and slot < max_spell_slots:
		spell_slots[slot] = spell
		return true
	return false

## 移除法术
func remove_spell(slot: int) -> void:
	if slot >= 0 and slot < max_spell_slots:
		spell_slots[slot] = null

## 获取法术
func get_spell(slot: int) -> BaseSpell:
	if slot >= 0 and slot < max_spell_slots:
		return spell_slots[slot]
	return null

## 检查法术冷却
func is_spell_on_cooldown(spell: BaseSpell) -> bool:
	return cooldowns.get(spell.get_instance_id(), 0.0) > 0.0

## 获取法术冷却剩余时间
func get_spell_cooldown(spell: BaseSpell) -> float:
	return cooldowns.get(spell.get_instance_id(), 0.0)

## 设置法术冷却
func set_spell_cooldown(spell: BaseSpell, cooldown: float) -> void:
	cooldowns[spell.get_instance_id()] = cooldown

## 更新所有法术冷却
func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	var keys_to_remove = []
	for spell_id in cooldowns:
		cooldowns[spell_id] -= delta * GameManager.game_speed
		if cooldowns[spell_id] <= 0.0:
			cooldowns[spell_id] = 0.0
			keys_to_remove.append(spell_id)
	
	for key in keys_to_remove:
		cooldowns.erase(key)

## 自动施放所有法术
func auto_cast_spells() -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	for spell in spell_slots:
		if spell != null and not is_spell_on_cooldown(spell):
			spell.cast()
			set_spell_cooldown(spell, spell.cooldown)

## 获取所有法术
func get_all_spells() -> Array[BaseSpell]:
	return spell_slots.filter(func(s): return s != null)
