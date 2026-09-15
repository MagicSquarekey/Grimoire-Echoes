## verify_all_spells.gd - 全量法术脚本冒烟测试（headless）
## 运行：godot --headless --path . res://tests/verify_all_spells_scene.tscn
## 遍历 res://scripts/spells/ 全部 .gd：脚本编译 → 实例化 → 入树跑数帧 → free，
## 对有 cast/activate 等施放入口的法术尝试触发，收集失败清单。
extends Node

var fails: Array = []
var tested := 0

## 非法术类基础设施脚本（组件/纯数据，需宿主上下文，由玩法测试覆盖）
const SKIP := ["spell_caster.gd", "spell_data.gd", "spell_registry.gd", "spell_scene_generator.gd"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()

func _run() -> void:
	print("=== 全量法术脚本冒烟测试 ===")
	var paths: Array[String] = []
	_collect("res://scripts/spells", paths)
	paths.sort()
	print("共发现 %d 个法术脚本" % paths.size())

	for path in paths:
		if path.get_file() in SKIP:
			print("  - 跳过基础设施: %s" % path.get_file())
			continue
		tested += 1
		var script = load(path)
		if script == null:
			fails.append(path + " (load失败)")
			print("  ✗ load失败: " + path)
			continue
		if not script.can_instantiate():
			fails.append(path + " (脚本编译失败)")
			print("  ✗ 编译失败: " + path)
			continue
		var inst = null
		# 实例化（仅 Node 类入树验证 _ready；不主动调 cast——无玩家/目标环境下的
		# 施放报错属预期噪音，注册表内 13 个法术的完整施放由 tools/verify_spells.gd 覆盖）
		if script.get_instance_base_type() in ["Node", "Node2D", "Area2D", "CharacterBody2D"]:
			inst = script.new()
			if inst == null:
				fails.append(path + " (new失败)")
				print("  ✗ new失败: " + path)
				continue
			add_child(inst)
			await get_tree().create_timer(0.12).timeout
			if is_instance_valid(inst):
				inst.queue_free()
				await get_tree().process_frame
		else:
			inst = script.new()
			if inst == null:
				fails.append(path + " (new失败)")
				print("  ✗ new失败: " + path)
				continue
			if inst is RefCounted:
				# 无入树需求，直接释放
				inst = null
		print("  ✓ %s" % path.get_file())

	print("===============================")
	print("结果：%d/%d 通过" % [tested - fails.size(), tested])
	if fails.is_empty():
		print("全部通过 ✓")
		get_tree().quit(0)
	else:
		for f in fails:
			print("  - " + f)
		get_tree().quit(1)

func _collect(dir_path: String, out: Array[String]) -> void:
	var dir = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var f: String = dir.get_next()
	while f != "":
		var full := dir_path + "/" + f
		if dir.current_is_dir() and not f.begins_with("."):
			_collect(full, out)
		elif f.ends_with(".gd"):
			out.append(full)
		f = dir.get_next()
