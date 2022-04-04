extends Module
class_name MedicalModule

const Eliza_IntroducedMedical = "Eliza_IntroducedMedical"
const Med_pcKnowsAboutWork = "Med_pcKnowsAboutWork"
const Med_pcKnowsAboutBreeding = "Med_pcKnowsAboutBreeding"
const Med_pcKnowsAboutTests = "Med_pcKnowsAboutTests"
const Med_pcKnowsAboutMilking = "Med_pcKnowsAboutBreeding"
const Med_milkingMilkFirstTime = "Med_milkingMilkFirstTime"
const Med_milkingSeedFirstTime = "Med_milkingSeedFirstTime"

const Med_milkMilked = "Med_milkMilked"
const Med_seedMilked = "Med_seedMilked"
const Med_milkedMilkTimes = "Med_milkedMilkTimes"
const Med_milkedSeedTimes = "Med_milkedSeedTimes"

const Med_wasMilkedToday = "Med_wasMilkedToday"

func _init():
	id = "MedicalModule"
	author = "Rahi"
	
	scenes = [
		"res://Modules/MedicalModule/ElizaTalkScene.gd",
		"res://Modules/MedicalModule/ElizaInducingLactation.gd",
		"res://Modules/MedicalModule/ElizaHandMilking.gd",
		"res://Modules/MedicalModule/ElizaMilkingPumps.gd",
		]
	characters = [
	]
	items = []
	events = [
		"res://Modules/MedicalModule/ElizaTalkEvent.gd",
	]

func resetFlagsOnNewDay():
	GM.main.setFlag(Med_wasMilkedToday, false)