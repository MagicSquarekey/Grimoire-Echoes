## render_sprites.gd - 3D 模型 → 2D 精灵帧 渲染管线
## 用法（窗口模式，不要 --headless）：
##   Godot --path game res://tools/render_sprites.tscn
## 探针模式（只渲几个方位角试帧，用于校准朝向/构图）：
##   RENDER_PROBE=1 Godot --path game res://tools/render_sprites.tscn
extends Node

const OUT_BASE := "res://assets/sprites/gen"
const PROBE_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/probe"

# 相机参数
const PITCH_DEG := -50.0     # 俯视角（类幸存者）
const FOV_DEG := 40.0
const FRAME := 384           # 单帧尺寸
const PORTRAIT := 512        # 立绘尺寸
const MARGIN_FACTOR := 2.05  # 距离裕量

# 渲染任务表：模型 → 输出前缀 → 动画映射（输出名: 源动画名）
const JOBS := [
	{
		"model": "res://assets/models/mage.glb",
		"prefix": "player_water",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Running_A"},
		"portrait": true,
	},
	{
		"model": "res://assets/models/skeleton_mage.glb",
		"prefix": "enemy_skeleton_mage",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Running_A", "attack": "Spellcast_Shoot"},
		"portrait": false,
	},
	{
		"model": "res://assets/models/blue_demon.gltf",
		"prefix": "enemy_shadow_servant",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Run", "attack": "Punch"},
		"portrait": false,
	},
	{
		"model": "res://assets/models/creep_creature.glb",
		"prefix": "enemy_swarm_bug",
		"frames": 8,
		"anims": {"idle": "Idle1_Action", "run": "Walk1_Action", "attack": "Bite_Action"},
		"portrait": false,
		"tint_color": Color(0.45, 0.8, 0.4),  # 灰白模型 → 绿色小虫
	},
]

# 侧视图方位角：实测各模型面向 +Z，yaw=270 时画面朝右
const SIDE_YAW_DEG := 270.0
const FRONT_YAW_DEG := 0.0
# 距离缩放（有效裕量 = MARGIN_FACTOR * dist_scale，越小越近越大）
const FRAMES_DIST_SCALE := 0.60
const PORTRAIT_DIST_SCALE := 0.55

# 玩家配色变体：名称 → 目标色相
const TINTS := {"player_fire": 0.02, "player_lightning": 0.13}
# 立绘用更平的俯角 + 更近的镜头（能看到脸）
const PORTRAIT_PITCH_DEG := -18.0

var vp: SubViewport
var stage: Node3D
var cam: Camera3D


func _ready() -> void:
	_build_stage()
	var probe := OS.get_environment("RENDER_PROBE") == "1"
	if probe:
		DirAccess.make_dir_recursive_absolute(PROBE_DIR)
		await _run_probe()
	else:
		await _run_full()
	print("[render_sprites] DONE")
	get_tree().quit()


# ---------- 舞台搭建 ----------

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


func _place_camera(aabb: AABB, yaw_deg: float, dist_scale: float,
		pitch_deg: float = PITCH_DEG) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var target: Vector3 = aabb.get_center()
	# 俯视投影后近似竖直跨度
	var vspan: float = aabb.size.y * absf(cos(pitch)) + aabb.size.z * absf(sin(pitch))
	var hspan: float = maxf(aabb.size.x, aabb.size.z)
	var fit: float = maxf(vspan, hspan * 0.85) * 0.5 / tan(deg_to_rad(FOV_DEG * 0.5))
	var dist: float = fit * MARGIN_FACTOR * dist_scale
	cam.position = target + Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.look_at(target, Vector3.UP)


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


func _find_anim_player(root: Node) -> AnimationPlayer:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is AnimationPlayer:
			return n
	return null


# ---------- 帧采集 ----------

func _capture(model_scene: PackedScene, anim_src: String, n_frames: int,
		yaw_deg: float, view_size: int, dist_scale: float,
		job_tint: Dictionary = {}, pitch_deg: float = PITCH_DEG) -> Array[Image]:
	vp.size = Vector2i(view_size, view_size)
	var model: Node3D = model_scene.instantiate()
	stage.add_child(model)
	if job_tint.get("tint_color", null) != null:
		_apply_material_tint(model, job_tint["tint_color"])
	var aabb := _compute_aabb(model)
	_place_camera(aabb, yaw_deg, dist_scale, pitch_deg)

	var imgs: Array[Image] = []
	var ap := _find_anim_player(model)
	if ap == null:
		push_error("no AnimationPlayer in " + str(model_scene.resource_path))
		model.queue_free()
		return imgs
	if not ap.has_animation(anim_src):
		push_error("anim '%s' missing in %s; list: %s" % [anim_src, model_scene.resource_path, str(ap.get_animation_list())])
		model.queue_free()
		return imgs
	var anim_len: float = ap.get_animation(anim_src).length
	ap.play(anim_src)
	for i in n_frames:
		var t := anim_len * float(i) / float(n_frames)
		ap.seek(t, true)
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		imgs.append(img)
	model.queue_free()
	await get_tree().process_frame
	return imgs


