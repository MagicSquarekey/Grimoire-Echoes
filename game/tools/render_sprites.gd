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
const FRAME := 512           # 单帧尺寸（512px 高清渲染，游戏内按比例缩小显示）
const PORTRAIT := 640        # 立绘尺寸
const MARGIN_FACTOR := 1.88  # 距离裕量（越小取景越满；宽体模型原先留得过多导致精灵偏小）

# 渲染任务表：模型 → 输出前缀 → 动画映射（输出名: 源动画名）
# 动画命名约定：idle / run（侧视，兼容旧引用）+ idle_front / run_front /
# idle_back / run_back（纵向朝向）。*_front 面向镜头（向下移动），
# *_back 背对镜头（向上移动）。三视角帧内容相同，仅相机方位角不同。
const JOBS := [
	{
		"model": "res://assets/models/kaykit/Mage.glb",
		"prefix": "player_water",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Running_A",
			"idle_front": "Idle", "run_front": "Running_A",
			"idle_back": "Idle", "run_back": "Running_A"},
		"portrait": true,
	},
	{
		"model": "res://assets/models/kaykit/Skeleton_Mage.glb",
		"prefix": "enemy_skeleton_mage",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Running_A", "attack": "Spellcast_Shoot",
			"idle_front": "Idle", "run_front": "Running_A",
			"idle_back": "Idle", "run_back": "Running_A"},
		"portrait": false,
	},
	{
		"model": "res://assets/models/kaykit/Skeleton_Minion.glb",
		"prefix": "enemy_shadow_servant",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Running_A", "attack": "Unarmed_Melee_Attack_Punch_A",
			"idle_front": "Idle", "run_front": "Running_A",
			"idle_back": "Idle", "run_back": "Running_A"},
		"portrait": false,
	},
	{
		"model": "res://assets/models/pizza/Orc_5vO2YJsPEf.glb",
		"prefix": "enemy_orc_warrior",
		"frames": 8,
		"anims": {"idle": "CharacterArmature|Idle", "run": "CharacterArmature|Run",
			"attack": "CharacterArmature|Punch",
			"idle_front": "CharacterArmature|Idle", "run_front": "CharacterArmature|Run",
			"idle_back": "CharacterArmature|Idle", "run_back": "CharacterArmature|Run"},
		"portrait": false,
		# 原来用的 assets/models/orc.gltf 有 skin 和 JOINTS/WEIGHTS，但逐帧采样时
		# 骨架始终不动（8 帧像素完全一致）；换成同源的 .glb 版本后正常，面数也更高
	},
	{
		"model": "res://assets/models/AlienBug.glb",
		"prefix": "enemy_swarm_bug",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Run", "attack": "Attack_000",
			"idle_front": "Idle", "run_front": "Run",
			"idle_back": "Idle", "run_back": "Run"},
		"portrait": false,
		"tint_color": Color(0.45, 0.8, 0.4),  # 波次数量最多的单位，换用细节更高的虫族模型
	},
	{
		"model": "res://assets/models/pizza/Wolf_P1gU3Qkr9r.glb",
		"prefix": "enemy_demon_hound",
		"frames": 8,
		"anims": {"idle": "AnimalArmature|Idle", "run": "AnimalArmature|Gallop",
			"attack": "AnimalArmature|Attack",
			"idle_front": "AnimalArmature|Idle", "run_front": "AnimalArmature|Gallop",
			"idle_back": "AnimalArmature|Idle", "run_back": "AnimalArmature|Gallop"},
		"portrait": false,
		"tint_color": Color(0.95, 0.5, 0.42),  # 灰白狼皮 → 魔犬红
	},
	# ---- 新增怪物（对应 enemy_spawner 里的新 type key，前缀必须一致）----
	{
		"model": "res://assets/models/kaykit/Knight.glb",
		"prefix": "enemy_cursed_knight",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Running_A", "attack": "2H_Melee_Attack_Spin",
			"idle_front": "Idle", "run_front": "Running_A",
			"idle_back": "Idle", "run_back": "Running_A"},
		"portrait": false,
		"tint_color": Color(0.52, 0.46, 0.72),  # 钢铁护甲 → 暗影紫铁
	},
	{
		"model": "res://assets/models/kaykit/Rogue_Hooded.glb",
		"prefix": "enemy_shadow_assassin",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Running_A", "attack": "1H_Melee_Attack_Stab",
			"idle_front": "Idle", "run_front": "Running_A",
			"idle_back": "Idle", "run_back": "Running_A"},
		"portrait": false,
		"tint_color": Color(0.36, 0.32, 0.48),
	},
	{
		"model": "res://assets/models/kaykit/Skeleton_Rogue.glb",
		"prefix": "enemy_bone_archer",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Running_A", "attack": "1H_Ranged_Shoot",
			"idle_front": "Idle", "run_front": "Running_A",
			"idle_back": "Idle", "run_back": "Running_A"},
		"portrait": false,
		"tint_color": Color(0.93, 0.88, 0.76),  # 覆盖骨架自带的品红布料色，统一成骨白
	},
	{
		"model": "res://assets/models/kaykit/Barbarian.glb",
		"prefix": "enemy_ember_lord",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Running_A", "attack": "2H_Melee_Attack_Spin",
			"idle_front": "Idle", "run_front": "Running_A",
			"idle_back": "Idle", "run_back": "Running_A"},
		"portrait": false,
		"tint_color": Color(1.0, 0.42, 0.22),  # 蛮族体格 → 熔岩领主
	},
	{
		"model": "res://assets/models/pizza/Enemy_Flying_kzpT6fNmM5.glb",
		"prefix": "enemy_gargoyle",
		"frames": 8,
		"anims": {"idle": "CharacterArmature|Flying_Idle", "run": "CharacterArmature|Fast_Flying",
			"attack": "CharacterArmature|Headbutt",
			"idle_front": "CharacterArmature|Flying_Idle", "run_front": "CharacterArmature|Fast_Flying",
			"idle_back": "CharacterArmature|Flying_Idle", "run_back": "CharacterArmature|Fast_Flying"},
		"portrait": false,
	},
	{
		"model": "res://assets/models/pizza/Spider_yRYJiAJyiM.glb",
		"prefix": "enemy_plague_spitter",
		"frames": 8,
		"anims": {"idle": "SpiderArmature|Spider_Idle", "run": "SpiderArmature|Spider_Walk",
			"attack": "SpiderArmature|Spider_Attack",
			"idle_front": "SpiderArmature|Spider_Idle", "run_front": "SpiderArmature|Spider_Walk",
			"idle_back": "SpiderArmature|Spider_Idle", "run_back": "SpiderArmature|Spider_Walk"},
		"portrait": false,
		"tint_color": Color(0.66, 0.36, 0.8),  # 白模蜘蛛 → 疫病紫
	},
	{
		"model": "res://assets/models/pizza/Crab_Enemy_Gs3yfsV5lB.glb",
		"prefix": "enemy_ember_crab",
		"frames": 8,
		"anims": {"idle": "MonsterArmature|Idle", "run": "MonsterArmature|Walk",
			"attack": "MonsterArmature|Bite_InPlace",
			"idle_front": "MonsterArmature|Idle", "run_front": "MonsterArmature|Walk",
			"idle_back": "MonsterArmature|Idle", "run_back": "MonsterArmature|Walk"},
		"portrait": false,
		"tint_color": Color(1.0, 0.55, 0.3),  # 螃蟹本色偏青 → 熔岩橙（自爆预警色）
	},
	{
		"model": "res://assets/models/pizza/Bee_Enemy_6HsU6GQt3a.glb",
		"prefix": "enemy_bat_swarm",
		"frames": 8,
		"anims": {"idle": "MonsterArmature|Flying", "run": "MonsterArmature|Flying",
			"attack": "MonsterArmature|Bite_Front",
			"idle_front": "MonsterArmature|Flying", "run_front": "MonsterArmature|Flying",
			"idle_back": "MonsterArmature|Flying", "run_back": "MonsterArmature|Flying"},
		"portrait": false,
		"tint_color": Color(0.42, 0.32, 0.6),  # 白模飞虫 → 暗紫蝠群
	},
	{
		"model": "res://assets/models/GiantMutant.glb",
		"prefix": "enemy_aegis_golem",
		"frames": 8,
		"anims": {"idle": "idle", "run": "Giant Run", "attack": "Jump Slam",
			"idle_front": "idle", "run_front": "Giant Run",
			"idle_back": "idle", "run_back": "Giant Run"},
		"portrait": false,
		"tint_color": Color(0.72, 0.82, 0.95),  # 重甲石像 → 冷色巨体
	},
	{
		"model": "res://assets/models/kaykit/Skeleton_Mage.glb",
		"prefix": "enemy_grave_cleric",
		"frames": 8,
		"anims": {"idle": "Idle", "run": "Running_A", "attack": "Spellcast_Raise",
			"idle_front": "Idle", "run_front": "Running_A",
			"idle_back": "Idle", "run_back": "Running_A"},
		"portrait": false,
		"tint_color": Color(1.0, 0.93, 0.66),  # 治疗者：骨白圣金色
	},
	{
		"model": "res://assets/models/pizza/Ghost_Skull_TX8r9WBXpe.glb",
		"prefix": "enemy_storm_wisp",
		"frames": 8,
		"anims": {"idle": "CharacterArmature|Flying_Idle", "run": "CharacterArmature|Fast_Flying",
			"attack": "CharacterArmature|Headbutt",
			"idle_front": "CharacterArmature|Flying_Idle", "run_front": "CharacterArmature|Fast_Flying",
			"idle_back": "CharacterArmature|Flying_Idle", "run_back": "CharacterArmature|Fast_Flying"},
		"portrait": false,
		# 幽魂骷髅本身是骨白偏冷，再乘一层蓝色 tint 会压成近黑，
		# 在深色地面上直接消失——这个模型不上色
	},
	{
		"model": "res://assets/models/pizza/Zombie_VlXjG0N8Eg.glb",
		"prefix": "enemy_zombie_shambler",
		"frames": 8,
		"anims": {"idle": "CharacterArmature|Idle", "run": "CharacterArmature|Run",
			"attack": "CharacterArmature|Punch",
			"idle_front": "CharacterArmature|Idle", "run_front": "CharacterArmature|Run",
			"idle_back": "CharacterArmature|Idle", "run_back": "CharacterArmature|Run"},
		"portrait": false,
		# 无整图贴图、靠 3–6 个材质各自 baseColor 上色的模型不能整体染色：
		# 一层 tint 会把皮肤/布衣/绑带的色阶压成纯色，反而比原模型更糊
	},
	# Boss 专用：飞龙。enemy_spawner.BOSS_BASE_TYPE 指向 dragon
	{
		"model": "res://assets/models/pizza/Dragon_Evolved_LlwD0QNUPj.glb",
		"prefix": "enemy_dragon",
		"frames": 8,
		"anims": {"idle": "CharacterArmature|Flying_Idle", "run": "CharacterArmature|Fast_Flying",
			"attack": "CharacterArmature|Headbutt",
			"idle_front": "CharacterArmature|Flying_Idle", "run_front": "CharacterArmature|Fast_Flying",
			"idle_back": "CharacterArmature|Flying_Idle", "run_back": "CharacterArmature|Fast_Flying"},
		"portrait": false,
		"tint_color": Color(1.0, 0.52, 0.3),  # 灰白龙 → 熔岩红（火系 Boss 设定）
	},
]

