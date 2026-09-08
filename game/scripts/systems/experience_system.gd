## ExperienceSystem - 经验值系统
extends Node

## 信号
signal level_up(new_level)
signal exp_changed(current, required)

## 当前状态
var current_level = 1
var current_exp = 0
var required_exp = 56

## 升级需求表（20级）
const EXP_TABLE = [
    0, 56, 118, 186, 260, 340, 426, 518, 616, 720,
    830, 946, 1068, 1196, 1330, 1470, 1616, 1768, 1926, 2090
]

## 初始化
func _ready() -> void:
    # 经验改为由经验宝石直接加到 PlayerStats（此处不再监听击杀，避免双倍经验）
    pass

## 添加经验值
func add_exp(amount) -> void:
    current_exp += amount
    exp_changed.emit(current_exp, required_exp)
    while current_exp >= required_exp and current_level < 20:
        current_exp -= required_exp
        current_level += 1
        required_exp = EXP_TABLE[current_level] if current_level < EXP_TABLE.size() else 9999
        
        # 发送升级事件
        level_up.emit(current_level)
        EventBus.player_level_up.emit(current_level)
        
        # 显示升级效果
        _show_level_up_effect()

## 显示升级效果
func _show_level_up_effect() -> void:
    # 这里可以添加升级特效
    print("Level Up! Current Level: %d" % current_level)

## 敌人被击杀回调
func _on_enemy_killed(enemy_name: String, exp_reward: int, gold_reward: int) -> void:
    add_exp(exp_reward)

## 获取当前等级
func get_level() -> int:
    return current_level

## 获取当前经验
func get_exp() -> int:
    return current_exp

## 获取升级所需经验
func get_required_exp() -> int:
    return required_exp

## 获取经验百分比
func get_exp_percentage() -> float:
    if required_exp == 0:
        return 1.0
    return float(current_exp) / float(required_exp)

## 重置等级
func reset() -> void:
    current_level = 1
    current_exp = 0
    required_exp = EXP_TABLE[1] if EXP_TABLE.size() > 1 else 56

## 获取保存数据
func get_save_data() -> Dictionary:
    return {
        "level": current_level,
        "exp": current_exp,
        "required_exp": required_exp
    }

## 加载保存数据
func load_save_data(data: Dictionary) -> void:
    current_level = data.get("level", 1)
    current_exp = data.get("exp", 0)
    required_exp = data.get("required_exp", EXP_TABLE[1] if EXP_TABLE.size() > 1 else 56)
