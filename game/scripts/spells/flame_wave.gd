## FlameWave - 烈焰波
## 火焰系扇形法术
class_name FlameWave
extends BaseSpell

# 烈焰波特有属性
@export var wave_angle: float = 60.0  # 扇形角度
@export var wave_distance: float = 200.0  # 扇形距离
@export var burn_damage: float = 8.0  # 燃烧伤害
@export var burn_duration: float = 3.0  # 燃烧持续时间

func _init() -> void:
	spell_name = "烈焰波"
	spell_element = "fire"
	spell_type = SpellType.FAN
	damage = 30.0
	cooldown = 2.5
	mana_cost = 15.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取扇形范围内的敌人
	var enemies = _get_enemies_in_fan(global_position, wave_distance, wave_angle)
	
	for enemy in enemies:
		# 应用伤害
		_apply_damage(enemy)
		
		# 应用燃烧效果
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect(
				StatusEffectSystem.EffectType.BURN,
				burn_damage,
				burn_duration
			)

## 获取扇形范围内的敌人
func _get_enemies_in_fan(center: Vector2, distance: float, angle: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	# 获取施法方向
	var cast_direction = Vector2.RIGHT
	if owner_node:
		cast_direction = owner_node.global_position.direction_to(get_global_mouse_position())
	
	# 圆形查询
	var shape = CircleShape2D.new()
	shape.radius = distance
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, center)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			# 检查是否在扇形角度内
			var enemy_direction = center.direction_to(collider.global_position)
			var angle_to_enemy = rad_to_deg(cast_direction.angle_to(enemy_direction))
			
			if abs(angle_to_enemy) <= angle / 2.0:
				enemies.append(collider)
	
	return enemies

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 扇形角度+40%
			wave_angle *= 1.4
			print("烈焰波升级: 扇形角度增加")
		10:
			# Lv.10: 击退效果
			print("烈焰波升级: 获得击退效果")
		15:
			# Lv.15: 燃烧时间翻倍
			burn_duration *= 2.0
			print("烈焰波升级: 燃烧时间翻倍")