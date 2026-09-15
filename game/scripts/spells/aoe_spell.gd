## AoESpell - 范围法术
## 所有AoE法术的基础实现
class_name AoESpell
extends BaseSpell

## AoE属性
@export var aoe_delay: float = 0.0  # 延迟施放
@export var aoe_duration: float = 0.0  # 持续时间（0为瞬间）
@export var aoe_tick_interval: float = 1.0  # 持续伤害间隔
@export var aoe_visual_scene: PackedScene  # AoE视觉效果场景

## 当前AoE实例
var active_aoe: Node2D = null

## 重写施放逻辑（target 可能是敌人节点或 Vector2 坐标——SpellCaster.auto_cast 传坐标）
func _on_cast(target = null) -> void:
    if aoe_delay > 0:
        await get_tree().create_timer(aoe_delay).timeout

    # 获取施放位置
    var cast_position := _resolve_cast_position(target)

    # 创建AoE效果
    _create_aoe_effect(cast_position)

## 解析施放目标点：Vector2 坐标 / 节点全局位置 / 回退到自身位置
func _resolve_cast_position(target = null) -> Vector2:
    if target is Vector2:
        return target
    if target is Node2D and is_instance_valid(target):
        return target.global_position
    if owner_node is Node2D:
        return (owner_node as Node2D).global_position
    return global_position

## 创建AoE效果
func _create_aoe_effect(position: Vector2) -> void:
    # 创建AoE区域
    var aoe_area = Area2D.new()
    aoe_area.global_position = position
    
    # 添加碰撞形状
    var collision = CollisionShape2D.new()
    var circle = CircleShape2D.new()
    circle.radius = aoe_radius
    collision.shape = circle
    aoe_area.add_child(collision)
    
    # 设置碰撞层
    aoe_area.collision_layer = 0
    aoe_area.collision_mask = 2  # 敌人层
    
    # 添加到场景
    get_tree().current_scene.add_child(aoe_area)
    active_aoe = aoe_area
    
    # 创建视觉效果
    if aoe_visual_scene:
        var visual = aoe_visual_scene.instantiate()
        aoe_area.add_child(visual)
    
    # 处理AoE效果
    if aoe_duration > 0:
        # 持续AoE
        _process_duration_aoe(aoe_area)
    else:
        # 瞬间AoE
        _process_instant_aoe(aoe_area)
        
        # 延迟销毁
        await get_tree().create_timer(0.3).timeout
        aoe_area.queue_free()

## 处理瞬间AoE
func _process_instant_aoe(aoe_area: Area2D) -> void:
    var bodies = aoe_area.get_overlapping_bodies()
    for body in bodies:
        if body.is_in_group("enemies"):
            _apply_damage(body)

## 处理持续AoE
func _process_duration_aoe(aoe_area: Area2D) -> void:
    var elapsed = 0.0
    while elapsed < aoe_duration:
        await get_tree().create_timer(aoe_tick_interval).timeout
        elapsed += aoe_tick_interval
        
        # 对范围内敌人造成伤害
        var bodies = aoe_area.get_overlapping_bodies()
        for body in bodies:
            if body.is_in_group("enemies"):
                _apply_damage(body)
    
    # 持续时间结束
    aoe_area.queue_free()

## 获取AoE范围内敌人
func _get_enemies_in_aoe(center: Vector2, radius: float) -> Array[Node2D]:
    var enemies: Array[Node2D] = []
    var space_state = get_world_2d().direct_space_state
    
    var shape = CircleShape2D.new()
    shape.radius = radius
    
    var query = PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = Transform2D(0, center)
    query.collision_mask = 2
    
    var results = space_state.intersect_shape(query)
    for result in results:
        var collider = result.get("collider")
        if collider is Node2D and collider.is_in_group("enemies"):
            enemies.append(collider)
    
    return enemies

## 应用伤害到目标
func _apply_damage(target: Node2D) -> void:
    if target.has_method("take_damage"):
        var final_damage = _calculate_damage()
        target.take_damage(final_damage, owner_node)
        spell_hit.emit(target, final_damage)
