## WaveBanner - 波次开场横幅（纯视觉）
## 监听 EventBus.wave_started：「第 X 波来袭」大字 1.2s 淡入淡出；
## Boss 波（每5波）显示红色「⚠ Boss 来袭」
extends Control

@onready var label: Label = $CenterLabel

const BANNER_TIME := 1.2          # 横幅总时长（淡入+淡出）
const COLOR_NORMAL := Color(1.0, 0.93, 0.75)
const COLOR_BOSS := Color(1.0, 0.25, 0.2)

var _tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	EventBus.wave_started.connect(_on_wave_started)

func _on_wave_started(wave_number: int) -> void:
	if GameManager.game_mode == "boss_rush":
		label.text = "⚠ Boss 连战 · 第 %d 战" % wave_number
		label.add_theme_color_override("font_color", COLOR_BOSS)
	elif wave_number % 5 == 0:
		label.text = "⚠ Boss 来袭"
		label.add_theme_color_override("font_color", COLOR_BOSS)
	else:
		label.text = "第 %d 波来袭" % wave_number
		label.add_theme_color_override("font_color", COLOR_NORMAL)

	if _tween and _tween.is_valid():
		_tween.kill()

	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, BANNER_TIME * 0.3)
	_tween.tween_interval(BANNER_TIME * 0.25)
	_tween.tween_property(self, "modulate:a", 0.0, BANNER_TIME * 0.45)
