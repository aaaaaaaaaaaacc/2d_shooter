extends Capital
class_name Boss

var display = "Boss"

func _ready():
	pass
		
func do_specific_unit_init():
	$ThrusterNodes/Aft/Particle2D.emitting = false
	$Mounts/Missiles.hide()
	$Sprites/Missile_Lights.hide()
	
#	disable_missile_tubes()
	
#	for n in $Mounts.get_children():
#		n.get_node("Weapon").forcedDisabled = true
#		n.get_node("Weapon").doDisable()

	for mount in $Mounts.get_children():
#		mount.position *= 1.75
		if mount.has_node("Weapon"):
			if mount.get_node("Weapon").display == "Flak":
				mount.add_health_bar(0.5)

func crash_step_one():
	.crash_step_one()
	
	for n in $ThrusterNodes.get_children():
		n.get_node("Particle2D").emitting = false
		
	var power = $AnimationPlayer.get_animation("crash_powering_down")
	for n in 4:
		power.track_insert_key(n, 2.0, $Sprites.get_child(n+1).self_modulate)
		power.track_insert_key(n, 8.0, Color(0.4, 0.4, 0.4, 1.0))
	$AnimationPlayer.play("crash_powering_down")
		
func kill_by_crash():
	.kill_by_crash()
		
	for n in 35:
		add_exp_fire_smoke_fx(rand_range(0.3, 1.0), rand_range(0.2, 0.6))
		
	for n in 10:
		var explo = Globals.getExplo("radial", get_dmg_gfx_scale())
		explo.position += position + get_point_inside_tex()
		explo.rotation = Globals.rng.randi_range(0, 2*PI)
		Globals.curScene.get_node("Various").add_child(explo)
	
func addPhysCollision():
#	return
	var phys = CollisionShape2D.new()
	phys.name = "CollisionShape2D"
	phys.shape = RectangleShape2D.new()
	phys.shape.extents = Vector2(texDim.x/2, texDim.y/2)
	$Phys.add_child(phys)
	
func bossUnpowerShieldAnimationCallFunction():
	$Mounts/Shield.get_node("Weapon").call_deferred("unpowerShield")
	
func initCallMethodTrack(method, interval, start):
	var animation = Animation.new()
#	animation.set_length(start + (interval * amount))
	animation.add_track(Animation.TYPE_METHOD)
	animation.track_set_path(0, ".")
	
	var maxLength:float
	
	for effect in result:
		for i in effect.stacks:
			var time = start + interval*(i+1)
			maxLength = max(maxLength, time)
			animation.track_insert_key(0, time, {"method" :method, "args" : []})
		
	animation.set_length(maxLength)
#	print("len: ", maxLength)
		
	$AnimationPlayer.add_animation("anim", animation)

func get_crash_velo():
	return 20
	
func do_turnaround():
	pass
	
func getPossibleWeapons(index):
#	return false
#	if index < 1:
#		return Globals.getWeaponBase("Light Missile")
#	if index < 4:
#		return Globals.getWeaponBase("Heavy Autocannon")
#	else:
#		var weapon = Globals.weapon_shield_dir.instance()
##		construct(init_type, init_display, init_health, init_turnrate, init_shield, init_shieldDist = 60, init_shieldLength = 36):
#		weapon.construct(5, "Shield", 120, 70, 72)
#		return weapon
	
	if index == 7: 
#			return Globals.getWeaponBase("Heavy Autocannon")
		var weapon = Globals.getWeaponBase("Boss Missile")
#			var weapon = Globals.getWeaponBase("Swarmlauncher")
		weapon.fof = 90
#			weapon.steerForce = 60
#			weapon.lifetime = 6.0
#			weapon.displaceForce = 0.2
		weapon.vLaunch = true
#			weapon.forcedDisabled = true
		return weapon
	return false
		
	match index:
		0:
#			return Globals.getWeaponBase("Light Missile")
			return Globals.getWeaponBase("Beamlance")
		1:
			return Globals.getWeaponBase("Heavy Autocannon")
		2:
			return Globals.getWeaponBase("Flak")
		3:
			return Globals.getWeaponBase("Flak")
		4:
			return Globals.getWeaponBase("Flak")
		5:
			return Globals.getWeaponBase("Flak")
		6:
