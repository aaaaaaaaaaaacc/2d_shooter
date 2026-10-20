extends Node2D
class_name Handler_Spawn

const currency = preload("res://scenes/Utilities/Currency.tscn")

enum UnitType {
	TRUCK_LIGHT,
	TRUCK_HEAVY,
	JEEP,
	ARTILLERY,
	HELI_LIGHT,
	HELI_HEAVY,
	FIGHTER,
	BOMBER,
	FRIGATE,
	DESTROYER,
	CRUISER,
	AA_TOWER,
	MOBILE_AA_LIGHT,
	MOBILE_AA_HEAVY,
	CITY,
	CARGO_HAULER,
	BOSS,
	DRONE_SHIELD,
	DRONE_SHOTGUN,
	DRONE_KAMIKAZE
}
# Load enemy scenes on game startup
#const TRUCK_LIGHT = preload("res://scenes/Units/Unit_Truck_Light.tscn")
#const TRUCK_HEAVY = preload("res://scenes/Units/Unit_Truck_Heavy.tscn")
#const JEEP = preload("res://scenes/Units/Unit_Jeep.tscn")
#const ARTILLERY = preload("res://scenes/Units/Unit_Arty.tscn")
#const HELI_LIGHT = preload("res://scenes/Units/Unit_Helicopter_Light.tscn")
#const HELI_HEAVY = preload("res://scenes/Units/Unit_Helicopter_Heavy.tscn")
#const FIGHTER = preload("res://scenes/Units/Unit_Fighter.tscn")
#const BOMBER = preload("res://scenes/Units/Unit_Bomber.tscn")
#const FRIGATE = preload("res://scenes/Units/Unit_Frigate.tscn")
#const DESTROYER = preload("res://scenes/Units/Unit_Destroyer.tscn")
#const CRUISER = preload("res://scenes/Units/Unit_Cruiser.tscn")
#const AA_TOWER = preload("res://scenes/Units/Unit_AA_Tower.tscn")
#const MOBILE_AA_LIGHT = preload("res://scenes/Units/Unit_Mobile_AA_Light.tscn")
#const MOBILE_AA_HEAVY = preload("res://scenes/Units/Unit_Mobile_AA_Heavy.tscn")
#const CITY = preload("res://scenes/Units/Unit_City.tscn")
#const CARGO_HAULER = preload("res://scenes/Units/Unit_Cargo_Hauler.tscn")
#const BOSS = preload("res://scenes/Units/Unit_Boss.tscn")
#const DRONE_SHIELD = preload("res://scenes/Units/Unit_DroneShield.tscn")
#const DRONE_SHOTGUN = preload("res://scenes/Units/Unit_Drone_Shotgun.tscn")
#const DRONE_KAMIKAZE = preload("res://scenes/Units/Unit_Drone_Kamikaze.tscn")

const UNIT_SCENES = {
	UnitType.TRUCK_LIGHT: preload("res://scenes/Units/Unit_Truck_Light.tscn"),
	UnitType.TRUCK_HEAVY: preload("res://scenes/Units/Unit_Truck_Heavy.tscn"),
	UnitType.JEEP: preload("res://scenes/Units/Unit_Jeep.tscn"),
	UnitType.ARTILLERY: preload("res://scenes/Units/Unit_Arty.tscn"),
	UnitType.HELI_LIGHT: preload("res://scenes/Units/Unit_Helicopter_Light.tscn"),
	UnitType.HELI_HEAVY: preload("res://scenes/Units/Unit_Helicopter_Heavy.tscn"),
	UnitType.FIGHTER: preload("res://scenes/Units/Unit_Fighter.tscn"),
	UnitType.BOMBER: preload("res://scenes/Units/Unit_Bomber.tscn"),
	UnitType.FRIGATE: preload("res://scenes/Units/Unit_Frigate.tscn"),
	UnitType.DESTROYER: preload("res://scenes/Units/Unit_Destroyer.tscn"),
	UnitType.CRUISER: preload("res://scenes/Units/Unit_Cruiser.tscn"),
	UnitType.AA_TOWER: preload("res://scenes/Units/Unit_AA_Tower.tscn"),
	UnitType.MOBILE_AA_LIGHT: preload("res://scenes/Units/Unit_Mobile_AA_Light.tscn"),
	UnitType.MOBILE_AA_HEAVY: preload("res://scenes/Units/Unit_Mobile_AA_Heavy.tscn"),
	UnitType.CITY: preload("res://scenes/Units/Unit_City.tscn"),
	UnitType.CARGO_HAULER: preload("res://scenes/Units/Unit_Cargo_Hauler.tscn"),
	UnitType.BOSS: preload("res://scenes/Units/Unit_Boss.tscn"),
	UnitType.DRONE_SHIELD: preload("res://scenes/Units/Unit_DroneShield.tscn"),
	UnitType.DRONE_SHOTGUN: preload("res://scenes/Units/Unit_Drone_Shotgun.tscn"),
	UnitType.DRONE_KAMIKAZE: preload("res://scenes/Units/Unit_Drone_Kamikaze.tscn"),
}



