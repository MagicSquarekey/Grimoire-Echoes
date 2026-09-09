## StressTestMain - 压力模拟入口场景的根节点脚本
## 把 stress_test.gd 实例挂到树根，change_scene 时不会被释放。
extends Node

func _ready() -> void:
	var tester = preload("res://tests/stress_test.gd").new()
	tester.name = "StressTester"
	get_tree().root.call_deferred("add_child", tester)
