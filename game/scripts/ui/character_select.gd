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
