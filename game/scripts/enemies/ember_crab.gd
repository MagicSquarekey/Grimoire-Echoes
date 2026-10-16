## EmberCrab - 熔壳爆虫（E8，预警自爆）
## 快速冲脸 → 进入 78px 后停住点燃引信 1.15s（身体高频闪橙 + 地面预警环）→ 引爆。
## 反制窗口明确：引信期间它不移动，玩家走位或提前击杀都不会炸；
## 击杀（而非等它炸）才拿到经验，所以它是"要么早杀要么吃一发"的读条怪。
class_name EmberCrab
extends EnemyBase

@export var trigger_distance: float = 78.0
@export var fuse_time: float = 1.15
@export var blast_radius: float = 132.0
@export var blast_damage: float = 30.0

var _fusing := false

func _init() -> void:
	enemy_name = "熔壳爆虫"
	enemy_type = "exploder"
	max_health = 18.0
	attack_damage = blast_damage   # 伤害只在爆炸里用，接触不结算
	move_speed = 150.0
	exp_reward = 8
	gold_reward = 1

func _process_ai(delta: float) -> void:
	if _fusing:
		return
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
	if distance < trigger_distance:
		_start_fuse()
		return

	velocity = (target.global_position - global_position).normalized() * move_speed
	move_and_slide()

func _process_attack(delta: float) -> void:
	_process_chase(delta)

## 引信：定身 + 高频闪橙 + 预警环，时间到才炸
func _start_fuse() -> void:
	_fusing = true
	velocity = Vector2.ZERO
	move_and_slide()

	if body:
		var pulse := create_tween()
		pulse.set_loops(4)
		pulse.tween_property(body, "modulate", Color(1.9, 0.75, 0.25), fuse_time / 8.0)
		pulse.tween_property(body, "modulate", Color(1.0, 0.35, 0.1), fuse_time / 8.0)
	# 地面预警环：引信期间从 0.35 涨到满半径，玩家一眼看到爆炸范围
	_add_detonation_telegraph()

	await get_tree().create_timer(fuse_time).timeout
	if not is_instance_valid(self) or not is_alive:
		return
	_detonate()

## 预警环（纯视觉）：复用 FxLib 出生门的环形贴图，引信结束自动清理
func _add_detonation_telegraph() -> void:
	var host := get_tree().current_scene
	if host == null:
		return
	var tex: Texture2D = load("res://assets/fx/ring_glow.png")
	if tex == null:
		return
	var size := Vector2(tex.get_size())
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var ring := Sprite2D.new()
	ring.texture = tex
	ring.z_index = -1
	ring.modulate = Color(1.0, 0.45, 0.15, 0.8)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ring.material = mat
	add_child(ring)
	ring.scale = Vector2(0.35, 0.35 * 0.72)
	var full_ring := Vector2((blast_radius * 2.0) / size.x, (blast_radius * 2.0 * 0.72) / size.y)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", full_ring, fuse_time)
	tween.tween_property(ring, "modulate:a", 0.95, fuse_time)

## 引爆：一次性冲击波（命中玩家一次）后自己殉爆
func _detonate() -> void:
	ShockwaveRing.spawn(self, global_position, blast_radius, blast_damage,
			Color(1.0, 0.45, 0.15), 0.22, "fire")
	_die()
