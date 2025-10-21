extends Node

var inventory: Dictionary = {}
func get_item_count(entity: PandoraEntity) -> int:
	var id = entity.get_entity_id()
	if inventory.has(id):
		return inventory[id].size()
	return 0
