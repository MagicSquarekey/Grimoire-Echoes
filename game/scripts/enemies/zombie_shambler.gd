## ZombieShambler - 僵尸（E13，迟缓潮怪 / 会再爬起来一次）
## 又慢又厚，靠数量堆线；被打倒一次不会真的死：倒下 1.3s（期间免伤、不结算击杀）
## 后以 35% 生命重新站起来继续追。波次存活数只在真正死亡时扣，所以"倒下"不会让波次提前结束。
## 玩家反制：光顾着清别的东西会被它站起来再咬，最好用爆发一口气打死。
class_name ZombieShambler
extends EnemyBase

@export var collapse_time: float = 1.3
@export var revive_ratio: float = 0.35   # 复活后的生命比例
@export var attack_interval: float = 1.5

var _risen := false
var _collapse_timer := 0.0
var _attack_timer := 0.0

func _init() -> void:
	enemy_name = "僵尸"
	enemy_type = "horde"
	max_health = 45.0
	attack_damage = 7.0
	move_speed = 55.0
	exp_reward = 8
	gold_reward = 1

func _process_ai(delta: float) -> void:
	if _collapse_timer > 0.0:
		_collapse_timer -= delta
		velocity = Vector2.ZERO
		if _collapse_timer <= 0.0:
			_rise()
		return
	super(delta)

## 倒下期间免伤：既不会被顺手补掉，也不会被反复重置复活计时
func take_damage(damage: float, attacker = null) -> void:
	if _collapse_timer > 0.0:
		return
	super(damage, attacker)

## 第一次被击杀 → 倒下；第二次 → 走基类真正死亡（经验/掉落/波次计数）
func _die() -> void:
	if _risen:
		super._die()
		return
	# 不调用 super._die()：is_alive 必须保持 true，否则 _physics_process 直接 return，
	# 复活计时无人推进，WaveManager 也会提前扣掉这只僵尸的存活数
	_risen = true
	current_health = 0.0
	_attack_timer = 0.0
	if body:
		body.modulate = Color(0.5, 0.46, 0.5, 0.62)
	FxLib.element_burst(self, global_position, "shadow", 0.6)
	_collapse_timer = collapse_time

func _rise() -> void:
	current_health = max_health * revive_ratio
	current_ai_state = AIState.CHASE
	if body:
		var tween := create_tween()
		tween.tween_property(body, "modulate", Color.WHITE, 0.35)
	FxLib.element_burst(self, global_position, "shadow", 0.8)

## 贴脸慢咬（基类 _process_attack 是空实现，必须自己接管）
func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return
	if global_position.distance_to(target.global_position) > 62.0:
		current_ai_state = AIState.CHASE
		return

	velocity = Vector2.ZERO
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		if target.has_method("take_damage"):
			target.take_damage(attack_damage, self)
