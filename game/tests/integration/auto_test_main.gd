## AutoTestMain - 无头端到端测试入口场景的根节点脚本
## 职责：把 auto_test.gd 实例挂到树根（root）下，
## 这样后续 change_scene_to_file 切换场景时测试节点不会被释放。
extends Node

func _ready() -> void:
	var tester = preload("res://tests/auto_test.gd").new()
	tester.name = "AutoTester"
	get_tree().root.call_deferred("add_child", tester)
