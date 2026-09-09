## verify_shots.gd - 视觉验证工具：窗口模式跑游戏并截图
## 用法：Godot --path game res://tools/verify_shots.tscn
## 截图输出：C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/verify_*.png
extends Node

const SHOT_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots"

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
	if is_instance_valid(game):
		get_tree().current_scene = game
		var player := get_tree().get_first_node_in_group("player")
		# 额外放两只变体敌人用于视觉验证（WaveManager 当前只出 shadow_servant）
		var skel: PackedScene = load("res://scenes/enemies/skeleton_mage.tscn")
		var bug: PackedScene = load("res://scenes/enemies/swarm_bug.tscn")
		if player:
			var e1 := skel.instantiate()
			game.add_child(e1)
			e1.global_position = player.global_position + Vector2(-140, -70)
			var e2 := bug.instantiate()
			game.add_child(e2)
			e2.global_position = player.global_position + Vector2(140, -90)
			print("[verify] sample enemies placed")


func _process(delta: float) -> void:
	t += delta
	# 模拟移动输入：验证 run 动画切换与左右翻转
	if t >= 4.0 and t < 6.2:
		Input.action_press("move_left")
	elif t >= 6.2 and t < 8.0:
		Input.action_release("move_left")
		Input.action_press("move_right")
	match stage:
		0:
			if t >= 3.0:
				_shot("verify_1")
				stage = 1
		1:
			if t >= 6.0:
				_shot("verify_2")
				stage = 2
		2:
			if t >= 10.0:
				Input.action_release("move_right")
				_shot("verify_3")
				_report()
				get_tree().quit()


func _shot(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [SHOT_DIR, shot_name])
	print("[verify] saved ", shot_name)


func _report() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p:
		var body := p.get_node_or_null("Body")
		if body:
			print("[verify] player Body class=", body.get_class(),
					" anim=", body.animation,
					" frames_ok=", body.sprite_frames != null,
					" frames_path=", body.sprite_frames.resource_path if body.sprite_frames else "null",
					" auto_variant=", body.auto_variant,
					" flip_h=", body.flip_h,
					" modulate.a=", body.modulate.a)
		print("[verify] current_character=", GameManager.current_character)
	var enemies := get_tree().get_nodes_in_group("enemies")
	print("[verify] enemies alive=", enemies.size())
	for e in enemies.slice(0, 8):
		var b: Node = e.get_node_or_null("Body")
		if b is AnimatedSprite2D:
			print("  - ", e.name, " anim=", b.animation, " frame=", b.frame,
					" playing=", b.is_playing())
	print("[verify] report done")
