## MapHazard - 地图陷阱
## 地图中的危险区域和陷阱
class_name MapHazard
extends Area2D

## 陷阱属性
@export var hazard_name: String = ""
@export var hazard_type: String = ""  # lava, poison, vine, geyser
@export var damage: float = 10.0
@export var damage_interval: float = 1.0
@export var effect_duration: float = 3.0

## 状态
var is_active: bool = true
var damage_timer: float = 0.0

## 组件引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## 信号
signal hazard_triggered(target: Node2D)

func _ready() -> void:
	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if not is_active:
		return
	
	# 更新伤害计时器
	damage_timer += delta
	if damage_timer >= damage_interval:
		damage_timer = 0.0
		_apply_damage_to_all()

## 碰撞检测 - 进入
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("enemies"):
		_apply_effect(body)
		hazard_triggered.emit(body)

## 碰撞检测 - 离开
func _on_body_exited(body: Node2D) -> void:
	# 移除效果
	_remove_effect(body)

## 应用效果
func _apply_effect(target: Node2D) -> void:
	match hazard_type:
		"lava":
			_apply_lava_effect(target)
		"poison":
			_apply_poison_effect(target)
		"vine":
			_apply_vine_effect(target)
		"geyser":
			_apply_geyser_effect(target)

## 应用岩浆效果
func _apply_lava_effect(target: Node2D) -> void:
	# 造成持续伤害
	if target.has_method("take_damage"):
		target.take_damage(damage, null, DamageCalculator.DamageType.DOT)

## 应用毒雾效果
func _apply_poison_effect(target: Node2D) -> void:
	# 造成持续伤害并降低移速
	if target.has_method("take_damage"):
		target.take_damage(damage, null, DamageCalculator.DamageType.DOT)
	if target.has_method("apply_status_effect"):
		target.apply_status_effect(StatusEffectSystem.EffectType.SLOW, 0.3, effect_duration)

## 应用藤蔓效果
func _apply_vine_effect(target: Node2D) -> void:
	# 缠绕目标
	if target.has_method("apply_status_effect"):
		target.apply_status_effect(StatusEffectSystem.EffectType.STUN, 0.0, 2.0)

## 应用间歇泉效果
func _apply_geyser_effect(target: Node2D) -> void:
	# 造成伤害并击飞
	if target.has_method("take_damage"):
		target.take_damage(damage * 2, null, DamageCalculator.DamageType.PHYSICAL)
	if target.has_method("apply_knockback"):
		target.apply_knockback(Vector2.UP, 300.0)

## 移除效果
func _remove_effect(target: Node2D) -> void:
	# 根据类型移除效果
	match hazard_type:
		"vine":
			# 藤蔓缠绕在目标离开时自动解除
			pass

## 对范围内所有目标造成伤害
func _apply_damage_to_all() -> void:
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") or body.is_in_group("enemies"):
			if body.has_method("take_damage"):
				body.take_damage(damage, null, DamageCalculator.DamageType.DOT)

## 激活陷阱
func activate() -> void:
	is_active = true
	visible = true
	collision_shape.set_deferred("disabled", false)

## 停用陷阱
func deactivate() -> void:
	is_active = false
	visible = false
	collision_shape.set_deferred("disabled", true)

## 获取陷阱信息
func get_hazard_info() -> Dictionary:
	return {
		"name": hazard_name,
		"type": hazard_type,
		"damage": damage,
		"active": is_active
	}
