## TrailFx - 弹体拖尾（Line2D 历史点渐隐，轻量方案：点数上限 12）
## 节点挂在 projectile.tscn 下作为子节点；每帧把记录的世界坐标历史回写为局部坐标。
## 池化/复用前必须调用 reset_trail() 清空历史点，避免出现横跨屏幕的拖尾条纹。
class_name TrailFx
extends Line2D

@export var max_points: int = 12
@export var min_point_dist: float = 5.0
## 锯齿抖动幅度（px）：>0 时每个历史点逐帧随机偏移，模拟闪电锯齿（lightning 元素用）
@export var jitter: float = 0.0

var _world_pts := PackedVector2Array()


func _ready() -> void:
	clear_points()


## 复用初始化：清空历史点（projectile 的 setup 钩子会调用）
func reset_trail() -> void:
	_world_pts = PackedVector2Array()
	clear_points()


func _process(_delta: float) -> void:
	var gp := global_position
	if _world_pts.is_empty() or gp.distance_to(_world_pts[0]) >= min_point_dist:
		_world_pts.insert(0, gp)
	while _world_pts.size() > max_points:
		_world_pts.remove_at(_world_pts.size() - 1)
	# 世界坐标 → 相对拖尾节点的局部坐标（拖尾节点跟随弹体移动）
	var local := PackedVector2Array()
	local.resize(_world_pts.size())
	var do_jitter := jitter > 0.0
	for i in _world_pts.size():
		# 闪电：越靠近弹头的点抖动越大（尾部渐稳），逐帧随机 → 闪烁锯齿
		local[i] = _world_pts[i] - gp
		if do_jitter:
			var amp := jitter * (1.0 - float(i) / float(max_points))
			local[i] += Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	points = local
