## EnemyBase - 敌人基类
## 所有敌人的基类，定义敌人的基本属性和行为
class_name EnemyBase
extends CharacterBody2D

# 敌人属性
@export var enemy_name = ""
@export var enemy_type = ""
@export var max_health = 30.0
@export var attack_damage = 8.0
@export var move_speed = 120.0
@export var exp_reward = 10
@export var gold_reward = 1

# 当前状态
var current_health = 30.0
var is_alive = true
var target = null

# AI状态枚举
enum AIState {
	IDLE,
	CHASE,
	ATTACK,
	DEAD
}
var current_ai_state = AIState.IDLE

# 组件引用
@onready var body = $Body
@onready var collision_shape = $CollisionShape2D
@onready var hitbox = $Hitbox
@onready var hurtbox = $Hurtbox
@onready var detection_area = $DetectionArea
@onready var ai_timer = $AITimer

# 信号
signal enemy_died(enemy)
signal enemy_hit(attacker, damage)

const GEM_SCENE = preload("res://scenes/pickups/experience_gem.tscn")
const COIN_SCENE = preload("res://scenes/pickups/gold_coin.tscn")

func _ready() -> void:
	current_health = max_health
	# 信号由 .tscn 的 [connection] 段连接，不在脚本中重复连接
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_process_ai(delta)

## 受到伤害
func take_damage(damage: float, attacker = null) -> void:
	if not is_alive:
		return
	
	current_health -= damage
	enemy_hit.emit(attacker, damage)
	
	_on_hit_effect()
	
	if current_health <= 0:
		_die()

## 应用状态效果
func apply_status_effect(effect_type, value, duration) -> void:
	pass

## 应用击退效果
func apply_knockback(direction: Vector2, force: float) -> void:
	velocity = direction * force
	move_and_slide()

## 死亡处理
func _die() -> void:
	if not is_alive:
		return
	is_alive = false
	current_ai_state = AIState.DEAD
	
	collision_shape.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)
	
	_on_death_animation()
	enemy_died.emit(self)
	# 掉落物含 Area2D；_die 常由物理回调(弹体body_entered)触发，
	# 在物理flush期间直接add_child会报 "Can't change this state while flushing queries"，改为延迟执行
	_drop_rewards.call_deferred()
	
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self):
		queue_free()

## 掉落奖励：经验宝石 + 概率金币
func _drop_rewards() -> void:
	EventBus.enemy_killed.emit(enemy_name, exp_reward, gold_reward)
	
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return
	
	# 掉落经验宝石（承载敌人经验值）
	if GEM_SCENE:
		var gem = GEM_SCENE.instantiate()
		gem.pickup_value = exp_reward
		scene_root.add_child(gem)
		# add_child之后再设置位置，否则赋值丢失
		gem.global_position = global_position
	
	# 40% 概率掉落金币
	if COIN_SCENE and randf() < 0.4:
		var coin = COIN_SCENE.instantiate()
		coin.pickup_value = gold_reward
		scene_root.add_child(coin)
		coin.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))

## AI逻辑处理
func _process_ai(delta: float) -> void:
	match current_ai_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.ATTACK:
			_process_attack(delta)

## 空闲状态
func _process_idle(delta: float) -> void:
	if target:
		current_ai_state = AIState.CHASE

## 追踪状态
func _process_chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.IDLE
		return
	
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	
	var distance = global_position.distance_to(target.global_position)
	if distance < 50.0:
		current_ai_state = AIState.ATTACK

## 攻击状态（子类重写）
func _process_attack(delta: float) -> void:
	pass

## 受击特效
func _on_hit_effect() -> void:
	if body:
		body.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(body, "modulate", Color.WHITE, 0.1)

## 死亡动画
func _on_death_animation() -> void:
	if body:
		var tween = create_tween()
		tween.tween_property(body, "modulate:a", 0.0, 0.3)

## 受击区域检测
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hitbox"):
		var attacker = area.get_parent()
		if attacker.has_method("get_damage"):
			take_damage(attacker.get_damage(), attacker)

## 检测区域检测
func _on_detection_area_body_entered(body_node: Node2D) -> void:
	if body_node.is_in_group("player"):
		target = body_node

## AI计时器超时
func _on_ai_timer_timeout() -> void:
	if target and not is_instance_valid(target):
		target = null
		current_ai_state = AIState.IDLE

## 获取伤害
func get_damage() -> float:
	return attack_damage

## 设置难度系数
func set_difficulty(multiplier: float) -> void:
	max_health *= multiplier
	current_health = max_health
	attack_damage *= multiplier
	move_speed *= (1.0 + (multiplier - 1.0) * 0.2)
