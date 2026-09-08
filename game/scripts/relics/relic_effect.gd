## RelicEffect - 遗物效果基类
extends RefCounted

## 效果类型常量
const STAT_BOOST = 0
const DAMAGE_BOOST = 1
const COOLDOWN_REDUCTION = 2
const LIFE_STEAL = 3
const CRITICAL_BOOST = 4
const SPECIAL_EFFECT = 5

## 应用效果
func apply(player, stacks = 1) -> void:
    pass

## 移除效果
func remove(player, stacks = 1) -> void:
    # 子类覆盖
    pass

## 获取效果描述
func get_description(stacks: int = 1) -> String:
    # 子类覆盖
    return ""

## 获取效果值
func get_effect_value(stacks: int = 1) -> float:
    return 0.0