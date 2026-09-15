## SpellIcons - 法术图标程序化生成器（静态，带缓存）
## HUD 武器槽 / 升级卡用：128px 高清绘制，SDF 抗锯齿 + 徽章底 + 辉光光环。
## 形状沿用「攻击方式语义」：火球=圆球、闪电=折线、波=弧线、环绕=点环、光束=横线……
## 形状坐标沿用旧 32 空间定义，绘制时统一 ×SCALE 放大。
class_name SpellIcons
extends Object

## 输出尺寸（正方形）
const SIZE := 128
## 旧 32 空间 → 输出空间 缩放系数
const SCALE := 4.0

static var _cache := {}


## 获取法术图标（首次绘制后缓存；spell 用于兜底读元素色）
static func icon_for(spell_id: String, spell: Node = null) -> Texture2D:
	if _cache.has(spell_id):
		return _cache[spell_id]
	var element := ""
	if spell != null and "spell_element" in spell:
		element = str(spell.spell_element)
	var col := FxLib.color_for(element)
	var shapes: Array = []
	match spell_id:
		"magic_bolt":
			shapes = [
				{"kind": "diamond", "c": Vector2(16, 16), "r": 11.5, "col": col},
				{"kind": "diamond", "c": Vector2(16, 16), "r": 5.0, "col": Color(1, 1, 1, 0.95)},
			]
		"fireball":
			shapes = [
				{"kind": "circle", "c": Vector2(16, 17), "r": 10.5, "col": col},
				{"kind": "circle", "c": Vector2(13, 13.5), "r": 4.2, "col": Color(1.0, 0.88, 0.55)},
				{"kind": "circle", "c": Vector2(14.5, 15), "r": 2.2, "col": Color(1, 1, 0.92)},
			]
		"tidal_wave":
			shapes = [
				{"kind": "line", "a": Vector2(3, 21), "b": Vector2(10, 11), "w": 5.0, "col": col.darkened(0.12)},
				{"kind": "line", "a": Vector2(10, 11), "b": Vector2(17, 18), "w": 5.0, "col": col},
				{"kind": "line", "a": Vector2(17, 18), "b": Vector2(24, 9), "w": 5.0, "col": col.lightened(0.18)},
				{"kind": "line", "a": Vector2(24, 9), "b": Vector2(29, 14), "w": 5.0, "col": col.lightened(0.32)},
				{"kind": "circle", "c": Vector2(24, 9), "r": 2.6, "col": Color(1, 1, 1, 0.9)},
			]
		"chain_lightning":
			shapes = [
				{"kind": "line", "a": Vector2(20, 3), "b": Vector2(12, 14), "w": 4.0, "col": col},
				{"kind": "line", "a": Vector2(12, 14), "b": Vector2(20, 16), "w": 4.0, "col": col.lightened(0.2)},
				{"kind": "line", "a": Vector2(20, 16), "b": Vector2(12, 29), "w": 4.0, "col": col},
				{"kind": "circle", "c": Vector2(20, 3), "r": 2.6, "col": Color(1, 1, 1, 0.95)},
				{"kind": "circle", "c": Vector2(12, 29), "r": 2.2, "col": Color(1, 1, 1, 0.8)},
			]
		"frost_nova":
			shapes = [
				{"kind": "ring", "c": Vector2(16, 16), "r": 10.0, "w": 3.2, "col": col},
				{"kind": "ring", "c": Vector2(16, 16), "r": 4.0, "w": 2.6, "col": col.lightened(0.42)},
				{"kind": "circle", "c": Vector2(16, 6.5), "r": 1.6, "col": Color(1, 1, 1, 0.85)},
			]
		"meteor_strike":
			shapes = [
				{"kind": "line", "a": Vector2(7, 27), "b": Vector2(15, 18), "w": 4.6, "col": Color(1.0, 0.6, 0.25, 0.75)},
				{"kind": "circle", "c": Vector2(20, 13), "r": 8.4, "col": col},
				{"kind": "circle", "c": Vector2(17.5, 10.5), "r": 3.2, "col": Color(1.0, 0.9, 0.6)},
			]
		"pollen_bomb":
			shapes = [
				{"kind": "circle", "c": Vector2(11, 12), "r": 5.6, "col": col},
				{"kind": "circle", "c": Vector2(21, 12), "r": 5.6, "col": col.darkened(0.15)},
				{"kind": "circle", "c": Vector2(16, 21.5), "r": 5.6, "col": col.lightened(0.22)},
				{"kind": "circle", "c": Vector2(9.5, 10), "r": 1.8, "col": Color(1, 1, 1, 0.75)},
			]
		"shadow_bolt":
			shapes = [
				{"kind": "circle", "c": Vector2(15, 16), "r": 10.5, "col": col},
				{"kind": "erase", "c": Vector2(20.5, 11.5), "r": 8.0},
				{"kind": "circle", "c": Vector2(12, 12.5), "r": 2.8, "col": Color(0.85, 0.7, 1.0, 0.9)},
			]
		"thunderstorm":
			shapes = [
				{"kind": "circle", "c": Vector2(10.5, 11), "r": 5.0, "col": Color(0.82, 0.86, 1.0, 0.92)},
				{"kind": "circle", "c": Vector2(19.5, 9.5), "r": 6.0, "col": Color(0.88, 0.9, 1.0, 0.92)},
				{"kind": "circle", "c": Vector2(24, 14), "r": 4.2, "col": Color(0.8, 0.85, 1.0, 0.92)},
				{"kind": "line", "a": Vector2(17, 17), "b": Vector2(13, 22), "w": 3.6, "col": col.lightened(0.25)},
				{"kind": "line", "a": Vector2(13, 22), "b": Vector2(18, 23), "w": 3.6, "col": col},
				{"kind": "line", "a": Vector2(18, 23), "b": Vector2(14, 29), "w": 3.6, "col": col.lightened(0.35)},
			]
		"flame_wave":
			shapes = [
				{"kind": "tri", "a": Vector2(15, 4), "b": Vector2(5, 27), "c": Vector2(15, 20), "col": col.darkened(0.1)},
				{"kind": "tri", "a": Vector2(15, 4), "b": Vector2(27, 27), "c": Vector2(15, 20), "col": col.lightened(0.25)},
				{"kind": "circle", "c": Vector2(15, 8), "r": 2.4, "col": Color(1, 0.95, 0.8, 0.9)},
			]
		"ice_spike_array":
			shapes = [
				{"kind": "tri", "a": Vector2(4, 27), "b": Vector2(10, 9), "c": Vector2(16, 27), "col": col},
				{"kind": "tri", "a": Vector2(14, 27), "b": Vector2(22, 4), "c": Vector2(29, 27), "col": col.lightened(0.22)},
			]
		"orbit_orbs":
			shapes = [
				{"kind": "ring", "c": Vector2(16, 16), "r": 9.5, "w": 2.4, "col": col.darkened(0.08)},
				{"kind": "circle", "c": Vector2(16, 16) + Vector2(1, 0) * 9.5, "r": 3.8, "col": col.lightened(0.35)},
				{"kind": "circle", "c": Vector2(16, 16) + Vector2(-0.5, 0.866) * 9.5, "r": 3.8, "col": col.lightened(0.15)},
				{"kind": "circle", "c": Vector2(16, 16) + Vector2(-0.5, -0.866) * 9.5, "r": 3.8, "col": col.lightened(0.25)},
				{"kind": "circle", "c": Vector2(16, 16), "r": 2.6, "col": Color(1, 1, 1, 0.85)},
			]
		"arcane_beam":
			shapes = [
				{"kind": "line", "a": Vector2(3, 16), "b": Vector2(29, 16), "w": 6.4, "col": col},
				{"kind": "line", "a": Vector2(3, 16), "b": Vector2(29, 16), "w": 2.6, "col": Color(1, 1, 1, 0.95)},
				{"kind": "circle", "c": Vector2(16, 16), "r": 4.4, "col": col.lightened(0.35)},
			]
		_:
			# 未知 id：元素色菱形兜底
			shapes = [
				{"kind": "diamond", "c": Vector2(16, 16), "r": 11.5, "col": col},
				{"kind": "diamond", "c": Vector2(16, 16), "r": 4.6, "col": Color(1, 1, 1, 0.9)},
			]
	var tex := _paint_icon(shapes, col)
	_cache[spell_id] = tex
	return tex


