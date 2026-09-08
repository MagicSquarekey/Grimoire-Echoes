## GoldCoin - 金币
## 击杀敌人后掉落的金币，靠近自动吸取
extends PickupBase

## 初始化
func _init() -> void:
	pickup_name = "金币"

## 应用效果：增加金币并通知 HUD
func _apply_effect(collector) -> void:
	GameManager.add_gold(int(pickup_value))
	EventBus.gold_changed.emit(GameManager.total_gold)
