## UpgradePanel - 升级选择面板
## 玩家升级时显示的法术选择界面
class_name UpgradePanel
extends Control

## 组件引用
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var card_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/CardContainer
@onready var description_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/DescriptionLabel

## 升级选项场景
var upgrade_card_scene: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")

## 当前选项
var current_options = []

## 信号
signal option_selected(option_index: int)

## 初始化
func _ready() -> void:
	# 连接信号
	visible = false

## 显示升级选项
func show_upgrade_options(options) -> void:
	current_options = options
	visible = true
	
	# 清空旧卡片
	for child in card_container.get_children():
		child.queue_free()
	
	# 生成新卡片
	for i in range(options.size()):
		var option = options[i]
		var card = upgrade_card_scene.instantiate()
		if card:
			card.setup(option)
			card.option_selected.connect(_on_option_selected.bind(i))
			card_container.add_child(card)
	
	# 入场动画
	_play_entrance_animation()

## 选择选项
func _on_option_selected(index: int) -> void:
	option_selected.emit(index)
	hide_panel()

## 隐藏面板
func hide_panel() -> void:
	visible = false
	current_options.clear()

## 入场动画
func _play_entrance_animation() -> void:
	var cards = card_container.get_children()
	for i in range(cards.size()):
		var card = cards[i]
		card.modulate.a = 0.0
		card.scale = Vector2(0.8, 0.8)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(i * 0.1)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3).set_delay(i * 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## 获取选项信息
func get_option_info(index: int) -> Dictionary:
	if index >= 0 and index < current_options.size():
		return current_options[index]
	return {}
