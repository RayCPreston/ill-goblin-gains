class_name PoolRoller
extends RefCounted

func roll(ids: Array[String], count: int) -> Array[String]:
	var pool: Array[String] = ids.duplicate()
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))
