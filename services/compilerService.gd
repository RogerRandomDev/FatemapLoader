extends Node
class_name compilerService
##used to compile/decompile a map into its own file

#region general utilities

### DECODERS

static func decodeVector3Float(from:int=0,data:PackedByteArray=[],half_precision:bool=false)->Vector3:
	if half_precision:
		return Vector3(
			data.decode_half(from),
			data.decode_half(from+2),
			data.decode_half(from+4)
		)
	return Vector3(
		data.decode_float(from),
		data.decode_float(from+4),
		data.decode_float(from+8)
	)

static func decodeVector2Float(from:int=0,data:PackedByteArray=[])->Vector2:
	return Vector2(
		data.decode_float(from),
		data.decode_float(from+4)
	)

static func decodeInt(from:int=0,value:PackedByteArray=[],signed:bool=false,size:int=0)->int:
	var decoded:int=0
	match size:
		0:
			if signed:decoded = value.decode_s8(from)
			else:decoded = value.decode_u8(from)
		1:
			if signed:decoded = value.decode_s16(from)
			else:decoded = value.decode_u16(from)
		2:
			if signed:decoded = value.decode_s32(from)
			else:decoded = value.decode_u32(from)
		3:
			if signed:decoded = value.decode_s64(from)
			else:decoded = value.decode_u64(from)
	return decoded

static func decodeFloat(from:int=0,value:PackedByteArray=[])->float:
	return value.decode_float(from)

static func paramValueDecode(paramValue,decompiler:compilerService.decompilerInfo)->Array:
	var decoded:Array=[null,null]
	var skipBytes=0
	match paramValue.decode_u8(0):
		TYPE_INT:
			decoded[0]=&"Integer"
			var precision=!decompiler.formatParameters.get("precision:32_bit_integers",false)
			decoded[1]=decodeInt(1,paramValue,true,2+int(precision))
			skipBytes=4<<int(precision)
		TYPE_FLOAT:
			decoded[0]=&"Float"
			decoded[1]=decodeFloat(1,paramValue)
			skipBytes=4
		TYPE_VECTOR2:
			decoded[0]=&"Vector2"
			decoded[1]=decodeVector2Float(1,paramValue)
			skipBytes=8
		TYPE_VECTOR3:
			decoded[0]=&"Vector3"
			#decoded[1]=decompiler.vector3List[paramValue.decode_u32(1)]
			#skipBytes=4
			decoded[1]=compilerService.decodeVector3Float(1,paramValue)
			skipBytes=12
		TYPE_COLOR:
			decoded[0]=&"Color"
			decoded[1]=Color.from_rgba8(paramValue.decode_u8(1),paramValue.decode_u8(2),paramValue.decode_u8(3),paramValue.decode_u8(4))
			skipBytes=4
		TYPE_BOOL:
			decoded[0]=&"Boolean"
			decoded[1]=bool(paramValue[1])
			skipBytes=1
		TYPE_OBJECT:
			#needs done still
			pass
		TYPE_STRING:
			decoded[0]=&"Text"
			decoded[1]=decompiler.stringList[decodeInt(1,paramValue,false,2)]
			skipBytes=4
		TYPE_STRING+64:
			decoded[0]=&"File"
			decoded[1]=decompiler.stringList[decodeInt(1,paramValue,false,2)]
			skipBytes=4
	return [decoded,skipBytes]

static func paramsDecode(parameters:PackedByteArray,decompiler:compilerService.decompilerInfo)->Dictionary:
	var decoded:Dictionary={}
	var paramCount:int=parameters.decode_u16(0)
	var checkFrom:int=2
	for i in paramCount:
		var paramNameID:int=parameters.decode_u32(checkFrom)
		decoded[decompiler.stringList[paramNameID]]=null
		checkFrom+=4
	checkFrom+=2
	parameters=parameters.slice(checkFrom)
	for i in decoded.keys():
		var paramValueData:Array=paramValueDecode(parameters,decompiler)
		parameters=parameters.slice(paramValueData[1]+1)
		var paramValue=paramValueData[0]
		decoded[i]=paramValue
		
	
	return decoded

#endregion

#region decompiler class

class decompilerInfo extends RefCounted:
	var stringList:Array=[]
	var materialList:Array[MaterialService.materialModel]=[]
	
	var objectList:Array=[]
	
	var formatVersion:int=0
	var formatParameters:Dictionary={}
	
	func loadFormat(formatData:PackedByteArray)->void:
		formatVersion=formatData.decode_u16(0)
		formatParameters=bytes_to_var(formatData.slice(6))
	
