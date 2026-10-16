## PlagueSpitter - 毒疫吐息者（E6，远程中毒）
## 中距离吐毒：弹速慢、单发伤害低，但命中后给玩家叠 1 层瘟疫
## （每 0.75s 一跳、持续 3s，最多 5 层，结算见 PlagueDot）。
## 定位是"清场优先级怪"：放着不管，层数一叠起来玩家血线就再也回不来。
class_name PlagueSpitter
extends EnemyBase

@export var attack_range: float = 230.0
@export var keep_distance: float = 120.0
@export var attack_cooldown: float = 1.9
@export var glob_speed: float = 300.0
@export var plague_tick_damage: float = 3.0   # 单层每跳伤害
@export var plague_duration: float = 3.0      # 单层持续秒数

var _attack_timer := 1.0

func _init() -> void:
	enemy_name = "毒疫吐息者"
	enemy_type = "ranged"
	max_health = 25.0
	attack_damage = 6.0
	move_speed = 70.0
	exp_reward = 15
	gold_reward = 2

func _process_ai(delta: float) -> void:
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
	if distance <= attack_range:
		current_ai_state = AIState.ATTACK
		return

	velocity = (target.global_position - global_position).normalized() * move_speed
	move_and_slide()

func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return

	var to_target = target.global_position - global_position
	if to_target.length() > attack_range * 1.35:
		current_ai_state = AIState.CHASE
		return

	if to_target.length() < keep_distance:
		velocity = -to_target.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_spit()
		_attack_timer = attack_cooldown

## 吐一枚毒弹：命中判定与叠毒都在 EnemyProjectile 里完成
func _spit() -> void:
	var proj = make_projectile(attack_damage, glob_speed, "nature")
	if proj == null:
		return
	proj.plague_stacks = 1
	proj.plague_tick_damage = plague_tick_damage
	proj.plague_duration = plague_duration
	get_tree().current_scene.add_child.call_deferred(proj)
