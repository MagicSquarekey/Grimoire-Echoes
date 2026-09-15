## OrbitOrbsController - 环绕法书控制器（纯视觉+命中判定，不碰玩家逻辑）
## 由 OrbitOrbs 法术创建，挂在 current_scene 下，跟随玩家旋转光球。
## 命中采用分组距离检测（敌人数 × 光球数 ≤ 几百次/帧），避免物理回调开销；
## 每个敌人 0.5s 内不重复受伤（时间戳表）。
extends Node2D

const ORB_SCRIPT := preload("res://scripts/spells/orbit_orb_visual.gd")

var _player: Node2D = null
var _radius: float = 70.0
var _speed: float = 2.6
var _remain: float = 0.0
var _damage: float = 10.0
var _hit_radius: float = 24.0
var _hit_interval: float = 0.5
var _orbs: Array[Node2D] = []
var _base_angle: float = 0.0
# 敌人 → 上次受击时间戳（msec）
var _last_hit := {}


func setup_deferred(player: Node2D, radius: float, speed: float, duration: float,
		orb_count: int, damage: float, hit_radius: float, hit_interval: float) -> void:
	_player = player
	_radius = radius
	_speed = speed
	_remain = duration
	_damage = damage
	_hit_radius = hit_radius
	_hit_interval = hit_interval
	_build_orbs(orb_count)


func refresh(duration: float, orb_count: int, damage: float) -> void:
	_remain = duration
	_damage = damage
	while _orbs.size() < orb_count:
		_add_orb(_orbs.size())
	# 统一刷新 index/total 与伤害（新增光球后重新分布）
	for i in range(_orbs.size()):
		if is_instance_valid(_orbs[i]):
			_orbs[i].orb_index = i
			_orbs[i].orb_total = _orbs.size()
	# 刷新光球伤害
	for orb in _orbs:
		if orb.has_method("set_damage"):
			orb.set_damage(_damage)


func _build_orbs(count: int) -> void:
	for i in range(count):
		_add_orb(i)


func _add_orb(index: int) -> void:
	var orb: Node2D = ORB_SCRIPT.new()
	orb.orb_index = index
	orb.orb_total = maxi(_orbs.size() + 1, 1)
	add_child(orb)
	_orbs.append(orb)


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return
	_remain -= delta
	if _remain <= 0.0:
		queue_free()
		return

	_base_angle += delta * _speed * GameManager.speed_multiplier
	global_position = _player.global_position

	# 光球位置 + 命中检测
	var now := Time.get_ticks_msec()
	for orb in _orbs:
		if not is_instance_valid(orb):
			continue
		var a := _base_angle + TAU * float(orb.orb_index) / float(orb.orb_total)
		orb.global_position = global_position + Vector2(cos(a), sin(a)) * _radius
	# 命中检测（分组：每帧只查光球周围敌人）
	_check_hits(now)

	# 定期清理过期时间戳（防表无限增长）
	if _last_hit.size() > 64:
		for key in _last_hit.keys():
			if now - _last_hit[key] > int(_hit_interval * 2000.0):
				_last_hit.erase(key)


func _check_hits(now: int) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.get("is_alive"):
			continue
		var last: int = _last_hit.get(enemy, -999999)
		if now - last < int(_hit_interval * 1000.0):
			continue
		for orb in _orbs:
			if is_instance_valid(orb) and orb.global_position.distance_to(enemy.global_position) <= _hit_radius:
				_last_hit[enemy] = now
				if enemy.has_method("take_damage"):
					enemy.take_damage(_damage, _player)
				EventBus.spell_hit.emit(enemy, _damage)
				# 命中爆裂（arcane 预设）
				FxLib.element_burst(orb, orb.global_position, "arcane", 0.5)
				if orb.has_method("pulse"):
					orb.pulse()
				break


func _exit_tree() -> void:
	_orbs.clear()
