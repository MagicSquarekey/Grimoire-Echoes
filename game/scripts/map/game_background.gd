## GameBackground - 主题化无限游戏地面背景
## 无限跟随：节点吸附对齐相机中心（32px 网格），_draw 以节点位置为原点绘制
## 「可视区域 + 边距」内的内容，任何位置都不会看到地面边界。
## 世界锚定：细纹平铺对齐世界网格；斑块 / 装饰 / 地标均由「世界坐标 cell 的
## 确定性哈希」决定，相机移动时地面图案连续稳定，不随背景节点移动而漂移。
## 装饰只按可视范围 + 边距内的 cell 生成，draw 调用数恒定，性能稳定。
## 全部程序化生成，GL Compatibility 兼容
## （不用 GradientTexture2D 径向填充——该后端下会渲染成纯白色）。
extends Node2D

## 主题调色板（按 map_id 映射；不改动地图资源结构，加载逻辑零影响）
## base: 地面基调  tone_a/tone_b: 噪点暗纹两色  grid: 网格线色
## decor: 装饰主色  glow: 少量亮点点缀  vignette: 边缘压暗强度
## decor_mix: 小装饰权重 [草丛/荆棘, 碎石, 裂纹, 光点, 符文]
const PALETTES := {
	"forest": {
		"base": Color(0.078, 0.128, 0.088),
		"tone_a": Color(0.060, 0.104, 0.070),
		"tone_b": Color(0.108, 0.170, 0.110),
		"grid": Color(0.55, 0.70, 0.55, 0.045),
		"decor": Color(0.185, 0.320, 0.165, 0.62),
		"glow": Color(0.85, 0.78, 0.42, 0.38),
		"vignette": 0.40,
		"decor_mix": [0.42, 0.18, 0.08, 0.22, 0.10],
	},
	"lava": {
		"base": Color(0.135, 0.072, 0.064),
		"tone_a": Color(0.106, 0.055, 0.050),
		"tone_b": Color(0.185, 0.100, 0.086),
		"grid": Color(0.75, 0.50, 0.42, 0.045),
		"decor": Color(0.380, 0.125, 0.070, 0.58),
		"glow": Color(0.850, 0.320, 0.110, 0.48),
		"vignette": 0.44,
		"decor_mix": [0.05, 0.20, 0.38, 0.27, 0.10],
	},
	"ice": {
		"base": Color(0.102, 0.140, 0.195),
		"tone_a": Color(0.080, 0.112, 0.158),
		"tone_b": Color(0.150, 0.196, 0.258),
		"grid": Color(0.62, 0.75, 0.90, 0.05),
		"decor": Color(0.430, 0.610, 0.790, 0.42),
		"glow": Color(0.800, 0.900, 1.000, 0.42),
		"vignette": 0.38,
		"decor_mix": [0.06, 0.16, 0.30, 0.34, 0.14],
	},
	"altar": {
		"base": Color(0.150, 0.128, 0.088),
		"tone_a": Color(0.125, 0.107, 0.074),
		"tone_b": Color(0.196, 0.166, 0.116),
		"grid": Color(0.85, 0.75, 0.50, 0.055),
		"decor": Color(0.620, 0.520, 0.295, 0.48),
		"glow": Color(0.940, 0.800, 0.450, 0.42),
		"vignette": 0.36,
		"decor_mix": [0.12, 0.22, 0.12, 0.24, 0.30],
	},
	"shadow_realm": {
		"base": Color(0.090, 0.067, 0.152),
		"tone_a": Color(0.071, 0.053, 0.124),
		"tone_b": Color(0.128, 0.090, 0.210),
		"grid": Color(0.60, 0.50, 0.85, 0.05),
		"decor": Color(0.355, 0.235, 0.575, 0.52),
		"glow": Color(0.620, 0.480, 0.950, 0.42),
		"vignette": 0.48,
		"decor_mix": [0.16, 0.10, 0.16, 0.34, 0.24],
	},
}

