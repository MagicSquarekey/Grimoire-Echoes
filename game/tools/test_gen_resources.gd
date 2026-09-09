## test_gen_resources.gd - 验证生成的 SpriteFrames .tres 可加载、动画齐全
extends SceneTree

func _init() -> void:
	var ok := true
	for prefix in ["player_water", "player_fire", "player_lightning",
			"enemy_skeleton_mage", "enemy_shadow_servant", "enemy_swarm_bug"]:
		var path := "res://assets/sprites/gen/%s.tres" % prefix
		if not ResourceLoader.exists(path):
			print("[FAIL] missing ", path)
			ok = false
			continue
		var sf: SpriteFrames = load(path)
		if sf == null:
			print("[FAIL] load null ", path)
			ok = false
			continue
		var anims := sf.get_animation_names()
		var line := "[OK] %s anims=%s" % [prefix, str(anims)]
		for need in ["idle", "run"]:
			if not anims.has(need):
				line += " MISSING:" + need
				ok = false
			else:
				line += " (%s:%df)" % [need, sf.get_frame_count(need)]
		print(line)
		var tex: Texture2D = sf.get_frame_texture(anims[0], 0)
		print("     frame0 tex=", tex != null, " size=", tex.get_size() if tex else Vector2.ZERO)
	var shadow := load("res://assets/sprites/gen/shadow_blob.png")
	print("[OK] shadow_blob.png size=", shadow.get_size())
	for p in ["portraits/player_water.png", "portraits/player_fire.png", "portraits/player_lightning.png"]:
		var t: Texture2D = load("res://assets/sprites/gen/" + p)
		print("[OK] ", p, " size=", t.get_size())
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit()
