## inspect_models.gd - 检查 glb 模型的动画名/AABB/朝向（headless）
## 用法: godot --headless --path . -s res://tools/inspect_models.gd
## 自定义清单: INSPECT_PATHS="a.glb,b.gltf" （相对 res:// 路径，逗号分隔）
extends SceneTree

const DIR := "res://assets/models/kaykit/"

func _initialize() -> void:
	var custom := OS.get_environment("INSPECT_PATHS")
	if not custom.is_empty():
		for p in custom.split(","):
			_inspect(p.strip_edges())
		quit(0)
		return
	for f in ["Mage.glb", "Skeleton_Mage.glb", "Skeleton_Minion.glb", "Rogue.glb", "Barbarian.glb"]:
		_inspect(DIR + f)
	quit(0)


func _inspect(path: String) -> void:
	var scene: PackedScene = load(path)
	if scene == null:
		print("✗ load失败: ", path)
		return
	var inst: Node3D = scene.instantiate()
	get_root().add_child(inst)
	var ap := _find_anim(inst)
	var anims: PackedStringArray = ap.get_animation_list() if ap else PackedStringArray()
	print("=== ", path, " ===")
	print("  anims(", anims.size(), "): ", ", ".join(anims))
	print("  aabb: ", str(_bounds(inst)))
	inst.queue_free()


func _bounds(root: Node) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var ab: AABB = mi.transform * mi.get_aabb()
			result = ab if first else result.merge(ab)
			first = false
	return result

func _find_anim(root: Node) -> AnimationPlayer:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is AnimationPlayer:
			return n
	return null
