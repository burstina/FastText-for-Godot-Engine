#extends Label
#class_name FastTextInit
class_name FastTextInit,"res://FastText/FT.png"
extends Label


func _init():
	_FastTextInit()

func _enter_tree():
	_FastTextEnterTree()
	
func _ready():
	_FastTextReady()
	
func _process(delta):
	_FastTextProcess(delta)

func _unhandled_input(event):
	_FastTextUnhandledInput(event)

############################################ FastText Area - init
export var FastText 							= true		# true = enhanched Text node, false = standard Label
export var AllowInput							= true		# false = like Label, true = like LineEdit
enum UseType {sprite, control}
export (UseType) var TargetType					= UseType.control	
export var SharedInputBox						=false		# first FastText node who open IC defines the common shared IC
export(NodePath) var InputNode		 			= null		# Input node, must be in Scene Tree. Input node must have NO custom script
export(NodePath) var InputBoxParent 			= null		# when "InputNode" is null: where to create default Input node
export(bool) 	 var InputBoxStyleInherited 	= true		# InputBox node inherits Style from this node
export(StyleBox) var InputBoxStyle			= StyleBoxEmpty	# Force StyleBox for inputBox node
export(bool) 	 var InputBoxFontInherited	 	= true		# InputBox node inherits Font from this node
export(Font) 	 var InputBoxFont				= null		# Force Font for inputBox node
export var InputBoxFullWidth					= true		# Input box Width forced to full screen width
export var InputBoxCustomRect : Rect2			= Rect2(0,0,0,0) # (0,0,0,0) put InputBox at the top of the screen

# --- # default crift for InputBox default node.
# using a custom InputNode with custom script, InputBoxScript has to be included manually 
export (String) var InputBoxScript="res://FastText/_FastText_IC_custom_script.gd" 

# --- # core
var sprite_suffix 		= "_spr"
var duplicate_suffix 	= "_dup"
var control_suffix 		= "_ctr"
var inputControl_suffix = "_inp"

var Spr : Sprite		= null	# Text rendered node, can be used when no input needed (as Label)
var Lab : Label			= null	# Text rendering object
var VP  : Viewport		= null	# Viewport rendering target
var CT  : TextureRect	= null	# Text rendered node, needed to check input
var IC	: TextEdit		= null	# InputNode/InputBox

var parent: Node		= null

# METAs, used to coordinate multiple FastText nodes behaviour
var IC_OtherAlreadyOpenMeta 	 = "FastTextICAlreadyOpen"			# only 1 IC opened at the same time: true/false
var IC_OtherAlreadyOpenOwnerMeta = "FastTextICAlreadyOpenOwner"     # only 1 IC opened at the same time: object
var IC_ScriptReference		 	 = "FastTextICScriptReference"		# TextEdit custom script
var IC_SharedNode				 = "FastTextICSharedNode"			# Shared IC TextBox

enum FastTextButton {idle,pressed,drag}
var	FastTextButtonState = FastTextButton.idle
# processing phases, 
var yielding 			  	= false
var processed			  	= false
var processOpenTextEdit		= false
var processCreateEnv		= false
var processCreateControl	= false
var processCreateSprite		= false
var processCloseTextEdit  	= false
var processSetVisible	  	= false	; var FastEditVisibleFlag	= false
var processParentNodeToAbs	= false	
var NothingToDo				= false

############################################ FastText Area - end
############################################ FastText Funcion Area - init

func _FastTextInit():
	if !FastText:
		return
	
	if get_name().right(duplicate_suffix.length()) == duplicate_suffix:
		FastText = false
		return

	processCreateEnv = true
	return

func _FastTextEnterTree():
	_FastTextCheckConsistency()
	_FastTextGetParent()
	if InputNode != null:
		InputBoxParent = null
		InputNode = _FastTextNodepathToAbsolute(InputNode)
	elif InputBoxParent == null:
		InputBoxParent = parent.get_path()
	InputBoxParent =_FastTextNodepathToAbsolute(InputBoxParent)
	if !_IC_is_global_already_open():
		_IC_init_global()
	pass
		
