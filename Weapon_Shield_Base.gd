extends Weapon_Base
class_name Weapon_Shield_Base

var baseStats:Dictionary
var health:int
var armor:int = 0
var maxHealth:int
var shield:int
var maxShield:int
var shieldRadius:int
var shieldRegenTime:float
var shieldBreakTime:float
var shieldFastCharge:float
var shieldLength:int = 36
var shieldDist:int = 60
var is_powering_up:bool = false
var shieldbar = null

var isRamming = false
const SHIELD_BREAK_TWEEN_TIME:float = 0.6

var dmgZones = {"Shield": 1}

var tween = null

#var time:float

signal updateShield_UI_Nodes
signal updateShieldBreakCooldown
		
func connect_shield_timer_signals():
	$TimerNodes/ShieldRegen.connect("timeout", self, "_on_ShieldRegen_timeout")
	$TimerNodes/ShieldRegen.wait_time = shieldRegenTime
	if shieldBreakTime > 0.0:
		$TimerNodes/ShieldBreak.connect("timeout", self, "_on_ShieldBreak_timeout")
		$TimerNodes/ShieldBreak.wait_time = shieldBreakTime
	$TimerNodes/ShieldBreakUpdateTimer.connect("timeout", self, "_ShieldBreakUpdateTimer_timeout")
	if shieldFastCharge > 0.0:
		$TimerNodes/ShieldSupercharge.connect("timeout", self, "_on_Supercharge_timeout")
	

func construct(init_type, init_display, stats):
	type = init_type
	display = init_display
	baseStats = stats
	set_shield_base_stats()
	if shieldFastCharge > 0.0:
		shield = 0
	else: 
		shield = maxShield

func set_shield_base_stats():
	for key in baseStats:
		self[key] = baseStats[key]
#
#func connectHurtBoxes():
##	print("connectHurtBoxes for: ", self.display)
#	$ColNodes.get_node("Shield").connect("area_entered", self, "_on_Shield_area_entered")
#
#func _on_Shield_area_entered(area):
##	print(area.owner.display, "-", area.name, " ENTER ", self.display, "/", name, " frame: ", Engine.get_idle_frames())
#	if area.owner.is_in_group("isUnit"):
#		return
#	handleImpact(area, self.dmgZones["Shield"])
	
func _on_area_exited(area):
	pass
	
func _physics_process(_delta):
	if has_ControlNodes:
		handleControlNodes()
	
func handleControlNodes():
	for n in $ControlNodes.get_children():
		n.rect_position = global_position + n.offset
	pass

func is_in_active_burst():
	return false
	
func can_fire():
	return false
	
func update_cooldown_ui_nodes():
	return
	
func doUnselect():
	return false
	
func kill():
	if destroyed or indestructable: return
	destroyed = true
	if active:
		doDisable()
	set_physics_process(false)
	emit_signal("_isdestroyed")
	if has_node("ControlNodes"):
		$ControlNodes.set_as_toplevel(false)
		hide_control_nodes()
#	disable_col_nodes()
	disable_all_timers()
	
func doDisable():
	if destroyed:
		handle_shield_disable_on_kill()
	unpowerShield()
	.doDisable()
	shield = 0
	updateShield()
		
func handle_shield_disable_on_kill():
	if tween.is_running():
		if is_powering_up:
			tween.stop()

func doEnable():
	.doEnable()
	powerShield()
	
func disable_col_nodes():
	if has_node("ColNodes"):
		call_deferred("next_frame_disable_col_nodes")
		
func next_frame_disable_col_nodes():
#	print("disabling ", self.display)
	for n in $ColNodes.get_children():
		n.set("monitoring", false)
		n.set("monitorable", false)
		for i in n.get_children():
			i.disabled = true
	
func unpowerShield():
	disable_col_nodes()
	$TimerNodes/ShieldRegen.stop()
	if active == false: 
		$Shield.modulate.a = 0.0
		$Shield.scale = Vector2(3.5, 3.5)
		return
		
	print("unpowerShield on ", display, " #", get_instance_id(), " frame: ", Engine.get_idle_frames())

	tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property($Shield, "modulate:a", 0.0, SHIELD_BREAK_TWEEN_TIME)
	tween.tween_property($Shield, "scale", Vector2(3.5, 3.5), SHIELD_BREAK_TWEEN_TIME)
	
func powerShield():
	if active == false:
		return
	active = false
	is_powering_up = true
	print("powerShield on ", display, " #", get_instance_id(), " frame: ", Engine.get_idle_frames())
	
	var target_charge:int = maxShield * shieldFastCharge
	var charge_tick:float = 0.05
	var total_time:float = (charge_tick * target_charge) + charge_tick

	$TimerNodes/ShieldRegen.wait_time = charge_tick
	$TimerNodes/ShieldRegen.start()
	
	tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property($Shield, "modulate:a", shieldFastCharge, SHIELD_BREAK_TWEEN_TIME)
	tween.tween_property($Shield, "scale", get_shield_max_scale(), SHIELD_BREAK_TWEEN_TIME)
	tween.set_parallel(false)
	tween.tween_callback(self, "powering_up_done")
	
	$TimerNodes/ShieldSupercharge.wait_time = total_time
	$TimerNodes/ShieldSupercharge.start()
	
func get_shield_max_scale():
	pass
#
func powering_up_done():
	is_powering_up = false
	active = true
	enableCollisionNodes()
	
func enableCollisionNodes():
#	print(self.display, ": ENABLE collisions")
	call_deferred("next_frame_enableCollisionNodes")
			
