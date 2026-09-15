## CursedAltar - 诅咒祭坛（事件波实体）
## 触碰达成契约：牺牲 30% 当前生命，换取全部法术伤害 +30%（一次性）。
## 生命过低时祭坛不肯回应，可离开后再次触碰重试。
extends Area2D

const HP_COST_RATIO := 0.3      # 代价：30% 当前生命
const HP_FLOOR := 5.0           # 契约后至少保留的生命
const DAMAGE_BONUS := 1.3       # 回报：法术伤害 ×1.3

var _used := false
var _retry_ready := true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	var stats = body.get_node_or_null("PlayerStats")
	if stats == null:
		return

	var cost: float = stats.current_health * HP_COST_RATIO
	if stats.current_health - cost <= HP_FLOOR:
		if _retry_ready:
			_retry_ready = false
			get_tree().create_timer(1.5).timeout.connect(func(): _retry_ready = true)
			EventBus.show_toast.emit("生命过低，祭坛不肯回应……", 1.5)
		return

	_used = true
	set_deferred("monitoring", false)

	# 代价：直接结算生命（绕过玩家无敌帧，契约不受闪避保护）
	stats.take_damage(cost)

	# 回报：全部已装备法术伤害 ×1.3
	var spell_caster = body.get_node_or_null("SpellCaster")
	if spell_caster:
		for spell in spell_caster.spell_slots:
			if spell:
				spell.damage *= DAMAGE_BONUS

	EventBus.show_toast.emit("祭坛契约达成：损失 %d 生命，法术伤害 +30%%" % int(cost), 2.2)
	AudioManager.play_named("altar_deal", 0.8)

	# 消散动画
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tw.parallel().tween_property(self, "scale", Vector2(1.4, 1.4), 0.5)
	tw.tween_callback(queue_free)
