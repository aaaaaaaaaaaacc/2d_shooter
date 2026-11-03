extends Air_Unit
class_name Helicopter_Light
#
#const CRASH_GRAVITY := 30.0
#const CRASH_DRAG := 0.995
#const CRASH_ROT_ACCEL_MIN := 0.1
#const CRASH_ROT_ACCEL_MAX := 0.2
#const CRASH_ROT_SPEED_MAX := 10.0


# Tunable Crash Physics Constants
const CRASH_GRAVITY := 140.0          # Downward acceleration (increase for heavier feel)
const CRASH_X_DRAG := 0.985           # Horizontal air resistance
const CRASH_FORWARD_PULL := 90.0      # Forward pull from tilted rotors during dive

const CRASH_ROT_ACCEL_MIN := 10.0     # Degrees/sec^2 (was 0.3, which was barely visible)
const CRASH_ROT_ACCEL_MAX := 25.0
const CRASH_ROT_SPEED_MAX := 30.0     # Max pitch rate in degrees/sec
const CRASH_NOSE_DIVE_ANGLE := 10.0   # Max nose-down angle so it hits nose-first

const CONTROL_LOSS_TIME := 1.8        # Seconds it takes to fully lose rotor lift
const WOBBLE_SPEED := 3.0            # Speed of initial pitch shudder
const WOBBLE_STRENGTH := 3.0          # Degrees of initial pitch shudder

var display = "Helicopter_Light"
var crash_elapsed := 0.0
var spin_direction := 1.0
var initial_crash_rot := 0.0

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
	$TimerNodes/CrashTimer.wait_time = 2.0 # Shortened slightly so it doesn't stall too long
	$TimerNodes/CrashTimer.one_shot = true
	if not $TimerNodes/CrashTimer.is_connected("timeout", self, "crash_step_two"):
		$TimerNodes/CrashTimer.connect("timeout", self, "crash_step_two")
	$TimerNodes/CrashTimer.start()
	
	add_exp_fire_smoke_fx(1.25, 0.3)


func crash_step_two():
	danger.fill(0.0)
	crashing = true
	crash_elapsed = 0.0
	initial_crash_rot = rotation_degrees

	# Preserve horizontal momentum; start with a slight downward drop (or upward pop)
	crash_velocity.x = velocity.x * 0.85
	crash_velocity.y = max(velocity.y, 5.0)
	velocity = Vector2.ZERO

	# Pick dive direction based on travel direction (fallback to facing/right)
	spin_direction = sign(direction.x)
	if spin_direction == 0:
		spin_direction = 1.0 if scale.x >= 0.0 else -1.0

	crash_rotation_speed = 0.0
	crash_rotation_accel = rand_range(
		CRASH_ROT_ACCEL_MIN,
		CRASH_ROT_ACCEL_MAX
	)

	for n in max_smoke:
		add_exp_fire_smoke_fx(1.0, rand_range(0, 1) * n * 2)

	for n in max_smoke:
		var explo = Globals.getExplo("wreck", get_dmg_gfx_scale())
		explo.set_as_toplevel(true)
		explo.offset = get_point_inside_tex()
		explo.delay = rand_range(0.3, 1.0) * n + 3
		$EffectNodes.add_child(explo)


