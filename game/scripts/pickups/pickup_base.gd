## PickupBase - 拾取物基类
## 所有可拾取物品的基类
class_name PickupBase
extends Area2D

## 拾取属性
@export var pickup_name: String = ""
@export var pickup_value: float = 1.0
@export var magnet_speed: float = 300.0
@export var magnet_range: float = 100.0
@export var lifetime: float = 30.0  # 30秒后自动消失

## 状态
var is_collected: bool = false
var target: Node2D = null
var lifetime_timer: float = 0.0

## 视觉节点（子类设置）
var visual_node: Node2D = null

## 信号
signal collected(collector: Node2D, value: float)

func _ready() -> void:
    # 连接信号
    area_entered.connect(_on_area_entered)
    
    # 添加到拾取物组
    add_to_group("pickups")
    
    # 查找视觉节点
    visual_node = get_node_or_null("PolygonVisual")
    if visual_node == null:
        visual_node = get_node_or_null("Sprite2D")

func _physics_process(delta: float) -> void:
    if is_collected:
        return
    
    # 生存时间倒计时
    lifetime_timer += delta
    if lifetime_timer > lifetime:
        # 超时消失（最后5秒开始闪烁）
        if lifetime_timer > lifetime - 5.0:
            if visual_node:
                visual_node.modulate.a = 0.3 + sin(lifetime_timer * 10.0) * 0.3
        if lifetime_timer > lifetime:
            queue_free()
            return
    
    # 检测玩家并在范围内吸附
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        var player = players[0]
        var distance = global_position.distance_to(player.global_position)
        
        # 磁吸范围 = 基础范围 + 玩家磁石加成
        var effective_range = magnet_range
        if player.has_method("get_stats"):
            var stats = player.get_stats()
            if stats:
                effective_range += stats.magnet_bonus
        
        if distance < effective_range:
            # 向玩家移动
            var direction = (player.global_position - global_position).normalized()
            position += direction * magnet_speed * delta * GameManager.speed_multiplier
            
            # 进入拾取范围
            if distance < 20.0:
                _collect(player)

## 拾取检测
func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("player_pickup_detector"):
        var player = area.get_parent()
        if player:
            _collect(player)

## 收集物品
func _collect(collector: Node2D) -> void:
    if is_collected:
        return
    
    is_collected = true
    
    # 应用效果
    _apply_effect(collector)
    
    # 发送信号
    collected.emit(collector, pickup_value)
    
    # 播放收集动画
    _play_collect_animation()

## 应用效果（子类重写）
func _apply_effect(collector: Node2D) -> void:
    pass

## 播放收集动画
func _play_collect_animation() -> void:
    # 禁用碰撞
    $CollisionShape2D.set_deferred("disabled", true)
    
    # 缩小并淡出（兼容 Polygon2D 和 Sprite2D）
    if visual_node:
        var tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(visual_node, "scale", Vector2(0.1, 0.1), 0.2)
        tween.tween_property(visual_node, "modulate:a", 0.0, 0.2)
        await tween.finished
    
    queue_free()

## 获取拾取信息
func get_pickup_info() -> Dictionary:
    return {
        "name": pickup_name,
        "value": pickup_value,
        "position": global_position
    }
