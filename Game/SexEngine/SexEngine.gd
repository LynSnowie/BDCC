extends Reference
class_name SexEngine

var activities:Array = []

var messages:Array = []
var state = "start" # start, waitingForPCSub, waitingForPCDom
var waitingActivityID

var doms = {}
var subs = {}

var currentLastActivityID = 0

var sexEnded = false

func initPeople(domIDs, subIDs):
	if(domIDs is String):
		domIDs = [domIDs]
	if(subIDs is String):
		subIDs = [subIDs]
	
	for domID in domIDs:
		var domInfo = SexDomInfo.new()
		domInfo.initInfo(domID)
		
		doms[domID] = domInfo
		
	for subID in subIDs:
		var subInfo = SexSubInfo.new()
		subInfo.initInfo(subID)
		
		subs[subID] = subInfo

func makeActivity(id, theDomID, theSubID):
	var activityObject = GlobalRegistry.createSexActivity(id)
	if(activityObject == null):
		return null
	
	activityObject.uniqueID = currentLastActivityID
	activityObject.sexEngineRef = weakref(self)
	activities.append(activityObject)
	activityObject.initParticipants(theDomID, theSubID)
	currentLastActivityID += 1
	return activityObject

func processText(thetext, theDomID, theSubID):
	return GM.ui.processString(thetext, {dom=theDomID, sub=theSubID})

func addText(thetext, theDomID, theSubID):
	messages.append(processText(thetext, theDomID, theSubID))

func combineData(firstData, secondData):
	if(firstData == null && secondData == null):
		return null
	if(firstData == null):
		return secondData
	if(secondData == null):
		return firstData
	
	var texts = []
	var domSays = []
	var subSays = []
	
	for data in [firstData, secondData]:
		if(data.has("text")):
			texts.append(data["text"])
		if(data.has("domSay") && data["domSay"] != null):
			domSays.append(data["domSay"])
		if(data.has("subSay") && data["subSay"] != null):
			subSays.append(data["subSay"])
		
	var resultData = {}
	if(texts.size() > 0):
		resultData["text"] = Util.join(texts, " ")
	if(domSays.size() > 0):
		resultData["domSay"] = RNG.pick(domSays)
	if(subSays.size() > 0):
		resultData["subSay"] = RNG.pick(subSays)
	return resultData

func reactToActivityEnd(theactivity):
	var resultData = null
	
	for activity in activities:
		if(activity.hasEnded || activity == theactivity):
			continue
		
		resultData = combineData(resultData, activity.reactActivityEnd(theactivity))
	
	return resultData

func startActivity(id, theDomID, theSubID, _args = null, startedBySub = false):
	var activity = makeActivity(id, theDomID, theSubID)
	if(activity == null):
		return
		
	var startData = activity.startActivity(_args)
	if(activity.hasEnded):
		startData = combineData(startData, reactToActivityEnd(activity))
	
	if(startData != null):
		if(startData.has("text")):
			addText(startData["text"], theDomID, theSubID)
		
		if(!startedBySub):
			if(startData.has("domSay") && startData["domSay"] != null):
				addText("[say=dom]"+startData["domSay"]+"[/say]", activity.domID, activity.subID)

			elif(startData.has("subSay") && startData["subSay"] != null):
				addText("[say=sub]"+startData["subSay"]+"[/say]", activity.domID, activity.subID)
		else:
			if(startData.has("subSay") && startData["subSay"] != null):
				addText("[say=sub]"+startData["subSay"]+"[/say]", activity.domID, activity.subID)
	
			elif(startData.has("domSay") && startData["domSay"] != null):
				addText("[say=dom]"+startData["domSay"]+"[/say]", activity.domID, activity.subID)
	
func switchActivity(oldActivity, newActivityID, _args = []):
	oldActivity.endActivity()
	
	var activityObject = makeActivity(newActivityID, oldActivity.domID, oldActivity.subID)
	if(activityObject == null):
		return
	
	var startData = activityObject.onSwitchFrom(oldActivity, _args)
	if(startData != null && startData.has("text")):
		addText(startData["text"], oldActivity.domID, oldActivity.subID)

func getActivityWithUniqueID(uniqueID):
	for activity in activities:
		if(activity.uniqueID == uniqueID):
			return activity
	return null

