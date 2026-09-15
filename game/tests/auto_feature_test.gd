## auto_feature_test.gd - 新功能引擎内自动化测试（模拟真实输入管线）
## 运行：godot --headless --path . res://tests/auto_feature_test_scene.tscn
##
## 通过 Input.parse_input_event 注入 ESC 按键（与真实键盘事件走同一管线），
## 覆盖：ESC 暂停开关（修复验证）/ ESC 关商店 / 升级重投 / 宝箱事件 /
##       诅咒祭坛 / 悬赏标记 / Boss 连战全流程
extends Node

var fails: Array = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if cond:
		print("  ✓ %s" % label)
	else:
		fails.append(label)
		print("  ✗ %s" % label)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 脱离当前场景挂到 root，避免 change_scene 时被销毁
	get_tree().root.call_deferred("add_child", _make_driver())

func _make_driver() -> Node:
	var driver := Node.new()
	driver.name = "FeatureTestDriver"
	driver.set_script(load("res://tests/auto_feature_driver.gd"))
	return driver
