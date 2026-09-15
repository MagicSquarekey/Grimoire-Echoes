## OrbitOrbVisual - 单颗环绕光球视觉（arcane 预设：蓝白光晕 + 微型拖尾）
## 纯视觉节点，位置由 OrbitOrbsController 每帧驱动。
extends Node2D

var orb_index: int = 0
var orb_total: int = 1

var _glow: Sprite2D
var _core: Sprite2D
var _trail: Line2D
var _pulse_tw: Tween


func _ready() -> void:
	var col := FxLib.color_for("arcane")
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	z_index = 3

	# 微型拖尾（6 点历史，控制器每帧改位置 → 自然甩出短尾）
	_trail = Line2D.new()
	_trail.material = mat
	_trail.width = 4.0
	_trail.modulate = Color(col.r, col.g, col.b, 0.5)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.0)])
	_trail.gradient = grad
	add_child(_trail)

	# 加法混合光晕
	_glow = Sprite2D.new()
	_glow.texture = load("res://assets/fx/glow_soft.png")
	_glow.material = mat
	_glow.modulate = Color(col.r, col.g, col.b, 0.85)
	_glow.scale = Vector2(0.55, 0.55)
	add_child(_glow)

	# 亮核
	_core = Sprite2D.new()
	_core.texture = load("res://assets/fx/spark.png")
	_core.modulate = Color(1.0, 0.96, 1.0, 0.95)
	_core.scale = Vector2(0.42, 0.42)
	add_child(_core)

	# 呼吸脉动
	var tw := create_tween().set_loops()
	tw.tween_property(_glow, "scale", Vector2(0.62, 0.62), randf_range(0.5, 0.8))
	tw.tween_property(_glow, "scale", Vector2(0.5, 0.5), randf_range(0.5, 0.8))


var _prev_pos := Vector2.INF


func _process(_delta: float) -> void:
	# 微型拖尾：记录世界坐标历史（≤6 点），回写局部坐标
	if _prev_pos == Vector2.INF:
		_prev_pos = global_position
		return
	if _trail == null:
		return
	var pts := _trail.points
	var local_prev := _prev_pos - global_position
	if pts.is_empty() or local_prev.length() > 3.0:
		pts.insert(0, local_prev)
	while pts.size() > 6:
		pts.remove_at(pts.size() - 1)
	_trail.points = pts
	_prev_pos = global_position


func set_damage(_dmg: float) -> void:
	pass  # 伤害由控制器持有，光球纯视觉


## 受击脉冲反馈
func pulse() -> void:
	if _pulse_tw and _pulse_tw.is_valid():
		_pulse_tw.kill()
	scale = Vector2(1.35, 1.35)
	_pulse_tw = create_tween()
	_pulse_tw.tween_property(self, "scale", Vector2.ONE, 0.18)
