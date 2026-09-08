## DamageNumber - 伤害数字
## 显示伤害数字飘字效果
class_name DamageNumber
extends Node2D

## 属性
var damage: float = 0.0
var is_critical: bool = false
var move_speed: float = 50.0
var fade_speed: float = 2.0
var lifetime: float = 1.0

## 组件引用
@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## 初始化
func _ready() -> void:
    # 随机偏移，避免重叠
    position.x += randf_range(-20, 20)
    position.y += randf_range(-10, 10)
    
    # 播放动画
    if animation_player:
        animation_player.play("float_up")

## 设置伤害数字
func setup(_damage: float, _is_critical: bool = false) -> void:
    damage = _damage
    is_critical = _is_critical
    
    # 更新显示
    _update_display()

## 更新显示
func _update_display() -> void:
    if label == null:
        return
    
    # 设置文本
    label.text = str(int(damage))
    if is_critical:
        label.text += "!"
    
    # 设置颜色和大小
    if is_critical:
        label.modulate = Color.RED
        label.add_theme_font_size_override("font_size", 28)
    else:
        label.modulate = Color.WHITE
        label.add_theme_font_size_override("font_size", 20)

## 动画完成回调
func _on_animation_finished() -> void:
    queue_free()

## 生命周期结束
func _on_lifetime_timeout() -> void:
    # 淡出效果
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    await tween.finished
    queue_free()