var player
var wave = Array()
var enemies = Array()
var unitData = Array()
var mission_unit_data = Array()
var enemy_str_max:int = 0
var enemy_str_cur:int = 0
var totalWeight:int = 0

const reinforce_check_interval:float = 5.0
var current_reinforce_check_timer:float = 0.0
var timeSinceLastReinforceCheck:float = 0.0

const difficulty_increase_timer_interval:float = 5.0

var enabled = false

signal wave_updated
signal diffi_updated
var diffi_add_timer:Timer

#var diffiUI
#var waveUI

func _init():
	pass
	
func _physics_process(_delta):
	current_reinforce_check_timer += _delta
	if current_reinforce_check_timer >= reinforce_check_interval:
		current_reinforce_check_timer = 0.0
		check_for_reinforce()
				
func check_for_reinforce():
	if enemy_str_cur < enemy_str_max * 0.7:
		var reinforceStrength:int = floor(enemy_str_max/5)
#		print("enemies under 0.7 of max ---", enemy_str_cur, "/", enemy_str_max)
#		print("add: ", reinforceStrength)
		Globals.UI.set_main_text(str("Reinforce by ", reinforceStrength))
		
		pick_units_into_pool(reinforceStrength)
		spawn_all_from_pool()

func get_unit_instance(unit_enum):
	return UNIT_SCENES[unit_enum].instance()

func do_bare_setup():
	print("do_bare_setup ", name)
	name = "Handler_Spawner"
	player = Globals.PLAYER

func connect_debug_diffi_ui_in_game():
	diffi_add_timer = Globals.curScene.get_node("Timers/diffi_add_timer")
	diffi_add_timer.connect("timeout", self, "_on_diffi_add_timer_timeout")
	
func do_enable():
	print("do_enable ", name)
	enabled = true
	set_physics_process(enabled)
	diffi_add_timer.wait_time = difficulty_increase_timer_interval
	diffi_add_timer.start()
	
	use_mission_spawn_data()
	pick_units_into_pool(Globals.DIFFICULTY)
	spawn_all_from_pool()
	Globals.UI.set_main_text(str(name, " enabled"))
	
func do_disable():
	print("do_disable ", name)
	enabled = false
	set_physics_process(enabled)
	if is_instance_valid(diffi_add_timer) == true:
		diffi_add_timer.stop()
		
	Globals.UI.set_main_text(str(name, " disabled"))
	
func getSpawnOutsideView(enemy):
	var cam = Globals.curScene.get_node("CamA")
	#var viewport = get_viewport_rect().size
	var camPos = cam.position
	if camPos == Vector2.ZERO:
		return enemy.getSelfSpawnPosition(Vector2.ZERO, Vector2.ZERO)
	var SCREEN = Globals.SCREEN
	var from = Vector2(camPos - (SCREEN/2))
	var to = Vector2(from + SCREEN)
	return enemy.getSelfSpawnPosition(from, to)
	
