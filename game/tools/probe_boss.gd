## probe_boss.gd - Boss 战诊断探针·引导脚本（开发工具）
## 把逻辑节点挂到 /root，避免 change_scene_to_file 把探针自身释放掉。
## 用法: Godot --headless --path game res://tools/probe_boss.tscn
extends Node

const LOGIC := preload("res://tools/probe_boss_logic.gd")

func _ready() -> void:
	var logic = LOGIC.new()
	logic.name = "ProbeBossLogic"
	get_tree().root.call_deferred("add_child", logic)
