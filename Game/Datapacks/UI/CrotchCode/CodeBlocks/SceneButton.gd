extends "res://Game/Datapacks/UI/CrotchCode/CodeBlockBase.gd"

var nameSlot := CrotchSlotVar.new()
var descSlot := CrotchSlotVar.new()
var stateSlot := CrotchSlotVar.new()
var codeSlot := CrotchSlotCalls.new()

func _init():
	nameSlot.setRawType(CrotchVarType.STRING)
	nameSlot.setRawValue("")
	descSlot.setRawType(CrotchVarType.STRING)
	descSlot.setRawValue("")
	stateSlot.setRawType(CrotchVarType.STRING)
	stateSlot.setRawValue("")

func getCategories():
	return ["Scene"]

func getType():
	return CrotchBlocks.CALL

func execute(_contex:CodeContex):
#	if(conditionSlot.isEmpty()):
#		throwError(_contex, "Condition can't be empty")
#		return false
#
#	if(conditionSlot.getValue(_contex)):
#		return thenSlot.execute(_contex)
	var nameText = nameSlot.getValue(_contex)
	var descText = descSlot.getValue(_contex)
	var nextState = stateSlot.getValue(_contex)
	
	_contex.addButton(nameText, descText, nextState, codeSlot)

func shouldExpandTemplate():
	return true

func getTemplate():
	return [
		{
			type = "label",
			text = "Button",
		},
		{
			type = "slot",
			id = "nameSlot",
			slot = nameSlot,
			slotType = CrotchBlocks.VALUE,
			placeholder = "Name",
		},
		{
			type = "slot",
			id = "descSlot",
			slot = descSlot,
			slotType = CrotchBlocks.VALUE,
			placeholder = "Decription",
			expand=true,
		},
		{
			type = "slot",
			id = "stateSlot",
			slot = stateSlot,
			slotType = CrotchBlocks.VALUE,
			placeholder = "State",
		},
		{
			type = "slot_list",
			id = "codeSlot",
			slot = codeSlot,
		},
	]

func getSlot(_id):
	if(_id == "nameSlot"):
		return nameSlot
	if(_id == "descSlot"):
		return descSlot
	if(_id == "stateSlot"):
		return stateSlot
	if(_id == "codeSlot"):
		return codeSlot

func getVisualBlockTheme():
	return themeControl

func updateEditor(_editor):
	if(_editor != null && _editor.has_method("getAllStateIDs")):
		stateSlot.setRawValue(_editor.getAllStateIDs()[0])

func updateVisualSlot(_editor, _id, _visSlot):
	if(_id == "stateSlot"):
		if(_editor != null && _editor.has_method("getAllStateIDs")):
			_visSlot.setPossibleValues(_editor.getAllStateIDs())
