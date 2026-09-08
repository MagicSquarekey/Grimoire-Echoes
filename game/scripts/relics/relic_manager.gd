## RelicManager - 遗物管理器
extends Node

# 已获得的遗物
var acquired_relics = {}

# 遗物池
var relic_pool = []

# 信号
signal relic_acquired(relic, stacks)
signal relic_removed(relic)

func _ready() -> void:
    _initialize_relic_pool()

## 获得遗物
func acquire_relic(relic) -> bool:
    if acquired_relics.has(relic.id):
        var current_stacks = acquired_relics[relic.id]
        if current_stacks >= relic.max_stacks:
            return false
        acquired_relics[relic.id] = current_stacks + 1
    else:
        acquired_relics[relic.id] = 1
    
    # 应用遗物效果
    _apply_relic_effect(relic, acquired_relics[relic.id])
    
    relic_acquired.emit(relic, acquired_relics[relic.id])
    return true

## 移除遗物
func remove_relic(relic_id: String) -> void:
    if acquired_relics.has(relic_id):
        var relic = _get_relic_by_id(relic_id)
        if relic:
            _remove_relic_effect(relic, acquired_relics[relic_id])
            acquired_relics.erase(relic_id)
            relic_removed.emit(relic)

## 获取遗物数量
func get_relic_count(relic_id: String) -> int:
    return acquired_relics.get(relic_id, 0)

## 获取总属性加成
func get_total_stat_bonus(stat_name: String) -> float:
    var total = 0.0
    for relic_id in acquired_relics:
        var relic = _get_relic_by_id(relic_id)
        if relic and relic.effect_type == RelicResource.RelicEffectType.STAT_BOOST:
            if relic.effect_target == stat_name:
                total += relic.effect_value * acquired_relics[relic_id]
    return total

## 获取总伤害加成
func get_total_damage_bonus() -> float:
    var total = 0.0
    for relic_id in acquired_relics:
        var relic = _get_relic_by_id(relic_id)
        if relic and relic.effect_type == RelicResource.RelicEffectType.DAMAGE_BOOST:
            total += relic.effect_value * acquired_relics[relic_id]
    return total

## 获取总冷却减少
func get_total_cooldown_reduction() -> float:
    var total = 0.0
    for relic_id in acquired_relics:
        var relic = _get_relic_by_id(relic_id)
        if relic and relic.effect_type == RelicResource.RelicEffectType.COOLDOWN_REDUCTION:
            total += relic.effect_value * acquired_relics[relic_id]
    return total

## 获取总生命偷取
func get_total_life_steal() -> float:
    var total = 0.0
    for relic_id in acquired_relics:
        var relic = _get_relic_by_id(relic_id)
        if relic and relic.effect_type == RelicResource.RelicEffectType.LIFE_STEAL:
            total += relic.effect_value * acquired_relics[relic_id]
    return total

## 获取总暴击加成
func get_total_critical_bonus() -> float:
    var total = 0.0
    for relic_id in acquired_relics:
        var relic = _get_relic_by_id(relic_id)
        if relic and relic.effect_type == RelicResource.RelicEffectType.CRITICAL_BOOST:
            total += relic.effect_value * acquired_relics[relic_id]
    return total

## 应用遗物效果
func _apply_relic_effect(relic: RelicResource, stacks: int) -> void:
    # 应用遗物效果到玩家
    pass

## 移除遗物效果
func _remove_relic_effect(relic: RelicResource, stacks: int) -> void:
    # 移除遗物效果
    pass

## 初始化遗物池
func _initialize_relic_pool() -> void:
    # 使用遗物生成器加载所有遗物
    var all_relic_data = RelicGenerator.get_all_relic_data()
    for data in all_relic_data:
        var relic = RelicGenerator.create_relic(data["id"])
        if relic:
            relic_pool.append(relic)

## 根据ID获取遗物资源
func _get_relic_by_id(relic_id: String) -> RelicResource:
    # 从遗物池中查找
    for relic in relic_pool:
        if relic.id == relic_id:
            return relic
    return null

## 获取所有遗物
func get_all_relics() -> Array[RelicResource]:
    return relic_pool

## 获取已获得遗物
func get_acquired_relics() -> Array[RelicResource]:
    var relics: Array[RelicResource] = []
    for relic_id in acquired_relics:
        var relic = _get_relic_by_id(relic_id)
        if relic:
            relics.append(relic)
    return relics

## 随机获取一个遗物
func get_random_relic(quality: RelicResource.RelicQuality = RelicResource.RelicQuality.COMMON) -> RelicResource:
    var available_relics: Array[RelicResource] = []
    for relic in relic_pool:
        if relic.quality == quality and relic.id not in acquired_relics:
            available_relics.append(relic)
    
    if available_relics.size() == 0:
        return null
    
    return available_relics[randi() % available_relics.size()]

## 清除所有遗物
func clear_all_relics() -> void:
    for relic_id in acquired_relics.keys():
        var relic = _get_relic_by_id(relic_id)
        if relic:
            _remove_relic_effect(relic, acquired_relics[relic_id])
    
    acquired_relics.clear()