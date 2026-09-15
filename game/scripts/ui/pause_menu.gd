## PauseMenu - 暂停菜单
## ESC 呼出/关闭的游戏暂停菜单（CanvasLayer layer=20，置于商店等弹层之上；
## process_mode=ALWAYS：未暂停时可打开、暂停中可关闭）
class_name PauseMenu
extends CanvasLayer

## 组件引用
@onready var resume_button: Button = $Root/Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var save_button: Button = $Root/Panel/MarginContainer/VBoxContainer/SaveButton
@onready var settings_button: Button = $Root/Panel/MarginContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $Root/Panel/MarginContainer/VBoxContainer/QuitButton

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
	var settings = get_node_or_null("../../SettingsMenu")
	if settings and settings.has_method("show_settings"):
		# 暂停菜单让位，保持暂停状态由设置菜单接管（其关闭时会恢复游戏）
		visible = false
		settings.show_settings()
	else:
		EventBus.show_toast.emit("设置功能暂不可用", 1.0)

## 返回主菜单
func _on_quit_pressed() -> void:
	hide_menu()
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

## 处理输入（process_mode=ALWAYS，暂停/未暂停都能收到）
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return

	# 结算/游戏结束画面打开时：ESC 不做任何事（避免把暂停菜单叠在上面）
	for screen_path in ["../../GameOverScreen", "../../ResultScreen"]:
		var screen = get_node_or_null(screen_path)
		if screen and screen.visible:
			return

	# 升级三选一必须选择一项，ESC 不响应
	var player = get_tree().get_first_node_in_group("player")
	if player and player.get("is_choosing_upgrade"):
		return

	# 设置菜单打开时：ESC 关闭设置并回到暂停菜单
	var settings = get_node_or_null("../../SettingsMenu")
	if settings and settings.visible:
		if settings.has_method("close_settings"):
			settings.close_settings()
		show_menu()
		return

	# 商店营业中：ESC 等同「离开商店，开始下一波」
	var shop = get_tree().get_first_node_in_group("shop_ui")
	if shop and shop.visible:
		if shop.has_method("close_shop"):
			shop.close_shop()
		return

	# 常规：切换暂停菜单
	if visible:
		hide_menu()
	else:
		show_menu()
