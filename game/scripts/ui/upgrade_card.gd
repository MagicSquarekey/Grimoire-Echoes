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

# [UI美化] 程序化图标目录与强化ID映射
const UI_ICON_DIR := "res://assets/ui/icons/"
const UPGRADE_ICONS := {
	"damage": "sword",
	"haste": "bolt",
	"multishot": "multishot",
	"speed": "speed",
	"health": "heart",
	"magnet": "magnet",
}
# [UI美化] 品阶边框色（按ID稳定哈希分配）
const RARITY_COLORS: Array[Color] = [
	Color(0.788, 0.643, 0.361),
	Color(0.627, 0.42, 0.91),
	Color(0.31, 0.765, 0.91),
	Color(0.91, 0.42, 0.66),
]

## 信号
signal option_selected()

## 初始化
func _ready() -> void:
	# 信号已在场景文件中连接（gui_input/mouse_entered/mouse_exited）
	pass
	# [UI美化] 悬停缩放以中心为轴
	resized.connect(_center_pivot)

## [UI美化] 悬停缩放中心点
func _center_pivot() -> void:
	pivot_offset = size / 2.0

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

	# [UI美化] 图标回退：按强化ID加载程序化图标
	if icon and icon.texture == null and option_data.has("id"):
		var icon_id: String = UPGRADE_ICONS.get(option_data["id"], "star")
		icon.texture = load(UI_ICON_DIR + icon_id + ".png")

	# [UI美化] 品阶边框配色
	_apply_rarity_border()

## [UI美化] 按选项ID稳定分配品阶边框色
func _apply_rarity_border() -> void:
	var idx := 0
	if option_data.has("id"):
		idx = absi(str(option_data["id"]).hash()) % RARITY_COLORS.size()
	var col: Color = RARITY_COLORS[idx]
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.09, 0.2, 0.98)
	sb.set_border_width_all(2)
	sb.border_color = col
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 18.0
	sb.content_margin_top = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_bottom = 18.0
	sb.shadow_color = Color(col.r, col.g, col.b, 0.25)
	sb.shadow_size = 8
	add_theme_stylebox_override("panel", sb)
	if name_label:
		name_label.add_theme_color_override("font_color", col.lightened(0.35))

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
