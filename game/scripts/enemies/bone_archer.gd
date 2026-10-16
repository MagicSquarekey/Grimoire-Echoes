## BoneArcher - 白骨射手（E16，远程物理）
## 保持距离的弓箭手：进入射程就停下点名，被贴脸（<150px）时边射边退。
## 弹体走通用 EnemyProjectile（直线物理弹，命中玩家本体结算），元素用 air 表示无属性的物理箭。
class_name BoneArcher
extends EnemyBase

@export var attack_range: float = 270.0    # 开火射程
@export var keep_distance: float = 150.0   # 低于该距离后撤
@export var attack_cooldown: float = 1.6
@export var arrow_speed: float = 470.0

var _attack_timer := 0.6

func _init() -> void:
	enemy_name = "白骨射手"
	enemy_type = "ranged"
	max_health = 22.0
	attack_damage = 9.0
	move_speed = 95.0
	exp_reward = 14
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

## 攻击：站桩射击，被贴身则后撤（幸存者类标准的风筝怪）
func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return

	var to_target = target.global_position - global_position
	var distance = to_target.length()
	if distance > attack_range * 1.3:
		current_ai_state = AIState.CHASE
		return

	if distance < keep_distance:
		# 被贴身：边射边退
		velocity = -to_target.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_shoot()
		_attack_timer = attack_cooldown

func _shoot() -> void:
	var proj = make_projectile(attack_damage, arrow_speed, "air")
	if proj == null:
		return
	get_tree().current_scene.add_child.call_deferred(proj)
