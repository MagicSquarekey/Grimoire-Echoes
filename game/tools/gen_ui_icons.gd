## gen_ui_icons.gd - 程序化生成 UI 图标 PNG（几何形状光栅化，4x 超采样抗锯齿）
## 用法: godot --headless --path <项目> -s res://tools/gen_ui_icons.gd
## 输出: res://assets/ui/icons/*.png
extends SceneTree

const OUT := "res://assets/ui/icons"
const SIZE := 32
const SS := 4

# 形状: {"t": "circle"/"capsule"/"ringseg"/"poly", ...参数, "c": Color}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_save("heart", _heart())
	_save("mana", _mana())
	_save("star", _star())
	_save("sword", _sword())
	_save("skull", _skull())
	_save("coin", _coin())
	_save("clock", _clock())
	_save("bolt", _bolt())
	_save("multishot", _multishot())
	_save("speed", _speed())
	_save("magnet", _magnet())
	print("[icons] done -> ", OUT)
	quit(0)

# ---------- 光栅化 ----------

func _save(icon_name: String, shapes: Array) -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var half := 1.0 / (SS * 2.0)
	for y in SIZE:
		for x in SIZE:
			var col := Color(0, 0, 0, 0)
			for sy in SS:
				for sx in SS:
					var p := Vector2(x + (sx + 0.5) / SS, y + (sy + 0.5) / SS)
					# 从最上层往下找第一个命中的形状
					var hit: Color = Color(0, 0, 0, 0)
					for i in range(shapes.size() - 1, -1, -1):
						if _hit(shapes[i], p):
							hit = shapes[i]["c"]
							break
					if hit.a > 0.0:
						col += hit
			col = col / float(SS * SS)
			img.set_pixel(x, y, col)
	img.save_png("%s/%s.png" % [OUT, icon_name])

func _hit(shape: Dictionary, p: Vector2) -> bool:
	match shape["t"]:
		"circle":
			return p.distance_to(shape["p"]) <= shape["r"]
		"capsule":
			return _seg_dist(p, shape["a"], shape["b"]) <= shape["r"]
		"ringseg":
			var d: Vector2 = p - shape["p"]
			var dist := d.length()
			if dist < shape["r_in"] or dist > shape["r_out"]:
				return false
			var ang := atan2(d.y, d.x)
			return ang >= shape["a0"] and ang <= shape["a1"]
		"poly":
			return _in_poly(p, shape["pts"])
	return false

func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _in_poly(p: Vector2, pts: PackedVector2Array) -> bool:
	var inside := false
	var j := pts.size() - 1
	for i in pts.size():
		if (pts[i].y > p.y) != (pts[j].y > p.y):
			if p.x < (pts[j].x - pts[i].x) * (p.y - pts[i].y) / (pts[j].y - pts[i].y) + pts[i].x:
				inside = not inside
		j = i
	return inside

