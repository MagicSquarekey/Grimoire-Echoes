## auto_feature_driver.gd - 自动化测试驱动逻辑（挂在 /root 下，跨场景存活）
extends Node

var fails: Array = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if cond:
		print("  ✓ %s" % label)
	else:
		fails.append(label)
		print("  ✗ %s" % label)

func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

## 等待物理引擎消化碰撞事件（headless 下进程帧率远高于物理帧率，帧数等待不可靠）
func _wait_phys(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

## 清场：秒杀所有存活敌人（加速波次推进）
func _nuke_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.take_damage(999999.0)

func _press_escape() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_ESCAPE
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventKey.new()
	ev2.physical_keycode = KEY_ESCAPE
	ev2.pressed = false
	Input.parse_input_event(ev2)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()

func _run() -> void:
	print("=== 新功能引擎内自动化测试 ===")
	# 兜底看门狗：3 分钟未结束强制退出
	get_tree().create_timer(180.0).timeout.connect(func():
		print("✗ 看门狗超时，强制退出")
		get_tree().quit(2))

	# ---------- Stage 1: 标准模式启动 ----------
	print("[Stage 1] 标准模式启动")
	GameManager.game_mode = "normal"
	GameManager.start_new_game("fire_mage", "forest")
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")
	await _wait_frames(40)

	var game := get_tree().current_scene
	check(game != null and game.name == "Game", "游戏场景已加载")
	if game == null:
		return _finish()
	var pause_menu = game.get_node_or_null("UI/PauseMenu")
	var upanel = game.get_node_or_null("UI/UpgradePanel")
	var shop = game.get_node_or_null("UI/Shop")
	check(pause_menu != null, "暂停菜单节点存在")
	check(upanel != null, "升级面板节点存在")
	if pause_menu == null or upanel == null:
		return _finish()

	# ---------- Stage 2: ESC 暂停开关（核心修复验证） ----------
	print("[Stage 2] ESC 暂停开关")
	_press_escape()
	await _wait_frames(8)
	check(pause_menu.visible, "ESC 打开暂停菜单")
	check(get_tree().paused, "游戏已暂停")
	_press_escape()
	await _wait_frames(8)
	check(not pause_menu.visible, "再按 ESC 关闭暂停菜单")
	check(not get_tree().paused, "游戏恢复运行")

	# ---------- Stage 3: 升级面板 + 重投 ----------
	print("[Stage 3] 升级重投")
	var player = get_tree().get_first_node_in_group("player")
	check(player != null, "玩家存在")
	if player == null:
		return _finish()
	var stats = player.get_node("PlayerStats")
	stats.add_exp(stats.get_required_exp())
	await _wait_frames(15)
	check(upanel.visible, "升级面板自动弹出")
	check(player.is_choosing_upgrade, "选择期间锁定状态")
	var gold0: int = GameManager.total_gold
	var btn = upanel.get_node_or_null("Panel/MarginContainer/VBoxContainer/RerollButton")
	check(btn != null, "重投按钮存在")
	if btn:
		check(not btn.disabled, "重投按钮可用（金币 %d ≥ 20）" % gold0)
		var opts_before := str(upanel.current_options)
		btn.pressed.emit()
		await _wait_frames(8)
		check(GameManager.total_gold == gold0 - 20, "重投扣除 20 金币（%d → %d）" % [gold0, GameManager.total_gold])
		check("40" in btn.text, "重投价格翻倍为 40")
		check(btn.disabled, "金币不足 40 时按钮置灰")
		check(not str(upanel.current_options).is_empty(), "重投后选项已重建")
	upanel._on_option_selected(0)
	await _wait_frames(8)
	check(not upanel.visible, "选择后面板关闭")
	check(not get_tree().paused, "选择后恢复运行")

	# ---------- Stage 4: 推进到第 3 波验证宝箱事件 ----------
	print("[Stage 4] 宝箱事件波")
	GameManager.game_speed = 3.0
	var deadline := Time.get_ticks_msec() + 120000
	var esc_shop_tested := false
	while WaveManager.current_wave < 3 and Time.get_ticks_msec() < deadline:
		await _wait_frames(20)
		# 等待期间：升级面板自动选第一项
		if upanel.visible:
			upanel._on_option_selected(0)
			await _wait_frames(5)
			continue
		# 等待期间：商店弹出 → 用 ESC 关闭（验证商店 ESC 路由）
		if shop and shop.visible:
			_press_escape()
			await _wait_frames(8)
			if not esc_shop_tested:
				esc_shop_tested = true
				check(not shop.visible, "ESC 关闭波间商店")
			continue
		# 主动清场加速波次推进（headless 下自动输出击杀很慢）
		_nuke_enemies()
	GameManager.game_speed = 1.0
	check(WaveManager.current_wave >= 3, "推进到第 3 波（实际 %d）" % WaveManager.current_wave)
	check(WaveManager.current_plan.get("event", "") == "treasure", "第 3 波计划为宝箱事件")
	var chest = game.get_node_or_null("GameController/TreasureChest")
	check(chest != null, "稀有宝箱已生成在场")
	if chest:
		var g0: int = GameManager.total_gold
		player.global_position = chest.global_position
		await _wait_phys(0.6)
		check(GameManager.total_gold >= g0 + 60, "触碰宝箱 +60 金币（%d → %d）" % [g0, GameManager.total_gold])
		check(not is_instance_valid(chest) or chest._opened, "宝箱开启后消失")

	# ---------- Stage 5: 诅咒祭坛 ----------
	print("[Stage 5] 诅咒祭坛")
	stats.heal(9999.0)  # 回满血：祭坛在生命过低时会拒绝契约（设计行为）
	var altar = load("res://scenes/events/cursed_altar.tscn").instantiate()
	game.add_child(altar)
	altar.global_position = player.global_position + Vector2(60, 0)
	await _wait_frames(5)
	var sc = player.get_node_or_null("SpellCaster")
	var dmg0 := -1.0
	if sc:
		for spell in sc.spell_slots:
			if spell:
				dmg0 = spell.damage
				break
	var hp0: float = stats.current_health
	player.global_position = altar.global_position
	await _wait_phys(0.6)
	var dmg1 := -1.0
	if sc:
		for spell in sc.spell_slots:
			if spell:
				dmg1 = spell.damage
				break
	check(stats.current_health < hp0, "祭坛契约扣血（%.0f → %.0f）" % [hp0, stats.current_health])
	check(dmg0 > 0 and dmg1 > dmg0 * 1.25, "法术伤害 +30%%（%.1f → %.1f）" % [dmg0, dmg1])
	if is_instance_valid(altar):
		altar.queue_free()

	# ---------- Stage 6: 悬赏标记 ----------
	print("[Stage 6] 悬赏精英")
	var spawner = game.get_node_or_null("GameController/EnemySpawner")
	check(spawner != null, "刷怪器存在")
	if spawner:
		var bounty_plan := {"events": [{"type": "shadow_servant", "count": 6, "formation": "scatter"}], "elite_count": 0, "event": "bounty"}
		spawner.begin_wave(bounty_plan, 1.0)
		spawner.spawn_next_batch()
		await _wait_frames(10)
		var bounty_found := false
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.modulate == Color(1.0, 0.62, 0.15):
				bounty_found = true
		check(bounty_found, "悬赏精英已标记（橙金色）")
		# 清掉测试怪，避免干扰下一阶段
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e):
				e.take_damage(999999.0)
		await _wait_frames(10)

	# ---------- Stage 7: Boss 连战流程 ----------
	print("[Stage 7] Boss 连战")
	GameManager.game_mode = "boss_rush"
	GameManager.start_new_game("fire_mage", "forest")
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")
	await _wait_frames(40)
	check(EnemySpawner.boss_rush_mode, "连战模式同步给刷怪器")
	check(WaveManager.current_plan.get("is_boss", false), "连战第 1 战为 Boss 波")
	game = get_tree().current_scene
	# 重新获取新场景的 UI 引用（旧引用已随场景释放）
	upanel = game.get_node_or_null("UI/UpgradePanel")
	shop = game.get_node_or_null("UI/Shop")
	var player2 = get_tree().get_first_node_in_group("player")
	var deadline2 := Time.get_ticks_msec() + 60000
	var last_diag := 0
	while get_tree().get_nodes_in_group("boss").is_empty() and Time.get_ticks_msec() < deadline2:
		await _wait_frames(20)
		if upanel and is_instance_valid(upanel) and upanel.visible:
			upanel._on_option_selected(0)
			await _wait_frames(5)
		if shop and is_instance_valid(shop) and shop.visible:
			shop.close_shop()
			await _wait_frames(5)
		if Time.get_ticks_msec() - last_diag > 4000:
			last_diag = Time.get_ticks_msec()
			print("    [diag] wave=%s state=%s to_spawn=%s alive=%s paused=%s gstate=%s speed=%.1f" % [
				WaveManager.current_wave, WaveManager.wave_state, WaveManager.enemies_to_spawn,
				WaveManager.enemies_alive, get_tree().paused, GameManager.current_state, GameManager.game_speed])
	check(not get_tree().get_nodes_in_group("boss").is_empty(), "连战 Boss 已生成")
	var banner = game.get_node_or_null("UI/WaveBanner/CenterLabel")
	if banner:
		check("连战" in banner.text, "横幅显示连战文案（%s）" % banner.text)

	_finish()

func _finish() -> void:
	print("===============================")
	if fails.is_empty():
		print("全部通过：%d 项检查 ✓" % checks)
		get_tree().quit(0)
	else:
		print("失败 %d/%d 项：" % [fails.size(), checks])
		for f in fails:
			print("  - " + f)
		get_tree().quit(1)
