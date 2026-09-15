## w_shots.gd - 武器化系统视觉验证：窗口模式跑游戏并截图
## 用法: Godot --path game res://tools/w_shots.tscn
## 输出: C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/w_*.png
## 覆盖：不同武器开火区分度 / 施法动作+法杖闪光 / HUD武器槽 / 元素爆裂区分 / 升级池新选项
extends Node

const SHOT_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots"
const ENEMY_SCENES := [
	"res://scenes/enemies/skeleton_mage.tscn",
	"res://scenes/enemies/swarm_bug.tscn",
	"res://scenes/enemies/shadow_servant.tscn",
]

var t := 0.0
var stage := 0
var game: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_character("fire_mage")


func _start_character(char_id: String) -> void:
	if game != null and is_instance_valid(game):
		game.queue_free()
		game = null
	GameManager.start_new_game(char_id, "forest")
	game = load("res://scenes/main/game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	_setup.call_deferred(game)


func _setup(game_node: Node) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(game_node):
		return
	get_tree().current_scene = game_node
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	# 摆一圈敌人（供索敌/命中）
	var offsets := [Vector2(-360, -80), Vector2(390, -120), Vector2(-320, 150), Vector2(350, 190), Vector2(60, -390)]
	for i in offsets.size():
		var e = load(ENEMY_SCENES[i % ENEMY_SCENES.size()]).instantiate()
		game_node.add_child(e)
		e.global_position = player.global_position + offsets[i]
	print("[wshots] setup ok char=", GameManager.current_character)


func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _shot(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [SHOT_DIR, shot_name])
	print("[wshots] saved ", shot_name)


func _process(delta: float) -> void:
	t += delta
	match stage:
		0:  # 等战斗热起来
			if t >= 1.6:
				# 补满 4 件武器（环绕法书 + 寒冰新星）→ HUD 4 槽全亮
				var p := _player()
				if p:
					p._equip_new_spell("orbit_orbs")
					p._equip_new_spell("frost_nova")
					p._equip_new_spell.call_deferred("arcane_beam")
				stage = 1
		1:  # 火法师多武器开火中：火球+光束齐射（飞弹自动）
			if t >= 2.0:
				var p := _player()
				if p:
					var enemies := get_tree().get_nodes_in_group("enemies")
					if enemies.size() > 0:
						p.spell_caster.cast_spell(1, enemies[0].global_position)
						if p.spell_caster.spell_slots[3]:
							p.spell_caster.cooldowns[3] = 0.0
							p.spell_caster.cast_spell(3, enemies[0].global_position)
				stage = 2
		2:  # 弹体飞行中截图（不同武器拖尾/光晕区分 + HUD 武器槽）
			if t >= 2.1:
				_shot("w_1_weapons_fire")
				stage = 3
		3:  # 元素爆裂横排对比（六元素运动模式差异）
			if t >= 2.6:
				_spawn_element_bursts()
				stage = 4
		4:
			if t >= 2.78:
				_shot("w_2_element_bursts")
				stage = 5
		5:  # 施法动作：镜头推近 → 手动触发一次施法 → 抓施法帧+法杖闪光
			if t >= 2.95:
				_set_cam_zoom(4.0)
				var p := _player()
				if p:
					var enemies := get_tree().get_nodes_in_group("enemies")
					if enemies.size() > 0:
						p.spell_caster.cooldowns[1] = 0.0
						p.spell_caster.spell_slots[1].current_cooldown = 0.0
						p.spell_caster.cast_spell(1, enemies[0].global_position)
				stage = 6
		6:
			if t >= 3.14:
				_shot("w_3_cast_anim")
				_set_cam_zoom(1.5)
				stage = 7
		7:  # 升级池新选项（获得新法术 / 法术强化）
			if t >= 3.5:
				_show_upgrade_showcase()
				stage = 8
		8:
			if t >= 3.9:
				_shot("w_4_upgrade_pool")
				_close_upgrade_showcase()
				stage = 9
		9:  # 水法师：潮汐冲击（推近镜头抓水浪展开瞬间）
			if t >= 4.4:
				_start_character("water_mage")
				stage = 10
		10:
			if t >= 6.0:
				_set_cam_zoom(2.5)
				var p := _player()
				if p:
					var enemies := get_tree().get_nodes_in_group("enemies")
					if enemies.size() > 0:
						p.spell_caster.cooldowns[1] = 0.0
						p.spell_caster.spell_slots[1].current_cooldown = 0.0
						p.spell_caster.cast_spell(1, enemies[0].global_position)
				stage = 11
		11:
			if t >= 6.12:
				_shot("w_5_water_mage")
				_set_cam_zoom(1.5)
				stage = 12
		12:  # 雷法师：连锁闪电（抓连锁闪线进行时）
			if t >= 6.7:
				_start_character("lightning_mage")
				stage = 13
		13:
			if t >= 8.3:
				_set_cam_zoom(4.0)
				var p := _player()
				if p:
					var enemies := get_tree().get_nodes_in_group("enemies")
					if enemies.size() > 0:
						p.spell_caster.cooldowns[1] = 0.0
						p.spell_caster.spell_slots[1].current_cooldown = 0.0
						p.spell_caster.cast_spell(1, enemies[0].global_position)
				stage = 14
		14:
			if t >= 8.48:
				_shot("w_6_lightning_mage")
				_set_cam_zoom(1.5)
				get_tree().quit()


## 相机推近/复原（玩家自带 Camera2D，基准 zoom=1.5）
func _set_cam_zoom(value: float) -> void:
	var p := _player()
	if p and p.has_node("Camera2D"):
		p.get_node("Camera2D").zoom = Vector2(value, value)


## 六元素爆裂横排（上飘/放射/抖动/下坠运动模式一目了然）
func _spawn_element_bursts() -> void:
	var p := _player()
	if p == null:
		return
	var base: Vector2 = p.global_position
	var elements := ["fire", "water", "lightning", "nature", "shadow", "arcane"]
	for i in elements.size():
		FxLib.element_burst(self, base + Vector2(-250.0 + i * 100.0, -120.0), elements[i], 1.6)


## 升级面板展示（确定性构造：新法术 + 法术强化 + 数值升级）
func _show_upgrade_showcase() -> void:
	var p := _player()
	var panel = get_tree().current_scene.get_node_or_null("UI/UpgradePanel")
	if p == null or panel == null:
		return
	var options := [
		{"id": "new_spell", "spell_id": "arcane_beam", "name": "获得法术·穿透光束",
			"desc": "朝最近敌人瞬发直线穿透光束，命中线上所有敌人", "level": 1},
		{"id": "spell_power", "spell_id": "fireball", "boost": "damage",
			"name": "法术强化·火球术", "desc": "火球术 伤害 +25%", "level": 1},
		{"id": "damage", "name": "秘能强化", "desc": "所有法术伤害 +20%", "level": 1},
	]
	p.is_choosing_upgrade = true
	get_tree().paused = true
	panel.show_upgrade_options(options)


func _close_upgrade_showcase() -> void:
	var panel = get_tree().current_scene.get_node_or_null("UI/UpgradePanel")
	if panel:
		panel.hide_panel()
	get_tree().paused = false
	var p := _player()
	if p:
		p.is_choosing_upgrade = false
