## verify_spells.gd - 一次性法术实测工具（headless）
## 用法: godot --headless --path . -s res://tools/verify_spells.gd
## 对 SpellRegistry 中每个法术：实例化 → 摆假人 → 施放 → 跑2秒，收集脚本错误。
extends SceneTree

const ENEMY_SCENE := "res://scenes/enemies/swarm_bug.tscn"

var _frames := 0
var _current: Dictionary = {}
var _spell: Node = null
var _results: Array[String] = []
var _phase := 0


func _initialize() -> void:
	var ids: Array = []
	for id in SpellRegistry.SPELLS:
		ids.append(id)
	ids.sort()  # 确定性顺序
	_current = {"list": ids, "i": -1}
	# 首个法术延迟到首帧内实测（避开 _initialize 阶段树未就绪的边缘情况）
	_next_spell.call_deferred()


func _process(_delta: float) -> bool:
	_frames += 1
	# 每个法术跑 ~120 帧（2秒）后切换下一个
	if _frames >= 120:
		_frames = 0
		_finish_current()
		_next_spell()
	return false


func _next_spell() -> void:
	_current["i"] += 1
	var list: Array = _current["list"]
	var i: int = _current["i"]
	if i >= list.size():
		_report()
		quit(0)
		return
	var id: String = list[i]
	# 干净的隔离场景
	var root_node := Node2D.new()
	root.add_child(root_node)
	current_scene = root_node
	# 玩家替身（owner_node）
	var fake_player := Node2D.new()
	fake_player.name = "FakePlayer"
	fake_player.add_to_group("player")
	root_node.add_child(fake_player)
	var stats := Node2D.new()
	stats.name = "PlayerStats"
	stats.set_script(load("res://scripts/player/player_stats.gd"))
	fake_player.add_child(stats)
	# 假人敌人
	var enemy = load(ENEMY_SCENE).instantiate()
	root_node.add_child(enemy)
	enemy.global_position = Vector2(150, 0)
	# 法术
	var info: Dictionary = SpellRegistry.SPELLS[id]
	_spell = load(info["script"]).new()
	if _spell == null:
		_results.append("[cast] %-18s NEW_FAILED" % id)
		_finish_current()
		_next_spell()
		return
	_spell.set_meta("spell_id", id)
	fake_player.add_child(_spell)
	_spell.owner_node = fake_player
	var ok: bool = _spell.cast(Vector2(150, 0))
	_results.append("[cast] %-18s %s" % [id, "OK" if ok else "FAILED"])
	_current["scene"] = root_node


func _finish_current() -> void:
	if _spell != null and is_instance_valid(_spell):
		_spell.queue_free()
	if _current.has("scene") and is_instance_valid(_current["scene"]):
		_current["scene"].queue_free()
	_spell = null


func _report() -> void:
	print("==== 法术实测结果 ====")
	for r in _results:
		print(r)
	print("==== 共 %d 个法术 ====" % _results.size())
