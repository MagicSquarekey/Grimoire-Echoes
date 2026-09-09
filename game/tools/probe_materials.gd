## probe_materials.gd - 诊断模型材质/贴图 + yaw270 朝向验证
extends Node

const PROBE_DIR := "C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/probe"

var vp: SubViewport
var stage: Node3D
var cam: Camera3D


func _ready() -> void:
	_build_stage()
	var tests := [
		{"path": "res://assets/models/creep_creature.glb", "anim": "Idle1_Action"},
		{"path": "res://assets/models/blue_demon.gltf", "anim": "Idle"},
		{"path": "res://assets/models/blue_demon.gltf", "anim": "Run"},
	]
	for t in tests:
		var model_path: String = t["path"]
		var scene: PackedScene = load(model_path)
		var model: Node3D = scene.instantiate()
		stage.add_child(model)
		print("=== ", model_path)
		_dump_materials(model)
		# yaw 270 侧视一帧
		var aabb := _compute_aabb(model)
		_place_camera(aabb, 270.0, 0.63)
		var ap := _find_anim_player(model)
		if ap:
			ap.play(String(t["anim"]))
			ap.seek(0.15, true)
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		var fname: String = model_path.get_file().get_basename() + "_" + str(t["anim"])
		img.save_png("%s/orient_%s.png" % [PROBE_DIR, fname])
		print("saved orient_", fname)
		model.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _dump_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mesh := mi.mesh
		if mesh:
			for s in mesh.get_surface_count():
				var mat := mesh.surface_get_material(s)
				if mat is StandardMaterial3D:
					var sm := mat as StandardMaterial3D
					print("  mesh=%s surf=%d mat=%s albedo_tex=%s transp=%d" % [
						mesh.get_name(), s, sm.resource_name, sm.albedo_texture != null, sm.transparency])
				elif mat != null:
					print("  mesh=%s surf=%d mat_type=%s" % [mesh.get_name(), s, mat.get_class()])
				else:
					print("  mesh=%s surf=%d mat=null" % [mesh.get_name(), s])
	for c in node.get_children():
		_dump_materials(c)


func _build_stage() -> void:
	vp = SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.size = Vector2i(320, 320)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	stage = Node3D.new()
	vp.add_child(stage)
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.85, 0.92)
	env.ambient_light_energy = 0.85
	var we := WorldEnvironment.new()
	we.environment = env
	stage.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 1.25
	stage.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 40.0
	cam.current = true
	stage.add_child(cam)


func _place_camera(aabb: AABB, yaw_deg: float, dist_scale: float) -> void:
	var pitch := deg_to_rad(-50.0)
	var yaw := deg_to_rad(yaw_deg)
	var target: Vector3 = aabb.get_center()
	var vspan: float = aabb.size.y * absf(cos(pitch)) + aabb.size.z * absf(sin(pitch))
	var hspan: float = maxf(aabb.size.x, aabb.size.z)
	var fit: float = maxf(vspan, hspan * 0.85) * 0.5 / tan(deg_to_rad(20.0))
	var dist: float = fit * 2.05 * dist_scale
	cam.position = target + Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.look_at(target, Vector3.UP)


func _compute_aabb(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var ab: AABB = mi.global_transform * mi.get_aabb()
			if first:
				result = ab
				first = false
			else:
				result = result.merge(ab)
	return result


func _find_anim_player(root: Node) -> AnimationPlayer:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is AnimationPlayer:
			return n
	return null
