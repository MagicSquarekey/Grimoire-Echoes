## ResultScreen - 结算画面
## 游戏结束后显示统计信息和奖励
extends CanvasLayer

# UI引用
@onready var wave_label: Label = $MarginContainer/VBoxContainer/WaveLabel
@onready var kills_label: Label = $MarginContainer/VBoxContainer/KillsLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var gold_label: Label = $MarginContainer/VBoxContainer/GoldLabel
@onready var exp_label: Label = $MarginContainer/VBoxContainer/ExpLabel
@onready var retry_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/RetryButton
@onready var menu_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/MenuButton

# 结算数据
var result_data: Dictionary = {}

func _ready() -> void:
	# 连接按钮信号
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# 隐藏自身
	hide()

## 显示结算画面
func show_result(data: Dictionary) -> void:
	result_data = data
	
	# 更新UI显示
	wave_label.text = "到达波次: %d" % data.get("wave", 0)
	kills_label.text = "击杀敌人: %d" % data.get("kills", 0)
	time_label.text = "游戏时间: %s" % _format_time(data.get("time", 0.0))
	gold_label.text = "获得金币: %d" % data.get("gold", 0)
	exp_label.text = "获得经验: %d" % data.get("exp", 0)
	
	# 显示结算画面
	show()
	get_tree().paused = true

## 格式化时间
func _format_time(seconds: float) -> String:
	var hours = int(seconds) / 3600
	var minutes = (int(seconds) % 3600) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]

## 重试按钮
func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

## 返回主菜单按钮
func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