# ---------- 主流程 ----------

func _run_probe() -> void:
	var mage: PackedScene = load("res://assets/models/mage.glb")
	var creep: PackedScene = load("res://assets/models/creep_creature.glb")
	for yaw in [0.0, 45.0, 90.0, 135.0, 180.0]:
		var imgs := await _capture(mage, "Idle", 1, yaw, 256, 1.0)
		if not imgs.is_empty():
			imgs[0].save_png("%s/mage_yaw_%d.png" % [PROBE_DIR, int(yaw)])
		print("[probe] mage yaw ", yaw)
	var imgs2 := await _capture(creep, "Idle1_Action", 1, 90.0, 256, 1.0)
	if not imgs2.is_empty():
		imgs2[0].save_png(PROBE_DIR + "/creep_yaw_90.png")
	print("[probe] creep done")


func _run_full() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_BASE)
	_make_shadow_blob()

	var char_results: Array[Dictionary] = []
	for job in JOBS:
		var prefix: String = job["prefix"]
		var scene: PackedScene = load(job["model"])
		if scene == null:
			push_error("model missing: " + str(job["model"]))
			continue
		var out_dir := OUT_BASE + "/" + prefix
		DirAccess.make_dir_recursive_absolute(out_dir)
		var anim_info: Array[Dictionary] = []
		for out_name in job["anims"]:
			var src: String = job["anims"][out_name]
			var imgs := await _capture(scene, src, int(job["frames"]), SIDE_YAW_DEG, FRAME,
					FRAMES_DIST_SCALE, job)
			if imgs.is_empty():
				continue
			var cell := FRAME
			# 保存单帧 + 拼横条图集
			var sheet := Image.create(cell * imgs.size(), cell, false, Image.FORMAT_RGBA8)
			for i in imgs.size():
				imgs[i].save_png("%s/%s_%d.png" % [out_dir, out_name, i])
				sheet.blit_rect(imgs[i], Rect2i(0, 0, cell, cell), Vector2i(i * cell, 0))
			var sheet_path := "%s/%s_sheet.png" % [out_dir, out_name]
			sheet.save_png(sheet_path)
			anim_info.append({"name": out_name, "file": sheet_path,
				"frames": imgs.size(), "cell": cell})
			print("[render] ", prefix, " / ", out_name, " x", imgs.size())

		# 玩家基础（water）渲完后，烘焙 fire / lightning 变体与立绘
		if job.get("portrait", false):
			await _bake_tinted_variants(scene, char_results)

		char_results.append({"prefix": prefix, "anims": anim_info})

	for cr in char_results:
		_write_sprite_frames_tres(cr["prefix"], cr["anims"])
	print("[render_sprites] all rendered")


func _bake_tinted_variants(scene: PackedScene, char_results: Array[Dictionary]) -> void:
	# 立绘：正面近景，俯角更平以看到脸
	var portrait_arr := await _capture(scene, "Idle", 1, FRONT_YAW_DEG, PORTRAIT,
			0.5, {}, PORTRAIT_PITCH_DEG)
	if not portrait_arr.is_empty():
		var portrait := portrait_arr[0]
		DirAccess.make_dir_recursive_absolute(OUT_BASE + "/portraits")
		portrait.save_png(OUT_BASE + "/portraits/player_water.png")
		for tint_name in TINTS:
			var t := _tint_image(portrait, TINTS[tint_name])
			t.save_png("%s/portraits/%s.png" % [OUT_BASE, tint_name])
		print("[render] portraits saved")

	# 从已生成的 water 帧烘焙 fire / lightning 帧 + 图集
	var water_dir := OUT_BASE + "/player_water"
	for tint_name in TINTS:
		var out_dir: String = OUT_BASE + "/" + str(tint_name)
		DirAccess.make_dir_recursive_absolute(out_dir)
		var anim_info: Array[Dictionary] = []
		for anim in ["idle", "run"]:
			var imgs: Array[Image] = []
			var i := 0
			while true:
				var p := "%s/%s_%d.png" % [water_dir, anim, i]
				if not FileAccess.file_exists(p):
					break
				var img := Image.load_from_file(ProjectSettings.globalize_path(p))
				var tinted := _tint_image(img, TINTS[tint_name])
				tinted.save_png("%s/%s_%d.png" % [out_dir, anim, i])
				imgs.append(tinted)
				i += 1
			if imgs.is_empty():
				continue
			var cell := imgs[0].get_width()
			var sheet := Image.create(cell * imgs.size(), imgs[0].get_height(), false, Image.FORMAT_RGBA8)
			for j in imgs.size():
				sheet.blit_rect(imgs[j], Rect2i(0, 0, cell, cell), Vector2i(j * cell, 0))
			var sheet_path := "%s/%s_sheet.png" % [out_dir, anim]
			sheet.save_png(sheet_path)
			anim_info.append({"name": anim, "file": sheet_path,
				"frames": imgs.size(), "cell": cell})
			print("[render] ", tint_name, " / ", anim, " x", imgs.size())
		char_results.append({"prefix": tint_name, "anims": anim_info})


