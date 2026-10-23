class_name IterUtils
extends RefCounted

# arr.filter().front() errors on empty, this returns null instead
static func first(array: Array, predicate: Callable) -> Variant:
	var index := array.find_custom(predicate)
	if index == -1: return null
	return array[index]
