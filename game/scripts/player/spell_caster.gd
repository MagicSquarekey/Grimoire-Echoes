## SpellCaster - 法术施放器
extends Node2D

## 法术槽位数量
const MAX_SPELL_SLOTS = 4

## 当前装备的法术
var spell_slots = []
var ultimate_spell = null

## 法术冷却
var cooldowns = []

## 信号
signal spell_cast(spell, slot_index)
signal spell_changed(slot_index, old_spell, new_spell)

func _ready() -> void:
	for i in range(MAX_SPELL_SLOTS):
		spell_slots.append(null)
		cooldowns.append(0.0)

func _process(delta: float) -> void:
	for i in range(cooldowns.size()):
		if cooldowns[i] > 0:
			cooldowns[i] -= delta * GameManager.speed_multiplier
			if cooldowns[i] <= 0:
				cooldowns[i] = 0

func equip_spell(spell, slot_index = -1) -> bool:
	if spell == null:
		return false
	if slot_index == -1:
		for i in range(MAX_SPELL_SLOTS):
			if spell_slots[i] == null:
				slot_index = i
				break
	
	# 检查槽位有效性
	if slot_index < 0 or slot_index >= MAX_SPELL_SLOTS:
		return false
	
	# 替换现有法术
	var old_spell = spell_slots[slot_index]
	spell_slots[slot_index] = spell
	
	# 添加到节点树
	add_child(spell)
	
	# 发送信号
	spell_changed.emit(slot_index, old_spell, spell)
	
	# 移除旧法术
	if old_spell and old_spell != spell:
		old_spell.queue_free()
	
	return true

## 卸下法术
func unequip_spell(slot_index: int) -> BaseSpell:
	if slot_index < 0 or slot_index >= MAX_SPELL_SLOTS:
		return null
	
	var spell = spell_slots[slot_index]
	if spell:
		spell_slots[slot_index] = null
		remove_child(spell)
	
	return spell

## 施放法术
func cast_spell(slot_index: int, target_pos: Vector2 = Vector2.ZERO) -> bool:
	if slot_index < 0 or slot_index >= MAX_SPELL_SLOTS:
		return false
	
	var spell = spell_slots[slot_index]
	if spell == null:
		return false
	
	# 检查冷却
	if cooldowns[slot_index] > 0:
		return false
	
	# 设置所有者
	spell.owner_node = get_parent()
	
	# 施放法术
	var success = spell.cast(target_pos)
	if success:
		# 冷却缩减（商店「冷却减少」等）真实生效（上限 60% 防零冷却）
		var cd_scale := 1.0
		var stats = get_parent().get_node_or_null("PlayerStats") if get_parent() else null
		if stats:
			cd_scale = 1.0 - clampf(stats.cooldown_reduction, 0.0, 0.6)
		cooldowns[slot_index] = spell.cooldown * cd_scale
		spell_cast.emit(spell, slot_index)
	
	return success

## 自动施放（选择最近敌人）
func auto_cast() -> void:
	# 找到最近敌人
	var player = get_parent()
	if player == null:
		return
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy = null
	var nearest_distance = INF
	
	for enemy in enemies:
		if enemy.has_method("take_damage") and enemy.get("is_alive"):
			var distance = player.global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = enemy
	
	# 施放法术
	for i in range(MAX_SPELL_SLOTS):
		if spell_slots[i] and cooldowns[i] <= 0:
			if nearest_enemy:
				cast_spell(i, nearest_enemy.global_position)
			else:
				cast_spell(i, player.global_position + Vector2(100, 0))
			break

## 获取法术槽位信息
func get_spell_info(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SPELL_SLOTS:
		return {}
	
	var spell = spell_slots[slot_index]
	if spell:
		return spell.get_spell_info()
	return {}

## 获取所有法术信息
func get_all_spells_info() -> Array[Dictionary]:
	var info: Array[Dictionary] = []
	for i in range(MAX_SPELL_SLOTS):
		info.append(get_spell_info(i))
	return info

## 获取冷却信息
func get_cooldown_info() -> Array[float]:
	return cooldowns.duplicate()

## 升级法术
func upgrade_spell(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SPELL_SLOTS:
		return false
	
	var spell = spell_slots[slot_index]
	if spell:
		return spell.upgrade_spell()
	return false

## 获取法术数量
func get_spell_count() -> int:
	var count = 0
	for spell in spell_slots:
		if spell:
			count += 1
	return count

## 清空所有法术
func clear_all_spells() -> void:
	for i in range(MAX_SPELL_SLOTS):
		if spell_slots[i]:
			spell_slots[i].queue_free()
			spell_slots[i] = null
			cooldowns[i] = 0.0
