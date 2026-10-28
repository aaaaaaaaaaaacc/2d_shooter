extends Air_Unit
class_name Helicopter_Light

const CRASH_GRAVITY := 30.0
const CRASH_DRAG := 0.995
const CRASH_ROT_ACCEL_MIN := 0.1
const CRASH_ROT_ACCEL_MAX := 0.2
const CRASH_ROT_SPEED_MAX := 10.0

var display = "Helicopter_Light"

func _physics_process(_delta):
	pass
	
func process_movement(_delta):
	
	set_interest()
	set_danger()
	choose_direction()
	accel = chosen_dir.rotated(rotation) * maxSpeed
	accel = accel.limit_length(maxSpeed)
	velocity += accel * _delta
	velocity = velocity.limit_length(maxSpeed)

func do_turnaround():
#	$Sprites/Main.flip_h = !$Sprites/Main.flip_h
	mirrorTurrets()
	mirrorVarious()
	mirrorColNodes()
	mirrorSprite()

func mirrorSprite():
	if $Sprites/Main.flip_h == true:
		for n in $Sprites.get_children():
			n.rotation = -(2*rotation)
			n.flip_h = false
			n.position.x *= -1
	else: 
		for n in $Sprites.get_children():
			n.rotation = 0
			n.flip_h = true
			n.position.x *= -1

func setUnitFacing():
	if $SM.state == $SM.states.crash:
		return
		
	if curTarget == null:
		if moveTarget.x - position.x < 0:
			if $Sprites/Main.flip_h == false:
				do_turnaround()
		else:
			if $Sprites/Main.flip_h == true:
				do_turnaround()
	else: doFaceTarget()

func getPossibleWeapons(index):
#	return
#	var weapon = Globals.getWeaponBase("Beamlance");
	var weapon = Globals.getWeaponBase("Heavy Machinecannon");
#	var weapon = Globals.getWeaponBase("Light Railgun");
#	var weapon = Globals.getWeaponBase("AI_Laser");
	
#	var weapon = Globals.getWeaponBase("Minelayer");
	return weapon
	
func crash_step_one():
	$TimerNodes/CrashTimer.wait_time = 3.0
	$TimerNodes/CrashTimer.one_shot = true
	$TimerNodes/CrashTimer.connect("timeout", self, "crash_step_two")
	$TimerNodes/CrashTimer.start()
	for n in 1:
		add_exp_fire_smoke_fx(1.25, 0.3)
		
	for n in $Mounts.get_children():
		n.kill()

func crash_step_two():
	danger.fill(0.0)
	crashing = true

	# Preserve momentum, but reduce it for the damaged ship.
	crash_velocity = velocity * 0.8
	crash_velocity.y *= 2

	# Ensure a minimum downward falling speed.
	crash_velocity.y = max(crash_velocity.y, 10.0)

	velocity = Vector2.ZERO

	# Pick a spin direction based on the ship's travel direction.
#	var spin_direction = sign(crash_velocity.x)
	var spin_direction = sign(direction.x)
	if spin_direction == 0:
		spin_direction = 1.0

	crash_rotation_speed = 0.0
	crash_rotation_accel = rand_range(
		CRASH_ROT_ACCEL_MIN,
		CRASH_ROT_ACCEL_MAX
	) * spin_direction

	for n in max_smoke:
		add_exp_fire_smoke_fx(1.0, rand_range(0, 1) * n * 2)

	for n in max_smoke:
		var explo = Globals.getExplo("wreck", get_dmg_gfx_scale())
		explo.set_as_toplevel(true)
		explo.offset = get_point_inside_tex()
		explo.delay = rand_range(0.3, 1.0) * n + 3
		$EffectNodes.add_child(explo)


func process_movement_crash(delta):
	# Gravity affects only the vertical axis.
	crash_velocity.y += CRASH_GRAVITY * delta

	# Frame-rate-independent damping.
#	crash_velocity *= pow(CRASH_DRAG, delta * 60.0)

	global_position += crash_velocity * delta

	# Gradually develop a tumble.
	crash_rotation_speed += crash_rotation_accel * delta
	crash_rotation_speed = clamp(
		crash_rotation_speed,
		-CRASH_ROT_SPEED_MAX,
		CRASH_ROT_SPEED_MAX
	)

	# Use angular velocity in degrees per second.
	rotation_degrees += crash_rotation_speed * delta

	# Trigger impact when the ship reaches the ground.
	if global_position.y >= Globals.HEIGHT - 30:
		crash_impact()

#const CRASH_ROT_ACCEL_MIN := 0.8
#const CRASH_ROT_ACCEL_MAX := 1.4
#const CRASH_ROT_SPEED_MAX := 10.0

func crash_impact():
	crashing = false

	global_position.y = Globals.HEIGHT - 30

	crash_rotation_speed = 0
	crash_velocity = Vector2.ZERO
	
func get_crash_velo():
	return max(30, maxSpeed / 4)

func kill_by_crash():
	.kill_by_crash()
		
	for n in max_smoke * 2:
		var explo = Globals.getExplo("radial", get_dmg_gfx_scale())
		explo.position += position + get_point_inside_tex()
		explo.rotation = Globals.rng.randi_range(0, 2*PI)
		Globals.curScene.get_node("Various").add_child(explo)
	
func initAvoidValues():
	avoidValues = {"Player": 2.0, "Fighter": 2.0, "Helicopter_Light": 2.0, "Boundary": 5.0, "Obstacle": 5.0, "Cargohauler": 3.5, "City": 3.5}
