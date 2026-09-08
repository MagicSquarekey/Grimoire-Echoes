## GameController - 游戏控制器
extends Node

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
	
	call_deferred("_start_game")

## 开始游戏
func _start_game() -> void:
	is_game_active = true
	current_wave = 0
	total_kills = 0
	total_gold = 0
	
	_update_hud()
	
	if enemy_spawner:
		enemy_spawner.start_next_wave()

## 波次开始
func _on_wave_started(wave_number) -> void:
	current_wave = wave_number
	_update_hud()

## 波次完成
func _on_wave_completed(wave_number) -> void:
	SaveManager.auto_save()
	if wave_number % 10 == 0:
		_trigger_milestone_reward()

## 敌人被击杀
func _on_enemy_killed(enemy_name, exp_reward, gold_reward) -> void:
	total_kills += 1
	total_gold += gold_reward
	GameManager.add_gold(gold_reward)
	_update_hud()

## 游戏结束
func _on_game_over(stats: Dictionary) -> void:
	is_game_active = false
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
		"gold": total_gold,
		"time": GameManager.play_time
	}
