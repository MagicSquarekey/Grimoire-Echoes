# 🔧 秘法回响（Grimoire Echoes）— Godot 4.x 技术实现方案

> **文档版本：** v1.0  
> **日期：** 2026-08-27  
> **引擎：** Godot 4.x（GDScript 为主）  
> **平台：** Windows 11 本地单机  

---

## 目录

1. [项目结构与目录规范](#1-项目结构与目录规范)
2. [场景树架构设计](#2-场景树架构设计)
3. [核心系统实现](#3-核心系统实现)
4. [法术系统实现](#4-法术系统实现)
5. [敌人AI与波次系统](#5-敌人ai与波次系统)
6. [Roguelite升级系统](#6-roguelite升级系统)
7. [地图系统实现](#7-地图系统实现)
8. [UI/UX系统](#8-uiux系统)
9. [存档系统](#9-存档系统)
10. [性能优化策略](#10-性能优化策略)
11. [资产管线与工作流](#11-资产管线与工作流)
12. [调试与测试工具](#12-调试与测试工具)

---

## 1. 项目结构与目录规范

### 1.1 项目根目录结构

```
grimoire_echoes/
├── project.godot                    # Godot 项目配置
├── export_presets.cfg               # 导出配置
├── .godot/                          # Godot 编辑器缓存
│
├── assets/                          # 所有原始资产
│   ├── art/                         # 美术资产
│   │   ├── characters/              # 角色精灵图
│   │   │   ├── mage_fire/           # 炽焰（火焰法师）
│   │   │   ├── mage_shadow/         # 暮霭（暗影法师）
│   │   │   └── mage_nature/         # 露珠（自然法师）
│   │   ├── enemies/                 # 敌人精灵图
│   │   │   ├── common/              # 普通敌人
│   │   │   ├── elite/               # 精英敌人
│   │   │   └── boss/                # Boss
│   │   ├── spells/                  # 法术特效帧
│   │   │   ├── fire/                # 火焰系
│   │   │   ├── water/               # 水流系
│   │   │   ├── lightning/           # 雷电系
│   │   │   ├── nature/              # 自然系
│   │   │   ├── shadow/              # 暗影系
│   │   │   └── air/                 # 风暴系
│   │   ├── maps/                    # 地图瓦片集
│   │   │   ├── forest/              # 幽暗森林
│   │   │   ├── lava/                # 熔岩裂谷
│   │   │   ├── ice/                 # 冰封山脉
│   │   │   ├── shadow_realm/        # 暗影深渊
│   │   │   └── altar/               # 元素祭坛
│   │   ├── ui/                      # UI 素材
│   │   │   ├── icons/               # 图标
│   │   │   ├── hud/                 # HUD 元素
│   │   │   ├── menus/               # 菜单背景
│   │   │   └── fonts/               # 字体文件
│   │   └── effects/                 # 通用特效帧
│   │
│   ├── audio/                       # 音频资产
│   │   ├── music/                   # 背景音乐
│   │   └── sfx/                     # 音效
│   │       ├── spells/              # 法术音效
│   │       ├── enemies/             # 敌人音效
│   │       ├── ui/                  # UI 音效
│   │       └── environment/         # 环境音效
│   │
│   └── data/                        # 数据资产
│       ├── spells.json              # 法术数据表
│       ├── enemies.json             # 敌人数据表
│       ├── relics.json              # 遗物数据表
│       ├── passives.json            # 被动技能数据表
│       ├── waves.json               # 波次配置
│       ├── maps.json                # 地图配置
│       └── balance.json             # 平衡性数值
│
├── scenes/                          # 场景文件（.tscn）
│   ├── main/                        # 主场景
│   │   ├── main_menu.tscn           # 主菜单
│   │   ├── game.tscn                # 游戏主场景
│   │   └── settings.tscn            # 设置界面
│   ├── player/                      # 玩家相关场景
│   │   ├── player.tscn              # 玩家角色
│   │   ├── spell_slot.tscn          # 法术槽位
│   │   └── player_hud.tscn          # 玩家HUD
│   ├── enemies/                     # 敌人场景
│   │   ├── base_enemy.tscn          # 敌人基类
│   │   ├── shadow_servant.tscn      # 暗影仆从
│   │   ├── skeleton_warrior.tscn    # 骷髅战士
│   │   └── ...                      # 其他敌人
│   ├── spells/                      # 法术场景
│   │   ├── base_spell.tscn          # 法术基类
│   │   ├── fireball.tscn            # 火球术
│   │   └── ...                      # 其他法术
│   ├── maps/                        # 地图场景
│   │   ├── forest_map.tscn          # 幽暗森林
│   │   └── ...                      # 其他地图
│   ├── ui/                          # UI 场景
│   │   ├── upgrade_panel.tscn       # 升级选择面板
│   │   ├── pause_menu.tscn          # 暂停菜单
│   │   ├── shop_ui.tscn             # 商店界面
│   │   ├── save_slot.tscn           # 存档槽位
│   │   └── ...                      # 其他UI
│   └── effects/                     # 特效场景
│       ├── damage_number.tscn       # 伤害数字
│       └── particle_effect.tscn     # 通用粒子效果
│
├── scripts/                         # 脚本文件（.gd）
│   ├── autoload/                    # 全局单例（Autoload）
│   │   ├── game_manager.gd          # 游戏管理器
│   │   ├── spell_manager.gd         # 法术管理器
│   │   ├── wave_manager.gd          # 波次管理器
│   │   ├── save_manager.gd          # 存档管理器
│   │   ├── audio_manager.gd         # 音频管理器
│   │   ├── event_bus.gd             # 事件总线
│   │   └── object_pool.gd           # 对象池管理器
│   │
│   ├── player/                      # 玩家相关脚本
│   │   ├── player.gd                # 玩家主逻辑
│   │   ├── player_stats.gd          # 玩家属性
│   │   └── player_controller.gd     # 输入控制
│   │
│   ├── spells/                      # 法术相关脚本
│   │   ├── base_spell.gd            # 法术基类
│   │   ├── spell_data.gd            # 法术数据资源
│   │   ├── projectile_spell.gd      # 投射物法术
│   │   ├── aoe_spell.gd             # 范围法术
│   │   ├── buff_spell.gd            # 增益法术
│   │   ├── summon_spell.gd          # 召唤法术
│   │   └── fusion_system.gd         # 融合系统
│   │
│   ├── enemies/                     # 敌人相关脚本
│   │   ├── base_enemy.gd            # 敌人基类
│   │   ├── enemy_spawner.gd         # 敌人生成器
│   │   ├── enemy_ai.gd              # 敌人AI状态机
│   │   └── boss_controller.gd       # Boss控制器
│   │
│   ├── systems/                     # 游戏系统脚本
│   │   ├── experience_system.gd     # 经验值系统
│   │   ├── relic_system.gd          # 遗物系统
│   │   ├── passive_system.gd        # 被动技能系统
│   │   ├── element_system.gd        # 元素系统
│   │   ├── status_effect_system.gd  # 状态效果系统
│   │   └── damage_calculator.gd     # 伤害计算器
│   │
│   ├── ui/                          # UI 相关脚本
│   │   ├── main_menu_ui.gd          # 主菜单
│   │   ├── hud.gd                   # 游戏内HUD
│   │   ├── upgrade_ui.gd            # 升级界面
│   │   ├── pause_ui.gd              # 暂停菜单
│   │   ├── shop_ui.gd               # 商店界面
│   │   └── minimap.gd               # 小地图
│   │
│   ├── map/                         # 地图相关脚本
│   │   ├── map_generator.gd         # 地图生成器
│   │   ├── map_hazard.gd            # 地图陷阱
│   │   └── hidden_area.gd           # 隐藏区域
│   │
│   └── utils/                       # 工具脚本
│       ├── math_utils.gd            # 数学工具
│       ├── object_pool.gd           # 对象池
│       ├── data_loader.gd           # 数据加载器
│       └── debug_tools.gd           # 调试工具
│
├── addons/                          # 第三方插件
│   └── ...                          # 根据需要添加
│
└── tests/                           # 测试场景
    ├── unit/                         # 单元测试
    └── integration/                  # 集成测试
```

### 1.2 命名规范

| 类别 | 规范 | 示例 |
|------|------|------|
| **场景文件** | snake_case.tscn | `fireball.tscn` |
| **脚本文件** | snake_case.gd | `base_spell.gd` |
| **资源文件** | PascalCase.tres | `FireballData.tres` |
| **节点名** | PascalCase | `SpellSlot1` |
| **变量/函数** | snake_case | `current_hp`, `take_damage()` |
| **常量/枚举** | SCREAMING_SNAKE_CASE | `MAX_SPELL_SLOTS` |
| **信号** | snake_case（动词过去式） | `health_changed`, `spell_fired` |
| **Autoload 单例** | PascalCase | `GameManager`, `EventBus` |

### 1.3 Godot 项目配置（project.godot 关键设置）

```ini
[application]
config/name="秘法回响"
config/description="Grimoire Echoes - 类幸存者肉鸽动作游戏"
run/main_scene="res://scenes/main/main_menu.tscn"
config/features=PackedStringArray("4.3", "GL Compatibility")

[autoload]
EventBus="*res://scripts/autoload/event_bus.gd"
GameManager="*res://scripts/autoload/game_manager.gd"
SpellManager="*res://scripts/autoload/spell_manager.gd"
WaveManager="*res://scripts/autoload/wave_manager.gd"
SaveManager="*res://scripts/autoload/save_manager.gd"
AudioManager="*res://scripts/autoload/audio_manager.gd"
ObjectPool="*res://scripts/autoload/object_pool.gd"

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[input]
move_up={deadzone: 0.5, events: [InputEventKey(keycode=87)]}  # W
move_down={deadzone: 0.5, events: [InputEventKey(keycode=83)]}  # S
move_left={deadzone: 0.5, events: [InputEventKey(keycode=65)]}  # A
move_right={deadzone: 0.5, events: [InputEventKey(keycode=68)]}  # D
dodge={deadzone: 0.5, events: [InputEventKey(keycode=4194325)]}  # Shift
interact={deadzone: 0.5, events: [InputEventKey(keycode=69)]}  # E
pause={deadzone: 0.5, events: [InputEventKey(keycode=4194305)]}  # Escape
speed_toggle={deadzone: 0.5, events: [InputEventKey(keycode=4194330)]}  # Tab
minimap_toggle={deadzone: 0.5, events: [InputEventKey(keycode=77)]}  # M

[physics]
2d/default_gravity=0.0  # 俯视角，无重力

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

---

## 2. 场景树架构设计

### 2.1 主场景架构（game.tscn）

```
Game (Node2D)
├── Camera2D                        # 主摄像机（跟随玩家）
│   └── CameraShake                 # 震屏效果节点
│
├── Map                             # 当前地图容器（TileMapLayer）
│   ├── Ground                     # 地面层
│   ├── Obstacles                  # 障碍物层
│   ├── Hazards                    # 陷阱层
│   └── Decorations                # 装饰层
│
├── Entities                        # 游戏实体容器
│   ├── Player                     # 玩家角色
│   │   ├── CharacterBody2D        # 物理体
│   │   ├── AnimatedSprite2D       # 精灵动画
│   │   ├── CollisionShape2D       # 碰撞体
│   │   ├── SpellCaster            # 法术施放器
│   │   ├── HitboxComponent        # 受击判定
│   │   ├── HurtboxComponent       # 伤害判定
│   │   └── StatusEffects          # 状态效果容器
│   │
│   ├── Enemies                     # 敌人容器
│   │   └── (动态添加敌人实例)
│   │
│   ├── Projectiles                 # 投射物容器
│   │   └── (动态添加法术投射物)
│   │
│   ├── Summons                     # 召唤物容器
│   │   └── (动态添加召唤物)
│   │
│   └── Pickups                     # 拾取物容器
│       ├── ExperienceGems          # 经验宝石
│       ├── GoldCoins              # 金币
│       └── Items                  # 道具
│
├── Effects                         # 特效容器
│   ├── DamageNumbers              # 伤害数字层
│   ├── SpellEffects               # 法术特效层
│   └── EnvironmentEffects         # 环境特效层
│
├── UI                              # UI 层（CanvasLayer）
│   ├── HUD                        # 游戏内HUD
│   │   ├── HealthBar              # 血量条
│   │   ├── ManaBar                # 法力条
│   │   ├── EXPBar                 # 经验条
│   │   ├── SpellSlots             # 法术槽位
│   │   ├── WaveInfo               # 波次信息
│   │   ├── MiniMap                # 小地图
│   │   ├── KillCounter            # 击杀计数
│   │   └── SpeedIndicator         # 加速指示器
│   │
│   ├── PauseMenu                  # 暂停菜单（默认隐藏）
│   ├── UpgradePanel               # 升级选择面板（默认隐藏）
│   ├── ShopUI                     # 商店界面（默认隐藏）
│   └── BossWarning                # Boss警告（默认隐藏）
│
├── WorldEnvironment               # 世界环境
│   └── CanvasModulate             # 全局光照调制
│
└── Systems                        # 系统节点
    ├── WaveTimer                  # 波次计时器
    ├── AutoSaveTimer              # 自动存档计时器
    └── SpawnDirector              # 生成调度器
```

### 2.2 玩家场景结构（player.tscn）

```
Player (CharacterBody2D)
├── AnimatedSprite2D               # 精灵动画
├── CollisionShape2D               # 物理碰撞
│
├── HitboxComponent (Area2D)       # 攻击判定区（被攻击时）
│   └── CollisionShape2D
│
├── HurtboxComponent (Area2D)      # 受击判定区（攻击敌人时）
│   └── CollisionShape2D
│
├── SpellCaster (Node2D)           # 法术施放管理器
│   ├── SpellSlot1                 # 法术槽位1
│   ├── SpellSlot2                 # 法术槽位2
│   ├── SpellSlot3                 # 法术槽位3（Lv.5解锁）
│   ├── SpellSlot4                 # 法术槽位4（Lv.10解锁）
│   └── UltimateSlot               # 终极槽（Lv.15解锁）
│
├── StatusEffects (Node)           # 状态效果管理器
│
├── PickupDetector (Area2D)        # 拾取范围检测
│   └── CollisionShape2D           # 圆形，半径80px
│
├── DodgeSystem (Node)             # 闪避系统
│
└── PassiveEffects (Node)          # 被动效果管理器
```

### 2.3 敌人场景结构（base_enemy.tscn）

```
BaseEnemy (CharacterBody2D)
├── AnimatedSprite2D               # 精灵动画
├── CollisionShape2D               # 物理碰撞
│
├── HitboxComponent (Area2D)       # 攻击判定区
│   └── CollisionShape2D
│
├── HurtboxComponent (Area2D)      # 受击判定区
│   └── CollisionShape2D
│
├── HealthBar (ProgressBar)        # 血条（头顶显示）
│
├── StatusEffects (Node)           # 状态效果管理器
│
├── AISensor (Area2D)              # AI感知范围
│   └── CollisionShape2D
│
└── DeathEffect (GPUParticles2D)   # 死亡特效
```

### 2.4 法术场景结构（base_spell.tscn）

```
BaseSpell (Node2D)
├── SpellSprite (Sprite2D/AnimatedSprite2D)  # 法术精灵
├── SpellHitbox (Area2D)                      # 命中判定
│   └── CollisionShape2D
├── SpellEffect (GPUParticles2D)              # 粒子特效
└── SpellTrail (Trail2D)                      # 拖尾效果（可选）
```

---

## 3. 核心系统实现

### 3.1 事件总线（EventBus）— 全局信号中心

```gdscript
# scripts/autoload/event_bus.gd
extends Node

## 游戏状态信号
signal game_started
signal game_paused(is_paused: bool)
signal game_over(stats: Dictionary)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal boss_spawned(boss_type: String)

## 玩家信号
signal player_damaged(amount: float, source: Node2D)
signal player_healed(amount: float)
signal player_died
signal player_level_up(new_level: int)
signal player_dodged

## 法术信号
signal spell_cast(spell_data: SpellData, caster: Node2D)
signal spell_hit(spell_data: SpellData, target: Node2D, damage: float)
signal spell_upgraded(spell_data: SpellData, new_level: int)
signal spell_fusion_unlocked(fusion_id: String)

## 敌人信号
signal enemy_spawned(enemy: BaseEnemy)
signal enemy_killed(enemy: BaseEnemy, exp_reward: int)
signal enemy_damaged(enemy: BaseEnemy, amount: float, damage_type: DamageType)

## 系统信号
signal exp_changed(current_exp: int, required_exp: int)
signal gold_changed(amount: int)
signal relic_acquired(relic_data: RelicData)
signal passive_acquired(passive_data: PassiveData)
signal upgrade_options_ready(options: Array[UpgradeOption])
signal upgrade_selected(option: UpgradeOption)

## UI信号
signal show_damage_number(position: Vector2, amount: float, type: DamageType)
signal show_toast(message: String, duration: float)
```

### 3.2 游戏管理器（GameManager）— 全局状态控制

```gdscript
# scripts/autoload/game_manager.gd
extends Node

enum GameState {
    MENU,
    PLAYING,
    PAUSED,
    UPGRADE,
    SHOP,
    GAME_OVER
}

var current_state: GameState = GameState.MENU
var current_wave: int = 0
var current_map: String = ""
var selected_character: String = ""
var play_time: float = 0.0
var total_kills: int = 0
var gold: int = 0
var speed_multiplier: float = 1.0

# 存档相关
var active_save_slot: int = -1
var has_unsaved_progress: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func start_new_game(character: String, map: String) -> void:
    selected_character = character
    current_map = map
    current_wave = 0
    play_time = 0.0
    total_kills = 0
    gold = 0
    speed_multiplier = 1.0
    current_state = GameState.PLAYING
    EventBus.game_started.emit()
    get_tree().change_scene_to_file("res://scenes/main/game.tscn")

func continue_game(save_slot: int) -> void:
    var save_data = SaveManager.load_game(save_slot)
    if save_data.is_empty():
        return
    # 从存档恢复状态
    active_save_slot = save_slot
    selected_character = save_data.character
    current_map = save_data.map
    current_wave = save_data.wave
    play_time = save_data.play_time
    total_kills = save_data.kill_count
    gold = save_data.gold
    current_state = GameState.PLAYING
    get_tree().change_scene_to_file("res://scenes/main/game.tscn")
    # 等场景加载完成后恢复玩家状态
    await get_tree().process_frame
    EventBus.game_started.emit()

func toggle_pause() -> void:
    if current_state == GameState.PLAYING:
        current_state = GameState.PAUSED
        get_tree().paused = true
        EventBus.game_paused.emit(true)
    elif current_state == GameState.PAUSED:
        current_state = GameState.PLAYING
        get_tree().paused = false
        EventBus.game_paused.emit(false)

func set_speed(multiplier: float) -> void:
    speed_multiplier = clampf(multiplier, 1.0, 3.0)

func toggle_speed() -> void:
    match speed_multiplier:
        1.0: set_speed(2.0)
        2.0: set_speed(3.0)
        3.0: set_speed(1.0)

func add_gold(amount: int) -> void:
    gold += amount
    EventBus.gold_changed.emit(gold)

func add_kill() -> void:
    total_kills += 1

func game_over() -> void:
    current_state = GameState.GAME_OVER
    # 自动保存最高记录
    SaveManager.save_high_score({
        "character": selected_character,
        "map": current_map,
        "wave": current_wave,
        "kills": total_kills,
        "time": play_time
    })
    EventBus.game_over.emit({
        "wave": current_wave,
        "kills": total_kills,
        "time": play_time,
        "gold": gold
    })

func _process(delta: float) -> void:
    if current_state == GameState.PLAYING:
        play_time += delta * speed_multiplier
```

### 3.3 对象池（ObjectPool）— 性能核心

```gdscript
# scripts/autoload/object_pool.gd
extends Node

## 对象池：管理投射物、伤害数字、敌人等高频创建/销毁对象
## 目标：消除帧间 GC 压力，维持 60 FPS

var _pools: Dictionary = {}  # pool_name -> { scene: PackedScene, pool: Array[Node], active: int }
var _max_pool_sizes: Dictionary = {
    "projectiles": 500,
    "damage_numbers": 200,
    "exp_gems": 300,
    "gold_coins": 200,
    "particles": 100,
    "enemies": 250,  # 最大同屏敌人
}

func register_pool(pool_name: String, scene: PackedScene, max_size: int = 100) -> void:
    _pools[pool_name] = {
        "scene": scene,
        "pool": [],
        "active": 0,
        "max_size": max_size
    }

func get_object(pool_name: String, parent: Node) -> Node:
    if not _pools.has(pool_name):
        push_warning("Pool '%s' not registered" % pool_name)
        return null

    var pool_data = _pools[pool_name]

    # 尝试从池中获取
    for i in range(pool_data.pool.size() - 1, -1, -1):
        var obj = pool_data.pool[i]
        if not obj.visible and obj.get_parent() == null:
            pool_data.pool.remove_at(i)
            parent.add_child(obj)
            obj.visible = true
            pool_data.active += 1
            return obj

    # 池为空且未达上限，创建新对象
    if pool_data.active < pool_data.max_size:
        var obj = pool_data.scene.instantiate()
        parent.add_child(obj)
        pool_data.active += 1
        return obj

    # 达到上限，返回null（跳过本次创建）
    return null

func return_object(pool_name: String, obj: Node) -> void:
    if not _pools.has(pool_name):
        return

    var pool_data = _pools[pool_name]
    if obj.get_parent():
        obj.get_parent().remove_child(obj)
    obj.visible = false
    pool_data.active -= 1

    # 控制池大小，防止内存膨胀
    if pool_data.pool.size() < pool_data.max_size:
        pool_data.pool.append(obj)
    else:
        obj.queue_free()  # 池已满，直接释放

func return_all(pool_name: String) -> void:
    if not _pools.has(pool_name):
        return
    var pool_data = _pools[pool_name]
    for obj in pool_data.pool:
        if obj.get_parent():
            obj.get_parent().remove_child(obj)
        obj.visible = false
    pool_data.active = 0

func get_stats() -> Dictionary:
    var stats = {}
    for pool_name in _pools:
        var pool_data = _pools[pool_name]
        stats[pool_name] = {
            "active": pool_data.active,
            "pooled": pool_data.pool.size(),
            "max": pool_data.max_size
        }
    return stats
```

### 3.4 碰撞层设计

| 层 | 名称 | 用途 |
|----|------|------|
| 1 | Player | 玩家物理体 |
| 2 | Enemy | 敌人物理体 |
| 3 | PlayerProjectile | 玩家投射物 |
| 4 | EnemyProjectile | 敌人投射物 |
| 5 | Pickup | 拾取物 |
| 6 | Obstacle | 地图障碍物 |
| 7 | Hazard | 地图陷阱 |
| 8 | Hitbox | 攻击判定区 |
| 9 | Hurtbox | 受击判定区 |
| 10 | Summon | 召唤物 |

**碰撞矩阵配置：**

| 碰撞对 | 玩家 | 敌人 | 玩家弹 | 敌人弹 | 拾取 | 障碍 | 陷阱 | Hitbox | Hurtbox | 召唤 |
|--------|------|------|--------|--------|------|------|------|--------|---------|------|
| **玩家** | - | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **敌人** | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ |
| **玩家弹** | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **敌人弹** | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **拾取** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **障碍** | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **陷阱** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Hitbox** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Hurtbox** | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **召唤** | ❌ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ |

> **注：** 使用 Area2D 的 Hitbox/Hurtbox 模式处理战斗判定，CharacterBody2D 的物理碰撞处理移动阻挡。这种分离让战斗逻辑和移动逻辑解耦，便于调试和优化。

---

## 4. 法术系统实现

### 4.1 法术数据资源（Resource）

```gdscript
# scripts/spells/spell_data.gd
class_name SpellData
extends Resource

@export var id: String = ""
@export var spell_name: String = ""
@export var description: String = ""
@export var element: Element = Element.FIRE
@export var spell_type: SpellType = SpellType.PROJECTILE
@export var icon: Texture2D

# 数值属性
@export var base_damage: float = 10.0
@export var base_cooldown: float = 1.0
@export var base_mana_cost: float = 0.0
@export var max_level: int = 20

# 升级倍率
@export var damage_per_level: float = 0.08  # 每级+8%
@export var milestone_bonuses: Array[MilestoneData] = []

# 法术行为参数
@export var projectile_count: int = 1
@export var projectile_speed: float = 400.0
@export var aoe_radius: float = 0.0
@export var duration: float = 0.0
@export var pierce_count: int = 0
@export var chain_count: int = 0
@export var knockback_force: float = 0.0

enum Element {
    FIRE,       # 🔥 火焰
    WATER,      # 💧 水流
    LIGHTNING,  # ⚡ 雷电
    NATURE,     # 🌿 自然
    SHADOW,     # 🌑 暗影
    AIR         # 🌬️ 风暴
}

enum SpellType {
    PROJECTILE,   # 投射物（火球、水弹等）
   扇形,          # 扇形范围（烈焰波等）
    GROUND_AOE,   # 地面AoE（陨石、冰锥等）
    RING,         # 环形（寒冰新星等）
    BUFF,         # 增益（护盾、屏障等）
    SUMMON,       # 召唤（藤蔓守卫等）
    CHAIN,        # 连锁（连锁闪电等）
    MARK,         # 标记（火焰印记等）
    DASH,         # 冲刺（疾风步等）
}

func get_damage_at_level(level: int) -> float:
    var multiplier := 1.0 + (level - 1) * damage_per_level
    # 质变点加成
    match level:
        5: multiplier = 1.40
        10: multiplier = 2.20
        15: multiplier = 3.50
        20: multiplier = 5.50
    return base_damage * multiplier

func get_cooldown_at_level(level: int) -> float:
    if level >= 15:
        return base_cooldown * 0.75
    elif level >= 10:
        return base_cooldown * 0.85
    elif level >= 5:
        return base_cooldown * 0.92
    return base_cooldown
```

### 4.2 法术基类实现

```gdscript
# scripts/spells/base_spell.gd
class_name BaseSpell
extends Node2D

@export var spell_data: SpellData

var current_level: int = 1
var current_cooldown: float = 0.0
var is_ready: bool = true
var caster: Node2D = null

signal spell_fired
signal spell_ready

func _ready() -> void:
    current_cooldown = spell_data.base_cooldown

func _process(delta: float) -> void:
    if not is_ready:
        current_cooldown -= delta * GameManager.speed_multiplier
        if current_cooldown <= 0.0:
            is_ready = true
            spell_ready.emit()

func cast(target_pos: Vector2 = Vector2.ZERO) -> void:
    if not is_ready:
        return
    if not can_cast():
        return

    is_ready = false
    current_cooldown = spell_data.get_cooldown_at_level(current_level)
    _on_cast(target_pos)
    spell_fired.emit()
    EventBus.spell_cast.emit(spell_data, caster)

func can_cast() -> bool:
    # 检查法力值等条件
    return true

## 子类重写此方法实现具体施法逻辑
func _on_cast(target_pos: Vector2) -> void:
    pass

func upgrade() -> void:
    if current_level >= spell_data.max_level:
        return
    current_level += 1
    EventBus.spell_upgraded.emit(spell_data, current_level)
    _on_upgrade(current_level)

func _on_upgrade(new_level: int) -> void:
    pass

## 获取当前伤害值（含所有加成）
func get_current_damage() -> float:
    var base_dmg = spell_data.get_damage_at_level(current_level)
    # 叠加攻击力倍率、元素亲和、遗物加成等
    return base_dmg * _get_total_damage_multiplier()

func _get_total_damage_multiplier() -> float:
    var multiplier := 1.0
    # 攻击力倍率
    multiplier *= caster.get_stat("attack_multiplier")
    # 元素亲和
    multiplier *= caster.get_element_affinity_bonus(spell_data.element)
    # 遗物加成
    multiplier *= RelicSystem.get_damage_bonus(spell_data.element)
    # 被动技能加成
    multiplier *= PassiveSystem.get_damage_bonus()
    return multiplier
```

### 4.3 投射物法术实现

```gdscript
# scripts/spells/projectile_spell.gd
class_name ProjectileSpell
extends BaseSpell

@onready var projectile_scene: PackedScene = preload("res://scenes/spells/projectile.tscn")

func _on_cast(target_pos: Vector2) -> void:
    var direction := (target_pos - caster.global_position).normalized()

    for i in range(spell_data.projectile_count):
        var projectile = ObjectPool.get_object("projectiles", get_tree().current_scene)
        if projectile == null:
            return

        # 初始化投射物
        projectile.global_position = caster.global_position
        projectile.setup({
            "damage": get_current_damage(),
            "speed": spell_data.projectile_speed,
            "direction": direction,
            "element": spell_data.element,
            "pierce": spell_data.pierce_count,
            "chain": spell_data.chain_count,
            "knockback": spell_data.knockback_force,
            "level": current_level,
            "source": caster
        })

        # 多发射时添加散射角
        if spell_data.projectile_count > 1:
            var spread_angle = deg_to_rad(15.0)
            var angle_offset = (i - spell_data.projectile_count / 2.0) * spread_angle
            projectile.direction = direction.rotated(angle_offset)

        # Lv.10 多连发效果
        if current_level >= 10:
            _spawn_additional_projectile(direction, i)
```

### 4.4 融合系统

```gdscript
# scripts/spells/fusion_system.gd
class_name FusionSystem
extends Node

## 元素融合配方表
const FUSION_RECIPES: Dictionary = {
    # 🔥+💧 = 蒸汽爆炸
    ["FIRE", "WATER"]: {
        "id": "fusion_steam_blast",
        "name": "蒸汽爆炸",
        "description": "高温蒸汽，持续伤害+降低视野",
        "required_spells": ["F1", "W1"],
        "effect_scene": "res://scenes/spells/fusions/steam_blast.tscn"
    },
    # 🔥+⚡ = 雷火交加
    ["FIRE", "LIGHTNING"]: {
        "id": "fusion_thunderfire",
        "name": "雷火交加",
        "description": "雷火弹，连锁电火花",
        "required_spells": ["F1", "L1"],
        "effect_scene": "res://scenes/spells/fusions/thunderfire.tscn"
    },
    # 💧+⚡ = 冰雷爆裂
    ["WATER", "LIGHTNING"]: {
        "id": "fusion_frost_shock",
        "name": "冰雷爆裂",
        "description": "冻结+连锁麻痹",
        "required_spells": ["W1", "L1"],
        "effect_scene": "res://scenes/spells/fusions/frost_shock.tscn"
    },
    # ... 其余12种融合配方
}

var unlocked_fusions: Array[String] = []
var active_fusion: Node2D = null

## 检查是否满足融合条件
func check_fusion_availability(spell_slots: Array[BaseSpell]) -> Array[Dictionary]:
    var available: Array[Dictionary] = []
    var equipped_elements: Array[String] = []

    for spell in spell_slots:
        if spell:
            equipped_elements.append(spell.spell_data.element.keys()[spell.spell_data.element])

    for recipe_key in FUSION_RECIPES:
        if recipe_key[0] in equipped_elements and recipe_key[1] in equipped_elements:
            var recipe = FUSION_RECIPES[recipe_key]
            if recipe.id not in unlocked_fusions:
                available.append(recipe)

    return available

## 激活融合法术
func activate_fusion(fusion_id: String) -> void:
    var recipe = _get_recipe_by_id(fusion_id)
    if recipe == null:
        return

    var fusion_scene = load(recipe.effect_scene)
    active_fusion = fusion_scene.instantiate()
    active_fusion.position = Vector2.ZERO
    # 添加到玩家节点下
    caster.add_child(active_fusion)
    unlocked_fusions.append(fusion_id)
    EventBus.spell_fusion_unlocked.emit(fusion_id)
```

---

## 5. 敌人AI与波次系统

### 5.1 敌人基类

```gdscript
# scripts/enemies/base_enemy.gd
class_name BaseEnemy
extends CharacterBody2D

@export var enemy_data: EnemyData

var current_hp: float
var max_hp: float
var damage_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var current_wave: int = 1
var is_alive: bool = true
var target: Node2D = null

# AI状态
enum AIState { IDLE, CHASE, ATTACK, FLEE, STUNNED }
var current_state: AIState = AIState.IDLE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var hitbox: Area2D = $HitboxComponent
@onready var hurtbox: Area2D = $HurtboxComponent
@onready var ai_sensor: Area2D = $AISensor
@onready var status_effects: Node = $StatusEffects

func _ready() -> void:
    max_hp = enemy_data.base_hp * (1.0 + current_wave * 0.10)
    current_hp = max_hp
    health_bar.max_value = max_hp
    health_bar.value = max_hp

    # 连接信号
    hurtbox.area_entered.connect(_on_hurtbox_entered)

func _physics_process(delta: float) -> void:
    if not is_alive:
        return

    # 更新AI
    _update_ai(delta)

    # 应用状态效果
    _apply_status_effects(delta)

    # 移动
    move_and_slide()

func _update_ai(delta: float) -> void:
    match current_state:
        AIState.IDLE:
            _state_idle(delta)
        AIState.CHASE:
            _state_chase(delta)
        AIState.ATTACK:
            _state_attack(delta)

func _state_chase(delta: float) -> void:
    if target == null or not is_instance_valid(target):
        _find_target()
        return

    var direction = (target.global_position - global_position).normalized()
    velocity = direction * enemy_data.base_speed * speed_multiplier * GameManager.speed_multiplier

    # 面向目标
    if velocity.x < 0:
        sprite.flip_h = true
    elif velocity.x > 0:
        sprite.flip_h = false

func _state_attack(delta: float) -> void:
    velocity = Vector2.ZERO
    # 实现具体攻击逻辑（子类重写）
    pass

func _find_target() -> void:
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        target = players[0]
        current_state = AIState.CHASE

func take_damage(amount: float, damage_type: DamageType = DamageType.PHYSICAL, source: Node2D = null) -> void:
    if not is_alive:
        return

    # 诅咒加成
    if status_effects.has_effect("curse"):
        amount *= 1.15

    current_hp -= amount
    health_bar.value = current_hp

    # 伤害数字
    EventBus.show_damage_number.emit(global_position + Vector2(0, -30), amount, damage_type)

    # 闪烁效果
    _flash_damage()

    if current_hp <= 0:
        _die()

func _die() -> void:
    is_alive = false
    EventBus.enemy_killed.emit(self, enemy_data.exp_reward)

    # 掉落物
    _drop_loot()

    # 死亡动画
    sprite.play("death")
    await sprite.animation_finished

    # 归还对象池
    ObjectPool.return_object("enemies", self)
    current_state = AIState.IDLE

func _drop_loot() -> void:
    # 经验宝石
    var exp_gem = ObjectPool.get_object("exp_gems", get_tree().current_scene)
    if exp_gem:
        exp_gem.global_position = global_position
        exp_gem.exp_value = enemy_data.exp_reward

    # 金币（随机）
    if randf() < 0.3:
        var gold = ObjectPool.get_object("gold_coins", get_tree().current_scene)
        if gold:
            gold.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
            gold.value = randi_range(1, 3)
```

### 5.2 波次管理器

```gdscript
# scripts/autoload/wave_manager.gd
extends Node

## 无限波次模式管理器

var current_wave: int = 0
var wave_timer: float = 0.0
var wave_duration: float = 30.0
var enemies_alive: int = 0
var enemies_spawned: int = 0
var enemies_to_spawn: int = 0
var is_wave_active: bool = false
var spawn_interval: float = 1.0
var spawn_timer: float = 0.0

# 波次配置缓存
var wave_config: Dictionary = {}

func _ready() -> void:
    EventBus.enemy_killed.connect(_on_enemy_killed)
    EventBus.game_started.connect(_on_game_started)

func _on_game_started() -> void:
    start_next_wave()

func _process(delta: float) -> void:
    if not is_wave_active:
        return

    var dt = delta * GameManager.speed_multiplier

    # 波次计时
    wave_timer -= dt
    spawn_timer -= dt

    # 持续生成敌人
    if spawn_timer <= 0 and enemies_spawned < enemies_to_spawn:
        _spawn_enemy()
        spawn_timer = spawn_interval

    # 波次完成判定
    if enemies_spawned >= enemies_to_spawn and enemies_alive <= 0:
        _on_wave_complete()

func start_next_wave() -> void:
    current_wave += 1
    is_wave_active = true
    wave_timer = _get_wave_duration()
    enemies_spawned = 0
    enemies_alive = 0
    enemies_to_spawn = _calculate_enemy_count()
    spawn_interval = _calculate_spawn_interval()

    EventBus.wave_started.emit(current_wave)

    # Boss 波次检查
    if current_wave % 20 == 0:
        _spawn_boss("major")
    elif current_wave % 5 == 0:
        _spawn_boss("minor")

func _calculate_enemy_count() -> int:
    # 无限模式：数量随波次递增
    var base_count := 10
    var scaling := current_wave * 0.5
    return int(base_count + scaling)

func _calculate_spawn_interval() -> float:
    # 后期波次生成更快
    var interval := 1.5 - (current_wave * 0.01)
    return maxf(interval, 0.3)

func _get_wave_duration() -> float:
    # 波次持续时间随波次增加
    var duration := 30.0 + (current_wave * 0.5)
    return minf(duration, 90.0)

func _spawn_enemy() -> void:
    var enemy_type = _select_enemy_type()
    var spawn_pos = _get_spawn_position()

    var enemy = ObjectPool.get_object("enemies", get_tree().current_scene)
    if enemy == null:
        return

    enemy.current_wave = current_wave
    enemy.global_position = spawn_pos
    enemy.setup(enemy_type)

    enemies_spawned += 1
    enemies_alive += 1

func _select_enemy_type() -> String:
    # 根据波次选择敌人类型
    var available_types: Array[String] = []

    if current_wave >= 1:
        available_types.append_array(["shadow_servant", "swarm"])
    if current_wave >= 3:
        available_types.append("skeleton_mage")
    if current_wave >= 5:
        available_types.append_array(["skeleton_warrior", "bat_swarm", "exploder"])
    if current_wave >= 8:
        available_types.append("shadow_knight")
    if current_wave >= 10:
        available_types.append_array(["stone_gargoyle", "healer"])
    if current_wave >= 12:
        available_types.append("lightning_spirit")
    if current_wave >= 15:
        available_types.append("shadow_assassin")
    if current_wave >= 20:
        available_types.append("elemental_lord")

    return available_types[randi() % available_types.size()]

func _get_spawn_position() -> Vector2:
    # 在屏幕边缘外随机生成
    var camera = get_viewport().get_camera_2d()
    if camera == null:
        return Vector2.ZERO

    var center = camera.global_position
    var margin = 100.0
    var viewport_size = get_viewport().get_visible_rect().size

    var side = randi() % 4
    var pos: Vector2
    match side:
        0: pos = center + Vector2(randf_range(-viewport_size.x/2, viewport_size.x/2), -viewport_size.y/2 - margin)  # 上
        1: pos = center + Vector2(randf_range(-viewport_size.x/2, viewport_size.x/2), viewport_size.y/2 + margin)   # 下
        2: pos = center + Vector2(-viewport_size.x/2 - margin, randf_range(-viewport_size.y/2, viewport_size.y/2))  # 左
        3: pos = center + Vector2(viewport_size.x/2 + margin, randf_range(-viewport_size.y/2, viewport_size.y/2))   # 右
    return pos

func _on_enemy_killed(enemy: BaseEnemy, _exp_reward: int) -> void:
    enemies_alive -= 1
    GameManager.add_kill()

func _on_wave_complete() -> void:
    is_wave_active = false
    EventBus.wave_completed.emit(current_wave)

    # 每10波里程碑奖励
    if current_wave % 10 == 0:
        _trigger_milestone_reward()

    # 自动存档
    SaveManager.auto_save()

    # 短暂延迟后开始下一波
    await get_tree().create_timer(2.0).timeout
    start_next_wave()

func _spawn_boss(type: String) -> void:
    var boss_scene = preload("res://scenes/enemies/boss.tscn")
    var boss = boss_scene.instantiate()
    boss.setup(type, current_wave)
    boss.global_position = _get_spawn_position()
    get_tree().current_scene.get_node("Entities/Enemies").add_child(boss)
    EventBus.boss_spawned.emit(type)
```

---

## 6. Roguelite升级系统

### 6.1 经验值系统

```gdscript
# scripts/systems/experience_system.gd
class_name ExperienceSystem
extends Node

signal level_up(new_level: int)
signal exp_changed(current: int, required: int)

var current_level: int = 1
var current_exp: int = 0
var required_exp: int = 56  # Lv.1→2 所需经验

# 升级需求表
const EXP_TABLE: Array[int] = [
    0, 56, 118, 186, 260, 340, 426, 518, 616, 720,
    830, 946, 1068, 1196, 1330, 1470, 1616, 1768, 1926, 2090
]

func add_exp(amount: int) -> void:
    current_exp += amount
    exp_changed.emit(current_exp, required_exp)

    while current_exp >= required_exp and current_level < 20:
        current_exp -= required_exp
        current_level += 1
        required_exp = EXP_TABLE[current_level] if current_level < EXP_TABLE.size() else 9999
        level_up.emit(current_level)
        EventBus.player_level_up.emit(current_level)
        _show_upgrade_options()

func _show_upgrade_options() -> void:
    var options = UpgradeSystem.generate_options(3)
    EventBus.upgrade_options_ready.emit(options)
    # 暂停游戏，显示升级面板
    GameManager.current_state = GameManager.GameState.UPGRADE
    get_tree().paused = true
```

### 6.2 升级选项生成

```gdscript
# scripts/systems/upgrade_system.gd
class_name UpgradeSystem
extends RefCounted

## 升级选项权重配置
const OPTION_WEIGHTS = {
    "new_spell": 40,      # 新法术
    "spell_upgrade": 35,  # 法术升级
    "passive": 15,        # 被动技能
    "element_affinity": 10 # 元素亲和
}

static func generate_options(count: int) -> Array[UpgradeOption]:
    var options: Array[UpgradeOption] = []
    var player = get_tree().get_first_node_in_group("player")
    var spell_slots = player.spell_caster.get_all_spells()

    for i in range(count):
        var option_type = _weighted_random(OPTION_WEIGHTS)
        var option: UpgradeOption

        match option_type:
            "new_spell":
                option = _generate_new_spell_option(spell_slots)
            "spell_upgrade":
                option = _generate_spell_upgrade_option(spell_slots)
            "passive":
                option = _generate_passive_option()
            "element_affinity":
                option = _generate_affinity_option()

        if option != null:
            options.append(option)

    return options

static func _generate_new_spell_option(spells: Array) -> UpgradeOption:
    var all_spells = SpellManager.get_all_spells()
    var owned_ids = spells.filter(func(s): return s != null).map(func(s): return s.spell_data.id)
    var available = all_spells.filter(func(s): return s.id not in owned_ids)

    if available.is_empty():
        return null

    var chosen = available[randi() % available.size()]
    var option = UpgradeOption.new()
    option.type = "new_spell"
    option.spell_data = chosen
    option.display_name = "获得法术: %s" % chosen.spell_name
    option.description = chosen.description
    option.icon = chosen.icon
    return option

static func _generate_spell_upgrade_option(spells: Array) -> UpgradeOption:
    var upgradeable = spells.filter(func(s): return s != null and s.current_level < s.spell_data.max_level)
    if upgradeable.is_empty():
        return null

    var chosen = upgradeable[randi() % upgradeable.size()]
    var option = UpgradeOption.new()
    option.type = "spell_upgrade"
    option.target_spell = chosen
    option.new_level = chosen.current_level + 1
    option.display_name = "%s Lv.%d → Lv.%d" % [chosen.spell_data.spell_name, chosen.current_level, chosen.new_level]
    option.description = _get_level_up_description(chosen)
    option.icon = chosen.spell_data.icon
    return option

# ... 其他选项生成方法
```

---

## 7. 地图系统实现

### 7.1 地图生成器

```gdscript
# scripts/map/map_generator.gd
class_name MapGenerator
extends Node

## 地图使用 Godot 4.x 的 TileMapLayer 节点
## 每张地图为预设的 TileSet + 预制布局
## 非程序化生成（保证每张地图体验一致）

@export var map_config: MapConfig

# 地图图层
@onready var ground_layer: TileMapLayer = $"../Ground"
@onready var obstacle_layer: TileMapLayer = $"../Obstacles"
@onready var hazard_layer: TileMapLayer = $"../Hazards"

func generate_map(map_id: String) -> void:
    map_config = load("res://assets/data/maps/%s_config.tres" % map_id)

    # 1. 渲染地面
    _render_ground()

    # 2. 放置障碍物
    _place_obstacles()

    # 3. 放置陷阱
    _place_hazards()

    # 4. 放置互动元素
    _place_interactables()

    # 5. 配置地图特殊机制
    _setup_map_mechanics()

func _setup_map_mechanics() -> void:
    match map_config.map_id:
        "forest":
            _setup_vine_traps()
            _setup_poison_mist()
        "lava":
            _setup_lava_rivers()
            _setup_geysers()
        "ice":
            _setup_ice_surfing()
            _setup_blizzard()
        "shadow_realm":
            _setup_vision_limit()
            _setup_teleporters()
        "altar":
            _setup_element_zones()
            _setup_elemental_storm()
```

### 7.2 地图配置资源

```gdscript
# scripts/map/map_config.gd
class_name MapConfig
extends Resource

@export var map_id: String = ""
@export var map_name: String = ""
@export var tileset: TileSet
@export var map_size: Vector2i = Vector2i(100, 100)  # 瓦片数
@export var tile_size: int = 64

# 特殊机制
@export var has_vine_traps: bool = false
@export var has_poison_mist: bool = false
@export var has_lava_damage: bool = false
@export var has_ice_physics: bool = false
@export var has_vision_limit: bool = false
@export var has_teleporters: bool = false

# 环境效果
@export var ambient_color: Color = Color.WHITE
@export var fog_density: float = 0.0
@export var music_track: String = ""
```

---

## 8. UI/UX系统

### 8.1 HUD系统

```gdscript
# scripts/ui/hud.gd
class_name HUD
extends CanvasLayer

@onready var health_bar: ProgressBar = $HUDContainer/HealthBar
@onready var mana_bar: ProgressBar = $HUDContainer/ManaBar
@onready var exp_bar: ProgressBar = $HUDContainer/ExpBar
@onready var wave_label: Label = $HUDContainer/WaveLabel
@onready var kill_label: Label = $HUDContainer/KillLabel
@onready var gold_label: Label = $HUDContainer/GoldLabel
@onready var speed_label: Label = $HUDContainer/SpeedLabel
@onready var time_label: Label = $HUDContainer/TimeLabel
@onready var spell_slots: HBoxContainer = $HUDContainer/SpellSlots
@onready var minimap: Control = $HUDContainer/MiniMap

func _ready() -> void:
    EventBus.player_damaged.connect(_on_player_damaged)
    EventBus.player_healed.connect(_on_player_healed)
    EventBus.wave_started.connect(_on_wave_started)
    EventBus.exp_changed.connect(_on_exp_changed)
    EventBus.gold_changed.connect(_on_gold_changed)
    EventBus.enemy_killed.connect(_on_enemy_killed)

func _process(_delta: float) -> void:
    # 更新时间显示
    var time = GameManager.play_time
    var minutes = int(time) / 60
    var seconds = int(time) % 60
    time_label.text = "%02d:%02d" % [minutes, seconds]

func _on_player_damaged(amount: float, _source: Node2D) -> void:
    var player = get_tree().get_first_node_in_group("player")
    if player:
        health_bar.max_value = player.stats.max_hp
        health_bar.value = player.stats.current_hp
        _shake_bar(health_bar)

func _on_wave_started(wave_number: int) -> void:
    wave_label.text = "Wave %d" % wave_number
    _animate_wave_text()

func _on_exp_changed(current: int, required: int) -> void:
    exp_bar.max_value = required
    exp_bar.value = current

func _shake_bar(bar: ProgressBar) -> void:
    var tween = create_tween()
    tween.tween_property(bar, "modulate", Color.RED, 0.05)
    tween.tween_property(bar, "modulate", Color.WHITE, 0.1)
```

### 8.2 升级选择面板

```gdscript
# scripts/ui/upgrade_ui.gd
class_name UpgradeUI
extends Control

@onready var card_container: HBoxContainer = $Panel/MarginContainer/CardContainer
@onready var title_label: Label = $Panel/TitleLabel

var card_scene: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")

func show_options(options: Array[UpgradeOption]) -> void:
    visible = true

    # 清空旧卡片
    for child in card_container.get_children():
        child.queue_free()

    # 生成新卡片
    for option in options:
        var card = card_scene.instantiate()
        card.setup(option)
        card.card_selected.connect(_on_card_selected)
        card_container.add_child(card)

    # 入场动画
    _play_entrance_animation()

func _on_card_selected(option: UpgradeOption) -> void:
    match option.type:
        "new_spell":
            EventBus.spell_cast.emit(option.spell_data, null)
        "spell_upgrade":
            option.target_spell.upgrade()
        "passive":
            PassiveSystem.acquire_passive(option.passive_data)
        "element_affinity":
            PlayerStats.add_element_affinity(option.element)

    # 关闭面板，恢复游戏
    visible = false
    get_tree().paused = false
    GameManager.current_state = GameManager.GameState.PLAYING

func _play_entrance_animation() -> void:
    var cards = card_container.get_children()
    for i in range(cards.size()):
        var card = cards[i]
        card.modulate.a = 0.0
        card.scale = Vector2(0.8, 0.8)
        var tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(i * 0.1)
        tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3).set_delay(i * 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
```

### 8.3 伤害数字系统

```gdscript
# scripts/ui/damage_number.gd
class_name DamageNumber
extends Node2D

@onready var label: Label = $Label
@onready var animation: AnimationPlayer = $AnimationPlayer

enum DamageType { NORMAL, CRITICAL, HEAL }

func setup(amount: float, type: DamageType = DamageType.NORMAL) -> void:
    match type:
        DamageType.NORMAL:
            label.text = str(int(amount))
            label.modulate = Color.WHITE
            label.add_theme_font_size_override("font_size", 20)
        DamageType.CRITICAL:
            label.text = str(int(amount)) + "!"
            label.modulate = Color.RED
            label.add_theme_font_size_override("font_size", 28)
        DamageType.HEAL:
            label.text = "+" + str(int(amount))
            label.add_theme_font_size_override("font_size", 20)

    # 随机偏移，避免重叠
    position.x += randf_range(-15, 15)

    animation.play("float_up")
    await animation.animation_finished
    ObjectPool.return_object("damage_numbers", self)
```

---

## 9. 存档系统

### 9.1 存档管理器

```gdscript
# scripts/autoload/save_manager.gd
extends Node

const SAVE_DIR = "user://saves/"
const HIGH_SCORE_FILE = "user://high_scores.json"
const MAX_SAVE_SLOTS = 3

func _ready() -> void:
    # 确保存档目录存在
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int, data: Dictionary) -> bool:
    var file_path = SAVE_DIR + "save_%d.json" % slot

    # 添加元数据
    data.version = "1.0"
    data.slot = slot
    data.timestamp = Time.get_datetime_string_from_system()
    data.checksum = _calculate_checksum(data)

    # 加密存档
    var json_string = JSON.stringify(data)
    var encrypted = _encrypt_data(json_string)

    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file == null:
        push_error("Failed to save game: %s" % file_path)
        return false

    file.store_string(encrypted)
    file.close()

    print("Game saved to slot %d" % slot)
    return true

func load_game(slot: int) -> Dictionary:
    var file_path = SAVE_DIR + "save_%d.json" % slot

    if not FileAccess.file_exists(file_path):
        return {}

    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        return {}

    var encrypted = file.get_as_text()
    file.close()

    var json_string = _decrypt_data(encrypted)
    var json = JSON.new()
    var error = json.parse(json_string)

    if error != OK:
        push_error("Failed to parse save data")
        return {}

    var data = json.data

    # 校验完整性
    if not _verify_checksum(data):
        push_error("Save data corrupted")
        return {}

    return data

func delete_save(slot: int) -> bool:
    var file_path = SAVE_DIR + "save_%d.json" % slot
    if FileAccess.file_exists(file_path):
        DirAccess.remove_absolute(file_path)
        return true
    return false

func get_save_info(slot: int) -> Dictionary:
    var data = load_game(slot)
    if data.is_empty():
        return {"empty": true}
    return {
        "empty": false,
        "character": data.get("character", ""),
        "map": data.get("map", ""),
        "wave": data.get("wave", 0),
        "play_time": data.get("play_time", 0),
        "timestamp": data.get("timestamp", "")
    }

func get_all_save_info() -> Array[Dictionary]:
    var saves: Array[Dictionary] = []
    for i in range(1, MAX_SAVE_SLOTS + 1):
        saves.append(get_save_info(i))
    return saves

func auto_save() -> void:
    var current_slot = GameManager.active_save_slot
    if current_slot < 1:
        current_slot = 1  # 默认存到槽位1

    var player = get_tree().get_first_node_in_group("player")
    if player == null:
        return

    var data = {
        "character": GameManager.selected_character,
        "map": GameManager.current_map,
        "wave": GameManager.current_wave,
        "hp": player.stats.current_hp,
        "max_hp": player.stats.max_hp,
        "mp": player.stats.current_mp,
        "max_mp": player.stats.max_mp,
        "level": player.stats.current_level,
        "exp": player.stats.current_exp,
        "gold": GameManager.gold,
        "spells": player.spell_caster.serialize(),
        "relics": RelicSystem.serialize(),
        "passives": PassiveSystem.serialize(),
        "element_affinity": player.stats.element_affinity,
        "play_time": GameManager.play_time,
        "kill_count": GameManager.total_kills
    }

    save_game(current_slot, data)

func save_high_score(data: Dictionary) -> void:
    var scores = _load_high_scores()
    scores.append(data)

    # 按波次排序，保留前10名
    scores.sort_custom(func(a, b): return a.wave > b.wave)
    scores = scores.slice(0, 10)

    var json_string = JSON.stringify(scores)
    var file = FileAccess.open(HIGH_SCORE_FILE, FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()

func _load_high_scores() -> Array:
    if not FileAccess.file_exists(HIGH_SCORE_FILE):
        return []

    var file = FileAccess.open(HIGH_SCORE_FILE, FileAccess.READ)
    if file == null:
        return []

    var json_string = file.get_as_text()
    file.close()

    var json = JSON.new()
    var error = json.parse(json_string)
    if error != OK:
        return []

    return json.data if json.data is Array else []

func _encrypt_data(data: String) -> String:
    # 简单的Base64编码（实际项目建议用AES-128）
    return Marshalls.utf8_to_base64(data)

func _decrypt_data(data: String) -> String:
    return Marshalls.base64_to_utf8(data)

func _calculate_checksum(data: Dictionary) -> String:
    var temp = data.duplicate()
    temp.erase("checksum")
    return Hash.hash_text_to_hex(JSON.stringify(temp))

func _verify_checksum(data: Dictionary) -> bool:
    var stored = data.get("checksum", "")
    var calculated = _calculate_checksum(data)
    return stored == calculated
```

---

## 10. 性能优化策略

### 10.1 性能目标与瓶颈分析

| 指标 | 目标 | 关键瓶颈 |
|------|------|----------|
| **帧率** | 60 FPS (GTX 960) | 大量敌人的AI和碰撞检测 |
| **同屏敌人** | 最大200个 | 渲染批处理、物理碰撞 |
| **投射物** | 最大500个 | 对象池、碰撞检测 |
| **加载时间** | < 3秒 | 场景预加载、资源异步加载 |

### 10.2 渲染优化

#### MultiMesh 批处理渲染

```gdscript
# 用于大量相同类型敌人的批处理渲染
# 替代方案：每个敌人单独的 Sprite2D → MultiMeshInstance2D 批量渲染

class_name BatchEnemyRenderer
extends MultiMeshInstance2D

var enemy_instances: Array[BaseEnemy] = []
var transform_updates_needed: bool = false

func _ready() -> void:
    multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_2D
    multimesh.instance_count = 200  # 预分配
    multimesh.visible_instance_count = 0

func register_enemy(enemy: BaseEnemy) -> int:
    var index = enemy_instances.size()
    enemy_instances.append(enemy)
    multimesh.visible_instance_count = enemy_instances.size()
    return index

func _process(_delta: float) -> void:
    # 批量更新所有敌人位置
    for i in range(enemy_instances.size()):
        if is_instance_valid(enemy_instances[i]):
            var transform = Transform2D(0, enemy_instances[i].global_position)
            multimesh.set_instance_transform_2d(i, transform)
```

#### 视锥裁剪（Frustum Culling）

```gdscript
# 只处理屏幕内或屏幕附近的实体
class_name ViewportCuller
extends Node

var screen_rect: Rect2
var margin: float = 200.0  # 屏幕外额外边距

func _ready() -> void:
    var viewport = get_viewport()
    viewport.size_changed.connect(_on_viewport_size_changed)
    _on_viewport_size_changed()

func _on_viewport_size_changed() -> void:
    var viewport_size = get_viewport().get_visible_rect().size
    var camera = get_viewport().get_camera_2d()
    if camera:
        var cam_pos = camera.global_position
        screen_rect = Rect2(
            cam_pos - viewport_size / 2 - Vector2(margin, margin),
            viewport_size + Vector2(margin * 2, margin * 2)
        )

func is_on_screen(pos: Vector2) -> bool:
    return screen_rect.has_point(pos)
```

### 10.3 物理碰撞优化

```gdscript
# 使用空间查询代替全量碰撞检测
# 对于大范围AoE法术，使用 Area2D 的直接检测而非逐个碰撞

class_name SpatialQueryOptimizer
extends Node

## 用 PhysicsServer2D 直接查询空间，避免遍历所有节点
static func query_area(center: Vector2, radius: float, mask: int) -> Array[Node2D]:
    var space_state = PhysicsServer2D.space_get_direct_state(
        get_viewport().get_world_2d().space
    )

    var shape = CircleShape2D.new()
    shape.radius = radius

    var params = PhysicsShapeQueryParameters2D.new()
    params.shape = shape
    params.transform = Transform2D(0, center)
    params.collision_mask = mask

    var results = space_state.intersect_shape(params, 50)

    var nodes: Array[Node2D] = []
    for result in results:
        if result.collider is Node2D:
            nodes.append(result.collider)
    return nodes
```

### 10.4 内存管理

```gdscript
# 在每波结束时进行内存清理
class_name MemoryOptimizer
extends Node

func cleanup_after_wave() -> void:
    # 1. 归还所有对象池
    ObjectPool.return_all("projectiles")
    ObjectPool.return_all("damage_numbers")

    # 2. 清理无效引用
    var enemies = get_tree().get_nodes_in_group("enemy")
    for enemy in enemies:
        if not is_instance_valid(enemy):
            enemies.erase(enemy)

    # 3. 强制GC（Godot 4.x 自动GC，但可提示）
    if OS.get_static_memory_usage() > 500 * 1024 * 1024:  # > 500MB
        print("Warning: High memory usage - %d bytes" % OS.get_static_memory_usage())
```

### 10.5 性能预算表

| 系统 | CPU 预算 | GPU 预算 | 内存 |
|------|----------|----------|------|
| **敌人AI** | 2ms/帧 | - | 20MB |
| **物理碰撞** | 3ms/帧 | - | 10MB |
| **法术系统** | 2ms/帧 | - | 5MB |
| **渲染** | 1ms/帧 | 8ms/帧 | 100MB |
| **UI** | 1ms/帧 | 2ms/帧 | 20MB |
| **音频** | 0.5ms/帧 | - | 50MB |
| **系统/其他** | 0.5ms/帧 | - | 10MB |
| **总计** | **10ms/帧** | **10ms/帧** | **215MB** |

> 10ms CPU + 10ms GPU = 20ms/帧 ≈ 50 FPS（保守估计），实际目标60 FPS需要在核心循环中保持高效。

---

## 11. 资产管线与工作流

### 11.1 美术资产规范

| 资产类型 | 格式 | 尺寸 | 说明 |
|----------|------|------|------|
| **角色精灵** | PNG (RGBA) | 256×256 | 每帧，骨骼动画 |
| **敌人精灵** | PNG (RGBA) | 128×128 | 普通敌人 |
| **Boss精灵** | PNG (RGBA) | 512×512 | Boss专用 |
| **法术特效** | PNG 序列帧 | 128×128 | 30fps播放 |
| **瓦片集** | PNG | 64×64 | TileSet |
| **UI图标** | PNG (RGBA) | 64×64 | 法术/遗物图标 |
| **UI背景** | PNG | 1920×1080 | 菜单背景 |
| **字体** | TTF/OTF | - | 主字体+数字字体 |

### 11.2 音频资产规范

| 资产类型 | 格式 | 采样率 | 说明 |
|----------|------|--------|------|
| **BGM** | OGG Vorbis | 44.1kHz | 压缩，循环 |
| **SFX** | WAV | 44.1kHz | 未压缩，低延迟 |
| **语音** | OGG Vorbis | 22kHz | 压缩 |

### 11.3 数据驱动设计

所有数值通过 JSON/TRES 资源文件配置，不硬编码在脚本中：

```
assets/data/
├── spells/              # 每个法术一个 .tres
│   ├── fireball.tres
│   ├── flame_wave.tres
│   └── ...
├── enemies/             # 每个敌人一个 .tres
│   ├── shadow_servant.tres
│   └── ...
├── relics/              # 每个遗物一个 .tres
├── passives/            # 每个被动一个 .tres
├── waves.json           # 波次配置
├── maps.json            # 地图配置
└── balance.json         # 全局平衡性数值
```

### 11.4 开发迭代流程

```
1. 编辑数据文件（.json/.tres）
       ↓
2. Godot 编辑器热重载（自动检测文件变更）
       ↓
3. 场景中测试效果
       ↓
4. 调整数值
       ↓
5. 重复 1-4
```

---

## 12. 调试与测试工具

### 12.1 内置调试面板

```gdscript
# scripts/utils/debug_tools.gd
extends Node

var show_debug_panel: bool = false
var debug_font: FontFile

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("debug_toggle"):  # F3
        show_debug_panel = not show_debug_panel

func _draw() -> void:
    if not show_debug_panel:
        return

    # FPS 显示
    draw_string(debug_font, Vector2(10, 20), "FPS: %d" % Engine.get_frames_per_second(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GREEN)

    # 对象池统计
    var pool_stats = ObjectPool.get_stats()
    var y = 40
    for pool_name in pool_stats:
        var stats = pool_stats[pool_name]
        draw_string(debug_font, Vector2(10, y), "%s: %d/%d" % [pool_name, stats.active, stats.max], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)
        y += 20

    # 内存使用
    draw_string(debug_font, Vector2(10, y + 10), "Memory: %d MB" % (OS.get_static_memory_usage() / 1024 / 1024), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.CYAN)
```

### 12.2 调试快捷键

| 按键 | 功能 |
|------|------|
| F3 | 切换调试面板 |
| F4 | 无敌模式 |
| F5 | 跳过当前波次 |
| F6 | 满级（所有法术Lv.20） |
| F7 | 显示碰撞框 |
| F8 | 快速生成Boss |
| F9 | 截图 |

### 12.3 单元测试框架

```gdscript
# tests/unit/test_damage_calculator.gd
extends GutTest

var calculator: DamageCalculator

func before_each():
    calculator = DamageCalculator.new()

func test_basic_damage():
    var result = calculator.calculate(
        100,   # 基础伤害
        2.2,   # 法术等级倍率
        1.38,  # 攻击力倍率
        1.10,  # 元素亲和
        1.50,  # 暴击倍率
        1.08,  # 遗物加成
        1.0    # 契约惩罚
    )
    assert_eq_approx(result, 415.6, 0.1)

func test_no_critical():
    var result = calculator.calculate(100, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    assert_eq_approx(result, 100.0, 0.1)

func test_curse_bonus():
    var result = calculator.apply_curse(100, 1.15)
    assert_eq_approx(result, 115.0, 0.1)
```

---

## 附录：Godot 4.x 关键特性使用指南

### A. 节点类型选择指南

| 需求 | 推荐节点 | 原因 |
|------|----------|------|
| 玩家/敌人移动 | CharacterBody2D | 手动控制移动，内置碰撞处理 |
| 投射物 | Area2D | 只需检测碰撞，不需要物理模拟 |
| 拾取物 | Area2D + 引力吸引 | 检测拾取范围 |
| 地图 | TileMapLayer | 瓦片地图，高效渲染 |
| UI | Control | Godot原生UI系统 |
| 粒子效果 | GPUParticles2D | GPU加速粒子 |
| 摄像机 | Camera2D | 跟随、震屏 |

### B. 信号最佳实践

1. **使用 EventBus** 进行跨系统通信，避免直接引用
2. **使用组（Group）** 进行批量操作（如"所有敌人"）
3. **避免循环信号**：A→B→C→A 会导致无限循环
4. **信号连接在 `_ready()` 中**，断开在 `_exit_tree()` 中

### C. 资源加载策略

| 场景 | 策略 | 示例 |
|------|------|------|
| 主菜单 | 预加载 | `preload()` |
| 游戏场景 | 异步加载 | `ResourceLoader.load_threaded_request()` |
| 法术特效 | 对象池 | 运行时从池中获取 |
| 地图瓦片 | 按需加载 | `TileMapLayer` 自动管理 |

---

*文档生成：MiMo-v2.5 (godot-expert)*  
*项目代号：Grimoire-Echoes*  
*文档状态：技术实现方案 v1.0*
