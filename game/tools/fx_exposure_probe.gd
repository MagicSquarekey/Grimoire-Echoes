## fx_exposure_probe.gd - 施法白闪归因台
## 目的：实战截图噪声太大（每帧弹体数量/位置都不同），无法判断"白闪"到底由哪一层造成。
## 这里把构图固定成"暗底 + 玩家 + 4 发弹体叠在施法点"，逐层开关，量化近白覆盖率。
## 用法（必须窗口模式，headless 不出图）：
##   Godot --path game res://tools/fx_exposure_probe.tscn
extends Node2D

const SHOT_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/fx"
const BG := Color(0.09, 0.10, 0.13)
const CENTER := Vector2(960, 540)
const PROJ_COUNT := 4
## 从搭建完成到截图的物理帧数：固定帧数才能保证各配置可比
const SETTLE_FRAMES := 12

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const PROJ_SCENE := preload("res://scenes/spells/projectile.tscn")
const GRADE_SHADER := preload("res://assets/fx/grade_overlay.gdshader")

## 每个配置只关掉一层，其余与游戏内一致
const VARIANTS := [
	{"tag": "00_all", "env_glow": true, "grade": true, "dim": true,
		"light": true, "aura": true, "pglow": true, "trail": true, "burst": true},
	{"tag": "01_no_env_glow", "env_glow": false, "grade": true, "dim": true,
		"light": true, "aura": true, "pglow": true, "trail": true, "burst": true},
	{"tag": "02_no_grade", "env_glow": true, "grade": false, "dim": true,
		"light": true, "aura": true, "pglow": true, "trail": true, "burst": true},
	{"tag": "03_no_player_light", "env_glow": true, "grade": true, "dim": true,
		"light": false, "aura": true, "pglow": true, "trail": true, "burst": true},
	{"tag": "04_no_player_aura", "env_glow": true, "grade": true, "dim": true,
		"light": true, "aura": false, "pglow": true, "trail": true, "burst": true},
	{"tag": "05_no_proj_glow", "env_glow": true, "grade": true, "dim": true,
		"light": true, "aura": true, "pglow": false, "trail": true, "burst": true},
	{"tag": "06_no_proj_trail", "env_glow": true, "grade": true, "dim": true,
		"light": true, "aura": true, "pglow": true, "trail": false, "burst": true},
	{"tag": "07_no_cast_burst", "env_glow": true, "grade": true, "dim": true,
		"light": true, "aura": true, "pglow": true, "trail": true, "burst": false},
	{"tag": "08_env_glow_only", "env_glow": true, "grade": false, "dim": false,
		"light": false, "aura": false, "pglow": false, "trail": false, "burst": false},
	{"tag": "09_bare", "env_glow": false, "grade": false, "dim": false,
		"light": false, "aura": false, "pglow": false, "trail": false, "burst": false},
]

var _rig: Node2D
var _env_host: WorldEnvironment
var _grade_layer: CanvasLayer
var _dim: CanvasModulate
var _frame := 0
var _idx := -1
var _busy := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(BG)
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	_next()


func _next() -> void:
	_idx += 1
	if _idx >= VARIANTS.size():
		print("[fxprobe] DONE")
		get_tree().quit()
		return
	var v: Dictionary = VARIANTS[_idx]
	_build(v)
	_frame = 0


func _build(v: Dictionary) -> void:
	if _rig != null and is_instance_valid(_rig):
		_rig.free()
	_rig = Node2D.new()
	_rig.name = "Rig"
	add_child(_rig)

	# 与 game.tscn 一致的三层后处理
	if v["dim"]:
		_dim = CanvasModulate.new()
		_dim.color = Color(0.87, 0.87, 0.97, 1)
		_rig.add_child(_dim)
	else:
		_dim = null

	_env_host = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.glow_enabled = bool(v["env_glow"])
	env.glow_intensity = 0.95
	env.glow_strength = 1.0
	env.glow_bloom = 0.08
	env.glow_blend_mode = 2
	_env_host.environment = env
	_rig.add_child(_env_host)

	# 玩家
	var player: Node2D = PLAYER_SCENE.instantiate()
	player.position = CENTER
	_rig.add_child(player)
	var light := player.get_node_or_null("ElementLight")
	if light and not bool(v["light"]):
		light.enabled = false
	var aura := player.get_node_or_null("AuraGlow")
	if aura and not bool(v["aura"]):
		aura.visible = false

	# 施法点：与 sprite_body._on_spell_cast 同一个位置（朝右）
	var tip: Vector2 = CENTER + Vector2(24, -26)
	for i in PROJ_COUNT:
		var p: Projectile = PROJ_SCENE.instantiate()
		_rig.add_child(p)
		p.global_position = tip + Vector2(0, float(i - PROJ_COUNT / 2) * 3.0)
		# 速度归零：把"连发时弹体堆在施法点"这一帧固定下来，便于横向比较
		p.setup(25.0, 0.0, Vector2.RIGHT, "fire")
		if not bool(v["pglow"]):
			var g := p.get_node_or_null("Glow")
			if g:
				g.visible = false
		if not bool(v["trail"]):
			var t := p.get_node_or_null("Trail")
			if t:
				t.visible = false
	if bool(v["burst"]):
		FxLib.element_burst(self, tip, "fire", 0.45)

	if v["grade"]:
		_grade_layer = CanvasLayer.new()
		_grade_layer.layer = 15
		var rect := ColorRect.new()
		var mat := ShaderMaterial.new()
		mat.shader = GRADE_SHADER
		rect.material = mat
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_grade_layer.add_child(rect)
		_rig.add_child(_grade_layer)
	else:
		_grade_layer = null


func _physics_process(_delta: float) -> void:
	if _busy or _idx >= VARIANTS.size():
		return
	_frame += 1
	if _frame < SETTLE_FRAMES:
		return
	_busy = true
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [SHOT_DIR, str(VARIANTS[_idx]["tag"])]
	img.save_png(path)
	print("[fxprobe] saved ", path)
	_busy = false
	_next()