func _star_pts(center: Vector2, r_out: float, r_in: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + i * PI / 5.0
		var r := r_out if i % 2 == 0 else r_in
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	return pts

# ---------- 各图标 ----------

func _heart() -> Array:
	var c := Color("ef5a63")
	var hi := Color("ffa8ae")
	return [
		{"t": "circle", "p": Vector2(10.5, 12.5), "r": 6.6, "c": c},
		{"t": "circle", "p": Vector2(21.5, 12.5), "r": 6.6, "c": c},
		{"t": "poly", "pts": PackedVector2Array([Vector2(5.1, 15.5), Vector2(26.9, 15.5), Vector2(16, 27.5)]), "c": c},
		{"t": "circle", "p": Vector2(9.6, 10.4), "r": 2.1, "c": hi},
	]

func _mana() -> Array:
	var c := Color("4f8fe8")
	var hi := Color("a4ccff")
	return [
		{"t": "poly", "pts": PackedVector2Array([Vector2(16, 3.5), Vector2(8.8, 17.5), Vector2(23.2, 17.5)]), "c": c},
		{"t": "circle", "p": Vector2(16, 18.8), "r": 7.6, "c": c},
		{"t": "circle", "p": Vector2(12.6, 16.6), "r": 2.2, "c": hi},
	]

func _star() -> Array:
	return [
		{"t": "poly", "pts": _star_pts(Vector2(16, 17), 13.5, 5.6), "c": Color("f2c14e")},
		{"t": "circle", "p": Vector2(11.5, 13.5), "r": 1.9, "c": Color("ffe9a8")},
	]

func _sword() -> Array:
	return [
		{"t": "capsule", "a": Vector2(9.5, 22.5), "b": Vector2(22.5, 6.5), "r": 2.7, "c": Color("cfd6ea")},
		{"t": "capsule", "a": Vector2(6.6, 18.6), "b": Vector2(13.4, 25.4), "r": 1.9, "c": Color("d8b45a")},
		{"t": "circle", "p": Vector2(8.2, 24.6), "r": 2.9, "c": Color("d8b45a")},
		{"t": "capsule", "a": Vector2(15.5, 12.5), "b": Vector2(19.5, 9.5), "r": 0.9, "c": Color("f0f4ff")},
	]

func _skull() -> Array:
	var bone := Color("e8e4f2")
	var dark := Color("1a1630")
	return [
		{"t": "circle", "p": Vector2(16, 13.5), "r": 8.6, "c": bone},
		{"t": "poly", "pts": PackedVector2Array([Vector2(10.5, 19), Vector2(21.5, 19), Vector2(20.5, 27), Vector2(11.5, 27)]), "c": bone},
		{"t": "circle", "p": Vector2(12.4, 13.8), "r": 2.7, "c": dark},
		{"t": "circle", "p": Vector2(19.6, 13.8), "r": 2.7, "c": dark},
		{"t": "poly", "pts": PackedVector2Array([Vector2(16, 16.8), Vector2(14.4, 19.6), Vector2(17.6, 19.6)]), "c": dark},
		{"t": "capsule", "a": Vector2(14.2, 22.5), "b": Vector2(14.2, 26), "r": 0.8, "c": dark},
		{"t": "capsule", "a": Vector2(17.8, 22.5), "b": Vector2(17.8, 26), "r": 0.8, "c": dark},
	]

func _coin() -> Array:
	return [
		{"t": "circle", "p": Vector2(16, 16), "r": 11.2, "c": Color("d9a53c")},
		{"t": "circle", "p": Vector2(16, 16), "r": 9.4, "c": Color("f2c14e")},
		{"t": "poly", "pts": PackedVector2Array([Vector2(14.6, 9.5), Vector2(17.4, 9.5), Vector2(17.4, 22.5), Vector2(14.6, 22.5)]), "c": Color("b8862e")},
		{"t": "circle", "p": Vector2(11.5, 10.5), "r": 1.7, "c": Color("ffe9a8")},
	]

func _clock() -> Array:
	return [
		{"t": "circle", "p": Vector2(16, 16), "r": 11.4, "c": Color("8f86c9")},
		{"t": "circle", "p": Vector2(16, 16), "r": 9.2, "c": Color("1d1836")},
		{"t": "capsule", "a": Vector2(16, 16), "b": Vector2(16, 8.8), "r": 1.5, "c": Color("e8e4f2")},
		{"t": "capsule", "a": Vector2(16, 16), "b": Vector2(21.6, 16), "r": 1.5, "c": Color("e8e4f2")},
		{"t": "circle", "p": Vector2(16, 16), "r": 1.9, "c": Color("f2c14e")},
	]

func _bolt() -> Array:
	return [
		{"t": "poly", "pts": PackedVector2Array([
			Vector2(18.5, 2.5), Vector2(8.5, 18), Vector2(14.2, 18), Vector2(11.5, 29.5),
			Vector2(23.5, 13), Vector2(17, 13),
		]), "c": Color("f2c14e")},
	]

func _multishot() -> Array:
	var c := Color("b48cf2")
	var tip := Color("e2d2ff")
	return [
		{"t": "capsule", "a": Vector2(16, 27.5), "b": Vector2(5.5, 7), "r": 2.0, "c": c},
		{"t": "capsule", "a": Vector2(16, 27.5), "b": Vector2(16, 4.5), "r": 2.0, "c": c},
		{"t": "capsule", "a": Vector2(16, 27.5), "b": Vector2(26.5, 7), "r": 2.0, "c": c},
		{"t": "poly", "pts": PackedVector2Array([Vector2(3.5, 6.5), Vector2(8.5, 5), Vector2(6, 10.5)]), "c": tip},
		{"t": "poly", "pts": PackedVector2Array([Vector2(13.5, 4.5), Vector2(18.5, 4.5), Vector2(16, 10)]), "c": tip},
		{"t": "poly", "pts": PackedVector2Array([Vector2(28.5, 6.5), Vector2(23.5, 5), Vector2(26, 10.5)]), "c": tip},
	]

func _speed() -> Array:
	var c := Color("6cd4ff")
	return [
		{"t": "capsule", "a": Vector2(4.5, 10), "b": Vector2(23, 10), "r": 2.3, "c": c},
		{"t": "capsule", "a": Vector2(9, 16), "b": Vector2(28, 16), "r": 2.3, "c": c},
		{"t": "capsule", "a": Vector2(4.5, 22), "b": Vector2(19, 22), "r": 2.3, "c": c},
		{"t": "circle", "p": Vector2(26.5, 24.5), "r": 1.5, "c": Color("bdeaff")},
	]

func _magnet() -> Array:
	var body := Color("e0524d")
	var silver := Color("dfe4f5")
	return [
		{"t": "poly", "pts": PackedVector2Array([Vector2(5.5, 7), Vector2(11, 7), Vector2(11, 14), Vector2(5.5, 14)]), "c": silver},
		{"t": "poly", "pts": PackedVector2Array([Vector2(21, 7), Vector2(26.5, 7), Vector2(26.5, 14), Vector2(21, 14)]), "c": silver},
		{"t": "ringseg", "p": Vector2(16, 14), "r_in": 5.0, "r_out": 10.5, "a0": 0.0, "a1": PI, "c": body},
	]
