## UserSimBot - 真实用户模拟机器人
## 模拟真人玩家的完整行为闭环：
##   - WASD 走位：倾向宝石（价值/距离评分），敌人近身时逃离（会死，不开无敌）
##   - 升级面板弹出时自动选择（优先 新法术 > 法术强化 > 数值强化）
##   - 商店出现时买第一件买得起的商品，买不起则离开（跳过）开下一波
## 以 3 倍速跑 8 分钟游戏时间（或死亡提前结束），输出结构化战报。
extends Node

## 目标游戏时长（游戏内秒）
var target_game_time := 480.0
## 随机种子（USIM_SEED 环境变量可覆盖）
var seed_value := -1

var t := 0.0
var stage := 0  # 0=启动 1=游戏中 2=收尾退出

# ---- 数据记录 ----
var wave_reached := 0
var waves_cleared := 0
var death_game_time := -1.0
var level_reached := 1
var kills_final := 0
var gold_peak := 0
var gold_spent := 0
var shop_buys := 0
var upgrades_taken := 0
var potions_drunk := 0
var magnets_used := 0
var hp_min_sampled := 99999.0
var _wave_log: Array = []          # "1@12.3" 波次@游戏时间
var _status_timer := 0.0
var _shop_cooldown := 0.0
var _waypoint := Vector2(960, 540)
var _waypoint_timer := 0.0
var _quit_timer := -1.0
var _dbg := false
var _dbg_timer := 0.0

