extends RayCast3D
class_name RayCastFMT

func getFMT():
	var mat = getCollidingMaterial() as Material
	if mat==null:return
	return mat.get_meta(&"FMT")


func getCollidingMaterial():
	if is_colliding():
		var collision_at = get_collision_point()+get_collision_normal()*0.1-get_collider().global_position
		var obj=get_collider().get_parent().get_parent()
		for child:MeshInstance3D in obj.get_children():
			if child==null:continue
			if not child.mesh is FateFinalMesh:continue
			var intersectingSurface = child.mesh.getIntersectingSurface(
				collision_at,collision_at-get_collision_normal()*0.2
			)
			if intersectingSurface!=null:return intersectingSurface
	return null
