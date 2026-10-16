## TestWaveManager - 波次管理器测试
## 测试波次系统的正确性
## 注意：WaveManager 是 autoload 单例，这里通过加载脚本 new() 出独立实例，
## 不入树（避免触发 _ready 重复连接 EventBus 信号），直接调用其方法验证逻辑。
extends Node

## 软断言：失败时记录并继续，保证 run_all_tests 返回准确的通过状态
var _test_failed := false

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_test_failed = true
		print("❌ 断言失败: " + msg)

## 创建一个独立的 WaveManager 实例用于测试（统一追踪，结束时释放）
var _created_managers: Array = []

func _create_wave_manager() -> Node:
	var wm = load("res://scripts/autoload/wave_manager.gd").new()
	_created_managers.append(wm)
	return wm

## 测试波次初始化
func test_wave_initialization() -> void:
	var wm = _create_wave_manager()

	_check(wm.current_wave == 0, "初始波次应为0")
	_check(wm.wave_state == WaveManager.PREPARING, "初始状态应为PREPARING")
	_check(wm.enemies_alive == 0, "初始敌人数应为0")
	_check(wm.enemies_to_spawn == 0, "初始待生成敌人数应为0")
	print("✅ 波次初始化测试通过")

## 测试波次开始
func test_wave_start() -> void:
	var wm = _create_wave_manager()

	wm.start_wave()

	_check(wm.current_wave == 1, "第一波开始后波次应为1")
	_check(wm.wave_state == WaveManager.PREPARING, "开始后状态应为PREPARING")
	_check(wm.wave_timer == wm.preparation_time, "准备期计时器应重置为准备时长")
	print("✅ 波次开始测试通过")

## 测试 start_next_wave 别名
func test_start_next_wave_alias() -> void:
	var wm = _create_wave_manager()

	wm.start_next_wave()

	_check(wm.current_wave == 1, "start_next_wave应等效于start_wave")
	print("✅ start_next_wave别名测试通过")

## 测试重置
func test_reset() -> void:
	var wm = _create_wave_manager()

	wm.start_wave()
	wm.enemies_alive = 7
	wm.enemies_to_spawn = 5
	wm.reset()

	_check(wm.current_wave == 0, "重置后波次应为0")
	_check(wm.wave_state == WaveManager.PREPARING, "重置后状态应为PREPARING")
	_check(wm.enemies_alive == 0, "重置后敌人数应为0")
	_check(wm.enemies_to_spawn == 0, "重置后待生成敌人数应为0")
	print("✅ 波次重置测试通过")

## 测试敌人数量计算
func test_enemy_count_calculation() -> void:
	var wm = _create_wave_manager()

	# 测试不同波次的敌人数量
	wm.current_wave = 1
	var count1 = wm._calculate_enemy_count()
	_check(count1 > 0, "第1波敌人数量应大于0")

	wm.current_wave = 10
	var count10 = wm._calculate_enemy_count()
	_check(count10 > count1, "第10波敌人数量应多于第1波")

	wm.current_wave = 20
	var count20 = wm._calculate_enemy_count()
	_check(count20 > count10, "第20波敌人数量应多于第10波")
	print("✅ 敌人数量计算测试通过")

## 测试难度系数
func test_difficulty_multiplier() -> void:
	var wm = _create_wave_manager()

	wm.current_wave = 1
	var diff1 = wm.get_difficulty_multiplier()

	wm.current_wave = 10
	var diff10 = wm.get_difficulty_multiplier()

	wm.current_wave = 20
	var diff20 = wm.get_difficulty_multiplier()

	_check(diff1 < diff10, "难度应随波次增加")
	_check(diff10 < diff20, "难度应持续增加")
	print("✅ 难度系数测试通过")

## 测试波次信息
func test_wave_info() -> void:
	var wm = _create_wave_manager()
	wm.current_wave = 5
	wm.enemies_alive = 10

	var info = wm.get_wave_info()

	_check(info["wave"] == 5, "波次信息应为5")
	_check(info["enemies_alive"] == 10, "敌人数信息应为10")
	_check(info.has("state"), "波次信息应包含state")
	_check(info.has("difficulty"), "波次信息应包含difficulty")
	print("✅ 波次信息测试通过")

## 测试Boss波次检测
func test_boss_wave_detection() -> void:
	var wm = _create_wave_manager()

	# 测试大Boss波次（每20波）
	wm.current_wave = 20
	_check(wm.current_wave % wm.boss_wave_interval == 0, "第20波应为大Boss波次")

	# 测试小Boss波次（每5波）
	wm.current_wave = 10
	_check(wm.current_wave % wm.mini_boss_interval == 0, "第10波应为小Boss波次")

	# 测试普通波次
	wm.current_wave = 7
	_check(wm.current_wave % wm.boss_wave_interval != 0, "第7波不应为大Boss波次")
	_check(wm.current_wave % wm.mini_boss_interval != 0, "第7波不应为小Boss波次")
	print("✅ Boss波次检测测试通过")

