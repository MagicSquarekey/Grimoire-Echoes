## AegisGolem - 圣盾石像（E10，护盾光环）
## 慢速重装：自己血厚，还给半径 175px 内的友军挂吸收盾（每 4s 补一层，单只友军最多叠到
## 自身上限 25%）。护盾走 EnemyBase.take_damage 的吸收分支，会顶掉玩家的一轮输出，
## 所以它是"必须优先点掉的软骨头集合器"，和墓园牧师构成两类支援压力。
## 光环结算只在冷却到点时做一次形状查询，不逐帧扫描。
class_name AegisGolem
extends EnemyBase

@export var shield_radius: float = 175.0
@export var aura_cooldown: float = 4.0
@export var shield_amount: float = 14.0
@export var shield_cap_ratio: float = 0.25   # 单只友军护盾上限 = 生命上限的 25%

var _aura_timer := 1.0
var _attack_timer := 0.0

func _init() -> void:
	enemy_name = "圣盾石像"
	enemy_type = "support"
	max_health = 150.0
	attack_damage = 10.0
	move_speed = 62.0
	exp_reward = 22
	gold_reward = 4

func _ready() -> void:
	super()
	# 光环范围用脚下的蓝色环表示，和精英金环/Boss 红环区分
	_add_ground_ring(Color(0.42, 0.72, 1.0, 0.75), 1.6)

func _process_ai(delta: float) -> void:
	if not target or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
		return

	_aura_timer -= delta
	if _aura_timer <= 0.0:
		_pulse_shield_aura()
		_aura_timer = aura_cooldown

	var distance = global_position.distance_to(target.global_position)
	if distance < 52.0:
		_melee_tick(delta)
		return

	velocity = (target.global_position - global_position).normalized() * move_speed
	move_and_slide()

## 近身钝击（与兽人同型：贴住后按间隔结算）
func _melee_tick(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if target.has_method("take_damage"):
		target.take_damage(attack_damage, self)
	_attack_timer = 1.3

## 护盾光环：范围内未满盾的友军各补一层
func _pulse_shield_aura() -> void:
	var shielded := 0
	for ally_node in allies_in_radius(shield_radius, 24):
		if not (ally_node is EnemyBase):
			continue
		var ally := ally_node as EnemyBase
		if not ally.is_alive:
			continue
		var shield_cap: float = ally.max_health * shield_cap_ratio
		if ally.shield_hp >= shield_cap:
			continue
		ally.apply_shield(minf(shield_amount, shield_cap - ally.shield_hp))
		shielded += 1

	# 自己也挂盾
	var self_cap: float = max_health * shield_cap_ratio
	if shield_hp < self_cap:
		apply_shield(minf(shield_amount, self_cap - shield_hp))
		shielded += 1

	if shielded > 0:
		FxLib.element_burst(self, global_position, "water", 0.8)
