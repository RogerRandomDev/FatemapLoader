@tool
extends Node

var FMTCreatePopup=load("res://addons/fatemap/Tools/CreateFMTPopup.tscn")

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
		var f=FileAccess.open(FMTPath,FileAccess.WRITE)
		f.store_string(FMTBaseFormat%[n,texture])
		f.close()

func updateFMTHashMap()->void:
	var root="res://FateMap/Imported"
	var allSubDirectories=_getSubDirectory(root)
	var allFMTs:Array=[]
	for dir in allSubDirectories:
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".fmt"):continue
			allFMTs.push_back(dir+"/"+file)
	root+="/"
	var fmtHashes:Dictionary={}
	for fmt in allFMTs:
		fmtHashes[hash(fmt.trim_prefix(root))]=fmt
	var f=FileAccess.open("res://FateMap/Imported/FMTHash.dat",FileAccess.WRITE)
	for h in fmtHashes:
		f.store_line(str(h)+":"+fmtHashes[h])
	f.close()

func _getSubDirectory(path):
	var fullList=[]
	for dir in DirAccess.get_directories_at(path):
		fullList.push_back(path+"/"+dir)
		fullList.append_array(_getSubDirectory(path+"/"+dir))
	return fullList
	
