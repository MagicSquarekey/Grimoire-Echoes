## verify_all.gd - 四项修复综合验证截图（边界/朝向/地面/特效）
## 用法：Godot --path game res://tools/verify_all.tscn
extends Node

const SHOT_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots"
const WALK := 2.6  # 每方向行走秒数

var t := 0.0
var stage := 0
var dir_queue: Array = []  # [action, shot_tag]
var dir_t := 0.0


func _ready() -> void:
	if get_tree().current_scene == self:
		var driver := Node.new()
		driver.set_script(get_script())
		driver.name = "VerifyAllDriver"
		get_tree().root.add_child.call_deferred(driver)
		GameManager.start_new_game("fire_mage", "forest")
		get_tree().change_scene_to_file.call_deferred("res://scenes/main/game.tscn")
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	dir_queue = [
		["move_up", "v4_back_facing"],      # 向上走：背面朝向
		["move_down", "v4_front_facing"],   # 向下走：正面朝镜头
		["move_left", "v4_left_side"],
		["move_right", "v4_right_side"],
	]


func _shot(tag: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(SHOT_DIR + "/" + tag + ".png")
	print("[v4] saved ", tag)


func _process(delta: float) -> void:
	t += delta
	var p := get_tree().get_first_node_in_group("player")
	# 持续治疗防干扰
	if p and is_instance_valid(p) and fmod(t, 1.0) < delta:
		p.stats.heal(9999)

	match stage:
		0:  # 等游戏场景就绪
			if p and t >= 2.0:
				stage = 1
				dir_t = 0.0
		1:  # 四方向行走 + 逐向截图（走到远处同时验证无限地面）
			if p:
				dir_t += delta
				var cur: Array = dir_queue[0]
				Input.action_press(cur[0])
				if dir_t >= WALK * 0.7 and not has_meta("shot_" + cur[1]):
					_shot(cur[1])
					set_meta("shot_" + cur[1], true)
				if dir_t >= WALK:
					Input.action_release(cur[0])
					dir_queue.pop_front()
					dir_t = 0.0
					if dir_queue.is_empty():
						stage = 2
			else:
				stage = 2
		2:  # 远离出生点的地面全景（此时已走出 4×WALK×速度 距离）
			if t >= 15.0:
				stage = 3
				_shot("v4_far_ground")  # 行走结束瞬间，含地面全景
		3:  # 战斗特效（拖尾/爆裂在真实战斗中抓拍）+ 超时保护
			if t >= 18.0 and not has_meta("fx_a"):
				set_meta("fx_a", true)
				_shot("v4_fx_combat_1")
			if t >= 22.0 and not has_meta("fx_b"):
				set_meta("fx_b", true)
				_shot("v4_fx_combat_2")
			if t >= 24.5:
				print("[v4] done. 玩家位置=", p.global_position if p else "N/A")
				get_tree().quit()
