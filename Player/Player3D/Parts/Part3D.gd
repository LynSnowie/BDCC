extends Spatial

var dollSkeleton: DollSkeleton
var doll3D
var attachProxies = []
var partPickers = {}

func initPart(newDoll3d):
	doll3D = newDoll3d
	dollSkeleton = doll3D.getDollSkeleton()
	
	for child in get_children():
		setSkeletonRecursive(child, dollSkeleton.getSkeleton())
#		if(child is MeshInstance):
#			#child.skeleton = dollSkeleton.getSkeleton().get_path()
#			child.skeleton = child.get_path_to(dollSkeleton.getSkeleton())

func onRemoved():
	for proxy in attachProxies:
		doll3D.removeDollAttachmentZone(proxy.dollAttachmentZone)

func setSkeletonRecursive(childnode, skeleton):
	if(childnode is MeshInstance):
		childnode.skeleton = childnode.get_path_to(skeleton)
		childnode.software_skinning_transform_normals = false # Removing this will make Software Skinning break so don't
		
		if(childnode.mesh != null):
			for _i in range(childnode.mesh.get_surface_count()):
				var material = childnode.mesh.surface_get_material(_i)
				if(material is SpatialMaterial):
					material.flags_unshaded = true
					material.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_OPAQUE_ONLY
					material.params_cull_mode = SpatialMaterial.CULL_DISABLED
			for _i in range(childnode.get_surface_material_count()):
				var material = childnode.get_surface_material(_i)
				if(material is SpatialMaterial):
					material.flags_unshaded = true
					material.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_OPAQUE_ONLY
					material.params_cull_mode = SpatialMaterial.CULL_DISABLED
				
	if(childnode is MyBoneAttachment):
		childnode.setSkeletonPath(childnode.get_path_to(skeleton))
	if(childnode is AttachmentProxy):
		attachProxies.append(childnode)
	if(childnode is PartStatePicker):
		if(!partPickers.has(childnode.getState())):
			partPickers[childnode.getState()] = []
		partPickers[childnode.getState()].append(childnode)
	
	for child in childnode.get_children():
		setSkeletonRecursive(child, skeleton)

func setStateRecursive(childnode, stateID, value):
	if(childnode is PartStatePicker):
		if(childnode.getState() == stateID):
			childnode.setValue(value)
	
	for child in childnode.get_children():
		setStateRecursive(child, stateID, value)

func setState(stateID, value):
	if(!partPickers.has(stateID)):
		return
	for picker in partPickers[stateID]:
		picker.setValue(value)
	#setStateRecursive(self, stateID, value)

func setShapeKeyValue(shapekey: String, value: float):
	setShapeKeyValueRecursive(self, shapekey, value)

func setShapeKeyValueRecursive(childnode, shapekey: String, value: float):
	if(childnode is MeshInstance):
		childnode.set("blend_shapes/"+shapekey, value)
	
	for child in childnode.get_children():
		setShapeKeyValueRecursive(child, shapekey, value)

func getAttachProxies():
	return attachProxies
