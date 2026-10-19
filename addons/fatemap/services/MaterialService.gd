@tool
#marked tool so you can test it without running the scene.
extends RefCounted
class_name MaterialService

static var materialList:Array[materialModel]=[]
static var materialHashes:Dictionary={}
static var basicMaterial:Material=null
static var basicMaterialParams:Dictionary={}
static var materialSource:String="res://FateMap/Imported/"
static var hashMap:Dictionary={}

static func loadHashMap()->void:
	var f=FileAccess.open("res://FateMap/Imported/FMTHash.dat",FileAccess.READ)
	while not f.eof_reached():
		var line = f.get_line().split(":",true,1)
		if line.size()<2:continue
		hashMap[int(line[0])]=line[1]
	

static func setDefaultMaterialBase(material:Material,params:Dictionary={})->void:
	basicMaterial=material
	basicMaterialParams=params

static func addMaterial(materialName:StringName,material:Material=null,texture:Texture=null,params:Dictionary={},tags:PackedStringArray=[],path:String="")->bool:
	var ignoreBaseParams:bool=false
	if material==null:material=basicMaterial
	else:ignoreBaseParams=true
	var newMaterial=materialModel.new(materialName,params,path,ignoreBaseParams)
	if materialList.any(func(mat):return mat.checkConflict(newMaterial)):
		return false
	
	
	materialHashes[newMaterial.materialHash]=newMaterial
	newMaterial.setMaterial(material)
	newMaterial.setTexture(texture)
	newMaterial.setParameters(params)
	newMaterial.setTags(tags)
	newMaterial.updateMaterial()
	materialList.push_back(newMaterial)
	
	return true

static func getMaterialList()->Array[materialModel]:return materialList

static func getMaterial(materialName:StringName)->materialModel:
	var index = materialList.find_custom(func(mat):return mat.materialName==materialName)
	
	if index==-1:return null
	return materialList[index]

static func getMaterialByHash(materialHash:int)->materialModel:
	if not materialHashes.has(materialHash) and hashMap.has(materialHash):
		loadFMT(hashMap[materialHash])
	return materialHashes.get(materialHash,null)

static func loadAllFMT(path:String)->void:
	for d in DirAccess.get_directories_at(path):
		loadAllFMT(path+"/"+d)
	for f in DirAccess.get_files_at(path):
		if not f.ends_with(".fmt"):continue
		loadFMT(path+"/"+f)

static func loadFMT(fmtPath:String)->materialModel:
	if not FileAccess.file_exists(fmtPath):return null
	var file = FileAccess.open(fmtPath,FileAccess.READ)
	var contents = Array(file.get_as_text().split("\n",true))
	var values:Dictionary={}
	var nameLine = contents.find_custom(FMTLineParameterFind.bind("name"))
	var materialLine = contents.find_custom(FMTLineParameterFind.bind("material"))
	var textureLine = contents.find_custom(FMTLineParameterFind.bind("texture"))
	var parameterStartLine = contents.find_custom(FMTLineParameterFind.bind("parameters"))
	var tagStartLine = contents.find_custom(FMTLineParameterFind.bind("tags"))
	
	values["name"]=getValueOfFMTLine(contents[nameLine],"NONE")
	values["material"]=getValueOfFMTLine(contents[materialLine],"Default/defaultMaterial.material")
	values["texture"]=getValueOfFMTLine(contents[textureLine],"Default/defaultTexture.png")
	
	#parameters
	var parameterLines=getValueOfFMTLine(contents[parameterStartLine],"{}").strip_edges().trim_prefix("{").trim_suffix("}").split(",")
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
	var tagLines=getValueOfFMTLine(contents[tagStartLine],"").strip_edges().trim_prefix("[").trim_suffix("]").split(",")
	i=tagStartLine+1
	while contents.size()>i and contents[i].begins_with("\t"):
		var subLine=contents[i].strip_edges()
		if subLine.is_empty():continue
		tagLines.push_back(subLine)
		i+=1
	tagLines=",".join(tagLines)
	
	addMaterial(
		values.get("name"),
		load("res://FateMap/Imported/"+values.get("material")),
		load("res://FateMap/Imported/"+values.get("texture")),
		values.get("parameters",{}),
		values.get("tags","").split(","),
		fmtPath
	)
	
	return getMaterial(values.get("name","NONE"))

static func FMTLineParameterFind(line,compare)->bool:
	return line.split("=")[0].strip_edges(false)==compare

static func getValueOfFMTLine(line,default)->String:
	var sub=line.split("=",1)
	if sub.size()<1:return default
	return sub[1].strip_edges()


class materialModel extends Resource:
	var materialName:StringName
	var materialMat:Material
	var materialTexture:Texture
	var materialParameters:Dictionary={}
	var materialTags:PackedStringArray=[]
	var materialHash:int=0
	var path:String
	
	func _init(name:StringName=&"",params:Dictionary={},_path:String="",ignoreDefaultParams:bool=false):
		materialName=name
		path=_path
		materialHash=hash(_path.split(MaterialService.materialSource)[-1])
		if not ignoreDefaultParams:materialParameters=MaterialService.basicMaterialParams.duplicate(false)
		for parameter in params:
			materialParameters[parameter]=params[parameter]
		updateMaterial()
	
	
	
	func setTexture(texture:Texture)->void:
		materialTexture=texture
		updateMaterial()
	
	##sets the material and specifies to make it unique or shared
	func setMaterial(mat:Material,unique:bool=true)->void:
		if unique:
			materialMat=mat.duplicate(true)
		else:
			materialMat=mat
		materialMat.set_meta(&"FMT",self)
		updateMaterial()
	
	##Sets the parameters for the material using the provided dictionary
	func setParameters(parameterList:Dictionary={},ignoreDefaultParams:bool=false)->void:
		if not ignoreDefaultParams:materialParameters=MaterialService.basicMaterialParams.duplicate(false)
		for parameter in parameterList:
			materialParameters[parameter]=parameterList[parameter]
		updateMaterial()
	
	##applies tags to the material
	func setTags(tags:PackedStringArray)->void:
		materialTags=tags
	
	##returns an assembled copy of the material that can be shared or unique
	func getInstance(unique:bool=true)->Material:
		var materialInstance:Material
		if unique:materialInstance=materialMat.duplicate()
		else:materialInstance=materialMat
		
		return materialInstance
	
	##updates the material to keep up to date with current stored values
	func updateMaterial()->void:
		if materialMat is StandardMaterial3D:
			materialMat.albedo_texture=materialTexture
			var possibleParameters:Array=materialMat.get_property_list().map(func(param):return param.name)
			for param in materialParameters:
				if not possibleParameters.has(param):continue
				materialMat.set(param,materialParameters[param])
		if materialMat is ShaderMaterial:
			var shaderParameterList=(
				materialMat.get_property_list().filter(
					func(param):return param.name.begins_with("shader_parameter/")
				).map(func(param):return param.name.trim_prefix("shader_parameter/"))
			)
			if shaderParameterList.has("albedo_texture"):
				materialMat.set_shader_parameter(&"albedo_texture",materialTexture)
			for param in materialParameters:
				if not shaderParameterList.has(param):continue
				materialMat.set_shader_parameter(param,materialParameters[param])
	
	##check that the check material isn't conflicting with anything in this material
	func checkConflict(check:materialModel):
		return (
			check.materialHash==materialHash
			#check.materialName==materialName # old method
		)
