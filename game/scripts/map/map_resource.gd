## MapResource - 地图资源
## 定义地图的所有属性和配置
class_name MapResource
extends Resource

## 基础信息
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var theme: MapTheme = MapTheme.FOREST
@export var unlock_condition: String = ""

## 地图属性
@export_group("Map Properties")
@export var map_size: Vector2i = Vector2i(100, 100)  # 瓦片数
@export var tile_size: int = 64
@export var ambient_color: Color = Color.WHITE
@export var fog_density: float = 0.0
@export var music_track: String = ""

## 特殊机制
@export_group("Special Mechanics")
@export var special_mechanics: Array[MapMechanic] = []

## 隐藏区域
@export_group("Hidden Areas")
@export var hidden_areas: Array[HiddenArea] = []

## Boss波次
@export_group("Boss Waves")
@export var boss_waves: Array[int] = []

## 获取主题名称
func get_theme_name() -> String:
    return MapTheme.keys()[theme]

## 获取地图像素尺寸
func get_pixel_size() -> Vector2:
    return Vector2(map_size.x * tile_size, map_size.y * tile_size)

## 获取中心位置
func get_center() -> Vector2:
    return get_pixel_size() / 2.0

## 获取地图边界
func get_bounds() -> Rect2:
    return Rect2(Vector2.ZERO, get_pixel_size())

## 检查位置是否在地图内
func is_position_valid(pos: Vector2) -> bool:
    return get_bounds().has_point(pos)

## 获取随机位置
func get_random_position(margin: float = 100.0) -> Vector2:
    var bounds = get_bounds()
    return Vector2(
        randf_range(bounds.position.x + margin, bounds.end.x - margin),
        randf_range(bounds.position.y + margin, bounds.end.y - margin)
    )

## 主题枚举
enum MapTheme {
    FOREST,      # 幽暗森林
    LAVA,        # 熔岩裂谷
    ICE,         # 冰封山脉
    SHADOW,      # 暗影深渊
    ELEMENTAL    # 元素祭坛
}

## 地图机制数据
class MapMechanic:
    var id: String
    var name: String
    var description: String
    var trigger_type: TriggerType
    var cooldown: float
    var effect_data: Dictionary
    
    func _init(
        _id: String,
        _name: String,
        _description: String,
        _trigger_type: TriggerType,
        _cooldown: float,
        _effect_data: Dictionary = {}
    ) -> void:
        id = _id
        name = _name
        description = _description
        trigger_type = _trigger_type
        cooldown = _cooldown
        effect_data = _effect_data

## 触发类型枚举
enum TriggerType {
    TIMED,      # 定时触发
    AREA,       # 区域触发
    INTERACTIVE # 交互触发
}

## 隐藏区域数据
class HiddenArea:
    var id: String
    var name: String
    var description: String
    var position: Vector2
    var trigger_condition: String
    var rewards: Array[String]
    
    func _init(
        _id: String,
        _name: String,
        _description: String,
        _position: Vector2,
        _trigger_condition: String,
        _rewards: Array[String]
    ) -> void:
        id = _id
        name = _name
        description = _description
        position = _position
        trigger_condition = _trigger_condition
        rewards = _rewards