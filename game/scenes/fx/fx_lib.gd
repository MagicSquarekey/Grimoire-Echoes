## FxLib - 特效工具库（静态，纯视觉）
## 统一提供：元素配色、命中爆裂/消散粒子的安全生成。
## 所有节点生成均延迟到帧末执行（call_deferred），避免在物理回调 flush 期间 add_child 报错。
## 生成的一次性粒子会自动 queue_free，不留残留节点。
class_name FxLib
extends Object

const HIT_BURST_SCENE_PATH := "res://scenes/fx/hit_burst.tscn"

## 元素 → 粒子运动模式（命中爆裂的形状差异）
## RISE=火星上飘  RADIAL=碎片放射  JITTER=抖动闪线  DRIFT=叶片旋转飘落  SINK=烟雾下沉
enum BurstMode { RADIAL, RISE, JITTER, DRIFT, SINK }

## 中心化元素特效预设：
##   color       主题色（拖尾/光晕/爆裂共用）
##   trail_width 拖尾线宽
##   glow_scale  弹体光晕缩放
##   trail_jitter 拖尾锯齿抖动幅度（lightning 专用，其余 0）
##   burst       爆裂参数包 {count,speed_min,speed_max,life,gravity,angular,damping,scale,mode}
const PRESETS := {
	"fire": {
		"color": Color(1.0, 0.5, 0.16), "trail_width": 8.0, "glow_scale": 1.05, "trail_jitter": 0.0,
		"burst": {"count": 14, "speed_min": 60.0, "speed_max": 150.0, "life": 0.5,
			"gravity": Vector2(0, -85), "angular": 0.0, "damping": 0.0, "scale": 1.25, "mode": BurstMode.RISE},
	},
	"water": {
		"color": Color(0.32, 0.78, 1.0), "trail_width": 9.0, "glow_scale": 1.1, "trail_jitter": 0.0,
		"burst": {"count": 13, "speed_min": 110.0, "speed_max": 210.0, "life": 0.38,
			"gravity": Vector2(0, 70), "angular": 0.0, "damping": 0.0, "scale": 1.0, "mode": BurstMode.RADIAL},
	},
	"ice": {
		"color": Color(0.65, 0.92, 1.0), "trail_width": 7.0, "glow_scale": 1.0, "trail_jitter": 0.0,
		"burst": {"count": 12, "speed_min": 120.0, "speed_max": 230.0, "life": 0.34,
			"gravity": Vector2(0, 90), "angular": 0.0, "damping": 0.0, "scale": 0.9, "mode": BurstMode.RADIAL},
	},
	"lightning": {
		"color": Color(0.82, 0.72, 1.0), "trail_width": 6.0, "glow_scale": 1.15, "trail_jitter": 3.5,
		"burst": {"count": 10, "speed_min": 170.0, "speed_max": 270.0, "life": 0.22,
			"gravity": Vector2.ZERO, "angular": 0.0, "damping": 420.0, "scale": 0.85, "mode": BurstMode.JITTER},
	},
	"shadow": {
		"color": Color(0.62, 0.35, 0.95), "trail_width": 10.0, "glow_scale": 1.2, "trail_jitter": 0.0,
		"burst": {"count": 11, "speed_min": 28.0, "speed_max": 80.0, "life": 0.62,
			"gravity": Vector2(0, 72), "angular": 0.0, "damping": 0.0, "scale": 1.6, "mode": BurstMode.SINK},
	},
	"arcane": {
		"color": Color(0.85, 0.45, 1.0), "trail_width": 8.0, "glow_scale": 1.0, "trail_jitter": 0.0,
		"burst": {"count": 12, "speed_min": 90.0, "speed_max": 170.0, "life": 0.4,
			"gravity": Vector2.ZERO, "angular": 0.0, "damping": 0.0, "scale": 1.0, "mode": BurstMode.RADIAL},
	},
	"nature": {
		"color": Color(0.45, 0.9, 0.5), "trail_width": 7.0, "glow_scale": 0.95, "trail_jitter": 0.0,
		"burst": {"count": 10, "speed_min": 30.0, "speed_max": 90.0, "life": 0.72,
			"gravity": Vector2(0, 52), "angular": 260.0, "damping": 0.0, "scale": 1.1, "mode": BurstMode.DRIFT},
	},
	"air": {
		"color": Color(0.72, 1.0, 0.78), "trail_width": 6.0, "glow_scale": 0.95, "trail_jitter": 0.0,
		"burst": {"count": 10, "speed_min": 70.0, "speed_max": 150.0, "life": 0.4,
			"gravity": Vector2(0, -40), "angular": 160.0, "damping": 0.0, "scale": 1.0, "mode": BurstMode.DRIFT},
	},
}
const _DEFAULT_PRESET := {
	"color": Color(1.0, 0.86, 0.55), "trail_width": 8.0, "glow_scale": 1.0, "trail_jitter": 0.0,
	"burst": {"count": 12, "speed_min": 90.0, "speed_max": 170.0, "life": 0.4,
		"gravity": Vector2.ZERO, "angular": 0.0, "damping": 0.0, "scale": 1.0, "mode": BurstMode.RADIAL},
}


