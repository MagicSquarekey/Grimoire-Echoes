## FrostNova - 寒冰新星
## 水流系环形法术
class_name FrostNova
extends BaseSpell

# 寒冰新星特有属性
@export var freeze_duration: float = 2.0  # 冻结2秒
@export var nova_radius: float = 150.0  # 范围

func _init() -> void:
	spell_name = "寒冰新星"
	spell_element = "water"
	spell_type = SpellType.RING
	damage = 30.0
	cooldown = 7.0
	mana_cost = 25.0
	aoe_radius = 150.0

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 获取范围内所有敌人
	var enemies = _get_enemies_in_range(nova_radius)
	
	for enemy in enemies:
		# 应用伤害
		_apply_damage(enemy)
		
		# 应用冻结效果
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect("freeze", 0.0, freeze_duration)

## 重写法术升级
func _on_upgrade() -> void:
	damage *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 范围+40%
			nova_radius *= 1.4
			aoe_radius = nova_radius
			print("寒冰新星升级: 范围增加")
		10:
			# Lv.10: 冻结+1秒
			freeze_duration += 1.0
			print("寒冰新星升级: 冻结时间增加")
		15:
			# Lv.15: 伤害冰爆
			print("寒冰新星升级: 冻结敌人爆炸造成额外伤害")
