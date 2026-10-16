## Gargoyle - 石像鬼（E3，飞行俯冲）
## 空中单位：场景里 collision_mask = 0，不吃任何碰撞阻力（地形、玩家、其它怪都穿过去），
## 视觉上 Body 抬高 + 阴影留在地面表示高度。
## 行为：悬停逼近 → 进入俯冲距离后定身蓄力 0.45s（身体闪红 = 可读预警）→
##       620px/s 直线俯冲，末端一次性结算撕咬伤害 → 2.2s 冷却才能再俯冲。
class_name Gargoyle
extends EnemyBase

@export var swoop_range: float = 270.0     # 触发俯冲的距离
@export var swoop_speed: float = 620.0     # 俯冲速度
@export var swoop_cooldown: float = 2.2    # 俯冲冷却
@export var telegraph_time: float = 0.45   # 蓄力时间（玩家躲避窗口）
@export var dive_time: float = 0.4         # 俯冲持续时间
@export var hover_amplitude: float = 42.0  # 悬停横摆幅度（飞行的不稳定性观感）

var _swoop_cd := 1.2
var _hover_phase := 0.0
var _diving := false
var _attack_timer := 0.0

func _init() -> void:
	enemy_name = "石像鬼"
	enemy_type = "flyer"
	max_health = 80.0
	attack_damage = 18.0
	move_speed = 105.0
	exp_reward = 20
	gold_reward = 3

func _process_ai(delta: float) -> void:
	if _diving:
		return
	_swoop_cd -= delta
	match current_ai_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.ATTACK:
			_process_attack(delta)

## 追击：带横摆的悬停逼近，冷却就绪且进入距离即俯冲
func _process_chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.IDLE
		return

	var distance = global_position.distance_to(target.global_position)
	if distance < 46.0:
		current_ai_state = AIState.ATTACK
		return

	var direction = (target.global_position - global_position).normalized()
	_hover_phase += delta * 3.2
	velocity = direction * move_speed + direction.orthogonal() * sin(_hover_phase) * hover_amplitude
	move_and_slide()

	if distance < swoop_range and _swoop_cd <= 0.0:
		_perform_swoop()

func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return
	if global_position.distance_to(target.global_position) > 62.0:
		current_ai_state = AIState.CHASE
		return

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		if target.has_method("take_damage"):
			target.take_damage(attack_damage, self)
		_attack_timer = 1.0

## 俯冲：蓄力预警 → 锁定瞬移式直线冲刺 → 末端判定
func _perform_swoop() -> void:
	if not target or not is_instance_valid(target):
		return
	_swoop_cd = swoop_cooldown
	_diving = true
	velocity = Vector2.ZERO
	move_and_slide()

	if body:
		body.modulate = Color(1.0, 0.42, 0.32)
		var flash := create_tween()
		flash.tween_property(body, "modulate", Color.WHITE, telegraph_time)
	await get_tree().create_timer(telegraph_time).timeout
	if not is_instance_valid(self) or not is_alive:
		return
	if not target or not is_instance_valid(target):
		_diving = false
		return

	var lock_direction = (target.global_position - global_position).normalized()
	velocity = lock_direction * swoop_speed
	var dive := create_tween()
	dive.tween_property(self, "velocity", lock_direction * move_speed, dive_time)
	await dive.finished
	_diving = false

	if not is_instance_valid(self) or not is_alive:
		return
	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= 54.0:
		if target.has_method("take_damage"):
			target.take_damage(attack_damage, self)
		FxLib.element_burst(self, target.global_position, "shadow", 0.7)
