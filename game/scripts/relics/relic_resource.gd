## RelicResource - 遗物资源
## 定义遗物的所有属性和配置
class_name RelicResource
extends Resource

## 基础信息
@export var id = ""
@export var name = ""
@export var description = ""
@export var quality = 0
@export var icon: Texture2D = null

## 遗物效果
@export var effect_type = 0
@export var effect_value = 0.0
@export var effect_target = ""

## 叠加属性
@export var max_stacks = 1
@export var stackable = true

## 获取品质名称
func get_quality_name() -> String:
    return RelicQuality.keys()[quality]

## 获取效果类型名称
func get_effect_type_name() -> String:
    return RelicEffectType.keys()[effect_type]

## 获取遗物描述（包含效果信息）
func get_full_description(stacks: int = 1) -> String:
    var desc = description
    desc += "\n效果: %s" % _get_effect_description()
    if max_stacks > 1:
        desc += "\n叠加: %d/%d" % [stacks, max_stacks]
    return desc

## 获取效果描述
func _get_effect_description() -> String:
    match effect_type:
        RelicEffectType.STAT_BOOST:
            return "%s +%d%%" % [effect_target, int(effect_value * 100)]
        RelicEffectType.DAMAGE_BOOST:
            return "伤害 +%d%%" % int(effect_value * 100)
        RelicEffectType.COOLDOWN_REDUCTION:
            return "冷却时间 -%d%%" % int(effect_value * 100)
        RelicEffectType.LIFE_STEAL:
            return "生命偷取 +%d%%" % int(effect_value * 100)
        RelicEffectType.CRITICAL_BOOST:
            return "暴击率 +%d%%" % int(effect_value * 100)
        RelicEffectType.SPECIAL_EFFECT:
            return description
        _:
            return "特殊效果"

## 品质枚举
enum RelicQuality {
    COMMON,    # 普通（白色）
    RARE,      # 稀有（蓝色）
    LEGENDARY  # 传说（金色）
}

## 遗物效果类型枚举
enum RelicEffectType {
    STAT_BOOST,         # 属性加成
    DAMAGE_BOOST,       # 伤害加成
    COOLDOWN_REDUCTION, # 冷却减少
    LIFE_STEAL,         # 生命吸取
    CRITICAL_BOOST,     # 暴击加成
    SPECIAL_EFFECT      # 特殊效果
}