# 侧视图方位角：实测各模型面向 +Z，yaw=270 时画面朝右
const SIDE_YAW_DEG := 270.0
# 正面（面向镜头，用于向下移动）与背面（背对镜头，用于向上移动）方位角
const FRONT_YAW_DEG := 0.0
const BACK_YAW_DEG := 180.0
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
var key_light: DirectionalLight3D
var fill_light: DirectionalLight3D
var rim_light: DirectionalLight3D


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
	# 环境光改用程序化天空：上冷天光 + 下暖地面反光，
	# 低模模型因此获得体积感（纯色环境光会把明暗压平）
	# background_mode 保持默认 CLEAR_COLOR，天空只参与照明不进画面，
	# 保证 SubViewport.transparent_bg 仍然输出透明底
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.40, 0.48, 0.66)
	sky_mat.sky_horizon_color = Color(0.70, 0.71, 0.74)
	sky_mat.ground_horizon_color = Color(0.52, 0.49, 0.46)
	sky_mat.ground_bottom_color = Color(0.20, 0.18, 0.17)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.88
	# 渲染级辉光：模型亮部泛出柔光（配合材质高光提升精致感）
	# 白色模型（骷髅系）在强光下易过曝，整体采用低强度布光
	env.glow_enabled = false
	# 色调映射：Linear 直出会让高光硬切、暗部糊成一团，
	# Filmic 压高光提暗部，sprite 的色彩层次明显更足
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 2.2
	# Filmic 会压暗中间调，补一点曝光，避免小精灵在深色地面上糊成一团
	env.tonemap_exposure = 1.14
	# 末端调色：轻微提饱和与对比，抵消 Filmic 带来的发灰
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.14
	env.adjustment_contrast = 1.07
	var we := WorldEnvironment.new()
	we.environment = env
	stage.add_child(we)

	# 三点摄影棚灯光：主光（暖/带软阴影）+ 辅光（冷/低强度）+ 轮廓光（勾边）
	key_light = DirectionalLight3D.new()
	key_light.light_energy = 0.85
	key_light.shadow_enabled = true
	key_light.shadow_blur = 1.6
	key_light.shadow_bias = 0.05
	key_light.shadow_normal_bias = 1.2
	stage.add_child(key_light)

	fill_light = DirectionalLight3D.new()
	fill_light.light_energy = 0.28
	stage.add_child(fill_light)

	rim_light = DirectionalLight3D.new()
	rim_light.light_energy = 1.0
	stage.add_child(rim_light)

	cam = Camera3D.new()
	cam.fov = FOV_DEG
	cam.current = true
	stage.add_child(cam)


