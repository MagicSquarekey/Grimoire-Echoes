## EnemyResource - 敌人资源
## 定义敌人的所有属性和配置
class_name EnemyResource
extends Resource

## 基础信息
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var type: EnemyType = EnemyType.NORMAL
@export var element: String = ""

## 基础属性
@export var max_health: float = 30.0
@export var base_damage: float = 8.0
@export var move_speed: float = 120.0
@export var exp_value: int = 10
@export var gold_value: int = 1

## 行为参数
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var chase_range: float = 300.0
@export var retreat_threshold: float = 0.2

## 特殊能力
@export var special_abilities: Array[String] = []
@export var is_boss: bool = false
var boss_phases = []

## 获取类型名称
func get_type_name() -> String:
	return EnemyType.keys()[type]

## 获取敌人描述
func get_full_description() -> String:
	var desc = description
	desc += "\n类型: %s" % get_type_name()
	desc += "\n生命值: %d" % int(max_health)
	desc += "\n伤害: %d" % int(base_damage)
	desc += "\n速度: %d" % int(move_speed)
	desc += "\n经验值: %d" % exp_value
	desc += "\n金币: %d" % gold_value
	return desc

## 敌人类型枚举
enum EnemyType {
	NORMAL,     # 普通敌人
	RANGED,     # 远程敌人
	SPECIAL,    # 特殊敌人
	SWARM,      # 群体型敌人
	ELITE,      # 精英敌人
	BOSS        # Boss
}

## Boss阶段数据
class BossPhase:
	var phase_number: int
	var health_threshold: float
	var abilities: Array[String]
	var behavior_change: String
	
	func _init(
		_phase_number: int,
		_health_threshold: float,
		_abilities: Array[String],
		_behavior_change: String
	) -> void:
		phase_number = _phase_number
		health_threshold = _health_threshold
		abilities = _abilities
		behavior_change = _behavior_change