func generateGoals():
	var amountToGenerate = 2
	
	for domID in doms:
		if(domID == "pc"):
			continue
		
		var personDomInfo = doms[domID]
		var possibleGoals = []
		
		var dom = personDomInfo.getChar()
		
		for subID in subs:
			var personSubInfo = subs[subID]
			var sub = personSubInfo.getChar()
			
			var goalsToAdd = dom.getFetishHolder().getGoals(self, sub)
			if(goalsToAdd != null):
				for goal in goalsToAdd:
					var sexGoal:SexGoalBase = GlobalRegistry.getSexGoal(goal[0])
					if(sexGoal.isPossible(self, dom, sub) && !sexGoal.isCompleted(self, dom, sub)):
						possibleGoals.append([[goal[0], sub.getID()], goal[1]])
		
		if(possibleGoals.size() > 0):
			for _i in range(0, amountToGenerate):
				var randomGoalInfo = RNG.pickWeightedPairs(possibleGoals)
				personDomInfo.goals.append(randomGoalInfo)
			
		print(personDomInfo.goals)
	
	#domInfo.goals.append([SexGoal.Fuck, subID])
	
	#startActivity("SexFuckTest", domID, subID)
	#startActivity("SexFuckTest2", domID, subID)
	#startActivity("SexFuckExample", domID, subID)

func hasGoal(thedominfo, goal, thesubinfo):
	for goalInfo in thedominfo.goals:
		if(goalInfo[0] == goal && goalInfo[1] == thesubinfo.charID):
			return true
	return false

func satisfyGoal(thedominfo, goalid, thesubinfo):
	for _i in range(0, thedominfo.goals.size()):
		var goalInfo = thedominfo.goals[_i]
		
		if(goalInfo[0] == goalid && goalInfo[1] == thesubinfo.charID):
			thedominfo.goals.remove(_i)
			print(str(thedominfo.charID)+"'s goal to "+str(goalInfo[0])+" "+str(goalInfo[1])+" was satisfied")
			return true
	return false

func getDomInfo(theDomID) -> SexDomInfo:
	if(!doms.has(theDomID)):
		return null
	return doms[theDomID]

func getSubInfo(theSubID) -> SexSubInfo:
	if(!subs.has(theSubID)):
		return null
	return subs[theSubID]

func isDom(charID):
	if(!doms.has(charID)):
		return false
	return true

func isSub(charID):
	if(!subs.has(charID)):
		return false
	return true

func checkFailedAndCompletedGoals():
	for domID in doms:
		var domInfo = doms[domID]
		var domChar = domInfo.getChar()
		
		for i in range(domInfo.goals.size() - 1, -1, -1):
			var subChar = getSubInfo(domInfo.goals[i][1]).getChar()
			
			var sexGoal:SexGoalBase = GlobalRegistry.getSexGoal(domInfo.goals[i][0])
			if(sexGoal.isCompleted(self, domChar, subChar)):
				print("GOAL "+str(sexGoal.getVisibleName())+" "+str(domID)+" "+str(domInfo.goals[i][1])+" got completed")
				domInfo.goals.remove(i)
			elif(!sexGoal.isPossible(self, domChar, subChar)):
				print("GOAL "+str(sexGoal.getVisibleName())+" "+str(domID)+" "+str(domInfo.goals[i][1])+" is impossible, removed")
				domInfo.goals.remove(i)

func removeEndedActivities():
	for i in range(activities.size() - 1, -1, -1):
		if(activities[i].hasEnded):
			activities.remove(i)
			
	checkFailedAndCompletedGoals()

func processTurn():
	removeEndedActivities()
	
	var processMessages = []
	var subMessages = []
	var domMessages = []
	
	for domID in doms:
		var domInfo = doms[domID]
		
		if(domInfo.checkIsDown()):
			processMessages.append(processText("{dom.You} can't continue anymore!", domID, domID))
			
			for i in range(activities.size() - 1, -1, -1):
				if(activities[i].domID == domID):
					activities.remove(i)
			continue
			
		domInfo.processTurn()
	for subID in subs:
		var subInfo = subs[subID]
		subInfo.processTurn()
	
	for activity in activities:
		if(activity.hasEnded):
			continue
		var processResult = activity.processTurn()
		if(processResult != null):
			if(processResult.has("text")):
				processMessages.append(processText(processResult["text"], activity.domID, activity.subID))
			
			if(processResult.has("domSay") && processResult["domSay"] != null):
				domMessages.append(processText("[say=dom]"+processResult["domSay"]+"[/say]", activity.domID, activity.subID))

			elif(processResult.has("subSay") && processResult["subSay"] != null):
				subMessages.append(processText("[say=sub]"+processResult["subSay"]+"[/say]", activity.domID, activity.subID))
		
	if(processMessages.size() > 0):
		messages.append(Util.join(processMessages, " "))
	
	if(domMessages.size() > 0):
		messages.append(RNG.pick(domMessages))
		
	if(subMessages.size() > 0):
		messages.append(RNG.pick(subMessages))
		
	removeEndedActivities()
	
