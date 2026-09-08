# 🔮 秘法回响（Grimoire Echoes）— 游戏架构设计文档

> **版本：** v1.0  
> **创建日期：** 2026-08-27  
> **文档状态：** 架构设计完成  
> **项目代号：** Grimoire-Echoes

---

## 📑 目录

1. [架构概述](#1-架构概述)
2. [系统模块划分](#2-系统模块划分)
3. [核心系统设计](#3-核心系统设计)
4. [数据架构](#4-数据架构)
5. [技术实现方案](#5-技术实现方案)
6. [性能优化策略](#6-性能优化策略)
7. [扩展性设计](#7-扩展性设计)
8. [开发路线图](#8-开发路线图)

---

## 1. 架构概述

### 1.1 架构原则

| 原则 | 说明 | 实现方式 |
|------|------|----------|
| **组件化架构** | 游戏功能由独立组件构成，便于复用和维护 | Godot节点系统 + 组合模式 |
| **数据驱动设计** | 游戏内容通过数据配置，非硬编码 | Resource资源 + JSON数据 |
| **信号驱动通信** | 模块间通过信号解耦，降低依赖 | Godot信号系统 |
| **状态机模式** | 管理复杂状态转换（游戏状态、AI状态） | 自定义状态机实现 |
| **性能优先** | 保证60FPS，支持200+同屏敌人 | 对象池 + 批处理渲染 |

### 1.2 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        游戏应用层                                 │
├─────────────────────────────────────────────────────────────────┤
│  [游戏管理系统]  [玩家系统]  [法术系统]  [敌人系统]  [UI系统]     │
├─────────────────────────────────────────────────────────────────┤
│                        核心引擎层                                 │
├─────────────────────────────────────────────────────────────────┤
│  [场景管理]  [资源管理]  [音频管理]  [输入管理]  [存档管理]       │
├─────────────────────────────────────────────────────────────────┤
│                        Godot 4.x 引擎                            │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 技术栈确认

| 技术 | 选择 | 说明 |
|------|------|------|
| **游戏引擎** | Godot 4.x | 2D性能优秀，学习成本低 |
| **编程语言** | GDScript | 主逻辑，类Python语法 |
| **渲染引擎** | Vulkan | 高性能渲染 |
| **物理引擎** | Godot内置 | 2D物理碰撞 |
| **数据格式** | Resource + JSON | 配置数据 + 运行时数据 |
| **版本控制** | Git | 代码版本管理 |

---

## 2. 系统模块划分

### 2.1 模块总览

```
Grimoire-Echoes/
├── Core/                    # 核心系统
│   ├── GameManager.gd       # 游戏管理器（单例）
│   ├── SceneManager.gd      # 场景管理器
│   ├── ResourceManager.gd   # 资源管理器
│   ├── AudioManager.gd      # 音频管理器
│   ├── InputManager.gd      # 输入管理器
│   └── SaveManager.gd       # 存档管理器
├── Player/                  # 玩家系统
│   ├── Player.gd            # 玩家主控制器
│   ├── PlayerStats.gd       # 玩家属性
│   ├── PlayerMovement.gd    # 移动控制
│   └── PlayerInput.gd       # 输入处理
├── Spells/                  # 法术系统
│   ├── SpellManager.gd      # 法术管理器
│   ├── SpellBase.gd         # 法术基类
│   ├── SpellSlot.gd         # 法术槽位
│   └── Elements/            # 元素法术实现
│       ├── FireSpells.gd    # 火焰系
│       ├── WaterSpells.gd   # 水流系
│       ├── LightningSpells.gd # 雷电系
│       ├── NatureSpells.gd  # 自然系
│       ├── ShadowSpells.gd  # 暗影系
│       └── WindSpells.gd    # 风暴系
├── Enemies/                 # 敌人系统
│   ├── EnemyManager.gd      # 敌人管理器
│   ├── EnemyBase.gd         # 敌人基类
│   ├── EnemyAI.gd           # AI状态机
│   ├── EnemySpawner.gd      # 敌人生成器
│   └── Bosses/              # Boss实现
├── Combat/                  # 战斗系统
│   ├── DamageCalculator.gd  # 伤害计算器
│   ├── StatusEffectManager.gd # 状态效果管理
│   ├── CollisionManager.gd  # 碰撞检测
│   └── ProjectileManager.gd # 投射物管理
├── Maps/                    # 地图系统
│   ├── MapManager.gd        # 地图管理器
│   ├── MapGenerator.gd      # 地图生成器
│   ├── Environment.gd       # 环境效果
│   └── Shop.gd              # 商店系统
├── UI/                      # UI系统
│   ├── UIManager.gd         # UI管理器
│   ├── HUD.gd               # 游戏内HUD
│   ├── MenuUI.gd            # 菜单UI
│   ├── DamageNumbers.gd     # 伤害数字
│   └── Minimap.gd           # 小地图
├── Data/                    # 数据定义
│   ├── Resources/           # Resource资源
│   │   ├── SpellResource.gd # 法术资源
│   │   ├── EnemyResource.gd # 敌人资源
│   │   ├── RelicResource.gd # 遗物资源
│   │   └── CharacterResource.gd # 角色资源
│   └── Config/              # 配置文件
│       ├── spells.json      # 法术配置
│       ├── enemies.json     # 敌人配置
│       └── relics.json      # 遗物配置
└── Utils/                   # 工具类
    ├── ObjectPool.gd        # 对象池
    ├── MathUtils.gd         # 数学工具
    └── StringUtils.gd       # 字符串工具
```

### 2.2 模块依赖关系

```
GameManager (单例)
    │
    ├── SceneManager
    │   └── 当前场景
    │
    ├── ResourceManager
    │   └── 游戏资源
    │
    ├── AudioManager
    │   └── 音频播放
    │
    ├── InputManager
    │   └── 输入处理
    │
    └── SaveManager
        └── 存档读写

当前游戏场景
    │
    ├── Player
    │   ├── PlayerStats
    │   ├── PlayerMovement
    │   └── SpellManager
    │
    ├── EnemyManager
    │   ├── EnemySpawner
    │   └── EnemyBase (多个实例)
    │
    ├── CombatManager
    │   ├── DamageCalculator
    │   ├── StatusEffectManager
    │   └── ProjectileManager
    │
    ├── MapManager
    │   ├── MapGenerator
    │   └── Environment
    │
    └── UIManager
        ├── HUD
        ├── DamageNumbers
        └── Minimap
```

---

## 3. 核心系统设计

### 3.1 游戏状态管理

#### 游戏状态机

```gdscript
# GameManager.gd - 游戏状态管理
enum GameState {
    MAIN_MENU,      # 主菜单
    CHARACTER_SELECT, # 角色选择
    MAP_SELECT,     # 地图选择
    PLAYING,        # 游戏进行中
    PAUSED,         # 游戏暂停
    GAME_OVER,      # 游戏结束
    VICTORY,        # 胜利
    SETTINGS,       # 设置
    CREDITS         # 制作人员
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState

signal state_changed(old_state: GameState, new_state: GameState)

func change_state(new_state: GameState) -> void:
    if current_state == new_state:
        return
    
    previous_state = current_state
    current_state = new_state
    
    # 执行状态进入逻辑
    match new_state:
        GameState.PLAYING:
            _on_playing_enter()
        GameState.PAUSED:
            _on_paused_enter()
        GameState.GAME_OVER:
            _on_game_over_enter()
        # ... 其他状态
    
    state_changed.emit(previous_state, new_state)
```

#### 波次状态机

```gdscript
# WaveManager.gd - 波次状态管理
enum WaveState {
    PREPARING,      # 准备阶段（5秒倒计时）
    SPAWNING,       # 敌人生成中
    FIGHTING,       # 战斗阶段
    BOSS_FIGHT,     # Boss战
    WAVE_COMPLETE,  # 波次完成
    MILESTONE       # 里程碑奖励
}

var current_wave: int = 1
var wave_state: WaveState = WaveState.PREPARING
var wave_timer: float = 0.0
var enemies_alive: int = 0

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
```

### 3.2 玩家系统架构

#### 玩家节点结构

```
Player (CharacterBody2D)
├── CollisionShape2D          # 碰撞体
├── Sprite2D                  # 角色精灵
├── AnimationPlayer           # 动画播放器
├── PlayerMovement            # 移动控制组件
├── PlayerStats               # 属性组件
├── SpellManager              # 法术管理器
├── HitboxComponent           # 攻击判定
├── HurtboxComponent          # 受击判定
├── PickupDetector            # 拾取检测
├── Camera2D                  # 摄像机
└── Effects                   # 特效节点
    ├── TrailEffect           # 拖尾特效
    ├── HitEffect             # 受击特效
    └── BuffEffect            # Buff特效
```

#### 玩家属性系统

```gdscript
# PlayerStats.gd - 玩家属性管理
class_name PlayerStats
extends Node

# 基础属性
@export var max_health: float = 100.0
@export var max_mana: float = 100.0
@export var base_attack: float = 1.0
@export var base_defense: float = 1.0
@export var move_speed: float = 200.0
@export var crit_rate: float = 0.05
@export var crit_damage: float = 1.5

# 当前状态
var current_health: float
var current_mana: float
var current_level: int = 1
var current_exp: float = 0.0
var gold: int = 0

# 加成属性（来自被动、遗物、元素亲和）
var health_bonus: float = 0.0
var mana_bonus: float = 0.0
var attack_bonus: float = 0.0
var defense_bonus: float = 0.0
var speed_bonus: float = 0.0
var crit_rate_bonus: float = 0.0
var crit_damage_bonus: float = 0.0

# 元素亲和
var element_affinity: String = ""
var element_damage_bonus: float = 0.0

# 计算属性
func get_max_health() -> float:
    return max_health * (1.0 + health_bonus)

func get_attack_multiplier() -> float:
    return base_attack * (1.0 + attack_bonus)

func get_move_speed() -> float:
    return move_speed * (1.0 + speed_bonus)

# 信号
signal health_changed(old_value: float, new_value: float)
signal mana_changed(old_value: float, new_value: float)
signal level_up(new_level: int)
signal died()

func take_damage(amount: float) -> void:
    var actual_damage = amount * (1.0 - defense_bonus)
    var old_health = current_health
    current_health = max(0, current_health - actual_damage)
    health_changed.emit(old_health, current_health)
    
    if current_health <= 0:
        died.emit()

func heal(amount: float) -> void:
    var old_health = current_health
    current_health = min(get_max_health(), current_health + amount)
    health_changed.emit(old_health, current_health)
```

### 3.3 法术系统架构

#### 法术基类设计

```gdscript
# SpellBase.gd - 法术基类
class_name SpellBase
extends Node

# 基础属性
@export var spell_id: String = ""
@export var spell_name: String = ""
@export var element_type: ElementType = ElementType.FIRE
@export var spell_type: SpellType = SpellType.PROJECTILE
@export var base_damage: float = 25.0
@export var cooldown: float = 1.2
@export var mana_cost: float = 10.0
@export var description: String = ""

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

# 升级属性
var current_level: int = 1
var max_level: int = 20
var level_multipliers: Array[float] = []

# 冷却管理
var cooldown_timer: float = 0.0
var is_ready: bool = true

# 融合相关
var fusion_partner: SpellBase = null
var fusion_spell: SpellBase = null

# 信号
signal spell_cast(spell: SpellBase)
signal spell_cooldown_complete(spell: SpellBase)
signal spell_upgraded(spell: SpellBase, new_level: int)

func _ready() -> void:
    _initialize_level_multipliers()

func _process(delta: float) -> void:
    if not is_ready:
        cooldown_timer -= delta
        if cooldown_timer <= 0:
            is_ready = true
            spell_cooldown_complete.emit(self)

func cast(target_position: Vector2) -> bool:
    if not is_ready:
        return false
    
    # 检查法力消耗
    var player_stats = get_player_stats()
    if player_stats.current_mana < mana_cost:
        return false
    
    # 消耗法力
    player_stats.current_mana -= mana_cost
    
    # 执行施法逻辑
    _execute_cast(target_position)
    
    # 开始冷却
    is_ready = false
    cooldown_timer = cooldown
    
    spell_cast.emit(self)
    return true

func upgrade() -> void:
    if current_level >= max_level:
        return
    
    current_level += 1
    _apply_upgrade_effects()
    spell_upgraded.emit(self, current_level)

func get_damage_multiplier() -> float:
    if current_level <= level_multipliers.size():
        return level_multipliers[current_level - 1]
    return 1.0

# 子类实现
func _execute_cast(target_position: Vector2) -> void:
    pass

func _initialize_level_multipliers() -> void:
    # 默认升级曲线，子类可覆盖
    for i in range(max_level):
        level_multipliers.append(1.0 + i * 0.08)

func _apply_upgrade_effects() -> void:
    pass
```

#### 法术槽位管理

```gdscript
# SpellSlotManager.gd - 法术槽位管理
class_name SpellSlotManager
extends Node

# 槽位定义
var spell_slots: Array[SpellSlot] = []
var ultimate_slot: SpellSlot = null

# 槽位解锁等级
const SLOT_UNLOCK_LEVELS: Array[int] = [0, 0, 5, 10]  # 槽位1-4
const ULTIMATE_SLOT_UNLOCK_LEVEL: int = 15

# 信号
signal spell_slot_unlocked(slot_index: int)
signal spell_equipped(slot_index: int, spell: SpellBase)
signal ultimate_slot_unlocked()

func _ready() -> void:
    _initialize_slots()

func _initialize_slots() -> void:
    # 创建4个普通槽位
    for i in range(4):
        var slot = SpellSlot.new()
        slot.slot_index = i
        slot.unlock_level = SLOT_UNLOCK_LEVELS[i]
        spell_slots.append(slot)
    
    # 创建终极槽位
    ultimate_slot = SpellSlot.new()
    ultimate_slot.slot_index = -1  # 终极槽位标识
    ultimate_slot.unlock_level = ULTIMATE_SLOT_UNLOCK_LEVEL
    ultimate_slot.is_ultimate = true

func check_slot_unlocks(player_level: int) -> void:
    for i in range(spell_slots.size()):
        var slot = spell_slots[i]
        if not slot.is_unlocked and player_level >= slot.unlock_level:
            slot.is_unlocked = true
            spell_slot_unlocked.emit(i)
    
    if not ultimate_slot.is_unlocked and player_level >= ultimate_slot.unlock_level:
        ultimate_slot.is_unlocked = true
        ultimate_slot_unlocked.emit()

func equip_spell(slot_index: int, spell: SpellBase) -> bool:
    var slot = spell_slots[slot_index]
    if not slot.is_unlocked:
        return false
    
    # 检查是否需要替换
    if slot.spell != null:
        _unequip_spell(slot_index)
    
    slot.spell = spell
    add_child(spell)
    spell_equipped.emit(slot_index, spell)
    return true

func get_available_spells() -> Array[SpellBase]:
    var spells: Array[SpellBase] = []
    for slot in spell_slots:
        if slot.is_unlocked and slot.spell != null:
            spells.append(slot.spell)
    return spells

func check_fusion_available() -> Array[SpellBase]:
    var available_spells = get_available_spells()
    var fusion_candidates: Array[SpellBase] = []
    
    for i in range(available_spells.size()):
        for j in range(i + 1, available_spells.size()):
            var spell1 = available_spells[i]
            var spell2 = available_spells[j]
            
            if _can_fuse(spell1, spell2):
                var fusion_spell = _get_fusion_spell(spell1, spell2)
                if fusion_spell != null:
                    fusion_candidates.append(fusion_spell)
    
    return fusion_candidates
```

### 3.4 敌人系统架构

#### 敌人基类设计

```gdscript
# EnemyBase.gd - 敌人基类
class_name EnemyBase
extends CharacterBody2D

# 基础属性
@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export var enemy_type: EnemyType = EnemyType.NORMAL
@export var max_health: float = 30.0
@export var base_damage: float = 8.0
@export var move_speed: float = 120.0
@export var exp_value: int = 10
@export var gold_value: int = 1

enum EnemyType {
    NORMAL,     # 普通敌人
    RANGED,     # 远程敌人
    SPECIAL,    # 特殊敌人
    SWARM,      # 群体敌人
    ELITE,      # 精英敌人
    BOSS        # Boss
}

# 当前状态
var current_health: float
var is_alive: bool = true
var is_stunned: bool = false
var current_wave: int = 1

# 状态效果
var status_effects: Array[StatusEffect] = []

# 引用
var player: CharacterBody2D = null
var enemy_manager: Node = null

# 信号
signal health_changed(old_value: float, new_value: float)
signal died(enemy: EnemyBase)
signal damage_dealt(amount: float)

func _ready() -> void:
    current_health = max_health
    player = get_tree().get_first_node_in_group("player")
    enemy_manager = get_parent()

func _physics_process(delta: float) -> void:
    if not is_alive or is_stunned:
        return
    
    # 更新状态效果
    _update_status_effects(delta)
    
    # 执行AI行为
    _execute_ai(delta)
    
    # 移动
    move_and_slide()

func take_damage(amount: float, damage_type: DamageType = DamageType.PHYSICAL) -> void:
    if not is_alive:
        return
    
    # 计算实际伤害
    var actual_damage = _calculate_damage(amount, damage_type)
    
    # 应用伤害
    var old_health = current_health
    current_health = max(0, current_health - actual_damage)
    health_changed.emit(old_health, current_health)
    
    # 显示伤害数字
    _show_damage_number(actual_damage)
    
    # 死亡检查
    if current_health <= 0:
        _die()

func _calculate_damage(amount: float, damage_type: DamageType) -> float:
    var damage = amount
    
    # 应用状态效果加成
    for effect in status_effects:
        if effect.type == StatusEffect.Type.VULNERABLE:
            damage *= 1.15  # 易伤15%
    
    # 应用伤害类型计算
    match damage_type:
        DamageType.PHYSICAL:
            pass  # 物理伤害直接应用
        DamageType.MAGICAL:
            damage *= 1.0  # 魔法伤害，可扩展
        DamageType.TRUE:
            pass  # 真实伤害无视防御
    
    return damage

func _die() -> void:
    is_alive = false
    
    # 掉落物品
    _drop_items()
    
    # 掉落经验
    _drop_experience()
    
    # 掉落金币
    _drop_gold()
    
    # 播放死亡动画
    _play_death_animation()
    
    # 发送死亡信号
    died.emit(self)
    
    # 从敌人管理器移除
    enemy_manager.remove_enemy(self)
    
    # 自我销毁
    queue_free()

func _update_status_effects(delta: float) -> void:
    var i = 0
    while i < status_effects.size():
        var effect = status_effects[i]
        effect.duration -= delta
        
        if effect.duration <= 0:
            # 效果结束
            _remove_status_effect(effect)
            status_effects.remove_at(i)
        else:
            # 应用持续效果
            _apply_status_effect(effect, delta)
            i += 1

func apply_status_effect(effect: StatusEffect) -> void:
    # 检查是否已有相同效果
    for existing_effect in status_effects:
        if existing_effect.type == effect.type:
            # 刷新持续时间
            existing_effect.duration = max(existing_effect.duration, effect.duration)
            return
    
    # 添加新效果
    status_effects.append(effect)
    _on_status_effect_applied(effect)
```

#### 敌人AI状态机

```gdscript
# EnemyAI.gd - 敌人AI状态机
class_name EnemyAI
extends Node

enum AIState {
    IDLE,           # 空闲
    CHASE,          # 追击玩家
    ATTACK,         # 攻击
    RETREAT,        # 撤退
    PATROL,         # 巡逻
    SPECIAL_ABILITY # 特殊技能
}

var current_state: AIState = AIState.IDLE
var enemy: EnemyBase = null
var player: CharacterBody2D = null

# 状态参数
var chase_range: float = 300.0
var attack_range: float = 50.0
var retreat_health_threshold: float = 0.2
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

# 信号
signal state_changed(old_state: AIState, new_state: AIState)

func _ready() -> void:
    enemy = get_parent()
    player = enemy.player

func _process(delta: float) -> void:
    if not enemy.is_alive:
        return
    
    # 更新攻击冷却
    attack_timer = max(0, attack_timer - delta)
    
    # 执行当前状态逻辑
    match current_state:
        AIState.IDLE:
            _process_idle(delta)
        AIState.CHASE:
            _process_chase(delta)
        AIState.ATTACK:
            _process_attack(delta)
        AIState.RETREAT:
            _process_retreat(delta)
        AIState.PATROL:
            _process_patrol(delta)
        AIState.SPECIAL_ABILITY:
            _process_special_ability(delta)
    
    # 状态转换检查
    _check_transitions()

func change_state(new_state: AIState) -> void:
    if current_state == new_state:
        return
    
    var old_state = current_state
    current_state = new_state
    
    # 执行状态进入逻辑
    match new_state:
        AIState.CHASE:
            _on_chase_enter()
        AIState.ATTACK:
            _on_attack_enter()
        AIState.RETREAT:
            _on_retreat_enter()
    
    state_changed.emit(old_state, new_state)

func _check_transitions() -> void:
    var distance_to_player = enemy.global_position.distance_to(player.global_position)
    
    # 生命值低于阈值，撤退
    if enemy.current_health / enemy.max_health < retreat_health_threshold:
        if current_state != AIState.RETREAT:
            change_state(AIState.RETREAT)
        return
    
    # 在攻击范围内
    if distance_to_player <= attack_range:
        if current_state != AIState.ATTACK and attack_timer <= 0:
            change_state(AIState.ATTACK)
        return
    
    # 在追击范围内
    if distance_to_player <= chase_range:
        if current_state != AIState.CHASE:
            change_state(AIState.CHASE)
        return
    
    # 超出范围，返回空闲
    if current_state != AIState.IDLE:
        change_state(AIState.IDLE)

func _process_chase(delta: float) -> void:
    # 追击玩家
    var direction = (player.global_position - enemy.global_position).normalized()
    enemy.velocity = direction * enemy.move_speed

func _process_attack(delta: float) -> void:
    # 停止移动，准备攻击
    enemy.velocity = Vector2.ZERO
    
    # 检查攻击冷却
    if attack_timer <= 0:
        _perform_attack()
        attack_timer = attack_cooldown

func _perform_attack() -> void:
    # 计算伤害
    var damage = enemy.base_damage
    
    # 应用伤害到玩家
    var player_stats = player.get_node("PlayerStats")
    player_stats.take_damage(damage)
    
    # 显示伤害数字
    _show_attack_effect()
```

### 3.5 战斗系统架构

#### 伤害计算器

```gdscript
# DamageCalculator.gd - 伤害计算器
class_name DamageCalculator
extends Node

# 伤害类型
enum DamageType {
    PHYSICAL,   # 物理伤害
    MAGICAL,    # 魔法伤害
    TRUE,       # 真实伤害
    DOT         # 持续伤害
}

# 元素伤害加成表
const ELEMENT_BONUS: Dictionary = {
    "fire": "nature",      # 火克自然
    "water": "fire",       # 水克火
    "lightning": "water",  # 雷克水
    "nature": "lightning", # 自然克雷
    "shadow": "wind",      # 暗影克风
    "wind": "shadow"       # 风克暗影
}

# 元素抗性表
const ELEMENT_RESISTANCE: Dictionary = {
    "fire": "water",       # 火被水抗
    "water": "lightning",  # 水被雷抗
    "lightning": "nature", # 雷被自然抗
    "nature": "fire",      # 自然被火抗
    "shadow": "wind",      # 暗影被风抗
    "wind": "shadow"       # 风被暗影抗
}

func calculate_damage(
    base_damage: float,
    attacker_stats: Dictionary,
    defender_stats: Dictionary,
    spell_element: String = "",
    is_critical: bool = false
) -> Dictionary:
    var result = {
        "damage": 0.0,
        "is_critical": false,
        "element_bonus": 1.0,
        "damage_type": DamageType.MAGICAL
    }
    
    # 基础伤害
    var damage = base_damage
    
    # 攻击力加成
    damage *= attacker_stats.get("attack_multiplier", 1.0)
    
    # 法术等级加成
    damage *= attacker_stats.get("spell_level_multiplier", 1.0)
    
    # 元素亲和加成
    if spell_element == attacker_stats.get("element_affinity", ""):
        damage *= (1.0 + attacker_stats.get("element_affinity_bonus", 0.0))
    
    # 元素克制加成
    if ELEMENT_BONUS.has(spell_element):
        var target_element = defender_stats.get("element", "")
        if target_element == ELEMENT_BONUS[spell_element]:
            damage *= 1.25  # 25%克制加成
            result["element_bonus"] = 1.25
    
    # 元素抗性
    if ELEMENT_RESISTANCE.has(spell_element):
        var target_element = defender_stats.get("element", "")
        if target_element == ELEMENT_RESISTANCE[spell_element]:
            damage *= 0.75  # 25%抗性
            result["element_bonus"] = 0.75
    
    # 暴击计算
    var crit_rate = attacker_stats.get("crit_rate", 0.05)
    var crit_damage = attacker_stats.get("crit_damage", 1.5)
    
    if is_critical or randf() < crit_rate:
        damage *= crit_damage
        result["is_critical"] = true
    
    # 遗物加成
    damage *= (1.0 + attacker_stats.get("relic_bonus", 0.0))
    
    # 契约惩罚
    damage *= (1.0 / (1.0 + defender_stats.get("contract_health_bonus", 0.0)))
    
    # 防御力减免
    var defense = defender_stats.get("defense", 0.0)
    damage *= (1.0 / (1.0 + defense * 0.01))
    
    # 最终伤害（至少1点）
    damage = max(1.0, damage)
    
    result["damage"] = damage
    return result

func calculate_dot_damage(
    base_damage: float,
    duration: float,
    tick_interval: float,
    attacker_stats: Dictionary
) -> Dictionary:
    var total_ticks = duration / tick_interval
    var damage_per_tick = base_damage * attacker_stats.get("attack_multiplier", 1.0)
    
    return {
        "damage_per_tick": damage_per_tick,
        "total_ticks": total_ticks,
        "total_damage": damage_per_tick * total_ticks,
        "tick_interval": tick_interval
    }
```

### 3.6 存档系统架构

#### 存档数据结构

```gdscript
# SaveData.gd - 存档数据结构
class_name SaveData
extends Resource

# 存档版本
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
# 格式: [{"id": "F1", "name": "火球术", "level": 8, "slot": 1}]

# 遗物数据
@export var relics: Array[Dictionary] = []
# 格式: [{"id": "R4", "name": "火焰徽记", "quality": "common"}]

# 被动技能
@export var passives: Array[Dictionary] = []
# 格式: [{"id": "P7", "name": "暴击直觉", "stacks": 3}]

# 元素亲和
@export var element_affinity: String = ""

# 统计数据
@export var kill_count: int = 0
@export var highest_wave: int = 0
@export var total_gold_earned: int = 0

# 时间戳
@export var timestamp: String = ""

func generate_checksum() -> String:
    # 生成校验和，防止存档篡改
    var data_string = version + str(slot) + character + str(wave) + str(hp)
    return data_string.md5_text()

func validate_checksum() -> bool:
    return checksum == generate_checksum()

func to_dict() -> Dictionary:
    return {
        "version": version,
        "slot": slot,
        "character": character,
        "map": map,
        "wave": wave,
        "hp": hp,
        "max_hp": max_hp,
        "mp": mp,
        "max_mp": max_mp,
        "level": level,
        "exp": exp,
        "gold": gold,
        "spells": spells,
        "relics": relics,
        "passives": passives,
        "element_affinity": element_affinity,
        "play_time": play_time,
        "kill_count": kill_count,
        "timestamp": timestamp,
        "checksum": generate_checksum()
    }

static func from_dict(data: Dictionary) -> SaveData:
    var save_data = SaveData.new()
    save_data.version = data.get("version", "1.0")
    save_data.slot = data.get("slot", 1)
    save_data.character = data.get("character", "")
    save_data.map = data.get("map", "")
    save_data.wave = data.get("wave", 1)
    save_data.hp = data.get("hp", 100.0)
    save_data.max_hp = data.get("max_hp", 100.0)
    save_data.mp = data.get("mp", 100.0)
    save_data.max_mp = data.get("max_mp", 100.0)
    save_data.level = data.get("level", 1)
    save_data.exp = data.get("exp", 0.0)
    save_data.gold = data.get("gold", 0)
    save_data.spells = data.get("spells", [])
    save_data.relics = data.get("relics", [])
    save_data.passives = data.get("passives", [])
    save_data.element_affinity = data.get("element_affinity", "")
    save_data.play_time = data.get("play_time", 0.0)
    save_data.kill_count = data.get("kill_count", 0)
    save_data.timestamp = data.get("timestamp", "")
    save_data.checksum = data.get("checksum", "")
    
    return save_data
```

#### 存档管理器

```gdscript
# SaveManager.gd - 存档管理器
class_name SaveManager
extends Node

const SAVE_DIR = "user://saves/"
const SAVE_FILE_PATTERN = "save_%d.json"
const BACKUP_FILE_PATTERN = "save_%d.backup.json"
const MAX_SAVE_SLOTS = 3

# 信号
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal save_error(error: String)

func _ready() -> void:
    # 确保存档目录存在
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int, save_data: SaveData) -> bool:
    if slot < 1 or slot > MAX_SAVE_SLOTS:
        save_error.emit("无效的存档槽位: %d" % slot)
        return false
    
    # 创建备份
    _create_backup(slot)
    
    # 生成校验和
    save_data.checksum = save_data.generate_checksum()
    save_data.timestamp = Time.get_datetime_string_from_system()
    
    # 转换为JSON
    var json_string = JSON.stringify(save_data.to_dict(), "\t")
    
    # 保存文件
    var file_path = SAVE_DIR + SAVE_FILE_PATTERN % slot
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    
    if file == null:
        save_error.emit("无法创建存档文件: %s" % file_path)
        return false
    
    file.store_string(json_string)
    file.close()
    
    game_saved.emit(slot)
    return true

func load_game(slot: int) -> SaveData:
    if slot < 1 or slot > MAX_SAVE_SLOTS:
        save_error.emit("无效的存档槽位: %d" % slot)
        return null
    
    var file_path = SAVE_DIR + SAVE_FILE_PATTERN % slot
    
    # 检查文件是否存在
    if not FileAccess.file_exists(file_path):
        # 尝试加载备份
        file_path = SAVE_DIR + BACKUP_FILE_PATTERN % slot
        if not FileAccess.file_exists(file_path):
            return null
    
    # 读取文件
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        save_error.emit("无法读取存档文件: %s" % file_path)
        return null
    
    var json_string = file.get_as_text()
    file.close()
    
    # 解析JSON
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    
    if parse_result != OK:
        save_error.emit("存档文件格式错误")
        return null
    
    var data = json.data
    
    # 验证校验和
    var save_data = SaveData.from_dict(data)
    if not save_data.validate_checksum():
        save_error.emit("存档文件校验失败，可能已被篡改")
        return null
    
    game_loaded.emit(slot)
    return save_data

func delete_save(slot: int) -> bool:
    if slot < 1 or slot > MAX_SAVE_SLOTS:
        return false
    
    var file_path = SAVE_DIR + SAVE_FILE_PATTERN % slot
    var backup_path = SAVE_DIR + BACKUP_FILE_PATTERN % slot
    
    # 删除主存档
    if FileAccess.file_exists(file_path):
        DirAccess.remove_absolute(file_path)
    
    # 删除备份
    if FileAccess.file_exists(backup_path):
        DirAccess.remove_absolute(backup_path)
    
    return true

func get_save_info(slot: int) -> Dictionary:
    var save_data = load_game(slot)
    if save_data == null:
        return {}
    
    return {
        "slot": slot,
        "character": save_data.character,
        "wave": save_data.wave,
        "map": save_data.map,
        "play_time": save_data.play_time,
        "timestamp": save_data.timestamp
    }

func _create_backup(slot: int) -> void:
    var file_path = SAVE_DIR + SAVE_FILE_PATTERN % slot
    var backup_path = SAVE_DIR + BACKUP_FILE_PATTERN % slot
    
    if FileAccess.file_exists(file_path):
        var file = FileAccess.open(file_path, FileAccess.READ)
        if file != null:
            var content = file.get_as_text()
            file.close()
            
            var backup_file = FileAccess.open(backup_path, FileAccess.WRITE)
            if backup_file != null:
                backup_file.store_string(content)
                backup_file.close()
```

---

## 4. 数据架构

### 4.1 Resource资源定义

#### 法术资源

```gdscript
# SpellResource.gd - 法术资源定义
class_name SpellResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var element: SpellBase.ElementType = SpellBase.ElementType.FIRE
@export var type: SpellBase.SpellType = SpellBase.SpellType.PROJECTILE

# 基础属性
@export var base_damage: float = 25.0
@export var cooldown: float = 1.2
@export var mana_cost: float = 10.0
@export var range: float = 300.0

# 升级数据
@export var level_multipliers: Array[float] = []
@export var upgrade_descriptions: Array[String] = []

# 质变点数据
@export var milestone_levels: Array[int] = [5, 10, 15, 20]
@export var milestone_effects: Array[Dictionary] = []

# 视觉资源
@export var icon: Texture2D = null
@export var projectile_scene: PackedScene = null
@export var cast_animation: String = ""
@export var hit_effect: PackedScene = null

# 音效资源
@export var cast_sound: AudioStream = null
@export var hit_sound: AudioStream = null

func get_level_multiplier(level: int) -> float:
    if level <= 0 or level > level_multipliers.size():
        return 1.0
    return level_multipliers[level - 1]

func get_milestone_effect(level: int) -> Dictionary:
    for i in range(milestone_levels.size()):
        if milestone_levels[i] == level:
            return milestone_effects[i] if i < milestone_effects.size() else {}
    return {}
```

#### 敌人资源

```gdscript
# EnemyResource.gd - 敌人资源定义
class_name EnemyResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var type: EnemyBase.EnemyType = EnemyBase.EnemyType.NORMAL

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
@export var has_special_ability: bool = false
@export var special_ability_cooldown: float = 5.0
@export var special_ability_script: GDScript = null

# 视觉资源
@export var sprite: Texture2D = null
@export var sprite_frames: SpriteFrames = null
@export var death_effect: PackedScene = null
@export var projectile_scene: PackedScene = null

# 音效资源
@export var spawn_sound: AudioStream = null
@export var death_sound: AudioStream = null
@export var attack_sound: AudioStream = null

# 掉落物
@export var drop_table: Array[Dictionary] = []
# 格式: [{"item": "experience_gem", "chance": 0.8, "min": 1, "max": 3}]

func get_wave_scaling(wave: int) -> Dictionary:
    var scaling_factor = 1.0 + wave * 0.10
    return {
        "health": max_health * scaling_factor,
        "damage": base_damage * scaling_factor,
        "speed": move_speed * (1.0 + wave * 0.02)
    }
```

### 4.2 JSON配置文件

#### 法术配置

```json
{
  "spells": {
    "F1": {
      "id": "F1",
      "name": "火球术",
      "description": "向鼠标方向发射火球，命中后造成范围爆炸伤害",
      "element": "fire",
      "type": "projectile",
      "base_damage": 25,
      "cooldown": 1.2,
      "mana_cost": 10,
      "range": 300,
      "level_multipliers": [
        1.0, 1.08, 1.16, 1.24, 1.40,
        1.52, 1.64, 1.76, 1.88, 2.20,
        2.40, 2.60, 2.80, 3.00, 3.50,
        3.80, 4.10, 4.40, 4.70, 5.50
      ],
      "milestone_levels": [5, 10, 15, 20],
      "milestone_effects": [
        {"level": 5, "effect": "explosion_range_up", "value": 0.3, "description": "爆炸范围+30%"},
        {"level": 10, "effect": "multi_cast", "value": 2, "description": "2连发"},
        {"level": 15, "effect": "homing", "value": true, "description": "追踪弹"},
        {"level": 20, "effect": "afterburn", "value": 3.0, "description": "爆炸产生火焰余烬，持续燃烧3秒"}
      ],
      "upgrade_descriptions": [
        "基础火球",
        "微量伤害提升",
        "微量伤害提升",
        "微量伤害提升",
        "✦ 爆炸范围+30%",
        "微量伤害提升",
        "微量伤害提升",
        "微量伤害提升",
        "微量伤害提升",
        "✦ 火球变为2连发",
        "微量伤害提升",
        "微量伤害提升",
        "微量伤害提升",
        "微量伤害提升",
        "✦ 火球变为追踪弹",
        "微量伤害提升",
        "微量伤害提升",
        "微量伤害提升",
        "微量伤害提升",
        "✦ 爆炸产生火焰余烬，持续燃烧3秒"
      ]
    },
    "W1": {
      "id": "W1",
      "name": "水弹",
      "description": "发射水弹，命中后减速敌人30%持续3秒",
      "element": "water",
      "type": "projectile",
      "base_damage": 15,
      "cooldown": 0.8,
      "mana_cost": 8,
      "range": 250
    }
  }
}
```

---

## 5. 技术实现方案

### 5.1 场景管理

#### 主场景结构

```
Main (Node)
├── GameManager (Autoload)
├── SceneManager (Autoload)
├── ResourceManager (Autoload)
├── AudioManager (Autoload)
├── InputManager (Autoload)
├── SaveManager (Autoload)
└── CurrentScene (Node)
    └── [当前加载的场景]
```

#### 场景切换

```gdscript
# SceneManager.gd - 场景管理器
class_name SceneManager
extends Node

var current_scene: Node = null
var scene_stack: Array[String] = []

# 场景路径映射
const SCENE_PATHS: Dictionary = {
    "main_menu": "res://Scenes/UI/MainMenu.tscn",
    "character_select": "res://Scenes/UI/CharacterSelect.tscn",
    "map_select": "res://Scenes/UI/MapSelect.tscn",
    "game": "res://Scenes/Game/GameScene.tscn",
    "settings": "res://Scenes/UI/Settings.tscn",
    "credits": "res://Scenes/UI/Credits.tscn"
}

# 信号
signal scene_changed(old_scene: String, new_scene: String)
signal scene_load_started(scene_name: String)
signal scene_load_completed(scene_name: String)

func _ready() -> void:
    current_scene = get_tree().current_scene

func change_scene(scene_name: String, add_to_stack: bool = true) -> void:
    if not SCENE_PATHS.has(scene_name):
        push_error("Unknown scene: " + scene_name)
        return
    
    scene_load_started.emit(scene_name)
    
    # 添加到场景栈
    if add_to_stack and current_scene != null:
        scene_stack.append(current_scene.scene_file_path)
    
    # 加载新场景
    var scene_path = SCENE_PATHS[scene_name]
    var new_scene = load(scene_path).instantiate()
    
    # 替换当前场景
    var old_scene_name = _get_scene_name(current_scene)
    get_tree().current_scene.queue_free()
    get_tree().root.add_child(new_scene)
    get_tree().current_scene = new_scene
    current_scene = new_scene
    
    scene_load_completed.emit(scene_name)
    scene_changed.emit(old_scene_name, scene_name)

func go_back() -> void:
    if scene_stack.is_empty():
        push_error("Scene stack is empty")
        return
    
    var previous_scene_path = scene_stack.pop_back()
    var scene_name = _get_scene_name_from_path(previous_scene_path)
    change_scene(scene_name, false)

func _get_scene_name(scene: Node) -> String:
    if scene == null:
        return ""
    return _get_scene_name_from_path(scene.scene_file_path)

func _get_scene_name_from_path(path: String) -> String:
    for name in SCENE_PATHS:
        if SCENE_PATHS[name] == path:
            return name
    return path.get_file().get_basename()
```

### 5.2 对象池系统

```gdscript
# ObjectPool.gd - 通用对象池
class_name ObjectPool
extends Node

var pool: Dictionary = {}  # 场景路径 -> 对象数组
var active_objects: Dictionary = {}  # 场景路径 -> 活跃对象数组

# 信号
signal object_spawned(object: Node)
signal object_recycled(object: Node)

func create_pool(scene_path: String, initial_size: int = 20) -> void:
    if pool.has(scene_path):
        return
    
    var scene = load(scene_path)
    pool[scene_path] = []
    active_objects[scene_path] = []
    
    for i in range(initial_size):
        var obj = scene.instantiate()
        obj.visible = false
        obj.process_mode = Node.PROCESS_MODE_DISABLED
        add_child(obj)
        pool[scene_path].append(obj)

func spawn(scene_path: String, position: Vector2 = Vector2.ZERO) -> Node:
    if not pool.has(scene_path):
        create_pool(scene_path, 1)
    
    var obj: Node = null
    
    # 从池中获取对象
    if pool[scene_path].size() > 0:
        obj = pool[scene_path].pop_back()
    else:
        # 池为空，创建新对象
        var scene = load(scene_path)
        obj = scene.instantiate()
        add_child(obj)
    
    # 激活对象
    obj.global_position = position
    obj.visible = true
    obj.process_mode = Node.PROCESS_MODE_INHERIT
    
    active_objects[scene_path].append(obj)
    object_spawned.emit(obj)
    
    return obj

func recycle(obj: Node) -> void:
    var scene_path = obj.scene_file_path
    
    # 从活跃列表中移除
    if active_objects.has(scene_path):
        active_objects[scene_path].erase(obj)
    
    # 回收到池中
    obj.visible = false
    obj.process_mode = Node.PROCESS_MODE_DISABLED
    
    if not pool.has(scene_path):
        pool[scene_path] = []
    
    pool[scene_path].append(obj)
    object_recycled.emit(obj)

func get_active_count(scene_path: String) -> int:
    if active_objects.has(scene_path):
        return active_objects[scene_path].size()
    return 0

func get_pool_size(scene_path: String) -> int:
    if pool.has(scene_path):
        return pool[scene_path].size()
    return 0

func clear_pool(scene_path: String) -> void:
    if pool.has(scene_path):
        for obj in pool[scene_path]:
            obj.queue_free()
        pool.erase(scene_path)
    
    if active_objects.has(scene_path):
        for obj in active_objects[scene_path]:
            obj.queue_free()
        active_objects.erase(scene_path)
```

### 5.3 音频管理

```gdscript
# AudioManager.gd - 音频管理器
class_name AudioManager
extends Node

# 音频总线
const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"
const UI_BUS = "UI"

# 音频播放器
var music_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
var ui_players: Array[AudioStreamPlayer] = []

# 音量设置
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0
var ui_volume: float = 0.8

# 音频池大小
const SFX_POOL_SIZE = 10
const UI_POOL_SIZE = 5

func _ready() -> void:
    _initialize_audio_players()
    _load_audio_settings()

func _initialize_audio_players() -> void:
    # 创建音乐播放器
    music_player = AudioStreamPlayer.new()
    music_player.bus = MUSIC_BUS
    add_child(music_player)
    
    # 创建音效播放器池
    for i in range(SFX_POOL_SIZE):
        var player = AudioStreamPlayer.new()
        player.bus = SFX_BUS
        add_child(player)
        sfx_players.append(player)
    
    # 创建UI音效播放器池
    for i in range(UI_POOL_SIZE):
        var player = AudioStreamPlayer.new()
        player.bus = UI_BUS
        add_child(player)
        ui_players.append(player)

func play_music(music: AudioStream, fade_time: float = 1.0) -> void:
    if music_player.playing:
        # 淡出当前音乐
        var tween = create_tween()
        tween.tween_property(music_player, "volume_db", -80, fade_time / 2)
        await tween.finished
    
    music_player.stream = music
    music_player.volume_db = linear_to_db(music_volume)
    music_player.play()
    
    if fade_time > 0:
        music_player.volume_db = -80
        var tween = create_tween()
        tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_time / 2)

func stop_music(fade_time: float = 1.0) -> void:
    if not music_player.playing:
        return
    
    var tween = create_tween()
    tween.tween_property(music_player, "volume_db", -80, fade_time)
    await tween.finished
    music_player.stop()

func play_sfx(sfx: AudioStream, volume_scale: float = 1.0) -> void:
    var player = _get_free_sfx_player()
    if player == null:
        return
    
    player.stream = sfx
    player.volume_db = linear_to_db(sfx_volume * volume_scale)
    player.play()

func play_ui_sfx(sfx: AudioStream) -> void:
    var player = _get_free_ui_player()
    if player == null:
        return
    
    player.stream = sfx
    player.volume_db = linear_to_db(ui_volume)
    player.play()

func set_master_volume(volume: float) -> void:
    master_volume = clamp(volume, 0.0, 1.0)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(master_volume))
    _save_audio_settings()

func set_music_volume(volume: float) -> void:
    music_volume = clamp(volume, 0.0, 1.0)
    if music_player.playing:
        music_player.volume_db = linear_to_db(music_volume)
    _save_audio_settings()

func set_sfx_volume(volume: float) -> void:
    sfx_volume = clamp(volume, 0.0, 1.0)
    _save_audio_settings()

func set_ui_volume(volume: float) -> void:
    ui_volume = clamp(volume, 0.0, 1.0)
    _save_audio_settings()

func _get_free_sfx_player() -> AudioStreamPlayer:
    for player in sfx_players:
        if not player.playing:
            return player
    
    # 所有播放器都在使用，返回第一个
    return sfx_players[0]

func _get_free_ui_player() -> AudioStreamPlayer:
    for player in ui_players:
        if not player.playing:
            return player
    
    return ui_players[0]

func _save_audio_settings() -> void:
    var settings = {
        "master_volume": master_volume,
        "music_volume": music_volume,
        "sfx_volume": sfx_volume,
        "ui_volume": ui_volume
    }
    
    var file = FileAccess.open("user://audio_settings.json", FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(settings, "\t"))
        file.close()

func _load_audio_settings() -> void:
    if not FileAccess.file_exists("user://audio_settings.json"):
        return
    
    var file = FileAccess.open("user://audio_settings.json", FileAccess.READ)
    if file == null:
        return
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    
    if parse_result == OK:
        var settings = json.data
        master_volume = settings.get("master_volume", 1.0)
        music_volume = settings.get("music_volume", 0.7)
        sfx_volume = settings.get("sfx_volume", 1.0)
        ui_volume = settings.get("ui_volume", 0.8)
        
        # 应用音量设置
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(master_volume))
```

---

## 6. 性能优化策略

### 6.1 渲染优化

#### 批处理渲染

```gdscript
# ProjectileRenderer.gd - 投射物批处理渲染
extends MultiMeshInstance2D

const MAX_PROJECTILES = 500

var projectile_mesh: ImmediateMesh = null
var projectile_material: ShaderMaterial = null

func _ready() -> void:
    _initialize_multimesh()

func _initialize_multimesh() -> void:
    # 创建MultiMesh
    var multimesh = MultiMesh.new()
    multimesh.instance_count = MAX_PROJECTILES
    multimesh.visible_instance_count = 0
    multimesh.transform_format = MultiMesh.TRANSFORM_2D
    multimesh.custom_aabb = AABB(Vector3(-1000, -1000, -1000), Vector3(2000, 2000, 2000))
    
    # 创建网格
    var mesh = QuadMesh.new()
    mesh.size = Vector2(8, 8)
    multimesh.mesh = mesh
    
    # 创建材质
    var material = ShaderMaterial.new()
    material.shader = load("res://Shaders/projectile_shader.gdshader")
    multimesh.material = material
    
    self.multimesh = multimesh
    projectile_material = material

func update_projectiles(projectiles: Array[Node2D]) -> void:
    var count = min(projectiles.size(), MAX_PROJECTILES)
    multimesh.visible_instance_count = count
    
    for i in range(count):
        var projectile = projectiles[i]
        var transform = Transform2D(0, projectile.global_position)
        multimesh.set_instance_transform_2d(i, transform)
        
        # 更新实例数据（如颜色、大小等）
        _update_instance_data(i, projectile)

func _update_instance_data(index: int, projectile: Node2D) -> void:
    # 可以通过自定义数据传递额外信息
    # 例如：颜色、大小、生命周期等
    pass
```

#### 对象池优化

```gdscript
# EnemyObjectPool.gd - 敌人对象池优化
extends Node

var enemy_pools: Dictionary = {}  # 敌人类型 -> 对象池

func _ready() -> void:
    _initialize_enemy_pools()

func _initialize_enemy_pools() -> void:
    # 预加载敌人场景
    var enemy_scenes = {
        "shadow_servant": "res://Scenes/Enemies/ShadowServant.tscn",
        "skeleton_warrior": "res://Scenes/Enemies/SkeletonWarrior.tscn",
        "gargoyle": "res://Scenes/Enemies/Gargoyle.tscn",
        # ... 其他敌人类型
    }
    
    for enemy_type in enemy_scenes:
        var scene_path = enemy_scenes[enemy_type]
        var pool = ObjectPool.new()
        pool.create_pool(scene_path, 20)  # 预创建20个
        add_child(pool)
        enemy_pools[enemy_type] = pool

func spawn_enemy(enemy_type: String, position: Vector2, wave: int) -> EnemyBase:
    if not enemy_pools.has(enemy_type):
        push_error("Unknown enemy type: " + enemy_type)
        return null
    
    var enemy = enemy_pools[enemy_type].spawn(
        enemy_pools[enemy_type].pool[enemy_type][0].scene_file_path,
        position
    )
    
    # 应用波次缩放
    var scaling = enemy.get_node("EnemyResource").get_wave_scaling(wave)
    enemy.max_health = scaling.health
    enemy.current_health = scaling.health
    enemy.base_damage = scaling.damage
    enemy.move_speed = scaling.speed
    
    return enemy

func recycle_enemy(enemy: EnemyBase) -> void:
    var enemy_type = enemy.enemy_id
    if enemy_pools.has(enemy_type):
        enemy_pools[enemy_type].recycle(enemy)
```

### 6.2 物理优化

```gdscript
# CollisionOptimizer.gd - 碰撞优化
extends Node

# 空间分区网格
var grid_size: Vector2 = Vector2(64, 64)
var grid_cells: Dictionary = {}  # 网格坐标 -> 物体列表

func _ready() -> void:
    # 连接物理帧信号
    get_tree().physics_frame.connect(_on_physics_frame)

func _on_physics_frame() -> void:
    # 清空网格
    grid_cells.clear()
    
    # 将所有敌人分配到网格
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        var grid_pos = _world_to_grid(enemy.global_position)
        if not grid_cells.has(grid_pos):
            grid_cells[grid_pos] = []
        grid_cells[grid_pos].append(enemy)

func get_nearby_enemies(position: Vector2, radius: float) -> Array[Node2D]:
    var nearby: Array[Node2D] = []
    var grid_radius = int(ceil(radius / grid_size.x))
    var center_grid = _world_to_grid(position)
    
    for x in range(-grid_radius, grid_radius + 1):
        for y in range(-grid_radius, grid_radius + 1):
            var grid_pos = Vector2i(center_grid.x + x, center_grid.y + y)
            if grid_cells.has(grid_pos):
                for enemy in grid_cells[grid_pos]:
                    var distance = position.distance_to(enemy.global_position)
                    if distance <= radius:
                        nearby.append(enemy)
    
    return nearby

func _world_to_grid(world_pos: Vector2) -> Vector2i:
    return Vector2i(
        int(floor(world_pos.x / grid_size.x)),
        int(floor(world_pos.y / grid_size.y))
    )
```

### 6.3 内存优化

```gdscript
# MemoryOptimizer.gd - 内存优化
extends Node

# 资源缓存
var resource_cache: Dictionary = {}  # 资源路径 -> 资源实例

# 纹理缓存
var texture_cache: Dictionary = {}  # 纹理路径 -> 纹理实例

func _ready() -> void:
    # 连接内存警告信号
    if OS.has_feature("windows"):
        # Windows特定的内存监控
        pass

func preload_resources(resource_paths: Array[String]) -> void:
    for path in resource_paths:
        if not resource_cache.has(path):
            var resource = load(path)
            resource_cache[path] = resource

func get_resource(path: String) -> Resource:
    if resource_cache.has(path):
        return resource_cache[path]
    
    var resource = load(path)
    resource_cache[path] = resource
    return resource

func preload_textures(texture_paths: Array[String]) -> void:
    for path in texture_paths:
        if not texture_cache.has(path):
            var texture = load(path)
            texture_cache[path] = texture

func get_texture(path: String) -> Texture2D:
    if texture_cache.has(path):
        return texture_cache[path]
    
    var texture = load(path)
    texture_cache[path] = texture
    return texture

func clear_cache() -> void:
    resource_cache.clear()
    texture_cache.clear()
    
    # 强制垃圾回收
    if OS.has_feature("windows"):
        # Windows垃圾回收
        pass

func get_memory_usage() -> Dictionary:
    var usage = {
        "resource_cache_size": resource_cache.size(),
        "texture_cache_size": texture_cache.size(),
        "total_nodes": _count_nodes(get_tree().root)
    }
    
    return usage

func _count_nodes(node: Node) -> int:
    var count = 1
    for child in node.get_children():
        count += _count_nodes(child)
    return count
```

---

## 7. 扩展性设计

### 7.1 插件系统

```gdscript
# PluginManager.gd - 插件管理器
class_name PluginManager
extends Node

var plugins: Dictionary = {}  # 插件名 -> 插件实例
var plugin_dir: String = "user://plugins/"

func _ready() -> void:
    _discover_plugins()

func _discover_plugins() -> void:
    var dir = DirAccess.open(plugin_dir)
    if dir == null:
        return
    
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if dir.current_is_dir() and file_name != "." and file_name != "..":
            var plugin_path = plugin_dir + file_name + "/plugin.cfg"
            if FileAccess.file_exists(plugin_path):
                _load_plugin(file_name)
        file_name = dir.get_next()

func _load_plugin(plugin_name: String) -> void:
    var plugin_path = plugin_dir + plugin_name + "/plugin.cfg"
    var config = ConfigFile.new()
    
    if config.load(plugin_path) != OK:
        push_error("Failed to load plugin config: " + plugin_path)
        return
    
    var script_path = config.get_value("plugin", "script", "")
    if script_path == "":
        push_error("Plugin script not defined: " + plugin_name)
        return
    
    var script = load(script_path)
    if script == null:
        push_error("Failed to load plugin script: " + script_path)
        return
    
    var plugin_instance = script.new()
    if plugin_instance == null:
        push_error("Failed to instantiate plugin: " + plugin_name)
        return
    
    plugins[plugin_name] = plugin_instance
    add_child(plugin_instance)
    
    # 调用插件初始化
    if plugin_instance.has_method("initialize"):
        plugin_instance.initialize()

func get_plugin(plugin_name: String) -> Node:
    return plugins.get(plugin_name)

func unload_plugin(plugin_name: String) -> void:
    if plugins.has(plugin_name):
        var plugin = plugins[plugin_name]
        if plugin.has_method("cleanup"):
            plugin.cleanup()
        
        remove_child(plugin)
        plugin.queue_free()
        plugins.erase(plugin_name)
```

### 7.2 模块热重载

```gdscript
# HotReloadManager.gd - 热重载管理器
class_name HotReloadManager
extends Node

var watched_scripts: Dictionary = {}  # 脚本路径 -> 修改时间
var reload_callbacks: Dictionary = {}  # 脚本路径 -> 回调函数

func _ready() -> void:
    if OS.is_debug_build():
        # 只在调试模式下启用
        _start_watching()

func _start_watching() -> void:
    # 连接进程帧信号
    process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
    for script_path in watched_scripts:
        var last_modified = watched_scripts[script_path]
        var current_modified = _get_file_modified_time(script_path)
        
        if current_modified > last_modified:
            watched_scripts[script_path] = current_modified
            _on_script_changed(script_path)

func watch_script(script_path: String, callback: Callable = Callable()) -> void:
    watched_scripts[script_path] = _get_file_modified_time(script_path)
    if callback.is_valid():
        reload_callbacks[script_path] = callback

func _on_script_changed(script_path: String) -> void:
    print("Script changed: " + script_path)
    
    # 重新加载脚本
    var script = load(script_path)
    if script == null:
        push_error("Failed to reload script: " + script_path)
        return
    
    # 执行回调
    if reload_callbacks.has(script_path):
        reload_callbacks[script_path].call(script)

func _get_file_modified_time(file_path: String) -> int:
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        return 0
    
    var modified_time = file.get_modified_time(file_path)
    file.close()
    return modified_time
```

---

## 8. 开发路线图

### 8.1 Phase 1：核心原型（4周）

#### 目标
- 实现基础战斗系统
- 完成1个可玩角色（炽焰）
- 实现4个基础法术
- 完成基础敌人AI
- 创建单张测试地图
- 完成基础UI

#### 任务分解

| 周次 | 任务 | 产出 |
|------|------|------|
| **第1周** | 项目搭建 + 核心系统 | GameManager, SceneManager, Player系统 |
| **第2周** | 法术系统基础 | SpellBase, 火球术, 法术槽位 |
| **第3周** | 敌人系统基础 | EnemyBase, 敌人AI, 生成器 |
| **第4周** | UI + 整合测试 | HUD, 暂停菜单, 基础测试 |

#### 里程碑产出
- 可运行的游戏原型
- 基础战斗循环验证
- 性能基准测试

### 8.2 Phase 2：核心系统（8周）

#### 目标
- 完整法术进化系统（30个法术）
- 元素融合系统（15种融合）
- 遗物系统（30个遗物）
- 3个完整地图
- 10种敌人类型 + 2个Boss
- 无限波次模式
- 存档系统

#### 任务分解

| 周次 | 任务 | 产出 |
|------|------|------|
| **第5-6周** | 法术系统完善 | 30个法术实现, 升级系统, 融合系统 |
| **第7-8周** | 敌人系统完善 | 15种敌人, Boss战, 波次生成器 |
| **第9-10周** | 地图系统 | 3张地图, 环境效果, 商店系统 |
| **第11-12周** | 遗物+存档 | 30个遗物, 存档系统, UI完善 |

#### 里程碑产出
- 完整的法术系统
- 丰富的敌人种类
- 多样的地图体验
- 稳定的存档系统

### 8.3 Phase 3：内容填充（8周）

#### 目标
- 3个完整角色
- 15种敌人 + 3个Boss
- 5张完整地图
- 契约系统
- 图鉴系统
- 成就系统

#### 任务分解

| 周次 | 任务 | 产出 |
|------|------|------|
| **第13-14周** | 角色系统 | 3个角色实现, 角色平衡 |
| **第15-16周** | 敌人+Boss | 剩余敌人, 3个Boss战 |
| **第17-18周** | 地图系统 | 5张地图, 地图机制 |
| **第19-20周** | 系统完善 | 契约系统, 图鉴系统, 成就系统 |

#### 里程碑产出
- 完整的角色选择
- 丰富的游戏内容
- 深度的进度系统

### 8.4 Phase 4：打磨发布（4周）

#### 目标
- UI/UX优化（伤害数字、小地图、击杀统计）
- 音乐音效
- 平衡性调整
- Bug修复
- 性能优化
- Steam上架准备

#### 任务分解

| 周次 | 任务 | 产出 |
|------|------|------|
| **第21周** | UI/UX优化 | 伤害数字系统, 小地图, 击杀统计 |
| **第22周** | 音频系统 | 背景音乐, 音效, 音频设置 |
| **第23周** | 平衡性+Bug修复 | 数值调整, Bug修复, 稳定性优化 |
| **第24周** | 发布准备 | Steam上架, 打包, 文档 |

#### 里程碑产出
- 完整的游戏体验
- 稳定的游戏版本
- 发布就绪状态

---

## 📝 文档历史

| 版本 | 日期 | 修改内容 |
|------|------|----------|
| v1.0 | 2026-08-27 | 初始版本，完成架构设计 |

---

**文档生成：** MiMo-v2.5  
**项目代号：** Grimoire-Echoes  
**文档状态：** 架构设计完成，可进入技术实现阶段