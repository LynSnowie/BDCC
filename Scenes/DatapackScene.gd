extends "res://Scenes/SceneBase.gd"

var datapackID = ""
var datapackSceneID = ""
var datapack:Datapack
var datapackScene:DatapackScene
var codeContex:DatapackSceneCodeContext

func _init():
	sceneID = "DatapackScene"

func _initScene(_args = []):
	datapackID = _args[0]
	datapackSceneID = _args[1]
	
	datapack = GlobalRegistry.getDatapack(datapackID)
	datapackScene = datapack.getScene(datapackSceneID)
	
	codeContex = DatapackSceneCodeContext.new()
	codeContex.setScene(self)
	codeContex.setDatapack(datapack)
	codeContex.setDatapackScene(datapackScene)

func _run():
	if(datapack == null || datapackScene == null):
		saynn("[color=red]Error[/color] Sorry, datapack or scene from this datapack no longer exists")
		addButton("Close", "Close this scene", "endthescene")
		return
	
	codeContex.run()

func _react(_action: String, _args):
	if(codeContex.react(_action, _args)):
		return
	
	if(_action == "endthescene"):
		endScene()
		return

	setState(_action)

func saveData():
	var data = .saveData()
	
	data["datapackID"] = datapackID
	data["datapackSceneID"] = datapackSceneID
	data["codeContex"] = codeContex.saveData()

	return data
	
func loadData(data):
	.loadData(data)
	
	datapackID = SAVE.loadVar(data, "datapackID", "")
	datapackSceneID = SAVE.loadVar(data, "datapackSceneID", "")

	datapack = GlobalRegistry.getDatapack(datapackID)
	datapackScene = datapack.getScene(datapackSceneID)

	codeContex = DatapackSceneCodeContext.new()
	codeContex.setScene(self)
	codeContex.setDatapack(datapack)
	codeContex.setDatapackScene(datapackScene)
	codeContex.loadData(SAVE.loadVar(data, "codeContex", {}))