func _FastTextReady():
	if !FastText:
		return
	else:
		if AllowInput:
			processCreateControl = true
		elif TargetType == UseType.control:
			processCreateControl = true
		elif TargetType == UseType.sprite:
			processCreateSprite  = true
		if InputNode != null:
			get_node(InputNode).set_visible(false)


func _FastTextProcess(delta):
	if !FastText:
		return
	elif processCreateEnv:
		_FastTextCreateEnvironment()
		processCreateEnv = false
	elif processOpenTextEdit:
		_IC_open()
		processOpenTextEdit = false
	elif processCloseTextEdit:
		_IC_close()
		processCloseTextEdit = false
	elif NothingToDo:
		if processSetVisible:
			FastTextSetVisible()
			processSetVisible=false
		pass 
		#set_process(false) 
	elif processParentNodeToAbs:
		if InputNode != null:
			InputNode = _FastTextNodepathToAbsolute(InputNode)
		elif InputBoxParent != null:
			InputBoxParent =_FastTextNodepathToAbsolute(InputBoxParent)
		processParentNodeToAbs = false
	elif processCreateSprite:
		_spr_open(parent)
		processCreateSprite = false
	elif processCreateControl:
		_CT_open()
		processCreateControl = false
	elif !processed:
		_capture(VP)
	elif processed:
		.set_visible(false)
		remove_child(VP)
		NothingToDo = true
	return

func _FastTextUnhandledInput(event):
	if !FastText:
		pass
	elif !AllowInput:
		pass
	elif (event is InputEventMouseButton
	and   event.is_pressed()
	and   IC != null
	and   IC.is_visible()
	and   !IC.get_rect().has_point(event.position)
		):
#		var dd=IC.get_rect().has_point(event.position)
#		var rec=IC.get_rect()
#		var po=event.position
#		if !rec.has_point(po):
		accept_event()
		processCloseTextEdit = true
		

func _FastTextCreateEnvironment():
	_VP_open()
	Lab=_dupe()		
	VP.add_child(Lab)
	Lab.set_position(Vector2(0,0))
	connect ("item_rect_changed",self,"_FastText_item_rect_changed")

func _VP_open():
	VP=Viewport.new()
	VP.set_transparent_background(true)
	VP.set_handle_input_locally(false) 
	VP.set_disable_3d(true)
	VP.set_usage(Viewport.USAGE_2D)
	VP.set_vflip(true)
	VP.set_clear_mode(Viewport.CLEAR_MODE_ALWAYS)
	VP.set_update_mode(Viewport.UPDATE_ALWAYS)
	VP.set_disable_input(false)
	add_child(VP)
	VP.set_size(get_size())
	
func _IC_set_parent():
	if InputBoxParent != null:
		IC.set_owner(get_node(InputBoxParent))
		get_node(InputBoxParent).add_child(IC)
	else:
		IC.set_owner(parent)
		parent.add_child(IC)
			
func _IC_open():
	var otherOwner = null
	if _IC_is_global_already_open():
		otherOwner = _IC_get_global_owner()
		otherOwner._IC_close()
	elif SharedInputBox:
		pass
	else:
		_IC_init_global()
	_IC_set_global_open()

	if SharedInputBox:
		if _IC_shared_IC_exists():
			IC = _IC_get_shared_IC()
			_IC_set_properties(true)
			IC.disconnect("gui_input",IC._get_IC_owner(),"_IC_input")
			IC.disconnect("focus_exited",IC._get_IC_owner(),"_IC_focus_exited")
			IC._set_IC_owner(self)
			_IC_set_parent()
		else:
			_IC_new()
			_IC_set_shared_IC(IC)
	else:
		_IC_new()

	if IC.get_parent() == null:
		_IC_set_parent()
	IC.connect("gui_input",self,"_IC_input")
	IC.connect("focus_exited",self,"_IC_focus_exited")
	IC.get_parent().move_child(IC,0)
	IC.set_visible(true)
	IC.set_process(true)
	IC.grab_focus()
	IC.set_text(get_text())	
	IC._set_ResetCursor()

