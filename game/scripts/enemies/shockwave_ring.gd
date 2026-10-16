## ShockwaveRing - 敌方范围冲击波
## 由内向外扩散的伤害环，供三类敌人复用：
##   ember_crab 自爆（火光快扩）/ cursed_knight 暗影震波 / ember_lord 元素爆裂
## 职责：扩散期间只命中玩家一次（_hit_done 锁），环体贴图与碰撞半径同步长大。
## 生成入口统一走 spawn()：调用点常在物理回调里（接触自爆、受击死亡），
## 直接 add_child 会触发 "Can't change this state while flushing queries"，故延迟挂载。
class_name ShockwaveRing
extends Area2D

const RING_SCENE := preload("res://scenes/enemies/shockwave_ring.tscn")
const RING_TEXTURE := "res://assets/fx/ring_glow.png"
## 起波半径比例：从目标半径的这一成开始外扩，避免判定瞬间从 0 跳满
const START_EXPANSION := 0.18

## 冲击波参数（spawn 前赋值）
var radius: float = 140.0
var damage: float = 24.0
var expand_time: float = 0.3
var ring_color: Color = Color(0.62, 0.35, 0.95)
var caster: Node2D = null
var burst_element: String = ""  # 非空时命中点追加一次元素粒子
var spawn_pos: Vector2 = Vector2.ZERO

var _hit_done := false
var _shape: CircleShape2D
var _full_sprite_scale := Vector2.ONE

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ring_sprite: Sprite2D = $Ring

## 安全生成：pos 为爆炸中心（世界坐标）
static func spawn(from: Node, pos: Vector2, p_radius: float, p_damage: float,
		p_color: Color, p_expand_time: float = 0.3, p_element: String = "") -> void:
	var tree := from.get_tree()
	if tree == null or tree.current_scene == null:
		return
	var wave: ShockwaveRing = RING_SCENE.instantiate()
	wave.spawn_pos = pos
	wave.radius = p_radius
	wave.damage = p_damage
	wave.ring_color = p_color
	wave.expand_time = p_expand_time
	wave.burst_element = p_element
	wave.caster = from if from is Node2D else null
	tree.current_scene.add_child.call_deferred(wave)

func _ready() -> void:
	global_position = spawn_pos
	# 形状在代码里新建：.tscn 的 sub_resource 在同场景多个实例间共享，
	# 直接改 radius 会污染其它冲击波（与 enemy_base 放大碰撞前的 duplicate 同理）
	_shape = CircleShape2D.new()
	_shape.radius = radius * START_EXPANSION
	collision_shape.shape = _shape
	_full_sprite_scale = _build_visual()
	_apply_expansion(START_EXPANSION)

	# 扩散用 tween_method 直接改碰撞半径：不依赖"节点缩放是否作用于物理形状"
	# 这类跨版本行为，判定范围与视觉环严格同步。
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(_apply_expansion, START_EXPANSION, 1.0, expand_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring_sprite, "modulate:a", 0.0, expand_time + 0.18)
	tween.chain().tween_callback(queue_free)
	body_entered.connect(_on_body_entered)

## 按扩散比例同步碰撞半径与环贴图缩放
func _apply_expansion(t: float) -> void:
	_shape.radius = radius * t
	ring_sprite.scale = _full_sprite_scale * t

## 按目标半径换算环贴图缩放（贴图原始尺寸运行时取一次），返回扩散到位的最终缩放
func _build_visual() -> Vector2:
	var tex: Texture2D = load(RING_TEXTURE)
	if tex == null:
		return Vector2.ONE
	ring_sprite.texture = tex
	ring_sprite.modulate = Color(ring_color.r, ring_color.g, ring_color.b, 0.95)
	var size := Vector2(tex.get_size())
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ONE
	# y 向压扁 0.72：地面椭圆透视，与精英脚下光环同一套 2.5D 观感
	return Vector2((radius * 2.0) / size.x, (radius * 2.0 * 0.72) / size.y)

func _on_body_entered(body: Node2D) -> void:
	if _hit_done or not body.is_in_group("player"):
		return
	_hit_done = true
	if body.has_method("take_damage"):
		# 伤害归属记本环：自爆怪在起波同帧已 queue_free，caster 常为 null，
		# 记 caster 会让这跳伤害在玩家侧失去来源（元素/统计都取不到）
		body.take_damage(damage, self)
	if burst_element != "":
		FxLib.element_burst(self, body.global_position, burst_element, 1.0)
