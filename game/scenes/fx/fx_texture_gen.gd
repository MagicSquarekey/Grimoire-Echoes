## fx_texture_gen.gd - 特效纹理一次性程序化生成器
## 用法: godot --headless --path . -s res://scenes/fx/fx_texture_gen.gd
## 输出: res://assets/fx/*.png
## 注意：GradientTexture2D 的 FILL_RADIAL 在 GL Compatibility 渲染器下会渲染成纯白（已知引擎坑），
## 因此这里用逐像素 Image 手工生成径向光斑后存 PNG，不使用 GradientTexture2D。
extends SceneTree

const OUT_DIR := "res://assets/fx"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_save("glow_soft.png", _radial(64, 2.2))       # 柔和光晕（弹体光晕/施法闪光/拾取物光晕底图）
	_save("spark.png", _spark(32))                  # 高光小星点（爆裂粒子/金币星芒）
	_save("ring_glow.png", _ring(128, 0.78, 0.075)) # 扩散光环（升级特效）
	print("[FxTexGen] 全部纹理生成完毕")
	quit(0)


## 柔和径向光斑：alpha = (1 - r)^falloff
func _radial(size: int, falloff: float) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x - c, y - c).length() / c
			var a := pow(clampf(1.0 - d, 0.0, 1.0), falloff)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return img


## 星点：陡峭衰减 + 亮核
func _spark(size: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x - c, y - c).length() / c
			var a := maxf(pow(clampf(1.0 - d, 0.0, 1.0), 3.5), pow(clampf(1.0 - d, 0.0, 1.0), 14.0))
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(a, 0.0, 1.0)))
	return img


## 环形光带：高斯环
func _ring(size: int, radius_norm: float, width_norm: float) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x - c, y - c).length() / c
			var a := exp(-pow((d - radius_norm) / width_norm, 2.0)) * 0.95
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(a, 0.0, 1.0)))
	return img


func _save(file_name: String, img: Image) -> void:
	var path := OUT_DIR + "/" + file_name
	img.save_png(path)
	print("[FxTexGen] ", path, " ", img.get_size())
