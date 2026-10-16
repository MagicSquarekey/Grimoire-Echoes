## monster_roster_test.gd - 全怪物阵容实机行为测试
## 运行：godot --headless --path . res://tests/monster_roster_test_scene.tscn
## 覆盖每种敌人的四件事：精灵帧契约完整（含正/背面朝向）、会真的朝玩家移动并播放跑动动画、
## 会在时限内产生它该有的效果（伤害/治疗/护盾）、能被击杀且不报错。
## 与 feature_test 的分工：feature_test 验证支援机制的细节，本测试验证"每种怪都活着"。
extends Node

const PLAYER_POS := Vector2(300, 0)
## 单只怪的行为时限（秒）：够慢速僵尸走完 300px 追击距离
const BEHAVIOR_BUDGET := 7.0
const REQUIRED_ANIMS := ["idle", "run", "idle_front", "run_front", "idle_back", "run_back"]

## expect: damage=打玩家 / heal=奶友军 / shield=给友军挂盾
const ROSTER := [
	{"key": "shadow_servant", "expect": "damage"},
	{"key": "skeleton_mage", "expect": "damage"},
	{"key": "swarm_bug", "expect": "damage"},
	{"key": "orc_warrior", "expect": "damage"},
	{"key": "demon_hound", "expect": "damage"},
	{"key": "gargoyle", "expect": "damage"},
	{"key": "bone_archer", "expect": "damage"},
	{"key": "shadow_assassin", "expect": "damage"},
	{"key": "plague_spitter", "expect": "damage"},
	{"key": "storm_wisp", "expect": "damage"},
	{"key": "ember_crab", "expect": "damage"},
	{"key": "bat_swarm", "expect": "damage"},
	{"key": "zombie_shambler", "expect": "damage"},
	{"key": "cursed_knight", "expect": "damage"},
	{"key": "ember_lord", "expect": "damage"},
	{"key": "grave_cleric", "expect": "heal"},
	{"key": "aegis_golem", "expect": "shield"},
	# Boss 基底场景：不加 make_boss 时它就是一个会飞会近战的普通个体，
	# 正好用来验证场景本身可用（动画/碰撞/追击/击杀）
	{"key": "dragon", "expect": "damage"},
]

var failures: Array = []
var checks := 0
var arena: Node2D
var mock


func check(cond: bool, label: String) -> void:
	checks += 1
	if cond:
		print("  ✓ %s" % label)
	else:
		failures.append(label)
		print("  ✗ %s" % label)


func _ready() -> void:
	print("=== 全怪物阵容实机行为测试 ===")
	arena = Node2D.new()
	arena.name = "Arena"
	add_child(arena)
	for entry in ROSTER:
		await _exercise(entry)
	print("===============================")
	if failures.is_empty():
		print("全部通过：%d 项检查 ✓" % checks)
		get_tree().quit(0)
	else:
		print("失败 %d/%d 项：" % [failures.size(), checks])
		for f in failures:
			print("  - %s" % f)
		get_tree().quit(1)


func _exercise(entry: Dictionary) -> void:
	var key: String = entry["key"]
	print("\n[%s]" % key)
	var packed: PackedScene = load("res://scenes/enemies/%s.tscn" % key)
	if packed == null:
		check(false, "%s 场景加载失败" % key)
		return
	var enemy: Node2D = packed.instantiate()
	arena.add_child(enemy)
	check(enemy is EnemyBase, "%s 继承 EnemyBase" % key)

	var body := enemy.get_node_or_null("Body") as AnimatedSprite2D
	if body == null:
		check(false, "%s 缺少 Body 动画节点" % key)
		_enemy_cleanup(enemy)
		return
	_check_frames(key, body)

	# 假玩家 + 一个受伤友军（支援型怪要用）
	mock = _MockPlayer.new()
	mock.global_position = PLAYER_POS
	arena.add_child(mock)
	var ally: Node2D = load("res://scenes/enemies/shadow_servant.tscn").instantiate()
	arena.add_child(ally)
	ally.global_position = enemy.global_position + Vector2(0, 20)
	ally.current_health = 10.0
	var ally_hp_before: float = ally.current_health

	var start_dist: float = enemy.global_position.distance_to(mock.global_position)
	var min_dist := start_dist
	var saw_run := false
	var elapsed := 0.0
	var effect := ""
	while elapsed < BEHAVIOR_BUDGET:
		await get_tree().physics_frame
		elapsed += 1.0 / 60.0
		min_dist = minf(min_dist, enemy.global_position.distance_to(mock.global_position))
		if body.animation in ["run", "run_front", "run_back"] and enemy.velocity.length() > 8.0:
			saw_run = true
		if not mock.hits.is_empty():
			effect = "damage"
		elif ally.shield_hp > 0.0:
			effect = "shield"
		elif ally.current_health > ally_hp_before:
			effect = "heal"
		if effect == str(entry["expect"]):
			break

	# 用"接近过的最近距离"而不是末态距离：刺客这类打了就跑的怪，
	# 采样瞬间可能正在后撤，末态距离会比初始值更大
	check(min_dist < start_dist - 15.0,
			"%s 朝玩家逼近（%.0f → 最近 %.0f）" % [key, start_dist, min_dist])
	check(saw_run, "%s 移动时切到跑动动画（当前 %s）" % [key, body.animation])
	check(effect == str(entry["expect"]),
			"%s 产生了应有效果（实际 %s，期望 %s）" % [key, effect if effect != "" else "无", entry["expect"]])

	enemy.take_damage(999999.0, null)
	var died := false
	for i in 60:
		await get_tree().physics_frame
		if not is_instance_valid(enemy) or enemy.current_health <= 0.0:
			died = true
			break
	check(died, "%s 可被击杀" % key)

	_enemy_cleanup(enemy)
	if is_instance_valid(ally):
		ally.free()
	if is_instance_valid(mock):
		mock.free()


