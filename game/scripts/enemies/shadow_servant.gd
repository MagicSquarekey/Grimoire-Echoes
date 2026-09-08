## ShadowServant - 暗影仆从
## 基础近战敌人，直线追踪玩家
extends EnemyBase

func _init() -> void:
	enemy_name = "暗影仆从"
	enemy_type = "common"
	max_health = 30.0
	attack_damage = 8.0
	move_speed = 120.0
	exp_reward = 10
	gold_reward = 1

## 重写攻击逻辑
func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return
	
	var distance = global_position.distance_to(target.global_position)
	if distance > 60.0:
		current_ai_state = AIState.CHASE
		return
	
	_perform_attack()

## 执行攻击
func _perform_attack() -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(attack_damage, self)
	
	await get_tree().create_timer(1.0).timeout
	# 安全检查：敌人可能在等待期间死亡
	if is_instance_valid(self) and is_alive:
		current_ai_state = AIState.CHASE

## 重写死亡处理，添加粒子效果
func _die() -> void:
	_create_death_effect()
	super._die()

## 创建死亡效果
func _create_death_effect() -> void:
	var effect_script = preload("res://scripts/effects/particle_effect.gd")
	var effect = Node2D.new()
	effect.set_script(effect_script)
	effect.effect_color = Color(0.5, 0.2, 0.7, 1)
	effect.particle_count = 10
	effect.particle_size = 4.0
	effect.particle_speed = 120.0
	effect.lifetime = 0.6
	var effect_pos = global_position
	get_tree().current_scene.add_child(effect)
	effect.global_position = effect_pos
