## GraveCleric - 墓园牧师（E9，治疗支援）
## 不攻击玩家（attack_damage = 0），专职给半径 190px 内的友军回血：
## 每 3s 结算一次，所有受伤友军回复自身上限 5%，牧师长年拉着血线所以必须优先点掉。
## 走位：与玩家保持 170~260px 的距离，贴着最残血的友军移动（该目标每次治疗时刷新，
##      不是每帧扫描 —— 数百敌人同屏时 O(n²) 会掉帧，见 enemy_base.allies_in_radius 注释）。
class_name GraveCleric
extends EnemyBase

@export var heal_radius: float = 190.0
@export var heal_cooldown: float = 3.0
@export var heal_ratio: float = 0.05      # 每次治疗 = 目标生命上限的 5%
@export var retreat_distance: float = 170.0  # 玩家贴到这个距离就后撤
@export var follow_distance: float = 260.0   # 距玩家超过这个距离就跟上的友军靠拢

var _heal_timer := 1.5
var _follow_target: Node2D = null

func _init() -> void:
	enemy_name = "墓园牧师"
	enemy_type = "support"
	max_health = 45.0
	attack_damage = 0.0
	move_speed = 105.0
	exp_reward = 18
	gold_reward = 3

func _ready() -> void:
	super()
	# 支援单位的识别标志：脚下绿色光环（与精英金环同一套视觉语言）
	_add_ground_ring(Color(0.45, 0.9, 0.5, 0.8), 1.15)

func _process_ai(delta: float) -> void:
	if not target or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
		return
	_keep_distance()
	_heal_timer -= delta
	if _heal_timer <= 0.0:
		_perform_heal()
		_heal_timer = heal_cooldown

## 走位：远离玩家，向残血友军靠拢
func _keep_distance() -> void:
	var to_player = target.global_position - global_position
	var distance = to_player.length()

	var desired := Vector2.ZERO
	if distance < retreat_distance:
		desired = -to_player.normalized()
	elif _follow_target and is_instance_valid(_follow_target):
		var offset = _follow_target.global_position - global_position
		if offset.length() > 60.0:
			desired = offset.normalized()
	# 没有友军可跟时保持在玩家外围游走
	elif distance > follow_distance:
		desired = to_player.normalized()

	velocity = desired * move_speed
	move_and_slide()

## 治疗光环：一次形状查询拿到范围内友军，全部回血并刷新跟随目标
func _perform_heal() -> void:
	var allies := allies_in_radius(heal_radius, 24)
	var weakest: Node2D = null
	var weakest_ratio := 1.0
	var healed := 0

	for ally_node in allies:
		if not (ally_node is EnemyBase):
			continue
		var ally := ally_node as EnemyBase
		if not ally.is_alive:
			continue
		if ally.max_health - ally.current_health <= 0.0:
			continue
		ally.heal(ally.max_health * heal_ratio)
		FxLib.element_burst(ally, ally.global_position, "nature", 0.5)
		healed += 1
		var ratio: float = ally.current_health / maxf(ally.max_health, 1.0)
		if ratio < weakest_ratio:
			weakest_ratio = ratio
			weakest = ally

	# 自己也吃到治疗：牧师不该被顺手一箭带走
	if max_health - current_health > 0.0:
		heal(max_health * heal_ratio)

	if healed > 0:
		FxLib.element_burst(self, global_position, "nature", 0.9)
	_follow_target = weakest
