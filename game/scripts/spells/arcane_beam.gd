## ArcaneBeam - 穿透光束
## 奥术系直线法术：朝最近敌人方向瞬发直线穿透光束（Line2D 加法混合，0.15s 渐隐），
## 光束路径上所有敌人受伤。
class_name ArcaneBeam
extends BaseSpell

## 光束参数
@export var beam_length: float = 420.0
@export var beam_width: float = 14.0
@export var beam_life: float = 0.15

func _init() -> void:
	spell_name = "穿透光束"
	spell_element = "arcane"
	spell_type = SpellType.FAN
	damage = 18.0
	cooldown = 1.6
	mana_cost = 0.0  # 自动战斗法术不消耗法力
	cast_range = 500.0

## 施放：朝目标方向瞬发穿透光束
func _on_cast(target = null) -> void:
	var origin: Vector2 = owner_node.global_position if owner_node is Node2D else global_position
	var dir := _cast_direction(origin, target)
	_fire_beam(origin, dir)

## 施法方向：目标 → 最近敌人 → 面前
func _cast_direction(origin: Vector2, target = null) -> Vector2:
	var target_pos := Vector2.ZERO
	if target is Vector2:
		target_pos = target
	elif target is Node2D and is_instance_valid(target):
		target_pos = target.global_position
	else:
		var nearest: Node2D = null
		var best := INF
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.get("is_alive"):
				var d: float = origin.distance_to(e.global_position)
				if d < best:
					best = d
					nearest = e
		target_pos = nearest.global_position if nearest else origin + Vector2(100, 0)
	var to_target := target_pos - origin
	return to_target.normalized() if to_target.length() > 1.0 else Vector2.RIGHT

## 发射光束：命中线上敌人 + 光束视觉
func _fire_beam(origin: Vector2, dir: Vector2) -> void:
	if get_tree() == null:
		return
	var end := origin + dir * beam_length
	var normal := dir.orthogonal()

	# 命中线上所有敌人（点到直线距离 ≤ 光束半宽 + 敌人碰撞余量）
	var hit_radius := beam_width * 0.5 + 14.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.get("is_alive"):
			continue
		var to_e: Vector2 = enemy.global_position - origin
		var along := to_e.dot(dir)
		if along < 0.0 or along > beam_length:
			continue
		if absf(to_e.dot(normal)) <= hit_radius:
			_apply_damage(enemy)
			# 光束命中点爆裂（arcane 预设）
			FxLib.element_burst(self, enemy.global_position, spell_element, 0.55)

	# 光束视觉（两层：宽柔光 + 细亮芯）
	_spawn_beam_visual(origin, end)

## 光束视觉：加法混合 Line2D，0.15s 渐隐消散
func _spawn_beam_visual(origin: Vector2, end: Vector2) -> void:
	var preset := FxLib.preset_for(spell_element)
	var col: Color = preset["color"]
	var dir := (end - origin).normalized()
	var host := get_tree().current_scene
	if host == null:
		return

	var beam := Node2D.new()
	beam.global_position = origin
	beam.z_index = 4
	host.add_child(beam)

	var pts := PackedVector2Array([Vector2.ZERO, end - origin])
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	# 外层柔光
	var outer := Line2D.new()
	outer.material = mat
	outer.points = pts
	outer.width = beam_width
	outer.modulate = Color(col.r, col.g, col.b, 0.55)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.1)])
	outer.gradient = grad
	beam.add_child(outer)

	# 内层亮芯（蓝白）
	var core := Line2D.new()
	core.material = mat
	core.points = pts
	core.width = beam_width * 0.38
	core.modulate = Color(0.88, 0.95, 1.0, 0.95)
	beam.add_child(core)

	# 持续期轻微闪烁 → 0.15s 渐隐
	var tw := beam.create_tween()
	tw.tween_property(core, "width", beam_width * 0.28, beam_life * 0.5)
	tw.parallel().tween_property(beam, "modulate:a", 0.0, beam_life)
	tw.tween_callback(beam.queue_free)

	# 施法点小闪爆
	FxLib.element_burst(self, origin + dir * 20.0, spell_element, 0.4)
