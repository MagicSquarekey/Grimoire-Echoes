## Projectile - 通用投射物
## 所有投射物法术的基础实现
class_name Projectile
extends Area2D

## 投射物属性
var damage: float = 25.0
var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT
var pierce: int = 0  # 穿透次数
var knockback: float = 0.0
var element: String = ""
var spell_level: int = 1
var source: Node2D = null

## 状态
var pierce_count: int = 0
var hit_targets: Array[Node2D] = []

## 组件引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready() -> void:
    # 连接信号（projectile.tscn 的 [connection] 段可能已连接过，避免重复连接报错）
    if not area_entered.is_connected(_on_area_entered):
        area_entered.connect(_on_area_entered)
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)
    if not lifetime_timer.timeout.is_connected(_on_lifetime_timeout):
        lifetime_timer.timeout.connect(_on_lifetime_timeout)

func _physics_process(delta: float) -> void:
    # 移动
    position += direction * speed * delta * GameManager.speed_multiplier

## 设置投射物属性
func setup(
    _damage: float,
    _speed: float,
    _direction: Vector2,
    _element: String = "",
    _pierce: int = 0,
    _knockback: float = 0.0,
    _spell_level: int = 1,
    _source: Node2D = null
) -> void:
    damage = _damage
    speed = _speed
    direction = _direction.normalized()
    element = _element
    pierce = _pierce
    knockback = _knockback
    spell_level = _spell_level
    source = _source
    
    # 旋转朝向
    rotation = direction.angle()

## 碰撞检测 - 区域
func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("enemy_hurtbox"):
        var enemy = area.get_parent()
        if enemy and not enemy in hit_targets:
            _hit_target(enemy)

## 碰撞检测 - 物理体
func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("enemies") and not body in hit_targets:
        _hit_target(body)

## 命中目标
func _hit_target(target: Node2D) -> void:
    # 记录已命中目标（防止重复命中）
    hit_targets.append(target)
    
    # 应用伤害
    if target.has_method("take_damage"):
        target.take_damage(damage, source)
    
    # 应用击退
    if knockback > 0 and target.has_method("apply_knockback"):
        target.apply_knockback(direction, knockback)
    
    # 应用元素效果
    _apply_element_effect(target)
    
    # 发送事件
    EventBus.spell_hit.emit(target, damage)
    
    # 检查穿透
    pierce_count += 1
    if pierce_count > pierce:
        _destroy()

## 应用元素效果
func _apply_element_effect(target: Node2D) -> void:
    if not target.has_method("apply_status_effect"):
        return
    
    match element:
        "fire":
            # 火焰：燃烧
            target.apply_status_effect(
                StatusEffectSystem.EffectType.BURN,
                damage * 0.2,  # 20%伤害/秒
                3.0
            )
        "water":
            # 水流：减速
            target.apply_status_effect(
                StatusEffectSystem.EffectType.SLOW,
                0.3,  # 30%减速
                2.0
            )
        "lightning":
            # 雷电：麻痹（小概率）
            if randf() < 0.15:
                target.apply_status_effect(
                    StatusEffectSystem.EffectType.STUN,
                    0.0,
                    0.5
                )
        "shadow":
            # 暗影：诅咒
            target.apply_status_effect(
                StatusEffectSystem.EffectType.CURSE,
                0.15,  # 15%伤害加成
                4.0
            )

## 销毁投射物
func _destroy() -> void:
    # 停止碰撞
    collision_shape.set_deferred("disabled", true)
    
    # 淡出效果
    var tween = create_tween()
    tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
    await tween.finished
    
    queue_free()

## 生命周期结束
func _on_lifetime_timeout() -> void:
    _destroy()

## 获取伤害（供敌人检测用）
func get_damage() -> float:
    return damage
