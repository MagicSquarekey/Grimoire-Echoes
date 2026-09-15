## render_cast_frames.gd - 玩家施法帧补渲工具（窗口模式，勿 --headless）
## 用法: Godot --path game res://tools/render_cast_frames.tscn
## 职责：
##   1. 用 mage.glb 的 "Spellcast_Shoot" 动画渲三向施法帧（侧/正/背 × 6 帧，384px）
##   2. 输出到 player_water/，并按色相烘焙 player_fire / player_lightning 变体
##   3. 把 cast / cast_front / cast_back 三个动画补进 player_{water,fire,lightning}.tres
## 不触碰敌人素材（与并行开发隔离）。
extends Node

const OUT_BASE := "res://assets/sprites/gen"
const MODEL := "res://assets/models/mage.glb"
const ANIM_SRC := "Spellcast_Shoot"
const FRAMES := 6
const FRAME := 384
const CAST_FPS := 14.0  # 6帧 @14fps ≈ 0.43s 施法动作

# 相机参数（与 render_sprites.gd 完全一致，保证画面构图连贯）
const PITCH_DEG := -50.0
const FOV_DEG := 40.0
const MARGIN_FACTOR := 2.05
const FRAMES_DIST_SCALE := 0.60
const SIDE_YAW_DEG := 270.0
const FRONT_YAW_DEG := 0.0
const BACK_YAW_DEG := 180.0

# 三向输出：输出名 → 相机方位角
const VIEWS := {"cast": SIDE_YAW_DEG, "cast_front": FRONT_YAW_DEG, "cast_back": BACK_YAW_DEG}

# 玩家配色变体：名称 → 目标色相（与 render_sprites.gd 一致）
const TINTS := {"player_fire": 0.02, "player_lightning": 0.13}

var vp: SubViewport
var stage: Node3D
var cam: Camera3D


func _ready() -> void:
	_build_stage()
	await _render_all()
	print("[render_cast] DONE")
	get_tree().quit()


# ---------- 舞台（复制自 render_sprites.gd） ----------

func _build_stage() -> void:
	vp = SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.size = Vector2i(FRAME, FRAME)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	stage = Node3D.new()
	vp.add_child(stage)

	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.85, 0.92)
	env.ambient_light_energy = 0.85
	var we := WorldEnvironment.new()
	we.environment = env
	stage.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 1.25
	stage.add_child(sun)

	cam = Camera3D.new()
	cam.fov = FOV_DEG
	cam.current = true
	stage.add_child(cam)


