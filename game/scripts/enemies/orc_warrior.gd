## OrcWarrior - 兽人勇士
## 重甲近战：血厚、速度慢、伤害高、击退抵抗；8 波起出现
class_name OrcWarrior
extends EnemyBase

func _init() -> void:
	enemy_name = "兽人勇士"
	enemy_type = "elite_grunt"
	max_health = 120.0      # 约为暗影仆从(30)的4倍
	attack_damage = 18.0
	move_speed = 70.0       # 重甲，移动缓慢
	exp_reward = 30
	gold_reward = 5

## 击退抵抗：重甲单位只受 25% 击退力
func apply_knockback(direction: Vector2, force: float) -> void:
	super(direction, force * 0.25)

## 近战攻击逻辑（与暗影仆从同型：贴近后普攻，攻击间隙回追）
func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return

	var distance = global_position.distance_to(target.global_position)
	if distance > 70.0:
		current_ai_state = AIState.CHASE
		return

	_perform_attack()

func _perform_attack() -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(attack_damage, self)

	await get_tree().create_timer(1.2).timeout
	# 安全检查：敌人可能在等待期间死亡
	if is_instance_valid(self) and is_alive:
		current_ai_state = AIState.CHASE
