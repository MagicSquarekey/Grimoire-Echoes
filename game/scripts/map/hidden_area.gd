## HiddenArea - 隐藏区域
## 地图中的隐藏区域和秘密地点
class_name HiddenArea
extends Area2D

## 隐藏区域属性
@export var area_name: String = ""
@export var unlock_condition: String = ""  # 解锁条件
@export var reward_type: String = ""  # 奖励类型
@export var reward_value: float = 0.0

## 状态
var is_unlocked: bool = false
var is_discovered: bool = false

## 组件引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interact_area: Area2D = $InteractArea

## 信号
signal area_discovered()
signal area_unlocked()
signal reward_collected()

func _ready() -> void:
	# 连接信号
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	
	# 初始状态
	_update_visual()

## 碰撞检测
func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_try_unlock(body)

## 尝试解锁
func _try_unlock(player: Node2D) -> void:
	if is_unlocked:
		return
	
	# 检查解锁条件
	if _check_unlock_condition(player):
		_unlock_area()
		_collect_reward(player)

## 检查解锁条件
func _check_unlock_condition(player: Node2D) -> bool:
	match unlock_condition:
		"destroy_trees":
			# 需要摧毁特定树木
			return true  # 简化实现
		"find_path":
			# 需要找到隐藏路径
			return true
		"defeat精英":
			# 需要击败精英怪
			return true
		_:
			return true

## 解锁区域
func _unlock_area() -> void:
	is_unlocked = true
	is_discovered = true
	
	# 播放解锁动画
	_play_unlock_animation()
	
	# 发送信号
	area_unlocked.emit()
	area_discovered.emit()

## 收集奖励
func _collect_reward(player: Node2D) -> void:
	match reward_type:
		"relic":
			# 给予遗物
			pass
		"gold":
			# 给予金币
			GameManager.add_gold(int(reward_value))
		"exp":
			# 给予经验值
			EventBus.enemy_killed.emit("", int(reward_value), 0)
		"spell":
			# 给予法术
			pass
	
	# 发送信号
	reward_collected.emit()

## 播放解锁动画
func _play_unlock_animation() -> void:
	# 淡出效果
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	# 隐藏碰撞体
	collision_shape.set_deferred("disabled", true)

## 更新视觉效果
func _update_visual() -> void:
	if is_unlocked:
		visible = false
	else:
		# 显示提示效果（如发光的蘑菇）
		modulate = Color(0.5, 1.0, 0.5, 0.8)

## 获取区域信息
func get_area_info() -> Dictionary:
	return {
		"name": area_name,
		"unlock_condition": unlock_condition,
		"reward_type": reward_type,
		"is_unlocked": is_unlocked,
		"is_discovered": is_discovered
	}