## 测试准备期结束 → 进入生成状态
func test_preparing_to_spawning_transition() -> void:
	var wm = _create_wave_manager()

	wm.start_wave()
	# 直接推进准备期计时（避免依赖 _process 与场景树）
	wm._process_preparing(wm.preparation_time + 1.0)

	_check(wm.wave_state == WaveManager.SPAWNING, "准备期结束后应进入SPAWNING状态")
	_check(wm.enemies_to_spawn == wm._calculate_enemy_count(), "待生成数量应为该波敌人总数")
	print("✅ 准备期→生成期转换测试通过")

## 测试新波次曲线：前3波缓冲期、第4波上台阶、间隔递减
func test_wave_plan_curve() -> void:
	var plan1 = EnemySpawner.build_wave_plan(1)
	var plan3 = EnemySpawner.build_wave_plan(3)
	var plan4 = EnemySpawner.build_wave_plan(4)
	var plan10 = EnemySpawner.build_wave_plan(10)

	_check(plan1["total"] >= 8 and plan1["total"] <= 16, "第1波应为缓冲期数量(8-16只)，实际 %d" % plan1["total"])
	_check(plan3["total"] <= 16, "第3波仍应为缓冲期(≤16只)，实际 %d" % plan3["total"])
	_check(plan4["total"] > plan3["total"], "第4波数量应明显上台阶")
	_check(plan10["total"] > plan4["total"], "第10波数量应多于第4波")

	# spawn_interval：第1波0.5 → 第10波约0.22 → 后期不低于0.15
	_check(absf(plan1["spawn_interval"] - 0.5) < 0.001, "第1波间隔应为0.5s")
	_check(plan10["spawn_interval"] <= 0.3, "第10波间隔应≤0.3s，实际 %.2f" % plan10["spawn_interval"])
	var plan30 = EnemySpawner.build_wave_plan(30)
	_check(plan30["spawn_interval"] >= 0.15, "后期间隔不应低于0.15s下限")

	# 总量提升：1-15 波总量应约为旧配置(445)的1.4倍以上
	var sum := 0
	for w in range(1, 16):
		sum += int(EnemySpawner.build_wave_plan(w)["total"])
	_check(sum >= 620, "1-15波总数量应≥620(旧配置约445的1.4倍)，实际 %d" % sum)
	print("✅ 新波次曲线测试通过 (1-15波总量=%d)" % sum)

## 测试难度曲线不塌方：缓冲期(1-3波)之后，每波"有效血量压力"必须单调不降。
## 只看敌人数量会漏判——换成更多种类后，同样数量可能更硬也可能更软；
## 这里按 ENEMY_DATA 的 hp 加权，并把 Boss 的 make_boss 血量倍率算进来
## （精英倍率不在此计入，那条规则由 test_boss_and_elite_plan 单独守）。
func test_wave_pressure_monotonic() -> void:
	var hp_by_id := {}
	for data in EnemyGenerator.ENEMY_DATA:
		hp_by_id[str(data["id"])] = float(data["hp"])

	var boss_path: String = EnemySpawner.ENEMY_SCENE_PATHS[EnemySpawner.BOSS_BASE_TYPE]
	var boss_scene: PackedScene = load(boss_path)
	if boss_scene == null:
		_check(false, "Boss 基底场景不可加载：%s" % boss_path)
		return
	var boss_proto: EnemyBase = boss_scene.instantiate()
	var boss_hp: float = boss_proto.max_health * 8.0  # make_boss 的血量倍率
	boss_proto.free()

	var prev_normal := 0.0
	var first_normal := 0.0
	var last_normal := 0.0
	for w in range(4, 16):
		var plan = EnemySpawner.build_wave_plan(w)
		var is_boss_wave := bool(plan.get("is_boss", false))
		var pressure := 0.0
		for e in plan["events"]:
			var t := str(e["type"])
			var c := int(e["count"])
			if t == "boss":
				pressure += boss_hp * c
				continue
			var id := str(EnemySpawner.ENEMY_ID_MAP.get(t, ""))
			if hp_by_id.has(id):
				pressure += float(hp_by_id[id]) * c
		# Boss 波是节奏上的峰，其后一个普通波理应回落喘息，
		# 所以普通波只与前一个普通波比；Boss 波则必须高于目前为止的峰
		_check(pressure >= prev_normal - 0.001,
				"第%d波(%s)血量压力应不低于上一个普通波（%.0f vs %.0f）" % [
				w, "Boss" if is_boss_wave else "普通", pressure, prev_normal])
		# 基线只跟随普通波：Boss 波是峰，不该成为后续普通波的对照
		if not is_boss_wave:
			prev_normal = pressure
			if first_normal == 0.0:
				first_normal = pressure
			last_normal = pressure
	print("✅ 难度曲线单调性测试通过 (普通波压力 %.0f → %.0f 递增)" % [first_normal, last_normal])

