## AutoTest - 无头模式端到端自动化测试 v2（修正暂停时序）
extends Node

var t = 0.0
var stage = 0
var errors = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[TEST] === 自动化测试v2启动 ===")

func player_valid() -> bool:
	var p = get_tree().get_first_node_in_group("player")
	return p != null and is_instance_valid(p)

func _process(delta: float) -> void:
	t += delta
	match stage:
		0:
			if t >= 0.3:
				stage = 1
				print("[TEST] S1 t=%.1f 启动新游戏" % t)
				GameManager.start_new_game("fire_mage", "forest")
				get_tree().change_scene_to_file("res://scenes/main/game.tscn")
		1:
			if t >= 8.0:
				stage = 2
				var enemies = get_tree().get_nodes_in_group("enemies")
				print("[TEST] S2 t=%.1f 敌人=%d 玩家=%s 波次=%d 击杀=%d" % [t, enemies.size(), str(player_valid()), WaveManager.current_wave, GameManager.kill_count])
				if enemies.size() == 0:
					errors += 1
					print("[TEST] S2 错误: 无敌人生成")
		2:
			if t >= 9.0:
				stage = 3
				if player_valid():
					var p = get_tree().get_first_node_in_group("player")
					var hp0 = p.stats.current_health
					p.is_invincible = false
					p.take_damage(15.0)
					print("[TEST] S3 t=%.1f 受伤 %.1f→%.1f" % [t, hp0, p.stats.current_health])
					if abs(hp0 - p.stats.current_health) < 1.0:
						errors += 1
						print("[TEST] S3 错误: 伤害未生效")
					p.stats.heal(9999)
				else:
					errors += 1
		3:
			if t >= 11.0:
				stage = 4
				if player_valid():
					var p = get_tree().get_first_node_in_group("player")
					p.stats.add_exp(400.0)
					print("[TEST] S4 t=%.1f +400exp → 等级=%d 待处理=%d" % [t, p.stats.current_level, p.pending_upgrades])
				else:
					errors += 1
		4:
			# 清空升级面板(游戏会暂停,逐帧点击直到队列空且未暂停)
			if player_valid():
				var p = get_tree().get_first_node_in_group("player")
				var panel = get_tree().current_scene.get_node_or_null("UI/UpgradePanel")
				if panel and panel.visible:
					panel._on_option_selected(0)
				elif p.pending_upgrades == 0 and not p.is_choosing_upgrade and not get_tree().paused:
					stage = 5
					print("[TEST] S4 t=%.1f 面板队列清空, 恢复运行" % t)
			else:
				stage = 5
		5:
			# AI验证: 传送到一只活着的敌人旁,观察侦测→追击→攻击
			if t >= 13.0:
				stage = 6
				if player_valid():
					var p = get_tree().get_first_node_in_group("player")
					var target_e = null
					for e in get_tree().get_nodes_in_group("enemies"):
						if is_instance_valid(e) and e.is_alive:
							target_e = e
							break
					if target_e:
						p.global_position = target_e.global_position + Vector2(120, 0)
						p.stats.heal(9999)
						p.is_choosing_upgrade = true  # 暂停自动施法,保证观察目标存活
						set_meta("ai_e", target_e)
						set_meta("ai_pos", target_e.global_position)
						set_meta("ai_hp", p.stats.current_health)
						print("[TEST] S5 t=%.1f 传送到 %s 旁, 施法已暂停, AI观察2.5秒" % [t, target_e.name])
					else:
						print("[TEST] S5 跳过: 无存活敌人")
						stage = 7
				else:
					stage = 7
		6:
			# AI观察期: 敌人应侦测玩家并追击攻击
			if t >= 15.5 and stage == 6 and has_meta("ai_e"):
				stage = 7
				var e = get_meta("ai_e")
				if player_valid():
					var p = get_tree().get_first_node_in_group("player")
					p.is_choosing_upgrade = false  # 恢复自动施法
				if player_valid() and is_instance_valid(e):
					var p = get_tree().get_first_node_in_group("player")
					var moved = e.global_position.distance_to(get_meta("ai_pos"))
					var hp_drop = get_meta("ai_hp") - p.stats.current_health
					print("[TEST] S6 t=%.1f AI结果 → 敌移动=%.0fpx 玩家掉血=%.1f target=%s 暂停=%s" % [t, moved, hp_drop, str(e.target != null), str(get_tree().paused)])
					if get_tree().paused:
						print("[TEST] S6 警告: 观察期间处于暂停,结果无效")
					else:
						if moved < 5.0:
							errors += 1
							print("[TEST] S6 错误: 敌人未追击")
						if hp_drop < 1.0:
							print("[TEST] S6 警告: 2.5秒内未攻击到玩家(可能距离远)")
				else:
					print("[TEST] S6 敌人或玩家已死亡(战斗中属正常)")
		7:
			if t >= 16.0:
				stage = 8
				if player_valid():
					var p = get_tree().get_first_node_in_group("player")
					var bolt0 = p.spell_caster.spell_slots[0]
					if bolt0:
						var before = bolt0.damage
						p._apply_upgrade({"id": "damage", "name": "测试", "desc": "测试", "level": 1})
						if bolt0.damage > before:
							print("[TEST] S7 t=%.1f 强化应用 %.1f→%.1f 通过" % [t, before, bolt0.damage])
						else:
							errors += 1
							print("[TEST] S7 错误: 强化未生效")
				print("[TEST] S7 统计 → 击杀=%d 金币=%d 波次=%d 存活敌=%d" % [GameManager.kill_count, GameManager.total_gold, WaveManager.current_wave, WaveManager.enemies_alive])
				if GameManager.kill_count == 0:
					errors += 1
					print("[TEST] S7 错误: 零击杀")
		8:
			if t >= 16.5:
				stage = 9
				SaveManager.auto_save()
				if SaveManager.has_save(0):
					print("[TEST] S8 t=%.1f 存档通过" % t)
				else:
					errors += 1
		9:
			if t >= 17.0:
				stage = 10
				if errors == 0:
					print("[TEST] === 全部通过 ===")
				else:
					print("[TEST] === 完成: %d个错误 ===" % errors)
				get_tree().quit()
	
	if t > 40.0 and stage < 10:
		print("[TEST] 超时退出 stage=%d" % stage)
		get_tree().quit()
