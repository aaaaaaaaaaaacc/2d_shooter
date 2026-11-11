extends SM
class_name Fighter_Advanced_SM

# --- Behavior tuning ---------------------------------------------------------

export var ATTACK_RUN_DIST: float = 450.0
export var EVADE_TRIGGER_DIST: float = 150.0
export var BREAK_TURN_DIST: float = 350.0
export var WITHDRAW_DIST: float = 800.0

export var INTERCEPT_LEAD_TIME: float = 0.45
export var ATTACK_RUN_TIME: float = 0.8
export var EVADE_TIME: float = 0.65
export var DISENGAGE_TIME: float = 0.7
export var WITHDRAW_MAX_TIME: float = 2.5

export var STATE_SWITCH_COOLDOWN: float = 0.35
export var TARGET_LOST_DIST_MULT: float = 2.0

# --- Runtime bookkeeping -----------------------------------------------------

var _state_time: float = 0.0
var _cooldown: float = 0.0
var _evade_side: float = 1.0


func _ready():
	add_state("idle")
	add_state("wander")
	add_state("intercept")
	add_state("close")
	add_state("attack_run")
	add_state("evade")
	add_state("disengage")
	add_state("withdraw")
	add_state("crash")


func _enter_state(_prev_state, new_state):
	_state_time = 0.0
	_cooldown = STATE_SWITCH_COOLDOWN

	match new_state:
		states.idle:
			pass

		states.wander:
			if _has_live_target():
				parent.set_new_target()
			if _has_live_target():
				parent.moveTarget = parent.curTarget.global_position
			else:
				parent.curTarget = null
				parent.set_wander_target()

		states.intercept:
			if not _has_live_target():
				parent.set_new_target()
			if _has_live_target():
				parent.moveTarget = _intercept_point()

		states.close:
			if not _has_live_target():
				parent.set_new_target()
			if _has_live_target():
				parent.moveTarget = _intercept_point()

		states.attack_run:
			if _has_live_target():
				parent.moveTarget = _intercept_point(0.15)

		states.evade:
			# Pick a side for this break so the fighter doesn't flip directions
			# every frame while evading.
			_evade_side = Globals.rng.randi_range(0, 1) * 2.0 - 1.0
			if _has_live_target():
				parent.moveTarget = _evade_point()

		states.disengage:
			parent.moveTarget = _offset_target(BREAK_TURN_DIST)

		states.withdraw:
			parent.moveTarget = _offset_target(WITHDRAW_DIST)

		states.crash:
			parent.crash_step_one()


func _state_logic(delta):
	_state_time += delta
	_cooldown = max(0.0, _cooldown - delta)

	match state:
		states.idle:
			pass

		states.wander:
			if parent.moveTarget == Vector2.ZERO:
				parent.set_wander_target()
			parent.process_movement(delta)

			if parent.global_position.distance_to(parent.moveTarget) <= 100.0:
				parent.set_wander_target()

		states.intercept:
			if _has_live_target():
				parent.moveTarget = _intercept_point()
				parent.process_movement(delta)

		states.close:
			if _has_live_target():
				parent.moveTarget = _intercept_point()
				parent.process_movement(delta)

		states.attack_run:
			if _has_live_target():
				# Aim slightly ahead of the target during the committed pass.
				parent.moveTarget = _intercept_point(0.15)
				parent.process_movement(delta)

		states.evade:
			if _has_live_target():
				# Keep the break point moving with the target.
				parent.moveTarget = _evade_point()
				parent.process_movement(delta)

		states.disengage:
			parent.process_movement(delta)

		states.withdraw:
			parent.process_movement(delta)

		states.crash:
			parent.process_movement(delta)


