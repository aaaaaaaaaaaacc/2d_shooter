extends Strikecraft_Unit
class_name Fighter

 # Minimum speed during a crash
const CRASH_MIN_SPEED := 180.0

# Minimum horizontal speed
const CRASH_MIN_HORIZONTAL_SPEED := 120.0

# -- crashing
const CRASH_GRAVITY := 40.0          # Downward acceleration (increase for heavier feel)
const CRASH_X_DRAG := 1.002          # Horizontal air resistance
const CONTROL_LOSS_TIME := 2.5

# Pitch behavior
const CRASH_ROT_ACCEL_MIN := 5.0
const CRASH_ROT_ACCEL_MAX := 12.0
const CRASH_ROT_SPEED_MAX := 35.0
const CRASH_NOSE_DIVE_ANGLE := 25.0

# Initial instability
const WOBBLE_SPEED := 5.0
const WOBBLE_STRENGTH := 2.5

# Preserve most of the original momentum
const CRASH_VELOCITY_PRESERVE := 0.99

# Gradual downward instability
const CRASH_DOWNWARD_IMPULSE := 15.0

var crash_elapsed := 0.0
var spin_direction := 1.0
var initial_crash_rot := 0.0
var target_nose_angle:int = 0

# ── Flight model ─────────────────────────────────────────────────────────────
const MOVE_AGILITY: float = 0.5              # turn authority
const MOVE_TURN_RATE_BASE_DEG: float = 200.0  # heading change, deg/s, at agility 20
const MOVE_SPEED_RELAX: float = 1.5           # 1/s convergence of airspeed to target
const MOVE_MIN_SPEED_FRAC: float = 0.55       # speed floor at a full 180° reversal

var _airspeed: float = 0.0                    # scalar speed actually being carried

var display = "Fighter Adv"
	
func do_specific_unit_init():
	if position.x < Globals.WIDTH / 2:
		rotation_degrees += Globals.rng.randi_range(-4, 4)
	else:
		rotation_degrees += 180 + Globals.rng.randi_range(-4, 4)
	
	velocity = (moveTarget - global_position).normalized() * maxSpeed/2
	accel = velocity
	rotation = velocity.angle()
	
func _ready():
	pass

func _physics_process(_delta):
#	print("# ", self.id, ", rota: ", rotation_degrees)
	#print(rotation_degrees)
	pass
		
func process_movement(delta: float) -> void:
	if maxSpeed <= 0.0:
		return
		
	handle_steering_intentions(delta)

	# 2. Thrust as a world-space unit vector. chosen_dir is accumulated in LOCAL
	#    ray space, so exactly one rotation is applied - here, once.
	var thrust_dir: Vector2 = _thrust_dir_world()

	# 3. Heading being travelled, with a fallback for a standing start.
	var heading: Vector2 = thrust_dir
	if velocity.length_squared() > MOVE_DIR_EPS:
		heading = velocity.normalized()

	# 4. Airspeed is its own state, so a turn can bleed it and it recovers
	#    gradually instead of snapping back to maxSpeed on the next frame.
	if _airspeed <= 0.0:
		_airspeed = max(velocity.length(), maxSpeed * 0.5)

	# 5. Rate-limited turn toward the thrust direction (inertia, no snapping).
	var turn_rate: float = deg2rad(MOVE_TURN_RATE_BASE_DEG) * MOVE_AGILITY
	var ang_err: float = heading.angle_to(thrust_dir)
	var max_step: float = turn_rate * delta
	
	var turn_strength := 4.0
	var turn_step := clamp(
		ang_err * turn_strength * delta,
		-max_step,
		max_step
	)
	heading = heading.rotated(turn_step)


