## probe_anims.gd - 探针：列出模型的 AnimationPlayer 动画名（headless 可用）
## 用法: godot --headless --path . -s res://tools/probe_anims.gd
extends SceneTree

func _initialize() -> void:
	for path in ["res://assets/models/mage.glb", "res://assets/models/skeleton_mage.glb"]:
		var scene: PackedScene = load(path)
		if scene == null:
			print("[probe] load failed: ", path)
			continue
		var model: Node = scene.instantiate()
		var ap := _find_anim_player(model)
		if ap == null:
			print("[probe] no AnimationPlayer in ", path)
		else:
			print("[probe] ", path, " -> ", str(ap.get_animation_list()))
		model.free()
	quit(0)

func _find_anim_player(root: Node) -> AnimationPlayer:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
			if c is AnimationPlayer:
				return c
	return null
