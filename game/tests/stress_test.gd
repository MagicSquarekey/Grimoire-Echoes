## StressTest - 70秒无头压力模拟
## 场景：新游戏 → 3倍速 → 周期性全场清怪推进波次 → 大量敌人生成/死亡/掉落
## 观察目标：波次持续推进、敌人峰值、SCRIPT ERROR / WARNING、存档回环
extends Node

var t = 0.0
var stage = 0
var errors = 0
var max_wave_reached = 0
var max_enemies_alive = 0
var kill_timer = 0.0
var stat_timer = 0.0

const SIM_DURATION = 70.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[STRESS] === %.0f秒压力模拟启动 ===" % SIM_DURATION)

func _process(delta: float) -> void:
	t += delta
	match stage:
		0:
			if t >= 0.3:
				stage = 1
				GameManager.start_new_game("fire_mage", "forest")
				GameManager.toggle_game_speed()  # 2x
				GameManager.toggle_game_speed()  # 3x
				get_tree().change_scene_to_file("res://scenes/main/game.tscn")
				print("[STRESS] t=%.1f 新游戏启动, 3倍速" % t)
		1:
			if t >= 1.0:
				stage = 2
				print("[STRESS] t=%.1f 进入模拟主循环" % t)
		2:
			_run_simulation(delta)
		3:
			pass  # 已结束

func _run_simulation(delta: float) -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p == null or not is_instance_valid(p):
		if t > 3.0:
			errors += 1
			print("[STRESS] 错误: 玩家丢失 t=%.1f" % t)
			_finish()
		return

	# 保持玩家存活（专注压测波次与生成）
	p.is_invincible = true
	p.stats.heal(9999.0)

	# 每2秒全场清怪 → 推动波次 + 大量死亡/掉落/生成
	kill_timer += delta
	if kill_timer >= 2.0:
		kill_timer = 0.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.is_alive and e.has_method("take_damage"):
				e.take_damage(99999.0)

	# 统计峰值
	var enemies_now = get_tree().get_nodes_in_group("enemies").size()
	max_wave_reached = max(max_wave_reached, WaveManager.current_wave)
	max_enemies_alive = max(max_enemies_alive, enemies_now)

	stat_timer += delta
	if stat_timer >= 10.0:
		stat_timer = 0.0
		print("[STRESS] t=%.0f 波次=%d 存活敌=%d 峰值敌=%d 击杀=%d 金币=%d" % [
			t, WaveManager.current_wave, enemies_now, max_enemies_alive,
			GameManager.kill_count, GameManager.total_gold])

	if t >= SIM_DURATION:
		_finish()

func _finish() -> void:
	if stage == 3:
		return
	stage = 3
	print("[STRESS] t=%.1f 模拟结束" % t)
	print("[STRESS] 结果: 峰值波次=%d 峰值存活敌=%d 总击杀=%d 金币=%d 游戏时长=%.0fs" % [
		max_wave_reached, max_enemies_alive, GameManager.kill_count,
		GameManager.total_gold, GameManager.play_time])

	# 存档回环验证
	SaveManager.auto_save()
	if not SaveManager.has_save(0):
		errors += 1
		print("[STRESS] 错误: 自动存档失败")

	if max_wave_reached < 5:
		errors += 1
		print("[STRESS] 错误: %.0f秒内未推进到第5波 (仅到 %d)" % [SIM_DURATION, max_wave_reached])
	if max_enemies_alive < 10:
		errors += 1
		print("[STRESS] 错误: 敌人峰值过低 (%d)" % max_enemies_alive)

	if errors == 0:
		print("[STRESS] === 压力模拟通过 ===")
	else:
		print("[STRESS] === 压力模拟完成: %d个错误 ===" % errors)
	get_tree().quit(0 if errors == 0 else 1)
