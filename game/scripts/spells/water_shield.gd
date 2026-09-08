## WaterShield - 水之护盾
## 水流系防御法术
class_name WaterShield
extends BuffSpell

# 水之护盾特有属性
@export var shield_absorb_percent: float = 0.15  # 吸收最大生命值15%
@export var shield_duration: float = 6.0  # 持续时间
@export var shield_value: float = 0.0  # 护盾值（动态计算）

func _init() -> void:
	spell_name = "水之护盾"
	spell_element = "water"
	spell_type = SpellType.SHIELD
	damage = 0
	cooldown = 15.0
	mana_cost = 20.0
	buff_type = "shield"
	buff_duration = shield_duration

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 计算护盾值
	_calculate_shield_value()
	
	# 应用水之护盾
	_apply_water_shield(target if target else owner_node)

## 计算护盾值
func _calculate_shield_value() -> void:
	var player_stats = _get_owner_stats()
	if player_stats:
		shield_value = player_stats.max_health * shield_absorb_percent
	else:
		shield_value = 100.0  # 默认值

## 应用水之护盾
func _apply_water_shield(target: Node2D) -> void:
	# 应用护盾效果
	if target.has_method("apply_shield"):
		target.apply_shield(shield_value)
	
	# 播放护盾视觉效果
	_play_water_shield_effect(target)
	
	# 开始护盾持续时间
	is_active = true
	active_timer = shield_duration

## 播放水之护盾视觉效果
func _play_water_shield_effect(target: Node2D) -> void:
	# 创建护盾精灵
	var shield_sprite = Sprite2D.new()
	shield_sprite.name = "WaterShieldSprite"
	shield_sprite.modulate = Color(0.3, 0.5, 1.0, 0.6)  # 蓝色
	shield_sprite.scale = Vector2(1.5, 1.5)
	target.add_child(shield_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "WaterShieldParticles"
	particles.emitting = true
	particles.lifetime = shield_duration
	particles.amount = 12
	target.add_child(particles)

## 重写法术升级
func _on_upgrade() -> void:
	shield_absorb_percent *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 吸收+50%
			shield_absorb_percent *= 1.5
			print("水之护盾升级: 吸收效果增强")
		10:
			# Lv.10: 反弹伤害
			print("水之护盾升级: 反弹伤害")
		15:
			# Lv.15: 水波脉冲
			print("水之护盾升级: 水波脉冲")