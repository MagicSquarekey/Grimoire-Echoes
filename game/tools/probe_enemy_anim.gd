## probe_enemy_anim.gd - 真游戏内怪物动画播放状态探针（窗口模式）
## 目的：精灵帧本身各不相同，但游戏里怪物"平移不动画"。这里在真实 game.tscn 里
##       抓一只活怪，逐帧记录 velocity / animation / frame / frame_progress / is_playing，
##       定位是"没切到 run"还是"切了但帧不推进"。
## 用法: Godot --path game res://tools/probe_enemy_anim.tscn
extends Node

var game: Node = null
var t := 0.0
var sampled := 0
var distinct_frames := {}
var target_enemy: Node2D = null
var _last_beat := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.start_new_game("water_mage", "forest")
	game = load("res://scenes/main/game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	_setup.call_deferred(game)


func _setup(g: Node) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(g):
		return
	get_tree().current_scene = g
	game = g


func _process(delta: float) -> void:
	t += delta
	if target_enemy == null or not is_instance_valid(target_enemy):
		if t < 12.0:
			if int(t) != _last_beat:
				_last_beat = int(t)
				print("[anim] t=%.1f 敌人数=%d" % [t, get_tree().get_nodes_in_group("enemies").size()])
			return
		var e := get_tree().get_first_node_in_group("enemies")
		if e == null:
			print("[anim] 2 秒内没有敌人出现")
			get_tree().quit()
			return
		target_enemy = e
		print("[anim] 采样对象: %s" % e.name)
		return

	if sampled >= 24:
		print("[anim] 24 帧内出现过的 frame 索引: %s" % [distinct_frames.keys()])
		print("[anim] 不同 frame 数 = %d" % distinct_frames.size())
		get_tree().quit()
		return

	var body := target_enemy.get_node_or_null("Body") as AnimatedSprite2D
	if body == null:
		print("[anim] 没有 Body")
		get_tree().quit()
		return
	sampled += 1
	distinct_frames[body.frame] = true
	print("[anim] #%02d vel=%.1f anim=%s frame=%d progress=%.3f playing=%s fps=%.1f time_scale=%.2f" % [
		sampled,
		target_enemy.velocity.length(),
		body.animation,
		body.frame,
		body.frame_progress,
		str(body.is_playing()),
		body.sprite_frames.get_animation_speed(body.animation) if body.sprite_frames else -1.0,
		Engine.time_scale,
	])
