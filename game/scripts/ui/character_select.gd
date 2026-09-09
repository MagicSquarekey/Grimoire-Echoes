## CharacterSelect - 角色选择界面
## 选择游戏角色
extends CanvasLayer

# 角色数据
var characters: Array[Dictionary] = [
	{
		"id": "fire_mage",
		"name": "火焰法师",
		"description": "擅长火焰法术，伤害输出高",
		"element": "fire",
		"bonus": "+20%火焰伤害"
	},
	{
		"id": "water_mage",
		"name": "水流法师",
		"description": "擅长水流法术，控制能力强",
		"element": "water",
		"bonus": "+20%水流伤害"
	},
	{
		"id": "lightning_mage",
		"name": "雷电法师",
		"description": "擅长雷电法术，攻击速度快",
		"element": "lightning",
		"bonus": "+20%雷电伤害"
	}
]

# 当前选择
var selected_index: int = 0

# UI引用
@onready var character_list: VBoxContainer = $MarginContainer/VBoxContainer/CharacterList
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ConfirmButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
# [UI美化] 角色说明面板
@onready var desc_label: RichTextLabel = $MarginContainer/VBoxContainer/DescPanel/DescMargin/DescLabel

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# 生成角色列表
	_generate_character_list()
	
	# 默认高亮第一个角色
	_on_character_selected(0)

## 生成角色列表
func _generate_character_list() -> void:
	for i in range(characters.size()):
		var char_data = characters[i]
		
		# 创建角色按钮
		var button = Button.new()
		button.text = "%s - %s" % [char_data["name"], char_data["bonus"]]
		button.custom_minimum_size = Vector2(400, 60)

		# [UI美化] 卡片化：立绘头像 + 圆角描边样式
		button.custom_minimum_size = Vector2(820, 136)
		button.expand_icon = true
		button.icon = load("res://assets/sprites/gen/portraits/player_%s.png" % char_data["element"])
		button.add_theme_constant_override("h_separation", 26)
		button.add_theme_font_size_override("font_size", 24)
		button.add_theme_color_override("font_color", Color(0.95, 0.93, 1))
		button.add_theme_color_override("font_hover_color", Color(1, 0.99, 0.93))
		button.add_theme_stylebox_override("normal", _make_card_style(false))
		button.add_theme_stylebox_override("hover", _make_card_style(false, true))
		button.add_theme_stylebox_override("pressed", _make_card_style(false))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		# 连接信号
		var index = i
		button.pressed.connect(func(): _on_character_selected(index))
		
		character_list.add_child(button)

## 角色选择
func _on_character_selected(index: int) -> void:
	selected_index = index
	
	# 更新选择状态
	for i in range(character_list.get_child_count()):
		var button = character_list.get_child(i)
		button.modulate = Color.WHITE if i == index else Color(0.6, 0.6, 0.6)

	# [UI美化] 选中态：金色描边 + 轻微放大
	for i in range(character_list.get_child_count()):
		var card = character_list.get_child(i)
		card.add_theme_stylebox_override("normal", _make_card_style(i == index))
		card.add_theme_stylebox_override("hover", _make_card_style(i == index, i != index))
		var target_scale := Vector2(1.03, 1.03) if i == index else Vector2(1.0, 1.0)
		var tw = create_tween()
		tw.tween_property(card, "scale", target_scale, 0.12)

	# [UI美化] 同步角色说明面板
	if desc_label:
		var c: Dictionary = characters[index]
		var element_names := {"fire": "火焰", "water": "水流", "lightning": "雷电"}
		desc_label.text = "[color=#f0c969][b]%s[/b][/color]  [color=#a08fd8]%s[/color]\n[color=#d9d2ee]%s[/color]\n[color=#9be08a]元素亲和：%s · %s[/color]" % [
			c["name"], element_names.get(c["element"], c["element"]),
			c["description"], element_names.get(c["element"], c["element"]), c["bonus"]
		]

## 确认选择
func _on_confirm_pressed() -> void:
	var selected_character = characters[selected_index]
	
	# 开始新游戏（这会设置状态为PLAYING）
	GameManager.start_new_game(selected_character["id"], "forest")
	
	# 加载游戏场景
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")

## 返回
func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

## [UI美化] 生成角色卡片样式（selected=选中金边，hovered=悬停亮边）
func _make_card_style(selected: bool, hovered: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(2)
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	if selected:
		sb.bg_color = Color(0.16, 0.12, 0.3, 0.98)
		sb.border_color = Color(0.94, 0.8, 0.45)
		sb.shadow_color = Color(0.94, 0.8, 0.45, 0.25)
		sb.shadow_size = 10
	elif hovered:
		sb.bg_color = Color(0.14, 0.11, 0.26, 0.96)
		sb.border_color = Color(0.65, 0.55, 0.9)
		sb.shadow_color = Color(0, 0, 0, 0.4)
		sb.shadow_size = 6
	else:
		sb.bg_color = Color(0.1, 0.08, 0.19, 0.92)
		sb.border_color = Color(0.36, 0.3, 0.55)
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 4
	return sb
