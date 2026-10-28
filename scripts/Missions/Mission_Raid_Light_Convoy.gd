extends Mission_Base
class_name Mission_Raid_Light_Convoy

const warp_anim_time:float = 0.6
const mission_time:float = 3.0
const time_until_target_arrives:float = 3.0

func _ready():
	pass
	
func _physics_process(delta):
	pass
	
func set_base_props():
	code = "RAID_CONVOY_LIGHT"
	title = "Strike Light Ground Convoy"
	difficulty = 0
	reward = 0
	desc = "Ambush the lightly armored supply convoy before it reaches enemy lines.\nEliminate all escorts and destroy the cargo trucks with minimal collateral damage"

func mission_final_setup_self():
	do_init(mission_time)
	do_setup()
	
func do_process_time(_delta):
	if timeRemain > 0.0:
		timeRemain = max(0, timeRemain - _delta)
		timerLabel.text = "%.2f" % timeRemain
		bar.value = (timeRemain / maxTime) * 100.0
		
	if timeRemain <= 0.0:
		set_mission_condition_success()
		
func do_init(init_time):
	maxTime = init_time
	timeRemain = init_time
	remaining = amount
	
func do_setup():
	var raid_target_group = []
	raid_target_group.append({"type": handler_s.UnitType.MOBILE_AA_LIGHT, "name": "", "amount": Globals.rng.randi_range(1, 1), "target": false})
	raid_target_group.append({"type": handler_s.UnitType.TRUCK_LIGHT, "name": "", "amount": Globals.rng.randi_range(1, 2), "target": true})
	raid_target_group.append({"type": handler_s.UnitType.MOBILE_AA_LIGHT, "name": "", "amount": Globals.rng.randi_range(1, 1), "target": false})
	raid_target_group.append({"type": handler_s.UnitType.TRUCK_LIGHT, "name": "", "amount": Globals.rng.randi_range(1, 2), "target": true})
	raid_target_group.append({"type": handler_s.UnitType.MOBILE_AA_LIGHT, "name": "", "amount": Globals.rng.randi_range(1, 1), "target": false})
	
	setup_targets(raid_target_group)

	Globals.PLAYER.connect("_has_warped_in", self, "do_start_mission")
	
func setup_targets(unitArray):
	var num_targets:int = 0
	var allUnits = []
	var lowestSpeed:int = 1000
	
	var dir = Globals.getRandomEntry([-1, 1])
	dir = -1
	var startX:int
	if dir == 1:
		startX = 0
	else: startX = Globals.WIDTH
	
	timer
	
	
	for unit in unitArray:#mark unit as target
		for i in unit.amount:
			var target_unit = handler_s.get_unit_instance(unit.type)
			allUnits.append(target_unit)
			Globals.add_unit_to_scene(target_unit, Globals.Faction.hostile)
			target_unit.set_direction(Vector2(dir, 0))
			target_unit.look_ahead = 0
			lowestSpeed = min(lowestSpeed, target_unit.maxSpeed)
			if unit.target:
				num_targets += 1
				target_unit.mark_as_target()
				target_unit.add_health_bar()
				targets.append(target_unit)
				target_unit.connect("objectiveDestroyed", self, "_on_mission_target_destroyed")
		
	for i in len(allUnits):
		var single = allUnits[i]
		single.maxSpeed = lowestSpeed
		var x:int
		var y:int
		var w = single.texDim.x
		startX += (120 + w/2) * dir
		single.position = Vector2(startX, single.getSpawnY(0, 0))
		if single.display == "Light Truck" or single.display == "Heavy Truck" or single.display == "Mobile AA Light":
			single.set_active()
			single.get_node("SM").canChangeState = false
#			if single.display == "Heavy Truck" or single.display == "Light Truck":
#				single.mark_as_target()
#				single.add_health_bar()
		
	amount = num_targets
	remaining = num_targets
		
	for n in targets:
		Globals.UI.add_target_healthbar_to_mission_bar(n)
		
		
