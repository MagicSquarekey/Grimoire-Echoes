## MapDataGenerator - 地图数据生成器
## 根据地图数据动态创建地图资源
class_name MapDataGenerator
extends RefCounted

## 地图数据
class MapData:
    var id: String
    var name: String
    var description: String
    var theme: MapResource.MapTheme
    var unlock_condition: String
    var map_size: Vector2i
    var tile_size: int
    var ambient_color: Color
    var fog_density: float
    var music_track: String
    var special_mechanics: Array[MapResource.MapMechanic]
    var hidden_areas: Array[MapResource.HiddenArea]
    var boss_waves: Array[int]
    
    func _init(
        _id: String,
        _name: String,
        _description: String,
        _theme: MapResource.MapTheme,
        _unlock_condition: String,
        _map_size: Vector2i,
        _tile_size: int = 64,
        _ambient_color: Color = Color.WHITE,
        _fog_density: float = 0.0,
        _music_track: String = "",
        _special_mechanics: Array[MapResource.MapMechanic] = [],
        _hidden_areas: Array[MapResource.HiddenArea] = [],
        _boss_waves: Array[int] = []
    ) -> void:
        id = _id
        name = _name
        description = _description
        theme = _theme
        unlock_condition = _unlock_condition
        map_size = _map_size
        tile_size = _tile_size
        ambient_color = _ambient_color
        fog_density = _fog_density
        music_track = _music_track
        special_mechanics = _special_mechanics
        hidden_areas = _hidden_areas
        boss_waves = _boss_waves

## 地图数据表（5张地图）
const MAP_DATA: Array[MapData] = [
    # M1：幽暗森林
    MapData.new(
        "forest", "幽暗森林", "开放式森林，有树木作为掩体",
        MapResource.MapTheme.FOREST, "初始解锁",
        Vector2i(120, 120), 64,
        Color(0.8, 0.9, 0.7), 0.1, "forest_music",
        [
            MapResource.MapMechanic.new(
                "vine_trap", "藤蔓陷阱", "随机位置的藤蔓会缠绕玩家1秒",
                MapResource.TriggerType.AREA, 10.0,
                {"damage": 5, "duration": 1.0}
            ),
            MapResource.MapMechanic.new(
                "poison_fog", "毒雾区域", "地图边缘有绿色毒雾，进入后持续掉血",
                MapResource.TriggerType.AREA, 0.0,
                {"damage_per_second": 3, "area": "edge"}
            )
        ],
        [
            MapResource.HiddenArea.new(
                "forest_hidden", "隐藏区域", "需要摧毁特定树木才能进入",
                Vector2(-800, 600), "destroy_specific_tree",
                ["chest", "elite_enemy"]
            )
        ],
        [15, 30, 50]
    ),
    
    # M2：熔岩裂谷
    MapData.new(
        "lava", "熔岩裂谷", "狭窄的峡谷，中间有熔岩河流",
        MapResource.MapTheme.LAVA, "通关M1",
        Vector2i(100, 150), 64,
        Color(0.9, 0.7, 0.5), 0.2, "lava_music",
        [
            MapResource.MapMechanic.new(
                "lava_river", "岩浆河流", "踩在熔岩上每秒受到10点伤害",
                MapResource.TriggerType.AREA, 0.0,
                {"damage_per_second": 10, "slow_effect": 0.3}
            ),
            MapResource.MapMechanic.new(
                "lava_geyser", "岩浆泉", "每5秒喷发一次，向周围发射3枚火球",
                MapResource.TriggerType.TIMED, 5.0,
                {"projectile_count": 3, "damage": 20}
            ),
            MapResource.MapMechanic.new(
                "heat_wave", "热浪效果", "每30秒全屏热浪，所有敌人获得10%伤害加成",
                MapResource.TriggerType.TIMED, 30.0,
                {"enemy_damage_bonus": 0.10, "duration": 10.0}
            )
        ],
        [
            MapResource.HiddenArea.new(
                "lava_hidden", "隐藏区域", "需要从熔岩河流中找到安全路径",
                Vector2(600, 0), "find_safe_path",
                ["legendary_chest", "2x_elite_enemy"]
            )
        ],
        [15, 30, 50]
    ),
    
    # M3：冰封山脉
    MapData.new(
        "ice", "冰封山脉", "开阔的雪原，有冰川和雪堆",
        MapResource.MapTheme.ICE, "通关M2",
        Vector2i(110, 110), 64,
        Color(0.9, 0.95, 1.0), 0.3, "ice_music",
        [
            MapResource.MapMechanic.new(
                "ice_surface", "冰面滑行", "在冰面上移动时惯性增加，难以急停",
                MapResource.TriggerType.AREA, 0.0,
                {"friction": 0.3, "inertia_multiplier": 2.0}
            ),
            MapResource.MapMechanic.new(
                "blizzard", "暴风雪", "每60秒触发暴风雪，视野范围缩小50%，持续15秒",
                MapResource.TriggerType.TIMED, 60.0,
                {"vision_reduction": 0.5, "duration": 15.0}
            ),
            MapResource.MapMechanic.new(
                "ice_spike", "冰锥", "地图上随机位置会掉落冰锥，造成范围伤害",
                MapResource.TriggerType.TIMED, 5.0,
                {"damage": 25, "area_radius": 100}
            )
        ],
        [
            MapResource.HiddenArea.new(
                "ice_hidden", "隐藏区域", "需要被暴风雪吹到特定位置",
                Vector2(0, -800), "blow_to_position",
                ["rare_relic", "ice_elemental_elite"]
            )
        ],
        [15, 30, 50]
    ),
    
    # M4：暗影深渊
    MapData.new(
        "shadow_realm", "暗影深渊", "地下迷宫，有走廊和房间",
        MapResource.MapTheme.SHADOW, "通关M3",
        Vector2i(80, 80), 64,
        Color(0.3, 0.3, 0.4), 0.8, "shadow_music",
        [
            MapResource.MapMechanic.new(
                "vision_limit", "视野限制", "正常视野范围缩小60%，只能看到附近区域",
                MapResource.TriggerType.AREA, 0.0,
                {"vision_reduction": 0.6, "always_active": true}
            ),
            MapResource.MapMechanic.new(
                "teleporters", "传送门", "地图上有3个传送门，随机传送玩家到其他位置",
                MapResource.TriggerType.INTERACTIVE, 0.0,
                {"count": 3, "random_destination": true}
            ),
            MapResource.MapMechanic.new(
                "shadow_creatures", "暗影生物", "该地图特有敌人，只在黑暗中出现",
                MapResource.TriggerType.AREA, 0.0,
                {"only_in_dark": true, "spawn_in_hidden_areas": true}
            )
        ],
        [
            MapResource.HiddenArea.new(
                "shadow_hidden", "隐藏区域", "需要找到隐藏开关",
                Vector2(0, 0), "find_hidden_switch",
                ["legendary_chest", "shadow_boss"]
            )
        ],
        [15, 30, 50]
    ),
    
    # M5：元素祭坛
    MapData.new(
        "altar", "元素祭坛", "圆形祭坛，中心是最终Boss战区域",
        MapResource.MapTheme.ELEMENTAL, "通关M4+所有契约",
        Vector2i(90, 90), 64,
        Color(1.0, 1.0, 1.0), 0.0, "altar_music",
        [
            MapResource.MapMechanic.new(
                "elemental_zones", "元素区域", "地图被分为6个元素区域，站在对应区域获得元素加成",
                MapResource.TriggerType.AREA, 0.0,
                {"zones": ["fire", "water", "lightning", "nature", "shadow", "wind"], "bonus_damage": 0.15}
            ),
            MapResource.MapMechanic.new(
                "elemental_storm", "元素风暴", "每45秒随机元素风暴席卷地图，非对应元素敌人受到额外伤害",
                MapResource.TriggerType.TIMED, 45.0,
                {"random_element": true, "extra_damage_to_non_matching": 0.25}
            ),
            MapResource.MapMechanic.new(
                "altar_activation", "祭坛激活", "激活所有6个元素祭坛后，解锁隐藏Boss",
                MapResource.TriggerType.INTERACTIVE, 0.0,
                {"required_count": 6, "unlocks_hidden_boss": true}
            )
        ],
        [
            MapResource.HiddenArea.new(
                "altar_hidden", "隐藏区域", "需要激活所有6个元素祭坛",
                Vector2(0, 0), "activate_all_altars",
                ["hidden_boss_elemental_spirit", "hidden_spell"]
            )
        ],
        [50, 100, 150]
    )
]