## 三点灯光布置：随取景方位角旋转，保证任何朝向下光影一致
func _rig_lights(aabb: AABB, yaw_deg: float) -> void:
	var target: Vector3 = aabb.get_center()
	_place_light(key_light, target, yaw_deg - 45.0, -38.0, Color(1.0, 0.93, 0.82))
	_place_light(fill_light, target, yaw_deg + 65.0, -16.0, Color(0.70, 0.80, 1.0))
	_place_light(rim_light, target, yaw_deg + 155.0, -26.0, Color(0.96, 0.97, 1.0))

func _place_light(light: DirectionalLight3D, target: Vector3, yaw_deg: float,
		pitch_deg: float, color: Color) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	light.position = target + Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * 6.0
	light.look_at(target, Vector3.UP)
	light.light_color = color


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
	_rig_lights(aabb, yaw_deg)


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
	# SSAA 2× 超采样：2 倍尺寸渲染 + LANCZOS 降采样，边缘质量优于纯 MSAA
	vp.size = Vector2i(view_size * 2, view_size * 2)
	var model: Node3D = model_scene.instantiate()
	stage.add_child(model)
	_subdivide_model(model, 2)
	_smooth_model(model)
	_enhance_materials(model)
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
	# 不能用 play()+seek()：AnimationPlayer 在同一帧内还没真正接管该动画，
	# seek(t, true) 不会把姿势写进骨架，结果 8 帧全是同一张（怪物"平移不动画"）。
	# advance() 是手动步进，会立即应用姿势，离线逐帧采样要用它。
	ap.play(anim_src)
	ap.advance(0.0)
	var step: float = anim_len / float(n_frames)
	for i in n_frames:
		if i > 0:
			ap.advance(step)
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(view_size, view_size, Image.INTERPOLATE_LANCZOS)
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
	# RENDER_ONLY=enemy_x,enemy_y 时只渲指定 prefix（增量渲染，不动其他产物）
	var only := OS.get_environment("RENDER_ONLY")
	for job in JOBS:
		var prefix: String = job["prefix"]
		if not only.is_empty() and not (prefix in only.split(",")):
			continue
		var scene: PackedScene = load(job["model"])
		if scene == null:
			push_error("model missing: " + str(job["model"]))
			continue
		var out_dir := OUT_BASE + "/" + prefix
		DirAccess.make_dir_recursive_absolute(out_dir)
		var anim_info: Array[Dictionary] = []
		for out_name in job["anims"]:
			var src: String = job["anims"][out_name]
			# 输出名决定方位角：*_front 正面（面向镜头）、*_back 背面、其余侧视
			var yaw := SIDE_YAW_DEG
			if out_name.ends_with("_front"):
				yaw = FRONT_YAW_DEG
			elif out_name.ends_with("_back"):
				yaw = BACK_YAW_DEG
			var imgs := await _capture(scene, src, int(job["frames"]), yaw, FRAME,
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

	# 从已生成的 water 帧烘焙 fire / lightning 帧 + 图集（含正/背面朝向动画）
	var water_dir := OUT_BASE + "/player_water"
	for tint_name in TINTS:
		var out_dir: String = OUT_BASE + "/" + str(tint_name)
		DirAccess.make_dir_recursive_absolute(out_dir)
		var anim_info: Array[Dictionary] = []
		for anim in ["idle", "run", "idle_front", "run_front", "idle_back", "run_back"]:
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


# 材质调色：与 albedo_color **相乘**而非替换。
# 带贴图的模型 albedo_color 通常是纯白，乘与换等价；
# 但靠 baseColorFactor 上色的多材质模型（poly.pizza 那批）每个材质颜色不同，
# 替换会把 3–6 个材质的色阶压成一块纯色，细节全丢
func _apply_material_tint(model: Node, color: Color) -> void:
	var m := maxf(color.r, maxf(color.g, color.b))
	var tint := color / m if m > 0.0001 else color
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
					m2.albedo_color = m2.albedo_color * tint
					mi.set_surface_override_material(s, m2)


## 网格细分：中点细分 levels 轮（每三角→4三角），轮廓由棱角变圆润
## 网格是否蒙皮：Godot 4 里 skin 不在 Mesh 上，蒙皮信息体现在表面的
## bone 索引/权重数组里。细分会重建 ArrayMesh 且不带这两个数组，等于废掉骨架形变
func _mesh_is_skinned(mesh: Mesh) -> bool:
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		if arrays.size() <= Mesh.ARRAY_WEIGHTS:
			continue
		# 用无类型接收：没有权重时该槽位是 null，赋给 PackedFloat32Array 会抛错
		var raw = arrays[Mesh.ARRAY_WEIGHTS]
		if raw != null and raw.size() > 0:
			return true
	return false


func _subdivide_model(model: Node, levels: int) -> void:
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is MeshInstance3D and n.mesh != null:
			# 蒙皮网格一律跳过细分：重建 ArrayMesh 只带 VERTEX/INDEX/UV，
			# bone 索引与权重会丢失，骨架再也形变不了它——
			# 症状就是渲出来的 8 帧全是同一个姿势，游戏里怪物"平移不动画"
			if _mesh_is_skinned(n.mesh):
				continue
			var orig: Mesh = n.mesh
			var m: Mesh = orig
			for l in levels:
				m = _subdivide_mesh_once(m)
			# 细分中途出错会返回空网格，直接赋值等于把模型抹掉
			if m != null and m.get_surface_count() == orig.get_surface_count():
				n.mesh = m

func _subdivide_mesh_once(mesh: Mesh) -> Mesh:
	var new_mesh := ArrayMesh.new()
	if mesh == null:
		return new_mesh
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		# 靠 baseColor 上色的多材质模型没有 UV 通道，该槽位是 null；
		# 赋给类型化变量会抛错并中断整个细分，导致模型被抹成空网格
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] \
				if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if idx.is_empty():
			continue
		var has_uv := uvs.size() > 0
		var new_verts := verts.duplicate()
		var new_uvs := uvs.duplicate() if has_uv else PackedVector2Array()
		var mid_cache := {}
		var new_idx := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			var a := idx[t]
			var b := idx[t + 1]
			var c := idx[t + 2]
			var ab := _mid_idx(verts, uvs, new_verts, new_uvs, mid_cache, a, b, has_uv)
			var bc := _mid_idx(verts, uvs, new_verts, new_uvs, mid_cache, b, c, has_uv)
			var ca := _mid_idx(verts, uvs, new_verts, new_uvs, mid_cache, c, a, has_uv)
			new_idx.append_array(PackedInt32Array([a, ab, ca, b, bc, ab, c, ca, bc, ab, bc, ca]))
		var out := []
		out.resize(Mesh.ARRAY_MAX)
		out[Mesh.ARRAY_VERTEX] = new_verts
		out[Mesh.ARRAY_INDEX] = new_idx
		if has_uv:
			out[Mesh.ARRAY_TEX_UV] = new_uvs
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
		new_mesh.surface_set_material(new_mesh.get_surface_count() - 1, mesh.surface_get_material(s))
	return new_mesh

