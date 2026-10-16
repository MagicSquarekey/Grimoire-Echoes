## EnemyProjectile - 敌方投射物（通用弹体）
## 职责：直线飞行命中玩家本体结算伤害，与玩家弹体（Projectile）互为极性镜像。
##   1. collision_layer=8(EnemyProjectiles) / collision_mask=1(Player)
##   2. 视觉沿用玩家弹体一套语言：拖尾(TrailFx) + 元素光晕(FxLib 预设染色) + 地面阴影
##   3. 不发射 EventBus.spell_hit —— 那是玩家吸血的钩子，敌方弹体发出来等于玩家挨打回血
## 扩展字段 plague_stacks > 0 时命中额外给玩家叠加瘟疫（plague_spitter 使用）。
class_name EnemyProjectile
extends Area2D

## 弹体参数（由发射方在 add_child 前赋值，_ready 里统一染色）
var damage: float = 10.0
var speed: float = 320.0
var direction: Vector2 = Vector2.RIGHT
var element: String = "shadow"
var lifetime: float = 2.4
var caster: Node2D = null
## 瘟疫叠层：命中后附加到玩家身上的中毒层数/单跳伤害/持续时间
var plague_stacks: int = 0
var plague_tick_damage: float = 4.0
var plague_duration: float = 4.0
## 出生点：弹体在物理回调里延迟挂载，位置只能在入树时落定
var start_pos: Vector2 = Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _remaining: float = 0.0

func _ready() -> void:
	global_position = start_pos
	_remaining = lifetime
	rotation = direction.angle()
	_apply_element_style()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta * GameManager.speed_multiplier
	_remaining -= delta
	if _remaining <= 0.0:
		_expire()

## 按 FxLib 元素预设染色（与玩家弹体共用一套配色/线宽/光晕尺寸）
func _apply_element_style() -> void:
	var preset: Dictionary = FxLib.preset_for(element)
	var col: Color = preset["color"]
	# 2.5D 飞行高度：视觉体抬升 8px（抵消弹体自转），阴影留在节点原位
	var lift := Vector2(0, -8).rotated(-rotation)
	for visual_name in ["Sprite2D", "Glow", "Trail"]:
		var visual := get_node_or_null(visual_name)
		if visual is Node2D:
			(visual as Node2D).position = lift
	var shadow := get_node_or_null("Shadow")
	if shadow is Node2D:
		(shadow as Node2D).position = Vector2(0, 2).rotated(-rotation)
	var glow := get_node_or_null("Glow")
	if glow:
		glow.modulate = Color(col.r, col.g, col.b, 0.9)
		glow.scale = Vector2.ONE * maxf(0.45, preset["glow_scale"] * 0.7)
	var core := get_node_or_null("Sprite2D")
	if core:
		core.modulate = Color(1.0, 1.0, 1.0, 0.95).lerp(col, 0.45)
	var trail := get_node_or_null("Trail")
	if trail and trail.has_method("reset_trail"):
		trail.modulate = Color(col.r, col.g, col.b, 1.0)
		trail.width = preset["trail_width"] * 0.75
		if "jitter" in trail:
			trail.jitter = preset["trail_jitter"]
		trail.reset_trail()

## 命中玩家：伤害 + 可选瘟疫
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if plague_stacks > 0:
		var dot := PlagueDot.attach_from(self)
		if dot:
			dot.add_stack(plague_tick_damage, plague_duration, plague_stacks)
	if body.has_method("take_damage"):
		body.take_damage(damage, caster)
	FxLib.element_burst(self, global_position, element, 0.8)
	_destroy()

func _expire() -> void:
	_destroy()

func _destroy() -> void:
	collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