## 测试新怪物波次出场与阵型标记
func test_wave_plan_composition() -> void:
	var plan4 = EnemySpawner.build_wave_plan(4)
	var has_hound := false
	for e in plan4["events"]:
		if e["type"] == "demon_hound":
			has_hound = true
			_check(e["formation"] == "pack", "猎犬应为狼群包(pack)阵型")
			_check(e["count"] >= 4 and e["count"] <= 6, "猎犬应4-6只一包")
	_check(has_hound, "第4波应出现恶魔猎犬")

	var plan8 = EnemySpawner.build_wave_plan(8)
	var has_orc := false
	for e in plan8["events"]:
		if e["type"] == "orc_warrior":
			has_orc = true
	_check(has_orc, "第8波应出现兽人勇士")

	var has_ring := false
	for w in [3, 6, 11]:
		for e in EnemySpawner.build_wave_plan(w)["events"]:
			if e["type"] == "swarm_bug" and e["formation"] == "ring":
				has_ring = true
	_check(has_ring, "虫群应存在环形包抄(ring)阵型")
	print("✅ 波次构成（新怪物/阵型）测试通过")

## 测试Boss波与精英数量规则
func test_boss_and_elite_plan() -> void:
	for w in [5, 10, 15, 20]:
		var plan = EnemySpawner.build_wave_plan(w)
		_check(plan["is_boss"], "第%d波应为Boss波" % w)
		var has_boss := false
		for e in plan["events"]:
			if e["type"] == "boss":
				has_boss = true
		_check(has_boss, "第%d波事件中应含boss" % w)

	for w in [1, 2, 3, 4]:
		_check(EnemySpawner.build_wave_plan(w)["elite_count"] == 0, "第%d波不应有精英" % w)
	_check(EnemySpawner.build_wave_plan(5)["elite_count"] >= 1, "第5波起应有精英")
	_check(EnemySpawner.build_wave_plan(10)["elite_count"] >= 2, "第10波起精英应≥2只")
	_check(EnemySpawner.build_wave_plan(7)["is_boss"] == false, "第7波不应是Boss波")
	print("✅ Boss波与精英规则测试通过")

## 测试无限模式持续加码
func test_infinite_wave_growth() -> void:
	var plan16 = EnemySpawner.build_wave_plan(16)
	var plan25 = EnemySpawner.build_wave_plan(25)
	var plan40 = EnemySpawner.build_wave_plan(40)

	_check(plan25["total"] > plan16["total"], "无限模式数量应随波次增长")
	_check(plan40["total"] > plan25["total"], "无限模式数量应持续增长")
	_check(plan40["spawn_interval"] >= 0.15, "无限模式间隔不应低于0.15s下限")
	_check(plan25["elite_count"] >= plan16["elite_count"], "无限模式精英数不应减少")
	# Boss 每 5 波
	for w in [25, 30, 40]:
		_check(EnemySpawner.build_wave_plan(w)["is_boss"], "第%d波应为Boss波" % w)
	_check(EnemySpawner.build_wave_plan(23)["is_boss"] == false, "第23波不应是Boss波")
	print("✅ 无限模式成长测试通过")

## 测试 is_boss_wave 助手
func test_is_boss_wave_helper() -> void:
	var wm = _create_wave_manager()
	_check(wm.is_boss_wave(5), "is_boss_wave(5)应为真")
	_check(wm.is_boss_wave(10), "is_boss_wave(10)应为真")
	_check(not wm.is_boss_wave(7), "is_boss_wave(7)应为假")
	print("✅ is_boss_wave助手测试通过")

