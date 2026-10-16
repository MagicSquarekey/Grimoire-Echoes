## EmberLord - 元素领主（E15，天生精英 / 随机元素 AoE）
## 缓步逼近的法术精英：每 3.4s 随机挑一种元素（火/水/雷/影），
## 自身染色 0.55s 作为预警，然后在**施法瞬间的玩家位置**炸一圈该元素的冲击波。
## 因为爆炸点是预判落点而不是自身，玩家必须持续走位，站桩就会被连爆。
## 元素配色/粒子全部走 FxLib 预设，与玩家法术同一套视觉语言。
class_name EmberLord
extends EnemyBase

const ELEMENTS := ["fire", "water", "lightning", "shadow"]

@export var burst_cooldown: float = 3.4
@export var burst_radius: float = 120.0
@export var telegraph_time: float = 0.55
@export var cast_range: float = 380.0

var _burst_timer := 2.0
var _melee_timer := 0.0
var _casting := false

func _init() -> void:
	enemy_name = "元素领主"
	enemy_type = "elite"
	max_health = 250.0
	attack_damage = 30.0     # 元素爆裂的单圈伤害
	move_speed = 95.0
	exp_reward = 60
	gold_reward = 12
	# 在 _init 里标记：EnemySpawner 实例化后立刻判断 is_elite，决定精英槽是否让位
	mark_inherent_elite()

func _process_ai(delta: float) -> void:
	if not _casting:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_begin_cast()
	super(delta)

## 起手：元素染色预警 → 落点在起手瞬间锁定（玩家脚下）→ 0.55s 后在该固定位置引爆。
## 落点提前锁定意味着"看见圈亮就走"就能躲开，站桩必吃。
func _begin_cast() -> void:
	if not target or not is_instance_valid(target):
		return
	if global_position.distance_to(target.global_position) > cast_range:
		return

	_casting = true
	_burst_timer = burst_cooldown
	var element: String = ELEMENTS[randi() % ELEMENTS.size()]
	var col := FxLib.color_for(element)
	var aim: Vector2 = target.global_position

	if body:
		body.modulate = col
	# 预警：出生门环直接打在落点上（纯视觉 0.3s 收缩），玩家看到圈亮就该离开
	FxLib.spawn_portal(self, aim, col)

	await get_tree().create_timer(telegraph_time).timeout
	if not is_instance_valid(self) or not is_alive:
		return
	if body:
		var fade := create_tween()
		fade.tween_property(body, "modulate", Color.WHITE, 0.2)
	_casting = false

	ShockwaveRing.spawn(self, aim, burst_radius, attack_damage, col, 0.28, element)

## 被玩家贴住时的自保钝击（60% 伤害、1.6s 一次）
func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return
	if global_position.distance_to(target.global_position) > 70.0:
		current_ai_state = AIState.CHASE
		return

	velocity = Vector2.ZERO
	_melee_timer -= delta
	if _melee_timer <= 0.0:
		_melee_timer = 1.6
		if target.has_method("take_damage"):
			target.take_damage(attack_damage * 0.6, self)
