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
	mana_cost = 0.0  # 自动战斗法术不消耗法力
	aoe_radius = 150.0

## 重写施放逻辑（target 可能是 Vector2 坐标，环形新星以自身为中心，忽略该参数）
func _on_cast(_target = null) -> void:
	# 获取范围内所有敌人（基类签名：中心点 + 半径）
	var enemies = _get_enemies_in_range(global_position, nova_radius)

	for enemy in enemies:
		# 应用伤害
		_apply_damage(enemy)

		# 应用冻结效果
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect("freeze", 0.0, freeze_duration)
		# 冰霜爆裂（水/冰预设：青白碎片放射）
		FxLib.element_burst(self, enemy.global_position, "ice", 0.6)

	# 新星环视觉：冰环扩散 + 冰花粒子
	_spawn_nova_visual(global_position)

## 冰环扩散视觉（青白光环 + 放射冰屑）
func _spawn_nova_visual(pos: Vector2) -> void:
	var col := FxLib.color_for("ice")

	var ring := Sprite2D.new()
	ring.texture = load("res://assets/fx/ring_glow.png")
	ring.material = CanvasItemMaterial.new()
	ring.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ring.modulate = Color(col.r, col.g, col.b, 0.95)
	ring.global_position = pos
	ring.scale = Vector2(0.3, 0.3)
	get_tree().current_scene.add_child(ring)

	var burst := CPUParticles2D.new()
	burst.one_shot = true
	burst.emitting = true
	burst.lifetime = 0.45
	burst.amount = 18
	burst.initial_velocity_min = 160.0
	burst.initial_velocity_max = 300.0
	burst.gravity = Vector2(0, 90)
	burst.color = Color(col.r, col.g, col.b, 0.9)
	burst.global_position = pos
	get_tree().current_scene.add_child(burst)

	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2.ONE * (nova_radius / 46.0), 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(ring.queue_free)
	get_tree().create_timer(0.7).timeout.connect(burst.queue_free)

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
