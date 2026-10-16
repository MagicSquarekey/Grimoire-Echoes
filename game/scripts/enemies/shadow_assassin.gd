## ShadowAssassin - 暗影刺客（E4，突进-剥离）
## 极快的刺客：逼近到 260px 内瞬身突进到玩家脸上打一下，然后"闪现"回 240px 外重新起手。
## 循环节奏：突进 0.16s → 命中 → 后撤闪现 → 3s 冷却。
## 与猎犬的区别：猎犬是直线冲锋撞进来，刺客是"打完整个人弹走"，压迫感来自反复起手。
class_name ShadowAssassin
extends EnemyBase

@export var engage_range: float = 260.0    # 起手距离
@export var dash_speed: float = 900.0
@export var dash_time: float = 0.16
@export var blink_distance: float = 240.0  # 打完闪回的距离
@export var cycle_cooldown: float = 3.0
@export var strike_mult: float = 1.5       # 突进一击的伤害倍率

var _cycle_timer := 0.8
var _acting := false

func _init() -> void:
	enemy_name = "暗影刺客"
	enemy_type = "assassin"
	max_health = 28.0
	attack_damage = 15.0
	move_speed = 210.0
	exp_reward = 12
	gold_reward = 2

func _process_ai(delta: float) -> void:
	if _acting:
		return
	_cycle_timer -= delta
	match current_ai_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.ATTACK:
			_process_attack(delta)

func _process_chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.IDLE
		return

	var distance = global_position.distance_to(target.global_position)
	if distance < 44.0:
		current_ai_state = AIState.ATTACK
		return

	velocity = (target.global_position - global_position).normalized() * move_speed
	move_and_slide()

	if distance < engage_range and _cycle_timer <= 0.0:
		_perform_strike()

## 贴身时仍按冷却打普通一击（突进刚结束时玩家往往就在脸上）
func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return
	if global_position.distance_to(target.global_position) > 60.0:
		current_ai_state = AIState.CHASE
		return
	if _cycle_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_strike()
	_cycle_timer = cycle_cooldown * 0.5

## 突进 → 命中 → 闪现脱离
func _perform_strike() -> void:
	if not target or not is_instance_valid(target):
		return
	_acting = true
	_cycle_timer = cycle_cooldown

	var direction = (target.global_position - global_position).normalized()
	velocity = direction * dash_speed
	var dash := create_tween()
	dash.tween_property(self, "velocity", direction * move_speed, dash_time)
	await dash.finished

	if not is_instance_valid(self) or not is_alive:
		return
	_strike()
	_blink_away()
	_acting = false

## 一击：刺客伤害按倍率放大（0.5 秒无敌帧决定了它一次只能吃到一下）
func _strike() -> void:
	if not target or not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(attack_damage * strike_mult, self)
	FxLib.element_burst(self, target.global_position, "shadow", 0.9)

## 闪现：向背离玩家方向瞬移，两端各放一次传送门光效
func _blink_away() -> void:
	if not target or not is_instance_valid(target):
		return
	var away: Vector2 = (global_position - target.global_position).normalized()
	var old_pos := global_position
	global_position = old_pos + away * blink_distance
	FxLib.spawn_portal(self, old_pos, Color(0.45, 0.22, 0.7))
	FxLib.spawn_portal(self, global_position, Color(0.45, 0.22, 0.7))
	velocity = Vector2.ZERO
