## probe_boss_logic.gd - Boss 战诊断探针·逻辑节点（开发工具）
## 静态无敌玩家快速推进到 Boss 波，观察 Boss 追击/受击/击杀时间线。
## 日志写入绝对路径文件并逐行 flush（规避 headless 管道缓冲）。
extends Node

const LOG_PATH := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/probe_boss.log"

var t := 0.0
var wipe_timer := 0.0
var log_timer := 0.0
var boss: Node2D = null
var boss_seen_at := -1.0
var stage := 0
var _shop_wait := -1.0
var _last_heartbeat := 0.0
var _log: FileAccess = null

func _log_line(msg: String) -> void:
	if _log == null or not _log.is_open():
		_log = FileAccess.open(LOG_PATH, FileAccess.WRITE)
		if _log == null:
			return
	_log.seek_end()
	_log.store_line(msg)
	_log.flush()
	print(msg)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute("C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots")
	_log_line("[PROBE] 启动 t=0")

func _process(delta: float) -> void:
	t += delta
	match stage:
		0:
			if t >= 0.3:
				stage = 1
				GameManager.start_new_game("fire_mage", "forest")
				GameManager.toggle_game_speed()
				GameManager.toggle_game_speed()
				get_tree().change_scene_to_file("res://scenes/main/game.tscn")
				_log_line("[PROBE] 场景已切换")
		1:
			var p = get_tree().get_first_node_in_group("player")
			if p == null or not is_instance_valid(p):
				return
			p.is_invincible = true
			# 心跳：证明主循环仍在跑
			if t - _last_heartbeat >= 5.0:
				_last_heartbeat = t
				_log_line("[PROBE] 心跳 t=%.0f 波次=%d state=%d paused=%s" % [
					t, WaveManager.current_wave, WaveManager.wave_state, str(get_tree().paused)])
			# 自动处理升级面板（延迟关店，避免同帧开/关的未定义时序）
			var panel = get_tree().current_scene.get_node_or_null("UI/UpgradePanel")
			if panel and panel.visible:
				panel._on_option_selected(0)
			var shop = get_tree().current_scene.get_node_or_null("UI/Shop")
			if shop and shop.visible:
				if _shop_wait < 0.0:
					_shop_wait = t
				elif t - _shop_wait >= 1.0:
					_shop_wait = -1.0
					shop._on_close_pressed()
			else:
				_shop_wait = -1.0
			# 每2秒清一次非Boss怪，快速推波
			wipe_timer += delta
			if wipe_timer >= 2.0:
				wipe_timer = 0.0
				for e in get_tree().get_nodes_in_group("enemies"):
					if is_instance_valid(e) and e.is_alive and not e.is_boss:
						e.take_damage(99999.0)
			# 记录 Boss
			var bosses = get_tree().get_nodes_in_group("boss")
			if bosses.size() > 0 and (boss == null or not is_instance_valid(boss)):
				boss = bosses[0]
				boss_seen_at = t
				_log_line("[PROBE] Boss 出现 t=%.1f 波次=%d hp=%.0f" % [t, WaveManager.current_wave, boss.max_health])
			if boss != null and is_instance_valid(boss):
				if boss.is_alive:
					log_timer += delta
					if log_timer >= 4.0:
						log_timer = 0.0
						var p2 = get_tree().get_first_node_in_group("player")
						var d: float = boss.global_position.distance_to(p2.global_position) if p2 else -1.0
						_log_line("[PROBE] t=%.1f boss_hp=%.0f/%.0f dist=%.0f charge=%s tele=%s alive=%d kills=%d wave=%d state=%d" % [
							t, boss.current_health, boss.max_health, d,
							str(boss._boss_charging), str(boss._boss_telegraphing),
							get_tree().get_nodes_in_group("enemies").size(), GameManager.kill_count,
							WaveManager.current_wave, WaveManager.wave_state])
				else:
					_log_line("[PROBE] Boss 被击杀! 用时=%.1f（自出现）" % (t - boss_seen_at))
					boss = null
					stage = 2
			if t > 130.0:
				_log_line("[PROBE] 超时结束（Boss 未被击杀）")
				stage = 2
		2:
			# 收尾：等 2 秒让结算稳定后退出
			await get_tree().create_timer(2.0).timeout
			_log_line("[PROBE] 退出")
			get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
