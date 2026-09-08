## SkeletonMage - 骷髅法师
## 远程攻击型敌人，会发射魔法弹
class_name SkeletonMage
extends EnemyBase

# 骷髅法师特有属性
@export var attack_range: float = 200.0  # 攻击范围
@export var attack_cooldown: float = 2.0  # 攻击冷却
@export var projectile_speed: float = 250.0  # 投射物速度

# 攻击计时器
var attack_timer: float = 0.0

func _init() -> void:
	# 骷髅法师属性
	enemy_name = "skeleton_mage"
	enemy_type = "common"
	max_health = 25.0
	attack_damage = 12.0
	move_speed = 80.0
	exp_reward = 15
	gold_reward = 2

## 重写AI逻辑
func _process_ai(delta: float) -> void:
	match current_ai_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.ATTACK:
			_process_attack(delta)

## 追踪状态（保持距离）
func _process_chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.IDLE
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	# 如果在攻击范围内，切换到攻击状态
	if distance <= attack_range:
		current_ai_state = AIState.ATTACK
		return
	
	# 向目标移动（但保持距离）
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

## 攻击状态（远程攻击）
func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.IDLE
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	# 如果超出攻击范围，切换回追踪
	if distance > attack_range * 1.2:
		current_ai_state = AIState.CHASE
		return
	
	# 更新攻击计时器
	attack_timer -= delta
	if attack_timer <= 0:
		_fire_projectile()
		attack_timer = attack_cooldown

## 发射魔法弹
func _fire_projectile() -> void:
	if not target or not is_instance_valid(target):
		return
	
	var projectile = Area2D.new()
	projectile.collision_layer = 4  # EnemyProjectiles层
	projectile.collision_mask = 1   # 检测Player层
	
	# 视觉效果：紫色菱形
	var visual = Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(0, -6), Vector2(6, 0), Vector2(0, 6), Vector2(-6, 0)])
	visual.color = Color(0.6, 0.2, 0.9, 0.9)
	projectile.add_child(visual)
	
	# 碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8.0
	collision.shape = circle
	projectile.add_child(collision)
	
	# 添加到场景（先add再定位，否则位置赋值丢失）
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	
	# 计算目标位置（预测玩家移动）
	var target_pos = target.global_position
	if target is CharacterBody2D:
		target_pos += target.velocity * 0.3
	
	# 移动投射物
	var direction = (target_pos - global_position).normalized()
	var speed = projectile_speed
	var max_lifetime = 2.0
	
	# 用tween移动
	var tween = projectile.create_tween()
	var distance = global_position.distance_to(target_pos)
	var travel_time = distance / projectile_speed
	tween.tween_property(projectile, "global_position", target_pos, travel_time)
	tween.tween_callback(projectile.queue_free).set_delay(0.01)
	
	# 碰撞检测（Area2D body_entered）
	projectile.body_entered.connect(func(body):
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(attack_damage, self)
			projectile.queue_free()
	)
	
	# 超时销毁
	get_tree().create_timer(max_lifetime).timeout.connect(func():
		if is_instance_valid(projectile):
			projectile.queue_free()
	)
