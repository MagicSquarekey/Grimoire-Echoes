## FireballProjectile - 火球投射物
## 火球术的投射物实现
class_name FireballProjectile
extends Area2D

# 属性
var damage: float = 25.0
var explosion_radius: float = 50.0
var burn_damage: float = 5.0
var burn_duration: float = 3.0
var spell_level: int = 1
var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT

# 组件引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready() -> void:
	# 连接信号
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	
	# 启动粒子
	particles.emitting = true

func _physics_process(delta: float) -> void:
	# 移动
	position += direction * speed * delta

## 设置火球属性
func setup(
	_damage: float,
	_explosion_radius: float,
	_burn_damage: float,
	_burn_duration: float,
	_spell_level: int
) -> void:
	damage = _damage
	explosion_radius = _explosion_radius
	burn_damage = _burn_damage
	burn_duration = _burn_duration
	spell_level = _spell_level

## 碰撞检测 - 区域
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		_hit_target(area.get_parent())

## 碰撞检测 - 物理体
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		_hit_target(body)

## 命中目标
func _hit_target(target: Node2D) -> void:
	# 应用伤害
	if target.has_method("take_damage"):
		target.take_damage(damage, self)
	
	# 应用燃烧效果
	if target.has_method("apply_status_effect"):
		target.apply_status_effect("burn", burn_damage, burn_duration)
	
	# 爆炸效果
	_explode()
	
	# 销毁投射物
	queue_free()

## 爆炸效果
func _explode() -> void:
	# 获取爆炸范围内所有敌人
	var enemies = _get_enemies_in_explosion()
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage * 0.5, self)  # 爆炸伤害为50%
	
	# 播放爆炸粒子效果
	# TODO: 实现爆炸粒子

## 获取爆炸范围内敌人
func _get_enemies_in_explosion() -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var space_state = get_world_2d().direct_space_state
	
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2  # 敌人层
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is Node2D and collider.is_in_group("enemies"):
			enemies.append(collider)
	
	return enemies

## 生命周期结束
func _on_lifetime_timeout() -> void:
	queue_free()