func getSubIDs():
	return subs.keys()
	
func getDomIDs():
	return doms.keys()
	
func hasAnyAcitivites(charID):
	for activity in activities:
		if(activity.hasEnded):
			continue
		if(activity.subID == charID || activity.domID == charID):
			return true
	return false
	
func processAIActions(isDom = true):
	if(sexEnded):
		return
	
	var peopleToCheck = [
	]
	if(isDom):
		peopleToCheck = doms
	else:
		peopleToCheck = subs
	
	for personID in peopleToCheck:
		var theinfo = peopleToCheck[personID]
		if(personID == "pc"):
			continue
		
		var possibleActions = []
		var actionsScores = []
		if(hasAnyAcitivites(personID)):
			possibleActions = [{id="donothing"}]
			actionsScores = [0.01]
		
		# if is dom
		if(isDom(personID)):
			var allSexActivities = GlobalRegistry.getSexActivityReferences()
			for possibleSexActivityID in allSexActivities:
				var newSexActivityRef = allSexActivities[possibleSexActivityID]
				
				for subID in subs:
					var subInfo = subs[subID]
					if(!newSexActivityRef.canBeStartedByDom()):
						continue
					
					if(!newSexActivityRef.canStartActivity(self, theinfo, subInfo)):
						continue
					
					var newpossibleActions = newSexActivityRef.getStartActions(self, theinfo, subInfo)
					if(possibleActions == null):
						continue
					
					for newaction in newpossibleActions:
						var score = newaction["score"]
						if(score > 0.0):
							possibleActions.append({
								id = "startNewDomActivity",
								activityID = possibleSexActivityID,
								subID = subInfo.charID,
								args = newaction["args"],
							})
							actionsScores.append(score)
		
		if(isSub(personID)):
			var allSexActivities = GlobalRegistry.getSexActivityReferences()
			for possibleSexActivityID in allSexActivities:
				var newSexActivityRef = allSexActivities[possibleSexActivityID]
				
				for domID in doms:
					var domInfo = doms[domID]
					if(!newSexActivityRef.canBeStartedBySub()):
						continue
					
					if(!newSexActivityRef.canStartActivity(self, domInfo, theinfo)):
						continue
					
					var newpossibleActions = newSexActivityRef.getStartActions(self, domInfo, theinfo)
					if(possibleActions == null):
						continue
					
					for newaction in newpossibleActions:
						var score = newaction["score"]
						if(score > 0.0):
							possibleActions.append({
								id = "startNewSubActivity",
								activityID = possibleSexActivityID,
								domID = domInfo.charID,
								args = newaction["args"],
							})
							actionsScores.append(score)
		
		
		for activity in activities:
			if(activity.hasEnded):
				continue
			if(activity.domID == personID):
				var domActions = activity.getDomActions()
				if(domActions != null):
					for action in domActions:
						possibleActions.append({
							id = "domAction",
							activityID = activity.uniqueID,
							action = action,
						})
						if(action.has("score")):
							actionsScores.append(max(action["score"], 0.0))
						else:
							actionsScores.append(1.0)
				
			if(activity.subID == personID):
				var subActions = activity.getSubActions()
				if(subActions != null):
					for action in subActions:
						possibleActions.append({
							id = "subAction",
							activityID = activity.uniqueID,
							action = action,
						})
						if(action.has("score")):
							actionsScores.append(max(action["score"], 0.0))
						else:
							actionsScores.append(1.0)

		if(possibleActions.size() > 0 && theinfo.canDoActions()):
			var totalScore = 0.0
			for thescore in actionsScores:
				if(thescore > 0.0):
					totalScore += thescore
			
			if(RNG.chance(totalScore * 100.0)):
				var pickedFinalAction = RNG.pickWeighted(possibleActions, actionsScores)
				
				if(pickedFinalAction["id"] == "domAction"):
					var activity = getActivityWithUniqueID(pickedFinalAction["activityID"])
					doDomAction(activity, pickedFinalAction["action"])
				if(pickedFinalAction["id"] == "subAction"):
					var activity = getActivityWithUniqueID(pickedFinalAction["activityID"])
					doSubAction(activity, pickedFinalAction["action"])
				if(pickedFinalAction["id"] == "startNewDomActivity"):
					startActivity(pickedFinalAction["activityID"], personID, pickedFinalAction["subID"], pickedFinalAction["args"])
				if(pickedFinalAction["id"] == "startNewSubActivity"):
					startActivity(pickedFinalAction["activityID"], pickedFinalAction["domID"], personID, pickedFinalAction["args"])

	removeEndedActivities()
	
	if(sexShouldEnd()):
		endSex()