## 取/生成边中点顶点（带缓存）
func _mid_idx(verts: PackedVector3Array, uvs: PackedVector2Array,
		new_verts: PackedVector3Array, new_uvs: PackedVector2Array,
		cache: Dictionary, a: int, b: int, has_uv: bool) -> int:
	var lo := mini(a, b)
	var hi := maxi(a, b)
	var key := str(lo) + "_" + str(hi)
	if cache.has(key):
		return int(cache[key])
	new_verts.append((verts[a] + verts[b]) * 0.5)
	if has_uv and uvs.size() > maxi(a, b):
		new_uvs.append((uvs[a] + uvs[b]) * 0.5)
	var i := new_verts.size() - 1
	cache[key] = i
	return i

## 低多边形 → 圆滑造型：按顶点位置焊接并求平均法线（软阴影质感的关键）
func _smooth_model(model: Node) -> void:
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is MeshInstance3D and n.mesh != null:
			n.mesh = _smoothed_mesh(n.mesh)

func _smoothed_mesh(mesh: Mesh) -> Mesh:
	var new_mesh := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		# 从几何面片累积面法线（细分后原法线已失效），按焊接顶点求平均 → 圆滑着色
		var acc := {}
		if idx.is_empty():
			for i in range(0, verts.size(), 3):
				var fn: Vector3 = (verts[i + 1] - verts[i]).cross(verts[i + 2] - verts[i])
				for j in [i, i + 1, i + 2]:
					var key := _vkey(verts[j])
					acc[key] = (acc[key] if acc.has(key) else Vector3.ZERO) + fn
		else:
			for t in range(0, idx.size(), 3):
				var a := idx[t]
				var b := idx[t + 1]
				var c := idx[t + 2]
				var fn: Vector3 = (verts[b] - verts[a]).cross(verts[c] - verts[a])
				for j in [a, b, c]:
					var key := _vkey(verts[j])
					acc[key] = (acc[key] if acc.has(key) else Vector3.ZERO) + fn
		var new_normals := PackedVector3Array()
		new_normals.resize(verts.size())
		for i in verts.size():
			var avg: Vector3 = acc.get(_vkey(verts[i]), Vector3.UP)
			new_normals[i] = avg.normalized() if avg.length() > 0.0001 else Vector3.UP
		arrays[Mesh.ARRAY_NORMAL] = new_normals
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		new_mesh.surface_set_material(new_mesh.get_surface_count() - 1, mesh.surface_get_material(s))
	return new_mesh

