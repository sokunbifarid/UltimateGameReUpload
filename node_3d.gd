extends Node3D

# ============================================================================
# COMPLETE GUIDE TO DICTIONARIES IN GDSCRIPT
# ============================================================================

func _ready():
	print("=== DICTIONARY GUIDE ===\n")
	
	# Run all examples
	creating_dictionaries()
	accessing_values()
	adding_modifying_values()
	removing_values()
	checking_keys()
	iterating_dictionaries()
	dictionary_methods()
	nested_dictionaries()
	practical_examples()

# ============================================================================
# 1. CREATING DICTIONARIES
# ============================================================================
func creating_dictionaries():
	print("\n--- 1. CREATING DICTIONARIES ---")
	
	# Empty dictionaries
	var empty_dict = {}
	var another_empty = Dictionary()
	print("Empty dict: ", empty_dict)
	
	# Dictionary with initial values
	var player = {
		"name": "Hero",
		"health": 100,
		"mana": 50
	}
	print("Player dict: ", player)
	
	# Mixed key types
	var mixed_keys = {
		1: "one",                    # Integer key
		"two": 2,                    # String key
		Vector2(0, 0): "origin"      # Vector2 key
	}
	print("Mixed keys: ", mixed_keys)
	
	# Your example - integer key with array value
	var test = {
		1: ["oj"],
	}
	print("Test dict: ", test)

# ============================================================================
# 2. ACCESSING VALUES
# ============================================================================
func accessing_values():
	print("\n--- 2. ACCESSING VALUES ---")
	
	var player = {"name": "Hero", "health": 100, "mana": 50}
	
	# Bracket notation (works with any key type)
	print("Name (bracket): ", player["name"])
	print("Health (bracket): ", player["health"])
	
	# Dot notation (only for string keys)
	print("Name (dot): ", player.name)
	print("Mana (dot): ", player.mana)
	
	# Safe access with get() - returns default if key missing
	var value = player.get("name")
	print("Get name: ", value)
	
	var missing = player.get("age", 25)  # Returns 25 as default
	print("Get missing key with default: ", missing)

# ============================================================================
# 3. ADDING AND MODIFYING VALUES
# ============================================================================
func adding_modifying_values():
	print("\n--- 3. ADDING AND MODIFYING VALUES ---")
	
	var player = {}
	
	# Add new key-value pairs
	player["name"] = "Hero"
	player["health"] = 100
	print("After adding: ", player)
	
	# Modify existing values
	player["health"] = 80
	print("After modifying health: ", player)
	
	# Using dot notation
	player.mana = 50
	player.level = 5
	print("After dot notation adds: ", player)

# ============================================================================
# 4. REMOVING VALUES
# ============================================================================
func removing_values():
	print("\n--- 4. REMOVING VALUES ---")
	
	var player = {"name": "Hero", "health": 100, "mana": 50}
	print("Original: ", player)
	
	# Remove a specific key
	player.erase("mana")
	print("After erase mana: ", player)
	
	# Clear all entries
	var temp = {"a": 1, "b": 2, "c": 3}
	temp.clear()
	print("After clear: ", temp)

# ============================================================================
# 5. CHECKING FOR KEYS
# ============================================================================
func checking_keys():
	print("\n--- 5. CHECKING FOR KEYS ---")
	
	var player = {"name": "Hero", "health": 100}
	
	# Using has()
	if player.has("health"):
		print("Player has health!")
	
	# Using 'in' operator
	if "name" in player:
		print("Player has a name!")
	
	if not player.has("mana"):
		print("Player does NOT have mana")

# ============================================================================
# 6. ITERATING THROUGH DICTIONARIES
# ============================================================================
func iterating_dictionaries():
	print("\n--- 6. ITERATING THROUGH DICTIONARIES ---")
	
	var player = {"name": "Hero", "health": 100, "mana": 50}
	
	# Iterate over keys
	print("Keys only:")
	for key in player:
		print("  ", key)
	
	# Iterate over keys and values
	print("Keys and values:")
	for key in player:
		print("  ", key, " = ", player[key])
	
	# Using keys() and values()
	print("All keys: ", player.keys())
	print("All values: ", player.values())
	
	print("Values only:")
	for value in player.values():
		print("  ", value)

# ============================================================================
# 7. USEFUL DICTIONARY METHODS
# ============================================================================
func dictionary_methods():
	print("\n--- 7. USEFUL DICTIONARY METHODS ---")
	
	var player = {"name": "Hero", "health": 100}
	
	# Size and empty check
	print("Size: ", player.size())
	print("Is empty: ", player.is_empty())
	
	# Duplicate (copy)
	var copy = player.duplicate()
	copy["name"] = "Villain"
	print("Original: ", player)
	print("Copy: ", copy)
	
	# Merge dictionaries
	var dict1 = {"name": "Hero", "health": 100}
	var dict2 = {"mana": 50, "level": 5}
	dict1.merge(dict2)
	print("After merge: ", dict1)
	
	# Merge with overwrite
	var dict3 = {"health": 200}  # Same key as dict1
	dict1.merge(dict3, true)  # true = overwrite existing keys
	print("After merge with overwrite: ", dict1)
	
	# Hash (for comparison)
	var dict_a = {"a": 1, "b": 2}
	var dict_b = {"a": 1, "b": 2}
	print("Hashes equal: ", dict_a.hash() == dict_b.hash())

