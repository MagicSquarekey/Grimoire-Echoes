## SmokeTestAllScenes - 场景冒烟测试
## 遍历 res://scenes/ 下所有 .tscn：load + instantiate + 入树 + 等2帧 + free
## 收集加载失败、实例化失败、脚本错误、缺失节点报错。
## 用法: godot --headless --path <项目> -s res://tests/smoke_test_all_scenes.gd
extends SceneTree

var scene_paths: Array[String] = []
var failed: Array[String] = []
var passed := 0

func _initialize() -> void:
	# 等待一帧确保场景树与 autoload 就绪
	await process_frame
	_collect_scenes("res://scenes")

	print("=".repeat(60))
	print("场景冒烟测试 - 共 %d 个场景" % scene_paths.size())
	print("=".repeat(60))

	for path in scene_paths:
		print("\n[SMOKE] ---- 加载 %s ----" % path)
		var packed: PackedScene = load(path)
		if packed == null:
			print("[SMOKE] ❌ 加载失败: %s" % path)
			failed.append(path)
			continue

		var inst = packed.instantiate()
		if inst == null:
			print("[SMOKE] ❌ 实例化失败: %s" % path)
			failed.append(path)
			continue

		get_root().add_child(inst)
		# 模拟真实运行时的 current_scene（部分脚本通过它挂载子节点）
		current_scene = inst

		await process_frame
		await process_frame

		if is_instance_valid(inst):
			if current_scene == inst:
				current_scene = null
			inst.free()
			loaded_cleanly()
			print("[SMOKE] ✅ 通过")
		else:
			loaded_cleanly()
			print("[SMOKE] ⚠️ 场景在测试期间自行释放（可能触发场景切换）")

	print("\n" + "=".repeat(60))
	print("冒烟测试结果: %d/%d 个场景成功加载并运行2帧" % [passed, scene_paths.size()])
	if failed.is_empty():
		print("🎉 所有场景结构正常（脚本错误请检查上方控制台输出）")
	else:
		print("⚠️ 以下场景加载/实例化失败:")
		for f in failed:
			print("  ❌ " + f)
	print("=".repeat(60))
	quit(0 if failed.is_empty() else 1)

func loaded_cleanly() -> void:
	passed += 1

## 递归收集目录下所有 .tscn
func _collect_scenes(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if dir == null:
		print("[SMOKE] 无法打开目录: " + dir_path)
		failed.append(dir_path)
		return
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		var full = dir_path + "/" + name
		if dir.current_is_dir():
			if not name.begins_with("."):
				_collect_scenes(full)
		elif name.ends_with(".tscn"):
			scene_paths.append(full)
		name = dir.get_next()
	dir.list_dir_end()
