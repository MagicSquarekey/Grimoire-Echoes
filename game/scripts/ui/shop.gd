## Shop - 商店系统
## 在波次间购买遗物和升级
extends CanvasLayer

# 商店物品数据
var shop_items: Array[Dictionary] = []
var purchased_items: Array[String] = []

# UI引用
@onready var item_list: VBoxContainer = $MarginContainer/VBoxContainer/ItemList
@onready var gold_label: Label = $MarginContainer/VBoxContainer/GoldLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	hide()

## 显示商店
func show_shop() -> void:
	# 生成商店物品
	_generate_shop_items()
	
	# 更新金币显示
	_update_gold_display()
	
	show()
	get_tree().paused = true

## 生成商店物品
func _generate_shop_items() -> void:
	# 清空现有物品
	for child in item_list.get_child_count():
		item_list.get_child(child).queue_free()
	
	# 生成3个随机物品
	shop_items = _get_random_items(3)
	
	for item in shop_items:
		var button = Button.new()
		button.text = "%s - %d金币" % [item["name"], item["price"]]
		button.custom_minimum_size = Vector2(350, 50)
		
		# 检查是否已购买
		if item["id"] in purchased_items:
			button.disabled = true
			button.text += " (已购买)"
		
		# 连接信号
		var item_data = item
		button.pressed.connect(func(): _on_item_pressed(item_data))
		
		item_list.add_child(button)

## 获取随机物品
func _get_random_items(count: int) -> Array[Dictionary]:
	var all_items = [
		{"id": "damage_boost", "name": "伤害提升+10%", "price": 50, "type": "stat", "value": 0.1},
		{"id": "health_boost", "name": "生命提升+20%", "price": 40, "type": "stat", "value": 0.2},
		{"id": "speed_boost", "name": "移动速度+15%", "price": 45, "type": "stat", "value": 0.15},
		{"id": "crit_boost", "name": "暴击率+10%", "price": 60, "type": "stat", "value": 0.1},
		{"id": "life_steal", "name": "生命偷取+5%", "price": 80, "type": "stat", "value": 0.05},
		{"id": "cooldown_reduction", "name": "冷却减少+10%", "price": 55, "type": "stat", "value": 0.1},
	]
	
	# 随机选择
	var available = all_items.filter(func(item): return item["id"] not in purchased_items)
	available.shuffle()
	
	return available.slice(0, min(count, available.size()))

## 更新金币显示
func _update_gold_display() -> void:
	gold_label.text = "金币: %d" % GameManager.total_gold

## 购买物品
func _on_item_pressed(item: Dictionary) -> void:
	if GameManager.total_gold >= item["price"]:
		# 扣除金币
		GameManager.total_gold -= item["price"]
		
		# 应用效果
		_apply_item_effect(item)
		
		# 记录已购买
		purchased_items.append(item["id"])
		
		# 更新显示
		_update_gold_display()
		_generate_shop_items()
		
		# 显示提示
		EventBus.show_toast.emit("购买成功: %s" % item["name"], 1.5)

## 应用物品效果
func _apply_item_effect(item: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var stats = player.get_node_or_null("PlayerStats")
	if not stats:
		return
	
	match item["id"]:
		"damage_boost":
			stats.attack_damage_bonus += item["value"]
		"health_boost":
			stats.max_health *= (1.0 + item["value"])
			stats.current_health = stats.max_health
		"speed_boost":
			stats.move_speed_bonus += item["value"]
		"crit_boost":
			stats.crit_rate_bonus += item["value"]
		"life_steal":
			stats.life_steal += item["value"]
		"cooldown_reduction":
			stats.cooldown_reduction += item["value"]

## 关闭商店
func _on_close_pressed() -> void:
	get_tree().paused = false
	hide()
	
	# 通知游戏继续
	EventBus.shop_closed.emit()