## 升级选择优先级（索引越小越优先）
const PRIORITY := ["new_spell", "spell_power", "damage", "haste", "health", "multishot", "magnet", "speed"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var env_seed := OS.get_environment("USIM_SEED")
	if env_seed != "":
		seed_value = int(env_seed)
	var env_min := OS.get_environment("USIM_MINUTES")
	if env_min != "":
		target_game_time = float(env_min) * 60.0
	_dbg = OS.get_environment("USIM_DEBUG") == "1"
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.game_over.connect(_on_game_over)
	EventBus.pickup_collected.connect(_on_pickup_collected)
	print("[USIM] === 真实用户模拟启动 seed=%d 时长=%.0fs ===" % [seed_value, target_game_time])

func _process(delta: float) -> void:
	t += delta
	# 收尾退出倒计时（等死亡画面/结算稳定一瞬）
	if _quit_timer > 0.0:
		_quit_timer -= delta
		if _quit_timer <= 0.0:
			_finish()
		return

	match stage:
		0:
			if t >= 0.3:
				stage = 1
				if seed_value >= 0:
					seed(seed_value)
				else:
					randomize()
				GameManager.start_new_game("fire_mage", "forest")
				GameManager.toggle_game_speed()  # 2x
				GameManager.toggle_game_speed()  # 3x
				get_tree().change_scene_to_file("res://scenes/main/game.tscn")
				print("[USIM] 新游戏启动 3倍速")
		1:
			_tick_play(delta)
		2:
			pass

func _tick_play(delta: float) -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p == null or not is_instance_valid(p):
		return

	level_reached = maxi(level_reached, p.stats.current_level)
	gold_peak = maxi(gold_peak, GameManager.total_gold)
	hp_min_sampled = minf(hp_min_sampled, p.stats.current_health)

	# UI 交互（暂停状态下也能点）
	_handle_upgrade_panel()
	_shop_cooldown -= delta
	_handle_shop()

	# 走位（暂停时松开全部按键）
	if get_tree().paused or p.is_choosing_upgrade:
		_apply_input(Vector2.ZERO)
	else:
		var dir := _compute_move_dir(p)
		_apply_input(dir)

	# 周期战报（每 60 游戏秒）
	_status_timer += delta * GameManager.game_speed
	if _status_timer >= 60.0:
		_status_timer = 0.0
		print("[USIM] t=%s 波次=%d 击杀=%d 金币=%d 生命=%.0f/%.0f 等级=%d" % [
			GameManager.get_formatted_play_time(), WaveManager.current_wave,
			GameManager.kill_count, GameManager.total_gold,
			p.stats.current_health, p.stats.get_max_health(), p.stats.current_level])

	# Boss 阶段细粒度诊断（USIM_DEBUG=1 时开启，每 5 游戏秒）
	if _dbg and WaveManager.current_plan.get("is_boss", false) and WaveManager.wave_state == WaveManager.BOSS_FIGHT:
		_dbg_timer += delta * GameManager.game_speed
		if _dbg_timer >= 5.0:
			_dbg_timer = 0.0
			var boss = get_tree().get_first_node_in_group("boss")
			var enemies = get_tree().get_nodes_in_group("enemies")
			var nd := -1.0
			var ne := 0
			for e in enemies:
				if is_instance_valid(e) and e.get("is_alive"):
					ne += 1
					var d: float = e.global_position.distance_to(p.global_position)
					if nd < 0.0 or d < nd:
						nd = d
			var bd := -1.0
			var bhp := -1.0
			if boss != null and is_instance_valid(boss):
				bd = boss.global_position.distance_to(p.global_position)
				bhp = boss.current_health
			print("[USIM][DBG] t=%.0f boss_hp=%.0f boss_dist=%.0f nearest=%.0f alive=%d pos=(%.0f,%.0f) vel=%.0f" % [
				GameManager.play_time, bhp, bd, nd, ne,
				p.global_position.x, p.global_position.y, p.velocity.length()])

	# 时长到 → 存活通关
	if GameManager.play_time >= target_game_time:
		death_game_time = -1.0
		print("[USIM] 存活 %.0f 游戏秒，模拟结束" % target_game_time)
		_quit_timer = 0.5
		stage = 2

## ---------- 升级面板 ----------
func _handle_upgrade_panel() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p == null or not is_instance_valid(p):
		return
	var panel = get_tree().current_scene.get_node_or_null("UI/UpgradePanel")
	if panel == null or not panel.visible:
		return
	var options: Array = panel.get("current_options")
	if options == null or options.is_empty():
		return
	var best := 0
	var best_rank := 999
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var oid := str(opt.get("id", ""))
		var rank := PRIORITY.find(oid)
		if rank == -1:
			rank = 900 + i
		# 同优先级时：法术强化优先挑还没强化的（id 相同随便，简单取第一个更优）
		if rank < best_rank:
			best_rank = rank
			best = i
	upgrades_taken += 1
	panel._on_option_selected(best)

## ---------- 商店 ----------
func _handle_shop() -> void:
	if _shop_cooldown > 0.0:
		return
	var shop = get_tree().current_scene.get_node_or_null("UI/Shop")
	if shop == null or not shop.visible:
		return
	# 买第一件买得起的（价格递增曲线用 shop._item_price 计算）
	for item in shop.shop_items:
		var price: int = shop._item_price(item)
		if GameManager.total_gold >= price:
			shop._on_item_pressed(item)
			shop_buys += 1
			gold_spent += price
			_shop_cooldown = 0.5  # 等商品列表刷新
			print("[USIM] 商店购买 %s (-%d金币)" % [item["name"], price])
			return
	# 买不起任何商品 → 离开商店，立即开下一波
	shop._on_close_pressed()
	_shop_cooldown = 0.5

## ---------- 走位 AI ----------
func _compute_move_dir(p) -> Vector2:
	var pos: Vector2 = p.global_position
	var nearest_d := INF
	var nearest_e: Node2D = null
	var flee := Vector2.ZERO
	var alive := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.get("is_alive"):
			continue
		alive += 1
		var away: Vector2 = pos - e.global_position
		var dist := away.length()
		if dist < 0.01:
			away = Vector2.RIGHT
			dist = 0.01
		if dist < nearest_d:
			nearest_d = dist
			nearest_e = e
		if dist < 230.0:
			flee += away / dist * (1.0 - dist / 230.0)

	# 宝石目标评分：价值 / (距离+常数)
	var goal := Vector2.ZERO
	var best_score := 0.0
	for g in get_tree().get_nodes_in_group("pickups"):
		if not is_instance_valid(g):
			continue
		var to_gem: Vector2 = g.global_position - pos
		var dist := maxf(to_gem.length(), 20.0)
		var score: float = float(g.pickup_value) / (40.0 + dist)
		if score > best_score:
			best_score = score
			goal = to_gem / dist

	var dir := Vector2.ZERO
	var nothing_to_collect := best_score < 0.001
	var boss_e = get_tree().get_first_node_in_group("boss")
	if nearest_d < 120.0:
		# 敌人贴脸：纯逃离
		dir = flee
	elif boss_e != null and is_instance_valid(boss_e):
		# Boss 存活：真人会优先打 Boss——保持在 Boss 周边的输出距离带，
		# 小怪追进来会被顺带清掉
		var anchor: Node2D = boss_e
		var to_e: Vector2 = anchor.global_position - pos
		var d := maxf(to_e.length(), 1.0)
		var band_dir := to_e / d
		if d > 320.0:
			dir = band_dir
		elif d < 180.0:
			dir = -band_dir * 0.7
		else:
			dir = band_dir.orthogonal() * 0.3
	elif nothing_to_collect and alive <= 4 and nearest_e != null:
		# 残局收尾：没宝石可捡且剩余敌人不多时，保持在施法距离带内输出
		var to_enemy: Vector2 = nearest_e.global_position - pos
		var band_dir := to_enemy / maxf(nearest_d, 1.0)
		if nearest_d > 420.0:
			dir = band_dir          # 太远：贴上去
		elif nearest_d < 260.0:
			dir = -band_dir * 0.7   # 太近：缓退
		else:
			dir = band_dir.orthogonal() * 0.3  # 舒适区：绕行拉扯
	else:
		dir = flee * 1.2 + goal

	if dir.length_squared() < 0.02:
		# 无威胁无宝石：朝游走航点移动
		_waypoint_timer -= get_process_delta_time()
		if _waypoint_timer <= 0.0 or pos.distance_to(_waypoint) < 60.0:
			_waypoint_timer = randf_range(2.0, 4.0)
			_waypoint = pos + Vector2(randf_range(-420, 420), randf_range(-420, 420))
		dir = _waypoint - pos
	return dir.normalized()

func _apply_input(dir: Vector2) -> void:
	var press := {
		"move_up": dir.y < -0.35,
		"move_down": dir.y > 0.35,
		"move_left": dir.x < -0.35,
		"move_right": dir.x > 0.35,
	}
	for action in press:
		if press[action]:
			Input.action_press(action)
		else:
			Input.action_release(action)

## ---------- 数据采集 ----------
func _on_wave_started(wave: int) -> void:
	wave_reached = maxi(wave_reached, wave)
	_wave_log.append("%d@%.0f" % [wave, GameManager.play_time])

func _on_wave_completed(wave: int) -> void:
	waves_cleared = maxi(waves_cleared, wave)

func _on_pickup_collected(pickup_type: String, _value) -> void:
	if pickup_type == "health_potion":
		potions_drunk += 1
	elif pickup_type == "magnet":
		magnets_used += 1

func _on_game_over(_stats: Dictionary) -> void:
	if stage != 1:
		return
	death_game_time = GameManager.play_time
	print("[USIM] 玩家死亡，游戏时间 %s" % GameManager.get_formatted_play_time())
	_apply_input(Vector2.ZERO)
	_quit_timer = 1.0
	stage = 2

## ---------- 战报 ----------
func _finish() -> void:
	if stage == 3:
		return
	stage = 3
	kills_final = GameManager.kill_count
	var p = get_tree().get_first_node_in_group("player")
	var weapons: Array = []
	if p and is_instance_valid(p):
		for spell in p.spell_caster.spell_slots:
			if spell:
				weapons.append("%s(Lv%d)" % [spell.spell_name, spell.spell_level])
	var result := "died" if death_game_time >= 0.0 else "survived"
	print("[USIM] === RUN RESULT ===")
	print("[USIM] seed=%d" % seed_value)
	print("[USIM] result=%s" % result)
	print("[USIM] wave_reached=%d waves_cleared=%d death_time=%.1f level=%d" % [
		wave_reached, waves_cleared, death_game_time, level_reached])
	print("[USIM] kills=%d gold_peak=%d gold_spent=%d shop_buys=%d upgrades=%d" % [
		kills_final, gold_peak, gold_spent, shop_buys, upgrades_taken])
	print("[USIM] potions=%d magnets=%d hp_min=%.0f" % [potions_drunk, magnets_used, hp_min_sampled])
	print("[USIM] weapons=%s" % "、".join(weapons))
	print("[USIM] wave_log=%s" % ",".join(_wave_log))
	get_tree().quit(0)
