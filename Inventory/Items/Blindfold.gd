extends ItemBase

func _init():
	id = "blindfold"

func getVisibleName():
	return "Blindfold"
	
func getDescription():
	return "A simple piece of cloth"

func getClothingSlot():
	return InventorySlot.Eyes

func getBuffs():
	return [
		buff(Buff.BlindfoldBuff),
		]

func getPrice():
	return 0

func canSell():
	return true

func getTags():
	return [ItemTag.BDSMRestraint]
