class_name PriorityQueue extends RefCounted
# referred to https://www.reddit.com/r/godot/comments/100vnjv/i_wrote_astar_from_scratch_in_gdscript/
# root is minimum

var _heap: Array[Variant]
var _costs: Array[float]

func _init() -> void:
	_heap = []
	_costs = []

func push(v: Variant, cost: float) -> void:
	_push_back(v, cost)
	var idx := len(_heap) - 1
	_up_heap(idx)

func pop() -> Variant:
	if is_empty():
		return null
	var res: Variant = _pop_front()
	if not is_empty():
		var h = _heap.pop_back()
		var c = _costs.pop_back()
		_push_front(h, c)
		_down_heap(0)
	return res

func is_empty() -> bool:
	return _heap.is_empty() and _costs.is_empty()

func _pop_front() -> Variant:
	_costs.pop_front()
	return _heap.pop_front()

func _push_front(v: Variant, f: float) -> void:
	_heap.push_front(v)
	_costs.push_front(f)

func _push_back(v: Variant, f: float) -> void:
	_heap.push_back(v)
	_costs.push_back(f)

func _swap(idx1: int, idx2: int) -> void:
	var h1 = _heap[idx1]
	var c1 := _costs[idx1]
	
	_heap[idx1] = _heap[idx2]
	_costs[idx1] = _costs[idx2]
	_heap[idx2] = h1
	_costs[idx2] = c1

func _up_heap(idx: int) -> void:
	var child_idx := idx
	var parent_idx := (child_idx - 1) / 2
	
	while _costs[parent_idx] > _costs[idx]:
		_swap(idx, parent_idx)
		child_idx = parent_idx
		parent_idx = (child_idx - 1) / 2

func _down_heap(idx: int) -> void:
	var parent_idx := idx
	var left_child := (2 * parent_idx) + 1
	var right_child := (2 * parent_idx) + 2
	var smallest: int = parent_idx
	var size: int = len(_heap)
	
	while true:
		if right_child < size and _costs[right_child] < _costs[smallest]:
			smallest = right_child
		if left_child < size and _costs[left_child] < _costs[smallest]:
			smallest = left_child
		if smallest == parent_idx:
			break
		else:
			_swap(parent_idx, smallest)
			parent_idx = smallest
			left_child = (2 * parent_idx) + 1
			right_child = (2 * parent_idx) + 2
		
