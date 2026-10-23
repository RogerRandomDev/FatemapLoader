@tool
extends EditorImportPlugin

func _get_importer_name():
	return "FateMap.FateMaterial"

func _get_visible_name():
	return "Fate Material"

func _get_recognized_extensions():
	return ["fmt"]

func _get_save_extension():
	return "res"

func _get_resource_type():
	return "Resource"

func _get_import_options(path, preset_index):
	return []

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var contents = Array(file.get_as_text().split("\n",true))
	var values:Dictionary={}
	var nameLine = contents.find_custom(MaterialService.FMTLineParameterFind.bind("name"))
	var materialLine = contents.find_custom(MaterialService.FMTLineParameterFind.bind("material"))
	var textureLine = contents.find_custom(MaterialService.FMTLineParameterFind.bind("texture"))
	var parameterStartLine = contents.find_custom(MaterialService.FMTLineParameterFind.bind("parameters"))
	var tagStartLine = contents.find_custom(MaterialService.FMTLineParameterFind.bind("tags"))
	
	values["name"]=MaterialService.getValueOfFMTLine(contents[nameLine],"NONE")
	values["material"]=MaterialService.getValueOfFMTLine(contents[materialLine],"Default/defaultMaterial.material")
	values["texture"]=MaterialService.getValueOfFMTLine(contents[textureLine],"Default/defaultTexture.png")
	
	#parameters
	var parameterLines=MaterialService.getValueOfFMTLine(contents[parameterStartLine],"{}").strip_edges().trim_prefix("{").trim_suffix("}").split(",")
	var i:int=parameterStartLine+1
	while contents[i].begins_with("\t"):
		var split_sub=contents[i].split("=")
		split_sub[0]="\"%s\""%split_sub[0].strip_edges()
		var subLine=":".join(split_sub).strip_edges()
		if subLine.length()<2:continue
		parameterLines.push_back(subLine)
		i+=1
	parameterLines=",".join(parameterLines)
	parameterLines = "{%s}"%parameterLines.trim_prefix(",")
	if not parameterLines.contains(":"):values["parameters"]={}
	else:values["parameters"]=JSON.parse_string(parameterLines)
	#tags
	var tagLines=MaterialService.getValueOfFMTLine(contents[tagStartLine],"").strip_edges().trim_prefix("[").trim_suffix("]").split(",")
	i=tagStartLine+1
	while contents.size()>i and contents[i].begins_with("\t"):
		var subLine=contents[i].strip_edges()
		if subLine.is_empty():continue
		tagLines.push_back(subLine)
		i+=1
	tagLines=",".join(tagLines)
	
	var material=FMTImportedResource.new()
	material.materialName=values.get("name")
	material.materialMat=values.get("material")
	material.materialTexture=values.get("texture")
	material.materialParameters=values.get("parameters",{})
	material.materialTags=values.get("tags","").split(",")
	material.path=source_file
	return ResourceSaver.save(material, "%s.%s" % [save_path, _get_save_extension()])
