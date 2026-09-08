## ObjectPool - 对象池管理器（单例）
## 管理所有对象池，避免频繁创建/销毁
extends Node

# 对象池字典
var pools: Dictionary = {}

# 统计信息
var total_active: int = 0
var total_pooled: int = 0

func _ready() -> void:
	# 初始化各类对象池
	_init_pools()

## 初始化所有对象池
func _init_pools() -> void:
	# 延迟初始化：在实际使用时才创建池
	# 这样避免在游戏启动时加载不存在的场景
	pass

## 创建对象池
func _create_pool(pool_name: String, scene: PackedScene, size: int) -> void:
	var pool = ObjectPoolData.new()
	pool.scene = scene
	pool.pool_name = pool_name
	
	# 预分配对象
	for i in size:
		var obj = scene.instantiate()
		obj.visible = false
		obj.set_process(false)
		obj.set_physics_process(false)
		add_child(obj)
		pool.available.append(obj)
	
	pools[pool_name] = pool
	total_pooled += size
	print("对象池 '%s' 已创建，预分配 %d 个对象" % [pool_name, size])

## 获取对象
func acquire(pool_name: String) -> Node:
	if not pools.has(pool_name):
		push_error("对象池 '%s' 不存在" % pool_name)
		return null
	
	var pool = pools[pool_name]
	var obj: Node
	
	if pool.available.size() > 0:
		obj = pool.available.pop_back()
	else:
		# 池已满，动态创建（有上限）
		if pool.active.size() < pool.max_size:
			obj = pool.scene.instantiate()
			add_child(obj)
		else:
			push_warning("对象池 '%s' 已达最大容量" % pool_name)
			return null
	
	obj.visible = true
	obj.set_process(true)
	obj.set_physics_process(true)
	pool.active.append(obj)
	total_active += 1
	
	return obj

## 释放对象
func release(obj: Node, pool_name: String) -> void:
	if not pools.has(pool_name):
		push_error("对象池 '%s' 不存在" % pool_name)
		return
	
	var pool = pools[pool_name]
	
	if obj in pool.active:
		pool.active.erase(obj)
		obj.visible = false
		obj.set_process(false)
		obj.set_physics_process(false)
		obj.global_position = Vector2(-1000, -1000)  # 移到屏幕外
		pool.available.append(obj)
		total_active -= 1

## 获取池统计信息
func get_pool_stats() -> Dictionary:
	var stats = {}
	for pool_name in pools:
		var pool = pools[pool_name]
		stats[pool_name] = {
			"active": pool.active.size(),
			"available": pool.available.size(),
			"total": pool.active.size() + pool.available.size()
		}
	return stats

## 清空所有池
func clear_all_pools() -> void:
	for pool_name in pools:
		var pool = pools[pool_name]
		for obj in pool.active:
			obj.queue_free()
		for obj in pool.available:
			obj.queue_free()
		pool.active.clear()
		pool.available.clear()
	total_active = 0
	total_pooled = 0

## 对象池数据类
class ObjectPoolData:
	var scene: PackedScene
	var pool_name: String
	var active: Array[Node] = []
	var available: Array[Node] = []
	var max_size: int = 500  # 最大对象数量
