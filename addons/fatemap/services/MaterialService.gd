#marked tool so you can test it without running the scene.
extends Node

var materialList:Array[materialModel]=[]
var materialHashes:Dictionary={}
var basicMaterial:Material=null
var basicMaterialParams:Dictionary={}
var materialSource:String="res://FateMap/Imported/"
var hashMap:Dictionary={}

func loadHashMap()->void:
	var f=FileAccess.open("res://FateMap/Imported/FMTHash.dat",FileAccess.READ)
	while not f.eof_reached():
		var line = f.get_line().split(":",true,1)
		if line.size()<2:continue
		hashMap[int(line[0])]=line[1]
	

func setDefaultMaterialBase(material:Material,params:Dictionary={})->void:
	basicMaterial=material
	basicMaterialParams=params

func addMaterial(materialName:StringName,material:Material=null,texture:Texture=null,params:Dictionary={},tags:PackedStringArray=[],path:String="")->bool:
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

func getMaterialList()->Array[materialModel]:return materialList

func getMaterial(materialName:StringName)->materialModel:
	var index = materialList.find_custom(func(mat):return mat.materialName==materialName)
	
	if index==-1:return null
	return materialList[index]

func getMaterialByHash(materialHash:int)->materialModel:
	if not materialHashes.has(materialHash) and hashMap.has(materialHash):
		loadFMT(hashMap[materialHash])
	return materialHashes.get(materialHash,null)

func loadAllFMT(path:String)->void:
	for d in DirAccess.get_directories_at(path):
		loadAllFMT(path+"/"+d)
	for f in DirAccess.get_files_at(path):
		if not f.ends_with(".fmt"):continue
		loadFMT(path+"/"+f)

func loadFMT(fmtPath:String)->materialModel:
	if not FileAccess.file_exists(fmtPath):return null
	var fmt:FMTImportedResource=load(fmtPath)
	
	addMaterial(
		fmt.materialName,
		load(fmt.materialMat),
		load(fmt.materialTexture),
		fmt.materialParameters,
		fmt.materialTags,
		fmtPath
	)
	
	return getMaterial(fmt.materialName)


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
