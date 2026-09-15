## ChainLightning - 连锁闪电
## 雷电系连锁法术
class_name ChainLightning
extends BaseSpell

# 连锁闪电特有属性
@export var max_chain_count: int = 5  # 最大弹射数量
@export var chain_range: float = 200.0  # 弹射范围
@export var chain_damage_reduction: float = 0.2  # 弹射伤害递减20%
@export var chain_delay: float = 0.15  # 弹射延迟

# 已弹射目标
var chain_targets: Array[Node2D] = []

func _init() -> void:
	spell_name = "连锁闪电"
	spell_element = "lightning"
	spell_type = SpellType.CHAIN
	damage = 25.0
	cooldown = 4.0
	mana_cost = 0.0  # 自动战斗法术不消耗法力

## 重写施放逻辑（target 可能是 Vector2 坐标——auto_cast 传最近敌人坐标）
func _on_cast(target = null) -> void:
	# 清空弹射目标列表
	chain_targets.clear()

	# 获取初始目标：坐标 → 就近解析为敌人节点
	var initial_target: Node2D = null
	if target is Node2D and is_instance_valid(target):
		initial_target = target
	else:
		var search_pos: Vector2 = target if target is Vector2 else owner_node.global_position
		initial_target = _nearest_enemy_to(search_pos)

	if initial_target:
		# 开始连锁闪电
		_chain_lightning(initial_target, _calculate_damage())

## 就近解析敌人（含无敌人时的 null 回退）
func _nearest_enemy_to(pos: Vector2) -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.get("is_alive"):
			var d: float = pos.distance_to(e.global_position)
			if d < best:
				best = d
				nearest = e
	return nearest

## 获取最近的敌人
func _get_nearest_enemy() -> Node2D:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = 300.0  # 搜索范围
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, owner_node.global_position)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			enemies.append(collider)
	
	if enemies.size() == 0:
		return null
	
	# 按距离排序
	enemies.sort_custom(func(a, b): 
		return owner_node.global_position.distance_to(a.global_position) < owner_node.global_position.distance_to(b.global_position)
	)
	
	return enemies[0]

## 连锁闪电
func _chain_lightning(target: Node2D, current_damage: float) -> void:
	# 目标可能在等待期间死亡/回收
	if not is_instance_valid(target):
		return

	# 标记目标已弹射
	chain_targets.append(target)

	# 应用伤害
	if target.has_method("take_damage"):
		target.take_damage(current_damage, owner_node)

	# 创建闪电视觉效果
	var from_pos: Vector2 = owner_node.global_position if (chain_targets.size() == 1 and owner_node is Node2D) \
			else (chain_targets[-2].global_position if chain_targets.size() >= 2 and is_instance_valid(chain_targets[-2]) else target.global_position)
	_create_chain_visual(from_pos, target.global_position)

	# 检查是否达到最大弹射数量
	if chain_targets.size() >= max_chain_count:
		return

	# 获取下一个弹射目标
	var next_target = _get_chain_target(target)
	if next_target:
		# 等待弹射延迟（期间场景可能切换）
		await get_tree().create_timer(chain_delay).timeout
		if not is_inside_tree():
			return

		# 计算弹射后的伤害
		var next_damage = current_damage * (1.0 - chain_damage_reduction)

		# 继续连锁
		_chain_lightning(next_target, next_damage)

## 获取连锁目标
func _get_chain_target(from: Node2D) -> Node2D:
	if not is_instance_valid(from):
		return null
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = chain_range
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, from.global_position)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies") and not collider in chain_targets:
			enemies.append(collider)
	
	if enemies.size() == 0:
		return null
	
	# 按距离排序
	enemies.sort_custom(func(a, b): 
		return from.global_position.distance_to(a.global_position) < from.global_position.distance_to(b.global_position)
	)
	
	return enemies[0]

## 创建连锁视觉效果：锯齿闪线（加法混合 Line2D，逐帧抖动）+ 命中闪爆
func _create_chain_visual(from: Vector2, to: Vector2) -> void:
	var preset := FxLib.preset_for("lightning")
	var col: Color = preset["color"]

	var bolt := Line2D.new()
	bolt.material = CanvasItemMaterial.new()
	bolt.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	bolt.width = 5.0
	bolt.modulate = Color(col.r, col.g, col.b, 0.95)
	bolt.joint_mode = Line2D.LINE_JOINT_ROUND
	var seg := maxi(4, int(from.distance_to(to) / 30.0))
	var pts := PackedVector2Array()
	var dir := (to - from) / float(seg)
	var normal := dir.normalized().orthogonal()
	for i in range(seg + 1):
		var p := dir * float(i)
		# 端点固定、中段随机偏移形成锯齿
		if i > 0 and i < seg:
			p += normal * randf_range(-12.0, 12.0)
		pts.append(p)
	bolt.points = pts
	bolt.global_position = from
	get_tree().current_scene.add_child(bolt)

	# 逐帧抖动闪烁 + 渐隐自毁（0.12s）
	var tw := bolt.create_tween()
	for _i in range(3):
		tw.tween_callback(_jitter_bolt.bind(bolt))
		tw.tween_interval(0.03)
	tw.tween_property(bolt, "modulate:a", 0.0, 0.04)
	tw.tween_callback(bolt.queue_free)

	# 命中点紫色闪爆（lightning 预设：紫白抖动闪线粒子）
	FxLib.element_burst(self, to, spell_element, 0.8)

## 闪电锯齿重抖一帧
func _jitter_bolt(bolt: Line2D) -> void:
	if not is_instance_valid(bolt) or bolt.points.size() < 3:
		return
	var pts := bolt.points
	for i in range(1, pts.size() - 1):
		pts[i] += Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
	bolt.points = pts

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 弹射+3
			max_chain_count += 3
			print("连锁闪电升级: 弹射数量增加")
		10:
			# Lv.10: 无伤害递减
			chain_damage_reduction = 0.0
			print("连锁闪电升级: 弹射无递减")
		15:
			# Lv.15: 全屏弹射
			chain_range = 500.0
			print("连锁闪电升级: 弹射范围增加")