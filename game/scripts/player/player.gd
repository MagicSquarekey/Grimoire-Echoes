## Player - 玩家主控制器
extends CharacterBody2D

const MAGIC_BOLT_SCRIPT = preload("res://scripts/spells/magic_bolt.gd")

# 组件引用
@onready var stats = $PlayerStats
@onready var controller = $PlayerController
@onready var spell_caster = $SpellCaster
@onready var body = $Body
@onready var glow = $Glow
@onready var collision_shape = $CollisionShape2D

# 状态
var is_invincible = false
var invincible_timer = 0.0
var invincible_duration = 0.5
var upgrade_panel = null
var is_choosing_upgrade = false
var pending_upgrades: int = 0  # 待处理的升级队列

# 信号
signal player_hit(attacker, damage)
signal player_dodged()

func _ready() -> void:
	add_to_group("player")
	
	stats.died.connect(_on_player_died)
	stats.level_up.connect(_on_level_up)
	stats.exp_changed.connect(_on_exp_changed)
	controller.dodge_started.connect(_on_dodge_started)
	controller.dodge_ended.connect(_on_dodge_ended)
	# 生命偷取（商店等来源）：玩家法术命中时按比例回血
	EventBus.spell_hit.connect(_on_spell_hit_life_steal)
	
	# 装备初始法术 + 查找升级面板（延迟一帧确保场景树就绪）
	call_deferred("_setup_battle_kit")
	
	_init_player()

## 生命偷取：仅玩家法术的 EventBus.spell_hit 会到达这里（敌方弹体不发射该信号）
func _on_spell_hit_life_steal(_target, damage: float) -> void:
	if stats.life_steal > 0.0 and damage > 0.0:
		stats.heal(damage * stats.life_steal)

func _setup_battle_kit() -> void:
	# 自动装备初始法术：槽0 奥术飞弹（固定）+ 槽1 角色签名法术
	if spell_caster and spell_caster.get_spell_count() == 0:
		_equip_spell_by_id("magic_bolt", 0)
		var signature: String = SpellRegistry.CHARACTER_STARTER.get(GameManager.current_character, "")
		if signature != "":
			_equip_spell_by_id(signature, 1)

	# 查找升级面板并允许它在暂停时响应
	upgrade_panel = get_node_or_null("../UI/UpgradePanel")
	if upgrade_panel:
		upgrade_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		if not upgrade_panel.reroll_requested.is_connected(_on_reroll_requested):
			upgrade_panel.reroll_requested.connect(_on_reroll_requested)

## 重投：花费金币刷新升级三选一（价格随次数翻倍，由面板展示）
func _on_reroll_requested() -> void:
	if not is_choosing_upgrade or upgrade_panel == null:
		return
	var cost: int = upgrade_panel.get_reroll_cost()
	if GameManager.total_gold < cost:
		EventBus.show_toast.emit("金币不足，无法重投（需要 %d）" % cost, 1.2)
		return
	GameManager.total_gold -= cost
	EventBus.gold_changed.emit(GameManager.total_gold)
	upgrade_panel.apply_reroll(_generate_options(3))

## 按 id 实例化并装备法术（记录 spell_id 元数据供强化/HUD 识别）
func _equip_spell_by_id(spell_id: String, slot: int) -> void:
	if spell_caster == null:
		return
	var info: Dictionary = SpellRegistry.SPELLS.get(spell_id, {})
	if info.is_empty():
		return
	var spell = load(info["script"]).new()
	if spell == null:
		return
	spell.set_meta("spell_id", spell_id)
	spell_caster.equip_spell(spell, slot)

func _process(delta: float) -> void:
	if invincible_timer > 0:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
			if body:
				body.modulate.a = 1.0
	
	# 站立呼吸已由 Body(sprite_body.gd) 在精灵层处理（避免缩放整个 CharacterBody2D 影响物理）
	
	# 处理待升级队列（每次只弹一个面板，选完后再弹下一个）
	if pending_upgrades > 0 and not is_choosing_upgrade:
		pending_upgrades -= 1
		_show_upgrade_panel()
	
	# 自动施放法术（SpellCaster 内部有 PLAYING 状态检查）
	if not is_choosing_upgrade:
		auto_cast_spells()

func _init_player() -> void:
	global_position = Vector2(960, 540)
	
	# 根据选择的角色设置元素加成
	_apply_character_bonus(GameManager.current_character)

