## MainMenu - 主菜单
## 游戏主菜单界面
class_name MainMenu
extends Control

## 组件引用
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

## 初始化
func _ready() -> void:
	# 连接按钮信号
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 检查是否有存档
	continue_button.disabled = not SaveManager.has_any_save()

## 开始新游戏
func _on_start_pressed() -> void:
	# 切换到角色选择界面
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")

## 继续游戏
func _on_continue_pressed() -> void:
	var saves = SaveManager.get_all_saves()
	# 这里可以显示存档选择界面
	# 目前默认加载第一个存档
	for i in range(saves.size()):
		if not saves[i].is_empty():
			GameManager.continue_game(i)
			get_tree().change_scene_to_file("res://scenes/main/game.tscn")
			return

## 打开设置
func _on_settings_pressed() -> void:
	var settings = get_node_or_null("/root/SettingsMenu")
	if settings == null:
		# 创建简单的设置提示
		var dialog = AcceptDialog.new()
		dialog.title = "设置"
		dialog.dialog_text = "音频设置请在游戏中按ESC打开暂停菜单调整"
		add_child(dialog)
		dialog.popup_centered()
		dialog.confirmed.connect(dialog.queue_free)

## 退出游戏
func _on_quit_pressed() -> void:
	get_tree().quit()
