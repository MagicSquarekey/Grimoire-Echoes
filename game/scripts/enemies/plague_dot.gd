## PlagueDot - 瘟疫层数载体（敌方中毒持续伤害的结算器）
## 职责：plague_spitter 的毒弹命中后，把"中毒层数"记在本节点上并按固定间隔结算到玩家。
##   1. 全场单例（static 缓存 + group 双保险），弹体/法师死亡不影响已上的毒
##   2. tick 间隔 0.75s > 玩家 0.5s 无敌帧，保证每跳都能真正结算
##   3. 层数上限 5：超限时旧层先掉，避免多只毒蛛同屏把 DPS 叠成不可解的死局
## 无毒时 set_process(false) 休眠，不占逐帧开销。
class_name PlagueDot
extends Node2D

const GROUP := "enemy_plague_dot"
const TICK_INTERVAL := 0.75
const MAX_STACKS := 5

static var _instance: PlagueDot = null

## 每层：{remaining: 剩余秒数, tick_damage: 每跳伤害}
var _stacks: Array[Dictionary] = []
var _tick_accum := 0.0
var _player: Node2D = null

## 取/建全场唯一结算器。from 为任意在树节点（通常是命中的弹体）。
static func attach_from(from: Node) -> PlagueDot:
	if _instance != null and is_instance_valid(_instance):
		return _instance
	var tree := from.get_tree()
	if tree == null or tree.current_scene == null:
		return null
	# 切场景等异常路径下 static 缓存可能漏掉已在树的实例，按 group 兜底
	var found := tree.get_first_node_in_group(GROUP)
	if found is PlagueDot:
		_instance = found
		return found
	var dot := PlagueDot.new()
	_instance = dot
	# 常由弹体 body_entered（物理 flush 期间）调用，延迟挂载
	tree.current_scene.add_child.call_deferred(dot)
	return dot

func _ready() -> void:
	add_to_group(GROUP)
	# 毒弹常在同一帧内 attach_from() + add_stack()：此时 _ready 晚于
	# add_stack 的 set_process(true)，无条件关闭会让已经上的毒永不结算
	set_process(not _stacks.is_empty())

## 叠毒：stacks 层，每层每 TICK_INTERVAL 跳 tick_damage，持续 duration 秒
func add_stack(tick_damage: float, duration: float, stacks: int = 1) -> void:
	if tick_damage <= 0.0 or duration <= 0.0:
		return
	for i in stacks:
		_stacks.append({"remaining": duration, "tick_damage": tick_damage})
	while _stacks.size() > MAX_STACKS:
		_stacks.pop_front()
	set_process(true)

func _process(delta: float) -> void:
	var dt: float = delta * GameManager.speed_multiplier
	for i in range(_stacks.size() - 1, -1, -1):
		_stacks[i]["remaining"] -= dt
		if float(_stacks[i]["remaining"]) <= 0.0:
			_stacks.remove_at(i)

	if _stacks.is_empty():
		set_process(false)
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return

	_tick_accum += dt
	if _tick_accum < TICK_INTERVAL:
		return
	_tick_accum = 0.0

	var total := 0.0
	for stack in _stacks:
		total += float(stack["tick_damage"])
	if _player.has_method("take_damage"):
		_player.take_damage(total, self)
	# 中毒反馈：玩家身上冒一次毒绿粒子（数量少，只在真正掉血的一跳出现）
	FxLib.element_burst(self, _player.global_position, "nature", 0.55)
