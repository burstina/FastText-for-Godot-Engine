extends TextEdit

func _process(delta):
	_FastEditIC_process(delta)
func _input(event):
	_FastEditIC_input(event)

#--# FastEdit Area ###################################################################
var IC_OtherAlreadyOpenMeta 	 = "FastTextICAlreadyOpen"			# true/false
var IC_OtherAlreadyOpenOwnerMeta = "FastTextICAlreadyOpenOwner"   	# object
var MyOwner 	= null	# Calling FastEdit node
var ResetCursor	= true
var ResetMyOwner= true
#--# FastEdit Area ###################################################################

func _FastEditIC_process(delta):
	if ResetMyOwner:
		MyOwner =_get_IC_owner()
	elif ResetCursor:
		MyOwner._IC_reset_cursor()
		
func _FastEditIC_input(event):
	if MyOwner != null:
		if MyOwner._IC_input(event):
			accept_event()

func _get_IC_owner():  # fromt FastText.gd
	ResetMyOwner = false
	return get_tree().get_meta(IC_OtherAlreadyOpenOwnerMeta)

func _set_IC_owner(inp):  # fromt FastText.gd
	MyOwner = inp
	
func _set_ResetCursor(flag=true):
	ResetCursor = flag
	
		
#--# FastEdit Area ###################################################################