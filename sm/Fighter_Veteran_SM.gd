extends Fighter_SM
class_name VeteranFighter_SM

# --- Veteran tuning ---------------------------------------------------------
export var GUN_RANGE: float = 260.0           # within this the veteran will fire
export var BREAK_TRIGGER_DIST: float = 180.0  # player this close on our six = break
export var BREAK_DIST: float = 420.0          # how far the break jink goes
export var ZOOM_DIST: float = 1000.0          # extension length after a pass
export var RECOVER_MIN_DWELL: float = 0.5
export var REACTION_TIME: float = 0.12        # perceived "human" delay before reacting
export var AGGRESSION: float = 0.85           # 0..1, scales engage distances
export var MAX_CRASH_CHAIN: int = 2

var _aim_point: Vector2 = Vector2.ZERO
var _last_state: int = -1
var _crash_chain: int = 0
var _reaction_clock: float = 0.0
var _pending_transition: int = -1


func _ready():
	# Fighters already add idle/wander/close/trail/disengage/withdraw/crash.
	add_state("plus")
	add_state("break")
	add_state("zoom")
	add_state("recover")


func _enter_state(_prev, new_state):
	# Let the base set moveTarget for the shared states it knows about.
	if new_state in [states.idle, states.wander, states.close, states.trail,
			states.disengage, states.withdraw, states.crash]:
		_enter_state(_prev, new_state)
	else:
		_state_time = 0.0
		_cooldown = STATE_SWITCH_COOLDOWN
		_wander_step = Vector2.ZERO

	_last_state = new_state
	_reaction_clock = REACTION_TIME
	_pending_transition = -1

	match new_state:
		states.plus:
			# Head-on aggression: drive straight down the lead line, budgeted.
			parent.moveTarget = get_aim_point()
		states.break:
			# Hard jink away from the threat as it passes behind us.
			parent.moveTarget = parent.global_position + _break_vector() * BREAK_DIST
		states.zoom:
			# Extend straight past the target and out of its gun envelope.
			var away = parent.global_position - _aim_point
			if away.length() < 1.0:
				away = Vector2.RIGHT.rotated(parent.global_rotation)
			parent.moveTarget = parent.global_position + away.normalized() * ZOOM_DIST * AGGRESSION
		states.recover:
			# Small controlled re-orientation after a crash.
			parent.moveTarget = parent.global_position + Vector2.RIGHT.rotated(parent.global_rotation) * 300.0


func _state_logic(delta):
	_state_time += delta
	if _cooldown > 0.0:
		_cooldown -= delta

	# Reaction gate: hold the pending transition for REACTION_TIME so the
	# veteran is readable and not frame-perfect.
	if _pending_transition != -1:
		_reaction_clock -= delta
		if _reaction_clock <= 0.0:
			set_state(_pending_transition)
			return

	match state:
		states.idle:
			pass

		states.wander:
			_state_logic(delta)

		states.close:
			if not _has_live_target():
				return
			# Lead pursuit instead of mirroring the target's position.
			parent.moveTarget = get_aim_point()
			parent.process_movement(delta)

		states.trail:
			# Maintain a loose trail while waiting for a clean line.
			if not _has_live_target():
				return
			parent.moveTarget = _trail_point()
			parent.process_movement(delta)

		states.plus:
			if not _has_live_target():
				return
			parent.moveTarget = get_aim_point()
			parent.process_movement(delta)

		states.break:
			parent.process_movement(delta)

		states.zoom:
			parent.process_movement(delta)

		states.recover:
			parent.process_movement(delta)

		states.disengage:
			if _has_live_target():
				parent.moveTarget = _offset_target(DISENGAGE_MOVE_TARGET_DIST)
			parent.process_movement(delta)

		states.withdraw:
			parent.process_movement(delta)

		states.crash:
			parent.process_movement(delta)


