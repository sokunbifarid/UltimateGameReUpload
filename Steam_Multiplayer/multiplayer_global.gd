extends Node

var main_menu_scene : PackedScene = preload("res://Scenes/3dmain_menu.tscn")
var character_selection_scene : PackedScene = preload("res://Scenes/character_selection.tscn")

var selected_level : PackedScene 
var selected_player : PackedScene = preload("res://Scenes/player.tscn")
var selected_lobby 


var joined_lobby_id