## 兜底调色板（未知 map_id / 未开始游戏时）：与 UI 一致的深蓝紫夜色
const FALLBACK := {
	"base": Color(0.080, 0.068, 0.140),
	"tone_a": Color(0.064, 0.054, 0.112),
	"tone_b": Color(0.116, 0.097, 0.192),
	"grid": Color(0.60, 0.60, 0.85, 0.045),
	"decor": Color(0.320, 0.272, 0.550, 0.46),
	"glow": Color(0.940, 0.800, 0.450, 0.36),
	"vignette": 0.42,
	"decor_mix": [0.20, 0.20, 0.15, 0.25, 0.20],
}

## 可视区外额外绘制的边距（px）：吸收相机与背景节点吸附对齐的误差
const MARGIN := 160.0
## 背景节点位置吸附网格（px）：相机跨格才重绘；期间内容世界锚定，无抖动
const SNAP := 32.0
## 各层网格尺寸（世界 px）：patch 大尺度明暗 / blob 中尺度色斑 / decor 小装饰
const CELL_PATCH := 520.0
const CELL_BLOB := 240.0
const CELL_DECOR := 120.0
## 地标级装饰网格（世界 px）：间隔大、醒目但低饱和
const CELL_LANDMARK := 1150.0
## 极淡网格间距（替代原先明显的定位网格）
const GRID_SPACING := 160.0
## 地面细纹平铺周期（世界 px）与纹理边长（纹理像素）
const GRAIN_TILE := 512.0
const GRAIN_TEX := 128
## 出生点（与 player.gd 固定出生位置一致），用于出生魔法阵装饰
const SPAWN_POS := Vector2(960, 540)

## 当前地图 id（决定地标样式）
var _map_id := ""
## 当前调色板
var _palette: Dictionary = FALLBACK
## 地图种子（所有世界坐标哈希混入，保证同地图观感稳定、跨地图不同）
var _seed: int = 0
## 地面细纹纹理（无缝平铺，世界对齐）
var _grain_tex: ImageTexture = null
## 边缘暗角纹理（一次性生成；不用 GradientTexture2D 径向填充，
## GL Compatibility 下会整块渲染成白色）
var _vignette_tex: ImageTexture = null
## 细纹各倍频程的环绕晶格随机值（预生成，避免逐像素哈希开销）
var _lattices: Array = []
## 主题派生色
var _stone_light := Color(0.46, 0.44, 0.41, 0.85)
var _stone_dark := Color(0.14, 0.13, 0.12, 0.9)
var _crack_col := Color(0.1, 0.1, 0.1, 0.55)
## 相机中心（= 节点全局位置，吸附到 SNAP 网格）与可视世界尺寸
var _cam_center := Vector2(960, 540)
var _vis_size := Vector2(1280, 720)
var _last_snap := Vector2(1e12, 1e12)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	apply_map(GameManager.current_map if GameManager.current_map != "" else "")
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _process(_delta: float) -> void:
	# 节点吸附对齐相机中心；跨吸附格才重绘（draw 调用数恒定，开销可控）
	var center := _get_cam_center()
	var snap := Vector2(floorf(center.x / SNAP), floorf(center.y / SNAP)) * SNAP
	if snap != _last_snap:
		_last_snap = snap
		_cam_center = snap
		global_position = _cam_center
		queue_redraw()
	var vis := _get_vis_size()
	if vis != _vis_size:
		_vis_size = vis
		queue_redraw()


## 应用地图主题（map_id 为空时用兜底夜色）
func apply_map(map_id: String) -> void:
	_map_id = map_id
	_palette = PALETTES.get(map_id, FALLBACK)
	_seed = hash(map_id if map_id != "" else "arcane_night")
	_update_derived_colors()
	_rebuild_textures()
	queue_redraw()


func _on_viewport_size_changed() -> void:
	_vis_size = _get_vis_size()
	queue_redraw()