## 元素 → 主题色（弹体拖尾/光晕/爆裂共用一套配色）
static func color_for(element: String) -> Color:
	match element:
		"fire":
			return Color(1.0, 0.5, 0.16)
		"water":
			return Color(0.32, 0.78, 1.0)
		"lightning":
			return Color(0.82, 0.72, 1.0)
		"shadow":
			return Color(0.62, 0.35, 0.95)
		"arcane":
			return Color(0.85, 0.45, 1.0)
		"air", "wind":
			return Color(0.72, 1.0, 0.78)
		"nature":
			return Color(0.45, 0.9, 0.5)
		"ice":
			return Color(0.65, 0.92, 1.0)
		_:
			return Color(1.0, 0.86, 0.55)


## 元素 → 完整特效预设（缺失元素回退 arcane 标准样式）
static func preset_for(element: String) -> Dictionary:
	return PRESETS.get(element, PRESETS["arcane"])


## 按元素预设生成命中爆裂（自动带颜色/粒子数/速度/重力/自旋/阻尼）。
## scale_mul 可整体缩放粒子数量与速度（小体量命中用 0.6，大爆炸用 1.5）。
static func element_burst(from: Node, pos: Vector2, element: String, scale_mul: float = 1.0) -> void:
	var p := preset_for(element)
	var b: Dictionary = p["burst"]
	hit_burst(
		from, pos, p["color"],
		int(maxf(3.0, b["count"] * scale_mul)),
		b["speed_min"] * scale_mul, b["speed_max"] * scale_mul,
		b["life"], b["gravity"], null,
		b["angular"], b["damping"], b["scale"]
	)


## 命中爆裂：在 pos 处生成一次性粒子爆裂（自动清理）。
## from 仅用于定位场景树，可传弹体/敌人等任意在树节点。
static func hit_burst(
	from: Node,
	pos: Vector2,
	color: Color,
	count: int = 12,
	speed_min: float = 90.0,
	speed_max: float = 170.0,
	life: float = 0.4,
	gravity: Vector2 = Vector2.ZERO,
	parent_override: Node = null,
	angular_max: float = 0.0,
	damping: float = 0.0,
	particle_scale: float = 1.0
) -> void:
	var host := parent_override
	if host == null:
		host = _resolve_host(from)
	if host == null:
		return
	var spawn := func():
		# 延迟执行期间宿主可能已被释放（切场景/回收），先校验
		if not is_instance_valid(host) or not host.is_inside_tree():
			return
		var scene: PackedScene = load(HIT_BURST_SCENE_PATH)
		if scene == null:
			return
		var burst := scene.instantiate()
		host.add_child(burst)
		burst.emit_burst(pos, color, count, speed_min, speed_max, life, gravity,
				angular_max, damping, particle_scale)
	spawn.call_deferred()


## 敌人死亡消散：暗色主题粒子向上飘散（在 enemy_base 死亡动画处一行调用）
static func death_dissipate(enemy: Node) -> void:
	if enemy == null or not enemy.is_inside_tree():
		return
	var pos: Vector2 = enemy.global_position + Vector2(0, -6)
	hit_burst(enemy, pos, Color(0.5, 0.34, 0.68, 0.9), 9, 24.0, 72.0, 0.55, Vector2(0, -46))


## 出生传送门：敌人生成瞬间的主题色光圈收缩（0.3s，纯视觉，自动清理）。
## 用现成 ring_glow.png 单精灵 tween 实现，生成开销极低（每敌 1 节点 0.3 秒）。
static func spawn_portal(from: Node, pos: Vector2, color: Color = Color(0.62, 0.35, 0.95)) -> void:
	var host := _resolve_host(from)
	if host == null:
		return
	var spawn := func():
		# 延迟执行期间宿主可能已被释放（切场景），先校验
		if not is_instance_valid(host) or not host.is_inside_tree():
			return
		var tex: Texture2D = load("res://assets/fx/ring_glow.png")
		if tex == null:
			return
		var ring := Sprite2D.new()
		ring.texture = tex
		ring.position = pos
		ring.modulate = Color(color.r, color.g, color.b, 0.9)
		ring.scale = Vector2(1.15, 0.75)
		ring.rotation = randf() * TAU
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		ring.material = mat
		host.add_child(ring)
		var tw := ring.create_tween()
		tw.set_parallel(true)
		tw.tween_property(ring, "scale", Vector2(0.1, 0.065), 0.3) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(ring, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(ring.queue_free)
	spawn.call_deferred()


## 解析特效宿主：优先游戏场景的 Effects 容器，兜底 current_scene
static func _resolve_host(from: Node) -> Node:
	if from == null or not from.is_inside_tree():
		return null
	var cs := from.get_tree().current_scene
	if cs == null:
		return null
	var fx := cs.get_node_or_null("Effects")
	return fx if fx != null else cs
