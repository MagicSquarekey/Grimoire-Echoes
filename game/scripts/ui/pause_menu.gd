## PauseMenu - 暂停菜单
## 游戏暂停时显示的菜单
class_name PauseMenu
extends Control

## 组件引用
@onready var resume_button: Button = $Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var save_button: Button = $Panel/MarginContainer/VBoxContainer/SaveButton
@onready var settings_button: Button = $Panel/MarginContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $Panel/MarginContainer/VBoxContainer/QuitButton

## 初始化
func _ready() -> void:
	# 连接按钮信号
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 初始隐藏
	visible = false

## 显示暂停菜单
func show_menu() -> void:
	# 如果正在选择升级，不允许打开暂停菜单
	var player = get_tree().get_first_node_in_group("player")
	if player and player.get("is_choosing_upgrade"):
		return
	visible = true
	get_tree().paused = true

## 隐藏暂停菜单
func hide_menu() -> void:
	visible = false
	# 只有在不选择升级时才真正取消暂停
	var player = get_tree().get_first_node_in_group("player")
	if player and player.get("is_choosing_upgrade"):
		return
	get_tree().paused = false

## 继续游戏
func _on_resume_pressed() -> void:
	hide_menu()

## 保存游戏
func _on_save_pressed() -> void:
	SaveManager.auto_save()
	EventBus.show_toast.emit("游戏已保存", 1.0)

## 打开设置
func _on_settings_pressed() -> void:
	# 这里可以打开设置界面
	pass

## 返回主菜单
func _on_quit_pressed() -> void:
	hide_menu()
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

## 处理输入
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			hide_menu()
		else:
			show_menu()
