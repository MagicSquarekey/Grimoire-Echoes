# 🔮 秘法回响（Grimoire Echoes）— 性能优化方案

> **版本：** v1.0
> **日期：** 2026-08-27
> **引擎：** Godot 4.x
> **分析者：** 性能分析师（performance-analyst）

---

## 目录

1. [性能瓶颈预分析](#1-性能瓶颈预分析)
2. [实体管理系统](#2-实体管理系统)
3. [渲染优化方案](#3-渲染优化方案)
4. [碰撞检测优化](#4-碰撞检测优化)
5. [AI与寻路优化](#5-ai与寻路优化)
6. [内存管理策略](#6-内存管理策略)
7. [粒子与特效优化](#7-粒子与特效优化)
8. [场景加载与切换优化](#8-场景加载与切换优化)
9. [数值系统性能](#9-数值系统性能)
10. [多平台适配预留](#10-多平台适配预留)
11. [性能监控与调试工具](#11-性能监控与调试工具)
12. [分阶段优化路线图](#12-分阶段优化路线图)

---

## 1. 性能瓶颈预分析

### 1.1 实体数量峰值估算

根据设计文档中的波次配置，以下是各阶段的同屏实体数量估算：

| 波次阶段 | 敌人数量 | 玩家弹幕 | 敌人弹幕 | 召唤物 | 粒子特效 | **峰值实体总数** |
|----------|----------|----------|----------|--------|----------|-----------------|
| 1-5（教学） | 8-25 | 2-4 | 0-5 | 0 | 10-20 | **~60** |
| 6-10（成长） | 25-40 | 4-8 | 5-15 | 0-1 | 20-30 | **~100** |
| 11-15（挑战） | 40-55 | 6-12 | 10-25 | 1-2 | 30-50 | **~150** |
| 16-25（激战） | 50-80 | 8-16 | 15-35 | 2-3 | 40-60 | **~200** |
| 26-30（高潮） | 80-100 | 10-20 | 20-40 | 3-4 | 50-80 | **~260** |
| 31-45（极限） | 100-120 | 12-24 | 25-50 | 4-5 | 60-100 | **~320** |
| 46-49（终极） | 120+ | 14-28 | 30-60 | 5-6 | 80-120 | **~370** |
| Boss战 | Boss+10-15 | 10-20 | 20-40 | 2-4 | 60-100 | **~200** |

**⚠️ 关键瓶颈：波次31-49阶段，同屏实体可能达到300-400个**

### 1.2 主要性能瓶颈排序

| 优先级 | 瓶颈类型 | 影响范围 | 预估耗时占比 |
|--------|----------|----------|-------------|
| 🔴 P0 | **实体创建/销毁** | 全局 | 25-35% |
| 🔴 P0 | **碰撞检测** | 全局 | 20-30% |
| 🟡 P1 | **渲染批处理** | 全局 | 15-20% |
| 🟡 P1 | **AI寻路计算** | 敌人系统 | 10-15% |
| 🟢 P2 | **粒子特效** | 战斗系统 | 5-10% |
| 🟢 P2 | **内存分配** | 全局 | 3-5% |
| 🟢 P2 | **序列化/存档** | 存档系统 | 1-2% |

### 1.3 性能目标拆解

| 目标 | 指标 | 实现策略 |
|------|------|----------|
| 60 FPS | 帧时间 ≤ 16.67ms | 实体池 + 碰撞优化 + 渲染批处理 |
| 最低配置 | i5-6600 / GTX 960 / 8GB | 保守内存预算 + 降级方案 |
| 300+同屏实体 | 稳定不卡顿 | 空间分区 + 对象池 + LOD |
| 场景切换 < 3秒 | 加载流畅 | 异步加载 + 资源预加载 |

---

## 2. 实体管理系统

### 2.1 对象池（Object Pool）设计

**核心思想：** 预分配所有可能用到的实体，运行时只做启用/禁用，避免频繁 `queue_free()` 和 `instantiate()`。

#### 对象池架构

```
┌─────────────────────────────────────────────────────────────┐
│                    EntityPoolManager                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Projectile  │  │  Enemy      │  │  Particle   │         │
│  │    Pool     │  │    Pool     │  │    Pool     │         │
│  │  (200个)    │  │  (150个)    │  │  (300个)    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Pickup     │  │  DamageNum  │  │  Summon     │         │
│  │    Pool     │  │    Pool     │  │    Pool     │         │
│  │  (100个)    │  │  (50个)     │  │  (20个)     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
│  池化实体类型：                                              │
│  - PlayerProjectile（玩家投射物）                             │
│  - EnemyProjectile（敌人投射物）                              │
│  - BaseEnemy（基础敌人，各类型子类）                          │
│  - SpellEffect（法术特效）                                   │
│  - PickupItem（拾取物品：经验球、金币、遗物）                  │
│  - DamageNumber（伤害数字）                                  │
│  - SummonEntity（召唤物）                                    │
│  - Environmental（环境对象：陷阱、障碍）                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 对象池实现伪代码

```gdscript
# entity_pool.gd
class_name EntityPool
extends Node

@export var pool_scene: PackedScene
@export var pool_size: int = 100

var _pool: Array[Node] = []
var _active: Array[Node] = []

func _ready() -> void:
    _initialize_pool()

func _initialize_pool() -> void:
    for i in pool_size:
        var entity = pool_scene.instantiate()
        entity.set_process(false)
        entity.set_physics_process(false)
        entity.visible = false
        add_child(entity)
        _pool.append(entity)

func acquire() -> Node:
    var entity: Node
    if _pool.size() > 0:
        entity = _pool.pop_back()
    else:
        # 池耗尽时的降级策略：动态扩展（有上限）
        entity = pool_scene.instantiate()
        add_child(entity)
    
    entity.set_process(true)
    entity.set_physics_process(true)
    entity.visible = true
    _active.append(entity)
    return entity

func release(entity: Node) -> void:
    entity.set_process(false)
    entity.set_physics_process(false)
    entity.visible = false
    entity.global_position = Vector2(-1000, -1000)  # 移到屏幕外
    _active.erase(entity)
    _pool.append(entity)

func get_active_count() -> int:
    return _active.size()

func get_pool_size() -> int:
    return _pool.size()
```

#### 各池预分配大小建议

| 池类型 | 初始大小 | 最大扩展 | 依据 |
|--------|----------|----------|------|
| 玩家投射物 | 200 | 300 | 4法术×多连发×追踪弹 |
| 敌人投射物 | 150 | 250 | 远程怪×连锁闪电 |
| 基础敌人 | 150 | 200 | 波次峰值120+Boss |
| 法术特效 | 100 | 200 | 同时激活的法术效果 |
| 拾取物品 | 100 | 150 | 经验球+金币同时存在 |
| 伤害数字 | 50 | 80 | 同时显示的伤害数字 |
| 召唤物 | 20 | 30 | 藤蔓守卫+暗影分身 |
| 环境对象 | 30 | 50 | 陷阱+可破坏物 |

**内存预算：** 约 750 个预分配实体，每个实体约 2-5KB，总计 ~3MB

### 2.2 实体生命周期管理

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Inactive   │────▶│    Active    │────▶│   Releasing  │
│   (在池中)   │     │  (运行中)    │     │  (回收中)    │
└──────────────┘     └──────────────┘     └──────────────┘
       ▲                    │                     │
       │                    │                     │
       └────────────────────┘                     │
                    (池满则销毁)                    │
       └──────────────────────────────────────────┘
```

**实体状态切换规则：**

| 状态 | 条件 | 操作 |
|------|------|------|
| Inactive → Active | `acquire()` 调用 | 启用处理，设置初始状态 |
| Active → Releasing | 生命归零/出界/超时 | 禁用处理，播放死亡效果 |
| Releasing → Inactive | 死亡动画完成/效果结束 | 重置状态，返回池中 |
| Active → Pool满 | 池已满且有实体需要回收 | 直接销毁最旧的非关键实体 |

---

## 3. 渲染优化方案

### 3.1 MultiMeshInstance2D 批处理

**核心思想：** 将同类型、同贴图的多个实例合并为一次 draw call，大幅减少渲染开销。

#### 适用场景

| 场景 | 实体类型 | 批处理方式 | 预估 draw call 减少 |
|------|----------|-----------|-------------------|
| 敌人群 | 所有近战怪 | MultiMeshInstance2D | 从 100+ 降至 1-3 |
| 经验球 | 经验宝石 | MultiMeshInstance2D | 从 50+ 降至 1 |
| 投射物 | 同元素法术弹 | MultiMeshInstance2D | 从 30+ 降至 2-4 |
| 伤害数字 | 伤害浮字 | MultiMeshInstance2D | 从 50+ 降至 1 |

#### 实现方案

```gdscript
# multi_mesh_enemy_renderer.gd
extends MultiMeshInstance2D

var _enemy_data: Array[Dictionary] = []  # {position, rotation, scale, frame}
var _multi_mesh: MultiMesh

func _ready() -> void:
    _multi_mesh = multi_mesh
    _multi_mesh.instance_count = 150  # 最大敌人数量
    _multi_mesh.visible_instance_count = 0
    _multi_mesh.use_custom_data = true  # 自定义数据（动画帧等）

func update_enemies(enemies: Array[BaseEnemy]) -> void:
    _multi_mesh.visible_instance_count = enemies.size()
    for i in enemies.size():
        var enemy = enemies[i]
        var transform = Transform2D(0, enemy.global_position)
        _multi_mesh.set_instance_transform_2d(i, transform)
        _multi_mesh.set_instance_custom_data(i, Vector4(
            enemy.current_frame,
            enemy.health_percent,
            enemy.element_type,
            enemy.status_effect
        ))
```

### 3.2 视锥剔除（Frustum Culling）

**策略：** 只处理和渲染摄像机可视范围内的实体。

```
┌─────────────────────────────────────────┐
│              游戏世界                     │
│                                         │
│     ┌─────────────────────┐             │
│     │    可视区域          │             │
│     │   (玩家周围)        │             │
│     │                     │             │
│     │    ★ 玩家          │             │
│     │                     │             │
│     └─────────────────────┘             │
│                                         │
│  🔴 屏幕外：不渲染、AI降级              │
│  🟡 屏幕边缘：简化渲染                  │
│  🟢 屏幕中心：完整渲染                  │
└─────────────────────────────────────────┘
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

### 3.3 渲染层级优化

```
Layer 0: 背景层（Background）        - 1 draw call
Layer 1: 地形装饰层（Terrain Deco）  - 2-3 draw calls
Layer 2: 阴影层（Shadow）           - 1 draw call（可选）
Layer 3: 实体层（Entities）         - 5-10 draw calls（MultiMesh）
Layer 4: 特效层（VFX）              - 3-5 draw calls
Layer 5: UI层（HUD）                - 2-3 draw calls
─────────────────────────────────────────────────
总计：约 15-25 draw calls（目标）
```

### 3.4 纹理与图集优化

| 优化项 | 策略 | 效果 |
|--------|------|------|
| **纹理图集** | 同类型精灵合并到一张图集 | 减少纹理切换 |
| **分辨率** | 游戏内精灵使用 128×128 或更小 | 减少显存占用 |
| **压缩格式** | 使用 VRAM 压缩（ASTC/ETC2） | 减少 50-75% 显存 |
| **LOD** | 远处敌人使用低分辨率版本 | 减少渲染负担 |

---

## 4. 碰撞检测优化

### 4.1 空间分区：四叉树（Quadtree）

**核心思想：** 将碰撞检测从 O(n²) 降低到 O(n log n)。

#### 四叉树架构

```
┌─────────────────────────────────────────────┐
│                   World                      │
│  ┌───────────┬───────────┐                  │
│  │   NW      │   NE      │                  │
│  │  ┌──┬──┐  │  ┌──┬──┐  │                  │
│  │  │  │  │  │  │  │  │  │                  │
│  │  ├──┼──┤  │  ├──┼──┤  │                  │
│  │  │  │  │  │  │  │  │  │                  │
│  │  └──┴──┘  │  └──┴──┘  │                  │
│  ├───────────┼───────────┤                  │
│  │   SW      │   SE      │                  │
│  │  ┌──┬──┐  │  ┌──┬──┐  │                  │
│  │  │  │  │  │  │  │  │  │                  │
│  │  ├──┼──┤  │  ├──┼──┤  │                  │
│  │  │  │  │  │  │  │  │  │                  │
│  │  └──┴──┘  │  └──┴──┘  │                  │
│  └───────────┴───────────┘                  │
└─────────────────────────────────────────────┘

最大深度：4层
每叶节点最大实体数：8个
更新频率：每帧重建（或增量更新）
```

#### 实现方案

```gdscript
# spatial_partition.gd
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
```

### 4.2 碰撞检测分层策略

| 检测类型 | 频率 | 空间分区 | 形状简化 |
|----------|------|----------|----------|
| **玩家 ↔ 敌人** | 每物理帧 | 四叉树 | 圆形碰撞 |
| **玩家弹幕 ↔ 敌人** | 每物理帧 | 四叉树 | 圆形碰撞 |
| **敌人弹幕 ↔ 玩家** | 每物理帧 | 四叉树 | 圆形碰撞 |
| **敌人 ↔ 敌人** | 每2物理帧 | 四叉树 | AABB |
| **召唤物 ↔ 敌人** | 每物理帧 | 四叉树 | 圆形碰撞 |
| **玩家 ↔ 地形** | 每物理帧 | 瓦片地图 | AABB |
| **拾取物 ↔ 玩家** | 每3物理帧 | 四叉树 | 圆形碰撞 |

### 4.3 碰撞形状优化

| 实体类型 | 推荐碰撞形状 | 理由 |
|----------|-------------|------|
| 玩家 | 圆形 | 精确度足够，计算最快 |
| 近战敌人 | 圆形 | 简化碰撞判定 |
| 远程敌人 | 圆形 | 简化碰撞判定 |
| 投射物 | 圆形（小） | 高速移动需要小碰撞体 |
| Boss | 多圆形组合 | 复杂形状用多个圆形近似 |
| 地形障碍 | AABB / 线段 | 静态碰撞最高效 |

### 4.4 碰撞响应优化

```gdscript
# collision_response.gd

# 批量碰撞响应：避免每对碰撞单独处理
func process_collisions(collision_pairs: Array[Dictionary]) -> void:
    # 1. 收集所有伤害
    var damage_events: Array[DamageEvent] = []
    for pair in collision_pairs:
        if pair.attacker is PlayerProjectile and pair.defender is BaseEnemy:
            damage_events.append(DamageEvent.new(
                pair.attacker.damage,
                pair.attacker.element,
                pair.defender
            ))
    
    # 2. 批量应用伤害（减少虚方法调用）
    DamageSystem.apply_batch(damage_events)
    
    # 3. 批量播放效果
    VFXSystem.play_batch(damage_events)
    
    # 4. 批量回收投射物
    var to_release: Array[Node] = []
    for pair in collision_pairs:
        if pair.attacker is PlayerProjectile:
            to_release.append(pair.attacker)
    PoolManager.release_batch("projectiles", to_release)
```

---

## 5. AI与寻路优化

### 5.1 敌人AI分层策略

| AI层级 | 适用敌人 | 更新频率 | 复杂度 |
|--------|----------|----------|--------|
| **Level 0: 被动** | 虫群、蝙蝠群 | 每5帧 | 无AI，纯追踪 |
| **Level 1: 基础** | 暗影仆从、骷髅战士 | 每3帧 | 直线追踪+攻击 |
| **Level 2: 标准** | 骷髅法师、毒蛛女巫 | 每2帧 | 保持距离+射击 |
| **Level 3: 精英** | 暗影骑士、元素领主 | 每帧 | 技能释放+走位 |
| **Level 4: Boss** | 熔岩巨人、暗影君主 | 每帧 | 多阶段+技能组合 |

#### AI降级策略

```
┌─────────────────────────────────────────────┐
│              AI降级决策树                     │
├─────────────────────────────────────────────┤
│                                             │
│  实体在核心区域内？                          │
│  ├── 是 → 完整AI（Level 4）                 │
│  └── 否 → 实体在活跃区域内？                │
│           ├── 是 → 简化AI（Level 2-3）      │
│           └── 否 → 实体在边缘区域内？       │
│                    ├── 是 → 最小AI（Level 1）│
│                    └── 否 → AI暂停           │
│                                             │
└─────────────────────────────────────────────┘
```

### 5.2 寻路优化

#### 群体寻路（Crowd Navigation）

**策略：** 使用流场（Flow Field）代替逐体寻路。

```
┌─────────────────────────────────────────────┐
│              流场寻路示意                     │
├─────────────────────────────────────────────┤
│                                             │
│  玩家位置：★                                │
│                                             │
│  → → → → ↘ ↓ ↓ ↓                           │
│  → → → ↘ ↓ ↓ ↓ ↓                           │
│  → → ↘ ↓ ↓ ★ ↓ ↓                           │
│  → → → ↘ ↓ ↓ ↓ ↓                           │
│  → → → → ↘ ↓ ↓ ↓                           │
│                                             │
│  所有敌人共享同一个流场                       │
│  只需计算一次，所有敌人查表即可获得移动方向    │
│                                             │
└─────────────────────────────────────────────┘
```

**流场优势：**

| 对比项 | 逐体寻路（A*） | 流场（Flow Field） |
|--------|---------------|-------------------|
| 100个敌人 | 100次A*计算 | 1次BFS计算 |
| 计算复杂度 | O(n × m) | O(m) |
| 适合场景 | 敌人少、路径独立 | 敌人多、目标相同 |
| 内存占用 | 低 | 中（存储方向向量） |

**推荐配置：**

| 参数 | 值 | 说明 |
|------|-----|------|
| 流场网格大小 | 32×32px | 平衡精度和性能 |
| 更新频率 | 每0.5秒 | 玩家移动时才更新 |
| 缓存策略 | 玩家静止时缓存 | 减少不必要的计算 |

### 5.3 状态机优化

```gdscript
# enemy_ai_optimizer.gd

# 使用位掩码标记AI状态，减少虚方法调用
enum AIState {
    IDLE      = 0,
    CHASE     = 1,
    ATTACK    = 2,
    FLEE      = 3,
    CAST      = 4,
    DEAD      = 5,
    PAUSED    = 6  # 屏幕外AI暂停
}

func _physics_process(delta: float) -> void:
    # 快速跳过：AI暂停的敌人不处理
    if _current_state == AIState.PAUSED:
        return
    
    # 根据距离决定AI更新频率
    var dist_to_camera = global_position.distance_to(_camera_center)
    if dist_to_camera > 1200:
        return  # 超出边缘区域，完全跳过
    
    var should_update = false
    match _ai_level:
        0: should_update = Engine.get_physics_frames() % 5 == 0
        1: should_update = Engine.get_physics_frames() % 3 == 0
        2: should_update = Engine.get_physics_frames() % 2 == 0
        3, 4: should_update = true
    
    if should_update:
        _update_ai(delta)
```

---

## 6. 内存管理策略

### 6.1 内存预算分配

| 类别 | 预算 | 说明 |
|------|------|------|
| **纹理资源** | 512 MB | 角色、敌人、UI、地形 |
| **音频资源** | 128 MB | 音乐、音效 |
| **对象池** | 8 MB | 750个实体×~10KB |
| **场景数据** | 64 MB | 5张地图的瓦片数据 |
| **临时数据** | 32 MB | 寻路缓存、伤害计算 |
| **脚本对象** | 16 MB | GDScript运行时 |
| **系统开销** | 256 MB | Godot引擎+OS |
| **总计** | **~1 GB** | 8GB配置下的预算 |

### 6.2 资源加载策略

```
┌─────────────────────────────────────────────────────┐
│                 资源加载生命周期                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  [启动时预加载]                                      │
│  ├── 主菜单UI资源                                   │
│  ├── 角色选择界面资源                                │
│  ├── 基础敌人模板（5种）                             │
│  └── 基础法术特效（6种）                             │
│                                                     │
│  [地图加载时]                                        │
│  ├── 地图瓦片集                                     │
│  ├── 该地图敌人类型资源                              │
│  ├── 该地图环境特效                                  │
│  └── Boss资源（如果是Boss波）                       │
│                                                     │
│  [运行时动态加载]                                    │
│  ├── 遗物图标（按需）                                │
│  ├── 高级法术特效（解锁时）                          │
│  └── 成就图标（按需）                                │
│                                                     │
│  [卸载时机]                                          │
│  ├── 地图切换时卸载上一张地图资源                     │
│  ├── 返回主菜单时卸载战斗资源                        │
│  └── 内存不足时强制卸载非必需资源                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 6.3 内存碎片预防

| 策略 | 实现方式 | 效果 |
|------|----------|------|
| **预分配** | 对象池预先分配所有实体 | 避免运行时分配 |
| **栈分配** | 使用 `PackedArray` 存储批量数据 | 减少堆碎片 |
| **字符串池** | 常用字符串预定义为常量 | 减少字符串分配 |
| **避免闭包** | AI逻辑使用状态机而非lambda | 减少意外引用 |

### 6.4 垃圾回收优化

```gdscript
# 内存监控器
func _process(delta: float) -> void:
    if Engine.get_process_frames() % 60 == 0:  # 每秒检查一次
        var mem_usage = OS.get_memory_info()
        var used_mb = mem_usage.physical / (1024 * 1024)
        
        if used_mb > 1500:  # 超过1.5GB警告
            _trigger_memory_cleanup()
        elif used_mb > 1800:  # 超过1.8GB强制清理
            _force_memory_cleanup()

func _trigger_memory_cleanup() -> void:
    # 1. 回收所有非活跃实体池
    PoolManager.trim_pools(0.5)  # 保留50%
    
    # 2. 卸载未使用的资源
    ResourceLoader.get_cached_ref_count()
    
    # 3. 强制GC
    OS.request_permissions()

func _force_memory_cleanup() -> void:
    # 紧急情况：销毁所有池化实体，重新预分配
    PoolManager.destroy_all()
    PoolManager.initialize_all()
    print_rich("[color=red]紧急内存清理完成[/color]")
```

---

## 7. 粒子与特效优化

### 7.1 粒子系统层级

| 特效层级 | 适用场景 | 粒子数上限 | 优化策略 |
|----------|----------|-----------|----------|
| **低级** | 经验球拾取、小伤害 | 5-10 | Sprite序列帧 |
| **中级** | 法术命中、状态效果 | 15-30 | Godot粒子 |
| **高级** | Boss技能、融合法术 | 50-100 | GPU粒子 |
| **终极** | 元素之王全屏攻击 | 200+ | 预渲染动画 |

### 7.2 粒子降级策略

```
┌─────────────────────────────────────────────┐
│              粒子降级决策                     │
├─────────────────────────────────────────────┤
│                                             │
│  当前FPS ≥ 55？                             │
│  ├── 是 → 完整粒子效果                      │
│  └── 否 → 当前FPS ≥ 45？                   │
│           ├── 是 → 粒子数减半               │
│           └── 否 → 使用Sprite替代粒子       │
│                                             │
│  同屏粒子总数 > 500？                        │
│  ├── 是 → 新粒子使用Sprite替代              │
│  └── 否 → 正常创建粒子                      │
│                                             │
└─────────────────────────────────────────────┘
```

### 7.3 伤害数字优化

**问题：** 大量伤害数字同时显示会造成性能压力。

**解决方案：**

| 策略 | 实现方式 |
|------|----------|
| **合并显示** | 同一敌人1秒内的多次伤害合并为一个数字 |
| **简化渲染** | 使用 BitmapFont + 位图数字 |
| **数量限制** | 同屏最多显示 30 个伤害数字 |
| **层级管理** | 低优先级伤害数字在性能差时隐藏 |

---

## 8. 场景加载与切换优化

### 8.1 异步加载流程

```
┌─────────────────────────────────────────────────────┐
│                 场景切换流程                          │
├─────────────────────────────────────────────────────┤
│                                                     │
│  [当前场景] ──▶ [过渡动画] ──▶ [新场景]              │
│                    │                                │
│                    ▼                                │
│              [异步加载]                              │
│              ├── 加载地图瓦片                       │
│              ├── 加载敌人模板                       │
│              ├── 加载法术资源                       │
│              └── 预热对象池                         │
│                    │                                │
│                    ▼                                │
│              [加载完成] ──▶ [淡入新场景]             │
│                                                     │
│  总目标时间：< 3秒                                   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 8.2 地图数据优化

| 优化项 | 策略 | 效果 |
|--------|------|------|
| **瓦片压缩** | 使用 RLE 压缩瓦片数据 | 减少 60% 地图大小 |
| **图集合并** | 每张地图一张瓦片图集 | 减少纹理切换 |
| **LOD瓦片** | 远处使用低分辨率瓦片 | 减少渲染负担 |
| **分块加载** | 大地图分块异步加载 | 减少单次加载量 |

### 8.3 资源预加载提示

```gdscript
# 预加载管理器
func preload_map_resources(map_id: int) -> void:
    var progress = 0.0
    var steps = [
        ["res://maps/%d/tileset.tres" % map_id, 0.3],
        ["res://maps/%d/environment.tscn" % map_id, 0.2],
        ["res://enemies/templates_%d.tres" % map_id, 0.3],
        ["res://vfx/map_%d_effects.tres" % map_id, 0.2],
    ]
    
    for step in steps:
        ResourceLoader.load_threaded_request(step[0])
        progress += step[1]
        _update_loading_progress(progress)
    
    # 等待所有资源加载完成
    for step in steps:
        while ResourceLoader.load_threaded_get_status(step[0]) != ResourceLoader.THREAD_LOAD_LOADED:
            await get_tree().process_frame
```

---

## 9. 数值系统性能

### 9.1 伤害计算优化

**问题：** 法术伤害公式涉及多个乘数，大量实体时计算量大。

**优化策略：**

| 策略 | 实现方式 | 效果 |
|------|----------|------|
| **缓存乘数** | 角色属性变化时重新计算基础乘数 | 减少重复计算 |
| **批量计算** | 一次法术命中多个敌人时批量计算 | 减少虚方法调用 |
| **预计算表** | 法术等级倍率预计算为数组 | 避免运行时乘法 |
| **整数运算** | 伤害值使用整数（×100）避免浮点 | 提升计算速度 |

```gdscript
# 伤害计算器优化
class_name DamageCalculator

# 预计算的等级倍率表（避免运行时计算）
const SPELL_LEVEL_MULTIPLIERS: Array[float] = [
    1.00, 1.08, 1.16, 1.24, 1.40,  # Lv.1-5
    1.52, 1.64, 1.76, 1.88, 2.20,  # Lv.6-10
    2.40, 2.60, 2.80, 3.00, 3.50,  # Lv.11-15
    3.80, 4.10, 4.40, 4.70, 5.50   # Lv.16-20
]

# 缓存的角色属性
var _cached_attack_multiplier: float = 1.0
var _cached_element_bonus: float = 1.0
var _cache_dirty: bool = true

func invalidate_cache() -> void:
    _cache_dirty = true

func calculate_damage(spell: SpellData, level: int, is_crit: bool) -> int:
    if _cache_dirty:
        _recalculate_cache()
    
    var base = spell.base_damage
    var level_mult = SPELL_LEVEL_MULTIPLIERS[clampi(level - 1, 0, 19)]
    var result = base * level_mult * _cached_attack_multiplier * _cached_element_bonus
    
    if is_crit:
        result *= _cached_crit_multiplier
    
    return int(result)  # 使用整数避免浮点误差
```

### 9.2 状态效果管理

**批量状态效果处理：**

```gdscript
# 状态效果批处理器
class_name StatusEffectBatchProcessor

var _active_effects: Array[StatusEffect] = []

func process_all(delta: float) -> void:
    # 按类型分组处理，减少分支预测失败
    var burn_effects: Array[StatusEffect] = []
    var slow_effects: Array[StatusEffect] = []
    var freeze_effects: Array[StatusEffect] = []
    
    for effect in _active_effects:
        match effect.type:
            StatusType.BURN: burn_effects.append(effect)
            StatusType.SLOW: slow_effects.append(effect)
            StatusType.FREEZE: freeze_effects.append(effect)
    
    # 批量处理同类型效果
    _process_burns(burn_effects, delta)
    _process_slows(slow_effects, delta)
    _process_freezes(freeze_effects, delta)
    
    # 清理过期效果
    _cleanup_expired()
```

---

## 10. 多平台适配预留

### 10.1 性能降级配置

| 配置项 | 低配（GTX 960） | 中配（GTX 1660） | 高配（RTX 3060+） |
|--------|----------------|-----------------|-------------------|
| **分辨率** | 1280×720 | 1920×1080 | 1920×1080+ |
| **粒子质量** | 低 | 中 | 高 |
| **阴影** | 关闭 | 简单阴影 | 完整阴影 |
| **后处理** | 关闭 | 基础 | 完整 |
| **同屏实体** | 最大 200 | 最大 300 | 最大 400 |
| **AI更新频率** | 每5帧 | 每3帧 | 每帧 |
| **流场精度** | 64×64px | 32×32px | 16×16px |

### 10.2 自适应性能调节

```gdscript
# 性能自适应系统
class_name PerformanceAdaptiveSystem

var _target_fps: int = 60
var _current_quality: int = 2  # 0=低, 1=中, 2=高

func _process(delta: float) -> void:
    if Engine.get_process_frames() % 30 == 0:  # 每0.5秒检查
        var fps = Engine.get_frames_per_second()
        
        if fps < 50 and _current_quality > 0:
            _current_quality -= 1
            _apply_quality_settings()
        elif fps > 58 and _current_quality < 2:
            _current_quality += 1
            _apply_quality_settings()

func _apply_quality_settings() -> void:
    match _current_quality:
        0:  # 低质量
            ParticleManager.set_max_particles(200)
            AISystem.set_update_frequency(5)
            RenderSystem.set_shadow_enabled(false)
        1:  # 中质量
            ParticleManager.set_max_particles(400)
            AISystem.set_update_frequency(3)
            RenderSystem.set_shadow_enabled(true)
        2:  # 高质量
            ParticleManager.set_max_particles(800)
            AISystem.set_update_frequency(1)
            RenderSystem.set_shadow_enabled(true)
```

---

## 11. 性能监控与调试工具

### 11.1 运行时性能面板

```
┌─────────────────────────────────────────────────────┐
│  📊 性能监控面板                                     │
├─────────────────────────────────────────────────────┤
│  FPS: 60.2  │  帧时间: 16.6ms  │  实体数: 287      │
├─────────────────────────────────────────────────────┤
│  Draw Calls: 18  │  三角形: 12.5K  │  纹理: 24MB    │
├─────────────────────────────────────────────────────┤
│  CPU:                                                    │
│  ├── AI计算: 2.3ms (14%)                               │
│  ├── 碰撞检测: 3.1ms (18%)                             │
│  ├── 渲染: 4.2ms (25%)                                 │
│  ├── 逻辑: 1.8ms (11%)                                 │
│  └── 其他: 5.2ms (31%)                                 │
├─────────────────────────────────────────────────────┤
│  内存:                                                    │
│  ├── 纹理: 156MB  │  音频: 42MB  │  脚本: 18MB      │
│  └── 总计: 216MB / 1024MB (21%)                        │
├─────────────────────────────────────────────────────┤
│  对象池:                                                  │
│  ├── 投射物: 45/200 活跃  │  敌人: 120/150 活跃     │
│  ├── 特效: 32/100 活跃    │  拾取物: 67/100 活跃     │
│  └── 池命中率: 99.2%                                   │
└─────────────────────────────────────────────────────┘
```

### 11.2 关键性能指标（KPI）

| 指标 | 目标值 | 告警阈值 | 说明 |
|------|--------|----------|------|
| **帧率** | 60 FPS | < 50 FPS | 核心体验指标 |
| **帧时间** | ≤ 16.67ms | > 20ms | 响应性指标 |
| **同屏实体** | ≤ 300 | > 350 | 实体管理指标 |
| **Draw Calls** | ≤ 25 | > 35 | 渲染效率指标 |
| **内存使用** | ≤ 800MB | > 1200MB | 稳定性指标 |
| **池命中率** | ≥ 95% | < 90% | 对象池效率 |
| **碰撞检测时间** | ≤ 4ms | > 6ms | 碰撞系统指标 |
| **AI计算时间** | ≤ 3ms | > 5ms | AI系统指标 |

### 11.3 性能测试用例

| 测试场景 | 实体数量 | 测试目标 | 通过标准 |
|----------|----------|----------|----------|
| **压力测试** | 500个敌人 | 极限性能 | FPS ≥ 30 |
| **波次31** | 120敌人+弹幕 | 正常游戏 | FPS ≥ 55 |
| **Boss战** | Boss+15敌人+特效 | 复杂战斗 | FPS ≥ 50 |
| **内存泄漏** | 30分钟连续游戏 | 稳定性 | 内存增长 < 100MB |
| **场景切换** | 5张地图切换 | 加载速度 | 切换 < 3秒 |

---

## 12. 分阶段优化路线图

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
| 异步场景加载 | P1 | 2天 | 无 |
| 自适应性能调节 | P2 | 2天 | 性能面板 |
| 批量伤害计算 | P2 | 1天 | 对象池 |
| 批量状态效果 | P2 | 1天 | 无 |
| 性能测试自动化 | P2 | 2天 | 性能面板 |

### Phase 4：打磨优化（第13-16周）

| 任务 | 优先级 | 预估工时 | 依赖 |
|------|--------|----------|------|
| 内存泄漏修复 | P0 | 持续 | 监控系统 |
| 帧率波动修复 | P1 | 持续 | 监控系统 |
| 低端机型适配 | P2 | 2天 | 自适应系统 |
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

> 本性能优化方案为"秘法回响"（Grimoire Echoes）提供全面的性能优化指导，涵盖实体管理、渲染、碰撞、AI、内存等关键领域。方案根据Godot 4.x引擎特性和类幸存者游戏特点量身定制，确保在目标配置下实现60 FPS的流畅体验。
