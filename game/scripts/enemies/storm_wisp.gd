## StormWisp - 雷电游散（E7，浮空连锁闪电）
## 浮空远程：与玩家保持 ~250px 距离绕行，冷却到点释放一道闪电。
## 连锁实现：自身为起点，就近最多 2 只"导体"友军（其它雷电游散）逐级中继到玩家，
##          每级伤害按 DamageCalculator.calculate_chain_damage 递减后合并为一击结算
##          ——玩家有 0.5s 无敌帧，多发分头命中会被无敌帧吞掉，合并成一击才是真实威胁。
## 索敌用 allies_in_radius 单次形状查询，只在冷却到点时执行（见 enemy_base.gd 性能说明）。
class_name StormWisp
extends EnemyBase

const CONDUIT_GROUP := "storm_conduit"
const CHAIN_DECAY := 0.45  # 每级中继伤害递减 45%（与玩家连锁闪电同一递减口径）

@export var attack_range: float = 260.0
@export var chain_range: float = 240.0
@export var max_extra_targets: int = 2
@export var attack_cooldown: float = 2.2

var _attack_timer := 1.2
var _orbit_phase := 0.0

func _init() -> void:
	enemy_name = "雷电游散"
	enemy_type = "ranged"
	max_health = 18.0
	attack_damage = 10.0
	move_speed = 130.0
	exp_reward = 12
	gold_reward = 2

func _ready() -> void:
	super()
	add_to_group(CONDUIT_GROUP)

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

	if global_position.distance_to(target.global_position) <= attack_range:
		current_ai_state = AIState.ATTACK
		return

	velocity = (target.global_position - global_position).normalized() * move_speed
	move_and_slide()

## 攻击：绕圈走位 + 冷却到点放电
func _process_attack(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.CHASE
		return

	var to_target = target.global_position - global_position
	if to_target.length() > attack_range * 1.3:
		current_ai_state = AIState.CHASE
		return

	# 保持距离的切向绕行（浮空单位特有的不稳定感）
	_orbit_phase += delta * 1.6
	velocity = to_target.normalized().orthogonal() * move_speed * 0.55 \
			+ to_target.normalized() * sin(_orbit_phase) * 30.0
	move_and_slide()

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_discharge()
		_attack_timer = attack_cooldown

## 放电：串连最多 2 只导体友军，合并伤害一次命中玩家
func _discharge() -> void:
	if not target or not is_instance_valid(target):
		return

	var conduits: Array[Node2D] = []
	for ally in allies_in_radius(chain_range, 16):
		if conduits.size() >= max_extra_targets:
			break
		if ally.is_in_group(CONDUIT_GROUP):
			conduits.append(ally)

	# 伤害序列 [本体, 中继1, 中继2] 求和 = 本次放电总伤害
	var steps: Array = DamageCalculator.calculate_chain_damage(attack_damage, conduits.size(), CHAIN_DECAY)
	var total := 0.0
	for step in steps:
		total += float(step)

	# 折线：自身 → 各导体 → 玩家，逐段画锯齿闪线
	var points: Array[Vector2] = [global_position]
	for conduit in conduits:
		points.append(conduit.global_position)
		FxLib.element_burst(conduit, conduit.global_position, "lightning", 0.5)
	points.append(target.global_position)
	for i in range(points.size() - 1):
		_draw_bolt(points[i], points[i + 1])

	if target.has_method("take_damage"):
		target.take_damage(total, self)
	FxLib.element_burst(self, target.global_position, "lightning", 0.9)

## 单段闪电视觉：加法混合折线 + 0.12s 抖动渐隐自毁（与玩家连锁闪电同一观感）
func _draw_bolt(from_pos: Vector2, to_pos: Vector2) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var col := FxLib.color_for("lightning")
	var bolt := Line2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	bolt.material = mat
	bolt.width = 5.0
	bolt.modulate = Color(col.r, col.g, col.b, 0.95)
	bolt.joint_mode = Line2D.LINE_JOINT_ROUND
	var segments := maxi(4, int(from_pos.distance_to(to_pos) / 30.0))
	var step := (to_pos - from_pos) / float(segments)
	var perpendicular := step.normalized().orthogonal()
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var p := from_pos + step * float(i)
		if i > 0 and i < segments:
			p += perpendicular * randf_range(-12.0, 12.0)
		pts.append(p)
	bolt.points = pts
	scene_root.add_child(bolt)

	var tween := bolt.create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, 0.12)
	tween.tween_callback(bolt.queue_free)
