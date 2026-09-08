## CurseMark - 诅咒印记
## 暗影系标记法术
class_name CurseMark
extends BaseSpell

# 诅咒印记特有属性
@export var mark_count: int = 2  # 标记敌人数量
@export var mark_duration: float = 6.0  # 标记持续时间
@export var damage_increase: float = 0.15  # 伤害增加15%
@export var mark_range: float = 250.0  # 标记范围

# 标记状态
var marked_enemies: Array[Node2D] = []

func _init() -> void:
	spell_name = "诅咒印记"
	spell_element = "shadow"
	spell_type = SpellType.MARK
	damage = 0  # 标记本身无伤害
	cooldown = 5.0
	mana_cost = 15.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取最近的敌人进行标记
	var enemies = _get_nearest_enemies(mark_count)
	
	for enemy in enemies:
		# 应用标记
		_apply_mark(enemy)

## 获取最近的敌人
func _get_nearest_enemies(count: int) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = mark_range
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, owner_node.global_position)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			enemies.append(collider)
	
	# 按距离排序
	enemies.sort_custom(func(a, b): 
		return owner_node.global_position.distance_to(a.global_position) < owner_node.global_position.distance_to(b.global_position)
	)
	
	# 返回最近的敌人
	return enemies.slice(0, count)

## 应用标记
func _apply_mark(enemy: Node2D) -> void:
	# 添加到标记列表
	if not enemy in marked_enemies:
		marked_enemies.append(enemy)
		
		# 应用标记视觉效果
		_mark_visual_effect(enemy)
		
		# 应用伤害增加效果
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.CURSE,
				damage_increase,
				mark_duration
			)
		
		# 标记结束时移除
		_schedule_mark_removal(enemy)

## 标记视觉效果
func _mark_visual_effect(enemy: Node2D) -> void:
	# 创建标记精灵
	var mark_sprite = Sprite2D.new()
	mark_sprite.name = "CurseMarkSprite"
	mark_sprite.modulate = Color(0.3, 0.0, 0.5, 0.8)  # 深紫色
	mark_sprite.scale = Vector2(0.5, 0.5)
	enemy.add_child(mark_sprite)

## 定时移除标记
func _schedule_mark_removal(enemy: Node2D) -> void:
	# 等待标记持续时间
	await get_tree().create_timer(mark_duration).timeout
	
	# 检查敌人是否仍然存在
	if is_instance_valid(enemy) and enemy in marked_enemies:
		# 从标记列表中移除
		marked_enemies.erase(enemy)
		
		# 移除标记视觉效果
		if enemy.has_node("CurseMarkSprite"):
			enemy.get_node("CurseMarkSprite").queue_free()

## 清除所有标记
func clear_marks() -> void:
	for enemy in marked_enemies:
		if is_instance_valid(enemy):
			# 移除标记视觉效果
			if enemy.has_node("CurseMarkSprite"):
				enemy.get_node("CurseMarkSprite").queue_free()
	
	marked_enemies.clear()

## 重写法术升级
func _on_upgrade() -> void:
	damage_increase *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 伤害增加+10%
			damage_increase += 0.1
			print("诅咒印记升级: 伤害增加效果增强")
		10:
			# Lv.10: 双重诅咒
			mark_count += 1
			print("诅咒印记升级: 标记数量增加")
		15:
			# Lv.15: 诅咒传染
			print("诅咒印记升级: 诅咒传染")