## 主题派生色：碎石明暗面 / 裂纹色（由调色板混灰生成，随主题微调）
func _update_derived_colors() -> void:
	var tb: Color = _palette.tone_b
	_stone_light = Color(0.46, 0.44, 0.41).lerp(tb, 0.35)
	_stone_light.a = 0.85
	_stone_dark = Color(0.14, 0.13, 0.12).lerp(_palette.base, 0.5)
	_stone_dark.a = 0.9
	_crack_col = tb.darkened(0.25)
	_crack_col.a = 0.55


## 生成细纹平铺纹理与暗角纹理（换图时一次性重建）
func _rebuild_textures() -> void:
	_grain_tex = _make_grain_texture()
	_vignette_tex = _make_vignette_texture()


# ---------------------------------------------------------------------------
# 世界坐标工具
# ---------------------------------------------------------------------------

## 世界坐标 → 节点本地坐标（节点全局位置 = _cam_center）
func _w(world: Vector2) -> Vector2:
	return world - _cam_center


## 当前实际可视世界区域中心（含相机平滑/伸缩后的真实画面中心）
func _get_cam_center() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return _cam_center
	var ct := vp.get_canvas_transform()
	return ct.affine_inverse() * (Vector2(vp.get_visible_rect().size) * 0.5)


## 当前可视世界区域尺寸（画布基准尺寸 / 画布缩放，缩放含相机 zoom）
func _get_vis_size() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return _vis_size
	var ct := vp.get_canvas_transform()
	var s := ct.get_scale()
	var base := Vector2(vp.get_visible_rect().size)
	if s.x <= 0.0001 or s.y <= 0.0001:
		return base
	return base / Vector2(s.x, s.y)


## 确定性 32 位整数哈希 → [0,1)：所有世界锚定内容的随机源
func _ch(x: int, y: int, salt: int) -> float:
	var h := _u32(x * 374761393) ^ _u32(y * 668265263) ^ _u32(salt * 2246822519) ^ _u32(_seed)
	h = _u32(h ^ (h >> 13))
	h = _u32(h * 1274126177)
	h = _u32(h ^ (h >> 16))
	return float(h) / 4294967296.0


func _u32(v: int) -> int:
	return v & 0xFFFFFFFF


# ---------------------------------------------------------------------------
# 细纹平铺纹理（无缝循环：环绕晶格值噪声）
# ---------------------------------------------------------------------------

func _make_grain_texture() -> ImageTexture:
	_lattices.clear()
	var octaves := [[3, 0.42], [6, 0.28], [12, 0.18], [24, 0.12]]
	for oc in octaves:
		var p: int = oc[0]
		var lat := PackedFloat32Array()
		lat.resize(p * p)
		for y in p:
			for x in p:
				lat[y * p + x] = _ch(x, y, 60 + p)
		_lattices.append({"p": p, "w": oc[1], "lat": lat})

	var n := GRAIN_TEX
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var tone_a: Color = _palette.tone_a
	var tone_b: Color = _palette.tone_b
	for y in n:
		for x in n:
			var f := 0.0
			for lat_d in _lattices:
				f += _sample_lattice(lat_d, float(x) / float(n), float(y) / float(n)) * float(lat_d["w"])
			var c := tone_a.lerp(tone_b, clampf(f, 0.0, 1.0))
			# 逐像素微颗粒：细碎明暗点，增强近看质感
			var sp := _ch(x, y, 77)
			if sp > 0.965:
				c = c.lightened(0.10)
			elif sp < 0.02:
				c = c.darkened(0.12)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## 采样一个环绕晶格（晶格在 period 处 wrap，保证平铺无缝）
func _sample_lattice(lat_d: Dictionary, u: float, v: float) -> float:
	var p: int = lat_d["p"]
	var lat: PackedFloat32Array = lat_d["lat"]
	var fx := u * float(p)
	var fy := v * float(p)
	var xi := floori(fx)
	var yi := floori(fy)
	var xf := fx - float(xi)
	var yf := fy - float(yi)
	var su := xf * xf * (3.0 - 2.0 * xf)
	var sv := yf * yf * (3.0 - 2.0 * yf)
	var x0 := posmod(xi, p)
	var y0 := posmod(yi, p)
	var x1 := (x0 + 1) % p
	var y1 := (y0 + 1) % p
	var a := lat[y0 * p + x0]
	var b := lat[y0 * p + x1]
	var c := lat[y1 * p + x0]
	var d := lat[y1 * p + x1]
	return lerpf(lerpf(a, b, su), lerpf(c, d, su), sv)


