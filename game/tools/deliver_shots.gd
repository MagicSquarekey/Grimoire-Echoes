## deliver_shots.gd - 交付级截图工具
## 用法：Godot --path game res://tools/deliver_shots.tscn
## 截图输出：C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/deliver_*.png
## 覆盖：主菜单 / 角色选择 / 战斗全景(2.5D+弹体阴影+出生传送门) /
##       商店 / 升级面板 / 新掉落物(回血药剂+磁石) / 结算画面(完整数据)
extends Node

const SHOT_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots"

const HOUND_SCENE := preload("res://scenes/enemies/demon_hound.tscn")
const SHADOW_SCENE := preload("res://scenes/enemies/shadow_servant.tscn")
const ORC_SCENE := preload("res://scenes/enemies/orc_warrior.tscn")

var t := 0.0
var stage := 0
var _spawned := false
var _upgrade_shotted := false
var _last_hb := 0.0


func _ready() -> void:
	if get_tree().current_scene == self:
		# 包装模式：驱动副本挂树根（场景切换不释放），先进主菜单
		var driver := Node.new()
		driver.set_script(get_script())
		driver.name = "DeliverShotsDriver"
		get_tree().root.add_child.call_deferred(driver)
		get_tree().change_scene_to_file.call_deferred("res://scenes/main/main_menu.tscn")
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)


func _shot(tag: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(SHOT_DIR + "/deliver_" + tag + ".png")
	print("[deliver] saved deliver_", tag)


func _enter_game() -> void:
	GameManager.start_new_game("fire_mage", "forest")
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")


func _spawn(scene: PackedScene, pos: Vector2, difficulty := 3.0) -> void:
	var game := get_tree().current_scene
	var e = scene.instantiate()
	game.add_child(e)
	e.global_position = pos
	e.set_difficulty(difficulty)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		e.target = player


func _process(delta: float) -> void:
	t += delta
	# 摆拍期间保持玩家无敌（避免被围殴致死弹出结算画面卡住流程），
	# 并持续点掉升级面板（多级队列会反复弹面板）
	if stage >= 2 and stage <= 8:
		var p0 = get_tree().get_first_node_in_group("player")
		if p0 and is_instance_valid(p0):
			p0.is_invincible = true
			p0.stats.heal(9999.0)
		var panel_x = get_tree().current_scene.get_node_or_null("UI/UpgradePanel") if get_tree().current_scene else null
		if panel_x and panel_x.visible and (_upgrade_shotted or stage != 6):
			panel_x._on_option_selected(0)
	match stage:
		0:  # 主菜单（含"继续旅程"按钮可用性状态）
			if t >= 1.6:
				stage = 1
				_shot("1_main_menu")
				get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
		1:  # 角色选择
			if t >= 3.6:
				stage = 2
				_shot("2_char_select")
				_enter_game()
		2:  # 战斗全景：真实波次出怪 + 摆拍前后纵深（验证 y 排序/弹体阴影/传送门）
			if t >= 8.0 and not _spawned:
				_spawned = true
				var p = get_tree().get_first_node_in_group("player")
				if p:
					var base: Vector2 = p.global_position
					_spawn(SHADOW_SCENE, base + Vector2(60, 60))
					_spawn(SHADOW_SCENE, base + Vector2(-70, 40))
					_spawn(HOUND_SCENE, base + Vector2(120, -50))
					_spawn(HOUND_SCENE, base + Vector2(-140, -30))
					_spawn(ORC_SCENE, base + Vector2(20, 130))
			if t >= 10.0:
				stage = 3
				_shot("3_battle")
		3:  # 商店：给一笔金币开门营业
			if t >= 10.5:
				stage = 4
				GameManager.add_gold(120)
				var shop = get_tree().current_scene.get_node_or_null("UI/Shop")
				if shop:
					shop.show_shop()
		4:
			if t >= 12.2:
				stage = 5
				_shot("4_shop")
				var shop2 = get_tree().current_scene.get_node_or_null("UI/Shop")
				if shop2 and shop2.visible:
					shop2._on_close_pressed()
		5:  # 升级面板（真实选项）
			if t >= 12.8:
				var p = get_tree().get_first_node_in_group("player")
				if p:
					p.stats.add_exp(400.0)
				stage = 6
		6:
			var panel = get_tree().current_scene.get_node_or_null("UI/UpgradePanel")
			if panel and panel.visible and t >= 14.4 and not _upgrade_shotted:
				_upgrade_shotted = true
				_shot("5_upgrade")
			# 截图后持续点击，把多级升级队列全部清空（否则游戏停在暂停）
			if _upgrade_shotted and panel and panel.visible:
				panel._on_option_selected(0)
			if _upgrade_shotted and not get_tree().paused:
				stage = 7
			elif t >= 30.0:
				stage = 7

		7:  # 新掉落物特写：回血药剂 + 磁石
			if t >= 15.0 and not get_tree().paused:
				stage = 8
				var game := get_tree().current_scene
				var p = get_tree().get_first_node_in_group("player")
				if p and game:
					var potion = load("res://scenes/pickups/health_potion.tscn").instantiate()
					game.add_child(potion)
					# 放到磁吸范围(100px)外，避免还没截图就被吸走
					potion.global_position = p.global_position + Vector2(-190, 40)
					var magnet = load("res://scenes/pickups/magnet_pickup.tscn").instantiate()
					game.add_child(magnet)
					magnet.global_position = p.global_position + Vector2(190, 40)
					# 冻结出怪聚焦摆拍
					WaveManager.set_process(false)
				_t_pickups_done = t
		8:
			if _t_pickups_done > 0.0 and t >= _t_pickups_done + 2.0:
				stage = 9
				_shot("6_pickups")
				# 结算画面（死亡数据完整性：波次/击杀/金币/等级/时长/最终武器）
				WaveManager.set_process(true)
				var p = get_tree().get_first_node_in_group("player")
				if p:
					p.is_invincible = false
					p.take_damage(99999.0)
				_t_over = t
		9:
			if t >= _t_over + 1.6:
				stage = 10
				_shot("7_game_over")
		10:
			if t >= _t_over + 2.2:
				print("[deliver] all done")
				get_tree().quit()

var _t_pickups_done := 0.0
var _t_over := 0.0

