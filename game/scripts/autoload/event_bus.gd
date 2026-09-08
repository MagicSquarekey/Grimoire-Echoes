## EventBus - 全局事件总线
## 用于模块间解耦通信
extends Node

# 游戏状态信号
signal game_state_changed(old_state: int, new_state: int)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal boss_spawned(boss_name: String)

# 玩家信号
signal player_health_changed(old_value: float, new_value: float)
signal player_mana_changed(old_value: float, new_value: float)
signal player_level_up(new_level: int)
signal player_died()
signal player_respawned()
signal player_damaged(amount: float, attacker: Node2D)
signal player_healed(amount: float)

# 法术信号
signal spell_cast(spell_data: Resource, caster: Node2D)
signal spell_hit(target: Node2D, damage: float)
signal spell_upgraded(spell_name: String, new_level: int)
signal fusion_triggered(fusion_name: String)

# 敌人信号
signal enemy_spawned(enemy_type: String)
signal enemy_killed(enemy_type: String, exp_reward: int, gold_reward: int)
signal boss_defeated(boss_name: String)

# UI信号
signal upgrade_selected(upgrade_type: String, upgrade_data: Dictionary)
signal shop_item_bought(item_type: String, item_data: Dictionary)
signal save_requested()
signal load_requested(slot: int)
signal exp_changed(current: int, required: int)
signal gold_changed(amount: int)

# 存档信号
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal auto_saved()

# 伤害信号
signal damage_dealt(attacker: Node2D, target: Node2D, damage: float, is_critical: bool)
signal damage_number_spawned(position: Vector2, damage: float, is_critical: bool, element: String)

# 拾取信号
signal pickup_collected(pickup_type: String, value: int)
signal exp_gem_collected(amount: int)
signal gold_collected(amount: int)
signal relic_collected(relic_name: String)

# 游戏流程信号
signal game_started()
signal game_over(stats: Dictionary)
signal show_toast(message: String, duration: float)
signal spell_fusion_unlocked(fusion_id: String)
signal shop_closed()
