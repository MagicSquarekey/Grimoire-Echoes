## WindWall - 风之壁垒
## 风暴系防御法术
class_name WindWall
extends BuffSpell

# 风之壁垒特有属性
@export var wall_duration: float = 5.0  # 持续时间
@export var wall_width: float = 150.0  # 墙壁宽度
@export var wall_height: float = 100.0  # 墙壁高度
@export var deflect_range: float = 50.0  # 偏转范围

func _init() -> void:
	spell_name = "风之壁垒"
	spell_element = "air"
	spell_type = SpellType.SHIELD
	damage = 0
	cooldown = 12.0
	mana_cost = 20.0
	buff_type = "shield"
	buff_duration = wall_duration

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 应用风之壁垒效果
	_apply_wind_wall(target if target else owner_node)

## 应用风之壁垒效果
func _apply_wind_wall(target: Node2D) -> void:
	# 创建风之壁垒
	_create_wind_wall(target)
	
	# 开始持续时间计时
	is_active = true
	active_timer = wall_duration

## 创建风之壁垒
func _create_wind_wall(target: Node2D) -> void:
	# 创建壁垒区域
	var wall_area = Area2D.new()
	wall_area.name = "WindWallArea"
	wall_area.global_position = target.global_position + Vector2(0, -wall_height / 2.0)
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(wall_width, wall_height)
	collision.shape = rectangle
	wall_area.add_child(collision)
	
	# 设置碰撞层
	wall_area.collision_layer = 0
	wall_area.collision_mask = 4  # 投射物层
	
	# 添加到场景
	target.add_child(wall_area)
	
	# 创建视觉效果
	_create_wall_visual(wall_area)
	
	# 开始偏转投射物
	_process_projectile_deflection(wall_area)

## 创建壁垒视觉效果
func _create_wall_visual(area: Area2D) -> void:
	# 创建壁垒精灵
	var wall_sprite = Sprite2D.new()
	wall_sprite.name = "WindWallSprite"
	wall_sprite.modulate = Color(0.8, 0.9, 1.0, 0.5)  # 浅蓝色
	wall_sprite.scale = Vector2(3.0, 2.0)  # 长条形
	area.add_child(wall_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "WindWallParticles"
	particles.emitting = true
	particles.lifetime = wall_duration
	particles.amount = 15
	area.add_child(particles)

## 开始偏转投射物
func _process_projectile_deflection(wall_area: Area2D) -> void:
	# 连接投射物检测信号
	wall_area.area_entered.connect(_on_projectile_entered.bind(wall_area))
	wall_area.body_entered.connect(_on_projectile_body_entered.bind(wall_area))

## 投射物进入壁垒时的处理
func _on_projectile_entered(area: Area2D, wall_area: Area2D) -> void:
	if area.is_in_group("projectiles"):
		# 偏转投射物
		_deflect_projectile(area)

## 投射物物理体进入壁垒时的处理
func _on_projectile_body_entered(body: Node2D, wall_area: Area2D) -> void:
	if body.is_in_group("projectiles"):
		# 偏转投射物
		_deflect_projectile(body)

## 偏转投射物
func _deflect_projectile(projectile: Node2D) -> void:
	# 反转投射物方向
	if projectile.has_method("setup"):
		# 获取当前属性
		var current_direction = projectile.direction if projectile.has("direction") else Vector2.RIGHT
		var new_direction = -current_direction  # 反转方向
		
		# 重新设置投射物
		projectile.setup(
			projectile.damage,
			projectile.speed,
			new_direction,
			projectile.element,
			projectile.pierce,
			projectile.knockback,
			projectile.spell_level,
			owner_node  # 将所有者改为玩家
		)
		
		# 创建偏转视觉效果
		_create_deflect_visual(projectile.global_position)

## 创建偏转视觉效果
func _create_deflect_visual(position: Vector2) -> void:
	# 创建偏转精灵
	var deflect_sprite = Sprite2D.new()
	deflect_sprite.modulate = Color(0.8, 0.9, 1.0, 0.7)  # 浅蓝色
	deflect_sprite.global_position = position
	get_tree().current_scene.add_child(deflect_sprite)
	
	# 延迟销毁
	await get_tree().create_timer(0.2).timeout
	deflect_sprite.queue_free()

## 重写法术升级
func _on_upgrade() -> void:
	wall_duration *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 持续+2秒
			wall_duration += 2.0
			print("风之壁垒升级: 持续时间增加")
		10:
			# Lv.10: 偏转+反弹
			print("风之壁垒升级: 偏转+反弹")
		15:
			# Lv.15: 绝对防御
			print("风之壁垒升级: 绝对防御")