## final_survey.gd - UI 收尾全流程视觉验证工具
## 用法：Godot --path game res://tools/final_survey.tscn
## 截图输出：C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/final_*.png
## 覆盖：角色选择、游戏内 HUD/主题地面、升级面板（真实选项文本）、
##       暂停菜单、商店、结算、游戏结束、三种地图地面（lava/ice/shadow_realm）
## 截图方式与 ui_survey 一致：_process 阶段机中立即取当前帧，不使用 await
extends Node

const SHOT_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots"

var t := 0.0
var stage := 0
var t_pause_started := 0.0
var t_shop_started := 0.0
var t_result_started := 0.0
var t_result_shown := 0.0
var t_map_started := 0.0
var t_over_started := 0.0


func _ready() -> void:
	if get_tree().current_scene == self:
		# 包装模式：把驱动副本挂到树根（场景切换不会释放），再进入角色选择
		var driver := Node.new()
		driver.set_script(get_script())
		driver.name = "FinalSurveyDriver"
		get_tree().root.add_child.call_deferred(driver)
		get_tree().change_scene_to_file.call_deferred("res://scenes/ui/character_select.tscn")
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)


func _shot(tag: String) -> void:
	# 直接取最后一帧已渲染画面（不 await，避免场景切换后才截屏）
	var img := get_viewport().get_texture().get_image()
	img.save_png(SHOT_DIR + "/final_" + tag + ".png")
	print("[final] saved final_", tag)


func _enter_game(map_id: String) -> void:
	GameManager.start_new_game("fire_mage", map_id)
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")


func _process(delta: float) -> void:
	t += delta
	match stage:
		0:  # 角色选择（验证卡片间隙光条修复）
			if t >= 1.6:
				stage = 1
				_shot("1_char_select")
				_enter_game("forest")
		1:  # 游戏内 HUD + 森林主题地面
			if t >= 4.8:
				stage = 2
				_shot("2_game_forest")
				var p = get_tree().get_first_node_in_group("player")
				if p:
					# 60 经验恰好触发 1 级（首级需求 56，次级 118），只弹一次升级面板
					p.stats.add_exp(60.0)
		2:  # 升级面板（等待入场动画与文本填充完成后截图）
			if t >= 6.6:
				stage = 3
				_shot("3_upgrade")
				var panel = get_tree().current_scene.get_node_or_null("UI/UpgradePanel")
				if panel and panel.visible:
					panel._on_option_selected(0)
				get_tree().paused = false
		3:  # 暂停菜单（游戏流程内触发）
			if t >= 7.2:
				stage = 4
				var pm = get_tree().current_scene.get_node_or_null("UI/PauseMenu")
				if pm:
					pm.show_menu()
				t_pause_started = t
		4:
			if t >= t_pause_started + 0.9:
				stage = 5
				_shot("4_pause")
				var pm = get_tree().current_scene.get_node_or_null("UI/PauseMenu")
				if pm:
					pm.hide_menu()
				get_tree().paused = false
				get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")
		5:  # 商店（场景就绪后调 show_shop 生成真实商品）
			if t >= t_pause_started + 1.7:
				stage = 6
				var shop = get_tree().current_scene
				if shop and shop.has_method("show_shop"):
					shop.show_shop()
				t_shop_started = t
		6:
			if t >= t_shop_started + 0.9:
				stage = 7
				_shot("5_shop")
				get_tree().paused = false
				get_tree().change_scene_to_file("res://scenes/ui/result_screen.tscn")
				t_result_started = t
		7:  # 结算画面（注入测试数据后显示）
			if t >= t_result_started + 0.8:
				stage = 8
				var rs = get_tree().current_scene
				if rs and rs.has_method("show_result"):
					rs.show_result({"wave": 7, "kills": 132, "time": 512.4, "gold": 96, "exp": 340})
				t_result_shown = t
		8:
			if t >= t_result_shown + 0.9:
				stage = 9
				_shot("6_result")
				get_tree().paused = false
				_enter_game("lava")
				t_map_started = t
		9:  # 熔岩裂谷地面
			if t >= t_map_started + 3.2:
				stage = 10
				_shot("7_ground_lava")
				_enter_game("ice")
				t_map_started = t
		10:  # 冰封山脉地面
			if t >= t_map_started + 3.2:
				stage = 11
				_shot("8_ground_ice")
				_enter_game("shadow_realm")
				t_map_started = t
		11:  # 暗影深渊地面
			if t >= t_map_started + 3.2:
				stage = 12
				_shot("9_ground_shadow")
				# 游戏结束画面：用测试数据走真实触发链（GameManager.game_over → EventBus → GameOverScreen）
				GameManager.current_wave = 6
				GameManager.kill_count = 87
				GameManager.play_time = 437.25
				GameManager.game_over()
				t_over_started = t
		12:  # 游戏结束画面
			if t >= t_over_started + 1.1:
				stage = 13
				_shot("10_game_over")
				print("[final] done")
				get_tree().quit()