# ============================================================================
# 8. NESTED DICTIONARIES
# ============================================================================
func nested_dictionaries():
	print("\n--- 8. NESTED DICTIONARIES ---")
	
	var game_data = {
		"player": {
			"name": "Hero",
			"stats": {
				"health": 100,
				"mana": 50,
				"stamina": 80
			},
			"position": Vector3(0, 0, 0)
		},
		"enemies": [
			{"name": "Goblin", "health": 30},
			{"name": "Orc", "health": 50}
		],
		"settings": {
			"volume": 0.8,
			"fullscreen": false
		}
	}
	
	# Accessing nested data
	print("Player name: ", game_data["player"]["name"])
	print("Player health: ", game_data["player"]["stats"]["health"])
	print("First enemy: ", game_data["enemies"][0]["name"])
	print("Volume setting: ", game_data["settings"]["volume"])
	
	# Modifying nested data
	game_data["player"]["stats"]["health"] = 85
	print("Updated health: ", game_data["player"]["stats"]["health"])

# ============================================================================
# 9. PRACTICAL EXAMPLES
# ============================================================================
func practical_examples():
	print("\n--- 9. PRACTICAL EXAMPLES ---")
	
	# Example 1: Inventory System
	print("\nInventory System:")
	var inventory = inventory_example()
	
	# Example 2: Enemy Stats Database
	print("\nEnemy Stats Database:")
	enemy_stats_example()
	
	# Example 3: Settings/Configuration
	print("\nSettings Configuration:")
	settings_example()

# Inventory System Example
var inventory = {
	"sword": 1,
	"potion": 5,
	"gold": 250
}

func inventory_example() -> Dictionary:
	print("Starting inventory: ", inventory)
	
	add_item("potion", 3)
	print("After adding 3 potions: ", inventory)
	
	add_item("shield", 1)
	print("After adding shield: ", inventory)
	
	remove_item("potion", 4)
	print("After removing 4 potions: ", inventory)
	
	remove_item("sword", 1)
	print("After removing sword: ", inventory)
	
	return inventory

func add_item(item_name: String, amount: int = 1):
	if inventory.has(item_name):
		inventory[item_name] += amount
	else:
		inventory[item_name] = amount

func remove_item(item_name: String, amount: int = 1):
	if inventory.has(item_name):
		inventory[item_name] -= amount
		if inventory[item_name] <= 0:
			inventory.erase(item_name)

# Enemy Stats Database Example
var enemies = {
	"goblin": {"health": 30, "damage": 5, "speed": 100},
	"orc": {"health": 80, "damage": 15, "speed": 80},
	"dragon": {"health": 500, "damage": 50, "speed": 150}
}

func enemy_stats_example():
	print("All enemies: ", enemies.keys())
	
	for enemy_type in enemies:
		var stats = enemies[enemy_type]
		print("%s - HP: %d, DMG: %d, SPD: %d" % [
			enemy_type,
			stats["health"],
			stats["damage"],
			stats["speed"]
		])
	
	var spawned_goblin = spawn_enemy("goblin")
	print("Spawned goblin: ", spawned_goblin)

func spawn_enemy(enemy_type: String) -> Dictionary:
	if enemies.has(enemy_type):
		return enemies[enemy_type].duplicate()
	return {}

# Settings Configuration Example
var settings = {
	"volume": 0.8,
	"fullscreen": false,
	"resolution": Vector2(1920, 1080),
	"controls": {
		"jump": KEY_SPACE,
		"move_left": KEY_A,
		"move_right": KEY_D
	}
}

func settings_example():
	print("Current settings:")
	for setting in settings:
		if setting != "controls":
			print("  %s: %s" % [setting, settings[setting]])
	
	print("Controls:")
	for action in settings["controls"]:
		print("  %s: %s" % [action, settings["controls"][action]])
	
	# Modify settings
	settings["volume"] = 0.5
	settings["fullscreen"] = true
	print("\nAfter modifications:")
	print("  Volume: ", settings["volume"])
	print("  Fullscreen: ", settings["fullscreen"])

# ============================================================================
# IMPORTANT NOTES:
# ============================================================================
# 1. Keys are unique - adding same key twice overwrites the value
# 2. Order is preserved (Godot 3.1+)
# 3. Keys can be any type (int, String, Vector2, Objects, etc.)
# 4. Values can be any type (including other dictionaries and arrays)
# 5. Dictionaries are passed by reference - modifying in functions affects original
# 6. Use duplicate() or duplicate(true) for deep copy when needed
# 7. Dot notation only works with string keys that are valid identifiers
# 8. Use get() for safe access with default values
# ============================================================================