func next_frame_enableCollisionNodes():
#	print("enabling colNodes ", self.display)
	for n in $ColNodes.get_children():
		n.set("monitoring", true)
		n.set("monitorable", true)
		for i in n.get_children():
			i.disabled = false

func _on_Supercharge_timeout():
	$TimerNodes/ShieldRegen.wait_time = shieldRegenTime
	$TimerNodes/ShieldRegen.start()

func updateShield():
	#print("updateShield")
	setShieldBarHealth()

	if true:
		var factor:float = float(shield) / maxShield
		$Shield.material.set_shader_param("shield_strength", factor)
#		$Shield.modulate.a = factor
			
func setShieldBarBreakTime(time_left):
	if shieldbar and shieldbar.has_node("Value"):
		shieldbar.get_node("Value").text = str("%.1f" % time_left)
	
func doBreakShield():
	unpowerShield()
	shooter.checkForTriggers("on_shieldbreak")
	$TimerNodes/ShieldBreak.start()
	$TimerNodes/ShieldBreakUpdateTimer.start()

func _ShieldBreakUpdateTimer_timeout():
	if $TimerNodes/ShieldBreak.time_left > 0.0:
		$TimerNodes/ShieldBreakUpdateTimer.start()
		setShieldBarBreakTime($TimerNodes/ShieldBreak.time_left)
	
func _on_ShieldRegen_timeout():
#	time -= $TimerNodwwes/ShieldRegen.wait_time
	shield = min(maxShield, shield + 1)
	updateShield()
	$TimerNodes/ShieldRegen.start()
	
func _on_ShieldBreak_timeout():
	$TimerNodes/ShieldBreak.stop()
	$TimerNodes/ShieldBreakUpdateTimer.stop()
	powerShield()

func doInitUI():
	return false

func canBeSelected():
	return false
	
func getRamDamage():
	return shooter.getRamDamage()
	
func take_damage(entity, totalDmg:int):

	var pos = entity.getPointOfImpact(self)
	var angle = entity.getAttackAngle(self)
	
	shooter.applyForce(-(entity.impactForce).rotated(angle))
	
	var remDmg = totalDmg
	var shieldBefore = self.shield
	
#	print("takeDmg on ", self.display, " totalDmg: ", totalDmg)
	
	if shield > 0:
		shield -= remDmg
		remDmg = 0
		if shield < 0:
			remDmg = -shield
			shield = 0
			
	if remDmg:
		remDmg = max(0, remDmg - self.armor)
#		print("health dmg ", remDmg)
		health -= remDmg
		
	var shieldDmgTaken = shieldBefore - shield
	
	if shieldDmgTaken:
		handle_shield_damage(shieldDmgTaken, pos, angle)
	if remDmg:
		handle_shield_overflow_damage(entity, remDmg)
	emit_signal("_damage_taken")
		
func handle_shield_damage(shieldDmgTaken, pos, angle):
	addShieldExplosion(shieldDmgTaken, pos, angle)
	var labelPos = pos + Vector2(0, -(texDim.y/2) -10)
	createFloatingLabel(shieldDmgTaken, labelPos, Vector2(0, -100), false, "00b7ff")
	shooter.checkForTriggers("on_shield_damage")
	updateShield()
	if shield <= 0:
		call_deferred("doBreakShield")
	elif shield < maxShield:
		$TimerNodes/ShieldRegen.start()
	
func createFloatingLabel(string, pos, vector, crit = false, color = null):
	var dmg_label = Globals.DMG_LABEL.instance()
	Globals.curScene.get_node("Various").add_child(dmg_label)
	dmg_label.global_position = pos
	dmg_label.init_floating_number(string, vector, 2.5, PI/2, crit, color)
	
func addShieldExplosion(damage, pos, angle):
	var baseDmg = 8.0
	var scale:float  = sqrt(damage/baseDmg)
	var explo = Globals.getExplo("shield", scale)
	explo.position += pos
	explo.rotation = angle
	Globals.curScene.get_node("Various").add_child(explo)

func handle_shield_overflow_damage(entity, remDmg):
	print("handle_hull_damage on SHIELD")
	self.shooter.take_damage(entity, remDmg)
	return
	
func add_shield_bar(size:float = 1.0):
	print("add_shield_bar on ", self.display)
	shieldbar = Globals.SHIELDBAR.instance()
	shieldbar.offset = Vector2(0, 80)
	var bar = shieldbar.get_node("ProgressBar")
	bar.min_value = 0
	bar.max_value = round(self.maxShield)
	setShieldBarHealth()
	has_ControlNodes = true
	$ControlNodes.add_child(shieldbar)
	shieldbar.set_as_toplevel(true)
	
	if size:
		shieldbar.rect_scale = Vector2(size, size)
	#	target.offset.y *= targetScale
		if size <= 0.5:
			shieldbar.get_child(0).percent_visible = false
			
func _on_damage_taken():
	if shieldbar != null:
		setShieldBarHealth()
#	if shieldlabel != null:
#		setShieldLabelHealth()
	
#func setShieldLabelHealth():
#	shieldlabel.get_node("Label").text = str(round(self.shield), " / ", self.maxShield)

func setShieldBarHealth():
	if shieldbar == null:
		return
	if shieldbar is TextureProgress:
		shieldbar.value = self.shield
		shieldbar.max_value = self.maxShield
		if shieldbar.has_node("Value"):
			shieldbar.get_node("Value").text = str(round(self.shield), " / ", self.maxShield)
	else:
		shieldbar.get_node("ProgressBar").value = self.shield
		shieldbar.get_node("ProgressBar").max_value = self.maxShield
		if shieldbar.has_node("Value"):
			shieldbar.get_node("Value").text = str(round(self.shield), " / ", self.maxShield)
