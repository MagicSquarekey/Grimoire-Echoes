## fx_shots.gd - 特效视觉验证工具：窗口模式跑游戏并截图（仅验证新增战斗特效）
## 用法: Godot --path game res://tools/fx_shots.tscn
## 截图输出: C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/fx_*.png
extends Node

const SHOT_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots"

const PROJ_SCENE := preload("res://scenes/spells/projectile.tscn")
const GEM_SCENE := preload("res://scenes/pickups/experience_gem.tscn")
const COIN_SCENE := preload("res://scenes/pickups/gold_coin.tscn")

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
	# 摆几只敌人（供弹体命中/死亡消散验证）
	var skel: PackedScene = load("res://scenes/enemies/skeleton_mage.tscn")
	var bug: PackedScene = load("res://scenes/enemies/swarm_bug.tscn")
	var layouts := [[skel, Vector2(-170, -70)], [skel, Vector2(190, -100)], [bug, Vector2(-130, 90)], [bug, Vector2(160, 80)]]
	for cfg in layouts:
		var e = cfg[0].instantiate()
		game.add_child(e)
		e.global_position = player.global_position + cfg[1]
	# 摆一排拾取物（光晕/星芒验证）
	for i in 4:
		var gem = GEM_SCENE.instantiate()
		game.add_child(gem)
		gem.global_position = player.global_position + Vector2(-80 + i * 50, 100)
	for i in 3:
		var coin = COIN_SCENE.instantiate()
		game.add_child(coin)
		coin.global_position = player.global_position + Vector2(-55 + i * 55, 150)
	print("[fxshots] setup ok, player=", player.global_position)


func _process(delta: float) -> void:
	t += delta
	match stage:
		0:  # 展示弹体：1 发横穿空地的火弹（长拖尾）+ 3 发元素弹射向敌人
			if t >= 2.2:
				_spawn_showcase_projectiles()
				stage = 1
		1:  # 拖尾+光晕 飞行中
			if t >= 2.5:
				_shot("fx_1_trail")
				stage = 2
		2:  # 拖尾更长 + 命中爆裂正在发生
			if t >= 2.75:
				_shot("fx_2_hit_burst")
				stage = 3
		3:  # 定点补拍三色爆裂（确定性）
			if t >= 3.2:
				_spawn_manual_bursts()
				stage = 4
		4:
			if t >= 3.35:
				_shot("fx_3_hit_burst_colors")
				stage = 5
		5:  # 杀一只敌人 → 消散
			if t >= 3.7:
				_kill_one_enemy()
				stage = 6
		6:
			if t >= 3.95:
				_shot("fx_4_death_dissipate")
				stage = 7
		7:  # 拾取物光晕 + 强制金币星芒（确定性）
			if t >= 4.25:
				_force_coin_sparkle()
				stage = 8
		8:
			if t >= 4.4:
				_shot("fx_5_pickup_shine")
				stage = 9
		9:  # 升级光环（直接发 EventBus 信号，纯视觉监听响应）
			if t >= 4.7:
				EventBus.player_level_up.emit(3)
				stage = 10
		10:
			if t >= 4.9:
				_shot("fx_6_level_up_ring")
				_report()
				get_tree().quit()


## 展示弹体：火弹横穿空地（长拖尾），其余元素弹射向敌人
func _spawn_showcase_projectiles() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	var game := get_tree().current_scene
	# 火弹：向左横穿空地，拖尾最直观
	var p := PROJ_SCENE.instantiate()
	game.add_child(p)
	p.global_position = player.global_position + Vector2(60, -20)
	p.setup(20.0, 240.0, Vector2.LEFT, "fire", 0, 0, 1, player)
	# 各元素弹射向敌人（命中出爆裂）
	var elements := ["water", "shadow", "lightning"]
	for i in mini(3, enemies.size()):
		var e = enemies[i]
		if is_instance_valid(e):
			var p2 := PROJ_SCENE.instantiate()
			game.add_child(p2)
			p2.global_position = player.global_position
			var dir: Vector2 = player.global_position.direction_to(e.global_position)
			p2.setup(20.0, 520.0, dir, elements[i], 0, 0, 1, player)
	print("[fxshots] showcase projectiles spawned")


## 定点三色爆裂（确定性截图）
func _spawn_manual_bursts() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var base: Vector2 = player.global_position
	FxLib.hit_burst(self, base + Vector2(-120, -60), FxLib.color_for("fire"), 12)
	FxLib.hit_burst(self, base + Vector2(0, -90), FxLib.color_for("lightning"), 12)
	FxLib.hit_burst(self, base + Vector2(120, -60), FxLib.color_for("water"), 12)


func _kill_one_enemy() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.is_alive and e.has_method("take_damage"):
			e.take_damage(99999.0)
			print("[fxshots] killed ", e.name)
			return


func _force_coin_sparkle() -> void:
	# 找到金币的 FxSparkle 节点，立刻触发一次星芒（确定性）
	for coin in get_tree().current_scene.get_children():
		if coin.name.begins_with("GoldCoin"):
			var sp := coin.get_node_or_null("FxSparkle")
			if sp and sp.has_method("flash"):
				sp.flash()


func _shot(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [SHOT_DIR, shot_name])
	print("[fxshots] saved ", shot_name)


func _report() -> void:
	# 简单泄漏观察：统计树上一次性粒子与弹体残留
	var bursts := 0
	var projs := 0
	for n in _all_nodes(get_tree().root):
		if n is CPUParticles2D:
			bursts += 1
		elif n is Area2D and n.get_script() and String(n.get_script().resource_path).ends_with("projectile.gd"):
			projs += 1
	print("[fxshots] report: CPUParticles2D alive=", bursts, " projectiles alive=", projs)


func _all_nodes(root: Node) -> Array:
	var out: Array = []
	for c in root.get_children():
		out.append(c)
		out.append_array(_all_nodes(c))
	return out