func _IC_new():
	if IC != null:
		pass		
	elif InputNode != null:
		_IC_open_custom()
	else:
		_IC_open_default()
		
func _IC_open_custom():
	if IC == null:
		IC = get_node(InputNode)
		_IC_init_script()	# DO IT ASAP or won't work
		InputBoxParent = IC.get_parent().get_path()
	else:
		_IC_set_parent()


func _IC_open_default():
	if IC == null:
		IC = TextEdit.new()
		_IC_init_script() 	# DO IT ASAP or won't work
		_IC_set_properties()
		
func _IC_set_properties(keepname=false):
		if !keepname:
			IC.set_name(get_IC_name())
		IC.set_theme(get_theme())
		if InputBoxFullWidth:
			var ws = get_viewport().get_size()
			InputBoxCustomRect.size = ws - InputBoxCustomRect.position
			InputBoxCustomRect.size.y = get_size().y
		if InputBoxCustomRect.has_no_area():
			IC.set_size(get_size())
			IC.set_position(get_global_position())
		else:
			IC.set_size(InputBoxCustomRect.size)
			IC.set_position(InputBoxCustomRect.position)
		
		if (!InputBoxStyleInherited
		and !InputBoxFontInherited
		and InputBoxStyle == StyleBoxEmpty
		and InputBoxFont  == null):
			pass
		else:
			var them = IC.get_theme()
			if them == null:
				them=Theme.new()
				them.copy_default_theme()
				IC.set_theme(them)
				
			if  InputBoxStyleInherited:
				var styl = them.get_stylebox_list(IC.get_class())
				var stylme=get_stylebox(them.get_stylebox_list(get_class())[0])
				for i in styl:
					IC.add_stylebox_override(i,stylme)
				pass
			elif InputBoxStyle != StyleBoxEmpty:
				var styl = them.get_stylebox_list(IC.get_class())
				for i in styl:
					IC.add_stylebox_override(i,InputBoxStyle)
			if  InputBoxFontInherited:
				var fontl = them.get_font_list(IC.get_class())
				var fontme=get_font(them.get_font_list(get_class())[0])
				for i in fontl:
					IC.add_font_override(i,fontme)
			elif InputBoxFont != null:
				var fontl = them.get_font_list(IC.get_class())
				for i in fontl:
					IC.add_font_override(i,InputBoxFont)
		IC.set_wrap_enabled(true) 
		_IC_set_parent()

	
func _IC_close():
	if IC.get_text().ends_with("\n"):
		IC.set_text(IC.get_text().trim_suffix("\n"))
	set_text(IC.get_text())
	IC.set_visible(false) # execute _IC_focus_exited() just after by default
	IC.disconnect("gui_input",self,"_IC_input")
	IC.disconnect("focus_exited",self,"_IC_focus_exited")
	update() # update text
		

func _IC_reset_cursor():
	var linec=IC.get_line_count()
	IC.cursor_set_line(linec)
	var line=IC.get_line(linec - 1)
	var le=line.length()
	IC.cursor_set_column(le)
	IC._set_ResetCursor(false)
		
func _IC_focus_exited():
	IC.set_visible(false)
	IC.set_process(false)
	#parent.remove_child(IC)
	IC.get_parent().remove_child(IC)
#	_resample()
	pass

func _IC_input(event):
	if !FastText:
		pass
	elif !AllowInput:
		pass
	elif  IC == null:
		pass
	elif !IC.is_visible():
		pass
	elif (event is InputEventKey
	and   event.is_pressed()
		):
		var scancode = event.get_scancode()
		if (scancode == 16777221
		and scancode == event.get_scancode_with_modifiers()
			): # ENTER key
			processCloseTextEdit = true
			return true
	elif event is InputEventScreenDrag:
		pass
	elif event is InputEventGesture:
		pass
	elif (event is InputEventMouseButton
	and   event.is_pressed()
	and   !IC.get_rect().has_point(event.global_position)
		):
		processCloseTextEdit = true
		return true
	return false
		