func get_raw_unit_data_for_mission():
	return [
		#{"type": truck, "tresh": 1, "amount": 0, "strength": 1, "weight": 10},
		{"const": "FIGHTER", "legal": false, "tresh": 0, "amount": 0, "strength": 3, "weight": 6},
		{"const": "HELI_LIGHT", "legal": false, "tresh": 12, "amount": 0, "strength": 5, "weight": 3},
		{"const": "HELI_HEAVY", "legal": false, "tresh": 35, "amount": 0, "strength": 3, "weight": 2},
		{"const": "JEEP", "legal": false, "tresh": 0, "amount": 0, "strength": 2, "weight": 2},
		{"const": "FRIGATE", "legal": false, "tresh": 35, "amount": 0, "strength": 3, "weight": 2},
		{"const": "DESTROYER", "legal": false, "tresh": 55, "amount": 0, "strength": 7, "weight": 1},
	]
	
func use_mission_spawn_data():
	unitData = mission_unit_data
	
func set_spawner_unit_data():
	
	unitData =  [
		#{"type": truck, "tresh": 1, "amount": 0, "strength": 1, "weight": 10},
		{"type": currency.instance(), "display": "", "legal": true, "tresh": 0, "amount": 0, "strength": 3, "weight": 6},
		{"type": currency.instance(), "display": "", "legal": false, "tresh": 0, "amount": 0, "strength": 3, "weight": 6},
		{"type": currency.instance(), "display": "", "legal": true, "tresh": 12, "amount": 0, "strength": 5, "weight": 3},
		{"type": currency.instance(), "display": "", "legal": true, "tresh": 22, "amount": 0, "strength": 4, "weight": 3},
		{"type": currency.instance(), "display": "", "legal": true, "tresh": 35, "amount": 0, "strength": 3, "weight": 2},
		{"type": currency.instance(), "display": "", "legal": false, "tresh": 55, "amount": 0, "strength": 7, "weight": 1},
		{"type": currency.instance(), "display": "", "legal": false, "tresh": 55, "amount": 0, "strength": 7, "weight": 1},
		{"type": currency.instance(), "display": "", "legal": true, "tresh": 0, "amount": 0, "strength": 2, "weight": 2},
		{"type": currency.instance(), "display": "", "legal": true, "tresh": 25, "amount": 0, "strength": 5, "weight": 1},
		{"type": currency.instance(), "display": "", "legal": false, "tresh": 25, "amount": 0, "strength": 4, "weight": 2},
		{"type": currency.instance(), "display": "", "legal": true, "tresh": 25, "amount": 0, "strength": 4, "weight": 2},
		{"type": currency.instance(), "display": "", "legal": true, "tresh": 25, "amount": 0, "strength": 4, "weight": 2},
		{"type": currency.instance(), "display": "", "legal": false, "tresh": 100, "amount": 0, "strength": 4, "weight": 2},
		{"type": currency.instance(), "display": "", "legal": true, "tresh": 10, "amount": 0, "strength": 4, "weight": 2},
		{"type": currency.instance(), "display": "", "legal": true, "tresh": 10, "amount": 0, "strength": 4, "weight": 2},
	]
	
	for n in unitData:
		n.display = n.type.display.to_upper()
	
#	if Globals.handler_mission.pick == Globals.handler_mission.missions.SALVAGE_CARGOHAULER:
#		return
	return
	for n in unitData:
		if n.display != "Fighter":
			n.legal = false
#	print("ding")
	
func pick_units_into_pool(reinforcePoints):
#	return
	totalWeight = 0
	for entry in unitData:
		if entry.tresh >= Globals.DIFFICULTY or entry.legal == false: continue
		totalWeight += entry.weight
		
	if totalWeight > 0:
		while reinforcePoints >= 0:
			var dice = Globals.rng.randi_range(0, totalWeight)
			var current = dice
	#		print("totalWeight: ", totalWeight)
	#		print("rolled ", dice)
			for entry in unitData:
				if entry.tresh >= Globals.DIFFICULTY or entry.legal == false: continue
				if current > entry.weight:
					current -= entry.weight
				else:
#					print("adding: ",  entry.const, " to spawn")
					entry.amount += 1
					reinforcePoints -= entry.strength
					break
#		for entry in unitData:
#			if entry.amount > 0:
#				print("reinforcing by: ", entry.amount, "x ", entry.const)
	return
#	return roster
			
func adjustWaveDataByMission():
	if Globals.handler_mission.pick == Globals.handler_mission.missions.PROTECT_CITY or Globals.handler_mission.pick ==  Globals.handler_mission.missions.SALVAGE_CARGOHAULER:
		for entry in unitData:
			if entry.display == "Jeep":
				entry.legal = false
