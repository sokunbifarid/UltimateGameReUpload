extends Node

var selected_level : PackedScene 
var selected_player : PackedScene = preload("res://Players/player.tscn")
var selected_lobby 
var selected_player_num : int = 1 
var joined_lobby_id

var players_meshes: Dictionary = {
	1:null,
	2:preload("res://Players/red_player.tscn"),
	3:preload("res://Players/blue_player.tscn")
}
