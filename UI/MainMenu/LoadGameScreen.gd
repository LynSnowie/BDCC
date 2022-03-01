extends Control

onready var savesContainer = $VBoxContainer/ScrollContainer/ScrollVBox/SavesContainer
var saveGameElemenetScene = preload("res://UI/MainMenu/SaveGameElement.tscn")
signal onClosePressed
var inDeleteMode = false

func _ready():
	updateSaves()

func updateSaves():
	Util.delete_children(savesContainer)
	
	var savesPaths = SAVE.getSavesSortedByDate()
	
	for savePath in savesPaths:
		var saveGameElementObject = saveGameElemenetScene.instance()
		savesContainer.add_child(saveGameElementObject)
		saveGameElementObject.setSaveFile(savePath)
		saveGameElementObject.connect("onLoadButtonPressed", self, "onSaveLoadButtonClicked")
		saveGameElementObject.connect("onDeleteButtonPressed", self, "onDeleteButtonClicked")
		saveGameElementObject.setDeleteMode(inDeleteMode)
		
func onSaveLoadButtonClicked(savePath):
	SAVE.switchToGameAndLoad(savePath)

func onDeleteButtonClicked(savePath):
	SAVE.deleteSave(savePath)
	updateSaves()

func _on_CloseButton_pressed():
	emit_signal("onClosePressed")


func _on_LoadGameScreen_visibility_changed():
	if(visible):
		updateSaves()


func _on_DeleteButton_pressed():
	inDeleteMode = !inDeleteMode
	updateSaves()
