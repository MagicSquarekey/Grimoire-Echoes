## ParticleEffect - 粒子效果
## 用于敌人死亡、法术命中等视觉效果
extends Node2D

## 效果颜色
@export var effect_color: Color = Color(1, 1, 1, 1)

## 粒子数量
@export var particle_count: int = 8

## 粒子大小
@export var particle_size: float = 4.0

## 粒子速度
@export var particle_speed: float = 100.0

## 效果持续时间
@export var lifetime: float = 0.5

## 粒子数组
var particles: Array[Polygon2D] = []
var velocities: Array[Vector2] = []

func _ready() -> void:
	# 创建粒子
	for i in range(particle_count):
		var particle = Polygon2D.new()
		particle.polygon = PackedVector2Array([
			Vector2(-particle_size, -particle_size),
			Vector2(particle_size, -particle_size),
			Vector2(particle_size, particle_size),
			Vector2(-particle_size, particle_size)
		])
		particle.color = effect_color
		particle.position = Vector2.ZERO
		add_child(particle)
		particles.append(particle)
		
		# 随机速度方向
		var angle = randf() * TAU
		var speed = randf_range(particle_speed * 0.5, particle_speed)
		velocities.append(Vector2(cos(angle), sin(angle)) * speed)
	
	# 启动销毁计时器
	get_tree().create_timer(lifetime).timeout.connect(_destroy)

func _process(delta: float) -> void:
	# 更新粒子位置
	for i in range(particles.size()):
		if particles[i]:
			particles[i].position += velocities[i] * delta
			# 逐渐透明
			particles[i].color.a -= delta / lifetime
			# 缩小
			particles[i].scale *= 0.98

## 销毁效果
func _destroy() -> void:
	queue_free()

## 设置效果颜色
func set_color(color: Color) -> void:
	effect_color = color
	for particle in particles:
		if particle:
			particle.color = color
