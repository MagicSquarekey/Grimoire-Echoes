## HealthPotion - 回血药剂
## 敌人概率掉落（3%，Boss 必掉），拾取回复 25% 最大生命
extends PickupBase

## 回复比例（相对最大生命）
@export var heal_ratio: float = 0.25

## 初始化
func _init() -> void:
	pickup_name = "回血药剂"

## 应用效果：回复玩家 25% 最大生命并通知 HUD
func _apply_effect(collector) -> void:
	if collector and collector.has_method("get_stats"):
		var stats = collector.get_stats()
		if stats:
			var amount: float = stats.get_max_health() * heal_ratio
			stats.heal(amount)
			EventBus.player_healed.emit(amount)
	EventBus.pickup_collected.emit("health_potion", int(pickup_value))
