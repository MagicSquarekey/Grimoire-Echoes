## Dragon - 熔岩飞龙（Boss 基底）
## 空中 Boss：场景里 collision_mask = 0，不被地面人墙与地形卡住，追击靠 Boss 冲锋技能做爆发位移。
## 基线数值沿用被它替换的兽人勇士（血量/伤害一致，Boss 倍率仍由 make_boss 施加），
## 只把地面速度下调一档，补偿"飞行不受阻"带来的实际提速，避免换模型顺带把难度抬高。
class_name Dragon
extends EnemyBase

## 贴脸距离：龙的身体比兽人大，判定半径同步放宽
const MELEE_REACH := 90.0
## 两次吐息之间的间隔
const ATTACK_COOLDOWN := 1.3


func _init() -> void:
	enemy_name = "熔岩飞龙"
	enemy_type = "elite_grunt"
	max_health = 120.0
	attack_damage = 18.0
	move_speed = 60.0
	exp_reward = 30
	gold_reward = 5


## 首领体型不该被一次普攻推开
func apply_knockback(direction: Vector2, force: float) -> void:
	super(direction, force * 0.15)


func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return
	if global_position.distance_to(target.global_position) > MELEE_REACH:
		current_ai_state = AIState.CHASE
		return
	_perform_attack()


func _perform_attack() -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(attack_damage, self)
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	# 等待期间可能被击杀
	if is_instance_valid(self) and is_alive:
		current_ai_state = AIState.CHASE
