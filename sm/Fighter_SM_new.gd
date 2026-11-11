extends SM
class_name Fighter_SMNew

# --- Distance / behavior tuning ---------------------------------------------
export var DISENGAGE_DIST: int = 300
export var NEXT_WANDER_STEP_DIST: int = 100
export var MIN_DIST_TO_CLOSE_STATE: int = 600
export var NEW_ATTACK_RUN_MIN_DIST: int = 100
export var WITHDRAW_MOVE_TARGET_DIST: int = 900
export var DISENGAGE_MOVE_TARGET_DIST: int = 500

# Cooldown (seconds) after entering close/disengage before the reverse
# transition is allowed again. Stops the 300<->600 band from flapping.
export var STATE_SWITCH_COOLDOWN: float = 0.6

# Crash recovery: minimum dwell (s) and distance-to-target (px) at which a
# crashed fighter is considered recovered and allowed back into wander/close.
export var CRASH_MIN_DWELL: float = 0.8
export var CRASH_RECOVER_DIST: float = 220.0

# Range at which a target that just dropped out of close is forgotten.
export var TARGET_LOST_DIST_MULT: float = 2.0


var _state_time: float = 0.0          # time spent in current state
var _cooldown: float = 0.0            # time until the next switch is allowed
var _wander_step: Vector2 = Vector2.ZERO


func _ready():
	add_state("idle")
	add_state("wander")
	add_state("close")
	add_state("trail")
	add_state("disengage")
	add_state("withdraw")
	add_state("crash")


func _enter_state(_prev_state, new_state):
	# Reset per-state bookkeeping first, for every state.
	_state_time = 0.0
	_cooldown = STATE_SWITCH_COOLDOWN
	_wander_step = Vector2.ZERO

	match new_state:
		states.idle:
			pass

		states.wander:
			# Prefer hunting a known target, else drift.
			if _has_live_target():
				parent.set_new_target()
				parent.moveTarget = parent.curTarget.global_position
			else:
				parent.curTarget = null
				parent.set_wander_target()
				_wander_step = parent.moveTarget

		states.close:
			if not _has_live_target():
				parent.set_new_target()
			if _has_live_target():
				parent.moveTarget = parent.curTarget.global_position

		states.trail:
			if not _has_live_target():
				parent.set_new_target()
			if _has_live_target():
				parent.moveTarget = _trail_point()

		states.disengage:
			if _has_live_target():
				parent.moveTarget = _offset_target(DISENGAGE_MOVE_TARGET_DIST)
			else:
				parent.set_wander_target()

		states.withdraw:
			parent.moveTarget = _offset_target(WITHDRAW_MOVE_TARGET_DIST)

		states.crash:
			parent.crash_step_one()


func _state_logic(delta):
	_state_time += delta
	if _cooldown > 0.0:
		_cooldown -= delta

	# Movement is common to every moving state; idle is the only one that holds.
	match state:
		states.idle:
			pass

		states.wander:
			# Keep the wander step alive; refresh when it is reached.
			if parent.moveTarget == Vector2.ZERO:
				parent.set_wander_target()
				_wander_step = parent.moveTarget
			parent.process_movement(delta)
			if parent.global_position.distance_to(parent.moveTarget) <= NEXT_WANDER_STEP_DIST:
				parent.set_wander_target()
				_wander_step = parent.moveTarget

		states.close:
			if not _has_live_target():
				return
			parent.moveTarget = parent.curTarget.global_position
			parent.process_movement(delta)

		states.trail:
			if not _has_live_target():
				return
			parent.moveTarget = _trail_point()
			parent.process_movement(delta)

		states.disengage:
			# moveTarget was set on enter; only steer until it is reached or the
			# target closes back in (handled by _get_transition).
			if _has_live_target():
				parent.moveTarget = _offset_target(DISENGAGE_MOVE_TARGET_DIST)
			parent.process_movement(delta)

		states.withdraw:
			# moveTarget set on enter; don't chase the moving target here.
			parent.process_movement(delta)

		states.crash:
			parent.process_movement(delta)


