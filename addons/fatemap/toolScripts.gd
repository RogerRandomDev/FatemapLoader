@tool
extends Node

var FMTCreatePopup=load("res://addons/fatemap/CreateFMTPopup.tscn")

const FMTBaseFormat="name = %s
material = Materials/Default/defaultMaterial.material
texture = Materials/%s
parameters = {}
tags = []"


func CreateFMTs()->void:
	var selector=FMTCreatePopup.instantiate()
	EditorInterface.get_base_control().add_child(selector)
	selector.popup()
	await selector.close_requested
	var list = selector.data
	selector.queue_free()
	if list==null:return
	for texture in list:
		var n=texture.rsplit("/",true,1)[-1]
		var FMTPath="res://FateMap/Imported/Materials/%s.fmt"%texture.rsplit(".",true,1)[0]
		if FileAccess.file_exists(FMTPath):continue
		print(FMTPath)
		var f=FileAccess.open(FMTPath,FileAccess.WRITE)
		f.store_string(FMTBaseFormat%[n,texture])
		f.close()
	
	