#			return Globals.getWeaponBase("Flak")
#			var shield = Globals.weapon_shield_omni.instance()
#			var stats = {"maxShield": 30, "shieldRegenTime": 1.0, "shieldBreakTime": 4.0, "shieldFastCharge": 1.0, "shieldRadius": 180}
			var shield = Globals.weapon_shield_dir.instance()
			var stats = {"maxShield": 80, "shieldRegenTime": 0.5, "shieldBreakTime": 6.0, "shieldFastCharge": 0.75, "shieldDist": 150, "shieldLength": 200}
			shield.construct(5, "Shield", stats)
			shield.add_shield_bar()
			
#			shield.scale_progress_bar("shieldBar", 2.0)
			return shield
		7:
#			return Globals.getWeaponBase("Heavy Autocannon")
			var weapon = Globals.getWeaponBase("Boss Missile")
#			var weapon = Globals.getWeaponBase("Swarmlauncher")
			weapon.fof = 90
#			weapon.steerForce = 60
#			weapon.lifetime = 6.0
#			weapon.displaceForce = 0.2
			weapon.vLaunch = true
#			weapon.forcedDisabled = true
			return weapon

func getSelfSpawnPosition(viewFrom, viewTo):
	return Vector2(Globals.WIDTH/2, Globals.HEIGHT/2 -200)
	
#func check_hp_post_dmg(amount):
##	print("check_hp_post_dmg ", get_class())
#	if health <= 0:
#		kill()
#	elif can_withdraw() and withdraw_condition(amount):
#		enter_withdraw_condition_state()
#	elif can_crash() and crash_condition(amount):
#		enter_crash_condition_state()
#	else:
#		check_add_gfx_dmg_effect()

func check_hp_post_dmg(amount):
	check_add_gfx_dmg_effect()
	add_escalation()

	var tresh = [0.85, 0.65, 0.45, 0.25]
	
	if escalation < tresh.size():
		if health < self.maxHealth * tresh[escalation]:
			print("health now: ", health, ", below: ", tresh[escalation])
			add_escalation()

func add_escalation():
	var max_escalation = 4
	if escalation < max_escalation:
		escalation += 1
		print("add_escalation now: ", escalation)
		adjustEscalationVisuals()
		adjustEscalationMechanics()
	
func disable_missile_tubes():
	if $Mounts/Missiles.has_node("Weapon"):
		$Mounts/Missiles/Weapon.forcedDisabled = true
		$Mounts/Missiles/Weapon.doDisable()
	
func enable_missile_tubes():
	if $Mounts/Missiles.has_node("Weapon"):
		$Mounts/Missiles/Weapon.forcedDisabled = false
		$Mounts/Missiles/Weapon.doEnable()
		$Mounts/Missiles/Weapon.cooldown = 2.0

func adjustEscalationVisuals():
#	var raws = [1.0, 1.8, 2.1, 2.3, 2.5]
#	var fps = [5, 6, 7, 8, 9]
#	var pick = raws[escalation]
#	for n in $Sprites.get_children():
#		if n is AnimatedSprite:
#			n.self_modulate = Color(pick, 1, 1, 1)
#			n.frames.set_animation_speed("default", fps[escalation])


	var speed = 0.7 + (escalation * 0.2)
	var glow_strength = 1.0 + (escalation * 0.25)
	var band_width = 0.2 + (escalation * 0.05)
	
	for sprite in $Sprites/Power.get_children():
#		sprite.material.set_shader_param("speed", speed)
		sprite.material.set_shader_param("glow_strength", glow_strength)
		sprite.material.set_shader_param("band_width", band_width)
			
	if escalation == 1:
		$AnimationPlayer.play("missile_type_activation")
	
	for n in 3:
		var explo = Globals.getExplo("wreck", get_dmg_gfx_scale())
		explo.set_as_toplevel(true)
		explo.offset = get_point_inside_tex()
		explo.delay = rand_range(0.3, 1) * n + 1
		$EffectNodes.add_child(explo)
			
func adjustEscalationMechanics():
	for n in $Mounts.get_children():
		if n.has_node("Weapon"):
			n.get_node("Weapon").rof *= 0.8
	
func get_dmg_gfx_scale():
	return 1.5
