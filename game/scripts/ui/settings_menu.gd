## SettingsMenu - 设置菜单
## 游戏设置界面
extends CanvasLayer

# 音量设置
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

# UI引用
@onready var volume_slider: HSlider = $MarginContainer/VBoxContainer/VolumeHBox/VolumeSlider
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	volume_slider.value_changed.connect(_on_volume_changed)
	close_button.pressed.connect(_on_close_pressed)
	hide()

## 显示设置菜单
func show_settings() -> void:
	volume_slider.value = master_volume * 100.0
	show()
	get_tree().paused = true

## 音量改变
func _on_volume_changed(value: float) -> void:
	master_volume = value / 100.0
	# 应用音量
	if AudioManager.has_method("set_master_volume"):
		AudioManager.set_master_volume(master_volume)

## 关闭设置
func _on_close_pressed() -> void:
	get_tree().paused = false
	hide()
