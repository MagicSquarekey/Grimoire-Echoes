# 🔮 秘法回响（Grimoire Echoes）— Phase 2 核心系统架构设计

> **版本：** v1.0  
> **创建日期：** 2026-08-27  
> **文档状态：** Phase 2 架构设计完成  
> **项目代号：** Grimoire-Echoes

---

## 📑 目录

1. [Phase 2 概述](#1-phase-2-概述)
2. [法术进化系统架构](#2-法术进化系统架构)
3. [元素融合系统架构](#3-元素融合系统架构)
4. [遗物系统架构](#4-遗物系统架构)
5. [地图系统扩展](#5-地图系统扩展)
6. [敌人系统扩展](#6-敌人系统扩展)
7. [无限波次模式架构](#7-无限波次模式架构)
8. [存档系统架构](#8-存档系统架构)
9. [系统集成与依赖](#9-系统集成与依赖)
10. [开发任务拆分](#10-开发任务拆分)

---

## 1. Phase 2 概述

### 1.1 Phase 2 目标

| 目标 | 内容 | 周期 |
|------|------|------|
| **法术进化系统** | 30个法术，Lv.1-20升级，质变点机制 | 8周 |
| **元素融合系统** | 15种融合法术，融合配方，触发条件 | 8周 |
| **遗物系统** | 30个遗物，3种品质，效果框架 | 8周 |
| **地图系统** | 5张完整地图，差异化设计，特殊机制 | 8周 |
| **敌人系统** | 15种普通+6种精英，Boss多阶段战斗 | 8周 |
| **无限波次模式** | 波次生成，难度曲线，里程碑奖励 | 8周 |
| **存档系统** | 多槽位存档，加密存储，进度保存 | 8周 |

### 1.2 系统依赖关系

```
法术进化系统 ←─── 元素融合系统
     ↓                  ↓
遗物系统 ←────────── 敌人系统
     ↓                  ↓
地图系统 ←────────── 无限波次模式
     ↓                  ↓
存档系统 ←────────── UI系统
```

---

## 2. 法术进化系统架构

### 2.1 法术数据结构

```gdscript
# SpellResource.gd - 法术资源定义
class_name SpellResource
extends Resource

# 基础属性
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var element: ElementType = ElementType.FIRE
@export var type: SpellType = SpellType.PROJECTILE

# 基础数值
@export var base_damage: float = 25.0
@export var cooldown: float = 1.2
@export var mana_cost: float = 10.0
@export var range: float = 300.0

# 升级数据
@export var level_multipliers: Array[float] = []  # 20级伤害倍率
@export var milestone_effects: Array[MilestoneEffect] = []  # 质变点效果

# 视觉资源
@export var icon: Texture2D = null
@export var projectile_scene: PackedScene = null
@export var hit_effect: PackedScene = null

# 音效资源
@export var cast_sound: AudioStream = null
@export var hit_sound: AudioStream = null

enum ElementType {
    FIRE, WATER, LIGHTNING, NATURE, SHADOW, WIND
}

enum SpellType {
    PROJECTILE,    # 投射物
    AOE,          # 范围伤害
    WAVE,         # 波形攻击
    SHIELD,       # 防护
    SUMMON,       # 召唤
    BUFF,         # 增益
    DEBUFF        # 减益
}
```

### 2.2 质变点效果结构

```gdscript
# MilestoneEffect.gd - 质变点效果
class_name MilestoneEffect
extends Resource

@export var level: int = 5  # 触发等级
@export var effect_type: MilestoneType = MilestoneType.RANGE_UP
@export var value: float = 0.3  # 效果数值
@export var description: String = ""  # 效果描述

enum MilestoneType {
    RANGE_UP,           # 范围增加
    MULTI_CAST,         # 多连发
    HOMING,             # 追踪弹
    EXTRA_DURATION,     # 持续时间增加
    DAMAGE_BOOST,       # 伤害提升
    SPECIAL_EFFECT,     # 特殊效果
    FORM_CHANGE         # 形态变化
}
```

### 2.3 法术升级系统

```gdscript
# SpellUpgradeSystem.gd - 法术升级系统
class_name SpellUpgradeSystem
extends Node

# 升级模板
const UPGRADE_TEMPLATE: Dictionary = {
    "multipliers": [
        1.0, 1.08, 1.16, 1.24, 1.40,  # Lv.1-5
        1.52, 1.64, 1.76, 1.88, 2.20,  # Lv.6-10
        2.40, 2.60, 2.80, 3.00, 3.50,  # Lv.11-15
        3.80, 4.10, 4.40, 4.70, 5.50   # Lv.16-20
    ],
    "milestone_levels": [5, 10, 15, 20]
}

# 升级法术
func upgrade_spell(spell: SpellBase) -> void:
    if spell.current_level >= spell.max_level:
        return
    
    spell.current_level += 1
    
    # 应用伤害倍率
    var multiplier = UPGRADE_TEMPLATE.multipliers[spell.current_level - 1]
    spell.damage_multiplier = multiplier
    
    # 检查质变点
    if UPGRADE_TEMPLATE.milestone_levels.has(spell.current_level):
        _apply_milestone(spell, spell.current_level)
    
    # 发送升级信号
    spell.spell_upgraded.emit(spell, spell.current_level)

# 应用质变点效果
func _apply_milestone(spell: SpellBase, level: int) -> void:
    for milestone in spell.spell_resource.milestone_effects:
        if milestone.level == level:
            _execute_milestone_effect(spell, milestone)

func _execute_milestone_effect(spell: SpellBase, milestone: MilestoneEffect) -> void:
    match milestone.effect_type:
        MilestoneEffect.MilestoneType.RANGE_UP:
            spell.range *= (1.0 + milestone.value)
        MilestoneEffect.MilestoneType.MULTI_CAST:
            spell.multi_cast_count = int(milestone.value)
        MilestoneEffect.MilestoneType.HOMING:
            spell.is_homing = true
        MilestoneEffect.MilestoneType.EXTRA_DURATION:
            spell.duration *= (1.0 + milestone.value)
        MilestoneEffect.MilestoneType.DAMAGE_BOOST:
            spell.damage_boost += milestone.value
        MilestoneEffect.MilestoneType.SPECIAL_EFFECT:
            spell.special_effect = milestone.description
        MilestoneEffect.MilestoneType.FORM_CHANGE:
            spell.form_changed = true
```

### 2.4 30个法术完整列表

| 元素 | 法术ID | 法术名 | 类型 | 基础伤害 | 冷却 | 质变点Lv.5 | 质变点Lv.10 | 质变点Lv.15 |
|------|--------|--------|------|----------|------|------------|-------------|-------------|
| 🔥 | F1 | 火球术 | 投射物 | 25 | 1.2s | 爆炸范围+30% | 2连发 | 追踪弹 |
| 🔥 | F2 | 烈焰波 | 扇形 | 30 | 2.5s | 扇形角度+40% | 击退效果 | 燃烧时间翻倍 |
| 🔥 | F3 | 陨石坠落 | 地面AoE | 50 | 8s | 延迟缩短至1s | 3连陨石 | 陨石碎片散射 |
| 🔥 | F4 | 火焰屏障 | 环绕 | 10/s | 12s | 持续+2秒 | 接触伤害翻倍 | 护盾吸收伤害 |
| 🔥 | F5 | 火焰印记 | 标记 | 0 | 6s | 标记数+2 | 引爆伤害翻倍 | 连锁标记 |
| 💧 | W1 | 水弹 | 投射物 | 15 | 0.8s | 减速+15% | 3连发 | 冰冻效果 |
| 💧 | W2 | 寒冰新星 | 环形 | 40 | 7s | 范围+40% | 冻结+1秒 | 伤害冰爆 |
| 💧 | W3 | 冰锥阵列 | 地面AoE | 20/s | 5s | 持续+2秒 | 6个冰锥 | 冰锥爆炸 |
| 💧 | W4 | 水之护盾 | 防御 | 0 | 15s | 吸收+50% | 反弹伤害 | 水波脉冲 |
| 💧 | W5 | 潮汐冲击 | 冲击波 | 35 | 3s | 扇形+30% | 双重冲击 | 冲击波范围化 |
| ⚡ | L1 | 闪电箭 | 投射物 | 20 | 1s | 弹射+2 | 弹射无递减 | 闪电链扩散 |
| ⚡ | L2 | 雷暴领域 | 持续AoE | 15/s | 10s | 持续+2秒 | 打击频率翻倍 | 雷暴追踪 |
| ⚡ | L3 | 连锁闪电 | 连锁 | 25 | 4s | 弹射+3 | 无伤害递减 | 全屏弹射 |
| ⚡ | L4 | 静电场 | 被动光环 | 5/s | 0s | 范围+30% | 麻痹率+15% | 被动闪电 |
| ⚡ | L5 | 雷霆一击 | 单体爆发 | 80 | 6s | 伤害+30% | 双重打击 | 连锁打击 |
| 🌿 | N1 | 藤蔓缠绕 | 控制 | 10 | 3s | 缠绕+1秒 | 多段缠绕 | 藤蔓爆炸 |
| 🌿 | N2 | 治愈之风 | 治疗 | 0 | 10s | 治疗+3% | 移除debuff | 净化领域 |
| 🌿 | N3 | 花粉炸弹 | AoE | 15/s | 6s | 范围+30% | 致盲效果 | 毒雾扩散 |
| 🌿 | N4 | 藤蔓守卫 | 召唤 | 20 | 20s | 持续+5秒 | 守卫攻击翻倍 | 守卫分裂 |
| 🌿 | N5 | 荆棘甲 | 防御 | 0 | 12s | 反弹+15% | 反弹+40% | 荆棘领域 |
| 🌑 | D1 | 暗影弹 | 投射物 | 15 | 1.5s | 吸取+3% | 双暗影弹 | 暗影分裂 |
| 🌑 | D2 | 暗影之触 | 近战 | 30 | 3s | 攻击降低+10% | 双触手 | 暗影爆发 |
| 🌑 | D3 | 生命虹吸 | 范围 | 0 | 8s | 范围+30% | 吸取+2% | 暗影领域 |
| 🌑 | D4 | 诅咒印记 | 标记 | 0 | 5s | 伤害增加+10% | 双重诅咒 | 诅咒传染 |
| 🌑 | D5 | 暗影分身 | 召唤 | 15 | 18s | 持续+3秒 | 分身攻击翻倍 | 分身复制法术 |
| 🌬️ | A1 | 风刃 | 投射物 | 18 | 0.6s | 穿透+2 | 穿透+5 | 风刃分裂 |
| 🌬️ | A2 | 旋风 | 控制 | 10 | 8s | 持续+1秒 | 拉力翻倍 | 多旋风 |
| 🌬️ | A3 | 疾风步 | 位移 | 25 | 4s | 冲刺距离+30% | 双重冲刺 | 冲刺残影 |
| 🌬️ | A4 | 风之壁垒 | 防御 | 0 | 12s | 持续+2秒 | 偏转+反弹 | 绝对防御 |
| 🌬️ | A5 | 气旋爆破 | AoE | 30 | 6s | 范围+30% | 击退+50% | 气旋链 |

---

## 3. 元素融合系统架构

### 3.1 融合配方数据结构

```gdscript
# FusionRecipe.gd - 融合配方
class_name FusionRecipe
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var element1: SpellBase.ElementType
@export var element2: SpellBase.ElementType
@export var required_spell1: String = ""  # 需要的法术1 ID
@export var required_spell2: String = ""  # 需要的法术2 ID
@export var fusion_spell: SpellResource = null  # 融合法术资源
@export var unlock_condition: String = ""  # 解锁条件
```

### 3.2 融合法术实现

```gdscript
# FusionSpell.gd - 融合法术基类
class_name FusionSpell
extends SpellBase

# 融合属性
@export var fusion_recipe: FusionRecipe = null
@export var spell1: SpellBase = null
@export var spell2: SpellBase = null

# 融合等级计算
var fusion_level: int = 0:
    get:
        return spell1.current_level + spell2.current_level

# 融合加成计算
var fusion_bonus: float = 0.0:
    get:
        if fusion_level <= 10:
            return 0.0
        elif fusion_level <= 20:
            return 0.20
        elif fusion_level <= 30:
            return 0.40
        else:
            return 0.60

# 融合被动解锁
var fusion_passive_unlocked: bool:
    get:
        return fusion_level >= 21

# 施放融合法术
func cast(target_position: Vector2) -> bool:
    if not is_ready:
        return false
    
    # 执行融合施法逻辑
    _execute_fusion_cast(target_position)
    
    # 开始冷却
    is_ready = false
    cooldown_timer = cooldown * (1.0 - fusion_bonus * 0.25)  # 融合减少冷却
    
    spell_cast.emit(self)
    return true

func _execute_fusion_cast(target_position: Vector2) -> void:
    # 融合法术施放逻辑，子类覆盖
    pass
```

### 3.3 15种融合配方

| 组合 | 融合法术名 | 效果描述 | 触发条件 |
|------|-----------|----------|----------|
| 🔥+💧 | 蒸汽爆炸 | 高温蒸汽，持续伤害+降低视野 | F1+W1 |
| 🔥+⚡ | 雷火交加 | 雷火弹，电火花连锁伤害 | F1+L1 |
| 🔥+🌿 | 焚烧藤蔓 | 燃烧藤蔓，缠绕+持续燃烧 | N1+F2 |
| 🔥+🌑 | 暗焰爆弹 | 暗影火焰弹，吸取+燃烧 | D1+F1 |
| 🔥+🌬️ | 火焰旋风 | 火焰旋风，拉入+燃烧 | F2+A2 |
| 💧+⚡ | 冰雷爆裂 | 冰冻闪电，冻结+传导伤害 | W1+L1 |
| 💧+🌿 | 生命之泉 | 治愈之泉，持续治疗+减速 | N2+W1 |
| 💧+🌑 | 暗影潮汐 | 暗影水波，吸取+减速 | D1+W1 |
| 💧+🌬️ | 暴风雪 | 暴风雪，冰冻伤害+击退 | W3+A2 |
| ⚡+🌿 | 雷霆荆棘 | 带电荆棘，缠绕+持续放电 | N1+L1 |
| ⚡+🌑 | 暗影闪电 | 暗影闪电，吸取+麻痹 | D1+L1 |
| ⚡+🌬️ | 风暴之眼 | 风暴，击退+麻痹 | L2+A2 |
| 🌿+🌑 | 暗影荆棘 | 暗影荆棘，缠绕+吸取生命 | N1+D1 |
| 🌿+🌬️ | 自然风暴 | 自然风暴，范围伤害+召唤藤蔓 | A2+N4 |
| 🌑+🌬️ | 暗影风暴 | 暗影风暴，吸取+击退 | D3+A2 |

### 3.4 融合触发系统

```gdscript
# FusionManager.gd - 融合管理器
class_name FusionManager
extends Node

# 融合配方表
var fusion_recipes: Array[FusionRecipe] = []

# 已解锁的融合
var unlocked_fusions: Array[String] = []

# 信号
signal fusion_unlocked(recipe: FusionRecipe)
signal fusion_available(fusion_spells: Array[FusionSpell])

func _ready() -> void:
    _load_fusion_recipes()

func check_fusion_available(spells: Array[SpellBase]) -> Array[FusionSpell]:
    var available: Array[FusionSpell] = []
    
    for recipe in fusion_recipes:
        if _check_recipe_requirements(recipe, spells):
            var fusion_spell = _create_fusion_spell(recipe, spells)
            available.append(fusion_spell)
    
    return available

func _check_recipe_requirements(recipe: FusionRecipe, spells: Array[SpellBase]) -> bool:
    var has_spell1 = false
    var has_spell2 = false
    
    for spell in spells:
        if spell.spell_id == recipe.required_spell1:
            has_spell1 = true
        if spell.spell_id == recipe.required_spell2:
            has_spell2 = true
    
    return has_spell1 and has_spell2

func _create_fusion_spell(recipe: FusionRecipe, spells: Array[SpellBase]) -> FusionSpell:
    var fusion = FusionSpell.new()
    fusion.fusion_recipe = recipe
    
    # 找到对应的源法术
    for spell in spells:
        if spell.spell_id == recipe.required_spell1:
            fusion.spell1 = spell
        if spell.spell_id == recipe.required_spell2:
            fusion.spell2 = spell
    
    # 设置融合法术属性
    fusion.spell_resource = recipe.fusion_spell
    
    return fusion

func unlock_fusion(recipe: FusionRecipe) -> void:
    if not unlocked_fusions.has(recipe.id):
        unlocked_fusions.append(recipe.id)
        fusion_unlocked.emit(recipe)

func _load_fusion_recipes() -> void:
    # 加载融合配方数据
    pass
```

---

## 4. 遗物系统架构

### 4.1 遗物数据结构

```gdscript
# RelicResource.gd - 遗物资源
class_name RelicResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var quality: RelicQuality = RelicQuality.COMMON
@export var effect: RelicEffect = null
@export var icon: Texture2D = null
@export var max_stacks: int = 1  # 最大叠加数

enum RelicQuality {
    COMMON,    # 普通（白色）
    RARE,      # 稀有（蓝色）
    LEGENDARY  # 传说（金色）
}

# 遗物效果
@export var effect_type: RelicEffectType = RelicEffectType.STAT_BOOST
@export var effect_value: float = 0.0
@export var effect_target: String = ""

enum RelicEffectType {
    STAT_BOOST,         # 属性加成
    DAMAGE_BOOST,       # 伤害加成
    COOLDOWN_REDUCTION, # 冷却减少
    LIFE_STEAL,         # 生命吸取
    CRITICAL_BOOST,     # 暴击加成
    SPECIAL_EFFECT      # 特殊效果
}
```

### 4.2 遗物效果框架

```gdscript
# RelicEffect.gd - 遗物效果基类
class_name RelicEffect
extends RefCounted

# 效果类型
enum EffectType {
    STAT_BOOST,
    DAMAGE_BOOST,
    COOLDOWN_REDUCTION,
    LIFE_STEAL,
    CRITICAL_BOOST,
    SPECIAL_EFFECT
}

# 应用效果
func apply(player: Player, stacks: int = 1) -> void:
    # 子类覆盖
    pass

# 移除效果
func remove(player: Player, stacks: int = 1) -> void:
    # 子类覆盖
    pass

# 获取效果描述
func get_description(stacks: int = 1) -> String:
    # 子类覆盖
    return ""
```

### 4.3 遗物管理器

```gdscript
# RelicManager.gd - 遗物管理器
class_name RelicManager
extends Node

# 已获得的遗物
var acquired_relics: Dictionary = {}  # relic_id -> stacks

# 遗物池
var relic_pool: Array[RelicResource] = []

# 信号
signal relic_acquired(relic: RelicResource, stacks: int)
signal relic_removed(relic: RelicResource)

func _ready() -> void:
    _initialize_relic_pool()

func acquire_relic(relic: RelicResource) -> bool:
    # 检查是否已达到最大叠加
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

func remove_relic(relic_id: String) -> void:
    if acquired_relics.has(relic_id):
        var relic = _get_relic_by_id(relic_id)
        if relic:
            _remove_relic_effect(relic, acquired_relics[relic_id])
            acquired_relics.erase(relic_id)
            relic_removed.emit(relic)

func get_relic_count(relic_id: String) -> int:
    return acquired_relics.get(relic_id, 0)

func get_total_stat_bonus(stat_name: String) -> float:
    var total = 0.0
    for relic_id in acquired_relics:
        var relic = _get_relic_by_id(relic_id)
        if relic and relic.effect_type == RelicResource.RelicEffectType.STAT_BOOST:
            if relic.effect_target == stat_name:
                total += relic.effect_value * acquired_relics[relic_id]
    return total

func _apply_relic_effect(relic: RelicResource, stacks: int) -> void:
    # 应用遗物效果到玩家
    pass

func _remove_relic_effect(relic: RelicResource, stacks: int) -> void:
    # 移除遗物效果
    pass

func _initialize_relic_pool() -> void:
    # 加载所有遗物到池中
    pass

func _get_relic_by_id(relic_id: String) -> RelicResource:
    # 根据ID获取遗物资源
    return null
```

### 4.4 30个遗物完整列表

**普通遗物（12个）**

| ID | 遗物名 | 效果 | 数值 |
|----|--------|------|------|
| R1 | 魔力水晶 | 最大法力+20% | 0.20 |
| R2 | 生命之种 | 最大生命+15% | 0.15 |
| R3 | 疾风之靴 | 移动速度+10% | 0.10 |
| R4 | 火焰徽记 | 火焰法术伤害+8% | 0.08 |
| R5 | 冰霜徽记 | 水流法术伤害+8% | 0.08 |
| R6 | 雷电徽记 | 雷电法术伤害+8% | 0.08 |
| R7 | 自然徽记 | 自然法术伤害+8% | 0.08 |
| R8 | 暗影徽记 | 暗影法术伤害+8% | 0.08 |
| R9 | 风暴徽记 | 风暴法术伤害+8% | 0.08 |
| R10 | 经验宝石 | 经验获取+15% | 0.15 |
| R11 | 幸运护符 | 稀有掉落率+8% | 0.08 |
| R12 | 护盾碎片 | 护盾值+15% | 0.15 |

**稀有遗物（12个）**

| ID | 遗物名 | 效果 | 数值 |
|----|--------|------|------|
| R13 | 元素之心 | 所有元素伤害+12% | 0.12 |
| R14 | 时间沙漏 | 冷却恢复速度+15% | 0.15 |
| R15 | 生命之泉 | 每秒恢复2%最大生命 | 0.02 |
| R16 | 暴击之眼 | 暴击率+10%，暴击伤害+20% | 0.10/0.20 |
| R17 | 双重施法 | 15%几率法术释放两次 | 0.15 |
| R18 | 元素融合石 | 融合法术伤害+20% | 0.20 |
| R19 | 吸血之牙 | 造成伤害的5%转化为生命 | 0.05 |
| R20 | 幻影之靴 | 移动速度+20%，5%几率闪避 | 0.20/0.05 |
| R21 | 法力涌泉 | 每秒恢复3%最大法力 | 0.03 |
| R22 | 荆棘之甲 | 受到近战伤害时反弹15%伤害 | 0.15 |
| R23 | 连锁反应 | 连锁法术连锁数+2 | 2 |
| R24 | 召唤大师 | 召唤物伤害和持续时间+25% | 0.25 |

**传说遗物（6个）**

| ID | 遗物名 | 效果 | 数值 |
|----|--------|------|------|
| R25 | 凤凰之羽 | 死亡时复活一次（恢复50%生命） | 1次 |
| R26 | 时空扭曲 | 所有冷却时间-25%，移动速度+15% | 0.25/0.15 |
| R27 | 元素洪流 | 所有元素伤害+25%，10%几率触发融合效果 | 0.25/0.10 |
| R28 | 暗影之心 | 造成伤害的8%转化为生命，15%几率恢复10%生命 | 0.08/0.15 |
| R29 | 命运之轮 | 升级时从4个选项中选择，稀有遗物出现率+50% | 4选项 |
| R30 | 终极法典 | 所有法术等级+2，终极槽提前至Lv.10解锁 | +2等级 |

---

## 5. 地图系统扩展

### 5.1 地图数据结构

```gdscript
# MapResource.gd - 地图资源
class_name MapResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var theme: MapTheme = MapTheme.FOREST
@export var unlock_condition: String = ""
@export var special_mechanics: Array[MapMechanic] = []
@export var hidden_areas: Array[HiddenArea] = []
@export var boss_waves: Array[int] = []
@export var background_scene: PackedScene = null

enum MapTheme {
    FOREST,      # 幽暗森林
    LAVA,        # 熔岩裂谷
    ICE,         # 冰封山脉
    SHADOW,      # 暗影深渊
    ELEMENTAL    # 元素祭坛
}
```

### 5.2 地图特殊机制

```gdscript
# MapMechanic.gd - 地图特殊机制
class_name MapMechanic
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var trigger_type: TriggerType = TriggerType.TIMED
@export var effect: MechanicEffect = null
@export var cooldown: float = 0.0

enum TriggerType {
    TIMED,      # 定时触发
    AREA,       # 区域触发
    INTERACTIVE # 交互触发
}

# 机制效果
class MechanicEffect:
    var damage: float = 0.0
    var duration: float = 0.0
    var area_radius: float = 0.0
    var status_effect: String = ""
```

### 5.3 5张地图详细设计

#### M1：幽暗森林

```gdscript
# ForestMap.gd - 幽暗森林
extends MapBase

# 特殊机制
const MECHANICS = {
    "vine_trap": {
        "damage": 5,
        "duration": 1.0,
        "cooldown": 10.0
    },
    "poison_fog": {
        "damage_per_second": 3,
        "area": "edge"
    },
    "tree_cover": {
        "block_projectiles": true,
        "destructible": true
    }
}

# 隐藏区域
const HIDDEN_AREA = {
    "position": Vector2(-800, 600),
    "trigger": "destroy_specific_tree",
    "content": ["chest", "elite_enemy"]
}
```

#### M2：熔岩裂谷

```gdscript
# LavaCanyonMap.gd - 熔岩裂谷
extends MapBase

const MECHANICS = {
    "lava_river": {
        "damage_per_second": 10,
        "slow_effect": 0.3
    },
    "lava_geyser": {
        "cooldown": 5.0,
        "projectile_count": 3,
        "damage": 20
    },
    "heat_wave": {
        "cooldown": 30.0,
        "enemy_damage_bonus": 0.10,
        "duration": 10.0
    }
}

const HIDDEN_AREA = {
    "position": Vector2(600, 0),
    "trigger": "find_safe_path",
    "content": ["legendary_chest", "2x_elite_enemy"]
}
```

#### M3：冰封山脉

```gdscript
# IceMountainMap.gd - 冰封山脉
extends MapBase

const MECHANICS = {
    "ice_surface": {
        "friction": 0.3,
        "inertia_multiplier": 2.0
    },
    "blizzard": {
        "cooldown": 60.0,
        "vision_reduction": 0.5,
        "duration": 15.0
    },
    "ice_spike": {
        "damage": 25,
        "area_radius": 100,
        "spawn_interval": 5.0
    }
}

const HIDDEN_AREA = {
    "position": Vector2(0, -800),
    "trigger": "blow_to_position",
    "content": ["rare_relic", "ice_elemental_elite"]
}
```

#### M4：暗影深渊

```gdscript
# ShadowAbyssMap.gd - 暗影深渊
extends MapBase

const MECHANICS = {
    "vision_limit": {
        "vision_reduction": 0.6,
        "always_active": true
    },
    "teleporters": {
        "count": 3,
        "random_destination": true
    },
    "shadow_creatures": {
        "only_in_dark": true,
        "spawn_in_hidden_areas": true
    }
}

const HIDDEN_AREA = {
    "position": "random_room",
    "trigger": "find_hidden_switch",
    "content": ["legendary_chest", "shadow_boss"]
}
```

#### M5：元素祭坛

```gdscript
# ElementalAltarMap.gd - 元素祭坛
extends MapBase

const MECHANICS = {
    "elemental_zones": {
        "zones": ["fire", "water", "lightning", "nature", "shadow", "wind"],
        "bonus_damage": 0.15
    },
    "elemental_storm": {
        "cooldown": 45.0,
        "random_element": true,
        "extra_damage_to_non_matching": 0.25
    },
    "altar_activation": {
        "required_count": 6,
        "unlocks_hidden_boss": true
    }
}

const HIDDEN_AREA = {
    "position": "all_altars_activated",
    "trigger": "activate_all_altars",
    "content": ["hidden_boss_elemental_spirit", "hidden_spell"]
}
```

---

## 6. 敌人系统扩展

### 6.1 敌人数据结构

```gdscript
# EnemyResource.gd - 敌人资源
class_name EnemyResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var type: EnemyType = EnemyType.NORMAL
@export var element: SpellBase.ElementType = SpellBase.ElementType.FIRE

# 基础属性
@export var max_health: float = 30.0
@export var base_damage: float = 8.0
@export var move_speed: float = 120.0
@export var exp_value: int = 10
@export var gold_value: int = 1

# 行为参数
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var chase_range: float = 300.0
@export var retreat_threshold: float = 0.2

# 特殊能力
@export var special_abilities: Array[EnemyAbility] = []
@export var is_boss: bool = false
@export var boss_phases: Array[BossPhase] = []

enum EnemyType {
    NORMAL,     # 普通敌人
    RANGED,     # 远程敌人
    SPECIAL,    # 特殊敌人
    SWARM,      # 群体敌人
    ELITE       # 精英敌人
}
```

### 6.2 敌人AI行为树

```gdscript
# EnemyBehaviorTree.gd - 敌人AI行为树
class_name EnemyBehaviorTree
extends RefCounted

# 行为树节点
var root: BTNode = null

# 行为树状态
enum BTState {
    SUCCESS,
    FAILURE,
    RUNNING
}

# 行为树节点基类
class BTNode:
    var state: BTState = BTState.RUNNING
    
    func tick(enemy: EnemyBase, delta: float) -> BTState:
        return BTState.RUNNING

# 条件节点
class BTCondition extends BTNode:
    var condition: Callable
    
    func tick(enemy: EnemyBase, delta: float) -> BTState:
        if condition.call(enemy):
            return BTState.SUCCESS
        return BTState.FAILURE

# 动作节点
class BTAction extends BTNode:
    var action: Callable
    
    func tick(enemy: EnemyBase, delta: float) -> BTState:
        return action.call(enemy, delta)

# 序列节点
class BTSequence extends BTNode:
    var children: Array[BTNode] = []
    var current_child: int = 0
    
    func tick(enemy: EnemyBase, delta: float) -> BTState:
        while current_child < children.size():
            var result = children[current_child].tick(enemy, delta)
            
            if result == BTState.RUNNING:
                return BTState.RUNNING
            elif result == BTState.FAILURE:
                current_child = 0
                return BTState.FAILURE
            
            current_child += 1
        
        current_child = 0
        return BTState.SUCCESS

# 选择节点
class BTSelector extends BTNode:
    var children: Array[BTNode] = []
    var current_child: int = 0
    
    func tick(enemy: EnemyBase, delta: float) -> BTState:
        while current_child < children.size():
            var result = children[current_child].tick(enemy, delta)
            
            if result == BTState.RUNNING:
                return BTState.RUNNING
            elif result == BTState.SUCCESS:
                current_child = 0
                return BTState.SUCCESS
            
            current_child += 1
        
        current_child = 0
        return BTState.FAILURE
```

### 6.3 15种普通敌人

| ID | 敌人名 | 类型 | 行为模式 | 生命值 | 伤害 | 速度 | 出现波次 |
|----|--------|------|----------|--------|------|------|----------|
| E1 | 暗影仆从 | 近战 | 直线追踪，接触攻击 | 30 | 8 | 中 | 1+ |
| E2 | 骷髅战士 | 近战 | 追踪，死亡分裂为2个小骷髅 | 50 | 12 | 中 | 5+ |
| E3 | 石像鬼 | 近战 | 追踪，攻击时静止1秒 | 80 | 18 | 慢 | 10+ |
| E4 | 暗影刺客 | 近战 | 快速追踪，攻击后后退 | 25 | 15 | 快 | 15+ |
| E5 | 骷髅法师 | 远程 | 保持距离，每2秒发射暗影弹 | 20 | 10 | 慢 | 3+ |
| E6 | 毒蛛女巫 | 远程 | 保持距离，发射毒弹，持续掉血 | 25 | 6+3/s | 慢 | 8+ |
| E7 | 雷电精灵 | 远程 | 保持距离，连锁闪电，连锁2个目标 | 15 | 8 | 快 | 12+ |
| E8 | 自爆虫 | 特殊 | 快速追踪，接近后3秒自爆 | 15 | 30 | 快 | 5+ |
| E9 | 治疗者 | 特殊 | 追踪队友，每3秒治疗附近敌人5%生命 | 30 | 0 | 中 | 10+ |
| E10 | 护盾守卫 | 特殊 | 追踪玩家，为周围敌人提供护盾 | 40 | 5 | 慢 | 15+ |
| E11 | 虫群 | 群体 | 大量出现，每波10-20只 | 10 | 3 | 快 | 1+ |
| E12 | 蝙蝠群 | 群体 | 大量出现，会飞行，从空中攻击 | 8 | 4 | 快 | 5+ |
| E13 | 僵尸潮 | 群体 | 大量出现，移动慢但生命高 | 25 | 6 | 慢 | 10+ |
| E14 | 暗影骑士 | 精英 | 追踪，每5秒释放暗影冲击波 | 200 | 25 | 中 | 8+ |
| E15 | 元素领主 | 精英 | 追踪，每4秒释放对应元素AoE | 250 | 30 | 中 | 20+ |

### 6.4 Boss多阶段战斗系统

```gdscript
# BossController.gd - Boss控制器
class_name BossController
extends EnemyBase

# Boss阶段
var current_phase: int = 0
var phase_thresholds: Array[float] = []

# 阶段技能
var phase_abilities: Array[Array] = []

# 进入阶段
func enter_phase(phase: int) -> void:
    current_phase = phase
    _apply_phase_effects(phase)
    _enable_phase_abilities(phase)

# 检查阶段转换
func check_phase_transition() -> void:
    var health_percent = current_health / max_health
    
    for i in range(phase_thresholds.size()):
        if health_percent <= phase_thresholds[i] and current_phase < i + 1:
            enter_phase(i + 1)
            break

# 应用阶段效果
func _apply_phase_effects(phase: int) -> void:
    match phase:
        1:
            # 阶段1效果
            move_speed *= 1.2
        2:
            # 阶段2效果
            move_speed *= 1.5
            damage_multiplier *= 1.3
        3:
            # 阶段3效果
            move_speed *= 2.0
            damage_multiplier *= 1.5
            _summon_adds()

# 启用阶段技能
func _enable_phase_abilities(phase: int) -> void:
    for ability in phase_abilities[phase - 1]:
        ability.enable()

# 召唤小怪
func _summon_adds() -> void:
    # Boss召唤小怪逻辑
    pass
```

### 6.5 3个Boss详细设计

#### 熔岩巨人（波次20/40/60...）

| 阶段 | 血量 | 行为 | 技能 |
|------|------|------|------|
| 阶段1 | 100%-60% | 缓慢追踪 | 踩踏（地面AoE） |
| 阶段2 | 60%-20% | 加速追踪 | 熔岩弹（3连发），岩浆池 |
| 阶段3 | 20%-0% | 召唤小怪 | 召唤小熔岩巨人，火焰脉冲 |

#### 暗影君主（波次30/60/90...）

| 阶段 | 血量 | 行为 | 技能 |
|------|------|------|------|
| 阶段1 | 100%-70% | 传送，弹幕 | 暗影传送，暗影弹幕，召唤仆从 |
| 阶段2 | 70%-30% | 瞬移，旋风 | 视野缩小，暗影旋风，瞬移 |
| 阶段3 | 30%-0% | 无敌，全屏攻击 | 无敌3秒，全屏暗影波 |

#### 元素之王（波次50/100/150...）

| 阶段 | 血量 | 形态 | 技能 |
|------|------|------|------|
| 阶段1 | 100%-80% | 火焰形态 | 火焰弹幕+岩浆 |
| 阶段2 | 80%-60% | 水流形态 | 冰冻新星+冰锥 |
| 阶段3 | 60%-40% | 雷电形态 | 连锁闪电+雷暴 |
| 阶段4 | 40%-20% | 暗影形态 | 暗影弹幕+生命吸取 |
| 阶段5 | 20%-0% | 元素融合 | 全元素疯狂攻击 |

---

## 7. 无限波次模式架构

### 7.1 波次生成系统

```gdscript
# WaveManager.gd - 波次管理器
class_name WaveManager
extends Node

# 当前波次
var current_wave: int = 1
var wave_state: WaveState = WaveState.PREPARING
var wave_timer: float = 0.0

# 波次配置
var wave_config: WaveConfig = null

# 信号
signal wave_started(wave: int)
signal wave_completed(wave: int)
signal boss_spawned(boss: EnemyBase)

enum WaveState {
    PREPARING,
    SPAWNING,
    FIGHTING,
    BOSS_FIGHT,
    WAVE_COMPLETE,
    MILESTONE
}

func _process(delta: float) -> void:
    match wave_state:
        WaveState.PREPARING:
            _process_preparing(delta)
        WaveState.SPAWNING:
            _process_spawning(delta)
        WaveState.FIGHTING:
            _process_fighting(delta)
        WaveState.BOSS_FIGHT:
            _process_boss_fight(delta)
        WaveState.WAVE_COMPLETE:
            _process_wave_complete(delta)
        WaveState.MILESTONE:
            _process_milestone(delta)

func _process_preparing(delta: float) -> void:
    wave_timer -= delta
    if wave_timer <= 0:
        _start_wave()

func _start_wave() -> void:
    wave_state = WaveState.SPAWNING
    wave_started.emit(current_wave)

func _process_spawning(delta: float) -> void:
    # 敌人生成逻辑
    pass

func _process_fighting(delta: float) -> void:
    # 检查波次完成条件
    if _check_wave_complete():
        wave_state = WaveState.WAVE_COMPLETE

func _check_wave_complete() -> bool:
    # 检查所有敌人是否被消灭
    return get_tree().get_nodes_in_group("enemies").size() == 0
```

### 7.2 难度曲线

```gdscript
# DifficultyCurve.gd - 难度曲线
class_name DifficultyCurve
extends RefCounted

# 敌人属性缩放公式
static func get_stat_multiplier(wave: int) -> float:
    return 1.0 + wave * 0.10

# 敌人数量缩放
static func get_enemy_count_multiplier(wave: int) -> float:
    if wave <= 10:
        return 1.0
    elif wave <= 20:
        return 1.2
    elif wave <= 50:
        return 1.5
    else:
        return 2.0

# Boss强度缩放
static func get_boss_multiplier(wave: int) -> float:
    return 1.0 + wave * 0.05

# 波次持续时间
static func get_wave_duration(wave: int) -> float:
    if wave <= 10:
        return 30.0
    elif wave <= 20:
        return 40.0
    elif wave <= 50:
        return 50.0
    else:
        return 60.0
```

### 7.3 里程碑系统

```gdscript
# MilestoneManager.gd - 里程碑管理器
class_name MilestoneManager
extends Node

# 里程碑奖励
var milestone_rewards: Dictionary = {
    10: {"type": "relic", "quality": "rare", "choices": 3},
    20: {"type": "relic", "quality": "legendary", "choices": 3},
    30: {"type": "relic", "quality": "rare", "choices": 3},
    40: {"type": "relic", "quality": "legendary", "choices": 3},
    50: {"type": "relic", "quality": "legendary", "choices": 3}
}

# 检查里程碑
func check_milestone(wave: int) -> Dictionary:
    if milestone_rewards.has(wave):
        return milestone_rewards[wave]
    elif wave > 50 and wave % 10 == 0:
        return {"type": "relic", "quality": "legendary", "choices": 3}
    return {}

# 获取里程碑奖励
func get_milestone_reward(milestone: Dictionary) -> Array[RelicResource]:
    var rewards: Array[RelicResource] = []
    # 根据milestone生成奖励
    return rewards
```

---

## 8. 存档系统架构

### 8.1 存档数据结构

```gdscript
# SaveData.gd - 存档数据
class_name SaveData
extends Resource

@export var version: String = "1.0"
@export var slot: int = 1
@export var checksum: String = ""

# 游戏状态
@export var character: String = ""
@export var map: String = ""
@export var wave: int = 1
@export var play_time: float = 0.0

# 玩家属性
@export var hp: float = 100.0
@export var max_hp: float = 100.0
@export var mp: float = 100.0
@export var max_mp: float = 100.0
@export var level: int = 1
@export var exp: float = 0.0
@export var gold: int = 0

# 法术数据
@export var spells: Array[Dictionary] = []
# 格式: [{"id": "F1", "level": 8, "slot": 1}]

# 遗物数据
@export var relics: Array[Dictionary] = []
# 格式: [{"id": "R4", "stacks": 1}]

# 被动技能
@export var passives: Array[Dictionary] = []
# 格式: [{"id": "P7", "stacks": 3}]

# 元素亲和
@export var element_affinity: String = ""

# 统计数据
@export var kill_count: int = 0
@export var highest_wave: int = 0

# 时间戳
@export var timestamp: String = ""

func generate_checksum() -> String:
    var data_string = version + str(slot) + character + str(wave) + str(hp)
    return data_string.md5_text()

func validate_checksum() -> bool:
    return checksum == generate_checksum()
```

### 8.2 存档管理器

```gdscript
# SaveManager.gd - 存档管理器
class_name SaveManager
extends Node

const SAVE_DIR = "user://saves/"
const MAX_SAVE_SLOTS = 3

# 信号
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal save_error(error: String)

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int, save_data: SaveData) -> bool:
    if slot < 1 or slot > MAX_SAVE_SLOTS:
        save_error.emit("无效的存档槽位: %d" % slot)
        return false
    
    # 生成校验和
    save_data.checksum = save_data.generate_checksum()
    save_data.timestamp = Time.get_datetime_string_from_system()
    
    # 转换为JSON
    var json_string = JSON.stringify(save_data.to_dict(), "\t")
    
    # 保存文件
    var file_path = SAVE_DIR + "save_%d.json" % slot
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    
    if file == null:
        save_error.emit("无法创建存档文件")
        return false
    
    file.store_string(json_string)
    file.close()
    
    game_saved.emit(slot)
    return true

func load_game(slot: int) -> SaveData:
    var file_path = SAVE_DIR + "save_%d.json" % slot
    
    if not FileAccess.file_exists(file_path):
        return null
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        return null
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    
    if parse_result != OK:
        return null
    
    var save_data = SaveData.from_dict(json.data)
    
    if not save_data.validate_checksum():
        save_error.emit("存档校验失败")
        return null
    
    game_loaded.emit(slot)
    return save_data

func delete_save(slot: int) -> bool:
    var file_path = SAVE_DIR + "save_%d.json" % slot
    if FileAccess.file_exists(file_path):
        DirAccess.remove_absolute(file_path)
    return true
```

---

## 9. 系统集成与依赖

### 9.1 系统依赖图

```
┌─────────────────────────────────────────────────────────────┐
│                      GameManager                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ SpellSystem │  │ RelicSystem │  │ EnemySystem │         │
│  │  (30法术)   │  │  (30遗物)   │  │ (15敌人+6精英)│        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                 │
│         ▼                ▼                ▼                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │FusionSystem │  │ MapSystem   │  │ WaveManager │         │
│  │ (15融合)    │  │ (5地图)     │  │ (无限波次)   │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                 │
│         ▼                ▼                ▼                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   SaveManager                       │   │
│  │                 (存档系统)                          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 9.2 信号通信表

| 信号 | 发送者 | 接收者 | 用途 |
|------|--------|--------|------|
| spell_cast | SpellSystem | WaveManager | 统计法术使用 |
| spell_upgraded | SpellSystem | UI | 显示升级信息 |
| fusion_unlocked | FusionManager | UI | 显示融合解锁 |
| relic_acquired | RelicManager | UI | 显示遗物获得 |
| enemy_died | EnemySystem | WaveManager | 检查波次完成 |
| boss_spawned | WaveManager | UI | 显示Boss警告 |
| wave_completed | WaveManager | MilestoneManager | 检查里程碑 |
| game_saved | SaveManager | UI | 显示保存成功 |
| game_loaded | SaveManager | UI | 显示加载成功 |

---

## 10. 开发任务拆分

### 10.1 任务分解

| 任务ID | 任务名称 | 负责角色 | 预计时间 | 依赖 |
|--------|----------|----------|----------|------|
| T2.1 | 法术资源数据结构实现 | godot-expert | 2天 | - |
| T2.2 | 法术升级系统实现 | godot-expert | 3天 | T2.1 |
| T2.3 | 30个法术实现 | godot-expert | 5天 | T2.2 |
| T2.4 | 融合配方数据结构 | godot-expert | 1天 | - |
| T2.5 | 融合法术系统实现 | godot-expert | 3天 | T2.4 |
| T2.6 | 15种融合配方实现 | godot-expert | 3天 | T2.5 |
| T2.7 | 遗物资源数据结构 | godot-expert | 1天 | - |
| T2.8 | 遗物效果框架实现 | godot-expert | 2天 | T2.7 |
| T2.9 | 30个遗物实现 | godot-expert | 3天 | T2.8 |
| T2.10 | 地图资源数据结构 | godot-expert | 1天 | - |
| T2.11 | 地图特殊机制实现 | godot-expert | 3天 | T2.10 |
| T2.12 | 5张地图实现 | godot-expert | 5天 | T2.11 |
| T2.13 | 敌人资源数据结构 | godot-expert | 1天 | - |
| T2.14 | 敌人AI行为树实现 | godot-expert | 3天 | T2.13 |
| T2.15 | 15种普通敌人实现 | godot-expert | 4天 | T2.14 |
| T2.16 | 6种精英敌人实现 | godot-expert | 2天 | T2.15 |
| T2.17 | Boss多阶段战斗系统 | godot-expert | 4天 | T2.14 |
| T2.18 | 3个Boss实现 | godot-expert | 5天 | T2.17 |
| T2.19 | 无限波次模式实现 | godot-expert | 3天 | T2.12, T2.15 |
| T2.20 | 里程碑系统实现 | godot-expert | 2天 | T2.19 |
| T2.21 | 存档数据结构实现 | godot-expert | 1天 | - |
| T2.22 | 存档管理器实现 | godot-expert | 2天 | T2.21 |
| T2.23 | 系统集成测试 | godot-expert | 3天 | 所有任务 |
| T2.24 | Bug修复与优化 | godot-expert | 5天 | T2.23 |

### 10.2 依赖关系图

```
T2.1 → T2.2 → T2.3
T2.4 → T2.5 → T2.6
T2.7 → T2.8 → T2.9
T2.10 → T2.11 → T2.12
T2.13 → T2.14 → T2.15 → T2.16
                  ↓
               T2.17 → T2.18
T2.12 + T2.15 → T2.19 → T2.20
T2.21 → T2.22
所有任务 → T2.23 → T2.24
```

---

## 📝 文档历史

| 版本 | 日期 | 修改内容 |
|------|------|----------|
| v1.0 | 2026-08-27 | 初始版本，完成Phase 2架构设计 |

---

**文档生成：** MiMo-v2.5  
**项目代号：** Grimoire-Echoes  
**文档状态：** Phase 2 架构设计完成，可进入开发阶段