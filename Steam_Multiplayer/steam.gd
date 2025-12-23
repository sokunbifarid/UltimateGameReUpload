# global.gd (Add this to your autoload/singleton)
extends Node

func _init():
	# Initialize Steam BEFORE anything else
	# Use 480 for testing, or your actual App ID
	OS.set_environment("SteamAppId", str(480))
	OS.set_environment("SteamGameId", str(480))

func _ready():
	# Initialize Steam
	#developer commented code
	#var init_response: Dictionary = Steam.steamInitEx()
	#print("Steam Init Response: ", init_response)
	#
	#if init_response['status'] != 1:
		#print("ERROR: Failed to initialize Steam!")
		#print("Status: %s" % init_response['status'])
		#print("Verbal: %s" % init_response['verbal'])
		#return
	#
	#print("Steam initialized successfully!")
	#print("Steam ID: %s" % Steam.getSteamID())
	#print("Username: %s" % Steam.getPersonaName())
	pass
