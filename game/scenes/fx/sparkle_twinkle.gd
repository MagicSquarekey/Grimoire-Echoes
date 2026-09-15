## SparkleTwinkle - 金币偶发星芒闪点
## 加法混合小光点，随机间隔播放一次快速缩放+闪亮+消隐的星芒动画。
extends Sprite2D

@export var min_interval: float = 0.9
@export var max_interval: float = 2.4

var _t: float = 0.0
var _next: float = 1.0
var _tw: Tween


func _ready() -> void:
	modulate.a = 0.0
	_next = randf_range(min_interval, max_interval)


func _process(delta: float) -> void:
	_t += delta
	if _t >= _next:
		_t = 0.0
		_next = randf_range(min_interval, max_interval)
		flash()


## 播放一次星芒闪点（供复用/验证时手动触发）
func flash() -> void:
	if _tw and _tw.is_valid():
		_tw.kill()
	rotation = randf() * PI
	scale = Vector2(0.35, 0.35)
	modulate.a = 0.0
	_tw = create_tween()
	_tw.set_parallel(true)
	_tw.tween_property(self, "modulate:a", 0.95, 0.07)
	_tw.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)
	_tw.chain().tween_property(self, "modulate:a", 0.0, 0.22)
