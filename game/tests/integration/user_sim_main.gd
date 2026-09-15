## UserSimMain - 真实用户模拟器入口场景的根节点脚本
## 职责：把 user_sim_bot.gd 实例挂到树根（root）下，
## 这样后续 change_scene_to_file 切换场景时测试节点不会被释放。
## 用法:
##   Godot --headless --path game res://tests/integration/user_sim_main.tscn
##   环境变量 USIM_SEED 可固定随机种子（默认随机），USIM_MINUTES 可改时长（默认 8）
extends Node

func _ready() -> void:
	var bot = preload("res://tests/integration/user_sim_bot.gd").new()
	bot.name = "UserSimBot"
	get_tree().root.call_deferred("add_child", bot)
