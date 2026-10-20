extends Mission_Base
class_name Mission_Raid_Cargo_Hauler

const warp_anim_time:float = 0.6
const mission_time:float = 2.0
const time_until_target_arrives:float = 1.0

#var update_interval:float = 0.1
#var current_update_interval:float = 0.0
#
#func do_process_time(_delta):
#	current_update_interval += _delta
#	if current_update_interval >= update_interval:
#		if timeRemain > 0.0:
#			timeRemain = max(0, timeRemain - current_update_interval)
#			timerLabel.text = "%.2f" % timeRemain
#			bar.value = (1.0 - (timeRemain / maxTime)) * 100.0	
#			current_update_interval = 0.0

func _ready():
	pass
	
func _physics_process(delta):
	pass
	
func set_base_props():
	code = "RAID_CARGO_HAULER"
	title = "Raid Cargo Hauler"
	difficulty = 0
	reward = 0
	desc = "Raid the Cargo Hauler"

func mission_final_setup_self():
	do_init(mission_time)
	do_setup()
	
func do_process_time(_delta):
	if timeRemain > 0.0:
		timeRemain = max(0, timeRemain - _delta)
		timerLabel.text = "%.2f" % timeRemain
		bar.value = (timeRemain / maxTime) * 100.0
		
#func do_process_time(_delta):
#	if timeRemain > 0.0:
#		timeRemain = max(0, timeRemain - _delta)
#		timerLabel.text = "%.2f" % timeRemain
#		bar.value = (1.0 - (timeRemain / maxTime)) * 100.0

#		if timeRemain <= 0.0:
			#for n in targets:
				#n.setup_delayed_warp_out(Globals.rng.randf_range(0.1, 0.6))
#				n.warp_out_phase_one()
#			set_mission_condition_success()

func do_init(init_time):
	maxTime = init_time
	timeRemain = init_time
	remaining = amount

func do_setup():
	var raid_target_group = []
	raid_target_group.append({"type": handler_s.UnitType.CARGO_HAULER, "name": "CARGO_HAULER", "amount": Globals.rng.randi_range(1, 1), "target": true})
	
	var escort_group = []
	escort_group.append({"type": handler_s.UnitType.FRIGATE, "name": "FRIGATE", "amount": Globals.rng.randi_range(2, 2), "target": false})
	
	setup_targets(raid_target_group)
	#set_escort(escort_group)
	
func setup_targets(unitArray):
	var num_targets = 0
	var allUnits = []
	
	var dir = Globals.getRandomEntry([-1, 1])
#	dir = -1
	
	for unit in unitArray:
		for i in unit.amount:
			var target_unit = handler_s.get_unit_instance(unit.type)
			allUnits.append(target_unit)
			Globals.add_unit_to_scene(target_unit, Globals.Faction.hostile)
#			Globals.curScene.add_unit_to_scene(target_unit, Globals.Faction.hostile)
#			target_unit.do_init_unit()
#			Globals.set_faction(target_unit, Globals.Faction.hostile)
#			target_unit.set_armaments()
			target_unit.set_direction(Vector2(dir, 0))
			target_unit.add_health_bar()
			if unit.target:
				num_targets += 1
#				object.display = "Cargohauler"
				target_unit.mark_as_target()
				targets.append(target_unit)
				target_unit.connect("objectiveDestroyed", self, "_on_mission_target_destroyed")
	
	var initialX:int
	var initialY:int
	var variance:Vector2 = Vector2.ZERO
	
	match targets[0].display:
		"City":
			initialX = 0 - (Globals.rng.randi_range(1000, 1400) * dir)
			initialY = targets[0].getSpawnY(0, 0)
		"Cargohauler": 
			initialX = 0 + Globals.rng.randi_range(150, 300)
			initialY = Globals.HEIGHT/2 - Globals.rng.randi_range(150, 300)
#			timerLabel.text = ""
			
	for i in len(allUnits):
		var single = allUnits[i]
		var x:int
		var y:int
		if single.display == "City":
			x = initialX + ((Globals.rng.randi_range(1100, 1500) * i) * dir)
			y = single.getSpawnY(0, 0)
