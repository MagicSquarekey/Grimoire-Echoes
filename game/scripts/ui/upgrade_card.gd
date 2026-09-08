## UpgradeCard - 升级选项卡片
## 单个升级选项的显示和交互
class_name UpgradeCard
extends PanelContainer

## 组件引用
@onready var icon: TextureRect = $VBoxContainer/Icon
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var level_label: Label = $VBoxContainer/LevelLabel

## 当前选项数据
var option_data: Dictionary = {}

## 信号
signal option_selected()

## 初始化
func _ready() -> void:
	# 信号已在场景文件中连接（gui_input/mouse_entered/mouse_exited）
	pass

## 设置选项数据
func setup(data: Dictionary) -> void:
	option_data = data
	
	# 更新显示
	_update_display()

## 更新显示
func _update_display() -> void:
	if option_data.is_empty():
		return
	
	# 设置名称
	if name_label:
		name_label.text = option_data.get("name", "Unknown")
	
	# 设置描述（兼容 desc 和 description 两种key）
	if description_label:
		description_label.text = option_data.get("description", option_data.get("desc", ""))
	
	# 设置等级
	if level_label:
		var level = option_data.get("level", 1)
		level_label.text = "Lv.%d" % level
	
	# 设置图标
	if icon and option_data.has("icon"):
		icon.texture = option_data["icon"]

## 鼠标输入处理
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			option_selected.emit()

## 鼠标进入效果
func _on_mouse_entered() -> void:
	# 放大效果
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

## 鼠标离开效果
func _on_mouse_exited() -> void:
	# 恢复大小
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

## 获取选项信息
func get_option_data() -> Dictionary:
	return option_data
