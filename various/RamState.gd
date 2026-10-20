extends Reference
class_name RamState

var rammedById:int = 0
var rammedByDisplay:String = ""
var ticks_til_dmg:float = 0
var rammingArea:Area2D = null
var initFrame:int = 0
var legal:bool = true
var uid:int = 0

func _init(a, b, c, d, e, f, g):
	rammedById = a
	rammedByDisplay = b
	ticks_til_dmg = c
	rammingArea = d
	initFrame = e
	legal = f
	uid = g

	
#	var dict = {
#		"rammedById": area.owner.id,
#		"rammedByDisplay": area.owner.display,
#		"ticks_til_dmg": 1.0,
#		"rammingArea": area,
#		"initFrame": Engine.get_idle_frames(),
#		"legal": true,
#		"uid": Globals.getId()
		
		
		
