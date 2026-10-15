extends ArrayMesh
class_name FateFinalMesh

var fmtMeshes:Array[TriangleMesh]=[]



func getIntersectingSurface(from:Vector3,to:Vector3):
	for i in fmtMeshes.size():
		var mesh = fmtMeshes[i]
		if not mesh.intersect_segment(from,to).is_empty():
			return surface_get_material(i)
	return null