# ---------- 高清绘制（SDF 抗锯齿 + 徽章 + 辉光） ----------

## 绘制一枚图标：暗紫徽章底 + 金环 + 元素色辉光 + 双色调图形
static func _paint_icon(shapes: Array, element_col: Color) -> Texture2D:
	var n := SIZE
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var center := Vector2(n, n) * 0.5
	var badge_r := n * 0.47

	for y in n:
		for x in n:
			var p := Vector2(x + 0.5, y + 0.5)
			var out := Color(0, 0, 0, 0)

			# 1) 徽章底：深紫圆盘 + 顶部微亮渐变
			var d_badge := p.distance_to(center) - badge_r
			var badge_a := clampf(0.5 - d_badge, 0.0, 1.0)
			if badge_a > 0.0:
				var t := clampf(p.y / n, 0.0, 1.0)
				var badge := Color(0.135, 0.105, 0.225, 0.94).lerp(Color(0.07, 0.055, 0.13, 0.94), t)
				badge.a *= badge_a
				out = badge

			# 2) 徽章金环
			var ring_d := absf(p.distance_to(center) - badge_r + 1.0)
			if ring_d < 2.0:
				var ring := Color(0.82, 0.68, 0.40, 0.95)
				ring.a *= clampf(0.5 - ring_d * 0.55, 0.0, 1.0)
				out = out.lerp(ring, ring.a)

			# 3) 图形辉光：到图形表面的距离 → 指数衰减光晕
			var sd := _min_sd(shapes, p)
			if sd > 0.8:
				var g := exp(-sd / (n * 0.085)) * 0.6
				if g > 0.01:
					var glow := Color(element_col.r, element_col.g, element_col.b, clampf(g, 0.0, 0.55))
					out = out.lerp(glow, glow.a * (1.0 - out.a * 0.3))

			# 4) 图形本体：最上层命中色 + 左上偏移高光（双色调）
			var hit := _topmost(shapes, p)
			if hit.a > 0.0:
				var hi := _topmost(shapes, p + Vector2(1.4, -1.4) * SCALE * 0.22)
				var c := hit
				if hi.a > 0.0:
					c = c.lerp(Color(1, 1, 1, hit.a), 0.30)
				out = out.lerp(c, c.a)

			img.set_pixel(x, y, out)
	return ImageTexture.create_from_image(img)