# 材质调色：albedo_color 乘法（灰白模型烘焙成指定色调）
func _apply_material_tint(model: Node, color: Color) -> void:
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var mesh := mi.mesh
			if mesh == null:
				continue
			for s in mesh.get_surface_count():
				var mat := mesh.surface_get_material(s)
				if mat is StandardMaterial3D:
					var m2: StandardMaterial3D = mat.duplicate()
					m2.albedo_color = color
					mi.set_surface_override_material(s, m2)


# 色相烘焙：把蓝色系像素（衣袍）移到目标色相，肤色/木质等不动
func _tint_image(src: Image, target_h: float) -> Image:
	var out: Image = src.duplicate()
	out.convert(Image.FORMAT_RGBA8)
	var w: int = out.get_width()
	var h: int = out.get_height()
	for y in h:
		for x in w:
			var c: Color = out.get_pixel(x, y)
			if c.a < 0.03:
				continue
			if c.s > 0.12 and c.h > 0.45 and c.h < 0.75:
				c.h = target_h
				c.s = minf(1.0, c.s * 1.4)   # 提饱和，避免变棕/发灰
				c.v = minf(1.0, c.v * 1.12)
				out.set_pixel(x, y, c)
	return out


func _make_shadow_blob() -> void:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := float(size) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x - c + 0.5, y - c + 0.5) / Vector2(c * 0.92, c * 0.55)
			var r := d.length()
			var a := clampf(1.0 - r, 0.0, 1.0)
			a = a * a * 0.55
			img.set_pixel(x, y, Color(0.02, 0.02, 0.05, a))
	DirAccess.make_dir_recursive_absolute(OUT_BASE)
	img.save_png(OUT_BASE + "/shadow_blob.png")
	print("[render] shadow_blob.png")


# 生成 SpriteFrames .tres（引用 sheet PNG + AtlasTexture 切图）
func _write_sprite_frames_tres(prefix: String, anims: Array[Dictionary]) -> void:
	var ext_lines: Array[String] = []
	var sub_lines: Array[String] = []
	var anim_blocks: Array[String] = []
	var ext_id := 1
	var sub_count := 0
	var speed_map := {"idle": 8.0, "run": 12.0, "attack": 10.0, "walk": 12.0}
	for a in anims:
		var ext_key := "%d" % ext_id
		ext_id += 1
		var res_path: String = a["file"]  # res://...
		ext_lines.append('[ext_resource type="Texture2D" path="%s" id="%s"]' % [res_path, ext_key])
		var frame_refs: Array[String] = []
		for i in int(a["frames"]):
			var sub_key := "Atlas_%s_%d" % [a["name"], i]
			sub_count += 1
			sub_lines.append('[sub_resource type="AtlasTexture" id="%s"]' % sub_key)
			sub_lines.append("atlas = ExtResource(\"%s\")" % ext_key)
			sub_lines.append("region = Rect2(%d, 0, %d, %d)" % [i * int(a["cell"]), a["cell"], a["cell"]])
			sub_lines.append("")
			frame_refs.append("{\"duration\": 1.0, \"texture\": SubResource(\"%s\")}" % sub_key)
		var anim_name: String = a["name"]
		var speed: float = speed_map.get(anim_name, 8.0)
		anim_blocks.append("{\n\"frames\": [%s],\n\"loop\": true,\n\"name\": &\"%s\",\n\"speed\": %.1f\n}"
			% [", ".join(frame_refs), anim_name, speed])
	var load_steps := (ext_id - 1) + sub_count + 1
	var txt := "[gd_resource type=\"SpriteFrames\" load_steps=%d format=3]\n\n" % load_steps
	txt += "\n".join(ext_lines) + "\n\n"
	txt += "\n".join(sub_lines) + "\n"
	txt += "[resource]\nanimations = [" + ", ".join(anim_blocks) + "]\n"
	var f := FileAccess.open(OUT_BASE + "/" + prefix + ".tres", FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	print("[render] saved ", prefix, ".tres")
