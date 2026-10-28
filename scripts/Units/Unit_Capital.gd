extends Air_Unit
class_name Capital

const CRASH_MAX_TILT_DEGREES := 6.0

const CRASH_GRAVITY := 20.0
const CRASH_DRAG := 0.995
const CRASH_ROT_ACCEL_MIN := 0.3
const CRASH_ROT_ACCEL_MAX := 0.5
const CRASH_ROT_SPEED_MAX := 10.0

const CRASH_HORIZONTAL_SPEED_SCALE := 0.8
const CRASH_VERTICAL_SPEED_SCALE := 0.5
const CRASH_MIN_FALL_SPEED := 10.0
const CRASH_GROUND_MARGIN := 30.0

func _ready():
	for n in $ThrusterNodes.get_children():
		n.hide()
	canWarp = true
	
func _physics_process(_delta):
	pass
	
func process_movement(_delta):
#	if $SM.state == $SM.states.crash:
#		return
		
	set_interest()
	set_danger()
	choose_direction()
	accel = chosen_dir.rotated(rotation) * maxSpeed
	accel = accel.limit_length(maxSpeed)
	velocity += accel * _delta
	velocity = velocity.limit_length(maxSpeed)

func getSpawnY(viewFrom, viewTo):
	var minY = Globals.HEIGHT / 2
	var add = Globals.HEIGHT / 4
	var y =  Globals.rng.randi_range(minY-add, minY)
	return y
	
func crash_step_one():
	$TimerNodes/CrashTimer.wait_time = 3.0
	$TimerNodes/CrashTimer.one_shot = true
	$TimerNodes/CrashTimer.connect("timeout", self, "crash_step_two")
	$TimerNodes/CrashTimer.start()
	
	for n in 1:
		add_exp_fire_smoke_fx(1.25, 0.3)
		
#	for n in $Mounts.get_children():
#		n.kill()
		
func get_crash_spin_direction():
	if $Sprites/Main.flip_h == false:
		return 1
	return -1

func crash_step_two():
	if crashing:
		return

	danger.fill(0.0)
	crashing = true

	# Use the velocity before clearing it to choose the spin direction.
	crash_velocity = velocity * CRASH_HORIZONTAL_SPEED_SCALE
	crash_velocity.y *= CRASH_VERTICAL_SPEED_SCALE

	# In screen coordinates, positive Y is downward.
	crash_velocity.y = max(crash_velocity.y, CRASH_MIN_FALL_SPEED)
	velocity = Vector2.ZERO

#	var spin_direction = sign(direction.x)
	var spin_direction = get_crash_spin_direction()
	if spin_direction == 0:
		spin_direction = -1.0 if randf() < 0.5 else 1.0
	crash_start_rotation_degrees = rotation_degrees
	crash_tilt_degrees = 0.0
	crash_rotation_direction = spin_direction
	
	print("spin dir: ", spin_direction)
	print("crash rot dir: ", crash_rotation_direction)

	crash_rotation_speed = 0.0
	crash_rotation_accel = rand_range(CRASH_ROT_ACCEL_MIN, CRASH_ROT_ACCEL_MAX) * spin_direction

	for i in range(max_smoke):
		add_exp_fire_smoke_fx(1.0, rand_range(0.0, 1.0) * i * 2.0)

	for i in range(max_smoke):
		var explo = Globals.getExplo("wreck", get_dmg_gfx_scale())
		explo.set_as_toplevel(true)
		explo.offset = get_point_inside_tex()
		explo.delay = rand_range(0.3, 1.0) * i + 3.0
		$EffectNodes.add_child(explo)


func process_movement_crash(delta):
	crash_velocity.y += CRASH_GRAVITY * delta

	# 0.995 velocity retention per 1/60 second, scaled for delta.
#	var damping = pow(CRASH_DRAG, delta * 60.0)
#	crash_velocity *= damping

	global_position += crash_velocity * delta

	crash_rotation_speed += crash_rotation_accel * delta
	crash_rotation_speed = clamp(crash_rotation_speed, -CRASH_ROT_SPEED_MAX, CRASH_ROT_SPEED_MAX)
	
	var next_tilt = crash_tilt_degrees + crash_rotation_speed * delta

	if crash_rotation_direction > 0.0:
		crash_tilt_degrees = min(next_tilt, CRASH_MAX_TILT_DEGREES)
	else:
		crash_tilt_degrees = max(next_tilt, -CRASH_MAX_TILT_DEGREES)

	rotation_degrees = crash_start_rotation_degrees + crash_tilt_degrees

	# Stop the spin once the tilt limit is reached.
	if abs(crash_tilt_degrees) >= CRASH_MAX_TILT_DEGREES:
		crash_rotation_speed = 0.0
		crash_rotation_accel = 0.0

	var ground_y = Globals.HEIGHT - CRASH_GROUND_MARGIN
	if global_position.y >= ground_y:
		global_position.y = ground_y
		crash_impact()

func crash_impact():
	crashing = false

	global_position.y = Globals.HEIGHT - 30

	crash_rotation_speed = 0
	crash_velocity = Vector2.ZERO

	
func kill_by_crash():
	indestructable = true
	.kill_by_crash()

func get_crash_velo():
	return maxSpeed / 2
	
func disable_boosting():
	return

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
	
func set_wander_target():
	var pos = global_position
	var rot = rotation_degrees
	var newTarget = Vector2.ZERO
	var limit = look_ahead + 1
	
	if direction.x == 1:
		newTarget = pos + Vector2(300, 70 * Globals.getRandomEntry([1, -1]))
		if newTarget.x > Globals.WIDTH - limit:
			newTarget.x -= 600
	else:
		newTarget = pos + Vector2(-300, 70 * Globals.getRandomEntry([1, -1]))
		if newTarget.x < 0 + limit:
			newTarget.x += 600
#
	if newTarget.y > Globals.HEIGHT:
		newTarget.y -= Globals.HEIGHT
	elif newTarget.y < 0:
		newTarget.y += Globals.HEIGHT
		
	moveTarget = newTarget

func can_warp_in():
	return true
	
func withdraw_condition(remDmg):
	if $SM.state != $SM.states.prepareWarpOut:
		var rand = rand_range(0, 1)
		if (health < float(maxHealth * stats.flee_tresh) and rand < remDmg / float(health)):
			print("flee_tresh: ", stats.flee_tresh)
			print("hit for: ", remDmg, ", health remaining: ", health ,"/", maxHealth)
			print("rand 0-1: ", str(rand), " < than: ", (remDmg / float(health)))
			print("flee triggered")
			return true
	return false
	
