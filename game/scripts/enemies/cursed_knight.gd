## CursedKnight - 暗影骑士（E14，天生精英 / 暗影冲击波）
## 精英近战：血厚攻高，每 5s 以自身为圆心放一道向外扩散的暗影冲击波（0.6s 蓄力闪紫 = 预警）。
## 冲击波走 ShockwaveRing，扩散期间只咬玩家一次；贴脸时按 1.2s 间隔普通挥砍。
## 天生精英（mark_inherent_elite）：属性表已按精英配置，EnemySpawner 不会再给它叠 make_elite
## 的 8 倍血量，避免"精英槽随机抽中精英怪"变成血牛。
class_name CursedKnight
extends EnemyBase

@export var shockwave_cooldown: float = 5.0
@export var shockwave_radius: float = 215.0
@export var shockwave_damage: float = 25.0
@export var telegraph_time: float = 0.6
@export var attack_interval: float = 1.2

var _shock_timer := 2.5
var _attack_timer := 0.0
var _erupting := false

func _init() -> void:
	enemy_name = "暗影骑士"
	enemy_type = "elite"
	max_health = 200.0
	attack_damage = 25.0
	move_speed = 100.0
	exp_reward = 50
	gold_reward = 10
	# 在 _init 里标记：EnemySpawner 实例化后立刻判断 is_elite，决定精英槽是否让位
	mark_inherent_elite()

func _process_ai(delta: float) -> void:
	if not _erupting:
		_shock_timer -= delta
		if _shock_timer <= 0.0 and target and is_instance_valid(target) \
				and global_position.distance_to(target.global_position) < shockwave_radius:
			_erupt()
	super(delta)

## 贴脸挥砍
func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return
	if global_position.distance_to(target.global_position) > 66.0:
		current_ai_state = AIState.CHASE
		return

	velocity = Vector2.ZERO
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		if target.has_method("take_damage"):
			target.take_damage(attack_damage, self)

## 震波：先给自己 0.6s 紫色预警，再从脚下炸开一圈
func _erupt() -> void:
	_shock_timer = shockwave_cooldown
	_erupting = true

	if body:
		body.modulate = Color(1.3, 0.7, 1.9)
	await get_tree().create_timer(telegraph_time).timeout
	if not is_instance_valid(self) or not is_alive:
		return
	if body:
		var fade := create_tween()
		fade.tween_property(body, "modulate", Color.WHITE, 0.25)

	ShockwaveRing.spawn(self, global_position, shockwave_radius, shockwave_damage,
			Color(0.62, 0.35, 0.95), 0.4, "shadow")
	_erupting = false
