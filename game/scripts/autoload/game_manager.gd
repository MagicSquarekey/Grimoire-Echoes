## GameManager - 游戏管理器（单例）
## 管理游戏状态和核心逻辑
extends Node

# 游戏状态枚举
enum GameState {
	MAIN_MENU,
	CHARACTER_SELECT,
	MAP_SELECT,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY,
	SETTINGS,
	CREDITS
}

# 当前游戏状态
var current_state = GameState.MAIN_MENU
var previous_state = GameState.MAIN_MENU

# 游戏数据
var current_character = ""
var current_map = ""
var current_wave = 0
var play_time = 0.0
var kill_count = 0
var total_gold = 0

# 游戏模式："normal" 标准波次 / "boss_rush" Boss 连战（由主菜单设定，跨场景保留）
var game_mode: String = "normal"

# 游戏速度
var game_speed = 1.0
var speed_multiplier = 1.0
var speed_levels = [1.0, 2.0, 3.0]
var current_speed_index = 0

# 存档槽位
var current_save_slot = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## 失焦自动暂停：对局中切出窗口立即冻结并弹出暂停菜单（单机防挂机死亡）
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_auto_pause_on_focus_loss()

func _auto_pause_on_focus_loss() -> void:
	if current_state != GameState.PLAYING:
		return
	var tree := get_tree()
	if tree == null or tree.paused:
		return
	tree.paused = true
	var pm = tree.current_scene.get_node_or_null("UI/PauseMenu") if tree.current_scene else null
	if pm and pm.has_method("show_menu"):
		pm.show_menu()
	EventBus.show_toast.emit("窗口失焦，已自动暂停", 2.0)

## 顿帧：短暂冻结时间流动（升级/Boss 击杀等高光时刻的打击感）
func hitstop(duration: float = 0.06, freeze_scale: float = 0.05) -> void:
	if Engine.time_scale < 1.0:
		return  # 已在顿帧中，不叠加
	Engine.time_scale = freeze_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		play_time += delta * game_speed

## 改变游戏状态
func change_state(new_state) -> void:
	if current_state == new_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	match new_state:
		GameState.PLAYING:
			_on_playing_enter()
		GameState.PAUSED:
			_on_paused_enter()
		GameState.GAME_OVER:
			_on_game_over_enter()
	
	EventBus.game_state_changed.emit(previous_state, new_state)

## 开始新游戏
func start_new_game(character: String, map_name: String) -> void:
	current_character = character
	current_map = map_name
	current_wave = 0
	play_time = 0.0
	kill_count = 0
	total_gold = 0
	current_speed_index = 0
	game_speed = 1.0
	speed_multiplier = 1.0
	
	# 重置波次管理器
	WaveManager.reset()
	
	change_state(GameState.PLAYING)

## 继续游戏
func continue_game(slot: int) -> void:
	current_save_slot = slot
	var save_data = SaveManager.load_game(slot)
	if save_data:
		current_character = save_data.get("character", "")
		current_map = save_data.get("map", "")
		current_wave = save_data.get("wave", 0)
		play_time = save_data.get("play_time", 0.0)
		kill_count = save_data.get("kill_count", 0)
		total_gold = save_data.get("gold", 0)
		
		# 重置波次管理器并恢复波次
		# （存档 wave 可能为 0（开局早期自动存档），下限钳到 1，避免出现 Wave 0/-1
		#  导致 build_wave_plan 负索引取到末尾波次配置）
		WaveManager.reset()
		WaveManager.current_wave = maxi(1, current_wave) - 1  # start_wave会+1
		
		change_state(GameState.PLAYING)
		EventBus.game_loaded.emit(slot)

## 暂停游戏
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)

## 继续游戏（从暂停状态）
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)

## 切换游戏速度
func toggle_game_speed() -> void:
	current_speed_index = (current_speed_index + 1) % speed_levels.size()
	game_speed = speed_levels[current_speed_index]
	speed_multiplier = game_speed

## 返回主菜单
func return_to_main_menu() -> void:
	change_state(GameState.MAIN_MENU)

## 游戏结束
func game_over() -> void:
	change_state(GameState.GAME_OVER)
	EventBus.game_over.emit(get_game_stats())

## 胜利
func victory() -> void:
	change_state(GameState.VICTORY)

## 获取游戏统计
func get_game_stats() -> Dictionary:
	return {
		"wave": current_wave,
		"kills": kill_count,
		"gold": total_gold,
		"time": play_time
	}

## 获取格式化的游戏时间
func get_formatted_play_time() -> String:
	var hours = int(play_time) / 3600
	var minutes = (int(play_time) % 3600) / 60
	var seconds = int(play_time) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

## 添加击杀数
func add_kill(count = 1) -> void:
	kill_count += count

## 添加金币
func add_gold(amount = 1) -> void:
	total_gold += amount

# 状态进入回调
func _on_playing_enter() -> void:
	get_tree().paused = false

func _on_paused_enter() -> void:
	get_tree().paused = true

func _on_game_over_enter() -> void:
	get_tree().paused = false