## 创建地图资源
static func create_map_resource(map_id: String) -> MapResource:
    var data = _get_map_data_by_id(map_id)
    if data == null:
        push_warning("Map data not found: " + map_id)
        return null
    
    var resource = MapResource.new()
    resource.id = data.id
    resource.name = data.name
    resource.description = data.description
    resource.theme = data.theme
    resource.unlock_condition = data.unlock_condition
    resource.map_size = data.map_size
    resource.tile_size = data.tile_size
    resource.ambient_color = data.ambient_color
    resource.fog_density = data.fog_density
    resource.music_track = data.music_track
    resource.special_mechanics = data.special_mechanics.duplicate()
    resource.hidden_areas = data.hidden_areas.duplicate()
    resource.boss_waves = data.boss_waves.duplicate()
    
    return resource

## 获取地图数据
static func _get_map_data_by_id(map_id: String) -> MapData:
    for data in MAP_DATA:
        if data.id == map_id:
            return data
    return null

## 获取所有地图数据
static func get_all_map_data() -> Array[MapData]:
    return MAP_DATA

## 根据主题获取地图数据
static func get_map_data_by_theme(theme: MapResource.MapTheme) -> Array[MapData]:
    var result: Array[MapData] = []
    for data in MAP_DATA:
        if data.theme == theme:
            result.append(data)
    return result

## 获取森林地图数据
static func get_forest_map_data() -> MapData:
    return _get_map_data_by_id("forest")

## 获取熔岩地图数据
static func get_lava_map_data() -> MapData:
    return _get_map_data_by_id("lava")

## 获取冰山地图数据
static func get_ice_map_data() -> MapData:
    return _get_map_data_by_id("ice")

## 获取暗影地图数据
static func get_shadow_map_data() -> MapData:
    return _get_map_data_by_id("shadow_realm")

## 获取祭坛地图数据
static func get_altar_map_data() -> MapData:
    return _get_map_data_by_id("altar")

## 随机获取一个地图数据
static func get_random_map_data() -> MapData:
    return MAP_DATA[randi() % MAP_DATA.size()]

## 检查地图解锁条件
static func check_map_unlock(map_id: String, completed_maps: Array[String]) -> bool:
    var data = _get_map_data_by_id(map_id)
    if data == null:
        return false
    
    if data.unlock_condition == "初始解锁":
        return true
    
    # 检查解锁条件
    if data.unlock_condition.begins_with("通关"):
        var required_map = data.unlock_condition.substr(2)
        return required_map in completed_maps
    
    return false