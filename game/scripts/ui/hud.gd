## HUD - 游戏内界面
## 显示玩家状态、波次信息、法术槽位等
class_name HUD
extends CanvasLayer

## 组件引用
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var mana_bar: ProgressBar = $MarginContainer/VBoxContainer/ManaBar
@onready var exp_bar: ProgressBar = $MarginContainer/VBoxContainer/ExpBar
@onready var wave_label: Label = $MarginContainer/VBoxContainer/StatsContainer/WaveLabel
@onready var kill_label: Label = $MarginContainer/VBoxContainer/StatsContainer/KillLabel
@onready var gold_label: Label = $MarginContainer/VBoxContainer/StatsContainer/GoldLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/StatsContainer/TimeLabel
@onready var combo_label: Label = $MarginContainer/VBoxContainer/ComboLabel

## 法术槽位UI
@onready var spell_slots: HBoxContainer = $MarginContainer/VBoxContainer/SpellSlots

## 武器槽UI（左下 4 槽：图标 + 等级角标）
@onready var weapon_slots: HBoxContainer = $WeaponSlots

var _weapon_slots_bound := false

## 初始化
func _ready() -> void:
	# 连接信号（安全检查）
	if EventBus.has_signal("player_damaged"):
		EventBus.player_damaged.connect(_on_player_damaged)
	if EventBus.has_signal("player_healed"):
		EventBus.player_healed.connect(_on_player_healed)
	if EventBus.has_signal("wave_started"):
		EventBus.wave_started.connect(_on_wave_started)
	if EventBus.has_signal("exp_changed"):
		EventBus.exp_changed.connect(_on_exp_changed)
	if EventBus.has_signal("gold_changed"):
		EventBus.gold_changed.connect(_on_gold_changed)
	if EventBus.has_signal("enemy_killed"):
		EventBus.enemy_killed.connect(_on_enemy_killed)
	# 武器槽：延迟绑定玩家的 SpellCaster（等 battle 场景就绪）
	_bind_weapon_slots.call_deferred()
	if EventBus.has_signal("upgrade_selected"):
		EventBus.upgrade_selected.connect(_on_upgrade_selected_refresh_slots)

func _process(_delta: float) -> void:
	# 更新时间显示
	var time = GameManager.play_time
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

## 更新血量显示
func update_health(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current

## 更新法力显示
func update_mana(current: float, max_value: float) -> void:
	mana_bar.max_value = max_value
	mana_bar.value = current

## 更新经验显示
func _on_exp_changed(current: int, required: int) -> void:
	exp_bar.max_value = required
	exp_bar.value = current

## 更新波次显示
func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "⚔️ Wave %d" % wave_number
	_animate_wave_text()

## 更新击杀显示
func _on_enemy_killed(enemy_name: String, exp_reward: int, gold_reward: int) -> void:
	kill_label.text = "💀 %d" % GameManager.kill_count

## 更新金币显示
func _on_gold_changed(amount: int) -> void:
	gold_label.text = "💰 %d" % amount

## 玩家受伤回调
func _on_player_damaged(amount: float, attacker: Node2D) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_stats"):
		var stats = player.get_stats()
		if stats:
			update_health(stats.current_health, stats.max_health)
			_shake_bar(health_bar)

## 玩家治疗回调
func _on_player_healed(amount: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_stats"):
		var stats = player.get_stats()
		if stats:
			update_health(stats.current_health, stats.max_health)

## 更新连击显示
func update_combo(count: int, multiplier: float) -> void:
	if count >= 5:
		combo_label.text = "Combo x%d (%.0f%%)" % [count, (multiplier - 1.0) * 100]
		combo_label.visible = true
	else:
		combo_label.visible = false

## 波次文字动画
func _animate_wave_text() -> void:
	if wave_label == null:
		return
	
	wave_label.modulate = Color.YELLOW
	var tween = create_tween()
	tween.tween_property(wave_label, "modulate", Color.WHITE, 0.5)

## 血条抖动效果
func _shake_bar(bar: ProgressBar) -> void:
	if bar == null:
		return

	var tween = create_tween()
	tween.tween_property(bar, "modulate", Color.RED, 0.05)
	tween.tween_property(bar, "modulate", Color.WHITE, 0.1)

## ---------- 武器槽（左下 4 槽） ----------

## 绑定玩家 SpellCaster（重试几次，兼容场景加载时序）
func _bind_weapon_slots(retries: int = 6) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		if retries > 0:
			_bind_weapon_slots.call_deferred(retries - 1)
		return
	var sc = player.get_node_or_null("SpellCaster")
	if sc == null:
		if retries > 0:
			_bind_weapon_slots.call_deferred(retries - 1)
		return
	if not sc.spell_changed.is_connected(_on_spell_slots_changed):
		sc.spell_changed.connect(_on_spell_slots_changed)
	_refresh_weapon_slots()

## 装备变化 → 刷新
func _on_spell_slots_changed(_slot_index: int, _old_spell, _new_spell) -> void:
	_refresh_weapon_slots.call_deferred()

## 升级选择后 → 刷新（等级角标/新法术兜底刷新）
func _on_upgrade_selected_refresh_slots(_upgrade_type: String, _data: Dictionary) -> void:
	_refresh_weapon_slots.call_deferred()

## 刷新武器槽图标与等级角标
func _refresh_weapon_slots() -> void:
	if weapon_slots == null:
		return
	var player = get_tree().get_first_node_in_group("player")
	var sc = player.get_node_or_null("SpellCaster") if player else null
	for i in range(4):
		var slot_ui = weapon_slots.get_node_or_null("Slot%d" % i)
		if slot_ui == null:
			continue
		var icon: TextureRect = slot_ui.get_node_or_null("Icon")
		var level_label: Label = slot_ui.get_node_or_null("Level")
		if icon == null or level_label == null:
			continue
		var spell = sc.spell_slots[i] if (sc and i < sc.spell_slots.size()) else null
		if spell:
			var sid := str(spell.get_meta("spell_id", ""))
			icon.texture = SpellIcons.icon_for(sid, spell)
			icon.visible = true
			slot_ui.modulate = Color.WHITE
			level_label.text = "Lv.%d" % spell.spell_level
		else:
			icon.texture = null
			icon.visible = false
			slot_ui.modulate = Color(1, 1, 1, 0.35)  # 空槽半透明
			level_label.text = ""