func _compute_aabb(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var ab: AABB = mi.global_transform * mi.get_aabb()
			if first:
				result = ab
				first = false
			else:
				result = result.merge(ab)
	return result


func _place_camera(aabb: AABB, yaw_deg: float, dist_scale: float) -> void:
	var pitch := deg_to_rad(PITCH_DEG)
	var yaw := deg_to_rad(yaw_deg)
	var target: Vector3 = aabb.get_center()
	var vspan: float = aabb.size.y * absf(cos(pitch)) + aabb.size.z * absf(sin(pitch))
	var hspan: float = maxf(aabb.size.x, aabb.size.z)
	var fit: float = maxf(vspan, hspan * 0.85) * 0.5 / tan(deg_to_rad(FOV_DEG * 0.5))
	var dist: float = fit * MARGIN_FACTOR * dist_scale
	cam.position = target + Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.look_at(target, Vector3.UP)


func _find_anim_player(root: Node) -> AnimationPlayer:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
			if c is AnimationPlayer:
				return c
	return null


func _capture(anim_src: String, yaw_deg: float) -> Array[Image]:
	var scene: PackedScene = load(MODEL)
	var imgs: Array[Image] = []
	if scene == null:
		push_error("model missing: " + MODEL)
		return imgs
	var model: Node3D = scene.instantiate()
	stage.add_child(model)
	var aabb := _compute_aabb(model)
	_place_camera(aabb, yaw_deg, FRAMES_DIST_SCALE)

	var ap := _find_anim_player(model)
	if ap == null or not ap.has_animation(anim_src):
		push_error("anim missing: " + anim_src)
		model.queue_free()
		return imgs
	var anim_len: float = ap.get_animation(anim_src).length
	ap.play(anim_src)
	for i in FRAMES:
		var t := anim_len * float(i) / float(FRAMES)
		ap.seek(t, true)
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		imgs.append(img)
	model.queue_free()
	await get_tree().process_frame
	return imgs


# ---------- 主流程 ----------

func _render_all() -> void:
	# 1) 水法师基础帧
	var captured := {}
	for out_name in VIEWS:
		var imgs := await _capture(ANIM_SRC, VIEWS[out_name])
		if imgs.is_empty():
			push_error("capture failed: " + out_name)
			return
		captured[out_name] = imgs
		_save_frames("player_water", out_name, imgs)

	# 2) 色相烘焙 fire / lightning 变体
	for tint_name in TINTS:
		for out_name in captured:
			var tinted: Array[Image] = []
			for img in captured[out_name]:
				tinted.append(_tint_image(img, TINTS[tint_name]))
			_save_frames(tint_name, out_name, tinted)

	# 3) 补进三个 .tres
	for prefix in ["player_water", "player_fire", "player_lightning"]:
		_patch_tres(OUT_BASE + "/" + prefix + ".tres", prefix)
	print("[render_cast] all done")


func _save_frames(prefix: String, out_name: String, imgs: Array[Image]) -> void:
	var out_dir := OUT_BASE + "/" + prefix
	DirAccess.make_dir_recursive_absolute(out_dir)
	var cell := FRAME
	var sheet := Image.create(cell * imgs.size(), cell, false, Image.FORMAT_RGBA8)
	for i in imgs.size():
		imgs[i].save_png("%s/%s_%d.png" % [out_dir, out_name, i])
		sheet.blit_rect(imgs[i], Rect2i(0, 0, cell, cell), Vector2i(i * cell, 0))
	sheet.save_png("%s/%s_sheet.png" % [out_dir, out_name])
	print("[render_cast] ", prefix, "/", out_name, " x", imgs.size())


# 色相烘焙：蓝色系像素（衣袍）移到目标色相，肤色/木质等不动（同 render_sprites.gd）
func _tint_image(src: Image, target_h: float) -> Image:
	var out: Image = src.duplicate()
	out.convert(Image.FORMAT_RGBA8)
	for y in out.get_height():
		for x in out.get_width():
			var c: Color = out.get_pixel(x, y)
			if c.a < 0.03:
				continue
			if c.s > 0.12 and c.h > 0.45 and c.h < 0.75:
				c.h = target_h
				c.s = minf(1.0, c.s * 1.4)
				c.v = minf(1.0, c.v * 1.12)
				out.set_pixel(x, y, c)
	return out


# ---------- .tres 补丁：追加 cast / cast_front / cast_back ----------

func _patch_tres(path: String, prefix: String) -> void:
	var txt := FileAccess.get_file_as_string(path)
	if "Atlas_cast_0" in txt:
		print("[render_cast] already patched: ", path)
		return

	var anims := ["cast", "cast_front", "cast_back"]
	# 新增 ext_resource（紧跟最后一个 ext_resource 行之后）
	var ext_lines := ""
	var ext_ids := {}
	var next_id := txt.count("[ext_resource ") + 1
	for anim in anims:
		ext_ids[anim] = next_id
		ext_lines += '[ext_resource type="Texture2D" path="res://assets/sprites/gen/%s/%s_sheet.png" id="%d"]\n' % [prefix, anim, next_id]
		next_id += 1

	# 新增 sub_resource（插在 [resource] 之前）
	var sub_lines := ""
	for anim in anims:
		for i in FRAMES:
			sub_lines += '[sub_resource type="AtlasTexture" id="Atlas_%s_%d"]\n' % [anim, i]
			sub_lines += 'atlas = ExtResource("%d")\n' % ext_ids[anim]
			sub_lines += "region = Rect2(%d, 0, %d, %d)\n\n" % [i * FRAME, FRAME, FRAME]

	# 新增动画块（插在 animations 数组末尾）
	var anim_blocks := ""
	for anim in anims:
		var frame_refs: Array[String] = []
		for i in FRAMES:
			frame_refs.append('{"duration": 1.0, "texture": SubResource("Atlas_%s_%d")}' % [anim, i])
		anim_blocks += ", {\n\"frames\": [%s],\n\"loop\": true,\n\"name\": &\"%s\",\n\"speed\": %.1f\n}" % [", ".join(frame_refs), anim, CAST_FPS]

	# 拼装：ext 紧跟已有 ext_resource 之后（首个 sub_resource 前），sub 插在 [resource] 前
	var first_sub := txt.find("[sub_resource ")
	var insert_at := first_sub if first_sub >= 0 else txt.find("[resource]")
	txt = txt.insert(insert_at, ext_lines)
	txt = txt.insert(txt.find("[resource]"), sub_lines)

	# animations = [ ... ] 末尾追加（文件以 "]" 收尾）
	var arr_end := txt.rfind("]")
	txt = txt.insert(arr_end, anim_blocks)

	# load_steps 递增（3 ext + 18 sub）
	var load_steps := txt.count("[ext_resource ") + txt.count("[sub_resource ") + 1
	var re := RegEx.new()
	re.compile("load_steps=\\d+")
	txt = re.sub(txt, "load_steps=%d" % load_steps, true)

	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	print("[render_cast] patched ", path, " (load_steps=", load_steps, ")")
