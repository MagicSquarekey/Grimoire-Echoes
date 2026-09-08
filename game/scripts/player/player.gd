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
var breathe_timer = 0.0
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
	
	# 装备初始法术 + 查找升级面板（延迟一帧确保场景树就绪）
	call_deferred("_setup_battle_kit")
	
	_init_player()

func _setup_battle_kit() -> void:
	# 自动装备初始法术
	if spell_caster and spell_caster.get_spell_count() == 0:
		var bolt = MAGIC_BOLT_SCRIPT.new()
		spell_caster.equip_spell(bolt, 0)
	
	# 查找升级面板并允许它在暂停时响应
	upgrade_panel = get_node_or_null("../UI/UpgradePanel")
	if upgrade_panel:
		upgrade_panel.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if invincible_timer > 0:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
			if body:
				body.modulate.a = 1.0
	
	_update_breathe_animation(delta)
	
	# 处理待升级队列（每次只弹一个面板，选完后再弹下一个）
	if pending_upgrades > 0 and not is_choosing_upgrade:
		pending_upgrades -= 1
		_show_upgrade_panel()
	
	# 自动施放法术（SpellCaster 内部有 PLAYING 状态检查）
	if not is_choosing_upgrade:
		auto_cast_spells()

func _update_breathe_animation(delta: float) -> void:
	breathe_timer += delta * 2.0
	var scale_factor = 1.0 + sin(breathe_timer) * 0.03
	scale = Vector2(scale_factor, scale_factor)

func _init_player() -> void:
	global_position = Vector2(960, 540)
	
	# 根据选择的角色设置元素加成
	_apply_character_bonus(GameManager.current_character)

## 应用角色元素加成
func _apply_character_bonus(character_id: String) -> void:
	if not stats:
		return
	match character_id:
		"fire_mage":
			stats.element_affinity = "fire"
			stats.element_damage_bonus = 0.2
		"water_mage":
			stats.element_affinity = "water"
			stats.element_damage_bonus = 0.2
		"lightning_mage":
			stats.element_affinity = "lightning"
			stats.element_damage_bonus = 0.2

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

## 生成强化选项池（抽3个）
func _generate_options(count: int) -> Array:
	var pool = [
		{"id": "damage", "name": "秘能强化", "desc": "所有法术伤害 +20%", "level": 1},
		{"id": "haste", "name": "急速咏唱", "desc": "法术冷却时间 -15%", "level": 1},
		{"id": "multishot", "name": "分裂飞弹", "desc": "奥术飞弹数量 +1", "level": 1},
		{"id": "speed", "name": "疾行之靴", "desc": "移动速度 +12%", "level": 1},
		{"id": "health", "name": "生命祝福", "desc": "生命上限 +25，并回复 50% 生命", "level": 1},
		{"id": "magnet", "name": "经验磁石", "desc": "拾取范围 +50", "level": 1},
	]
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))

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
		_:
			pass
	
	EventBus.upgrade_selected.emit(option.get("id", ""), option)

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
