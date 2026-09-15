## AudioManager - 音频管理器（单例）
## 管理背景音乐和音效；SFX 走「命名注册表 + EventBus 自动接线」，
## 并带同类节流（命中/死亡等高频音效防刷屏）
extends Node

# 背景音乐播放器
var music_player: AudioStreamPlayer
var music_player_2: AudioStreamPlayer  # 用于交叉淡入淡出

# 音效播放器池
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS: int = 16

# 音量设置
var music_volume: float = 1.0
var sfx_volume: float = 1.0

# ---- 命名音效注册表 ----
const SFX_DIR := "res://assets/audio/sfx/"
const SFX_KEYS := [
	"shoot_arcane", "shoot_fire", "shoot_water", "shoot_lightning", "shoot_ice", "shoot_shadow",
	"hit", "enemy_die", "player_hurt",
	"pickup_gem", "pickup_coin", "pickup_potion", "pickup_magnet",
	"level_up", "upgrade_select", "shop_buy", "ui_click",
	"wave_start", "boss_spawn", "chest_open", "altar_deal", "bounty_ping",
]
var _streams := {}
var _last_play_ms := {}

# 高频音效节流窗口（毫秒）
const THROTTLE := {"hit": 50, "enemy_die": 60, "shoot_arcane": 40, "shoot_fire": 40,
	"shoot_water": 40, "shoot_lightning": 40, "shoot_ice": 40, "shoot_shadow": 40,
	"pickup_gem": 45, "pickup_coin": 45}

# 元素 → 射击音效
const ELEMENT_SHOOT := {
	"fire": "shoot_fire", "water": "shoot_water", "lightning": "shoot_lightning",
	"ice": "shoot_ice", "shadow": "shoot_shadow", "arcane": "shoot_arcane",
	"nature": "shoot_water", "air": "shoot_arcane",
}

func _ready() -> void:
	_ensure_buses()
	# 创建背景音乐播放器
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	music_player_2 = AudioStreamPlayer.new()
	music_player_2.bus = "Music"
	add_child(music_player_2)

	# 创建音效播放器池
	for i in MAX_SFX_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	_load_streams()
	_connect_events()

## 确保 Music / SFX 总线存在（项目未带 default_bus_layout.tres）
func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

func _load_streams() -> void:
	for key in SFX_KEYS:
		var path: String = SFX_DIR + str(key) + ".wav"
		if ResourceLoader.exists(path):
			_streams[key] = load(path)
		else:
			push_warning("AudioManager 缺少音效: " + path)

func _connect_events() -> void:
	EventBus.spell_cast.connect(_on_spell_cast)
	EventBus.spell_hit.connect(_on_spell_hit)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.pickup_collected.connect(_on_pickup_collected)
	EventBus.exp_gem_collected.connect(_on_exp_gem)
	EventBus.gold_collected.connect(_on_gold)
	EventBus.player_level_up.connect(_on_level_up)
	EventBus.upgrade_selected.connect(_on_upgrade_selected)
	EventBus.shop_item_bought.connect(_on_shop_bought)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.boss_spawned.connect(_on_boss_spawned)

# ---- 信号回调 ----

func _on_spell_cast(_spell_data: Resource, caster: Node2D) -> void:
	var element := ""
	if caster and caster.is_in_group("player"):
		element = str(_spell_data.get("spell_element")) if _spell_data and "spell_element" in _spell_data else ""
		if element == "" and _spell_data:
			element = str(_spell_data.get("element")) if "element" in _spell_data else ""
	play_named(ELEMENT_SHOOT.get(element, "shoot_arcane"), 0.4, randf_range(0.94, 1.06))

func _on_spell_hit(_target: Node2D, _damage: float) -> void:
	play_named("hit", 0.3, randf_range(0.9, 1.15))

func _on_enemy_killed(_enemy_type: String, _exp_reward: int, _gold_reward: int) -> void:
	play_named("enemy_die", 0.45, randf_range(0.88, 1.12))

func _on_player_damaged(_amount: float, _attacker: Node2D) -> void:
	play_named("player_hurt", 0.8)

func _on_pickup_collected(pickup_type: String, _value) -> void:
	match pickup_type:
		"health_potion":
			play_named("pickup_potion", 0.6)
		"magnet":
			play_named("pickup_magnet", 0.6)
		_:
			play_named("pickup_gem", 0.35)

func _on_exp_gem(_amount: int) -> void:
	play_named("pickup_gem", 0.4, randf_range(0.95, 1.1))

func _on_gold(_amount: int) -> void:
	play_named("pickup_coin", 0.45, randf_range(0.95, 1.1))

func _on_level_up(_level: int) -> void:
	play_named("level_up", 0.8)

func _on_upgrade_selected(_type: String, _data: Dictionary) -> void:
	play_named("upgrade_select", 0.6)

func _on_shop_bought(_item_type: String, _data: Dictionary) -> void:
	play_named("shop_buy", 0.7)

func _on_wave_started(wave_number: int) -> void:
	play_named("wave_start", 0.4)

func _on_boss_spawned(_boss_name: String) -> void:
	play_named("boss_spawn", 0.9)

# ---- 命名播放 API（供事件脚本等直接调用） ----

## 按注册名播放音效；同名校音节流防刷屏
func play_named(key: String, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> void:
	if not _streams.has(key):
		return
	var now := Time.get_ticks_msec()
	var window: int = THROTTLE.get(key, 0)
	if window > 0 and now - int(_last_play_ms.get(key, -10000)) < window:
		return
	_last_play_ms[key] = now
	play_sfx(_streams[key], volume_scale, pitch_scale)

## 播放背景音乐
func play_music(music: AudioStream, fade_time: float = 1.0) -> void:
	if music_player.playing:
		# 交叉淡入淡出
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(music_player, "volume_db", -80.0, fade_time / 2)
		tween.tween_callback(func(): music_player.stream = music; music_player.play()).set_delay(fade_time / 2)
		tween.tween_property(music_player, "volume_db", 0.0, fade_time / 2).set_delay(fade_time / 2)
	else:
		music_player.stream = music
		music_player.play()

## 停止背景音乐
func stop_music(fade_time: float = 1.0) -> void:
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(music_player.stop)

## 播放音效
func play_sfx(sfx: AudioStream, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> void:
	for player in sfx_players:
		if not player.playing:
			player.stream = sfx
			player.volume_db = linear_to_db(volume_scale * sfx_volume)
			player.pitch_scale = pitch_scale
			player.play()
			return

	# 如果所有播放器都在使用，使用第一个
	sfx_players[0].stream = sfx
	sfx_players[0].volume_db = linear_to_db(volume_scale * sfx_volume)
	sfx_players[0].pitch_scale = pitch_scale
	sfx_players[0].play()

## 设置主音量
func set_master_volume(volume: float) -> void:
	var master_vol = clampf(volume, 0.0, 1.0)
	# 设置主总线音量
	AudioServer.set_bus_volume_db(0, linear_to_db(master_vol))

## 设置音乐音量
func set_music_volume(volume: float) -> void:
	music_volume = clampf(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume)

## 设置音效音量
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)

## 暂停所有音频
func pause_all() -> void:
	music_player.stream_paused = true
	for player in sfx_players:
		player.stream_paused = true

## 恢复所有音频
func resume_all() -> void:
	music_player.stream_paused = false
	for player in sfx_players:
		player.stream_paused = false