#	heading = heading.rotated(clamp(ang_err, -max_step, max_step))

	# 6. Turn bleed: straight -> full speed, 180° -> MOVE_MIN_SPEED_FRAC.
	#    Actual rate of change is limited by enginePower, so heavy ships take
	#    longer to recover the speed a hard turn cost them.
	var severity: float = clamp(abs(ang_err) / PI, 0.0, 1.0)
	var target_speed: float = maxSpeed * lerp(1.0, MOVE_MIN_SPEED_FRAC, severity)
	var rate: float = MOVE_SPEED_RELAX * (enginePower if enginePower > 0.0 else maxSpeed)
	_airspeed = _approach(_airspeed, target_speed, rate * delta)

	velocity = heading * _airspeed
	accel = thrust_dir * enginePower
	rotation = velocity.angle()	


func _thrust_dir_world() -> Vector2:
	var local: Vector2 = chosen_dir
	if local.length_squared() > MOVE_DIR_EPS:
		return local.rotated(rotation).normalized()

	# Symmetric cancellation (target dead astern is the classic case) or no
	# interest at all: steer straight at the target rather than coasting.
	if moveTarget != Vector2.ZERO:
		var to_target: Vector2 = moveTarget - global_position
		if to_target.length_squared() > MOVE_DIR_EPS:
			return to_target.normalized()
	if velocity.length_squared() > MOVE_DIR_EPS:
		return velocity.normalized()
	return Vector2.RIGHT.rotated(rotation)

func _approach(cur: float, target: float, step: float) -> float:
	if cur < target:
		return min(cur + step, target)
	return max(cur - step, target)

func shortest_angle_dist(from: float, to: float) -> float:
	var twoPi = TAU
	var delta = fmod(to - from, twoPi)
	if delta > PI:
		delta -= twoPi
	elif delta < -PI:
		delta += twoPi
	return delta
	
func bound_process(_delta):
	
	if $VisibilityNotifier2D.is_on_screen():
		print("bound_process #", self.id, ", on screen")
	else:
		print("bound_process #", self.id, ", NOT on screen")
		set_inactive()
		$Debug.show()
		showDebug()
		mark_debug_menu_entry_as_out_of_bounds()
		return
		
	if position.y >= Globals.HEIGHT -5 or position.y <= Globals.ROADY -5:
		position.x = clamp(position.x, 5, Globals.WIDTH -5)
		position.y = clamp(position.y, 5, Globals.ROADY -5)
			
		var ram = Globals.curScene.get_node("Various/Boundary").getRamDamage()
		ram.minDmg *= 3
		ram.maxDmg *= 3
		ram.global_position = global_position + Vector2(0, 10)
		ram.velocity = Vector2(0, -10)

		take_damage(ram, ram.minDmg)
		ram.postImpacting()
	
func getSelfSpawnPosition(viewFrom, viewTo):
	var x:int = 0
	var	y:int = Globals.rng.randi_range(look_ahead, Globals.HEIGHT - look_ahead)
	
	if viewFrom == Vector2.ZERO and viewTo == Vector2.ZERO:
		x = Globals.WIDTH / 2 + (Globals.getRandomEntry([1, -1]) * Globals.rng.randi_range(200, Globals.WIDTH * 0.3))
	else:
		var legal = false
		while not legal:
			x = Globals.WIDTH / 2 + (Globals.getRandomEntry([1, -1]) * Globals.rng.randi_range(200, Globals.WIDTH * 0.3))
			if is_outside_viewport(x, y):
				legal = true
			
			
#
#		var xRng = Globals.rng.randi_range(100, 600)
#		var dir = Globals.getRandomEntry([-1, 1])
#		if dir == -1:
#			x = viewFrom.x - xRng
#		else: x = viewTo.x + xRng
#		x = clamp(x, 300, Globals.WIDTH-300)
	return Vector2(x, y)
	
func is_outside_viewport(x, y):
	var cam = Globals.curScene.get_node("CamA")
	var SCREEN = Globals.SCREEN
	var from = Vector2(cam.position - (SCREEN/2))
	var to = Vector2(from + SCREEN)
	
	if x > from.x and x < to.x and y > from.y and y < from.y:
		return false
	return true
	
