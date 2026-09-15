## GameCamera - 玩家相机（带震动反馈）
## 挂在玩家 Camera2D 上；通过组调用或脚本静态入口触发震动：
##   GameCameraScript.shake_global(强度, 时长)
extends Camera2D

## 当前震动强度（px）
var _shake_strength: float = 0.0
## 震动衰减时长
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0

func _ready() -> void:
	add_to_group("game_camera")

func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var decay := clampf(_shake_timer / maxf(_shake_duration, 0.001), 0.0, 1.0)
		offset = Vector2(
			randf_range(-1, 1) * _shake_strength * decay,
			randf_range(-1, 1) * _shake_strength * decay
		)
	else:
		offset = Vector2.ZERO

## 触发一次屏幕震动（strength 像素幅度，duration 秒）
func shake(strength: float = 6.0, duration: float = 0.25) -> void:
	# 取更强的一次，避免连续弱震动覆盖强震动
	if strength * duration > _shake_strength * maxf(_shake_timer, 0.001) * 0.6:
		_shake_strength = strength
		_shake_duration = duration
		_shake_timer = duration

## 静态便捷入口：对场景中相机触发震动（经组查找，不依赖全局类注册）
static func shake_global(strength: float, duration: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for cam in tree.get_nodes_in_group("game_camera"):
		if cam.has_method("shake"):
			cam.shake(strength, duration)
			return