func _IC_init_script():
	var script = _IC_get_script_from_meta()
	if script == null:
		script = load(InputBoxScript)
		_IC_set_script_to_meta(script)
	IC.set_script(script)

func _IC_get_script_from_meta():
	if get_tree().has_meta(IC_ScriptReference):
		return get_tree().get_meta(IC_ScriptReference)
	else:
		return null

func _IC_set_script_to_meta(ref):
	get_tree().set_meta(IC_ScriptReference,ref)
	
func _IC_is_global_already_open():
	return get_tree().get_meta(IC_OtherAlreadyOpenMeta)

func _IC_get_global_owner():
	return get_tree().get_meta(IC_OtherAlreadyOpenOwnerMeta)
	
func _IC_set_global_open():
	get_tree().set_meta(IC_OtherAlreadyOpenMeta,true)
	get_tree().set_meta(IC_OtherAlreadyOpenOwnerMeta,self)
	
func _IC_init_global():
	get_tree().set_meta(IC_OtherAlreadyOpenMeta,false)
	get_tree().set_meta(IC_OtherAlreadyOpenOwnerMeta,null)	


func _IC_shared_IC_exists():
	return get_tree().has_meta(IC_SharedNode)

func _IC_get_shared_IC():
	return get_tree().get_meta(IC_SharedNode)
	
func _IC_set_shared_IC(inp):
	return get_tree().set_meta(IC_SharedNode,inp)

func _IC_text_changed():
	pass
	
func _FastTextNodepathToAbsolute(np=null):   # np:nodepath
	var newNodePath = np
	var ps:String
	var nodop = null
	if   (np != null
	and   np is Node):
		nodop = np
	elif (np != null
	and   np is NodePath):
		nodop = get_node(np)
	
	if nodop != null:
		if nodop.is_inside_tree():
			if nodop != null:
				ps = nodop.get_path()
				if ps != "":
					newNodePath= NodePath(ps)
		else:
			processParentNodeToAbs = true
	return newNodePath
	
func  _FastTextGetParent():
	if parent == null:
		parent = get_parent()
		if TargetType != UseType.control:
			if parent is CanvasLayer:
				parent = get_parent()

func _FastTextCheckConsistency():
	if (InputBoxScript == null
	or  InputBoxScript == ""):
		AllowInput = false

	if AllowInput:
		TargetType = UseType.control
	
	if InputBoxFontInherited:
		InputBoxFont = null
		
	if InputBoxStyleInherited:
		InputBoxStyle = StyleBoxEmpty

func  _CT_open():
	if CT == null:
		CT= TextureRect.new()
		CT.set_name(get_CT_name())
		CT.set_owner(parent)
		parent.add_child(CT)
		CT.set_size(get_size())
		CT.set_position(get_position())
	if AllowInput:
		CT.connect("gui_input",self,"_CT_gui_input")

func _CT_gui_input(event):
	if !FastText:
		pass
	if !AllowInput:
		pass
	elif !CT.is_visible():
		pass
	elif event is InputEventMouseMotion:
		if event.get_relative().length() > 4: # tollerance
			FastTextButtonState = FastTextButton.drag
		pass
	elif event is InputEventGesture:
		pass
	elif (event is InputEventMouseButton
	and event.is_pressed()
		):
		accept_event()
		FastTextButtonState = FastTextButton.pressed

	elif (event is InputEventMouseButton
	and !event.is_pressed()
	and	FastTextButtonState == FastTextButton.pressed
	and IC == null
		):
		accept_event()
		FastTextButtonState = FastTextButton.idle
		processOpenTextEdit = true

	elif (event is InputEventMouseButton
	and   !event.is_pressed()
	and	  FastTextButtonState == FastTextButton.pressed
	and   IC != null
	and   !IC.is_visible()
		):
		accept_event()
		FastTextButtonState = FastTextButton.idle
		processOpenTextEdit = true
	elif event is InputEventMouseButton:
		prints("mouse non gestito -",FastTextButtonState,"-",event.is_pressed())

	
