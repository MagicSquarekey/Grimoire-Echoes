## diag_subdiv.gd - 细分+平滑诊断
extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://assets/models/kaykit/Skeleton_Minion.glb")
	var inst: Node3D = scene.instantiate()
	get_root().add_child(inst)
	var stack: Array[Node] = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var mesh := mi.mesh
			if mesh == null:
				continue
			for s in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(s)
				var vcount: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() if arr[Mesh.ARRAY_VERTEX] != null else 0
				var has_norm: bool = arr[Mesh.ARRAY_NORMAL] != null
				var has_idx: bool = arr[Mesh.ARRAY_INDEX] != null
				print("surface %d: verts=%d normal=%s index=%s" % [s, vcount, has_norm, has_idx])
			# 细分一次
			var sub := _subdivide(mesh)
			for s in sub.get_surface_count():
				var arr := sub.surface_get_arrays(s)
				var nrm = arr[Mesh.ARRAY_NORMAL]
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				print("subdiv surface %d: verts=%d normals=%s" % [s, v.size(), "null" if nrm == null else str((nrm as PackedVector3Array).size())])
	inst.queue_free()
	quit(0)

func _subdivide(mesh: Mesh) -> ArrayMesh:
	var new_mesh := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		print("  subdiv in: verts=%d idx=%d uv=%s" % [verts.size(), idx.size(), "yes" if uvs != null else "no"])
		var has_uv: bool = uvs != null and uvs.size() > 0
		var new_verts := verts.duplicate()
		var new_uvs := uvs.duplicate() if has_uv else PackedVector2Array()
		var cache := {}
		var new_idx := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			var abc := [idx[t], idx[t + 1], idx[t + 2]]
			var mids: Array[int] = []
			for k in 3:
				var a: int = abc[k]
				var b: int = abc[(k + 1) % 3]
				var lo := mini(a, b)
				var hi := maxi(a, b)
				var key := "%d_%d" % [lo, hi]
				if not cache.has(key):
					new_verts.append((verts[a] + verts[b]) * 0.5)
					if has_uv:
						new_uvs.append((uvs[a] + uvs[b]) * 0.5)
					cache[key] = new_verts.size() - 1
				mids.append(cache[key])
			new_idx.append_array(PackedInt32Array([abc[0], mids[0], mids[2], mids[0], abc[1], mids[1], mids[2], abc[2], mids[0] if false else mids[1], mids[0], mids[1], mids[2]]))
		var out := []
		out.resize(Mesh.ARRAY_MAX)
		out[Mesh.ARRAY_VERTEX] = new_verts
		out[Mesh.ARRAY_INDEX] = new_idx
		if has_uv:
			out[Mesh.ARRAY_TEX_UV] = new_uvs
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	return new_mesh
