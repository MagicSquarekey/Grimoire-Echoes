## GameOverScreen - 游戏结束画面
## 玩家死亡时显示
extends CanvasLayer

# UI引用
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var stats_label: Label = $MarginContainer/VBoxContainer/StatsPanel/StatsMargin/StatsLabel
@onready var respawn_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/RespawnButton
@onready var menu_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/MenuButton

func _ready() -> void:
	respawn_button.pressed.connect(_on_respawn_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	hide()

## 显示游戏结束画面
func show_game_over(stats: Dictionary) -> void:
	title_label.text = "游戏结束"

	var weapons: Array = stats.get("weapons", [])
	var weapons_text := "、".join(weapons) if not weapons.is_empty() else "无"
	var stats_text = "波次: %d\n击杀: %d\n金币: %d\n等级: %d\n时间: %s\n最终武器: %s" % [
		stats.get("wave", 0),
		stats.get("kills", 0),
		stats.get("gold", 0),
		stats.get("level", 1),
		_format_time(stats.get("time", 0.0)),
		weapons_text
	]
	stats_label.text = stats_text

	show()
	get_tree().paused = true

## 格式化时间
func _format_time(seconds: float) -> String:
	var hours = int(seconds) / 3600
	var minutes = (int(seconds) % 3600) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]

## 重生按钮
func _on_respawn_pressed() -> void:
	get_tree().paused = false
	# 重置所有状态并重新开始
	GameManager.start_new_game(GameManager.current_character, GameManager.current_map)
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")

## 返回主菜单按钮
func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