func _dupe():
	Lab = Label.new()
	var pro = get_property_list()
	
	for i in pro:
		var nam = i.name
		if nam.to_lower() == "script":  # Attenzione! su Windows la S è maiuscola, ma su Android è minuscola
			break
		if nam.to_lower() == "owner":
			pass
		elif i.type == 0:
			pass
		else:
			Lab.set(i.name,get(i.name))
	Lab.set_name(get_name() + duplicate_suffix)
	Lab.connect("draw",self,"_dup_redraw")
	return Lab

func _dup_redraw():
	_resample()
	.set_visible(false)

func get_dupe():
	return Lab
	
func get_spr_name():
	return get_name() + sprite_suffix

func get_IC_name():
	return get_name() + inputControl_suffix
	
func get_CT_name():
	return get_name() + control_suffix
	
func _spr_open(par):
	Spr=Sprite.new()
	Spr.set_name(get_spr_name())
	par.add_child(Spr)
	Spr.set_owner(par)
	Spr.set_position(get_position())
	Spr.set_centered(false)
	pass
	
func _capture(VP=get_viewport()):
		if !yielding:
			yielding = true
			if VP.get_size() != Lab.get_size():
				VP.set_size(Lab.get_size())
			yield(get_tree(),"idle_frame")
			var tex = VP.get_texture()
			if AllowInput:
				CT.set_texture(tex)
				CT.update()
			elif TargetType == UseType.control:
				CT.set_texture(tex)
				CT.update()
#			elif Spr == null:
#				_spr_open(parent)
#				Spr.set_texture(tex)
#				Spr.update()
			elif Spr != null:
				Spr.set_texture(tex)
				Spr.update()
#			var dbgimg=tex.get_data()
#			dbgimg.save_png("res://FastTextTex.png")
			yielding = false
			processed = true
			return 

func _resample():
	yielding 	= false
	processed	= false
	NothingToDo	= false
	set_process(true) 
	if VP.get_parent() == null:
		add_child(VP)
	

func set_size(size):
	.set_size(size)
	if FastText: 
		if VP and Lab:
			VP.set_size(size)
			Lab.set_size(size)
			if Spr:
				Spr.set_size(size)
			elif CT:
				CT.set_size(size)
#			if NothingToDo:
			_resample()

func set_text(Text):
	.set_text(Text)
	if FastText: 
		if Lab != null:
			Lab.set_text(Text)
			if NothingToDo:
				_resample()
	
func set_position(pos):
	.set_position(pos)
	if FastText:
		if Spr:
			Spr.set_position(pos)
		elif CT:
			CT.set_position(pos)

func set_visible(tf):
	if FastText:
		FastEditVisibleFlag = tf
		processSetVisible = true
		if Spr:
			Spr.set_visible (tf)
		elif CT:
			CT.set_visible (tf)
	
func set_InputBoxParent(nodepath):
	InputBoxParent =_FastTextNodepathToAbsolute(nodepath)
	
func set_InputBoxCustomRect(rect):
	InputBoxCustomRect = rect
	
func FastTextSetVisible():
	if	processSetVisible:
		if Spr:
			Spr.set_visible (FastEditVisibleFlag)
		elif CT:
			CT.set_visible (FastEditVisibleFlag)

func _FastText_item_rect_changed():
#	set_size(get_size())
#	set_position(get_position())
#	Lab.set_size(get_size())
#	VP.set_size(get_size())
	pass
func isFastMode():
	return FastText

########################################### FastText Function Area - end