func _get_transition(_delta):
	var next := _intermediate_transition()
	if next == -1:
		# Fall back to the base rules for anything the veteran logic didn't claim.
		next = _get_transition(_delta)

	# Debounce/reaction gate: anything other than "nothing" is queued, except
	# crash, which is immediate (you don't react to a crash, you're in one).
	if next != null and next != -1 and next != state and next != states.crash:
		if _pending_transition == -1:
			_pending_transition = next
			_reaction_clock = REACTION_TIME
			return null
		return null
	return next


# Veteran-only transition overlay. Returns -1 (not claimed) to defer to base.
func _intermediate_transition() -> int:
	match state:
		states.close:
			if not _has_live_target():
				return -1
			var d := _target_distance()
			# In a gun run and the player is very close on our tail: break.
			if d <= BREAK_TRIGGER_DIST and _threat_on_six():
				return states.break
			return -1

		states.plus:
			if not _has_live_target():
				return states.wander
			if _target_distance() <= GUN_RANGE:
				parent.on_shot_resolved()      # fire hook
				return states.zoom
			if _cooldown <= 0.0 and _target_distance() > parent.sightRange * 1.6 / AGGRESSION:
				return states.trail
			return -1

		states.break:
			# Break done once we've turned past the threat or timed out.
			if _state_time > max(0.45, BREAK_DIST / 420.0):
				return states.close if _has_live_target() else states.zoom
			return -1

		states.zoom:
			if _has_live_target() and _state_time > 0.6 and _target_distance() > parent.sightRange:
				return states.trail
			if _has_live_target() and _energy_ok() and _state_time > 0.3:
				return states.plus
			return -1

		states.recover:
			if _state_time > RECOVER_MIN_DWELL and _has_live_target():
				return states.close if _target_distance() < parent.sightRange else states.wander
			return -1

		states.crash:
			if _state_time < CRASH_MIN_DWELL:
				return -1
			if _state_time < CRASH_MIN_DWELL * 3.0:
				return states.recover
			_crash_chain = 0
			return states.close if _has_live_target() else states.wander

	return -1


func _exit_state(prev, new_state):
	_exit_state(prev, new_state)
	if prev == states.crash and new_state != states.recover:
		_crash_chain += 1
		if _crash_chain > MAX_CRASH_CHAIN:
			_crash_chain = 0


# --- Veteran helpers --------------------------------------------------------

# Lead the target: aim where it will be after the shot's flight time.
func get_aim_point() -> Vector2:
	if not _has_live_target():
		return parent.global_position + Vector2.RIGHT.rotated(parent.global_rotation) * 200.0
	var t = parent.curTarget
	var tpos: Vector2 = t.global_position
	if "velocity" in t and t.velocity is Vector2:
		var travel: Vector2 = parent.global_position.distance_to(tpos)
		var flight := tpos.distance_to(parent.global_position) / max(1.0, parent.velocity.length())
		_aim_point = tpos + t.velocity * flight * AGGRESSION
	else:
		_aim_point = tpos
	return _aim_point


# Threat is behind us and closing relative to our nose.
func _threat_on_six() -> bool:
	var to_target: Vector2 = (parent.curTarget.global_position - parent.global_position).normalized()
	var nose: Vector2 = Vector2.RIGHT.rotated(parent.global_rotation)
	var behind := nose.dot(to_target) < -0.25
	var closing := true
	if "velocity" in parent.curTarget and parent.curTarget.velocity is Vector2:
		closing = parent.curTarget.velocity.dot(-to_target) > 0.0
	return behind and closing


# Sidestep vector: perpendicular to the threat line, biased to the richer side.
func _break_vector() -> Vector2:
	var to_target: Vector2 = (parent.global_position - parent.curTarget.global_position).normalized()
	var perp := to_target.rotated(PI * 0.5)
	# Prefer the side with more room to the arena edge.
	var half := Globals.WIDTH * 0.5
	if parent.global_position.x < half:
		if perp.x < 0.0:
			perp = -perp
	elif perp.x > 0.0:
		perp = -perp
	return perp.normalized()


# Cheap energy proxy: turning hard at full speed costs reachable speed.
func _energy_ok() -> bool:
	return parent.velocity.length() >= parent.maxSpeed * 0.55
