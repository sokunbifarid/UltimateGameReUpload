extends Node3D



var players_in_lobby: Array = []

func _ready() -> void:
	child_entered_tree.connect(new_player_joined)

func new_player_joined(new_player):
	if !players_in_lobby.has(new_player):
		players_in_lobby.append(new_player)

func sync_mesh():
	for p in players_in_lobby:
		if !p: 
			players_in_lobby.erase(p)
			continue
		print(p.change_mesh())
	
func _process(delta: float) -> void:
	print("players in lobby ;",players_in_lobby)
