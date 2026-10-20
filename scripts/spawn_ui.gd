extends PanelContainer

var is_placing:bool = false
var position:Vector2 = Vector2.ZERO

var unit:Base_Unit = null


func _ready():
	init_spawn_panel()
	
func do_pause(state:bool):
	Globals.isPaused = state
	get_tree().paused = state

func _process(delta):
	if is_placing:
#		var id = $MC/HA/CC/VA3/OptionButton.get_selected_id()
#		var name = $MC/HA/CC/VA3/OptionButton.get_item_text(id)
#		var unit = Globals.handler_spawner.get_unit_instance(Handler_Spawn.UnitType[name])
		unit.position = Globals.MOUSE
		
func _input(event):
	if is_placing:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				is_placing = false
				unit.set_active()
				unit = null

func init_spawn_panel():
	var i:int = 0
	for val in Handler_Spawn.UnitType:
		print(val, ": ", i)
		i+= 1
		
#	print(Handler_Spawn.UNIT_SCENES[10])
	
#	for key in Handler_Spawn.UNIT_SCENES.keys():
#		var value = Handler_Spawn.UNIT_SCENES[key]
#		print(value, " -> ", key)
	
#	for n in Handler_Spawn.UNIT_SCENES.values():
#		print(Handler_Spawn.UNIT_SCENES[n])
		
	for unit in Handler_Spawn.UnitType:
		$MC/HA/CC/VA3/OptionButton.add_item(unit)

func _on_Button_pressed():
	
	var id = $MC/HA/CC/VA3/OptionButton.get_selected_id()
	var name = $MC/HA/CC/VA3/OptionButton.get_item_text(id)
	unit = Handler_Spawn.UNIT_SCENES[id].instance()
	unit.set_inactive()
	Globals.add_unit_to_scene(unit, Globals.Faction.hostile)
#	print($MC/HA/CC/VA3/OptionButton.get_item_text(id))
#	print(u.display)
	
	is_placing = true
	
#	var unit = Globals.handler_spawner.get_unit_instance(Handler_Spawn.UnitType[name])
#	print(unit.display, " #", unit.id)
#
#	Globals.add_unit_to_scene(unit, Globals.Faction.hostile)
#	unit.set_direction(Vector2(Globals.getRandomEntry([-1, 1]), 0))
#	unit.add_health_bar()
