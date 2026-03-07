extends Node

# total fragments collected across ALL levels
var memory_collected: int = 0
var memory_total: int = 0  

signal memory_updated(current, total)

func collect_memory():
	memory_collected += 1
	emit_signal("memory_updated", memory_collected, memory_total)
	print("Memory collected: %d / %d" % [memory_collected, memory_total])

func reset_memory():
	memory_collected = 0
	memory_total = 0
