## BossHealthBar - Boss 血条（纯视觉）
## 监听 EventBus.boss_spawned / boss_defeated；存活期间每帧读取 Boss 血量刷新
extends Control

@onready var bar: ProgressBar = $Bar
@onready var name_label: Label = $Bar/BossName

var _boss: Node = null

func _ready() -> void:
	visible = false
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_defeated.connect(_on_boss_defeated)

func _on_boss_spawned(boss_name: String) -> void:
	# boss_spawned 可能在 Boss 入树同帧发出，延迟一帧再取
	await get_tree().process_frame
	_boss = get_tree().get_first_node_in_group("boss")
	if _boss == null:
		return
	name_label.text = str(boss_name)
	visible = true
	_refresh()

func _on_boss_defeated(boss_name: String) -> void:
	_boss = null
	visible = false

func _process(_delta: float) -> void:
	if not visible:
		return
	if _boss == null or not is_instance_valid(_boss) or not _boss.is_alive:
		_boss = null
		visible = false
		return
	_refresh()

func _refresh() -> void:
	bar.max_value = _boss.max_health
	bar.value = _boss.current_health