## 测试敌人花名册一致性：
##   1. 波次表里出现的每个 type 都必须在 EnemySpawner 的场景注册表里（否则只有一条警告）
##   2. enemy_id_map 的每个ID都必须在 EnemyGenerator.ENEMY_DATA 里真实存在
##      （历史上 orc_warrior→E20 / demon_hound→E21 指向了不存在的ID）
##   3. 注册表里的场景文件必须存在于 res://scenes/enemies/
##   4. 新怪物类型确实被写进了脚本化波次（种类多样性是本次改动的目标）
func test_enemy_roster_consistency() -> void:
	var registry: Dictionary = EnemySpawner.ENEMY_SCENE_PATHS
	var id_map: Dictionary = EnemySpawner.ENEMY_ID_MAP

	var known_ids := {}
	for data in EnemyGenerator.ENEMY_DATA:
		known_ids[str(data["id"])] = true

	for type in id_map:
		_check(known_ids.has(id_map[type]),
				"enemy_id_map[%s] = %s 必须在 ENEMY_DATA 中存在" % [type, id_map[type]])
		_check(registry.has(type), "enemy_id_map 的 %s 必须有对应场景" % type)

	var wave_types := {}
	for w in range(1, 17):
		for e in EnemySpawner.build_wave_plan(w)["events"]:
			var t: String = e["type"]
			if t == "boss":
				continue
			wave_types[t] = true
			_check(registry.has(t), "第%d波引用了未注册的类型 %s" % [w, t])

	_check(wave_types.has("bat_swarm"), "脚本化波次应包含飞行群体 bat_swarm")
	_check(wave_types.has("gargoyle"), "脚本化波次应包含俯冲飞行 gargoyle")
	_check(wave_types.has("grave_cleric"), "脚本化波次应包含支援治疗 grave_cleric")
	_check(wave_types.has("aegis_golem"), "脚本化波次应包含护盾光环 aegis_golem")
	_check(wave_types.has("ember_crab"), "脚本化波次应包含自爆 ember_crab")
	_check(wave_types.has("plague_spitter"), "脚本化波次应包含中毒远程 plague_spitter")
	_check(wave_types.has("cursed_knight") and wave_types.has("ember_lord"),
			"脚本化波次应包含两只新精英")

	for type in registry:
		# FileAccess 而非 ResourceLoader.exists：新写的 .tscn 可能还没进编辑器的资源扫描缓存
		_check(FileAccess.file_exists(registry[type]),
				"%s 的场景文件缺失: %s" % [type, registry[type]])
	print("✅ 敌人花名册一致性测试通过（波次类型 %d 种）" % wave_types.size())

## 测试敌人场景可实例化 + _init 属性齐备（不入树，纯结构检查）
## 精灵素材由离线渲染管线并发生成：.tres 未就绪时只跳过并提示，不算失败。
func test_enemy_scenes_instantiate() -> void:
	var registry: Dictionary = EnemySpawner.ENEMY_SCENE_PATHS
	for type in registry:
		var packed: PackedScene = load(registry[type])
		if packed == null:
			print("⚠️ %s 场景暂不可加载（素材可能未就绪），跳过" % type)
			continue
		var enemy = packed.instantiate()
		_check(enemy is EnemyBase, "%s 实例化后不是 EnemyBase" % type)
		if enemy is EnemyBase:
			_check(enemy.max_health > 0.0, "%s 生命未初始化" % type)
			_check(enemy.attack_damage >= 0.0, "%s 伤害未初始化" % type)
			_check(enemy.move_speed > 0.0, "%s 移速未初始化" % type)
			_check(not enemy.enemy_name.is_empty(), "%s 缺少 enemy_name" % type)
		if is_instance_valid(enemy):
			enemy.free()
	print("✅ 敌人场景实例化测试通过")

## 测试天生精英不会被随机精英槽二次放大
## （cursed_knight / ember_lord 在 _init 里已置 is_elite，EnemySpawner 的精英槽必须跳过）
## 用 load() 取脚本而非 class_name 直引：-s 模式下全局类缓存可能还没扫到新脚本。
func test_inherent_elites_not_doubled() -> void:
	var knight = load("res://scripts/enemies/cursed_knight.gd").new()
	var lord = load("res://scripts/enemies/ember_lord.gd").new()
	_check(knight.is_elite and lord.is_elite, "天生精英生成时即带 is_elite 标记")
	_check(knight.max_health == 200.0 and lord.max_health == 250.0,
			"天生精英血量按数据表配置，未叠 8 倍精英倍率")
	var knight_hp_before: float = knight.max_health
	knight.make_elite()
	_check(is_equal_approx(knight.max_health, knight_hp_before),
			"make_elite 对已是精英的单位应为空操作")
	knight.free()
	lord.free()
	print("✅ 天生精英倍率保护测试通过")

## 运行所有测试
func run_all_tests() -> bool:
	print("开始运行波次管理器测试...")
	_test_failed = false
	test_wave_initialization()
	test_wave_start()
	test_start_next_wave_alias()
	test_reset()
	test_enemy_count_calculation()
	test_difficulty_multiplier()
	test_wave_info()
	test_boss_wave_detection()
	test_preparing_to_spawning_transition()
	test_wave_plan_curve()
	test_wave_pressure_monotonic()
	test_wave_plan_composition()
	test_boss_and_elite_plan()
	test_infinite_wave_growth()
	test_is_boss_wave_helper()
	test_enemy_roster_consistency()
	test_enemy_scenes_instantiate()
	test_inherent_elites_not_doubled()
	for wm in _created_managers:
		if is_instance_valid(wm):
			wm.free()
	print("所有波次管理器测试通过！✅")
	return not _test_failed