func doDomAction(activity, action):
	var actionResult = activity.doDomAction(action["id"], action)
	if(activity.hasEnded):
		actionResult = combineData(actionResult, reactToActivityEnd(activity))
	
	if(actionResult != null):
		if(actionResult.has("text")):
			addText(actionResult["text"], activity.domID, activity.subID)
		
		if(actionResult.has("domSay") && actionResult["domSay"] != null):
			addText("[say=dom]"+actionResult["domSay"]+"[/say]", activity.domID, activity.subID)

		elif(actionResult.has("subSay") && actionResult["subSay"] != null):
			addText("[say=sub]"+actionResult["subSay"]+"[/say]", activity.domID, activity.subID)


func doSubAction(activity, action):
	var actionResult = activity.doSubAction(action["id"], action)
	if(activity.hasEnded):
		actionResult = combineData(actionResult, reactToActivityEnd(activity))
	
	if(actionResult != null):
		if(actionResult.has("text")):
			addText(actionResult["text"], activity.domID, activity.subID)
		
		if(actionResult.has("subSay") && actionResult["subSay"] != null):
			addText("[say=sub]"+actionResult["subSay"]+"[/say]", activity.domID, activity.subID)

		elif(actionResult.has("domSay") && actionResult["domSay"] != null):
			addText("[say=dom]"+actionResult["domSay"]+"[/say]", activity.domID, activity.subID)

func start():
	if(!isDom("pc")):
		processAIActions(true)
		processAIActions(false)
		processTurn()

func getFinalText():
	return Util.join(messages, "\n\n")

func getActions():
	var result = []
	result.append({
		id = "continue",
		name = "Continue",
		desc = "Just continue doing what you're doing",
	})
	
	for activity in activities:
		if(activity.hasEnded):
			continue
		if(activity.domID == "pc" && getDomInfo("pc").canDoActions()):
			var domActions = activity.getDomActions()
			if(domActions != null):
				for action in domActions:
					result.append({
						id = "domAction",
						activityID = activity.uniqueID,
						action = action,
						name = action["name"],
						desc = action["desc"],
					})
		if(activity.subID == "pc" && getSubInfo("pc").canDoActions()):
			var subActions = activity.getSubActions()
			if(subActions != null):
				for action in subActions:
					result.append({
						id = "subAction",
						activityID = activity.uniqueID,
						action = action,
						name = action["name"],
						desc = action["desc"],
					})
					
	if(isDom("pc") && getDomInfo("pc").canDoActions()):
		var pctargetID = getPCTarget()
		if(pctargetID != null):
			var allSexActivities = GlobalRegistry.getSexActivityReferences()
			for possibleSexActivityID in allSexActivities:
				var newSexActivityRef = allSexActivities[possibleSexActivityID]
				
				if(!newSexActivityRef.canBeStartedByDom()):
					continue
				
				if(!newSexActivityRef.canStartActivity(self, getDomInfo("pc"), getSubInfo(pctargetID))):
					continue
				
				var possibleActions = newSexActivityRef.getStartActions(self, getDomInfo("pc"), getSubInfo(pctargetID))
				if(possibleActions == null):
					continue
				
				for newaction in possibleActions:
					result.append({
						id = "startNewDomActivity",
						activityID = possibleSexActivityID,
						name = newaction["name"],
						category = newaction["category"],
						subID = pctargetID,
						desc = "Start new activity",
						args = newaction["args"],
					})
					
	if(isSub("pc") && getSubInfo("pc").canDoActions()):
		var pctargetID = getPCTarget()
		if(pctargetID != null):
			var allSexActivities = GlobalRegistry.getSexActivityReferences()
			for possibleSexActivityID in allSexActivities:
				var newSexActivityRef = allSexActivities[possibleSexActivityID]
				
				if(!newSexActivityRef.canBeStartedBySub()):
					continue
				
				if(!newSexActivityRef.canStartActivity(self, getDomInfo(pctargetID), getSubInfo("pc"))):
					continue
				
				var possibleActions = newSexActivityRef.getStartActions(self, getDomInfo(pctargetID), getSubInfo("pc"))
				if(possibleActions == null):
					continue
				
				for newaction in possibleActions:
					result.append({
						id = "startNewSubActivity",
						activityID = possibleSexActivityID,
						name = newaction["name"],
						category = newaction["category"],
						domID = pctargetID,
						desc = "Start new activity",
						args = newaction["args"],
					})
	
	return result

