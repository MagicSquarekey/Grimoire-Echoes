## ui_survey.gd - UI 全界面巡检截图工具
## 用法：Godot --path game res://tools/ui_survey.tscn
## 截图输出：C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/ui_*.png
extends Node

const SHOT_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots"

var t := 0.0
var stage := 0


func _ready() -> void:
	if get_tree().current_scene == self:
		# 包装模式：把驱动副本挂到树根（场景切换不会释放），再进入主菜单
		var driver := Node.new()
		driver.set_script(get_script())
		driver.name = "UISurveyDriver"
		get_tree().root.add_child.call_deferred(driver)
		get_tree().change_scene_to_file.call_deferred("res://scenes/main/main_menu.tscn")
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)


func _shot(tag: String) -> void:
	# 直接取最后一帧已渲染画面（不 await，避免场景切换后才截屏）
	var img := get_viewport().get_texture().get_image()
	img.save_png(SHOT_DIR + "/ui_" + tag + ".png")
	print("[survey] saved ui_", tag)


func _process(delta: float) -> void:
	t += delta
	match stage:
		0:  # 主菜单
			if t >= 1.2:
				stage = 1
				_shot("1_main_menu")
				get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
		1:  # 角色选择
			if t >= 2.6:
				stage = 2
				_shot("2_char_select")
				# 与 auto_test 相同的启动方式：change_scene 会释放旧场景
				GameManager.start_new_game("fire_mage", "forest")
				get_tree().change_scene_to_file("res://scenes/main/game.tscn")
		2:  # 游戏内 HUD + 背景 + 角色
			if t >= 6.0:
				stage = 3
				_shot("3_game_hud")
				var p = get_tree().get_first_node_in_group("player")
				if p:
					p.stats.add_exp(400.0)  # 触发升级面板
		3:  # 升级面板（游戏暂停中）
			if t >= 7.5:
				stage = 4
				_shot("4_upgrade")
				var panel = get_tree().current_scene.get_node_or_null("UI/UpgradePanel")
				if panel and panel.visible:
					panel._on_option_selected(0)
				get_tree().paused = false
				get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")
		4:  # 商店
			if t >= 9.0:
				stage = 5
				_shot("5_shop")
				get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")
		5:  # 设置
			if t >= 10.4:
				stage = 6
				_shot("6_settings")
				get_tree().change_scene_to_file("res://scenes/ui/result_screen.tscn")
		6:  # 结算
			if t >= 11.8:
				stage = 7
				_shot("7_result")
				print("[survey] done")
				get_tree().quit()
