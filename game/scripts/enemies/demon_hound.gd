## DemonHound - 恶魔猎犬
## 极快冲锋怪：血薄、速度快，成群（4-6只一包）从同侧涌入；4 波起出现
class_name DemonHound
extends EnemyBase

@export var charge_speed: float = 460.0   # 冲锋速度
@export var charge_distance: float = 220.0  # 触发冲锋的距离
@export var attack_interval: float = 0.8

var attack_timer: float = 0.0
var is_charging: bool = false

func _init() -> void:
	enemy_name = "恶魔猎犬"
	enemy_type = "fast"
	max_health = 30.0       # 血薄（略高于20，保证狼群包能冲到玩家面前形成威胁）
	attack_damage = 10.0
	move_speed = 240.0      # 极快
	exp_reward = 8
	gold_reward = 1

func _process_ai(delta: float) -> void:
	if is_charging:
		return
	match current_ai_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.ATTACK:
			_process_attack(delta)

## 追击：接近时触发直线冲锋
func _process_chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.IDLE
		return

	var distance = global_position.distance_to(target.global_position)
	if distance < 45.0:
		current_ai_state = AIState.ATTACK
		return

	if distance < charge_distance:
		_perform_charge()
		return

	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return

	var distance = global_position.distance_to(target.global_position)
	if distance > 60.0:
		current_ai_state = AIState.CHASE
		return

	attack_timer -= delta
	if attack_timer <= 0:
		_perform_attack()
		attack_timer = attack_interval

func _perform_attack() -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(attack_damage, self)

## 冲锋：朝玩家直线加速一段，随后恢复常速
func _perform_charge() -> void:
	if not target or not is_instance_valid(target):
		return

	is_charging = true
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * charge_speed

	var tween = create_tween()
	tween.tween_property(self, "velocity", direction * move_speed, 0.35)

	await tween.finished
	# 安全检查：敌人可能在等待期间死亡
	if is_instance_valid(self):
		is_charging = false
