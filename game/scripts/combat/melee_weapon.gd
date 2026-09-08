## MeleeWeapon - 近战武器
## 近战武器的具体实现
class_name MeleeWeapon
extends WeaponBase

## 近战属性
@export var swing_angle: float = 120.0  # 挥砍角度
@export var swing_duration: float = 0.2  # 挥砍持续时间

## 动画播放器
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## 攻击逻辑
func _on_attack() -> void:
	# 播放挥砍动画
	if animation_player:
		animation_player.play("swing")
	
	# 调用父类攻击逻辑
	super._on_attack()

## 攻击区域检测（处理多个目标）
func _on_attack_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		var enemy = area.get_parent()
		if enemy and enemy.has_method("take_damage"):
			# 计算距离衰减
			var distance = global_position.distance_to(enemy.global_position)
			var damage_multiplier = _calculate_distance_falloff(distance)
			
			enemy.take_damage(damage * damage_multiplier, get_parent())
			weapon_hit.emit(enemy, damage * damage_multiplier)

## 计算距离衰减
func _calculate_distance_falloff(distance: float) -> float:
	if distance <= attack_range * 0.5:
		return 1.0  # 满伤害
	elif distance <= attack_range:
		return 0.7  # 70%伤害
	else:
		return 0.3  # 30%伤害
