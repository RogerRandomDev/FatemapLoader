@tool
extends EditorPlugin

var tools=load("res://addons/fatemap/Tools/toolScripts.gd").new()

var fmt_import

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
	# Create Importer
	fmt_import=preload("res://addons/fatemap/Importers/FMTImport.gd").new()
	add_import_plugin(fmt_import)
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_tool_menu_item("Create FMTs")
	remove_tool_menu_item("Update FMT hashmap")
	# Remove Importer
	remove_import_plugin(fmt_import)
	fmt_import=null
	pass
