## SwarmBug - 虫群
## 快速近战型敌人，成群出现
class_name SwarmBug
extends EnemyBase

# 虫群特有属性
@export var dash_speed: float = 250.0  # 冲刺速度
@export var dash_distance: float = 100.0  # 冲刺距离
@export var attack_interval: float = 0.8  # 攻击间隔
@export var swarm_bonus: float = 0.1  # 每个附近友军增加10%伤害

# 攻击计时器
var attack_timer: float = 0.0
var is_dashing: bool = false

func _init() -> void:
	# 虫群属性
	enemy_name = "swarm_bug"
	enemy_type = "common"
	max_health = 15.0
	attack_damage = 5.0
	move_speed = 160.0
	exp_reward = 5
	gold_reward = 1

## 重写AI逻辑
func _process_ai(delta: float) -> void:
	if is_dashing:
		return
	
	match current_ai_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.ATTACK:
			_process_attack(delta)

## 追踪状态（快速移动）
func _process_chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.IDLE
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	# 如果在攻击范围内
	if distance < 40.0:
		current_ai_state = AIState.ATTACK
		return
	
	# 检查是否可以冲刺
	if distance < dash_distance and not is_dashing:
		_perform_dash()
		return
	
	# 向目标移动
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

## 攻击状态
func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	# 如果超出攻击范围
	if distance > 50.0:
		current_ai_state = AIState.CHASE
		return
	
	# 更新攻击计时器
	attack_timer -= delta
	if attack_timer <= 0:
		_perform_attack()
		attack_timer = attack_interval

## 执行攻击
func _perform_attack() -> void:
	if target and target.has_method("take_damage"):
		# 计算虫群加成
		var bonus_damage = _get_swarm_bonus()
		target.take_damage(attack_damage + bonus_damage, self)

## 执行冲刺
func _perform_dash() -> void:
	if not target or not is_instance_valid(target):
		return
	
	is_dashing = true
	
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * dash_speed
	
	# 冲刺动画
	var tween = create_tween()
	tween.tween_property(self, "velocity", direction * move_speed, 0.2)
	
	await tween.finished
	is_dashing = false

## 获取虫群加成
func _get_swarm_bonus() -> float:
	var nearby_allies = 0
	var space_state = get_world_2d().direct_space_state
	var shape = CircleShape2D.new()
	shape.radius = 80.0
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies") and collider != self:
			nearby_allies += 1
	
	return attack_damage * swarm_bonus * nearby_allies