#			single.get_node("Mounts/A/Weapon/ControlNodes/ShieldBar").offset.x = -20 * dir
#			single.get_node("Mounts/C/Weapon/ControlNodes/ShieldBar").offset.x = +20 * dir
#			single.get_node("ControlNodes/HealthBar/ProgressBar").rect_min_size += Vector2(50, 0)
#	shield.add_shield_bar()
#	shield.scale_progress_bar("shieldbar", 0.5)
#			single.setup_delayed_warp_in(3 + i*3) 
		elif single.display == "Cargohauler":
			x = (initialX + ((Globals.rng.randi_range(200, 300) + 100) * i)) * dir
			y = initialY + (i*-Globals.getRandomEntry([-225, -150, 150, 225]))
			variance = Vector2(Globals.rng.randi_range(-25, 25), Globals.rng.randi_range(-25, 25))
			single.setup_delayed_warp_in(time_until_target_arrives)# + Globals.rng.randf_range(0.1, 0.6))
			single.connect("_has_warped_in", self, "do_start_mission")
			single.setup_delayed_warp_out(time_until_target_arrives + mission_time + warp_anim_time) 
			single.connect("_has_warped_out", self, "_on_mission_raid_target_warped_out")
			
		single.position = Vector2((Globals.WIDTH / 2) + x, y) + variance
		
	amount = num_targets
	remaining = num_targets
	
	for n in targets:
		Globals.UI.add_target_healthbar_to_mission_bar(n)
		
func _on_mission_raid_target_warped_out():
	print("_on_mission_raid_target_warped_out")
	target_fail += 1
	target_remain -= 1
	set_mission_condition_fail()
	
func _on_mission_target_destroyed():
	print("_on_mission_target_destroyed")
	target_remain -= 1
	if target_remain <= 0:
		set_mission_condition_success()
			
func set_escort(unitArray):
	for unit in unitArray:
		for i in unit.amount:
			var escort = handler_s.get_unit_instance(unit.type)
			var target = Globals.getRandomEntry(targets)
			Globals.add_unit_to_scene(escort, Globals.Faction.hostile)
#			Globals.curScene.add_unit_to_scene("Enemy_Units", escort)
#			escort.do_init_unit()
#			Globals.set_hostile(escort)
#			escort.set_armaments()
#			escort.add_primary_target(target)
			escort.stats.flee_tresh = 0.25
#			escort.connect("_has_warped_in", target, "add_primary_target", [escort])
			target.connect("_has_warped_out", escort, "_on_target_has_warped_out", [target])
#			escort.speed = target.speed
			escort.set_direction(target.direction)
#			print(escort.direction.x)
			var x:int = 0
			var y:int = 0
				
			if target.position.y > Globals.HEIGHT * 0.9:
				y = target.position.y - Globals.rng.randi_range(400, 650)
#				y = target.position.y - Globals.rng.randi_range(200, 350)
			else:
				y = target.position.y + (Globals.rng.randi_range(200, 350) * Globals.getRandomEntry([-1, 1]))
			
#			print(target.direction)
#			print(escort.direction)
				
			match escort.display:
				"Fighter":
					x = target.position.x + (700 * -target.direction.x)
				"Helicopter_Light":
					x = target.position.x + (700 * -target.direction.x)
				"Bomber":
					x = target.position.x + (1200 * -target.direction.x)
					y = target.position.y - 400
				"Frigate":
					x = target.position.x + (400 * -escort.direction.x)
					escort.stats.can_withdraw = true
					escort.stats.can_crash = false
			
#			print(target.position)
			escort.position = Vector2(x, y)
#			print(attacker.position)
			escort.add_health_bar()
			escort.avoidValues["Player"] = 0.0
			escort.init_as_attacker()
			
			if escort.can_warp_in():
				escort.setup_delayed_warp_in(time_until_target_arrives+1)
			else:
				escort.set_active()