func enable_boosting():
	return false
		
func setUnitFacing():
	if velocity.x < 0 and sprite.flip_v == false:
		sprite.flip_v = true
		mirrorTurrets()
		mirrorThrusters()
	elif velocity.x > 0 and sprite.flip_v == true:
		sprite.flip_v = false
		mirrorTurrets()
		mirrorThrusters()
		
func mirrorThrusters():
	for n in $ThrusterNodes.get_children():
		n.position.y *= -1
		
func mirrorTurrets():
	$Mounts.scale.y *= -1
	return
	for n in $Mounts.get_children():
		n.position.x *= -1
#		if not n.has_node("Weapon"): return
		var weapon = n.get_node("Weapon")
		weapon.arc_midpoint_v.x *= -1
		weapon.current_rot_v.x *= -1
		weapon.rotation = weapon.current_rot_v.angle()

func getPossibleWeapons(index):
#	return false
#	var weapon = Globals.getWeaponBase("Light Missile");
	var weapon:Weapon_Base
	match index:
		0:
#			return null
			weapon = Globals.getWeaponBase("Light Machinecannon");
			weapon.fof = 9
#			weapon.rof = 1
		1:
			weapon = Globals.getWeaponBase("Light Missile");
			weapon.fof = 12
			weapon.steerForce *= 1.5
	weapon.makeInvisible()
	return weapon
	
func initAvoidValues():
	avoidValues = {"Player": 1.0, "Fighter": 1.0, "Helicopter_Light": 1.0, "Boundary": 5.0, "Obstacle": 5.0, "Cargohauler": 3.5, "City": 3.5}
	
func crash_step_one():
#	$Tween.interpolate_property(self, "maxSpeed", maxSpeed, get_crash_velo(), 3.0)
#	$Tween.start()
#	Tween.connect("tween_all_completed", self, "crash_step_two")
	
	for n in 1:
		add_exp_fire_smoke_fx(1.25, 0.3)
		
	crash_step_two()
	
func crash_step_two():
	danger.fill(0.0)
	crashing = true
	crash_elapsed = 0.0

	initial_crash_rot = rotation_degrees
	# Preserve existing momentum
	crash_velocity = velocity * CRASH_VELOCITY_PRESERVE

	# Determine the jet's forward direction
	var forward_dir = Vector2.RIGHT.rotated(rotation)

	if scale.x < 0.0:
		forward_dir = -forward_dir

	# Ensure a minimum amount of forward momentum
	if crash_velocity.length() < CRASH_MIN_SPEED:
		var missing_speed = CRASH_MIN_SPEED - crash_velocity.length()
		crash_velocity += forward_dir * missing_speed

	# Ensure sufficient horizontal movement
	if abs(crash_velocity.x) < CRASH_MIN_HORIZONTAL_SPEED:
		var horizontal_sign = sign(forward_dir.x)

		if horizontal_sign == 0:
			horizontal_sign = 1.0

		crash_velocity.x = horizontal_sign * CRASH_MIN_HORIZONTAL_SPEED

	# Start the uncontrolled descent
	crash_velocity.y += CRASH_DOWNWARD_IMPULSE

	velocity = Vector2.ZERO

	# Determine which direction the jet is traveling
	spin_direction = sign(crash_velocity.x)
		
