# 🔮 秘法回响（Grimoire Echoes）— 性能优化方案

> **版本：** v1.0
> **日期：** 2026-08-27
> **引擎：** Godot 4.x (Vulkan)
> **分析者：** 性能分析师（performance-analyst）
> **依据：** 秘法回响_软件需求规格说明书 v2.0

---

## 目录

1. [核心性能挑战分析](#1-核心性能挑战分析)
2. [同屏200+敌人优化方案](#2-同屏200敌人优化方案)
3. [弹幕粒子渲染优化](#3-弹幕粒子渲染优化)
4. [60FPS保障策略](#4-60fps保障策略)
5. [无限波次模式特殊优化](#5-无限波次模式特殊优化)
6. [加速模式性能适配](#6-加速模式性能适配)
7. [存档系统性能优化](#7-存档系统性能优化)
8. [性能监控与调试](#8-性能监控与调试)
9. [实现路线图](#9-实现路线图)

---

## 1. 核心性能挑战分析

### 1.1 需求规格关键约束

| 约束项 | 规格要求 | 性能影响 |
|--------|----------|----------|
| **同屏敌人上限** | 200个 | 碰撞检测、AI计算、渲染 |
| **无限波次** | 无上限，难度持续递增 | 内存稳定性、长期性能 |
| **加速模式** | 1x/2x/3x | 物理计算、AI更新频率 |
| **6元素法术** | 30个基础+15融合 | 投射物数量、特效渲染 |
| **存档频率** | 每波结束自动保存 | IO性能、帧率波动 |
| **目标帧率** | 60 FPS（最低配置） | 帧时间 ≤ 16.67ms |
| **最低配置** | i5-6600 / GTX 960 / 8GB | 保守性能预算 |

### 1.2 同屏实体峰值估算

根据无限波次模式的难度递增公式 `敌人属性 = 基础属性 × (1 + 当前波次 × 0.10)`，实体数量随波次增长：

| 波次阶段 | 预估敌人数量 | 玩家弹幕 | 敌人弹幕 | 召唤物 | 粒子/特效 | **峰值实体总数** |
|----------|-------------|----------|----------|--------|-----------|-----------------|
| 1-10（新手） | 10-30 | 4-8 | 0-10 | 0 | 15-25 | **~80** |
| 11-20（成长） | 30-60 | 6-12 | 10-25 | 1-2 | 25-40 | **~140** |
| 21-50（挑战） | 60-120 | 8-16 | 20-50 | 2-4 | 40-70 | **~260** |
| 51-100（极限） | 100-200 | 10-20 | 30-60 | 4-6 | 60-100 | **~400** |
| 100+（疯狂） | 150-200+ | 12-24 | 40-80 | 5-8 | 80-120 | **~450** |

**⚠️ 关键瓶颈：波次51+阶段，同屏实体可能达到400-450个**

### 1.3 性能预算分配（60FPS = 16.67ms/帧）

| 系统 | 预算时间 | 占比 | 说明 |
|------|----------|------|------|
| **物理碰撞** | 4.0ms | 24% | 200敌人的碰撞检测 |
| **AI计算** | 3.0ms | 18% | 敌人行为、寻路 |
| **渲染** | 5.0ms | 30% | 精灵、粒子、UI |
| **游戏逻辑** | 2.0ms | 12% | 伤害计算、状态效果 |
| **其他** | 2.67ms | 16% | 存档、音频、GC |
| **总计** | **16.67ms** | **100%** | — |

---

## 2. 同屏200+敌人优化方案

### 2.1 对象池系统（Object Pool）

**核心思想：** 预分配所有敌人实例，运行时只做启用/禁用，避免 `instantiate()` 和 `queue_free()` 的GC压力。

#### 对象池配置

| 池类型 | 初始容量 | 最大扩展 | 单实例内存 | 总内存 |
|--------|----------|----------|-----------|--------|
| 近战敌人 | 80 | 120 | ~4KB | ~480KB |
| 远程敌人 | 40 | 60 | ~5KB | ~300KB |
| 特殊敌人 | 20 | 30 | ~6KB | ~180KB |
| 群体敌人 | 60 | 80 | ~3KB | ~240KB |
| 精英敌人 | 10 | 15 | ~8KB | ~120KB |
| Boss | 3 | 5 | ~15KB | ~75KB |
| **总计** | **213** | **310** | — | **~1.4MB** |

#### 实现方案

```gdscript
# enemy_pool_manager.gd
class_name EnemyPoolManager
extends Node

# 按敌人类型分组的池
var _pools: Dictionary = {}  # {EnemyType: Array[BaseEnemy]}

func initialize pools() -> void:
    # 预分配所有敌人类型
    for enemy_type in EnemyType.values():
        var pool_config = POOL_CONFIGS[enemy_type]
        _pools[enemy_type] = []
        
        for i in pool_config.initial_size:
            var enemy = _create_enemy(enemy_type)
            enemy.set_active(false)
            add_child(enemy)
            _pools[enemy_type].append(enemy)

func spawn(enemy_type: EnemyType, position: Vector2) -> BaseEnemy:
    var pool = _pools[enemy_type]
    
    # 从池中获取
    for enemy in pool:
        if not enemy.is_active():
            enemy.reset(position)
            enemy.set_active(true)
            return enemy
    
    # 池满时的降级策略
    print("Pool exhausted for: ", enemy_type)
    return _handle_pool_exhaustion(enemy_type, position)

func despawn(enemy: BaseEnemy) -> void:
    enemy.set_active(false)
    enemy.set_process(false)
    enemy.set_physics_process(false)
    enemy.visible = false
    enemy.global_position = Vector2(-9999, -9999)  # 移到屏幕外
```

### 2.2 空间分区：四叉树（Quadtree）

**核心思想：** 将碰撞检测从 O(n²) 降低到 O(n log n)。

#### 四叉树配置

| 参数 | 值 | 说明 |
|------|-----|------|
| 最大深度 | 4层 | 平衡精度和性能 |
| 叶节点容量 | 8个实体 | 避免过度细分 |
| 更新频率 | 每物理帧重建 | 或增量更新 |
| 查询范围 | 玩家周围800px | 活跃区域 |

```gdscript
# quadtree.gd
class_name Quadtree
extends RefCounted

const MAX_DEPTH := 4
const MAX_ENTITIES := 8

var _bounds: Rect2
var _entities: Array[Vector2] = []  # 只存位置引用
var _children: Array[Quadtree] = []
var _depth: int

func query_range(range: Rect2) -> Array[Vector2]:
    var result: Array[Vector2] = []
    
    # 快速排除：不相交则返回空
    if not _bounds.intersects(range):
        return result
    
    # 收集当前节点的实体
    for entity_pos in _entities:
        if range.has_point(entity_pos):
            result.append(entity_pos)
    
    # 递归查询子节点
    for child in _children:
        result.append_array(child.query_range(range))
    
    return result
```

#### 碰撞检测优化流程

```
┌─────────────────────────────────────────────────────────┐
│                 每帧碰撞检测流程                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. 查询玩家周围800px范围内的敌人                         │
│     └── 四叉树查询：O(n log n)                          │
│                                                         │
│  2. 过滤掉屏幕外的敌人（休眠区域）                        │
│     └── 只处理活跃区域内的敌人                           │
│                                                         │
│  3. 批量检测：玩家弹幕 ↔ 敌人                            │
│     └── 每个弹幕只检测附近敌人，非全部                   │
│                                                         │
│  4. 批量检测：敌人 ↔ 玩家                                │
│     └── 只检测近战敌人                                  │
│                                                         │
│  5. 批量处理碰撞响应                                    │
│     └── 收集所有碰撞对，一次性处理                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2.3 敌人AI分层降级

| AI层级 | 适用敌人 | 更新频率 | 复杂度 | 适用区域 |
|--------|----------|----------|--------|----------|
| **Level 0** | 虫群、蝙蝠群 | 每5帧 | 无AI，纯追踪 | 全局 |
| **Level 1** | 暗影仆从、骷髅战士 | 每3帧 | 直线追踪+攻击 | 活跃区域 |
| **Level 2** | 骷髅法师、毒蛛女巫 | 每2帧 | 保持距离+射击 | 核心区域 |
| **Level 3** | 暗影骑士、元素领主 | 每帧 | 技能释放+走位 | 核心区域 |
| **Level 4** | Boss | 每帧 | 多阶段+技能组合 | 核心区域 |

#### 区域划分

```
┌─────────────────────────────────────────────┐
│              区域划分策略                     │
├─────────────────────────────────────────────┤
│                                             │
│  核心区域：玩家周围 400×400px                │
│  ├── AI Level 2-4（完整AI）                 │
│  ├── 完整碰撞检测                           │
│  └── 完整渲染                               │
│                                             │
│  活跃区域：玩家周围 800×800px                │
│  ├── AI Level 1-2（简化AI）                 │
│  ├── 碰撞检测（降频）                       │
│  └── 简化渲染                               │
│                                             │
│  边缘区域：玩家周围 1200×1200px              │
│  ├── AI Level 0-1（最小AI）                 │
│  ├── 碰撞检测（每3帧）                      │
│  └── 最小渲染                               │
│                                             │
│  休眠区域：超出 1200px                       │
│  ├── AI暂停                                 │
│  ├── 碰撞暂停                               │
│  └── 不渲染                                 │
│                                             │
└─────────────────────────────────────────────┘
```

### 2.4 流场寻路（Flow Field）

**优势：** 100个敌人共享同一个流场，只需计算一次BFS。

```gdscript
# flow_field.gd
class_name FlowField
extends RefCounted

const CELL_SIZE := 32  # 网格大小
var _grid: Dictionary = {}  # {Vector2i: Vector2}
var _target: Vector2

func update(target: Vector2) -> void:
    if target == _target:
        return  # 目标未变，跳过计算
    
    _target = target
    _grid.clear()
    
    # BFS计算流场
    var queue: Array[Vector2i] = []
    var target_cell = _world_to_cell(target)
    queue.append(target_cell)
    _grid[target_cell] = Vector2.ZERO
    
    while queue.size() > 0:
        var current = queue.pop_front()
        var current_dir = _grid[current]
        
        for neighbor in _get_neighbors(current):
            if not _grid.has(neighbor):
                _grid[neighbor] = (Vector2(current) - Vector2(neighbor)).normalized()
                queue.append(neighbor)

func get_direction(world_pos: Vector2) -> Vector2:
    var cell = _world_to_cell(world_pos)
    return _grid.get(cell, Vector2.ZERO)
```

---

## 3. 弹幕粒子渲染优化

### 3.1 MultiMeshInstance2D 批处理

**核心思想：** 将同类型、同贴图的多个实例合并为一次 draw call。

#### 批处理配置

| 实体类型 | 批处理方式 | 最大实例数 | Draw Call 减少 |
|----------|-----------|-----------|---------------|
| 玩家投射物 | MultiMeshInstance2D | 200 | 从200降至1-2 |
| 敌人投射物 | MultiMeshInstance2D | 150 | 从150降至1-2 |
| 近战敌人 | MultiMeshInstance2D | 120 | 从120降至2-3 |
| 群体敌人 | MultiMeshInstance2D | 80 | 从80降至1-2 |
| 经验球 | MultiMeshInstance2D | 100 | 从100降至1 |
| 伤害数字 | MultiMeshInstance2D | 50 | 从50降至1 |

#### 实现方案

```gdscript
# multi_mesh_batch_renderer.gd
extends MultiMeshInstance2D

@export var max_instances: int = 200

var _multi_mesh: MultiMesh
var _instance_data: Array[Dictionary] = []

func _ready() -> void:
    _multi_mesh = multi_mesh
    _multi_mesh.instance_count = max_instances
    _multi_mesh.visible_instance_count = 0
    _multi_mesh.use_custom_data = true  # 自定义数据（动画帧、颜色等）

func update_batch(entities: Array[Node2D]) -> void:
    var count = mini(entities.size(), max_instances)
    _multi_mesh.visible_instance_count = count
    
    for i in count:
        var entity = entities[i]
        # 更新变换
        var transform = Transform2D(0, entity.global_position)
        _multi_mesh.set_instance_transform_2d(i, transform)
        
        # 更新自定义数据（动画帧、状态等）
        if entity.has_method("get_batch_data"):
            var data = entity.get_batch_data()
            _multi_mesh.set_instance_custom_data(i, data)
```

### 3.2 粒子特效降级策略

| 特效层级 | 适用场景 | 粒子数上限 | 降级策略 |
|----------|----------|-----------|----------|
| **低级** | 经验球拾取、小伤害 | 5-10 | Sprite序列帧替代 |
| **中级** | 法术命中、状态效果 | 15-30 | Godot粒子 |
| **高级** | Boss技能、融合法术 | 50-100 | GPU粒子 |
| **终极** | 元素之王全屏攻击 | 200+ | 预渲染动画 |

#### 动态降级逻辑

```gdscript
# particle_lod_system.gd
extends Node

var _current_quality: int = 2  # 0=低, 1=中, 2=高
var _active_particles: int = 0

func _process(delta: float) -> void:
    if Engine.get_process_frames() % 30 == 0:
        _evaluate_quality()

func _evaluate_quality() -> void:
    var fps = Engine.get_frames_per_second()
    var target_quality = 2
    
    if fps < 45:
        target_quality = 0  # 低质量
    elif fps < 55:
        target_quality = 1  # 中质量
    else:
        target_quality = 2  # 高质量
    
    if target_quality != _current_quality:
        _current_quality = target_quality
        _apply_quality_settings()

func _apply_quality_settings() -> void:
    match _current_quality:
        0:  # 低质量：Sprite替代粒子
            ParticleSystem.max_particles = 50
            ParticleSystem.use_gpu = false
        1:  # 中质量：简化粒子
            ParticleSystem.max_particles = 150
            ParticleSystem.use_gpu = false
        2:  # 高质量：完整粒子
            ParticleSystem.max_particles = 300
            ParticleSystem.use_gpu = true
```

### 3.3 伤害数字优化

**问题：** 大量伤害数字同时显示会造成性能压力。

**解决方案：**

| 策略 | 实现方式 | 效果 |
|------|----------|------|
| **合并显示** | 同一敌人1秒内的多次伤害合并为一个数字 | 减少50%伤害数字 |
| **简化渲染** | 使用 BitmapFont + 位图数字 | 减少渲染开销 |
| **数量限制** | 同屏最多显示 30 个伤害数字 | 稳定帧率 |
| **层级管理** | 低优先级伤害数字在性能差时隐藏 | 动态降级 |

```gdscript
# damage_number_manager.gd
extends Node

const MAX_VISIBLE_NUMBERS := 30
const MERGE_WINDOW := 0.5  # 0.5秒内的伤害合并

var _pending_numbers: Array[Dictionary] = []
var _visible_count: int = 0

func show_damage(target: Node2D, amount: int, is_crit: bool) -> void:
    # 检查是否可以合并
    for pending in _pending_numbers:
        if pending.target == target and (Time.get_ticks_msec() - pending.time) < MERGE_WINDOW * 1000:
            pending.amount += amount
            pending.time = Time.get_ticks_msec()
            return
    
    # 新增伤害数字
    _pending_numbers.append({
        "target": target,
        "amount": amount,
        "is_crit": is_crit,
        "time": Time.get_ticks_msec()
    })
    
    # 限制显示数量
    if _visible_count >= MAX_VISIBLE_NUMBERS:
        _hide_oldest()
```

---

## 4. 60FPS保障策略

### 4.1 帧率监控与自适应调节

```gdscript
# fps_manager.gd
extends Node

var _fps_history: Array[float] = []
var _target_fps: int = 60
var _quality_level: int = 2

func _process(delta: float) -> void:
    _fps_history.append(Engine.get_frames_per_second())
    if _fps_history.size() > 60:  # 保留1秒历史
        _fps_history.pop_front()
    
    if Engine.get_process_frames() % 60 == 0:  # 每秒评估
        _evaluate_performance()

func _evaluate_performance() -> void:
    var avg_fps = _fps_history.reduce(func(a, b): return a + b, 0) / _fps_history.size()
    var min_fps = _fps_history.min()
    
    # 根据最低帧率决定质量级别
    if min_fps < 45:
        _quality_level = 0  # 低质量
        _apply_quality(0)
    elif min_fps < 55:
        _quality_level = 1  # 中质量
        _apply_quality(1)
    elif min_fps > 58 and _quality_level < 2:
        _quality_level = min(_quality_level + 1, 2)  # 逐步提升
        _apply_quality(_quality_level)

func _apply_quality(level: int) -> void:
    match level:
        0:  # 低质量
            ProjectSettings.set_setting("rendering/quality/driver/driver_name", "opengl3")
            ParticleManager.max_particles = 50
            AISystem.update_interval = 5
            RenderSystem.shadows_enabled = false
            RenderSystem.post_processing = false
        1:  # 中质量
            ProjectSettings.set_setting("rendering/quality/driver/driver_name", "vulkan")
            ParticleManager.max_particles = 150
            AISystem.update_interval = 3
            RenderSystem.shadows_enabled = true
            RenderSystem.post_processing = false
        2:  # 高质量
            ProjectSettings.set_setting("rendering/quality/driver/driver_name", "vulkan")
            ParticleManager.max_particles = 300
            AISystem.update_interval = 1
            RenderSystem.shadows_enabled = true
            RenderSystem.post_processing = true
```

### 4.2 渲染层优化

| 层级 | 内容 | Draw Call | 优化策略 |
|------|------|----------|----------|
| Layer 0 | 背景 | 1 | 静态纹理 |
| Layer 1 | 地形装饰 | 2-3 | 图集合并 |
| Layer 2 | 实体层 | 5-8 | MultiMesh批处理 |
| Layer 3 | 特效层 | 3-5 | 粒子降级 |
| Layer 4 | UI层 | 2-3 | 静态UI缓存 |
| **总计** | — | **13-20** | 目标 ≤ 25 |

### 4.3 视锥剔除（Frustum Culling）

```gdscript
# visibility_optimizer.gd
extends Node

var _camera: Camera2D
var _visible_rect: Rect2

func _process(delta: float) -> void:
    # 更新可视区域
    var viewport_size = get_viewport().size
    var zoom = _camera.zoom
    var camera_pos = _camera.global_position
    
    _visible_rect = Rect2(
        camera_pos - viewport_size / (2 * zoom),
        viewport_size / zoom
    )
    
    # 扩展100px边距，避免弹出
    _visible_rect = _visible_rect.grow(100)

func is_visible(world_pos: Vector2) -> bool:
    return _visible_rect.has_point(world_pos)

func get_visible_enemies() -> Array[BaseEnemy]:
    return EnemyManager.get_enemies_in_rect(_visible_rect)
```

---

## 5. 无限波次模式特殊优化

### 5.1 内存稳定性保障

**问题：** 无限波次意味着游戏可能运行数小时，内存必须稳定。

**解决方案：**

| 策略 | 实现方式 | 效果 |
|------|----------|------|
| **对象池** | 所有实体预分配 | 避免运行时分配 |
| **流场缓存** | 玩家静止时缓存流场 | 减少计算 |
| **GC控制** | 每波结束时手动GC | 避免帧率波动 |
| **资源卸载** | 未使用的资源及时释放 | 控制内存增长 |

```gdscript
# memory_manager.gd
extends Node

var _last_gc_time: float = 0
const GC_INTERVAL := 30.0  # 每30秒检查一次

func _process(delta: float) -> void:
    _last_gc_time += delta
    
    if _last_gc_time >= GC_INTERVAL:
        _perform_maintenance()
        _last_gc_time = 0

func _perform_maintenance() -> void:
    # 1. 回收非活跃实体池
    EnemyPoolManager.trim_inactive(0.3)  # 保留30%备用
    
    # 2. 清理过期的流场缓存
    FlowFieldManager.cleanup_stale()
    
    # 3. 压缩存档数据
    SaveManager.compress_cache()
    
    # 4. 强制GC（Godot 4.x）
    OS.request_permissions()  # 触发GC
```

### 5.2 波次间性能平滑

**问题：** 波次切换时可能有大量实体同时创建/销毁，造成帧率波动。

**解决方案：**

```gdscript
# wave_transition_manager.gd
extends Node

var _transition_queue: Array[Dictionary] = []

func on_wave_complete(wave_number: int) -> void:
    # 异步处理波次切换，避免帧率峰值
    _transition_queue.append({
        "wave": wave_number,
        "phase": "cleanup"
    })
    
    # 分帧处理
    await get_tree().process_frame
    _process_transition()

func _process_transition() -> void:
    if _transition_queue.is_empty():
        return
    
    var transition = _transition_queue[0]
    
    match transition.phase:
        "cleanup":
            # 分批回收敌人（每帧最多回收20个）
            var batch = EnemyPoolManager.get_inactive_batch(20)
            for enemy in batch:
                EnemyPoolManager.release(enemy)
            
            if EnemyPoolManager.has_inactive():
                await get_tree().process_frame
                _process_transition()
            else:
                transition.phase = "spawn"
                _process_transition()
        
        "spawn":
            # 分批生成新敌人（每帧最多生成10个）
            var enemies_to_spawn = WaveManager.get_next_wave_enemies()
            var batch_size = mini(enemies_to_spawn.size(), 10)
            
            for i in batch_size:
                var enemy_data = enemies_to_spawn[i]
                EnemyPoolManager.spawn(enemy_data.type, enemy_data.position)
            
            if enemies_to_spawn.size() > batch_size:
                await get_tree().process_frame
                _process_transition()
            else:
                _transition_queue.pop_front()
```

### 5.3 长时间运行稳定性测试

| 测试场景 | 持续时间 | 通过标准 |
|----------|----------|----------|
| **波次50压力测试** | 30分钟 | FPS ≥ 55，内存增长 < 50MB |
| **波次100压力测试** | 1小时 | FPS ≥ 50，内存增长 < 100MB |
| **波次200压力测试** | 2小时 | FPS ≥ 45，内存增长 < 150MB |
| **加速模式测试** | 30分钟 | 3x速度下FPS ≥ 50 |

---

## 6. 加速模式性能适配

### 6.1 加速模式对性能的影响

| 加速等级 | 物理更新频率 | AI更新频率 | 渲染帧率 | 性能影响 |
|----------|-------------|-----------|----------|----------|
| **1x（正常）** | 60Hz | 每帧 | 60 FPS | 基准 |
| **2x（快速）** | 120Hz | 每帧 | 60 FPS | CPU压力×2 |
| **3x（极速）** | 180Hz | 每2帧 | 60 FPS | CPU压力×3 |

### 6.2 加速模式优化策略

```gdscript
# speed_boost_optimizer.gd
extends Node

var _current_speed: int = 1
var _physics_multiplier: float = 1.0

func set_speed(speed: int) -> void:
    _current_speed = speed
    _physics_multiplier = float(speed)
    
    # 调整物理引擎
    Engine.physics_ticks_per_second = 60 * speed
    Engine.max_physics_steps_per_frame = speed
    
    # 调整AI更新频率
    AISystem.update_interval = max(1, speed - 1)  # 2x时每2帧，3x时每3帧
    
    # 调整粒子更新
    ParticleManager.speed_scale = speed
    
    # 调整碰撞检测频率
    CollisionSystem.check_interval = max(1, speed - 1)

func _physics_process(delta: float) -> void:
    # 加速模式下的特殊处理
    if _current_speed >= 2:
        # 减少碰撞检测频率
        if Engine.get_physics_frames() % _current_speed != 0:
            return
        
        # 批量处理碰撞
        _batch_collision_detection()
```

### 6.3 Boss战自动降速

```gdscript
# boss_fight_handler.gd
extends Node

func on_boss_appeared() -> void:
    # Boss战时自动降为1x速度
    if SpeedManager.current_speed > 1:
        SpeedManager.set_speed(1)
        # 显示提示
        UIManager.show_notification("Boss战：速度恢复正常")

func on_boss_defeated() -> void:
    # Boss战结束后恢复之前的速度
    # （可选：不自动恢复，让玩家手动调整）
    pass
```

---

## 7. 存档系统性能优化

### 7.1 异步存档

**问题：** 每波结束自动存档可能造成帧率波动。

**解决方案：**

```gdscript
# async_save_system.gd
extends Node

var _save_queue: Array[Dictionary] = []
var _is_saving: bool = false

func request_save(game_state: Dictionary) -> void:
    _save_queue.append(game_state)
    
    if not _is_saving:
        _process_save_queue()

func _process_save_queue() -> void:
    if _save_queue.is_empty():
        _is_saving = false
        return
    
    _is_saving = true
    var state = _save_queue.pop_front()
    
    # 分帧序列化
    var json_string = JSON.stringify(state)
    await get_tree().process_frame
    
    # 异步写入文件
    var file = FileAccess.open(_get_save_path(state.slot), FileAccess.WRITE)
    file.store_string(json_string)
    file.close()
    
    # 下一帧处理下一个存档
    await get_tree().process_frame
    _process_save_queue()
```

### 7.2 存档数据压缩

| 数据类型 | 原始大小 | 压缩后 | 压缩率 |
|----------|----------|--------|--------|
| 角色状态 | ~2KB | ~1KB | 50% |
| 法术数据 | ~1KB | ~500B | 50% |
| 遗物数据 | ~500B | ~250B | 50% |
| 统计数据 | ~1KB | ~500B | 50% |
| **总计** | **~4.5KB** | **~2.25KB** | **50%** |

### 7.3 存档性能测试

| 测试场景 | 存档大小 | 写入时间 | 帧率影响 |
|----------|----------|----------|----------|
| 波次10 | ~2KB | < 1ms | 无 |
| 波次50 | ~4KB | < 2ms | 无 |
| 波次100 | ~6KB | < 3ms | < 1帧 |
| 波次200 | ~8KB | < 5ms | < 2帧 |

---

## 8. 性能监控与调试

### 8.1 运行时性能面板

```
┌─────────────────────────────────────────────────────┐
│  📊 性能监控面板                                     │
├─────────────────────────────────────────────────────┤
│  FPS: 60.2  │  帧时间: 16.6ms  │  波次: 45         │
├─────────────────────────────────────────────────────┤
│  Draw Calls: 18  │  三角形: 12.5K  │  纹理: 24MB    │
├─────────────────────────────────────────────────────┤
│  实体统计:                                            │
│  ├── 敌人: 180/200 活跃  │  投射物: 45/200 活跃    │
│  ├── 特效: 32/100 活跃   │  拾取物: 67/100 活跃    │
│  └── 总计: 324 活跃实体                             │
├─────────────────────────────────────────────────────┤
│  CPU耗时:                                            │
│  ├── AI计算: 2.3ms (14%)                            │
│  ├── 碰撞检测: 3.1ms (18%)                          │
│  ├── 渲染: 4.2ms (25%)                              │
│  ├── 逻辑: 1.8ms (11%)                              │
│  └── 其他: 5.2ms (31%)                              │
├─────────────────────────────────────────────────────┤
│  内存:                                                │
│  ├── 纹理: 156MB  │  音频: 42MB  │  脚本: 18MB     │
│  └── 总计: 216MB / 1024MB (21%)                     │
├─────────────────────────────────────────────────────┤
│  对象池:                                              │
│  ├── 池命中率: 99.2%  │  池扩展次数: 3              │
│  └── GC次数: 12  │  GC耗时: 0.8ms                   │
└─────────────────────────────────────────────────────┘
```

### 8.2 关键性能指标（KPI）

| 指标 | 目标值 | 告警阈值 | 说明 |
|------|--------|----------|------|
| **帧率** | 60 FPS | < 50 FPS | 核心体验指标 |
| **帧时间** | ≤ 16.67ms | > 20ms | 响应性指标 |
| **同屏实体** | ≤ 200 | > 250 | 实体管理指标 |
| **Draw Calls** | ≤ 25 | > 35 | 渲染效率指标 |
| **内存使用** | ≤ 800MB | > 1200MB | 稳定性指标 |
| **池命中率** | ≥ 95% | < 90% | 对象池效率 |
| **碰撞检测时间** | ≤ 4ms | > 6ms | 碰撞系统指标 |
| **AI计算时间** | ≤ 3ms | > 5ms | AI系统指标 |

### 8.3 性能测试用例

| 测试场景 | 实体数量 | 测试目标 | 通过标准 |
|----------|----------|----------|----------|
| **波次10压力测试** | 30敌人+弹幕 | 正常游戏 | FPS ≥ 58 |
| **波次50压力测试** | 120敌人+弹幕 | 高密度战斗 | FPS ≥ 55 |
| **波次100压力测试** | 200敌人+弹幕 | 极限压力 | FPS ≥ 50 |
| **3x加速测试** | 200敌人 | 加速模式 | FPS ≥ 50 |
| **内存泄漏测试** | 2小时连续游戏 | 稳定性 | 内存增长 < 100MB |
| **Boss战测试** | Boss+15敌人+特效 | 复杂战斗 | FPS ≥ 55 |

---

## 9. 实现路线图

### Phase 1：基础优化（第1-4周）

| 任务 | 优先级 | 预估工时 | 依赖 |
|------|--------|----------|------|
| 实现对象池系统 | P0 | 3天 | 无 |
| 基础四叉树碰撞 | P0 | 2天 | 无 |
| 视锥剔除实现 | P1 | 1天 | 无 |
| 基础性能面板 | P1 | 1天 | 无 |
| 纹理图集合并 | P1 | 1天 | 无 |

### Phase 2：核心优化（第5-8周）

| 任务 | 优先级 | 预估工时 | 依赖 |
|------|--------|----------|------|
| MultiMesh批处理 | P0 | 3天 | 对象池 |
| 流场寻路系统 | P1 | 3天 | 无 |
| AI分层降级 | P1 | 2天 | 无 |
| 粒子降级策略 | P2 | 1天 | 性能面板 |
| 内存监控系统 | P2 | 1天 | 无 |

### Phase 3：高级优化（第9-12周）

| 任务 | 优先级 | 预估工时 | 依赖 |
|------|--------|----------|------|
| 异步存档系统 | P1 | 2天 | 无 |
| 自适应性能调节 | P2 | 2天 | 性能面板 |
| 批量伤害计算 | P2 | 1天 | 对象池 |
| 加速模式优化 | P2 | 2天 | 物理系统 |
| 性能测试自动化 | P2 | 2天 | 性能面板 |

### Phase 4：打磨优化（第13-16周）

| 任务 | 优先级 | 预估工时 | 依赖 |
|------|--------|----------|------|
| 内存泄漏修复 | P0 | 持续 | 监控系统 |
| 帧率波动修复 | P1 | 持续 | 监控系统 |
| 低端机型适配 | P2 | 2天 | 自适应系统 |
| 长时间运行测试 | P2 | 3天 | 所有优化完成 |
| 性能文档完善 | P2 | 1天 | 所有优化完成 |

---

## 附录 A：Godot 4.x 性能优化最佳实践

### 推荐做法

| 做法 | 说明 |
|------|------|
| 使用 `PackedScene` | 预打包场景比代码构建更快 |
| 使用 `PackedStringArray` | 批量字符串操作比 `Array[String]` 更快 |
| 避免 `get_node()` | 使用 `@export` 或缓存引用 |
| 使用 `call_deferred()` | 非关键操作延迟执行 |
| 使用 `PhysicsServer2D` | 底层碰撞API比Area2D更高效 |
| 使用 `RenderingServer` | 底层渲染API比Node更高效 |
| 避免 `_process` 中分配内存 | 使用对象池和预分配 |

### 避免做法

| 做法 | 说明 |
|------|------|
| 每帧 `instantiate()` | 严重GC压力 |
| 每帧 `queue_free()` | 内存碎片 |
| 嵌套循环碰撞检测 | O(n²) 性能灾难 |
| 大量 `connect()` | 信号连接开销 |
| 字符串拼接 | 每帧创建新字符串 |
| `print()` 调试输出 | IO阻塞 |

---

## 附录 B：参考项目性能数据

### Brotato（Godot类幸存者游戏）

| 指标 | 数据 |
|------|------|
| 同屏敌人 | 最大 200+ |
| 帧率目标 | 60 FPS |
| 引擎版本 | Godot 3.x |
| 美术风格 | 2D像素 |
| 销售额 | $1070万 |

### Vampire Survivors

| 指标 | 数据 |
|------|------|
| 同屏敌人 | 最大 300+ |
| 帧率目标 | 60 FPS |
| 引擎 | Unity |
| 优化策略 | 对象池+批处理 |

---

**文档结束**

> 本性能优化方案针对"秘法回响"（Grimoire Echoes）的无限波次模式量身定制，重点解决同屏200+敌人、大量弹幕粒子、60FPS保障三大核心挑战。方案涵盖对象池、四叉树碰撞、MultiMesh批处理、流场寻路、粒子降级、自适应性能调节等关键技术，确保在最低配置（i5-6600/GTX 960/8GB）下实现流畅的游戏体验。
