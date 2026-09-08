## BuffSpell - 增益法术
## 所有增益/护盾法术的基础实现
class_name BuffSpell
extends BaseSpell

## 增益属性
@export var buff_duration: float = 5.0  # 持续时间
@export var buff_value: float = 0.0  # 增益数值
@export var buff_type: String = "shield"  # shield, heal, speed, damage

## 当前增益状态
var is_active: bool = false
var active_timer: float = 0.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
    var target_node = target if target else owner_node
    if target_node == null:
        return
    
    # 应用增益效果
    _apply_buff(target_node)

## 应用增益效果
func _apply_buff(target: Node2D) -> void:
    match buff_type:
        "shield":
            _apply_shield(target)
        "heal":
            _apply_heal(target)
        "speed":
            _apply_speed_boost(target)
        "damage":
            _apply_damage_boost(target)
    
    # 开始持续时间计时
    is_active = true
    active_timer = buff_duration

## 应用护盾
func _apply_shield(target: Node2D) -> void:
    if target.has_method("apply_shield"):
        target.apply_shield(buff_value)
    
    # 播放护盾视觉效果
    _play_buff_effect(target, "shield")

## 应用治疗
func _apply_heal(target: Node2D) -> void:
    if target.has_method("heal"):
        target.heal(buff_value)
    
    # 播放治疗视觉效果
    _play_buff_effect(target, "heal")

## 应用速度加成
func _apply_speed_boost(target: Node2D) -> void:
    if target.has_method("apply_status_effect"):
        target.apply_status_effect(
            StatusEffectSystem.EffectType.REGEN,  # 使用REGEN作为速度加成的临时方案
            buff_value,
            buff_duration
        )
    
    # 播放速度视觉效果
    _play_buff_effect(target, "speed")

## 应用伤害加成
func _apply_damage_boost(target: Node2D) -> void:
    # 伤害加成通过修改属性实现
    if target.has_method("get_stats"):
        var stats = target.get_stats()
        if stats:
            stats.damage_multiplier += buff_value
    
    # 播放伤害加成视觉效果
    _play_buff_effect(target, "damage")

## 播放增益视觉效果
func _play_buff_effect(target: Node2D, effect_type: String) -> void:
    # 创建粒子效果或动画
    var particles = GPUParticles2D.new()
    particles.emitting = true
    particles.one_shot = true
    particles.lifetime = 1.0
    
    # 根据类型设置颜色
    match effect_type:
        "shield":
            particles.modulate = Color(0.3, 0.5, 1.0, 0.8)
        "heal":
            particles.modulate = Color(0.3, 1.0, 0.3, 0.8)
        "speed":
            particles.modulate = Color(1.0, 1.0, 0.3, 0.8)
        "damage":
            particles.modulate = Color(1.0, 0.3, 0.3, 0.8)
    
    target.add_child(particles)
    
    # 延迟销毁
    await get_tree().create_timer(1.0).timeout
    particles.queue_free()

## 更新增益状态
func _process(delta: float) -> void:
    # 先调用父类的冷却更新
    super._process(delta)
    
    # 更新增益持续时间
    if is_active:
        active_timer -= delta
        if active_timer <= 0:
            _remove_buff()

## 移除增益效果
func _remove_buff() -> void:
    is_active = false
    
    # 根据类型移除效果
    match buff_type:
        "speed":
            # 移除速度加成
            pass
        "damage":
            # 移除伤害加成
            pass

## 获取增益信息
func get_buff_info() -> Dictionary:
    return {
        "type": buff_type,
        "value": buff_value,
        "duration": buff_duration,
        "remaining": active_timer,
        "is_active": is_active
    }
