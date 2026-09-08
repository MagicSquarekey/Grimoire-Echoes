# 🔮 秘法回响（Grimoire Echoes）— 技术架构设计文档

> **版本：** v1.0  
> **创建日期：** 2026-08-27  
> **文档状态：** 技术架构设计完成  
> **项目代号：** Grimoire-Echoes

---

## 📑 目录

1. [技术架构概述](#1-技术架构概述)
2. [Godot项目结构](#2-godot项目结构)
3. [核心系统实现](#3-核心系统实现)
4. [数据架构设计](#4-数据架构设计)
5. [性能优化方案](#5-性能优化方案)
6. [开发环境配置](#6-开发环境配置)
7. [部署与发布](#7-部署与发布)

---

## 1. 技术架构概述

### 1.1 架构设计原则

| 原则 | 说明 | Godot实现方式 |
|------|------|--------------|
| **组件化架构** | 游戏功能由独立组件构成 | Godot节点系统 + 组合模式 |
| **数据驱动设计** | 游戏内容通过数据配置 | Resource资源 + JSON数据 |
| **信号驱动通信** | 模块间通过信号解耦 | Godot信号系统 |
| **状态机模式** | 管理复杂状态转换 | 自定义状态机实现 |
| **性能优先** | 保证60FPS，支持200+同屏敌人 | 对象池 + 批处理渲染 |

### 1.2 技术栈确认

| 技术 | 选择 | 版本 | 说明 |
|------|------|------|------|
| **游戏引擎** | Godot | 4.x | 2D性能优秀，学习成本低 |
| **编程语言** | GDScript | - | 主逻辑，类Python语法 |
| **渲染引擎** | Vulkan | - | 高性能渲染 |
| **物理引擎** | Godot内置 | - | 2D物理碰撞 |
| **数据格式** | Resource + JSON | - | 配置数据 + 运行时数据 |
| **版本控制** | Git | - | 代码版本管理 |
| **IDE** | Godot编辑器 | - | 内置脚本编辑器 |
| **辅助工具** | VS Code | - | 代码补全、调试 |

### 1.3 性能目标

| 指标 | 目标 | 实现策略 |
|------|------|----------|
| **帧率** | 60 FPS（最低配置） | 对象池、批处理渲染、物理优化 |
| **分辨率** | 1920x1080 | 自适应缩放 |
| **加载时间** | 场景切换 < 3秒 | 异步加载、资源预加载 |
| **存档大小** | 单个存档 < 100KB | JSON压缩、数据精简 |
| **同屏敌人** | 最大200个 | MultiMesh批处理、空间分区 |

---

## 2. Godot项目结构

### 2.1 项目目录结构

```
Grimoire-Echoes/
├── project.godot                 # Godot项目文件
├── export_presets.cfg            # 导出配置
├── .gitignore                    # Git忽略文件
├── README.md                     # 项目说明
│
├── assets/                       # 资源文件
│   ├── sprites/                  # 精灵图
│   │   ├── characters/           # 角色精灵
│   │   ├── enemies/              # 敌人精灵
│   │   ├── spells/               # 法术特效
│   │   ├── ui/                   # UI元素
│   │   └── environment/          # 环境元素
│   ├── animations/               # 动画资源
│   ├── audio/                    # 音频资源
│   │   ├── music/                # 背景音乐
│   │   ├── sfx/                  # 音效
│   │   └── ui/                   # UI音效
│   ├── fonts/                    # 字体文件
│   ├── shaders/                  # 着色器
│   └── resources/                # 资源文件
│       ├── spells/               # 法术资源
│       ├── enemies/              # 敌人资源
│       ├── relics/               # 遗物资源
│       └── characters/           # 角色资源
│
├── scenes/                       # 场景文件
│   ├── main/                     # 主场景
│   │   ├── main_menu.tscn        # 主菜单场景
│   │   ├── character_select.tscn # 角色选择场景
│   │   ├── map_select.tscn       # 地图选择场景
│   │   └── game.tscn             # 游戏主场景
│   ├── player/                   # 玩家场景
│   │   └── player.tscn           # 玩家角色
│   ├── enemies/                  # 敌人场景
│   │   ├── base_enemy.tscn       # 敌人基类
│   │   ├── shadow_servant.tscn   # 暗影仆从
│   │   └── ...                   # 其他敌人
│   ├── spells/                   # 法术场景
│   │   ├── base_spell.tscn       # 法术基类
│   │   ├── fireball.tscn         # 火球术
│   │   └── ...                   # 其他法术
│   ├── effects/                  # 特效场景
│   │   ├── damage_number.tscn    # 伤害数字
│   │   ├── particle_effect.tscn  # 粒子特效
│   │   └── ...                   # 其他特效
│   ├── ui/                       # UI场景
│   │   ├── hud.tscn              # 游戏内HUD
│   │   ├── pause_menu.tscn       # 暂停菜单
│   │   ├── settings_menu.tscn    # 设置菜单
│   │   └── ...                   # 其他UI
│   └── maps/                     # 地图场景
│       ├── forest.tscn           # 幽暗森林
│       ├── lava_canyon.tscn      # 熔岩裂谷
│       └── ...                   # 其他地图
│
├── scripts/                      # 脚本文件
│   ├── autoload/                 # 自动加载脚本
│   │   ├── game_manager.gd       # 游戏管理器
│   │   ├── scene_manager.gd      # 场景管理器
│   │   ├── audio_manager.gd      # 音频管理器
│   │   ├── save_manager.gd       # 存档管理器
│   │   └── ...                   # 其他管理器
│   ├── player/                   # 玩家脚本
│   │   ├── player.gd             # 玩家主控制器
│   │   ├── player_stats.gd       # 玩家属性
│   │   ├── player_movement.gd    # 移动控制
│   │   └── player_input.gd       # 输入处理
│   ├── spells/                   # 法术脚本
│   │   ├── spell_base.gd         # 法术基类
│   │   ├── spell_manager.gd      # 法术管理器
│   │   ├── spell_slot.gd         # 法术槽位
│   │   └── elements/             # 元素法术实现
│   │       ├── fire_spells.gd    # 火焰系
│   │       ├── water_spells.gd   # 水流系
│   │       └── ...               # 其他元素
│   ├── enemies/                  # 敌人脚本
│   │   ├── enemy_base.gd         # 敌人基类
│   │   ├── enemy_ai.gd           # AI状态机
│   │   ├── enemy_spawner.gd      # 敌人生成器
│   │   └── bosses/               # Boss实现
│   ├── combat/                   # 战斗系统脚本
│   │   ├── damage_calculator.gd  # 伤害计算器
│   │   ├── status_effect_manager.gd # 状态效果管理
│   │   └── projectile_manager.gd # 投射物管理
│   ├── maps/                     # 地图系统脚本
│   │   ├── map_manager.gd        # 地图管理器
│   │   ├── map_generator.gd      # 地图生成器
│   │   └── environment.gd        # 环境效果
│   ├── ui/                       # UI脚本
│   │   ├── ui_manager.gd         # UI管理器
│   │   ├── hud.gd                # 游戏内HUD
│   │   ├── damage_numbers.gd     # 伤害数字
│   │   └── minimap.gd            # 小地图
│   ├── data/                     # 数据脚本
│   │   ├── spell_resource.gd     # 法术资源
│   │   ├── enemy_resource.gd     # 敌人资源
│   │   └── relic_resource.gd     # 遗物资源
│   └── utils/                    # 工具脚本
│       ├── object_pool.gd        # 对象池
│       ├── math_utils.gd         # 数学工具
│       └── string_utils.gd       # 字符串工具
│
├── data/                         # 数据配置
│   ├── spells.json               # 法术配置
│   ├── enemies.json              # 敌人配置
│   ├── relics.json               # 遗物配置
│   ├── characters.json           # 角色配置
│   ├── maps.json                 # 地图配置
│   └── balance.json              # 平衡性配置
│
├── tests/                        # 测试文件
│   ├── unit/                     # 单元测试
│   ├── integration/              # 集成测试
│   └── performance/              # 性能测试
│
└── docs/                         # 文档
    ├── game-design-document.md   # 游戏设计文档
    ├── game-architecture.md      # 游戏架构文档
    ├── technical-architecture.md # 技术架构文档（本文档）
    └── performance-optimization-plan.md # 性能优化方案
```

### 2.2 命名规范

| 类型 | 命名规范 | 示例 |
|------|----------|------|
| **文件名** | snake_case | `player_stats.gd`, `fireball.tscn` |
| **类名** | PascalCase | `PlayerStats`, `SpellBase` |
| **变量名** | snake_case | `current_health`, `move_speed` |
| **函数名** | snake_case | `take_damage()`, `cast_spell()` |
| **信号名** | snake_case | `health_changed`, `spell_cast` |
| **常量名** | SCREAMING_SNAKE_CASE | `MAX_HEALTH`, `COOLDOWN_TIME` |
| **枚举名** | PascalCase | `ElementType`, `GameState` |
| **枚举值** | SCREAMING_SNAKE_CASE | `FIRE`, `WATER`, `PLAYING` |

### 2.3 Autoload配置

在`project.godot`中配置自动加载脚本：

```ini
[autoload]

GameManager="*res://scripts/autoload/game_manager.gd"
SceneManager="*res://scripts/autoload/scene_manager.gd"
AudioManager="*res://scripts/autoload/audio_manager.gd"
SaveManager="*res://scripts/autoload/save_manager.gd"
ResourceManager="*res://scripts/autoload/resource_manager.gd"
InputManager="*res://scripts/autoload/input_manager.gd"
ObjectPoolManager="*res://scripts/autoload/object_pool_manager.gd"
```

### 2.4 输入映射配置

在`project.godot`中配置输入映射：

```ini
[input]

move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":119,"location":0,"echo":false,"script":null)]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":115,"location":0,"echo":false,"script":null)]
}
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)]
}
dodge={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194325,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
}
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":101,"location":0,"echo":false,"script":null)]
}
pause={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194305,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
}
speed_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194306,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
}
toggle_minimap={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":77,"key_label":0,"unicode":109,"location":0,"echo":false,"script":null)]
}
```

---

## 3. 核心系统实现

### 3.1 游戏状态管理

#### GameManager（游戏管理器）

```gdscript
# GameManager.gd - 游戏管理器（单例）
extends Node

# 游戏状态
enum GameState {
    MAIN_MENU,
    CHARACTER_SELECT,
    MAP_SELECT,
    PLAYING,
    PAUSED,
    GAME_OVER,
    VICTORY,
    SETTINGS,
    CREDITS
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState

# 游戏数据
var current_character: String = ""
var current_map: String = ""
var current_wave: int = 1
var play_time: float = 0.0

# 信号
signal state_changed(old_state: GameState, new_state: GameState)
signal game_started(character: String, map: String)
signal game_over(stats: Dictionary)
signal wave_completed(wave: int)

func _ready() -> void:
    # 初始化游戏
    _initialize_game()

func _process(delta: float) -> void:
    if current_state == GameState.PLAYING:
        play_time += delta

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
        GameState.VICTORY:
            _on_victory_enter()
    
    state_changed.emit(previous_state, new_state)

func start_game(character: String, map: String) -> void:
    current_character = character
    current_map = map
    current_wave = 1
    play_time = 0.0
    
    change_state(GameState.PLAYING)
    game_started.emit(character, map)

func pause_game() -> void:
    if current_state == GameState.PLAYING:
        change_state(GameState.PAUSED)
        get_tree().paused = true

func resume_game() -> void:
    if current_state == GameState.PAUSED:
        change_state(GameState.PLAYING)
        get_tree().paused = false

func end_game() -> void:
    var stats = {
        "character": current_character,
        "map": current_map,
        "wave": current_wave,
        "play_time": play_time,
        "timestamp": Time.get_datetime_string_from_system()
    }
    
    change_state(GameState.GAME_OVER)
    game_over.emit(stats)

func complete_wave() -> void:
    current_wave += 1
    wave_completed.emit(current_wave - 1)
    
    # 检查是否需要生成Boss
    if current_wave % 5 == 0:
        _spawn_boss()
    elif current_wave % 20 == 0:
        _spawn_major_boss()

func _initialize_game() -> void:
    # 加载设置
    _load_settings()
    
    # 初始化音频
    AudioManager.initialize()
    
    # 初始化存档
    SaveManager.initialize()

func _on_playing_enter() -> void:
    # 游戏开始逻辑
    pass

func _on_paused_enter() -> void:
    # 暂停逻辑
    pass

func _on_game_over_enter() -> void:
    # 游戏结束逻辑
    SaveManager.save_game_stats()

func _on_victory_enter() -> void:
    # 胜利逻辑
    SaveManager.save_game_stats()
    UnlockManager.unlock_next_map(current_map)

func _spawn_boss() -> void:
    # 生成Boss
    var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
    if enemy_spawner:
        enemy_spawner.spawn_boss(current_wave)

func _spawn_major_boss() -> void:
    # 生成大Boss
    var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
    if enemy_spawner:
        enemy_spawner.spawn_major_boss(current_wave)

func _load_settings() -> void:
    # 加载游戏设置
    var settings = SettingsManager.load_settings()
    # 应用设置
    apply_settings(settings)

func apply_settings(settings: Dictionary) -> void:
    # 应用图形设置
    if settings.has("resolution"):
        get_window().size = settings.resolution
    
    if settings.has("fullscreen"):
        if settings.fullscreen:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        else:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    
    # 应用音频设置
    if settings.has("master_volume"):
        AudioManager.set_master_volume(settings.master_volume)
    
    if settings.has("music_volume"):
        AudioManager.set_music_volume(settings.music_volume)
    
    if settings.has("sfx_volume"):
        AudioManager.set_sfx_volume(settings.sfx_volume)
```

### 3.2 玩家系统实现

#### Player（玩家主控制器）

```gdscript
# Player.gd - 玩家主控制器
class_name Player
extends CharacterBody2D

# 组件引用
@onready var stats: PlayerStats = $PlayerStats
@onready var movement: PlayerMovement = $PlayerMovement
@onready var input_handler: PlayerInput = $PlayerInput
@onready var spell_manager: SpellManager = $SpellManager
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D

# 状态
var is_invincible: bool = false
var is_dodging: bool = false
var dodge_cooldown: float = 0.0

# 信号
signal health_changed(old_value: float, new_value: float)
signal mana_changed(old_value: float, new_value: float)
signal level_up(new_level: int)
signal died()

func _ready() -> void:
    # 初始化玩家
    _initialize_player()
    
    # 连接信号
    _connect_signals()

func _physics_process(delta: float) -> void:
    # 处理输入
    var input_vector = input_handler.get_input_vector()
    
    # 处理移动
    movement.handle_movement(input_vector, delta)
    
    # 处理闪避
    if input_handler.is_dodge_pressed() and dodge_cooldown <= 0:
        dodge()
    
    # 更新闪避冷却
    dodge_cooldown = max(0, dodge_cooldown - delta)
    
    # 更新法术
    spell_manager.update_spells(delta)
    
    # 移动
    move_and_slide()

func _process(delta: float) -> void:
    # 更新动画
    _update_animation()
    
    # 更新摄像机
    _update_camera()

func take_damage(amount: float, damage_type: DamageType = DamageType.PHYSICAL) -> void:
    if is_invincible or is_dodging:
        return
    
    var actual_damage = stats.calculate_damage(amount, damage_type)
    var old_health = stats.current_health
    
    stats.current_health = max(0, stats.current_health - actual_damage)
    health_changed.emit(old_health, stats.current_health)
    
    # 显示伤害数字
    _show_damage_number(actual_damage)
    
    # 受击效果
    _play_hit_effect()
    
    # 死亡检查
    if stats.current_health <= 0:
        _die()

func heal(amount: float) -> void:
    var old_health = stats.current_health
    stats.current_health = min(stats.get_max_health(), stats.current_health + amount)
    health_changed.emit(old_health, stats.current_health)

func use_mana(amount: float) -> bool:
    if stats.current_mana < amount:
        return false
    
    var old_mana = stats.current_mana
    stats.current_mana -= amount
    mana_changed.emit(old_mana, stats.current_mana)
    return true

func dodge() -> void:
    if is_dodging or dodge_cooldown > 0:
        return
    
    is_dodging = true
    is_invincible = true
    dodge_cooldown = stats.dodge_cooldown
    
    # 执行闪避移动
    movement.dodge(input_handler.get_facing_direction())
    
    # 闪避动画
    animation_player.play("dodge")
    
    # 闪避结束
    await animation_player.animation_finished
    is_dodging = false
    is_invincible = false

func _initialize_player() -> void:
    # 根据角色类型初始化属性
    match GameManager.current_character:
        "炽焰":
            stats.initialize_fire_mage()
        "暮霭":
            stats.initialize_shadow_mage()
        "露珠":
            stats.initialize_nature_mage()
    
    # 初始法术
    spell_manager.initialize_spells(stats.initial_spell)

func _connect_signals() -> void:
    stats.health_changed.connect(_on_health_changed)
    stats.mana_changed.connect(_on_mana_changed)
    stats.level_up.connect(_on_level_up)
    stats.died.connect(_on_died)
    
    hurtbox.damage_received.connect(take_damage)

func _update_animation() -> void:
    var input_vector = input_handler.get_input_vector()
    
    if input_vector == Vector2.ZERO:
        animation_player.play("idle")
    else:
        animation_player.play("run")
        
        # 翻转精灵
        if input_vector.x < 0:
            sprite.flip_h = true
        elif input_vector.x > 0:
            sprite.flip_h = false

func _update_camera() -> void:
    # 摄像机跟随
    camera.global_position = global_position

func _show_damage_number(damage: float) -> void:
    var damage_number = ObjectPoolManager.acquire("res://scenes/effects/damage_number.tscn")
    damage_number.global_position = global_position + Vector2(randf_range(-20, 20), -30)
    damage_number.initialize(damage)

func _play_hit_effect() -> void:
    # 播放受击特效
    var hit_effect = ObjectPoolManager.acquire("res://scenes/effects/hit_effect.tscn")
    hit_effect.global_position = global_position
    hit_effect.emitting = true

func _die() -> void:
    # 播放死亡动画
    animation_player.play("die")
    
    # 禁用碰撞
    set_collision_layer_value(1, false)
    set_collision_mask_value(1, false)
    
    # 等待动画播放完成
    await animation_player.animation_finished
    
    # 游戏结束
    GameManager.end_game()
    
    # 自我销毁
    queue_free()

func _on_health_changed(old_value: float, new_value: float) -> void:
    # 更新HUD
    var hud = get_tree().get_first_node_in_group("hud")
    if hud:
        hud.update_health(new_value, stats.get_max_health())

func _on_mana_changed(old_value: float, new_value: float) -> void:
    # 更新HUD
    var hud = get_tree().get_first_node_in_group("hud")
    if hud:
        hud.update_mana(new_value, stats.get_max_mana())

func _on_level_up(new_level: int) -> void:
    # 显示升级效果
    _play_level_up_effect()
    
    # 更新HUD
    var hud = get_tree().get_first_node_in_group("hud")
    if hud:
        hud.show_level_up(new_level)
    
    # 检查槽位解锁
    spell_manager.check_slot_unlocks(new_level)

func _on_died() -> void:
    died.emit()
```

### 3.3 法术系统实现

#### SpellBase（法术基类）

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

# 枚举
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

# 引用
var player: Player = null
var spell_manager: SpellManager = null

# 信号
signal spell_cast(spell: SpellBase)
signal spell_cooldown_complete(spell: SpellBase)
signal spell_upgraded(spell: SpellBase, new_level: int)

func _ready() -> void:
    # 初始化升级数据
    _initialize_level_multipliers()
    
    # 获取引用
    player = get_tree().get_first_node_in_group("player")
    spell_manager = get_parent()

func _process(delta: float) -> void:
    # 更新冷却
    if not is_ready:
        cooldown_timer -= delta
        if cooldown_timer <= 0:
            is_ready = true
            spell_cooldown_complete.emit(self)

func cast(target_position: Vector2) -> bool:
    # 检查是否可以施法
    if not is_ready:
        return false
    
    # 检查法力消耗
    if player.stats.current_mana < mana_cost:
        return false
    
    # 消耗法力
    player.use_mana(mana_cost)
    
    # 执行施法逻辑
    _execute_cast(target_position)
    
    # 开始冷却
    is_ready = false
    cooldown_timer = cooldown
    
    # 播放施法动画
    _play_cast_animation()
    
    # 播放施法音效
    _play_cast_sound()
    
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

func get_cooldown() -> float:
    return cooldown

func get_mana_cost() -> float:
    return mana_cost

func can_cast() -> bool:
    return is_ready and player.stats.current_mana >= mana_cost

# 子类实现
func _execute_cast(target_position: Vector2) -> void:
    # 基类实现为空，子类覆盖
    pass

func _initialize_level_multipliers() -> void:
    # 默认升级曲线，子类可覆盖
    for i in range(max_level):
        level_multipliers.append(1.0 + i * 0.08)

func _apply_upgrade_effects() -> void:
    # 应用升级效果，子类覆盖
    pass

func _play_cast_animation() -> void:
    # 播放施法动画
    if player and player.animation_player:
        player.animation_player.play("cast_" + spell_id)

func _play_cast_sound() -> void:
    # 播放施法音效
    AudioManager.play_sfx("spell_cast_" + spell_id)
```

#### SpellManager（法术管理器）

```gdscript
# SpellManager.gd - 法术管理器
class_name SpellManager
extends Node

# 法术槽位
var spell_slots: Array[SpellSlot] = []
var ultimate_slot: SpellSlot = null

# 槽位解锁等级
const SLOT_UNLOCK_LEVELS: Array[int] = [0, 0, 5, 10]
const ULTIMATE_SLOT_UNLOCK_LEVEL: int = 15

# 信号
signal spell_slot_unlocked(slot_index: int)
signal spell_equipped(slot_index: int, spell: SpellBase)
signal ultimate_slot_unlocked()
signal fusion_available(fusion_spells: Array[SpellBase])

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
    ultimate_slot.slot_index = -1
    ultimate_slot.unlock_level = ULTIMATE_SLOT_UNLOCK_LEVEL
    ultimate_slot.is_ultimate = true

func initialize_spells(initial_spell_id: String) -> void:
    # 加载初始法术
    var spell_resource = ResourceManager.get_spell(initial_spell_id)
    if spell_resource:
        var spell = _create_spell_from_resource(spell_resource)
        equip_spell(0, spell)

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
    
    # 检查融合可能性
    _check_fusion_available()
    
    return true

func upgrade_spell(slot_index: int) -> bool:
    var slot = spell_slots[slot_index]
    if slot.spell == null:
        return false
    
    slot.spell.upgrade()
    return true

func cast_spell(slot_index: int, target_position: Vector2) -> bool:
    var slot = spell_slots[slot_index]
    if slot.spell == null:
        return false
    
    return slot.spell.cast(target_position)

func update_spells(delta: float) -> void:
    # 更新所有法术冷却
    for slot in spell_slots:
        if slot.spell != null:
            slot.spell._process(delta)

func check_slot_unlocks(player_level: int) -> void:
    for i in range(spell_slots.size()):
        var slot = spell_slots[i]
        if not slot.is_unlocked and player_level >= slot.unlock_level:
            slot.is_unlocked = true
            spell_slot_unlocked.emit(i)
    
    if not ultimate_slot.is_unlocked and player_level >= ultimate_slot.unlock_level:
        ultimate_slot.is_unlocked = true
        ultimate_slot_unlocked.emit()

func get_available_spells() -> Array[SpellBase]:
    var spells: Array[SpellBase] = []
    for slot in spell_slots:
        if slot.is_unlocked and slot.spell != null:
            spells.append(slot.spell)
    return spells

func get_all_spells() -> Array[SpellBase]:
    var spells: Array[SpellBase] = []
    for slot in spell_slots:
        if slot.spell != null:
            spells.append(slot.spell)
    
    if ultimate_slot.spell != null:
        spells.append(ultimate_slot.spell)
    
    return spells

func _unequip_spell(slot_index: int) -> void:
    var slot = spell_slots[slot_index]
    if slot.spell != null:
        remove_child(slot.spell)
        slot.spell.queue_free()
        slot.spell = null

func _check_fusion_available() -> void:
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
    
    if fusion_candidates.size() > 0:
        fusion_available.emit(fusion_candidates)

func _can_fuse(spell1: SpellBase, spell2: SpellBase) -> bool:
    # 检查两个法术是否可以融合
    # 不同元素的法术可以融合
    return spell1.element_type != spell2.element_type

func _get_fusion_spell(spell1: SpellBase, spell2: SpellBase) -> SpellBase:
    # 根据两个法术获取融合法术
    var fusion_id = _get_fusion_id(spell1.spell_id, spell2.spell_id)
    var fusion_resource = ResourceManager.get_fusion_spell(fusion_id)
    
    if fusion_resource:
        return _create_spell_from_resource(fusion_resource)
    
    return null

func _get_fusion_id(spell1_id: String, spell2_id: String) -> String:
    # 生成融合法术ID
    var ids = [spell1_id, spell2_id]
    ids.sort()
    return "fusion_" + ids[0] + "_" + ids[1]

func _create_spell_from_resource(resource: SpellResource) -> SpellBase:
    # 从资源创建法术实例
    var spell_script = load("res://scripts/spells/" + resource.script_path)
    var spell = spell_script.new()
    
    # 设置属性
    spell.spell_id = resource.id
    spell.spell_name = resource.name
    spell.description = resource.description
    spell.element_type = resource.element
    spell.spell_type = resource.type
    spell.base_damage = resource.base_damage
    spell.cooldown = resource.cooldown
    spell.mana_cost = resource.mana_cost
    
    return spell
```

### 3.4 敌人系统实现

#### EnemyBase（敌人基类）

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

# 枚举
enum EnemyType {
    NORMAL,
    RANGED,
    SPECIAL,
    SWARM,
    ELITE,
    BOSS
}

# 当前状态
var current_health: float
var is_alive: bool = true
var is_stunned: bool = false
var current_wave: int = 1

# 状态效果
var status_effects: Array[StatusEffect] = []

# 引用
var player: Player = null
var enemy_manager: Node = null

# 信号
signal health_changed(old_value: float, new_value: float)
signal died(enemy: EnemyBase)
signal damage_dealt(amount: float)

func _ready() -> void:
    current_health = max_health
    player = get_tree().get_first_node_in_group("player")
    enemy_manager = get_parent()
    
    # 添加到敌人组
    add_to_group("enemies")

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

func apply_status_effect(effect: StatusEffect) -> void:
    # 检查是否已有相同效果
    for existing_effect in status_effects:
        if existing_effect.type == effect.type:
            existing_effect.duration = max(existing_effect.duration, effect.duration)
            return
    
    # 添加新效果
    status_effects.append(effect)
    _on_status_effect_applied(effect)

func stun(duration: float) -> void:
    is_stunned = true
    await get_tree().create_timer(duration).timeout
    is_stunned = false

func _calculate_damage(amount: float, damage_type: DamageType) -> float:
    var damage = amount
    
    # 应用状态效果加成
    for effect in status_effects:
        if effect.type == StatusEffect.Type.VULNERABLE:
            damage *= 1.15
    
    # 应用伤害类型计算
    match damage_type:
        DamageType.PHYSICAL:
            pass
        DamageType.MAGICAL:
            damage *= 1.0
        DamageType.TRUE:
            pass
    
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
            _remove_status_effect(effect)
            status_effects.remove_at(i)
        else:
            _apply_status_effect(effect, delta)
            i += 1

func _apply_status_effect(effect: StatusEffect, delta: float) -> void:
    match effect.type:
        StatusEffect.Type.BURN:
            # 燃烧效果
            var burn_damage = effect.value * delta
            take_damage(burn_damage, DamageType.DOT)
        StatusEffect.Type.POISON:
            # 中毒效果
            var poison_damage = effect.value * delta
            take_damage(poison_damage, DamageType.DOT)
        StatusEffect.Type.SLOW:
            # 减速效果
            move_speed *= (1.0 - effect.value)

func _remove_status_effect(effect: StatusEffect) -> void:
    # 移除效果时恢复属性
    match effect.type:
        StatusEffect.Type.SLOW:
            move_speed /= (1.0 - effect.value)

func _on_status_effect_applied(effect: StatusEffect) -> void:
    # 效果应用时的处理
    pass

func _drop_items() -> void:
    # 掉落物品
    for drop in drop_table:
        if randf() <= drop.chance:
            var item = ObjectPoolManager.acquire(drop.item_scene)
            item.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))

func _drop_experience() -> void:
    # 掉落经验
    var exp_gem = ObjectPoolManager.acquire("res://scenes/items/experience_gem.tscn")
    exp_gem.global_position = global_position
    exp_gem.value = exp_value

func _drop_gold() -> void:
    # 掉落金币
    var gold_gem = ObjectPoolManager.acquire("res://scenes/items/gold_gem.tscn")
    gold_gem.global_position = global_position
    gold_gem.value = gold_value

func _play_death_animation() -> void:
    # 播放死亡动画
    animation_player.play("die")
    await animation_player.animation_finished

func _show_damage_number(damage: float) -> void:
    # 显示伤害数字
    var damage_number = ObjectPoolManager.acquire("res://scenes/effects/damage_number.tscn")
    damage_number.global_position = global_position + Vector2(randf_range(-20, 20), -30)
    damage_number.initialize(damage)

func _execute_ai(delta: float) -> void:
    # 执行AI逻辑，子类覆盖
    pass
```

### 3.5 战斗系统实现

#### DamageCalculator（伤害计算器）

```gdscript
# DamageCalculator.gd - 伤害计算器
class_name DamageCalculator
extends Node

# 伤害类型
enum DamageType {
    PHYSICAL,
    MAGICAL,
    TRUE,
    DOT
}

# 元素伤害加成表
const ELEMENT_BONUS: Dictionary = {
    "fire": "nature",
    "water": "fire",
    "lightning": "water",
    "nature": "lightning",
    "shadow": "wind",
    "wind": "shadow"
}

# 元素抗性表
const ELEMENT_RESISTANCE: Dictionary = {
    "fire": "water",
    "water": "lightning",
    "lightning": "nature",
    "nature": "fire",
    "shadow": "wind",
    "wind": "shadow"
}

static func calculate_damage(
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
            damage *= 1.25
            result["element_bonus"] = 1.25
    
    # 元素抗性
    if ELEMENT_RESISTANCE.has(spell_element):
        var target_element = defender_stats.get("element", "")
        if target_element == ELEMENT_RESISTANCE[spell_element]:
            damage *= 0.75
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
    
    # 最终伤害
    damage = max(1.0, damage)
    
    result["damage"] = damage
    return result

static func calculate_dot_damage(
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

---

## 4. 数据架构设计

### 4.1 Resource资源定义

#### SpellResource（法术资源）

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

# 脚本路径
@export var script_path: String = ""

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

#### EnemyResource（敌人资源）

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

# 场景路径
@export var scene_path: String = ""

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

## 5. 性能优化方案

### 5.1 对象池系统

```gdscript
# ObjectPoolManager.gd - 对象池管理器（单例）
extends Node

# 对象池配置 - 与性能优化方案对齐
var pool_configs: Dictionary = {
    "res://scenes/enemies/base_enemy.tscn": {"initial_size": 150, "max_size": 200},
    "res://scenes/spells/base_spell.tscn": {"initial_size": 200, "max_size": 300},
    "res://scenes/effects/damage_number.tscn": {"initial_size": 50, "max_size": 80},
    "res://scenes/effects/particle_effect.tscn": {"initial_size": 100, "max_size": 200},
    "res://scenes/items/experience_gem.tscn": {"initial_size": 100, "max_size": 150},
    "res://scenes/items/gold_gem.tscn": {"initial_size": 100, "max_size": 150},
    "res://scenes/summons/summon_entity.tscn": {"initial_size": 20, "max_size": 30},
    "res://scenes/environment/environmental.tscn": {"initial_size": 30, "max_size": 50}
}

# 内存预算：约750个预分配实体，每个实体约2-5KB，总计~3MB

# 对象池
var pools: Dictionary = {}  # 场景路径 -> 对象数组
var active_objects: Dictionary = {}  # 场景路径 -> 活跃对象数组

# 信号
signal object_acquired(object: Node)
signal object_released(object: Node)

func _ready() -> void:
    _initialize_pools()

func _initialize_pools() -> void:
    for scene_path in pool_configs:
        var config = pool_configs[scene_path]
        _create_pool(scene_path, config.initial_size)

func _create_pool(scene_path: String, initial_size: int) -> void:
    if pools.has(scene_path):
        return
    
    var scene = load(scene_path)
    pools[scene_path] = []
    active_objects[scene_path] = []
    
    for i in range(initial_size):
        var obj = scene.instantiate()
        obj.visible = false
        obj.process_mode = Node.PROCESS_MODE_DISABLED
        add_child(obj)
        pools[scene_path].append(obj)

func acquire(scene_path: String, position: Vector2 = Vector2.ZERO) -> Node:
    if not pools.has(scene_path):
        _create_pool(scene_path, 10)
    
    var obj: Node = null
    
    # 从池中获取对象
    if pools[scene_path].size() > 0:
        obj = pools[scene_path].pop_back()
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
    object_acquired.emit(obj)
    
    return obj

func release(obj: Node) -> void:
    var scene_path = obj.scene_file_path
    
    # 从活跃列表中移除
    if active_objects.has(scene_path):
        active_objects[scene_path].erase(obj)
    
    # 回收到池中
    obj.visible = false
    obj.process_mode = Node.PROCESS_MODE_DISABLED
    
    if not pools.has(scene_path):
        pools[scene_path] = []
    
    pools[scene_path].append(obj)
    object_released.emit(obj)

func get_active_count(scene_path: String) -> int:
    if active_objects.has(scene_path):
        return active_objects[scene_path].size()
    return 0

func get_pool_size(scene_path: String) -> int:
    if pools.has(scene_path):
        return pools[scene_path].size()
    return 0

func clear_pool(scene_path: String) -> void:
    if pools.has(scene_path):
        for obj in pools[scene_path]:
            obj.queue_free()
        pools.erase(scene_path)
    
    if active_objects.has(scene_path):
        for obj in active_objects[scene_path]:
            obj.queue_free()
        active_objects.erase(scene_path)

func get_memory_usage() -> Dictionary:
    var usage = {}
    for scene_path in pools:
        usage[scene_path] = {
            "pool_size": pools[scene_path].size(),
            "active_count": active_objects[scene_path].size()
        }
    return usage
```

### 5.2 视锥剔除策略

```gdscript
# ViewportCulling.gd - 视锥剔除管理器
class_name ViewportCulling
extends Node

# 视锥区域定义
const CORE_AREA: float = 400.0      # 核心区域：玩家周围400×400px
const ACTIVE_AREA: float = 800.0    # 活跃区域：玩家周围800×800px
const EDGE_AREA: float = 1200.0     # 边缘区域：玩家周围1200×1200px
const DORMANT_AREA: float = 1600.0  # 休眠区域：超出1200px

# 实体状态枚举
enum CullingState {
    CORE,       # 核心区域：完整渲染、完整AI、完整碰撞
    ACTIVE,     # 活跃区域：简化渲染、简化AI、碰撞检测
    EDGE,       # 边缘区域：最小渲染、AI暂停、碰撞降级
    DORMANT     # 休眠区域：不渲染、AI暂停、碰撞暂停
}

func get_culling_state(entity_position: Vector2, player_position: Vector2) -> CullingState:
    var distance = entity_position.distance_to(player_position)
    
    if distance <= CORE_AREA:
        return CullingState.CORE
    elif distance <= ACTIVE_AREA:
        return CullingState.ACTIVE
    elif distance <= EDGE_AREA:
        return CullingState.EDGE
    else:
        return CullingState.DORMANT

func update_entity_culling(entity: Node2D, player_position: Vector2) -> void:
    var state = get_culling_state(entity.global_position, player_position)
    
    match state:
        CullingState.CORE:
            _apply_core_state(entity)
        CullingState.ACTIVE:
            _apply_active_state(entity)
        CullingState.EDGE:
            _apply_edge_state(entity)
        CullingState.DORMANT:
            _apply_dormant_state(entity)

func _apply_core_state(entity: Node2D) -> void:
    # 核心区域：完整渲染、完整AI、完整碰撞
    entity.visible = true
    entity.set_process(true)
    entity.set_physics_process(true)

func _apply_active_state(entity: Node2D) -> void:
    # 活跃区域：简化渲染、简化AI、碰撞检测
    entity.visible = true
    entity.set_process(true)
    entity.set_physics_process(true)

func _apply_edge_state(entity: Node2D) -> void:
    # 边缘区域：最小渲染、AI暂停、碰撞降级
    entity.visible = true
    entity.set_process(false)
    entity.set_physics_process(true)

func _apply_dormant_state(entity: Node2D) -> void:
    # 休眠区域：不渲染、AI暂停、碰撞暂停
    entity.visible = false
    entity.set_process(false)
    entity.set_physics_process(false)
```

**视锥区域划分：**

| 区域 | 范围 | 处理策略 |
|------|------|----------|
| **核心区域** | 玩家周围 400×400px | 完整渲染、完整AI、完整碰撞 |
| **活跃区域** | 玩家周围 800×800px | 简化渲染、简化AI、碰撞检测 |
| **边缘区域** | 玩家周围 1200×1200px | 最小渲染、AI暂停、碰撞降级 |
| **休眠区域** | 超出 1200px | 不渲染、AI暂停、碰撞暂停 |

**屏幕外实体降级规则：**

| 实体类型 | 屏幕外行为 | 回到屏幕时行为 |
|----------|-----------|---------------|
| 普通敌人 | 继续移动但不渲染 | 恢复完整渲染 |
| 远程敌人 | 继续移动但不发射弹幕 | 恢复发射 |
| 召唤物 | 继续存在但不渲染 | 恢复渲染 |
| 投射物 | 继续飞行但不渲染 | 恢复渲染 |
| 粒子特效 | 暂停 | 恢复播放 |

### 5.3 渲染层级定义

```gdscript
# RenderLayers.gd - 渲染层级管理
class_name RenderLayers
extends Node

# 渲染层级定义
const LAYER_BACKGROUND: int = 0      # 背景层
const LAYER_TERRAIN_DECO: int = 1    # 地形装饰层
const LAYER_SHADOW: int = 2          # 阴影层
const LAYER_ENTITIES: int = 3        # 实体层
const LAYER_VFX: int = 4             # 特效层
const LAYER_UI: int = 5              # UI层

# 层级名称映射
const LAYER_NAMES: Dictionary = {
    LAYER_BACKGROUND: "Background",
    LAYER_TERRAIN_DECO: "Terrain Deco",
    LAYER_SHADOW: "Shadow",
    LAYER_ENTITIES: "Entities",
    LAYER_VFX: "VFX",
    LAYER_UI: "UI"
}

# 预期draw call数量
const EXPECTED_DRAW_CALLS: Dictionary = {
    LAYER_BACKGROUND: 1,
    LAYER_TERRAIN_DECO: "2-3",
    LAYER_SHADOW: "1 (可选)",
    LAYER_ENTITIES: "5-10 (MultiMesh)",
    LAYER_VFX: "3-5",
    LAYER_UI: "2-3"
}

# 总计：约15-25 draw calls（目标）
```

### 5.4 碰撞检测分层策略

```gdscript
# CollisionLayers.gd - 碰撞检测分层管理
class_name CollisionLayers
extends Node

# 碰撞层定义
const LAYER_PLAYER: int = 1
const LAYER_ENEMY: int = 2
const LAYER_PLAYER_PROJECTILE: int = 3
const LAYER_ENEMY_PROJECTILE: int = 4
const LAYER_PICKUP: int = 5
const LAYER_SUMMON: int = 6
const LAYER_TERRAIN: int = 7

# 碰撞检测分层策略
const COLLISION_STRATEGIES: Dictionary = {
    "player_enemy": {
        "frequency": "每物理帧",
        "spatial_partition": "四叉树",
        "shape": "圆形碰撞"
    },
    "player_projectile_enemy": {
        "frequency": "每物理帧",
        "spatial_partition": "四叉树",
        "shape": "圆形碰撞"
    },
    "enemy_projectile_player": {
        "frequency": "每物理帧",
        "spatial_partition": "四叉树",
        "shape": "圆形碰撞"
    },
    "enemy_enemy": {
        "frequency": "每2物理帧",
        "spatial_partition": "四叉树",
        "shape": "AABB"
    },
    "summon_enemy": {
        "frequency": "每物理帧",
        "spatial_partition": "四叉树",
        "shape": "圆形碰撞"
    },
    "player_terrain": {
        "frequency": "每物理帧",
        "spatial_partition": "瓦片地图",
        "shape": "AABB"
    },
    "pickup_player": {
        "frequency": "每3物理帧",
        "spatial_partition": "四叉树",
        "shape": "圆形碰撞"
    }
}

# 碰撞形状优化
const COLLISION_SHAPES: Dictionary = {
    "player": "圆形",
    "melee_enemy": "圆形",
    "ranged_enemy": "圆形",
    "projectile": "圆形（小）",
    "boss": "多圆形组合"
}
```

### 5.5 批处理渲染

```gdscript
# ProjectileRenderer.gd - 投射物批处理渲染
extends MultiMeshInstance2D

const MAX_PROJECTILES = 500

var projectile_mesh: ImmediateMesh = null
var projectile_material: ShaderMaterial = null

func _ready() -> void:
    _initialize_multimesh()

func _initialize_multimesh() -> void:
    var multimesh = MultiMesh.new()
    multimesh.instance_count = MAX_PROJECTILES
    multimesh.visible_instance_count = 0
    multimesh.transform_format = MultiMesh.TRANSFORM_2D
    multimesh.custom_aabb = AABB(Vector3(-1000, -1000, -1000), Vector3(2000, 2000, 2000))
    
    var mesh = QuadMesh.new()
    mesh.size = Vector2(8, 8)
    multimesh.mesh = mesh
    
    var material = ShaderMaterial.new()
    material.shader = load("res://shaders/projectile_shader.gdshader")
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
        
        _update_instance_data(i, projectile)

func _update_instance_data(index: int, projectile: Node2D) -> void:
    # 更新实例数据（颜色、大小等）
    pass
```

### 5.6 空间分区优化（四叉树）

```gdscript
# SpatialPartition.gd - 四叉树空间分区优化
class_name SpatialPartition
extends RefCounted

const MAX_DEPTH := 4
const MAX_ENTITIES_PER_NODE := 8

var _root: QuadTreeNode

func _init(world_bounds: Rect2) -> void:
    _root = QuadTreeNode.new(world_bounds, 0)

func insert(entity: Node2D, bounds: Rect2) -> void:
    _root.insert(entity, bounds)

func query(query_bounds: Rect2) -> Array[Node2D]:
    var result: Array[Node2D] = []
    _root.query(query_bounds, result)
    return result

func clear() -> void:
    _root.clear()

# 每帧更新：重建四叉树
func rebuild(entities: Array[Node2D]) -> void:
    clear()
    for entity in entities:
        if is_instance_valid(entity):
            var bounds = _get_entity_bounds(entity)
            insert(entity, bounds)

func _get_entity_bounds(entity: Node2D) -> Rect2:
    # 获取实体的边界框
    var size = Vector2(32, 32)  # 默认大小
    if entity.has_method("get_collision_shape_size"):
        size = entity.get_collision_shape_size()
    
    return Rect2(
        entity.global_position - size / 2,
        size
    )
```

#### 四叉树节点实现

```gdscript
# QuadTreeNode.gd - 四叉树节点
class_name QuadTreeNode
extends RefCounted

var bounds: Rect2
var depth: int
var entities: Array[Node2D] = []
var children: Array[QuadTreeNode] = []
var is_leaf: bool = true

func _init(bounds: Rect2, depth: int) -> void:
    self.bounds = bounds
    self.depth = depth

func insert(entity: Node2D, entity_bounds: Rect2) -> void:
    # 如果不是叶子节点，尝试插入子节点
    if not is_leaf:
        for child in children:
            if child.bounds.intersects(entity_bounds):
                child.insert(entity, entity_bounds)
        return
    
    # 添加实体
    entities.append(entity)
    
    # 检查是否需要分割
    if entities.size() > SpatialPartition.MAX_ENTITIES_PER_NODE and depth < SpatialPartition.MAX_DEPTH:
        _subdivide()

func _subdivide() -> void:
    is_leaf = false
    
    var half_size = bounds.size / 2
    var center = bounds.position + half_size
    
    # 创建四个子节点
    children.append(QuadTreeNode.new(Rect2(bounds.position, half_size), depth + 1))
    children.append(QuadTreeNode.new(Rect2(center.x, bounds.position.y, half_size.x, half_size.y), depth + 1))
    children.append(QuadTreeNode.new(Rect2(bounds.position.x, center.y, half_size.x, half_size.y), depth + 1))
    children.append(QuadTreeNode.new(Rect2(center, half_size), depth + 1))
    
    # 重新插入实体
    for entity in entities:
        var entity_bounds = SpatialPartition._get_entity_bounds(entity)
        for child in children:
            if child.bounds.intersects(entity_bounds):
                child.insert(entity, entity_bounds)
    
    entities.clear()

func query(query_bounds: Rect2, result: Array[Node2D]) -> void:
    if not bounds.intersects(query_bounds):
        return
    
    if is_leaf:
        for entity in entities:
            if query_bounds.has_point(entity.global_position):
                result.append(entity)
    else:
        for child in children:
            child.query(query_bounds, result)

func clear() -> void:
    entities.clear()
    children.clear()
    is_leaf = true
```

---

## 6. 开发环境配置

### 6.1 Godot项目设置

```ini
; project.godot - Godot项目配置

[application]

config/name="秘法回响"
config/description="类幸存者肉鸽动作游戏"
config/version="1.0.0"
run/main_scene="res://scenes/main/main_menu.tscn"
config/features=PackedStringArray("4.2", "GL Compatibility")

[autoload]

GameManager="*res://scripts/autoload/game_manager.gd"
SceneManager="*res://scripts/autoload/scene_manager.gd"
AudioManager="*res://scripts/autoload/audio_manager.gd"
SaveManager="*res://scripts/autoload/save_manager.gd"
ResourceManager="*res://scripts/autoload/resource_manager.gd"
InputManager="*res://scripts/autoload/input_manager.gd"
ObjectPoolManager="*res://scripts/autoload/object_pool_manager.gd"

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/size/resizable=true
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/canvas_textures/default_texture_filter=0
environment/defaults/default_clear_color=Color(0.1, 0.1, 0.15, 1)
```

### 6.2 VS Code配置

```json
// .vscode/settings.json
{
    "godot-tools.gdscript_lsp_server_port": 6005,
    "godot-tools.gdscript_lsp_server_host": "127.0.0.1",
    "godot-tools.editor_path": "C:\\Program Files\\Godot\\Godot.exe",
    "files.associations": {
        "*.gd": "gdscript",
        "*.tscn": "godot-scene",
        "*.tres": "godot-resource"
    },
    "gdformat.width": 100,
    "gdlint.line_length": 100
}
```

### 6.3 Git配置

```gitignore
# .gitignore

# Godot
.godot/
*.import
export/

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Builds
build/
*.exe
*.dll
*.so
*.dylib

# Temp
*.tmp
*.bak
```

---

## 7. 部署与发布

### 7.1 导出配置

```ini
; export_presets.cfg

[preset.0]

name="Windows Desktop"
platform="Windows Desktop"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/windows/秘法回响.exe"

[preset.0.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=1
binary_format/embed_pck=true
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
binary_format/architecture="x86_64"
codesign/enable=false
application/modify_resources=false
application/icon=""
application/console_wrapper_icon=""
application/icon_interpolation=4
application/file_version=""
application/product_version=""
application/company_name=""
application/product_name=""
application/file_description=""
application/copyright=""
application/trademarks=""
application/d3d12_agility_sdk_multiarch=true
ssh_remote_deploy/enabled=false
```

### 7.2 构建脚本

```powershell
# build.ps1 - Windows构建脚本

param(
    [string]$Configuration = "Release",
    [string]$OutputPath = "build/windows"
)

# 创建输出目录
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force
}

# 导出项目
$GodotPath = "C:\Program Files\Godot\Godot.exe"
$ProjectPath = "."

Write-Host "开始构建秘法回响..."
Write-Host "配置: $Configuration"
Write-Host "输出路径: $OutputPath"

# 执行导出
& $GodotPath --headless --export-release "Windows Desktop" "$OutputPath\秘法回响.exe"

if ($LASTEXITCODE -eq 0) {
    Write-Host "构建成功！" -ForegroundColor Green
    Write-Host "输出文件: $OutputPath\秘法回响.exe"
} else {
    Write-Host "构建失败！" -ForegroundColor Red
    exit 1
}
```

### 7.3 测试清单

| 测试类型 | 测试内容 | 通过标准 |
|----------|----------|----------|
| **单元测试** | 核心算法、数据计算 | 100%通过 |
| **集成测试** | 系统间交互 | 95%通过 |
| **性能测试** | 帧率、内存、加载时间 | 达到性能目标 |
| **兼容性测试** | 不同硬件配置 | 最低配置可运行 |
| **功能测试** | 所有游戏功能 | 功能完整 |
| **回归测试** | 修复Bug后验证 | 不引入新Bug |

---

## 📝 文档历史

| 版本 | 日期 | 修改内容 |
|------|------|----------|
| v1.1 | 2026-08-27 | 修复架构与性能方案不一致问题：更新对象池预分配数量、添加视锥剔除策略、补充渲染层级定义、添加碰撞检测分层策略、统一方法命名（spawn→acquire, recycle→release） |
| v1.0 | 2026-08-27 | 初始版本，完成技术架构设计 |

---

**文档生成：** MiMo-v2.5  
**项目代号：** Grimoire-Echoes  
**文档状态：** 技术架构设计完成，已修复与性能优化方案的不一致问题