#func create_initial_wave():
	
func spawn_all_from_pool():
	for element in unitData:
		var amount = element["amount"]
		for i in amount:
			element["amount"] -= 1
			var unit = get(element.const).instance()
			unit.set_wave_strength(element.strength)
			enemy_str_cur += unit.wave_strength
			spawn_and_init_unit(unit)
	
	emit_signal("diffi_updated", Globals.DIFFICULTY)
	emit_signal("wave_updated", enemy_str_cur, enemy_str_max)
	print("post reinforce: ", enemy_str_cur, "/", enemy_str_max)

func doInstanceEnemy(name):
	return get(name).instance()

func spawn_and_init_unit(enemy):
#	return
#	enemy.queue_free()
#	return
	Globals.curScene.add_unit_to_scene("Enemy_Units", enemy)
	enemy.do_init_unit()
	enemy.position = getSpawnOutsideView(enemy)
#	print("deploying enemy: ", enemy.display, " at ", pos)
#	enemy.position = Vector2(player.position.x + 100, player.position.y - 700 + Globals.curScene.get_node("Enemy_Units").get_children().size() * 125)
#	enemy.position = player.position + Vector2(0, - 300)
#	enemy.rotation = PI/3
#	enemy.kill()
	Globals.set_hostile(enemy)
	enemy.set_armaments()
#	print(enemy.get_node("Mounts").get_child(0).get_child(0).get_node("Sprites/Main").scale)
	enemy.set_direction()
#	enemy.set_active()
#	enemy.speed = 0
	enemy.connect("_isdestroyed", self, "_on_enemy_from_wave_destroyed", [enemy])
	enemy.set_active()
#	enemy.doFullyEnable()
	#print("spawning ", enemy.display, ": ", enemy.position, ", rot: ", enemy.rotation_degrees)

func spawnSpecial():
#	timer.queue_free()
			
	var enemy = UNIT_SCENES.UNIT_KAMIKAZE.instance()
	Globals.curScene.add_unit_to_scene("Enemy_Units", enemy)
	enemy.do_init_unit()
	var pos = getSpawnOutsideView(enemy)
	enemy.position = pos
#	enemy.kill()
	enemy.set_hostile()
	enemy.set_armaments()
	enemy.set_direction()
	enemy.visible = false
	enemy.set_inactive()
	
	enemy.connect("_isdestroyed", self, "_on_enemy_from_wave_destroyed", [enemy])
	
	Globals.curScene.doZoom(1, 1.5, 0.25)
	
	var timerB = Timer.new()
	Globals.curScene.add_child(timerB)
	timerB.connect("timeout", enemy, "doDelayedWarpIn", [timerB])
	timerB.wait_time = 1
	timerB.start()
	
	print("spawnSPECIAL ", enemy.display, ": ", enemy.position, ", rot: ", enemy.rotation_degrees)
	
func _on_enemy_from_wave_destroyed(enemy):
	print("_on_enemy_from_wave_destroyed: ", enemy.display)
	enemy_str_cur -= enemy.wave_strength
#	Globals.UI.set_wave_info()
	emit_signal("wave_updated", enemy_str_cur, enemy_str_max)

#	for n in mission_unit_data:
#		if enemy.display.to_upper() == n.display:
#			enemy_str_cur -= n.strength
#			Globals.UI.set_wave_info()
#			return
			
#	print("enemy strength: ", enemy_str_cur, "/", enemy_str_max)

func _on_diffi_add_timer_timeout():
	print("_on_diffi_add_timer_timeout")
	increase_difficulty(1)
	diffi_add_timer.start()
	
func increase_difficulty(value:int):
	Globals.DIFFICULTY += value
	enemy_str_max += value
	emit_signal("diffi_updated", Globals.DIFFICULTY)
	emit_signal("wave_updated", enemy_str_cur, enemy_str_max)
#	UI.set_diffi_info(DIFFICULTY)
#	UI.set_main_text("Diff up")
	
#	print("adding difficulty: ", value, ", now: ", Globals.DIFFICULTY)
	

