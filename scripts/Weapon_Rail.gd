extends Weapon_Base
class_name Weapon_Rail

var curDeviation:float

func _ready():
#	print("ready rail: ", display)
	$Aim/AimA.points[0] = Vector2.ZERO
	$Aim/AimB.points[0] = Vector2.ZERO
	
#	$Aim/AimA.hide()
#	$Aim/AimB.hide()	
#	$Aim/LineA.hide()
#	$Aim/LineB.hide()
	$Aim/Angle.hide()

func weapon_process(_delta):
#	print("rail weapon_process")
	if is_in_active_burst():
		handle_burst_cooldown(_delta)
	else:
		cooldown = max(cooldown - _delta, -rof)
	
	curDeviation = deviation + ((deviation * 6) * (cooldown + rof) / rof)
#	print(curDeviation)
	drawAimVector()
	update_cooldown_ui_nodes()
#	print(Engine.get_idle_frames(), "_weapon: ", global_rotation_degrees)



#func weapon_process(_delta):
##	print("weapon_process: ", display)
#	if is_in_active_burst():
#		handle_burst_cooldown(_delta)
#	else:
#		cooldown = max(cooldown - _delta, 0.0)
#	update_cooldown_ui_nodes()
	
	
	
func drawAimVector():
	drawCurrentDeviationLINES()
#	drawCurrentDeviationARC()

func drawCurrentDeviationLINES():
#	print(Engine.get_idle_frames(), "_drawDevi: ", deg2rad(curDeviation))
	$Aim/AimA.points[1] = Vector2(800, 0).rotated(deg2rad(curDeviation))
	$Aim/AimB.points[1] = Vector2(800, 0).rotated(deg2rad(-curDeviation))
	
func drawCurrentDeviationARC():
#	print("draw aim frame: ", Engine.get_idle_frames())
	$Aim/Angle.polygon[1] = Vector2(800, 0).rotated(deg2rad(curDeviation))
	$Aim/Angle.polygon[2] = Vector2(800, 0).rotated(deg2rad(-curDeviation))
	
func setProjRotation(all, current, proj):
	var rota
	
	if linearDevi:
		rota = - curDeviation + ((curDeviation*2) / (all + -1) * current)
	else:
		rota = rand_range(-curDeviation, curDeviation)
	
	proj.rotation_degrees =  global_rotation_degrees + rota

func get_class():
	return "Weapon_Rail"
	
