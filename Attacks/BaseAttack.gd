extends Node
class_name Attack

enum Category {Physical, Lust, Special, Humiliation, SelfHumiliation}
enum AICategory {Unspecified, Offensive, Defensive, Lust, DefensiveLust, DefensivePain}
enum LustTopic {selfUseMe, humYouSlut}

var id = "baseattack"
var category = Category.Physical
var aiCategory = AICategory.Unspecified
var aiScoreMultiplier = 1

func _init():
	pass
	
func getVisibleName():
	return "Bad attack"
	
func getVisibleDesc():
	return "Bad attack, let the developer know"
	
func _doAttack(_attacker, _reciever):
	return "Mew happened"
	
func _canUse(_attacker, _reciever):
	return true
	
	
func doAttack(_attacker, _reciever):
	doRequirements(_attacker, _reciever)
	return _doAttack(_attacker, _reciever)
	
func canUse(_attacker, _reciever):
	return _canUse(_attacker, _reciever)

func getRequirements():
	return []

func meetsRequirements(_attacker, _reciever):
	var reqs = getRequirements()
	for req in reqs:
		if(!checkRequirement(_attacker, _reciever, req)):
			return false
	
	return true

func checkRequirement(_attacker, _reciever, req):
	var reqtype = req[0]
	if(reqtype == "stamina"):
		if(_attacker.getStamina() < req[1]):
			return false
	if(reqtype == "freearms"):
		if(_attacker.hasEffect(StatusEffect.ArmsBound)):
			return false
	if(reqtype == "freelegs"):
		if(_attacker.hasEffect(StatusEffect.LegsBound)):
			return false
	if(reqtype == "freemouth"):
		if(_attacker.hasEffect(StatusEffect.Gagged)):
			return false
			
	return true

func doRequirement(_attacker, _reciever, req):
	var reqtype = req[0]
	if(reqtype == "stamina"):
		_attacker.addStamina(-req[1])

func doRequirements(_attacker, _reciever):
	var reqs = getRequirements()
	for req in reqs:
		doRequirement(_attacker, _reciever, req)

func getRequirementText(req):
	var reqtype = req[0]
	if(reqtype == "stamina"):
		return "Uses " + str(req[1]) + " stamina"
	if(reqtype == "freearms"):
		return "Arms must be free"
	if(reqtype == "freelegs"):
		return "Legs must be free"
	if(reqtype == "freemouth"):
		return "Mouth must be free"
			
	return "Error: bad requirement:" + reqtype
	
func getRequirementsColorText(_attacker, _reciever):
	var reqs = getRequirements()
	var text = ""
	for req in reqs:
		var reqText = getRequirementText(req)
		var reqCan = checkRequirement(_attacker, _reciever, req)
		if(reqCan):
			text += reqText
		else:
			text += "-> " + reqText + ""
		text += "\n"
	
	return text

func doDamage(_attacker, _reciever, _damageType, _damage: int):
	var damageMult = _attacker.getDamageMultiplier(_damageType)
	
	var damage = _reciever.recieveDamage(_damageType, _damage * damageMult)
	return damage

func canBeDodgedByPlayer(_attacker, _reciever):
	return true

func getAnticipationText(_attacker, _reciever):
	return "You're about to be bonked by "+getVisibleName()

func getAIScore(_attacker, _reciever):
	if(aiCategory == AICategory.Unspecified):
		return 1.0 * aiScoreMultiplier
		
	# we want the enemy to have high pain
	if(aiCategory == AICategory.Offensive):
		var enemyHealthFraction = _reciever.getPain() / _reciever.painThreshold()
		enemyHealthFraction = clamp(enemyHealthFraction, 0.0, 1.0)
		
		var score = 1.0 + pow(enemyHealthFraction, 3) * 2
		return score * aiScoreMultiplier
		
	# we want us to have low health
	if(aiCategory == AICategory.DefensivePain):
		var healthFraction = _attacker.getPain() / _attacker.painThreshold()
		healthFraction = clamp(healthFraction, 0.0, 1.0)
		
		var score = 0.0 + pow(1.0 - healthFraction, 3) * 4
		return score * aiScoreMultiplier
		
	# we want us to have low lust
	if(aiCategory == AICategory.DefensiveLust):
		var lustFraction = _attacker.getLust() / _attacker.lustThreshold()
		lustFraction = clamp(lustFraction, 0.0, 1.0)
		
		var score = 0.0 + pow(1.0 - lustFraction, 3) * 4
		return score * aiScoreMultiplier
		
	# we want us to have low pain and lust
	if(aiCategory == AICategory.Defensive):
		var lustFraction = _attacker.getLust() / _attacker.lustThreshold()
		lustFraction = clamp(lustFraction, 0.0, 1.0)
		var healthFraction = _attacker.getPain() / _attacker.painThreshold()
		healthFraction = clamp(healthFraction, 0.0, 1.0)
		
		var dangerFraction = min(lustFraction, healthFraction)
		
		var score = 0.0 + pow(1.0 - dangerFraction, 3) * 4
		return score * aiScoreMultiplier
		
	# we want the enemy to have high lust
	if(aiCategory == AICategory.Lust):
		var enemyLustFraction = _reciever.getLust() / _reciever.lustThreshold()
		enemyLustFraction = clamp(enemyLustFraction, 0.0, 1.0)
		
		var score = 1.0 + pow(enemyLustFraction, 3) * 2
		
		# if we're lusty we will prioritise lust attacks
		var lustFraction = _attacker.getLust() / _attacker.lustThreshold()
		lustFraction = clamp(lustFraction, 0.0, 1.0)
		if(lustFraction > 0.6):
			score += 0.5
		
		return score * aiScoreMultiplier
		
	return 0.0

func checkMissed(_attacker, _reciever, _damageType, customAccuracyMult = 1):
	if(_reciever.hasEffect(StatusEffect.Collapsed)):
		return false
	
	var chanceToHit = _attacker.getAttackAccuracy(_damageType) * customAccuracyMult
	if(!RNG.chance(100.0 * chanceToHit)):
		return true
	return false

func checkDodged(_attacker, _reciever, _damageType, customDodgeMult = 1):
	var dodgeChance = _reciever.getDodgeChance(_damageType) * customDodgeMult
	if(RNG.chance(100.0 * dodgeChance)):
		return true
	return false
	