## 边缘暗角：小图逐像素算径向透明度，再平滑放大（兼容所有渲染后端）
func _make_vignette_texture() -> ImageTexture:
	var vw := 160
	var vh := 90
	var vimg := Image.create(vw, vh, false, Image.FORMAT_RGBA8)
	var vcenter := Vector2(vw / 2.0, vh / 2.0)
	var max_d := vcenter.length()
	for y in range(vh):
		for x in range(vw):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(vcenter) / max_d
			var k := clampf((d - 0.52) / 0.48, 0.0, 1.0)
			vimg.set_pixel(x, y, Color(0.01, 0.005, 0.03, _palette.vignette * k * k))
	vimg.resize(1920, 1080, Image.INTERPOLATE_CUBIC)
	return ImageTexture.create_from_image(vimg)


# ---------------------------------------------------------------------------
# 绘制
# ---------------------------------------------------------------------------

func _draw() -> void:
	var half := _vis_size * 0.5
	var wr := Rect2(_cam_center - half - Vector2(MARGIN, MARGIN),
			_vis_size + Vector2(MARGIN, MARGIN) * 2.0)

	# 1. 地面基调
	draw_rect(Rect2(_w(wr.position), wr.size), _palette.base)

	# 2. 细纹平铺（世界网格对齐 + 无缝循环，相机移动时图案连续稳定）
	if _grain_tex:
		var gpos := Vector2(
				floorf(wr.position.x / GRAIN_TILE),
				floorf(wr.position.y / GRAIN_TILE)) * GRAIN_TILE
		var gsize := Vector2(
				ceilf((wr.end.x - gpos.x) / GRAIN_TILE),
				ceilf((wr.end.y - gpos.y) / GRAIN_TILE)) * GRAIN_TILE
		draw_texture_rect(_grain_tex, Rect2(_w(gpos), gsize), true)

	# 3. 大尺度明暗 / 主题色渐变斑块
	_draw_patches(wr)

	# 4. 中尺度色块斑（明暗两层，加厚地面层次）
	_draw_blobs(wr)

	# 5. 极淡网格线（世界对齐，弱空间参照）
	_draw_grid(wr)

	# 6. 小装饰：草丛 / 碎石 / 裂纹 / 光点 / 符文（世界 cell 哈希分布）
	_draw_decor(wr)

	# 7. 地标级装饰（大树影 / 熔岩裂缝带 / 冰面反光 / 石阵 / 暗影裂隙）
	_draw_landmarks(wr)

	# 8. 出生点魔法阵
	_draw_spawn_circle(wr)

	# 9. 边缘暗角（屏幕空间，覆盖可视区，聚焦画面中心）
	if _vignette_tex:
		draw_texture_rect(_vignette_tex, Rect2(-half, _vis_size), false)


## 大尺度斑块：压暗 / 提亮 / 主题色渐变斑，三层同心圆模拟软边
func _draw_patches(wr: Rect2) -> void:
	var c0 := Vector2i(floori(wr.position.x / CELL_PATCH), floori(wr.position.y / CELL_PATCH))
	var c1 := Vector2i(floori(wr.end.x / CELL_PATCH), floori(wr.end.y / CELL_PATCH))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			if _ch(cx, cy, 100) > 0.55:
				continue
			var p := Vector2(float(cx) + _ch(cx, cy, 101), float(cy) + _ch(cx, cy, 102)) * CELL_PATCH
			var radius := lerpf(150.0, 330.0, _ch(cx, cy, 103))
			var kind := _ch(cx, cy, 104)
			var col: Color
			if kind < 0.35:
				col = _palette.decor
				col.a = 0.10
			elif kind < 0.7:
				col = Color(0.0, 0.0, 0.02, 0.13)
			else:
				col = Color(1.0, 0.98, 0.92, 0.05)
			draw_circle(_w(p), radius, Color(col.r, col.g, col.b, col.a * 0.25))
			draw_circle(_w(p), radius * 0.72, Color(col.r, col.g, col.b, col.a * 0.55))
			draw_circle(_w(p), radius * 0.45, col)


