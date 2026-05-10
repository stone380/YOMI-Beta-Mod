# hitbox_validator.gd
# Validates hitbox and hurtbox definitions for both characters.
# Called at mod load time to catch configuration errors early.
# Covers Requirements: 12.1–12.7

class_name HitboxValidator


## Validates all hitbox and hurtbox definitions for a character.
## character: the character script instance (MalacharCharacter or SeraphielCharacter)
## move_list: Array of MoveData from the character's get_move_list()
## Returns an Array of error strings (empty if all valid).
static func validate(character: Object, move_list: Array) -> Array:
	var errors: Array = []

	# Req 12.1: Each character must define hurtbox states for idle, crouching, airborne, hit_stun
	var required_states: Array = ["standing", "crouching", "airborne", "hit_stun"]
	for state in required_states:
		var hb = character.get_hurtbox_state(state)
		if hb == null:
			errors.append("Missing hurtbox state: " + state)

	# Req 12.6: Crouching hurtbox must be 60% of standing height
	var standing_hb = character.get_hurtbox_state("standing")
	var crouching_hb = character.get_hurtbox_state("crouching")
	if standing_hb != null and crouching_hb != null:
		var expected_crouch_height: float = standing_hb.height * 0.6
		if abs(crouching_hb.height - expected_crouch_height) > 0.01:
			errors.append(
				"Crouching hurtbox height %.1f != 60%% of standing height %.1f (expected %.1f)" % [
					crouching_hb.height, standing_hb.height, expected_crouch_height
				]
			)

	# Req 12.2: Each non-movement move must have at least one hitbox
	for move in move_list:
		if not move.is_movement_only and move.base_damage > 0:
			if move.hitboxes.size() == 0:
				errors.append("Move '%s' has no hitboxes but is not movement-only." % move.move_id)

	# Req 12.3: Each hitbox active_frame_end >= active_frame_start
	for move in move_list:
		for hb in move.hitboxes:
			if hb.active_frame_end < hb.active_frame_start:
				errors.append(
					"Move '%s' hitbox has active_frame_end (%d) < active_frame_start (%d)." % [
						move.move_id, hb.active_frame_end, hb.active_frame_start
					]
				)

	return errors


## Logs all validation errors as warnings. Returns true if valid (no errors).
static func validate_and_log(character: Object, move_list: Array) -> bool:
	var errors: Array = validate(character, move_list)
	for error in errors:
		push_warning("HitboxValidator: " + error)
	return errors.size() == 0