func _get_transition(_delta):
	match state:
		states.idle:
			if _has_live_target() or _has_any_target():
				return states.intercept
			return null

		states.wander:
			if _has_live_target() or _has_any_target():
				return states.intercept

		states.intercept:
			if not _has_live_target():
				return states.wander if _has_any_target() else states.idle

			var intercept_distance = _target_distance()
			if intercept_distance >= parent.sightRange * TARGET_LOST_DIST_MULT:
				parent.remove_cur_target_set_new_target()
				return states.intercept if _has_live_target() else states.wander

			if _cooldown <= 0.0 and intercept_distance <= ATTACK_RUN_DIST:
				return states.close

		states.close:
			if not _has_live_target():
				return states.wander if _has_any_target() else states.idle

			var close_distance = _target_distance()
			if close_distance >= parent.sightRange * TARGET_LOST_DIST_MULT:
				parent.remove_cur_target_set_new_target()
				return states.intercept if _has_live_target() else states.wander

			if _cooldown <= 0.0:
				if close_distance <= EVADE_TRIGGER_DIST:
					return states.evade
				if close_distance <= ATTACK_RUN_DIST:
					return states.attack_run
				if close_distance >= parent.sightRange * 1.2:
					return states.intercept

		states.attack_run:
			if not _has_live_target():
				return states.wander if _has_any_target() else states.idle

			if _cooldown <= 0.0:
				if _target_distance() <= EVADE_TRIGGER_DIST:
					return states.evade
				if _state_time >= ATTACK_RUN_TIME:
					return states.evade

		states.evade:
			if not _has_live_target():
				return states.wander if _has_any_target() else states.idle

			if _state_time >= EVADE_TIME:
				return states.disengage

		states.disengage:
			if not _has_live_target():
				return states.wander if _has_any_target() else states.idle

			if _state_time >= DISENGAGE_TIME:
				return states.withdraw

		states.withdraw:
			if not _has_live_target():
				return states.wander if _has_any_target() else states.idle

			var distance_to_withdraw_point = parent.global_position.distance_to(parent.moveTarget)
			if distance_to_withdraw_point <= 100.0 or _state_time >= WITHDRAW_MAX_TIME:
				return states.intercept

		states.crash:
			# Keep the crashed fighter in this state; crash recovery can be
			# added here if the unit is intended to recover rather than be removed.

	return null


func _exit_state(_prev_state, _new_state):
	pass


# --- Helpers -----------------------------------------------------------------

func _has_live_target() -> bool:
	var target = parent.curTarget
	return target != null and is_instance_valid(target)


func _has_any_target() -> bool:
	return parent.targetsArr.size() > 0


func _target_distance() -> float:
	return parent.global_position.distance_to(parent.curTarget.global_position)


# Aim ahead of a moving target to make the fighter's approach less direct.
func _intercept_point(lead_time: float = -1.0) -> Vector2:
	var target = parent.curTarget
	if target == null or not is_instance_valid(target):
		return parent.global_position

	var prediction_time = INTERCEPT_LEAD_TIME
	if lead_time >= 0.0:
		prediction_time = lead_time

	var target_velocity = Vector2.ZERO
	if "velocity" in target and target.velocity is Vector2:
		target_velocity = target.velocity

	return target.global_position + target_velocity * prediction_time


# Make a lateral break around the target, rather than simply turning away.
func _evade_point() -> Vector2:
	var target = parent.curTarget
	if target == null or not is_instance_valid(target):
		return _offset_target(BREAK_TURN_DIST)

	var away_from_target = parent.global_position - target.global_position
	if away_from_target.length_squared() < 1.0:
		away_from_target = Vector2.RIGHT.rotated(parent.global_rotation)

	var lateral_direction = away_from_target.normalized().rotated(
		_evade_side * PI / 2.0
	)

	return target.global_position + lateral_direction * BREAK_TURN_DIST


# Set a point ahead of the fighter with a small sideways jink.
func _offset_target(distance: float) -> Vector2:
	var angle_degrees = Globals.rng.randi_range(15, 25) * _random_side()
	var direction = Vector2.RIGHT.rotated(
		parent.global_rotation + deg2rad(angle_degrees)
	)
	return parent.global_position + direction * distance


func _random_side() -> float:
	return 1.0 if Globals.rng.randi_range(0, 1) == 0 else -1.0