## 中尺度色块斑：暗斑 / 亮斑 / 主题染斑，双层圆软边
func _draw_blobs(wr: Rect2) -> void:
	var c0 := Vector2i(floori(wr.position.x / CELL_BLOB), floori(wr.position.y / CELL_BLOB))
	var c1 := Vector2i(floori(wr.end.x / CELL_BLOB), floori(wr.end.y / CELL_BLOB))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			if _ch(cx, cy, 200) < 0.35:
				continue
			var count := 1 + (1 if _ch(cx, cy, 201) > 0.62 else 0)
			for k in count:
				var salt := 202 + k * 4
				var p := Vector2(float(cx) + _ch(cx, cy, salt), float(cy) + _ch(cx, cy, salt + 1)) * CELL_BLOB
				var radius := lerpf(26.0, 68.0, _ch(cx, cy, salt + 2))
				var kind := _ch(cx, cy, salt + 3)
				var col: Color
				if kind < 0.4:
					col = _palette.base.darkened(0.3)
					col.a = 0.20
				elif kind < 0.8:
					col = _palette.tone_b.lightened(0.06)
					col.a = 0.16
				else:
					col = _palette.decor
					col.a = 0.10
				draw_circle(_w(p), radius, Color(col.r, col.g, col.b, col.a * 0.4))
				draw_circle(_w(p), radius * 0.6, col)


func _draw_grid(wr: Rect2) -> void:
	var col: Color = _palette.grid
	var x := ceilf(wr.position.x / GRID_SPACING) * GRID_SPACING
	while x <= wr.end.x:
		draw_line(_w(Vector2(x, wr.position.y)), _w(Vector2(x, wr.end.y)), col, 1.0)
		x += GRID_SPACING
	var y := ceilf(wr.position.y / GRID_SPACING) * GRID_SPACING
	while y <= wr.end.y:
		draw_line(_w(Vector2(wr.position.x, y)), _w(Vector2(wr.end.x, y)), col, 1.0)
		y += GRID_SPACING


## 小装饰：按 decor cell 哈希决定有无 / 种类 / 位置，同格概率追加第二件
func _draw_decor(wr: Rect2) -> void:
	var c0 := Vector2i(floori(wr.position.x / CELL_DECOR), floori(wr.position.y / CELL_DECOR))
	var c1 := Vector2i(floori(wr.end.x / CELL_DECOR), floori(wr.end.y / CELL_DECOR))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			if _ch(cx, cy, 300) > 0.66:
				continue
			var origin := Vector2(float(cx), float(cy)) * CELL_DECOR
			var p := origin + Vector2(_ch(cx, cy, 301), _ch(cx, cy, 302)) * CELL_DECOR
			var s := lerpf(2.0, 5.5, _ch(cx, cy, 303))
			_draw_decor_item(_pick_decor_kind(_ch(cx, cy, 304)), p, s, cx, cy, 0)
			if _ch(cx, cy, 305) > 0.72:
				var p2 := origin + Vector2(_ch(cx, cy, 306), _ch(cx, cy, 307)) * CELL_DECOR
				var s2 := lerpf(2.0, 5.0, _ch(cx, cy, 309))
				_draw_decor_item(_pick_decor_kind(_ch(cx, cy, 308)), p2, s2, cx, cy, 10)


func _pick_decor_kind(r: float) -> int:
	var mix: Array = _palette.decor_mix
	var acc := 0.0
	for i in mix.size():
		acc += float(mix[i])
		if r <= acc:
			return i
	return mix.size() - 1


