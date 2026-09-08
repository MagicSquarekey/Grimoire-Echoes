## SaveManager - 存档管理器（单例）
extends Node

# 存档槽位数量
const MAX_SAVE_SLOTS = 3

# 存档目录
const SAVE_DIR = "user://saves/"

# 备份目录
const BACKUP_DIR = "user://saves/backups/"

# 高分榜文件
const HIGH_SCORE_FILE = "user://high_scores.json"

# 存档文件后缀
const SAVE_EXTENSION = ".save"

# 存档版本
const SAVE_VERSION: String = "1.0"

func _ready() -> void:
	# 确保存档目录存在
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(BACKUP_DIR)

## 保存游戏
func save_game(slot: int, data: Dictionary) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	
	# 添加元数据
	data["version"] = "1.0"
	data["timestamp"] = Time.get_datetime_string_from_system()
	data["slot"] = slot
	
	# 序列化为JSON
	var json_string = JSON.stringify(data)
	
	# 加密（简化版本，实际应使用AES-128）
	var encrypted_data = _encrypt_data(json_string)
	
	# 写入文件
	var file_path = _get_save_path(slot)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("无法创建存档文件: " + file_path)
		return false
	
	file.store_string(encrypted_data)
	file.close()
	
	EventBus.game_saved.emit(slot)
	print("游戏已保存到槽位: ", slot)
	return true

## 加载游戏
func load_game(slot: int) -> Dictionary:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return {}
	
	var file_path = _get_save_path(slot)
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	
	var encrypted_data = file.get_as_text()
	file.close()
	
	# 解密
	var json_string = _decrypt_data(encrypted_data)
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("存档文件损坏")
		return {}
	
	var data = json.data
	if not data is Dictionary:
		return {}
	
	return data

## 检查存档是否存在
func has_save(slot: int) -> bool:
	var file_path = _get_save_path(slot)
	return FileAccess.file_exists(file_path)

## 删除存档
func delete_save(slot: int) -> bool:
	var file_path = _get_save_path(slot)
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		return true
	return false

## 获取所有存档信息
func get_all_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	for i in MAX_SAVE_SLOTS:
		if has_save(i):
			var data = load_game(i)
			saves.append(data)
		else:
			saves.append({})
	return saves

## 自动保存
func auto_save() -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		var data = _create_save_data()
		save_game(0, data)  # 槽位0用于自动存档
		EventBus.auto_saved.emit()

## 创建存档数据
func _create_save_data() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	var player_data = {}
	if player and player.has_method("get_save_data"):
		player_data = player.get_save_data()
	
	return {
		"version": SAVE_VERSION,
		"character": GameManager.current_character,
		"map": GameManager.current_map,
		"wave": GameManager.current_wave,
		"play_time": GameManager.play_time,
		"kill_count": GameManager.kill_count,
		"gold": GameManager.total_gold,
		"player": player_data,
		"checksum": ""
	}

## 检查是否有任何存档
func has_any_save() -> bool:
	for i in range(MAX_SAVE_SLOTS):
		if has_save(i):
			return true
	return false

## 获取存档预览信息
func get_save_preview(slot: int) -> Dictionary:
	var data = load_game(slot)
	if data.is_empty():
		return {"empty": true}
	
	return {
		"empty": false,
		"character": data.get("character", "Unknown"),
		"map": data.get("map", "Unknown"),
		"wave": data.get("wave", 0),
		"play_time": data.get("play_time", 0),
		"timestamp": data.get("timestamp", "")
	}

## 保存高分
func save_high_score(score_data: Dictionary) -> void:
	var scores = _load_high_scores()
	scores.append(score_data)
	
	# 按波次排序，保留前10名
	scores.sort_custom(func(a, b): return a.get("wave", 0) > b.get("wave", 0))
	scores = scores.slice(0, 10)
	
	var json_string = JSON.stringify(scores)
	var file = FileAccess.open(HIGH_SCORE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

## 加载高分榜
func _load_high_scores() -> Array:
	if not FileAccess.file_exists(HIGH_SCORE_FILE):
		return []
	
	var file = FileAccess.open(HIGH_SCORE_FILE, FileAccess.READ)
	if file == null:
		return []
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return []
	
	return json.data if json.data is Array else []

## 获取高分榜
func get_high_scores() -> Array:
	return _load_high_scores()

## 创建备份
func create_backup(slot: int) -> bool:
	var source_path = _get_save_path(slot)
	if not FileAccess.file_exists(source_path):
		return false
	
	var backup_path = BACKUP_DIR + "save_%d_backup_%s" % [slot, Time.get_datetime_string_from_system().replace(":", "-")]
	var source = FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return false
	
	var data = source.get_as_text()
	source.close()
	
	var backup = FileAccess.open(backup_path, FileAccess.WRITE)
	if backup == null:
		return false
	
	backup.store_string(data)
	backup.close()
	return true

## 计算校验和
func _calculate_checksum(data: Dictionary) -> String:
	var temp = data.duplicate()
	temp.erase("checksum")
	var json_string = JSON.stringify(temp)
	return str(hash(json_string))

## 获取存档路径
func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_%d" % slot + SAVE_EXTENSION

## 简单加密（实际项目应使用AES-128）
func _encrypt_data(data: String) -> String:
	# 简单的Base64编码（仅作示例）
	return Marshalls.utf8_to_base64(data)

## 简单解密
func _decrypt_data(data: String) -> String:
	return Marshalls.base64_to_utf8(data)
