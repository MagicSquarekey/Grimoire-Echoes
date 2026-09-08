## WeaponBase - 武器基类
## 所有武器的基类，定义武器的基本属性和行为
class_name WeaponBase
extends Node2D

## 武器属性
@export var weapon_name: String = ""
@export var damage: float = 10.0
@export var attack_speed: float = 1.0  # 攻击速度倍率
@export var attack_range: float = 50.0
@export var knockback_force: float = 0.0

## 攻击状态
var current_cooldown: float = 0.0
var is_attacking: bool = false

## 组件引用
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

## 信号
signal weapon_attacked()
signal weapon_hit(target: Node2D, damage: float)

func _ready() -> void:
	# 设置攻击区域
	attack_area.area_entered.connect(_on_attack_area_entered)

func _process(delta: float) -> void:
	# 更新冷却
	if current_cooldown > 0:
		current_cooldown -= delta * attack_speed

## 攻击
func attack() -> bool:
	if current_cooldown > 0:
		return false
	
	# 执行攻击逻辑
	_on_attack()
	
	# 设置冷却
	current_cooldown = 1.0
	weapon_attacked.emit()
	
	return true

## 攻击逻辑（子类重写）
func _on_attack() -> void:
	# 播放攻击动画
	is_attacking = true
	
	# 启用攻击区域
	attack_shape.set_deferred("disabled", false)
	
	# 延迟禁用
	await get_tree().create_timer(0.1).timeout
	attack_shape.set_deferred("disabled", true)
	is_attacking = false

## 攻击区域检测
func _on_attack_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		var enemy = area.get_parent()
		if enemy and enemy.has_method("take_damage"):
			enemy.take_damage(damage, get_parent())
			weapon_hit.emit(enemy, damage)

## 获取伤害（供外部调用）
func get_damage() -> float:
	return damage

## 获取攻击信息
func get_weapon_info() -> Dictionary:
	return {
		"name": weapon_name,
		"damage": damage,
		"speed": attack_speed,
		"range": attack_range
	}
