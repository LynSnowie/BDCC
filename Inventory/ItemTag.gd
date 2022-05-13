extends Object
class_name ItemTag

enum {
	Illegal,
	BDSMRestraint,
	CanBeForcedByGuards,
	Condom,
}

static func getName(tag):
	if(tag == Illegal):
		return "Illegal"
	if(tag == BDSMRestraint):
		return "Restraint"
	if(tag == Condom):
		return "Condom"
	return "error"
