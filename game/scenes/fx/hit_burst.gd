## HitBurst - 通用一次性爆裂粒子（CPUParticles2D, GL Compatibility 下比 GPU 稳）
## 由 FxLib.hit_burst() 统一生成；one_shot + 定时自毁，保证无节点泄漏。
class_name HitBurst
extends CPUParticles2D


func _ready() -> void:
	# 兜底自毁：即使发射逻辑异常，也能在最长寿命后清掉自己，防止泄漏
	get_tree().create_timer(lifetime + 1.0).timeout.connect(_self_free)


## 在 pos 处播放一次爆裂
## angular_max/damping/particle_scale 支持元素化运动模式（自旋/阻尼/尺寸），
## 均带默认值，旧调用不受影响。
func emit_burst(
	pos: Vector2,
	color: Color,
	count: int = 12,
	speed_min: float = 90.0,
	speed_max: float = 170.0,
	life: float = 0.4,
	gravity: Vector2 = Vector2.ZERO,
	angular_max: float = 0.0,
	damping: float = 0.0,
	particle_scale: float = 1.0
) -> void:
	global_position = pos
	self.color = color
	# CPUParticles2D 无 amount_ratio（那是 GPU 粒子的属性），直接设置本次数量
	amount = clampi(count, 1, 32)
	initial_velocity_min = speed_min
	initial_velocity_max = speed_max
	lifetime = life
	self.gravity = gravity
	if angular_max != 0.0:
		angular_velocity_min = -angular_max
		angular_velocity_max = angular_max
	if damping != 0.0:
		damping_min = damping
		damping_max = damping
	if not is_equal_approx(particle_scale, 1.0):
		scale_amount_min = particle_scale
		scale_amount_max = particle_scale * 1.3
	restart()
	# 正常路径：寿命结束后立即自毁
	get_tree().create_timer(life + 0.25).timeout.connect(_self_free)


func _self_free() -> void:
	queue_free()