func _draw_decor_item(kind: int, p: Vector2, s: float, cx: int, cy: int, salt_off: int) -> void:
	var decor: Color = _palette.decor
	var glow: Color = _palette.glow
	match kind:
		0:  # 草丛/荆棘/冰草：扇形短线簇
			var n := 3 + int(_ch(cx, cy, 310 + salt_off) * 2.9)
			var spread := lerpf(0.55, 1.1, _ch(cx, cy, 311 + salt_off))
			var lean := lerpf(-0.5, 0.5, _ch(cx, cy, 312 + salt_off))
			for i in n:
				var t := float(i) / maxf(1.0, float(n - 1))
				var ang := -PI * 0.5 + lean + (t - 0.5) * spread
				var ln := s * lerpf(2.0, 3.4, _ch(cx, cy, 313 + salt_off + i))
				var tip := p + Vector2.from_angle(ang) * ln
				var c := decor if i % 2 == 0 else decor * Color(1, 1, 1, 0.75)
				draw_line(_w(p), _w(tip), c, 1.4)
			draw_circle(_w(p), s * 0.5, Color(decor.r, decor.g, decor.b, decor.a * 0.5))
		1:  # 碎石：暗底 + 亮面
			var r := s * 0.9
			draw_circle(_w(p), r, _stone_dark)
			draw_circle(_w(p + Vector2(-r * 0.25, -r * 0.3)), r * 0.55, _stone_light)
		2:  # 裂纹：随机折线
			var dir := Vector2.from_angle(_ch(cx, cy, 320 + salt_off) * TAU)
			var seg := 2 + int(_ch(cx, cy, 321 + salt_off) * 2.9)
			var q := p
			var prev := _w(q)
			for i in seg:
				q += dir * s * 2.2 + Vector2.from_angle(_ch(cx, cy, 322 + salt_off + i) * TAU) * s * 0.8
				var cur := _w(q)
				draw_line(prev, cur, _crack_col, 1.2)
				prev = cur
		3:  # 光点：蘑菇/余烬/冰晶/幽光
			draw_circle(_w(p), s * 1.5, Color(glow.r, glow.g, glow.b, glow.a * 0.22))
			draw_circle(_w(p), s * 0.6, Color(glow.r, glow.g, glow.b, glow.a * 0.8))
		4:  # 符文：小菱形 + 中心亮点
			var r2 := s * 1.4
			var rp := _w(p)
			var pts := PackedVector2Array([
				rp + Vector2(0, -r2), rp + Vector2(r2, 0),
				rp + Vector2(0, r2), rp + Vector2(-r2, 0),
			])
			draw_colored_polygon(pts, Color(glow.r, glow.g, glow.b, glow.a * 0.4))
			draw_circle(rp, r2 * 0.32, glow)


## 地标级装饰：每个大 cell 概率出现一个，随主题变化；间隔大、醒目但低饱和
func _draw_landmarks(wr: Rect2) -> void:
	var c0 := Vector2i(floori(wr.position.x / CELL_LANDMARK), floori(wr.position.y / CELL_LANDMARK))
	var c1 := Vector2i(floori(wr.end.x / CELL_LANDMARK), floori(wr.end.y / CELL_LANDMARK))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			if _ch(cx, cy, 400) > 0.5:
				continue
			var p := Vector2(
					float(cx) + lerpf(0.3, 0.7, _ch(cx, cy, 401)),
					float(cy) + lerpf(0.3, 0.7, _ch(cx, cy, 402))) * CELL_LANDMARK
			match _map_id:
				"forest":
					_landmark_grove(p, cx, cy)
				"lava":
					_landmark_fissure(p, cx, cy)
				"ice":
					_landmark_sheen(p, cx, cy)
				"shadow_realm":
					_landmark_rift(p, cx, cy)
				_:
					_landmark_stone_circle(p, cx, cy)


