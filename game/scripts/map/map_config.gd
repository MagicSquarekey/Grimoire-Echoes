## MapConfig - 地图配置资源
## 定义地图的所有属性和配置
class_name MapConfig
extends Resource

## 基础信息
@export var map_id: String = ""
@export var map_name: String = ""
@export var description: String = ""
@export var tileset: TileSet

## 地图尺寸
@export_group("Map Size")
@export var map_size: Vector2i = Vector2i(100, 100)  # 瓦片数
@export var tile_size: int = 64

## 特殊机制
@export_group("Special Mechanics")
@export var has_vine_traps: bool = false
@export var has_poison_mist: bool = false
@export var has_lava_damage: bool = false
@export var has_ice_physics: bool = false
@export var has_vision_limit: bool = false
@export var has_teleporters: bool = false

## 环境效果
@export_group("Environment")
@export var ambient_color: Color = Color.WHITE
@export var fog_density: float = 0.0
@export var music_track: String = ""

## 敌人生成配置
@export_group("Enemy Spawning")
@export var enemy_types: Array[String] = []
@export var spawn_rate: float = 1.0
@export var max_enemies: int = 50

## 解锁条件
@export_group("Unlock Conditions")
@export var unlock_condition: String = ""
@export var required_wave: int = 0
@export var required_map: String = ""

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