static func _vkey(v: Vector3) -> Vector3i:
	return Vector3i(roundi(v.x * 512.0), roundi(v.y * 512.0), roundi(v.z * 512.0))

## 材质有效亮度：albedo 纹理均值 × albedo_color。
## 只看 albedo_color 会把所有带贴图的模型判成"白模"（该值几乎都是纯白），
## 于是深色怪物被关掉轮廓光、在深色地面上糊成剪影——必须算进纹理。
func _material_luminance(m: StandardMaterial3D) -> float:
	var c := m.albedo_color
	if m.albedo_texture != null:
		var img := m.albedo_texture.get_image()
		if img != null:
			img = img.duplicate()
			img.convert(Image.FORMAT_RGBA8)
			img.resize(8, 8, Image.INTERPOLATE_LANCZOS)
			var acc := Vector3.ZERO
			for y in 8:
				for x in 8:
					var p := img.get_pixel(x, y)
					acc += Vector3(p.r, p.g, p.b)
			acc /= 64.0
			c = Color(c.r * acc.x, c.g * acc.y, c.b * acc.z, c.a)
	return c.r * 0.3 + c.g * 0.6 + c.b * 0.1


## 材质增强：轮廓光边缘 + 高光反射 + 适中粗糙度，提升模型渲染精致度
func _enhance_materials(model: Node) -> void:
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
					# 按材质有效亮度自适应：白模降 rim/高光防过曝，深色模给足轮廓光
					var bright: float = _material_luminance(m2)
					var k: float = clampf(1.25 - bright, 0.25, 1.0)
					# 俯视角下 rim 极易过曝：白色模型（亮>0.85）完全关闭 rim
					if bright < 0.85:
						m2.rim_enabled = true
						m2.rim = 0.42 * k
						m2.rim_tint = 0.35
					else:
						m2.rim_enabled = false
					# 亮度地板：过暗的贴图在深色背景上只剩剪影，抬到可辨轮廓的水平。
					# 提升倍率封顶 1.5×，否则深色布料（如骷髅法师的暗紫兜帽）
					# 会被放大数倍直接炸成品红
					if bright < 0.30 and bright > 0.0:
						m2.albedo_color = m2.albedo_color * minf(1.5, 0.34 / bright)
					# 反向的地板：骨白模型（骷髅系）亮度接近 1，缩到 60px 时
					# 明暗梯度被一起压平，整只糊成一团白。压到 0.78 让体积感回来
					elif bright > 0.85:
						m2.albedo_color = m2.albedo_color * (0.78 / bright)
					m2.metallic = 0.08
					m2.roughness = 0.68
					m2.metallic_specular = 0.55 * k
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
		# 朝向变体（*_front / *_back）沿用基础动画的帧率
		var base_name: String = anim_name.replace("_front", "").replace("_back", "")
		var speed: float = speed_map.get(base_name, 8.0)
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