## 森林：古树影——暗色树冠团簇 + 树干 + 少量萤光
func _landmark_grove(p: Vector2, cx: int, cy: int) -> void:
	var canopy: Color = _palette.base.darkened(0.4)
	canopy.a = 0.42
	var canopy2: Color = _palette.tone_a.darkened(0.2)
	canopy2.a = 0.35
	var offs := [Vector2(-46, -18), Vector2(38, -40), Vector2(8, 26), Vector2(-12, -64)]
	var radii := [88.0, 74.0, 66.0, 52.0]
	for i in offs.size():
		draw_circle(_w(p + offs[i]), radii[i], canopy)
	for i in 3:
		draw_circle(_w(p + offs[i] * 0.6), radii[i] * 0.55, canopy2)
	var trunk := Color(0.16, 0.11, 0.07, 0.6)
	draw_line(_w(p + Vector2(3, 98)), _w(p + Vector2(-4, 10)), trunk, 7.0)
	draw_line(_w(p + Vector2(-4, 10)), _w(p + Vector2(-26, -36)), trunk, 4.5)
	var glow: Color = _palette.glow
	for i in 3:
		var gp := p + Vector2(lerpf(-80, 80, _ch(cx, cy, 450 + i)), lerpf(-70, 70, _ch(cx, cy, 453 + i)))
		draw_circle(_w(gp), lerpf(1.5, 3.0, _ch(cx, cy, 456 + i)),
				Color(glow.r, glow.g, glow.b, glow.a * 0.5))


## 熔岩：发光裂缝带——折线三层辉光 + 沿线余烬
func _landmark_fissure(p: Vector2, cx: int, cy: int) -> void:
	var dir := Vector2.from_angle(_ch(cx, cy, 410) * TAU)
	var glow: Color = _palette.glow
	var pts := PackedVector2Array([p])
	var q := p
	for i in 4:
		q += dir * lerpf(60.0, 110.0, _ch(cx, cy, 411 + i)) \
				+ Vector2.from_angle(_ch(cx, cy, 415 + i) * TAU) * 26.0
		pts.append(q)
	draw_polyline(_w_arr(pts), Color(glow.r, glow.g, glow.b, 0.10), 16.0)
	draw_polyline(_w_arr(pts), Color(glow.r, glow.g, glow.b, 0.30), 5.0)
	draw_polyline(_w_arr(pts), Color(1.0, 0.85, 0.6, 0.65), 1.8)
	for i in 3:
		var ep: Vector2 = pts[1 + i]
		ep += Vector2(lerpf(-14, 14, _ch(cx, cy, 460 + i)), lerpf(-14, 14, _ch(cx, cy, 463 + i)))
		draw_circle(_w(ep), 3.0, Color(glow.r, glow.g, glow.b, 0.5))


## 冰原：反光斑——宽淡光带 + 细长冰痕 + 闪点
func _landmark_sheen(p: Vector2, cx: int, cy: int) -> void:
	var dir := Vector2.from_angle(_ch(cx, cy, 416) * TAU)
	var perp := dir.orthogonal()
	draw_line(_w(p - dir * 140.0), _w(p + dir * 140.0), Color(0.85, 0.93, 1.0, 0.05), 26.0)
	for i in 3:
		var off := perp * lerpf(-26.0, 26.0, _ch(cx, cy, 420 + i))
		var half_len := lerpf(90.0, 150.0, _ch(cx, cy, 423 + i))
		var lp := p + off
		draw_line(_w(lp - dir * half_len), _w(lp + dir * half_len),
				Color(0.85, 0.93, 1.0, 0.14), 1.5)
	var glow: Color = _palette.glow
	for i in 4:
		var sp := p + Vector2(lerpf(-90, 90, _ch(cx, cy, 466 + i)), lerpf(-60, 60, _ch(cx, cy, 470 + i)))
		draw_circle(_w(sp), lerpf(1.2, 2.6, _ch(cx, cy, 474 + i)),
				Color(glow.r, glow.g, glow.b, glow.a * 0.7))


