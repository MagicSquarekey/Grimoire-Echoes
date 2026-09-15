## GameController - 游戏控制器
extends Node

## 事件波实体场景
const TREASURE_CHEST_SCENE = preload("res://scenes/events/treasure_chest.tscn")
const CURSED_ALTAR_SCENE = preload("res://scenes/events/cursed_altar.tscn")

## 相机震动脚本（经 preload 引用静态入口，不依赖全局类缓存）
const GameCameraScript = preload("res://scripts/player/game_camera.gd")

## 事件波提示文案
const EVENT_TOASTS := {
	"treasure": "🎁 稀有宝箱出现了！触碰开启",
	"altar": "⚗ 诅咒祭坛出现了！以血换力",
	"bounty": "🎯 悬赏令：本波藏着一只巨额赏金精英！",
}

## 系统引用
@onready var combat_manager = $CombatManager
@onready var experience_system = $ExperienceSystem
@onready var status_effect_system = $StatusEffectSystem
@onready var fusion_system = $FusionSystem
@onready var enemy_spawner = $EnemySpawner

## UI引用
var hud = null
var upgrade_panel = null
var pause_menu = null
var game_over_screen = null

## 游戏状态
var is_game_active = false
var current_wave = 0
var total_kills = 0
var total_gold = 0

## 当前事件波实体（宝箱/祭坛，换波时回收）
var _event_node: Node = null

## 初始化
func _ready() -> void:
	await get_tree().process_frame
	hud = get_node_or_null("../UI/HUD")
	upgrade_panel = get_node_or_null("../UI/UpgradePanel")
	pause_menu = get_node_or_null("../UI/PauseMenu")
	game_over_screen = get_node_or_null("../UI/GameOverScreen")
	
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.game_over.connect(_on_game_over)

	# 打击感接线：受击/Boss 震屏，升级/Boss 击杀顿帧
	EventBus.player_damaged.connect(_on_shake_small)
	EventBus.boss_spawned.connect(_on_boss_shake)
	EventBus.boss_defeated.connect(_on_boss_defeated_feel)
	EventBus.player_level_up.connect(_on_level_up_feel)

	call_deferred("_start_game")

## 打击感：玩家受击轻震
func _on_shake_small(_amount: float, _attacker: Node2D) -> void:
	GameCameraScript.shake_global(5.0, 0.22)

## 打击感：Boss 登场重震
func _on_boss_shake(_boss_name: String) -> void:
	GameCameraScript.shake_global(10.0, 0.55)

## 打击感：Boss 击杀顿帧 + 震屏
func _on_boss_defeated_feel(_boss_name: String) -> void:
	GameCameraScript.shake_global(8.0, 0.4)
	GameManager.hitstop(0.12, 0.05)

## 打击感：升级瞬间微顿帧（配合升级面板弹出）
func _on_level_up_feel(_level: int) -> void:
	GameManager.hitstop(0.05, 0.05)

## 开始游戏
func _start_game() -> void:
	is_game_active = true
	current_wave = 0
	total_kills = 0
	total_gold = 0

	# 同步游戏模式给刷怪器（Boss 连战：波次计划只出 Boss）
	EnemySpawner.boss_rush_mode = GameManager.game_mode == "boss_rush"

	# 起始资金：让「杀敌→掉落→购物」循环从第一波间隙就能转起来
	GameManager.add_gold(30)
	EventBus.gold_changed.emit(GameManager.total_gold)

	_update_hud()

	if enemy_spawner:
		enemy_spawner.start_next_wave()

## 波次开始
func _on_wave_started(wave_number) -> void:
	current_wave = wave_number
	_update_hud()
	_handle_wave_event()


## 事件波处理：按 WaveManager 计划中的 event 标记放置实体/播报
func _handle_wave_event() -> void:
	# 回收上一波的事件实体（未被拾取的宝箱/祭坛不跨波保留）
	if _event_node and is_instance_valid(_event_node):
		_event_node.queue_free()
	_event_node = null

	var event_id: String = WaveManager.current_plan.get("event", "")
	if event_id == "":
		return

	# 悬赏波只播报（标记由 EnemySpawner.begin_wave 完成）
	if event_id == "bounty":
		EventBus.show_toast.emit(EVENT_TOASTS[event_id], 2.5)
		AudioManager.play_named("bounty_ping", 0.7)
		return

	var scene: PackedScene = TREASURE_CHEST_SCENE if event_id == "treasure" else CURSED_ALTAR_SCENE
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	_event_node = scene.instantiate()
	add_child(_event_node)
	var dir := Vector2.RIGHT.rotated(randf() * TAU)
	_event_node.global_position = player.global_position + dir * 260.0
	EventBus.show_toast.emit(EVENT_TOASTS.get(event_id, ""), 2.5)

## 波次完成
func _on_wave_completed(wave_number) -> void:
	SaveManager.auto_save()
	if wave_number % 10 == 0:
		_trigger_milestone_reward()

## 敌人被击杀（金币由拾取金币时入账，避免"击杀+拾取"双重计数）
func _on_enemy_killed(enemy_name, exp_reward, gold_reward) -> void:
	total_kills += 1
	_update_hud()

## 游戏结束（补全结算数据：等级 + 最终武器列表，供结算画面展示）
func _on_game_over(stats: Dictionary) -> void:
	is_game_active = false
	# GameManager.current_wave 不随波次更新，用控制器维护的当前波次纠正
	stats["wave"] = maxi(int(stats.get("wave", 0)), current_wave)
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and player.get("spell_caster"):
		stats["level"] = player.stats.current_level
		var weapons: Array = []
		for spell in player.spell_caster.spell_slots:
			if spell:
				weapons.append(spell.spell_name)
		stats["weapons"] = weapons
	if game_over_screen:
		game_over_screen.show_game_over(stats)

## 触发里程碑奖励
func _trigger_milestone_reward() -> void:
	EventBus.show_toast.emit("里程碑达成！波次 %d" % current_wave, 2.0)

## 更新HUD
func _update_hud() -> void:
	if hud == null:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_stats"):
		var player_stats = player.get_stats()
		if player_stats:
			hud.update_health(player_stats.current_health, player_stats.max_health)
			hud.update_mana(player_stats.current_mana, player_stats.max_mana)

## 获取游戏统计
func get_game_stats() -> Dictionary:
	return {
		"wave": current_wave,
		"kills": total_kills,
		"gold": GameManager.total_gold,
		"time": GameManager.play_time
	}