## 精灵帧契约：六个朝向动画齐全，且每帧贴图真实存在
func _check_frames(key: String, body: AnimatedSprite2D) -> void:
	var frames := body.sprite_frames
	if frames == null:
		check(false, "%s 没有 sprite_frames" % key)
		return
	var missing: Array[String] = []
	for a in REQUIRED_ANIMS:
		if not frames.has_animation(a):
			missing.append(a)
	check(missing.is_empty(), "%s 六个朝向动画齐全（缺 %s）" % [key, ", ".join(missing)])
	var bad := 0
	for a in frames.get_animation_names():
		var n := frames.get_frame_count(a)
		if n == 0:
			bad += 1
			continue
		for i in n:
			var tex := frames.get_frame_texture(a, i)
			if tex == null or tex.get_width() <= 0:
				bad += 1
	check(bad == 0, "%s 全部帧贴图有效（异常 %d）" % [key, bad])
	_check_frames_animate(key, body)


## 冻结动画守卫：渲染管线出事故（丢蒙皮 / seek 不生效）时，同一动画的 8 帧会变成
## 同一张图。产物结构上完全正常——帧数对、贴图在、尺寸对——只有比像素才能发现，
## 而症状就是用户看到的"怪物移动时只是平移，没有动作"。
func _check_frames_animate(key: String, body: AnimatedSprite2D) -> void:
	var frames := body.sprite_frames
	if frames == null or not frames.has_animation("run") or frames.get_frame_count("run") < 5:
		return
	var t0 := frames.get_frame_texture("run", 0) as AtlasTexture
	var t4 := frames.get_frame_texture("run", 4) as AtlasTexture
	if t0 == null or t4 == null or t0.atlas == null:
		return
	var img := Image.load_from_file(ProjectSettings.globalize_path(t0.atlas.resource_path))
	if img == null:
		check(false, "%s 无法读取 run 图集做动画校验" % key)
		return
	var cell := Vector2i(int(t0.get_width()), int(t0.get_height()))
	var base0 := t0.region.position
	var base4 := t4.region.position
	var same := 0
	var total := 0
	for y in range(0, cell.y, 4):
		for x in range(0, cell.x, 4):
			var a := img.get_pixelv(base0 + Vector2i(x, y))
			var b := img.get_pixelv(base4 + Vector2i(x, y))
			total += 1
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a) < 0.02:
				same += 1
	var diff_ratio := 1.0 - float(same) / float(maxi(total, 1))
	check(diff_ratio > 0.005,
			"%s run 动画帧间有真实动作（差异 %.2f%%，为 0 说明骨架没被驱动）" % [key, diff_ratio * 100.0])


func _enemy_cleanup(enemy: Node2D) -> void:
	if is_instance_valid(enemy):
		enemy.free()


class _MockPlayer:
	extends CharacterBody2D
	var hits: Array[Dictionary] = []

	func _ready() -> void:
		collision_layer = 1
		collision_mask = 1
		add_to_group("player")
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		var shape := CollisionShape2D.new()
		shape.shape = circle
		add_child(shape)

	func take_damage(damage: float, attacker = null) -> void:
		hits.append({"damage": damage, "attacker": attacker})
