## check_theme.gd - 校验主题资源能否正常加载、变体与样式是否生效
## 用法: godot --headless --path <项目> -s res://tools/check_theme.gd
extends SceneTree

func _initialize() -> void:
	var t: Theme = load("res://assets/ui/theme.tres")
	if t == null:
		print("[check] THEME LOAD FAILED")
		quit(1)
		return
	print("[check] theme loaded ok")
	var types := t.get_type_list()
	print("[check] variations: ", types)
	print("[check] Button normal style: ", t.has_stylebox("normal", "Button"))
	print("[check] ProgressBar fill: ", t.has_stylebox("fill", "ProgressBar"))
	print("[check] PanelContainer panel: ", t.has_stylebox("panel", "PanelContainer"))
	print("[check] default_font: ", t.default_font)
	if t.default_font:
		print("[check] font_names: ", t.default_font.font_names)
	quit(0)