## 应用角色元素加成
func _apply_character_bonus(character_id: String) -> void:
	if not stats:
		return
	# 脚下元素光环配色（AuraGlow 在 player.tscn，随角色变色）
	var aura_col := Color(0.55, 0.85, 1, 0.4)
	match character_id:
		"fire_mage":
			stats.element_affinity = "fire"
			stats.element_damage_bonus = 0.2
			aura_col = Color(1.0, 0.55, 0.2, 0.4)
		"water_mage":
			stats.element_affinity = "water"
			stats.element_damage_bonus = 0.2
			aura_col = Color(0.4, 0.75, 1, 0.4)
		"lightning_mage":
			stats.element_affinity = "lightning"
			stats.element_damage_bonus = 0.2
			aura_col = Color(0.75, 0.62, 1, 0.4)
	var aura := get_node_or_null("AuraGlow")
	if aura:
		aura.modulate = aura_col

func take_damage(damage: float, attacker = null) -> void:
	if is_invincible:
		return
	
	stats.take_damage(damage)
	player_hit.emit(attacker, damage)
	EventBus.player_damaged.emit(damage, attacker)
	
	_start_invincible()

func _start_invincible() -> void:
	is_invincible = true
	invincible_timer = invincible_duration
	if body:
		body.modulate.a = 0.5

func _on_dodge_started() -> void:
	player_dodged.emit()
	is_invincible = true
	if glow:
		glow.color = Color(0.4, 0.7, 1, 0.4)

func _on_dodge_ended() -> void:
	is_invincible = false
	if glow:
		glow.color = Color(0.4, 0.7, 1, 0.15)

func _on_player_died() -> void:
	controller.set_process(false)
	controller.set_physics_process(false)
	GameManager.game_over()

## 经验变化 → 转发给 HUD
func _on_exp_changed(_new_exp) -> void:
	EventBus.exp_changed.emit(stats.current_exp, stats.get_required_exp())

## 升级 → 加入队列，逐个弹出面板
func _on_level_up(level) -> void:
	EventBus.player_level_up.emit(level)
	EventBus.show_toast.emit("升级！Lv.%d" % level, 1.5)
	pending_upgrades += 1

func _show_upgrade_panel() -> void:
	var options = _generate_options(3)
	
	if upgrade_panel == null or options.is_empty():
		# 面板缺失时自动应用第一个可用强化
		if not options.is_empty():
			_apply_upgrade(options[0])
		return
	
	is_choosing_upgrade = true
	get_tree().paused = true
	
	upgrade_panel.show_upgrade_options(options)
	
	var chosen = await upgrade_panel.option_selected
	_apply_upgrade(options[chosen])
	
	get_tree().paused = false
	is_choosing_upgrade = false

## 选项唯一键（去重用）
func _opt_key(opt: Dictionary) -> String:
	return "%s|%s|%s" % [opt.get("id", ""), opt.get("spell_id", ""), opt.get("boost", "")]

