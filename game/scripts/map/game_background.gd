## GameBackground - 游戏背景
## 动态背景效果
extends Node2D

## 网格间距
@export var grid_spacing: float = 100.0

## 网格颜色
@export var grid_color: Color = Color(0.2, 0.25, 0.3, 0.3)

## 网格宽度
@export var grid_width: float = 1.0

## 动画速度
@export var animation_speed: float = 0.5

## 当前偏移
var offset: Vector2 = Vector2.ZERO

func _draw() -> void:
	# 获取视口大小
	var viewport_size = get_viewport_rect().size
	
	# 计算需要绘制的网格数量
	var horizontal_lines = int(viewport_size.y / grid_spacing) + 2
	var vertical_lines = int(viewport_size.x / grid_spacing) + 2
	
	# 绘制水平线
	for i in range(horizontal_lines):
		var y = i * grid_spacing + offset.y
		var start = Vector2(0, y)
		var end = Vector2(viewport_size.x, y)
		draw_line(start, end, grid_color, grid_width)
	
	# 绘制垂直线
	for i in range(vertical_lines):
		var x = i * grid_spacing + offset.x
		var start = Vector2(x, 0)
		var end = Vector2(x, viewport_size.y)
		draw_line(start, end, grid_color, grid_width)
	
	# 绘制中心十字
	var center = viewport_size / 2
	draw_line(Vector2(center.x, 0), Vector2(center.x, viewport_size.y), 
			  Color(0.3, 0.4, 0.5, 0.5), 2.0)
	draw_line(Vector2(0, center.y), Vector2(viewport_size.x, center.y), 
			  Color(0.3, 0.4, 0.5, 0.5), 2.0)

func _process(delta: float) -> void:
	# 更新偏移
	offset.x += animation_speed * delta * 10
	offset.y += animation_speed * delta * 10
	
	# 循环偏移
	if offset.x >= grid_spacing:
		offset.x -= grid_spacing
	if offset.y >= grid_spacing:
		offset.y -= grid_spacing
	
	# 重绘
	queue_redraw()