func getPCTarget():
	if(isDom("pc")):
		return subs.keys()[0]
	if(isSub("pc")):
		return doms.keys()[0]
	
	return null

func doAction(_actionInfo):
	if(_actionInfo["id"] == "continue"):
		messages.clear()
		processAIActions(true)
		processTurn()
		processAIActions(false)
	if(_actionInfo["id"] == "domAction"):
		messages.clear()
		var activity = getActivityWithUniqueID(_actionInfo["activityID"])
		doDomAction(activity, _actionInfo["action"])
		processAIActions(true)
		processTurn()
		processAIActions(false)
	if(_actionInfo["id"] == "subAction"):
		messages.clear()
		var activity = getActivityWithUniqueID(_actionInfo["activityID"])
		doSubAction(activity, _actionInfo["action"])
		processAIActions(true)
		processAIActions(false)
		processTurn()
	if(_actionInfo["id"] == "startNewDomActivity"):
		messages.clear()
		startActivity(_actionInfo["activityID"], "pc", _actionInfo["subID"], _actionInfo["args"])
		processAIActions(true)
		processTurn()
		processAIActions(false)
	if(_actionInfo["id"] == "startNewSubActivity"):
		messages.clear()
		startActivity(_actionInfo["activityID"], _actionInfo["domID"], "pc", _actionInfo["args"])
		processAIActions(true)
		processAIActions(false)
		processTurn()

func hasTag(charID, tag):
	for activity in activities:
		if(activity.hasEnded):
			continue
		
		if(activity.domID == charID):
			if(tag in activity.getDomTags()):
				return true
		if(activity.subID == charID):
			if(tag in activity.getSubTags()):
				return true
	return false

func hasActivity(id, thedomID, thesubID):
	for activity in activities:
		if(activity.hasEnded):
			continue
		
		if(activity.id != id):
			continue
		
		if(activity.domID == thedomID && activity.subID == thesubID):
			return true
	return false

func sexShouldEnd():
	if(isDom("pc") && getDomInfo("pc").canDoActions()):
		return false
		
	for domID in doms:
		var domInfo = doms[domID]
		
		if(domInfo.canDoActions() && domInfo.hasGoals()):
			return false
	
	return true
	#return false

func endSex():
	if(sexEnded):
		return
	
	sexEnded = true
	var texts = ["The sex scene has ended!"]
	
	for domID in doms:
		var domInfo = doms[domID]
		
		GlobalRegistry.getCharacter(domID).afterSexEnded(domInfo)
		
		if(domInfo.getTimesCame() > 0):
			texts.append(processText("{dom.You} came "+str(domInfo.getTimesCame())+" times", domID, domID))

	for subID in subs:
		var subInfo = subs[subID]
		
		GlobalRegistry.getCharacter(subID).afterSexEnded(subInfo)

		if(subInfo.getTimesCame() > 0):
			texts.append(processText("{sub.You} came "+str(subInfo.getTimesCame())+" times", subID, subID))

	messages.append(Util.join(texts, "\n"))

func hasSexEnded():
	return sexEnded

func getBestAnimation():
	var hasPlayer = false
	if(isSub("pc") || isDom("pc")):
		hasPlayer = true
	
	for activity in activities:
		if(activity.hasEnded):
			continue
		var animInfo = activity.getAnimation()
		if(animInfo == null):
			continue
		
		if(hasPlayer):
			if(activity.subID == "pc" || activity.domID == "pc"):
				return animInfo
		else:
			return animInfo
	
	#return null
	if(subs.size() == 0 || doms.size() == 0):
		return null
	
	return [StageScene.Duo, "stand", {pc=subs.keys()[0], npc=doms.keys()[0]}]

func playAnimation():
	var animInfo = getBestAnimation()
	
	if(animInfo == null):
		return
	
	if(animInfo.size() > 2):
		GM.main.playAnimation(animInfo[0], animInfo[1], animInfo[2])
	else:
		GM.main.playAnimation(animInfo[0], animInfo[1])
