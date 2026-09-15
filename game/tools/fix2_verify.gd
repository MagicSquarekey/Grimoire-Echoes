## fix2_verify.gd - 修复验证：无限地面 + 四方向朝向动画 + 地面精美化截图
## 用法（窗口模式）：Godot --path game res://tools/fix2_verify.tscn
## 截图输出：C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/fix2_*.png
extends Node

const SHOT_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots"
const SPAWN := Vector2(960, 540)
const FAR_NORTH := Vector2(960, 540 - 1600)

var t := 0.0
var stage := 0
var game: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.start_new_game("fire_mage", "forest")
	game = load("res://scenes/main/game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	_setup.call_deferred()


func _setup() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(game):
		get_tree().current_scene = game
		print("[fix2] player spawn at ", _player_pos())


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _player_pos() -> Vector2:
	var p := _player()
	return p.global_position if p else Vector2.INF


func _player_body() -> AnimatedSprite2D:
	var p := _player()
	return p.get_node_or_null("Body") as AnimatedSprite2D if p else null


func _process(delta: float) -> void:
	t += delta
	match stage:
		0:  # 玩家向北远移（超出旧版 1920x1080 绘制区两屏之外），验证无灰底
			if t >= 1.0:
				var p := _player()
				if p:
					p.global_position = FAR_NORTH
				stage = 1
		1:
			if t >= 1.8:
				_shot("fix2_1_far_north")
				_check_ground("fix2_1_far_north")
				_print_bg_state()
				stage = 2
		2:  # 向上移动 → 应播 run_back（背对镜头）
			if t >= 2.2:
				Input.action_press("move_up")
				stage = 3
		3:
			if t >= 3.4:
				_report_anim("up")
				_shot("fix2_2_move_up")
				Input.action_release("move_up")
				stage = 4
		4:  # 向下移动 → 应播 run_front（面向镜头）
			if t >= 3.6:
				Input.action_press("move_down")
				stage = 5
		5:
			if t >= 4.8:
				_report_anim("down")
				_shot("fix2_3_move_down")
				Input.action_release("move_down")
				stage = 6
		6:  # 向左移动 → 侧视 + flip_h
			if t >= 5.0:
				Input.action_press("move_left")
				stage = 7
		7:
			if t >= 6.0:
				_report_anim("left")
				_shot("fix2_4_move_left")
				Input.action_release("move_left")
				stage = 8
		8:  # 向右移动 → 侧视不翻转
			if t >= 6.2:
				Input.action_press("move_right")
				stage = 9
		9:
			if t >= 7.2:
				_report_anim("right")
				_shot("fix2_5_move_right")
				Input.action_release("move_right")
				stage = 10
		10:  # 回出生点，验证出生魔法阵 + 地面精美化全景
			if t >= 7.4:
				var p := _player()
				if p:
					p.global_position = SPAWN
				stage = 11
		11:
			if t >= 8.4:
				_shot("fix2_6_spawn_forest")
				stage = 12
		12:  # 其余主题地面质量回归
			if t >= 8.6:
				var bg := game.get_node_or_null("Background")
				if bg:
					bg.apply_map("lava")
				stage = 13
		13:
			if t >= 9.6:
				_shot("fix2_7_ground_lava")
				var bg := game.get_node_or_null("Background")
				if bg:
					bg.apply_map("ice")
				stage = 14
		14:
			if t >= 10.6:
				_shot("fix2_8_ground_ice")
				var bg := game.get_node_or_null("Background")
				if bg:
					bg.apply_map("shadow_realm")
				stage = 15
		15:
			if t >= 11.6:
				_shot("fix2_9_ground_shadow")
				_report()
				get_tree().quit()


func _shot(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [SHOT_DIR, shot_name])
	print("[fix2] saved ", shot_name, "  player_at=", _player_pos())


## 检查截图四角与中心不是默认灰底（clear color 0.3,0.3,0.3）
func _check_ground(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var w := img.get_width()
	var h := img.get_height()
	var bad := 0
	for pt: Vector2i in [Vector2i(8, 8), Vector2i(w - 9, 8), Vector2i(8, h - 9),
			Vector2i(w - 9, h - 9), Vector2i(w / 2, h / 2)]:
		var c := img.get_pixel(pt.x, pt.y)
		var is_gray := absf(c.r - 0.3) < 0.02 and absf(c.g - 0.3) < 0.02 and absf(c.b - 0.3) < 0.02
		if is_gray:
			bad += 1
		print("[fix2]   px(%d,%d) = %s%s" % [pt.x, pt.y, c, "  <-- GRAY!" if is_gray else ""])
	print("[fix2] ground check ", shot_name, ": ", "FAIL gray px=" + str(bad) if bad > 0 else "OK no gray")


func _print_bg_state() -> void:
	var bg := game.get_node_or_null("Background")
	if bg:
		print("[fix2] bg cam_center=", bg._cam_center, " vis_size=", bg._vis_size,
				" node_pos=", bg.global_position)


func _report_anim(dir: String) -> void:
	var body := _player_body()
	if body:
		print("[fix2] move_", dir, ": anim=", body.animation, " flip_h=", body.flip_h,
				" velocity=", _player().velocity if _player() else Vector2.ZERO)


func _report() -> void:
	var body := _player_body()
	if body:
		print("[fix2] player frames=", body.sprite_frames.resource_path,
				" anims=", body.sprite_frames.get_animation_names())
	var enemies := get_tree().get_nodes_in_group("enemies")
	print("[fix2] enemies alive=", enemies.size())
	for e in enemies.slice(0, 8):
		var b: Node = e.get_node_or_null("Body")
		if b is AnimatedSprite2D:
			var vel: Vector2 = e.velocity if "velocity" in e else Vector2.ZERO
			print("  - ", e.name, " anim=", b.animation, " flip_h=", b.flip_h,
					" vel=", vel)
	print("[fix2] report done")