#	if spin_direction == 0:
#		spin_direction = 1.0 if scale.x >= 0.0 else -1.0
		
	target_nose_angle = CRASH_NOSE_DIVE_ANGLE * spin_direction

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

	# 0 = just lost control, 1 = completely uncontrolled
	var control_loss = clamp(
		crash_elapsed / CONTROL_LOSS_TIME,
		0.0,
		1.0
	)

	# Smooth progression into the uncontrolled descent
	var dive_factor = control_loss * control_loss

	# --------------------------------------------------
	# 1. VERTICAL MOVEMENT
	# --------------------------------------------------

	# Gravity gradually takes over.
	# The jet initially maintains its flight path.
	var current_gravity = CRASH_GRAVITY * lerp(
		0.25,
		1.0,
		dive_factor
	)

	crash_velocity.y += current_gravity * delta

	# --------------------------------------------------
	# 2. HORIZONTAL MOVEMENT
	# --------------------------------------------------

	# Very little drag: the jet retains its forward momentum.
	crash_velocity.x *= pow(
		CRASH_X_DRAG,
		delta * 60.0
	)

	# --------------------------------------------------
	# 3. ROTATION / LOSS OF CONTROL
	# --------------------------------------------------

	# Gradually increase the uncontrolled pitch movement
	crash_rotation_speed += (
		crash_rotation_accel * dive_factor * delta
	)

	crash_rotation_speed = min(
		crash_rotation_speed,
		CRASH_ROT_SPEED_MAX
	)

	# Gradually pitch the nose downward.
#	# Do not force the jet into a steep vertical dive.
#	var target_nose_angle = CRASH_NOSE_DIVE_ANGLE * spin_direction

#	print(target_nose_angle)
	initial_crash_rot = move_toward(
		initial_crash_rot,
		target_nose_angle,
		crash_rotation_speed * delta
	)

	# Small uncontrolled shaking
	var wobble = (
		sin(crash_elapsed * WOBBLE_SPEED)
		* WOBBLE_STRENGTH
		* (1.0 - dive_factor * 0.5)
	)

	rotation_degrees = initial_crash_rot + wobble

	# --------------------------------------------------
	# 4. APPLY MOVEMENT
	# --------------------------------------------------

	global_position += crash_velocity * delta

#	print(crash_velocity.x)
	# --------------------------------------------------
	# 5. GROUND COLLISION
	# --------------------------------------------------

	if global_position.y >= Globals.HEIGHT - 30:
		crash_impact()

func _on_crash_explo_timer_timeout():
	kill()

func crash_impact():
	print("crash_impact")
	crashing = false
	global_position.y = Globals.HEIGHT - 30
	crash_rotation_speed = 0
	crash_velocity = Vector2.ZERO

func kill_by_crash():
	print("kill_by_crash")
	if $SM.state == $SM.states.crash:
		kill()
		$ThrusterNodes/Aft/Particle2D.emitting = false
		if rotation_degrees > 55 and rotation_degrees < 125:
			hide()
	else:
		if global_position.x < 50 or global_position.x > Globals.WIDTH - 50:
#			global_rotation_degrees += 180
			velocity *= -1
			accel *= -1

func setMixUpWanderTarget():
	print("setMixUpWanderTarget #", self.id)
	if velocity.x > 0:
		moveTarget.x = global_position.x - look_ahead*2
	elif velocity.x < 0:
		moveTarget.x = global_position.x + look_ahead*2
		
	checkMoveTargetWithinBoundary()

func set_wander_target():
	if  Globals.rng.randf_range(0, 1) < 0.08:
		return setMixUpWanderTarget()
		
	var pos = global_position
	var rot = rotation_degrees
	var newTarget = Vector2.ZERO
	var limit = look_ahead
	
	if rotation_degrees > -90 and rotation_degrees < 90:
		newTarget = pos + Vector2(look_ahead, Globals.getRandomEntry([1, -1]) * 15)
	else:
		newTarget = pos + Vector2(-look_ahead, Globals.getRandomEntry([1, -1]) * 15)
		
	if newTarget.x > Globals.WIDTH - limit:
		newTarget.x -= limit *4
	elif newTarget.x < 0 + limit:
		newTarget.x += limit *4
	
#	if newTarget.y > Globals.HEIGHT:
#		newTarget.y -= Globals.HEIGHT
#	elif newTarget.y < 0:
#		newTarget.y += Globals.HEIGHT
	
	moveTarget = newTarget
	
