## PulseGlow - 拾取物脉动光晕（加法混合呼吸：缩放 + 透明度正弦脉动）
## 挂在拾取物场景的加色光晕 Sprite2D 上，随机相位避免同屏多个拾取物同步闪烁。
extends Sprite2D

@export var base_scale: Vector2 = Vector2(1.0, 1.0)
@export var breathe_speed: float = 3.0
@export var scale_amp: float = 0.12
@export var alpha_min: float = 0.4
@export var alpha_max: float = 0.75

var _t: float = 0.0


func _ready() -> void:
	_t = randf() * TAU  # 随机相位


func _process(delta: float) -> void:
	_t += delta * breathe_speed
	var s := sin(_t)
	scale = base_scale * (1.0 + scale_amp * s)
	modulate.a = (alpha_min + alpha_max) * 0.5 + (alpha_max - alpha_min) * 0.5 * s
