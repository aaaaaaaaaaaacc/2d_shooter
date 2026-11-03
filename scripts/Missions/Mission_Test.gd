extends Mission_Base
class_name Mission_Test

const mission_time:float = 300.0
const time_until_target_arrives:float = 1.0

func _ready():
	pass
	
func _physics_process(delta):
	pass
	
func set_base_props():
	code = "TEST"
	title = "Strike Light Ground Convoy"
	difficulty = 0
	reward = 0
	desc = "Ambush the lightly armored supply convoy before it reaches enemy lines.\nEliminate all escorts and destroy the cargo trucks with minimal collateral damage"

func mission_final_setup_self():
	do_init(mission_time)
	do_setup()
	
	Globals.PLAYER.connect("_has_warped_in", self, "do_start_mission")
	
func do_start_mission():
	.do_start_mission()
	
	handler_s.do_disable()
	
func do_setup():
	var unit_group = []
	unit_group.append({"type": handler_s.UnitType.UNIT_TEST, "name": "UNIT_TEST", "amount": Globals.rng.randi_range(1, 1), "target": true})
	setup_attackers(unit_group)
#
#
#			var target_unit = handler_s.get_unit_instance(unit.type)
#			allUnits.append(target_unit)
#			Globals.add_unit_to_scene(target_unit, Globals.Faction.hostile)
#			target_unit.set_direction(Vector2(dir, 0))
#			target_unit.maxSpeed = 0
			
			
			
func setup_attackers(unitArray):
	for entry in unitArray:
		for i in entry.amount:
			var unit = handler_s.get_unit_instance(entry.type)
			Globals.add_unit_to_scene(unit, Globals.Faction.hostile)
			unit.set_direction(Vector2.RIGHT)
			
			var x:int = Globals.WIDTH/2
			var y:int = Globals.HEIGHT/2
			
			var pos = Globals.PLAYER.global_position + Vector2(-350, -150) + Vector2(-0, -200)
			pos.x += 400 * i
			
			unit.position = pos
			unit.add_health_bar()
			
			if unit.can_warp_in():
				unit.setup_delayed_warp_in(time_until_target_arrives+1)
			else:
				unit.set_active()

func do_process(_delta):
#	if inArea:
#		timeRemain = max(0.0, timeRemain - _delta)
#	else:
#		timeRemain = min(maxTime, timeRemain + _delta)
		
	timeRemain = max(0, timeRemain - _delta)
	timerPct = timeRemain / maxTime * 100 / 100
	
	timerLabel.text = "%.2f" % timeRemain
	bar.value = (1-timerPct)*100
	
	if timeRemain <= 0.0:
		set_mission_condition_success()
