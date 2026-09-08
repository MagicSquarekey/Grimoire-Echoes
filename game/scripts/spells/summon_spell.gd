## SummonSpell - 召唤法术
## 所有召唤类法术的基础实现
class_name SummonSpell
extends BaseSpell

## 召唤属性
@export var summon_scene: PackedScene  # 召唤物场景
@export var summon_duration: float = 15.0  # 持续时间
@export var summon_count: int = 1  # 召唤数量
@export var summon_interval: float = 0.5  # 召唤间隔

## 已召唤的单位
var summoned_units: Array[Node2D] = []

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
    var cast_position = Vector2.ZERO
    if target:
        cast_position = target.global_position
    elif owner_node:
        cast_position = owner_node.global_position
    
    # 召唤单位
    _summon_units(cast_position)

## 召唤单位
func _summon_units(position: Vector2) -> void:
    if summon_scene == null:
        push_warning("Summon scene not set for spell: " + spell_name)
        return
    
    for i in range(summon_count):
        # 延迟召唤
        if i > 0:
            await get_tree().create_timer(summon_interval).timeout
        
        # 创建召唤物
        var summon = summon_scene.instantiate()
        if summon is Node2D:
            # 设置召唤物位置（在施法者周围随机位置）
            var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
            summon.global_position = position + offset
            
            # 设置召唤物属性
            if summon.has_method("setup"):
                summon.setup(
                    _calculate_damage(),
                    summon_duration,
                    owner_node
                )
            
            # 添加到场景
            get_tree().current_scene.add_child(summon)
            summoned_units.append(summon)
            
            # 连接死亡信号
            if summon.has_signal("died"):
                summon.died.connect(_on_summon_died.bind(summon))

## 召唤物死亡回调
func _on_summon_died(summon: Node2D) -> void:
    summoned_units.erase(summon)

## 清除所有召唤物
func clear_summons() -> void:
    for summon in summoned_units:
        if is_instance_valid(summon):
            summon.queue_free()
    summoned_units.clear()

## 获取召唤物数量
func get_summon_count() -> int:
    return summoned_units.size()

## 获取召唤信息
func get_summon_info() -> Dictionary:
    return {
        "count": summoned_units.size(),
        "max_count": summon_count,
        "duration": summon_duration
    }

## 升级效果
func _on_upgrade() -> void:
    # 基础伤害增长
    damage *= 1.08
    
    # 质变点效果
    match spell_level:
        5:
            # Lv.5: 召唤物持续+5秒
            summon_duration += 5.0
            print(spell_name + "升级: 召唤物持续时间增加")
        10:
            # Lv.10: 召唤物攻击翻倍
            print(spell_name + "升级: 召唤物攻击翻倍")
        15:
            # Lv.15: 召唤物分裂
            print(spell_name + "升级: 召唤物死亡时分裂")
        20:
            # Lv.20: 召唤物数量+2
            summon_count += 2
            print(spell_name + "升级: 召唤物数量增加")