## 到全部图形表面的最小有符号距离（外正内负，忽略 erase）
static func _min_sd(shapes: Array, p: Vector2) -> float:
	var best := 1e9
	for sh in shapes:
		if sh.get("kind", "") == "erase":
			continue
		best = minf(best, _shape_sd(sh, p))
	return best

## 单个图形的 SDF
static func _shape_sd(sh: Dictionary, p: Vector2) -> float:
	var kind: String = sh.get("kind", "")
	match kind:
		"circle":
			return p.distance_to(sh["c"] * SCALE) - sh["r"] * SCALE
		"ring":
			return absf(p.distance_to(sh["c"] * SCALE) - sh["r"] * SCALE) - sh["w"] * SCALE * 0.5
		"line":
			var ab: Vector2 = sh["b"] * SCALE - sh["a"] * SCALE
			var ap: Vector2 = p - sh["a"] * SCALE
			var t := clampf(ap.dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
			return ap.distance_to(ab * t) - sh["w"] * SCALE * 0.5
		"diamond":
			var q: Vector2 = (p - sh["c"] * SCALE).abs()
			return (q.x + q.y - sh["r"] * SCALE) * 0.7071
		"tri":
			var a: Vector2 = sh["a"] * SCALE
			var b: Vector2 = sh["b"] * SCALE
			var c: Vector2 = sh["c"] * SCALE
			var d1 := _edge_dist(p, a, b)
			var d2 := _edge_dist(p, b, c)
			var d3 := _edge_dist(p, c, a)
			if _point_in_tri(p, a, b, c):
				return -minf(d1, minf(d2, d3))
			return minf(d1, minf(d2, d3))
	return 1e9

## 点到线段距离
static func _edge_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)

## 最上层命中颜色（顺序合成：erase 命中清空当前结果）
static func _topmost(shapes: Array, p: Vector2) -> Color:
	var hit := Color(0, 0, 0, 0)
	for sh in shapes:
		if sh.get("kind", "") == "erase":
			if p.distance_to(sh["c"] * SCALE) - sh["r"] * SCALE < 0.0:
				hit = Color(0, 0, 0, 0)
			continue
		if _shape_sd(sh, p) < 0.0:
			hit = sh.get("col", Color.WHITE)
	return hit

## 点是否在三角形内（叉积同号判定）
static func _point_in_tri(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 := _cross(p, a, b)
	var d2 := _cross(p, b, c)
	var d3 := _cross(p, c, a)
	var has_neg := (d1 < 0.0) or (d2 < 0.0) or (d3 < 0.0)
	var has_pos := (d1 > 0.0) or (d2 > 0.0) or (d3 > 0.0)
	return not (has_neg and has_pos)

static func _cross(p1: Vector2, p2: Vector2, p3: Vector2) -> float:
	return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