## 生成强化选项池（抽3个，不重复）
## 构成：数值升级（6）+ 法术强化（对已装备法术实例，最多2条）+ 获得新法术（有空槽时，权重更高）
func _generate_options(count: int) -> Array:
	var candidates: Array = []

	# 1) 数值升级（保留原行为：multishot 只对奥术飞弹生效）
	candidates.append_array([
		{"id": "damage", "name": "秘能强化", "desc": "所有法术伤害 +20%", "level": 1},
		{"id": "haste", "name": "急速咏唱", "desc": "法术冷却时间 -15%", "level": 1},
		{"id": "multishot", "name": "分裂飞弹", "desc": "奥术飞弹数量 +1", "level": 1},
		{"id": "speed", "name": "疾行之靴", "desc": "移动速度 +12%", "level": 1},
		{"id": "health", "name": "生命祝福", "desc": "生命上限 +25，并回复 50% 生命", "level": 1},
		{"id": "magnet", "name": "经验磁石", "desc": "拾取范围 +50", "level": 1},
	])

	# 2) 法术强化：随机挑已装备法术给 伤害+25% / 冷却-20%（记到法术实例上，非全局）
	var equipped: Array = []
	for spell in spell_caster.spell_slots:
		if spell:
			equipped.append(spell)
	var boosts := ["damage", "cooldown"]
	for i in range(2):
		if equipped.is_empty():
			break
		var spell = equipped[randi() % equipped.size()]
		var boost: String = boosts[randi() % boosts.size()]
		var sid := str(spell.get_meta("spell_id", spell.spell_name))
		var desc := "伤害 +25%" if boost == "damage" else "冷却时间 -20%"
		candidates.append({
			"id": "spell_power", "spell_id": sid, "boost": boost,
			"name": "法术强化·%s" % spell.spell_name,
			"desc": "%s %s" % [spell.spell_name, desc], "level": 1,
		})

	# 3) 获得新法术：仅当有空槽时；剔除已有；重复入池一次 → 优先级略高
	if spell_caster and spell_caster.get_spell_count() < spell_caster.MAX_SPELL_SLOTS:
		var owned := {}
		for spell in spell_caster.spell_slots:
			if spell:
				owned[str(spell.get_meta("spell_id", ""))] = true
		var pool: Array = []
		for sid in SpellRegistry.UNLOCKABLE:
			if not owned.has(sid):
				pool.append(sid)
		if not pool.is_empty():
			var pick: String = pool[randi() % pool.size()]
			var info: Dictionary = SpellRegistry.SPELLS.get(pick, {})
			if not info.is_empty():
				var opt := {
					"id": "new_spell", "spell_id": pick,
					"name": "获得法术·%s" % info["name"],
					"desc": str(info["attack"]), "level": 1,
				}
				candidates.append(opt)
				candidates.append(opt.duplicate(true))

	# 加权不放回抽取（重复候选 = 更高权重）
	var picked: Array = []
	while picked.size() < count and not candidates.is_empty():
		var opt: Dictionary = candidates[randi() % candidates.size()]
		picked.append(opt)
		var key := _opt_key(opt)
		candidates = candidates.filter(func(o): return _opt_key(o) != key)
	return picked

## 应用强化
func _apply_upgrade(option) -> void:
	match option.get("id", ""):
		"damage":
			for spell in spell_caster.spell_slots:
				if spell:
					spell.damage *= 1.2
		"haste":
			for spell in spell_caster.spell_slots:
				if spell:
					spell.cooldown = max(0.15, spell.cooldown * 0.85)
		"multishot":
			for spell in spell_caster.spell_slots:
				if spell and "projectile_count" in spell:
					spell.projectile_count += 1
		"speed":
			stats.move_speed_bonus += 0.12
		"health":
			stats.max_health += 25.0
			stats.heal(stats.get_max_health() * 0.5)
		"magnet":
			stats.magnet_bonus += 50.0
		"spell_power":
			# 对指定法术实例强化（不是全局 damage）
			var sid := str(option.get("spell_id", ""))
			for spell in spell_caster.spell_slots:
				if spell and str(spell.get_meta("spell_id", "")) == sid:
					if option.get("boost", "damage") == "cooldown":
						spell.cooldown = max(0.15, spell.cooldown * 0.8)
					else:
						spell.damage *= 1.25
					break
		"new_spell":
			_equip_new_spell(option.get("spell_id", ""))
		_:
			pass

	EventBus.upgrade_selected.emit(option.get("id", ""), option)

## 获得新法术：装入第一个空槽；无空槽时兜底为全体法术伤害 +25%
func _equip_new_spell(spell_id: String) -> void:
	var free_slot := -1
	for i in range(spell_caster.spell_slots.size()):
		if spell_caster.spell_slots[i] == null:
			free_slot = i
			break
	if free_slot == -1:
		for spell in spell_caster.spell_slots:
			if spell:
				spell.damage *= 1.25
		return
	_equip_spell_by_id(spell_id, free_slot)

func heal(amount: float) -> void:
	stats.heal(amount)

func get_stats():
	return stats

func get_stat(stat_name: String) -> float:
	match stat_name:
		"max_health": return stats.get_max_health()
		"max_mana": return stats.get_max_mana()
		"attack": return stats.get_attack_multiplier()
		"defense": return stats.get_defense_multiplier()
		"speed": return stats.get_move_speed()
		"crit_rate": return stats.get_crit_rate()
		"crit_damage": return stats.get_crit_damage()
		_: return 0.0

func auto_cast_spells() -> void:
	if spell_caster:
		spell_caster.auto_cast()

func get_save_data() -> Dictionary:
	return stats.get_stats_dict()

func load_save_data(data: Dictionary) -> void:
	stats.load_stats_dict(data)
