## AudioManager - 音频管理器（单例）
## 管理背景音乐和音效
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

func _ready() -> void:
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