func _get_transition(_delta):
	match state:
		states.idle:
			# Leave idle as soon as anything is worth doing.
			if _has_live_target():
				return states.close
			if _has_any_target():
				return states.wander
			return null

		states.wander:
			if _has_live_target():
				return states.close
			if _has_any_target():
				# A target exists but wasn't adopted yet.
				return states.close

		states.close:
			if not _has_live_target():
				return states.wander if _has_any_target() else states.idle

			var d = _target_distance()

			# Too far: trail it (soft) or drop it entirely.
			if d >= parent.sightRange * TARGET_LOST_DIST_MULT:
				parent.remove_cur_target_set_new_target()
				return states.wander if _has_live_target() else states.idle

			if _cooldown > 0.0:
				return null

			# Committed to a gun run: hug the target.
			if d <= DISENGAGE_DIST:
				return states.disengage

			# Long-range approach only: drop to a trail if way too far.
			if d >= parent.sightRange * 1.2:
				return states.trail

			return null

		states.trail:
			if not _has_live_target():
				return states.wander if _has_any_target() else states.idle

			var d := _target_distance()

			if d >= parent.sightRange * TARGET_LOST_DIST_MULT:
				parent.remove_cur_target_set_new_target()
				return states.wander if _has_live_target() else states.idle

			if _cooldown > 0.0:
				return null

			# Close enough to commit.
			if d <= DISENGAGE_DIST * 1.5:
				return states.close

			return null

		states.disengage:
			if not _has_live_target():
				return states.wander if _has_any_target() else states.idle

			var d = _target_distance()

			# Overshot on the pass: extend away, then come around.
			if d >= MIN_DIST_TO_CLOSE_STATE and _cooldown <= 0.0:
				return states.withdraw

			if d >= MIN_DIST_TO_CLOSE_STATE and _state_time > STATE_SWITCH_COOLDOWN * 2.0:
				return states.close

			return null

		states.withdraw:
			var d = parent.global_position.distance_to(parent.moveTarget)

			# Reached the extension point (or it's far enough): turn back in.
			if d <= NEW_ATTACK_RUN_MIN_DIST:
				return states.close if _has_live_target() else states.wander

			return null

		states.crash:
			return null
			# Leave the crash only after the minimum dwell and once the ship has
			# recovered speed toward its last heading.
			if _state_time < CRASH_MIN_DWELL:
				return null
			if parent.global_position.distance_to(parent.moveTarget) <= CRASH_RECOVER_DIST:
				return states.close if _has_live_target() else states.wander
			# Dwell exceeded but still far: stop crashing anyway to avoid a
			# permanent stuck state.
			if _state_time > CRASH_MIN_DWELL * 3.0:
				return states.wander
			return null

	return null


func _exit_state(_prev_state, _new_state):
	_wander_step = Vector2.ZERO


# --- helpers ----------------------------------------------------------------

func _has_live_target() -> bool:
	var t = parent.curTarget
	return t != null and is_instance_valid(t)


func _has_any_target() -> bool:
	return parent.targetsArr.size() > 0


func _target_distance() -> float:
	return parent.global_position.distance_to(parent.curTarget.global_position)


# A point ahead of the target along its motion, for a trailing intercept.
func _trail_point() -> Vector2:
	var t = parent.curTarget
	var ahead: Vector2 = parent.global_position
	if t != null and is_instance_valid(t):
		if "velocity" in t and t.velocity is Vector2:
			ahead = t.global_position + t.velocity * 0.4
		else:
			ahead = t.global_position
	return ahead


# A point offset from the fighter's current heading (side jink).
func _offset_target(dist: float) -> Vector2:
	var angle = Globals.rng.randi_range(15, 23) * Globals.getRandomEntry([1, -1])
	var dir = Vector2(1, 0).rotated(parent.global_rotation + deg2rad(angle))
	return parent.global_position + dir * dist
