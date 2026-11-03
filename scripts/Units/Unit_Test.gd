extends Capital
class_name Unit_Test

var display = "Unit_Test"
	
func adjust_stats_res():
	pass
	
func getPossibleWeapons(index):
#	return false
#	var shield = Globals.weapon_shield_dir.instance()
#	var stats = {"maxShield": 60, "shieldRegenTime": 0.5, "shieldBreakTime": 6.0, "shieldFastCharge": 0.75, "shieldDist": 80, "shieldLength": 50}
#	shield.construct(5, "Shield", stats)
#	shield.add_shield_bar()
#	shield.scale_progress_bar("shieldbar", 0.5)
#	return shield

	return get_shield()
	
func get_shield():
	
	return get_omni_shield()
	return get_direct_shield()
	
func get_omni_shield():
	var shield = Globals.weapon_shield_omni.instance()
	
	var stats = {"maxShield": 30, "shieldRegenTime": 1.0, "shieldBreakTime": 4.0, "shieldFastCharge": 1.0, "shieldRadius": 80}
		
	shield.construct(5, "Shield", stats)
	shield.add_shield_bar(0.5)
#	shield_omni.position = Vector2(-15, 0)
#	shield_omni.connect("updateShield_UI_Nodes", mainUI, "_on_updateShield_UI_Nodes")
#	shield_omni.connect("updateShieldBreakCooldown", mainUI, "_on_updateShieldBeakCooldown")
#	shield_omni.shieldbar = Globals.UI.get_node("Bars/Panel/VBox/CC_HealthShield/VBox/Bar_Shield")
	return shield

func get_direct_shield():
	var shield = Globals.weapon_shield_dir.instance()
	var stats = {"maxShield": 60, "shieldRegenTime": 0.5, "shieldBreakTime": 6.0, "shieldFastCharge": 0.75, "shieldDist": 80, "shieldLength": 50}
	shield.construct(5, "Shield", stats)
	shield.add_shield_bar(0.5)
	return shield

func applyForce(force):
	return

func on_warp_in_done():
	print("on_warp_in_done frame: ", Engine.get_idle_frames())
	.on_warp_in_done()
	$SM.set_state($SM.states.wander)

func set_new_target():
	pass
	
func kill():
	indestructable = true
	.kill()
