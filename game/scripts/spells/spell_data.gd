## SpellData - 法术数据资源
extends Resource

## 基础信息
@export var id = ""
@export var spell_name = ""
@export var description = ""
@export var element = 0
@export var spell_type = 0
@export var icon: Texture2D = null

## 数值属性
@export var base_damage = 10.0
@export var base_cooldown = 1.0
@export var base_mana_cost = 0.0
@export var max_level = 20
@export var cast_range = 500.0

## 升级配置
@export var damage_per_level = 0.08
@export var cooldown_reduction_per_level = 0.0

## 法术行为参数
@export var projectile_count = 1
@export var projectile_speed = 400.0
@export var aoe_radius = 0.0
@export var duration = 0.0
@export var pierce_count = 0
@export var chain_count = 0
@export var knockback_force = 0.0

## 特殊效果参数
@export var burn_damage = 0.0
@export var burn_duration = 0.0
@export var slow_amount: float = 0.0
@export var slow_duration: float = 0.0
@export var freeze_duration: float = 0.0
@export var stun_duration: float = 0.0
@export var life_steal_percent: float = 0.0

## 元素枚举
enum Element {
    FIRE,       # 🔥 火焰
    WATER,      # 💧 水流
    LIGHTNING,  # ⚡ 雷电
    NATURE,     # 🌿 自然
    SHADOW,     # 🌑 暗影
    AIR         # 🌬️ 风暴
}

## 法术类型枚举
enum SpellType {
    PROJECTILE,   # 投射物（火球、水弹等）
    FAN,          # 扇形范围（烈焰波等）
    GROUND_AOE,   # 地面AoE（陨石、冰锥等）
    RING,         # 环形（寒冰新星等）
    BUFF,         # 增益（护盾、屏障等）
    SUMMON,       # 召唤（藤蔓守卫等）
    CHAIN,        # 连锁（连锁闪电等）
    MARK,         # 标记（火焰印记等）
    DASH,         # 冲刺（疾风步等）
}

## 获取指定等级的伤害值
func get_damage_at_level(level: int) -> float:
    var multiplier = 1.0 + (level - 1) * damage_per_level
    
    # 质变点加成
    match level:
        5: multiplier = 1.40
        10: multiplier = 2.20
        15: multiplier = 3.50
        20: multiplier = 5.50
    
    return base_damage * multiplier

## 获取指定等级的冷却时间
func get_cooldown_at_level(level: int) -> float:
    var reduction = 0.0
    
    # 质变点冷却减少
    if level >= 15:
        reduction = 0.25
    elif level >= 10:
        reduction = 0.15
    elif level >= 5:
        reduction = 0.08
    
    return base_cooldown * (1.0 - reduction)

## 获取指定等级的法力消耗
func get_mana_cost_at_level(level: int) -> float:
    # 法力消耗不随等级变化
    return base_mana_cost

## 获取元素名称
func get_element_name() -> String:
    return Element.keys()[element]

## 获取法术类型名称
func get_type_name() -> String:
    return SpellType.keys()[spell_type]

## 获取法术描述（包含等级信息）
func get_full_description(level: int) -> String:
    var desc = description
    desc += "\n伤害: %d" % int(get_damage_at_level(level))
    desc += "\n冷却: %.1fs" % get_cooldown_at_level(level)
    if aoe_radius > 0:
        desc += "\n范围: %d" % int(aoe_radius)
    return desc
