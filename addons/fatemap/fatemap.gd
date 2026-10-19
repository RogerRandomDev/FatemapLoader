@tool
extends EditorPlugin

var tools=load("res://addons/fatemap/Tools/toolScripts.gd").new()

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_tool_menu_item("Create FMTs",tools.CreateFMTs)
	add_tool_menu_item("Update FMT hashmap",tools.updateFMTHashMap)
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_tool_menu_item("Create FMTs")
	remove_tool_menu_item("Update FMT hashmap")
	pass