func checkMoveTargetWithinBoundary():
	if $SM.state != $SM.states.crash:
		moveTarget.x = clamp(moveTarget.x, look_ahead, Globals.WIDTH - look_ahead)
		moveTarget.y = clamp(moveTarget.y, look_ahead, Globals.HEIGHT - look_ahead)
	pass

func add_exp_fire_smoke_fx(scale:float, delay:float):
#	add_exp_fire_smoke_fx(scale, delay)
	var pos = get_point_inside_tex()
	var explo = Globals.getExplo("radial", scale, delay)
	explo.position = pos
	$EffectNodes.add_child(explo)
	var node = Globals.getFireSmokeNode(scale, delay + 0.2)
	node.position = pos
	$EffectNodes.add_child(node)

func get_dmg_gfx_scale():
	return 1
	
func crash_condition(remDmg):
	if $SM.state != $SM.states.crash:
		return true
	return false
	
func withdraw_condition(remDmg):
	if $SM.state != $SM.states.withdraw:
		var rand =  Globals.rng.randf_range(0, 1)
		if (health < float(maxHealth * stats.flee_tresh) and rand < remDmg / float(health)):
			print("flee_tresh: ", stats.flee_tresh)
			print("hit for: ", remDmg, ", health remaining: ", health ,"/", maxHealth)
			print("rand 0-1: ", str(rand), " < than: ", (remDmg / float(health)))
			print("flee triggered")
			return true
	return false
func process_movement_drift(delta: float) -> void:
	if maxSpeed <= 0.0:
		return

	# 1. AI steering
	# Ideally these calculations happen in your throttled steering update,
	# rather than every physics frame.
	set_interest()
	set_danger()
	choose_direction()

	# 2. Desired direction of acceleration
	var thrust_dir: Vector2 = _thrust_dir_world()

	# 3. Rotate the aircraft nose towards the desired direction.
	var nose_dir: Vector2 = Vector2.RIGHT.rotated(rotation)

	var ang_err: float = nose_dir.angle_to(thrust_dir)

	var turn_rate: float = deg2rad(MOVE_TURN_RATE_BASE_DEG) \
		* (MOVE_AGILITY / 20.0)

	var max_turn: float = turn_rate * delta

	rotation += clamp(ang_err, -max_turn, max_turn)

	# Recalculate nose direction after rotation.
	nose_dir = Vector2.RIGHT.rotated(rotation)

	# 4. Initialize airspeed if necessary.
	if _airspeed <= 0.0:
		_airspeed = max(velocity.length(), maxSpeed * 0.5)

	# 5. Calculate maneuvering intensity.
	# The difference between nose direction and velocity determines
	# how aggressively the aircraft is maneuvering.
	var speed: float = velocity.length()

	var turn_severity: float = 0.0

	if speed > MOVE_DIR_EPS:
		var velocity_dir: Vector2 = velocity.normalized()
		var alignment: float = clamp(
			nose_dir.dot(velocity_dir),
			-1.0,
			1.0
		)

		turn_severity = abs(acos(alignment)) / PI

	# 6. Turn bleed.
	var target_speed: float = maxSpeed * lerp(
		1.0,
		MOVE_MIN_SPEED_FRAC,
		turn_severity
	)

	var recovery_rate: float = MOVE_SPEED_RELAX * max(enginePower, 0.0)

	_airspeed = _approach(
		_airspeed,
		target_speed,
		recovery_rate * delta
	)

	# 7. Engine thrust.
	# Acceleration follows the aircraft nose, not its velocity.
	accel = nose_dir * enginePower

	velocity += accel * delta

	# 8. Simple drag.
	velocity -= velocity * 0.1 * delta

	# 9. Enforce maximum airspeed.
	# This is an arcade flight envelope rather than a physical speed limit.
	if velocity.length() > maxSpeed:
		velocity = velocity.normalized() * maxSpeed

	# 10. Keep actual airspeed synchronized with velocity.
	_airspeed = velocity.length()