## 祭坛：符文石阵——环 + 立石 + 石上符文亮点
func _landmark_stone_circle(p: Vector2, cx: int, cy: int) -> void:
	var glow: Color = _palette.glow
	var ring := lerpf(70.0, 95.0, _ch(cx, cy, 430))
	var rot := _ch(cx, cy, 431) * TAU
	draw_arc(_w(p), ring, 0, TAU, 48, Color(glow.r, glow.g, glow.b, 0.10), 1.2)
	var stone_col := Color(0.34, 0.31, 0.27, 0.85)
	for i in 5:
		var ang := rot + TAU * float(i) / 5.0
		var sp := p + Vector2.from_angle(ang) * ring
		var sw := lerpf(7.0, 11.0, _ch(cx, cy, 432 + i))
		var sh := sw * lerpf(1.6, 2.2, _ch(cx, cy, 437 + i))
		var quad := PackedVector2Array([
			_w(sp + Vector2(-sw * 0.5, 0)), _w(sp + Vector2(-sw * 0.32, -sh)),
			_w(sp + Vector2(sw * 0.32, -sh)), _w(sp + Vector2(sw * 0.5, 0)),
		])
		draw_colored_polygon(quad, stone_col)
		if i % 2 == 0:
			draw_circle(_w(sp + Vector2(0, -sh * 0.55)), 1.8,
					Color(glow.r, glow.g, glow.b, 0.55))


## 暗影领域：暗影裂隙——压扁的深色涡心 + 环绕幽光
func _landmark_rift(p: Vector2, cx: int, cy: int) -> void:
	draw_set_transform(_w(p), _ch(cx, cy, 440) * TAU, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 84, Color(0.02, 0.01, 0.04, 0.5))
	draw_circle(Vector2.ZERO, 56, Color(0.03, 0.015, 0.06, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var glow: Color = _palette.glow
	for i in 4:
		var ang := _ch(cx, cy, 441 + i) * TAU
		var base_p := p + Vector2.from_angle(ang) * lerpf(70.0, 100.0, _ch(cx, cy, 445 + i))
		var tip := base_p + Vector2.from_angle(ang + lerpf(-0.6, 0.6, _ch(cx, cy, 449 + i))) * 22.0
		draw_line(_w(base_p), _w(tip), Color(glow.r, glow.g, glow.b, 0.35), 1.4)
		draw_circle(_w(base_p), 1.8, Color(glow.r, glow.g, glow.b, 0.5))


## 出生点魔法阵：双环 + 8 符文 + 内环辐条 + 中心辉光（淡，不干扰战斗）
func _draw_spawn_circle(wr: Rect2) -> void:
	var zone := Rect2(SPAWN_POS - Vector2(110, 110), Vector2(220, 220))
	if not wr.intersects(zone):
		return
	var c := _w(SPAWN_POS)
	var glow: Color = _palette.glow
	draw_arc(c, 84, 0, TAU, 64, Color(glow.r, glow.g, glow.b, 0.22), 2.0)
	draw_arc(c, 64, 0, TAU, 64, Color(glow.r, glow.g, glow.b, 0.16), 1.2)
	draw_arc(c, 30, 0, TAU, 48, Color(glow.r, glow.g, glow.b, 0.14), 1.0)
	for i in 8:
		var ang := TAU * float(i) / 8.0 + 0.12
		var rp := c + Vector2.from_angle(ang) * 74.0
		var r := 4.5
		draw_colored_polygon(PackedVector2Array([
			rp + Vector2(0, -r), rp + Vector2(r, 0),
			rp + Vector2(0, r), rp + Vector2(-r, 0),
		]), Color(glow.r, glow.g, glow.b, 0.30))
	for i in 4:
		var ang2 := TAU * float(i) / 4.0 + PI * 0.25
		draw_line(c + Vector2.from_angle(ang2) * 32.0, c + Vector2.from_angle(ang2) * 62.0,
				Color(glow.r, glow.g, glow.b, 0.14), 1.0)
	draw_circle(c, 22.0, Color(glow.r, glow.g, glow.b, 0.08))
	draw_circle(c, 8.0, Color(glow.r, glow.g, glow.b, 0.14))


## 批量世界坐标 → 本地坐标
func _w_arr(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = pts[i] - _cam_center
	return out
