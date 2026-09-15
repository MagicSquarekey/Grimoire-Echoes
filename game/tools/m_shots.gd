## m_shots.gd - 敌人系统扩容视觉验证：窗口模式跑游戏并截图
## 用法: Godot --path game res://tools/m_shots.tscn
## 截图输出: C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/m_*.png
## 主题：狼群包围 / 兽人推进 / 精英金光 / Boss战+血条 / 波次横幅
extends Node

const SHOT_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots"

const HOUND_SCENE := preload("res://scenes/enemies/demon_hound.tscn")
const BUG_SCENE := preload("res://scenes/enemies/swarm_bug.tscn")
const ORC_SCENE := preload("res://scenes/enemies/orc_warrior.tscn")
const SHADOW_SCENE := preload("res://scenes/enemies/shadow_servant.tscn")

var t := 0.0
var stage := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.start_new_game("fire_mage", "forest")
	var game: Node = load("res://scenes/main/game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	_setup.call_deferred(game)


func _setup(game: Node) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(game):
		return
	get_tree().current_scene = game
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	# 摆拍环境：玩家无敌 + 暂停自动施法（避免 Subjects 被玩家法术清场）
	player.is_invincible = true
	player.is_choosing_upgrade = true
	# 冻结波次状态机（截图工具自己摆怪，避免真实波次横幅抢镜）
	WaveManager.set_process(false)
	print("[mshots] setup ok, player=", player.global_position)


func _spawn(scene: PackedScene, pos: Vector2, difficulty := 5.0) -> Node:
	var game := get_tree().current_scene
	var e = scene.instantiate()
	game.add_child(e)
	e.global_position = pos
	e.set_difficulty(difficulty)  # 摆拍用高血量，避免被流弹秒杀
	var player := get_tree().get_first_node_in_group("player")
	if player:
		e.target = player  # 直接指派目标，确保追击表现
	return e


func _shot(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [SHOT_DIR, shot_name])
	print("[mshots] saved ", shot_name)


func _process(delta: float) -> void:
	t += delta
	match stage:
		0:  # 狼群包围：左侧猎犬包涌入 + 虫群环形合围
			if t >= 1.0:
				var player := get_tree().get_first_node_in_group("player")
				var base: Vector2 = player.global_position
				for i in 5:  # 猎犬狼群包（同侧）
					_spawn(HOUND_SCENE, base + Vector2(-560, -160 + i * 80))
				for i in 10:  # 虫群环形包抄
					var ang := TAU * float(i) / 10.0
					_spawn(BUG_SCENE, base + Vector2(cos(ang), sin(ang)) * 380.0)
				stage = 1
		1:
			if t >= 1.8:
				_shot("m_1_hound_pack_ring")
				stage = 2
		2:  # 兽人推进：右路兽人勇士率暗影仆从压进
			if t >= 2.2:
				var player := get_tree().get_first_node_in_group("player")
				var base: Vector2 = player.global_position
				for i in 3:
					_spawn(ORC_SCENE, base + Vector2(430 + (i % 2) * 130, -180 + i * 170))
				for i in 6:
					_spawn(SHADOW_SCENE, base + Vector2(300 + randf() * 200, -260 + i * 100))
				stage = 3
		3:
			if t >= 3.0:
				_shot("m_2_orc_advance")
				stage = 4
		4:  # 精英金光：清场后摆三只精英（兽人/暗影/虫群）+ 脚下金环，展示必掉金币
			if t >= 3.4:
				stage = 5  # 先推进状态，_process 期间有 await 防止重入
				for e in get_tree().get_nodes_in_group("enemies"):
					if is_instance_valid(e) and e.has_method("take_damage"):
						e.take_damage(99999.0)  # 清场（金币/宝石掉落顺带入镜）
				await get_tree().create_timer(0.15).timeout
				var player := get_tree().get_first_node_in_group("player")
				if player == null:
					return
				var base: Vector2 = player.global_position
				var e1 = _spawn(ORC_SCENE, base + Vector2(-280, -30))
				e1.make_elite()
				var e2 = _spawn(SHADOW_SCENE, base + Vector2(-170, 120))
				e2.make_elite()
				var e3 = _spawn(BUG_SCENE, base + Vector2(230, -130))
				e3.make_elite()
		5:
			if t >= 4.1:
				_shot("m_3_elite_gold")
				stage = 6
		6:  # Boss 战：清场后 Boss 登场（血条经 boss_spawned 自动显示）
			if t >= 4.5:
				stage = 7  # 先推进状态，防止 await 期间重入
				for e in get_tree().get_nodes_in_group("enemies"):
					if is_instance_valid(e) and e.has_method("take_damage"):
						e.take_damage(99999.0)
				await get_tree().create_timer(0.15).timeout
				var player := get_tree().get_first_node_in_group("player")
				if player == null:
					return
				var base: Vector2 = player.global_position
				var boss = _spawn(ORC_SCENE, base + Vector2(230, -60), 8.0)
				boss.make_boss(2.2)
				boss.take_damage(boss.max_health * 0.35)  # 压到 65% 血展示血条变化
				_spawn(SHADOW_SCENE, base + Vector2(100, 110))
				_spawn(SHADOW_SCENE, base + Vector2(320, 150))
		7:
			if t >= 5.9:
				_shot("m_4_boss_fight_bar")
				stage = 8
		8:  # 波次横幅
			if t >= 6.0:
				EventBus.wave_started.emit(7)
				stage = 9
		9:
			if t >= 6.6:
				_shot("m_5_wave_banner")
				get_tree().quit()