func process_movement_crash(delta):
	crash_elapsed += delta
	
	# 0.0 = just started losing control, 1.0 = complete loss of lift
	var control_loss = clamp(crash_elapsed / CONTROL_LOSS_TIME, 0.0, 1.0)
	# Smooth ease-in curve so it struggles briefly before dropping fast
	var dive_factor = control_loss * control_loss

	# 1. VERTICAL MOVEMENT: Rotor lift fades out, gravity takes over
	var current_gravity = lerp(CRASH_GRAVITY * 0.15, CRASH_GRAVITY, dive_factor)
	crash_velocity.y += current_gravity * delta

	# 2. HORIZONTAL MOVEMENT: Tilted rotor pulls the helicopter forward into an arc
	crash_velocity.x += spin_direction * CRASH_FORWARD_PULL * dive_factor * delta
	# Apply air drag primarily to X so Y can reach a fast terminal velocity
	crash_velocity.x *= pow(CRASH_X_DRAG, delta * 60.0)

	global_position += crash_velocity * delta

	# 3. ROTATION: Wobble at first, then pitch into a clamped nose-first angle
	crash_rotation_speed += crash_rotation_accel * dive_factor * delta
	crash_rotation_speed = min(crash_rotation_speed, CRASH_ROT_SPEED_MAX)

	# Advance the base pitch toward the nose-dive angle (clamped so it won't flip upside down)
	var target_nose_angle = CRASH_NOSE_DIVE_ANGLE * spin_direction
	initial_crash_rot = move_toward(
		initial_crash_rot,
		target_nose_angle,
		crash_rotation_speed * delta
	)

	# Add a struggling shudder that fades out as the nose locks into the dive
	var wobble = sin(crash_elapsed * WOBBLE_SPEED) * WOBBLE_STRENGTH * (1.0 - dive_factor * 0.7)
	rotation_degrees = initial_crash_rot + wobble

	# Trigger impact when the ship reaches the ground
	if global_position.y >= Globals.HEIGHT - 30:
		crash_impact()
	
#func crash_step_one():
#	$TimerNodes/CrashTimer.wait_time = 3.0
#	$TimerNodes/CrashTimer.one_shot = true
#	$TimerNodes/CrashTimer.connect("timeout", self, "crash_step_two")
#	$TimerNodes/CrashTimer.start()
#	for n in 1:
#		add_exp_fire_smoke_fx(1.25, 0.3)
#
#	for n in $Mounts.get_children():
#		n.kill()
#
#func crash_step_two():
#	danger.fill(0.0)
#	crashing = true
#
#	# Preserve momentum, but reduce it for the damaged ship.
#	crash_velocity = velocity * 0.8
#	crash_velocity.y *= 2
#
#	# Ensure a minimum downward falling speed.
#	crash_velocity.y = max(crash_velocity.y, 10.0)
#
#	velocity = Vector2.ZERO
#
#	# Pick a spin direction based on the ship's travel direction.
##	var spin_direction = sign(crash_velocity.x)
#	var spin_direction = sign(direction.x)
#	if spin_direction == 0:
#		spin_direction = 1.0
#
#	crash_rotation_speed = 0.0
#	crash_rotation_accel = rand_range(
#		CRASH_ROT_ACCEL_MIN,
#		CRASH_ROT_ACCEL_MAX
#	) * spin_direction
#
#	for n in max_smoke:
#		add_exp_fire_smoke_fx(1.0, rand_range(0, 1) * n * 2)
#
#	for n in max_smoke:
#		var explo = Globals.getExplo("wreck", get_dmg_gfx_scale())
#		explo.set_as_toplevel(true)
#		explo.offset = get_point_inside_tex()
#		explo.delay = rand_range(0.3, 1.0) * n + 3
#		$EffectNodes.add_child(explo)
#
#
#func process_movement_crash(delta):
#	# Gravity affects only the vertical axis.
#	crash_velocity.y += CRASH_GRAVITY * delta
#
#	# Frame-rate-independent damping.
##	crash_velocity *= pow(CRASH_DRAG, delta * 60.0)
#
#	global_position += crash_velocity * delta
#
#	# Gradually develop a tumble.
#	crash_rotation_speed += crash_rotation_accel * delta
#	crash_rotation_speed = clamp(
#		crash_rotation_speed,
#		-CRASH_ROT_SPEED_MAX,
#		CRASH_ROT_SPEED_MAX
#	)
#
#	# Use angular velocity in degrees per second.
#	rotation_degrees += crash_rotation_speed * delta
#
#	# Trigger impact when the ship reaches the ground.
#	if global_position.y >= Globals.HEIGHT - 30:
#		crash_impact()

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
