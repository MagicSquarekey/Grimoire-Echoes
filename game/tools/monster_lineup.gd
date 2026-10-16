## monster_lineup.gd - 怪物阵容校验截图：把 scenes/enemies 下所有敌人摆成网格截图
## 用途：一次性肉眼核对每个敌人的精灵渲染、尺寸与配色是否达标
## 用法：Godot --path game res://tools/monster_lineup.tscn
extends Node2D

const OUT := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/monster_lineup.png"
const ENEMY_DIR := "res://scenes/enemies/"
## 只截真正的敌人场景，排除基类与特效辅助场景
const SKIP := ["enemy_base", "enemy_projectile", "shockwave_ring"]
const COLS := 6
const CELL := Vector2(240, 250)
const ORIGIN := Vector2(180, 150)

var _t := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.09, 0.10, 0.13))
	var dir := DirAccess.open(ENEMY_DIR)
	var names: Array[String] = []
	if dir:
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".tscn"):
				var key := f.trim_suffix(".tscn")
				if not (key in SKIP):
					names.append(key)
			f = dir.get_next()
	names.sort()
	for i in names.size():
		var scene: PackedScene = load(ENEMY_DIR + names[i] + ".tscn")
		if scene == null:
			print("[lineup] ❌ 加载失败 ", names[i])
			continue
		var inst := scene.instantiate()
		add_child(inst)
		inst.position = ORIGIN + Vector2(float(i % COLS), float(i / COLS)) * CELL
		var label := Label.new()
		label.text = names[i]
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
		label.position = ORIGIN + Vector2(float(i % COLS), float(i / COLS)) * CELL + Vector2(-70, 86)
		add_child(label)
		print("[lineup] ", names[i])
	print("[lineup] 共 ", names.size(), " 个敌人")


func _process(delta: float) -> void:
	_t += delta
	if _t < 1.2:
		return
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT)
	print("[lineup] saved ", OUT)
	get_tree().quit()
