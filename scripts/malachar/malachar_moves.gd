# malachar_moves.gd
# Defines all 11 MoveData instances for Malachar the Undying.
# Covers Requirements 4.1–4.12, 12.2, 12.3, 12.4

# Preload shared classes so this file can be used standalone or via autoload.
const MoveDataClass = preload("res://scripts/shared/move_data.gd")
const HitboxDataClass = preload("res://scripts/shared/hitbox_data.gd")

class_name MalacharMoves


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns the complete move list for Malachar as an Array of MoveData.
static func get_move_list() -> Array:
	return [
		_make_claw_swipe(),
		_make_lunge_bite(),
		_make_shadow_step(),
		_make_sweeping_talon(),
		_make_bat_swarm(),
		_make_hypnotic_gaze(),
		_make_crimson_mist(),
		_make_bat_form_dash(),
		_make_blood_nova(),
		_make_eternal_drain(),
		_make_lord_of_bats(),
	]


## Validates the move list against animation_data.
## Warns (does not abort) if frame counts mismatch or audio cues are absent.
## animation_data: Dictionary mapping move_id -> { "frame_count": int, ... }
static func _validate_move_list(move_list: Array, animation_data: Dictionary) -> void:
	for move in move_list:
		var expected_frames: int = move.startup_frames + move.active_frames + move.recovery_frames
		if animation_data.has(move.move_id):
			var anim_entry = animation_data[move.move_id]
			if anim_entry is Dictionary and anim_entry.has("frame_count"):
				var actual_frames: int = anim_entry["frame_count"]
				if actual_frames != expected_frames:
					push_warning(
						"MalacharMoves: animation frame count mismatch for '%s': " \
						+ "expected %d (startup %d + active %d + recovery %d), got %d" % [
							move.move_id,
							expected_frames,
							move.startup_frames,
							move.active_frames,
							move.recovery_frames,
							actual_frames
						]
					)
			else:
				push_warning(
					"MalacharMoves: animation entry for '%s' is missing 'frame_count' key." \
					% move.move_id
				)
		else:
			push_warning(
				"MalacharMoves: animation_data does not yet contain an entry for move '%s'. " \
				+ "Expected total frames: %d." % [move.move_id, expected_frames]
			)

		# Warn if audio cue key is not present in the manifest.
		# The manifest check is advisory — missing cues fall back to the default hit sound.
		if move.audio_cue_key == "":
			push_warning(
				"MalacharMoves: move '%s' has no audio_cue_key set." % move.move_id
			)


# ---------------------------------------------------------------------------
# Normal Moves
# ---------------------------------------------------------------------------

# Requirement 4.1 — Claw Swipe
# startup 3, active 4, recovery 5, damage 18, range 0–2, no special, no cost
static func _make_claw_swipe() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "claw_swipe"
	m.display_name = "Claw Swipe"
	m.startup_frames = 3
	m.active_frames = 4
	m.recovery_frames = 5
	m.base_damage = 18
	m.range_min = 0.0
	m.range_max = 2.0
	m.audio_cue_key = "claw_swipe"

	# Single hitbox active for the full active window (frames 4–7 of the move)
	var hb := HitboxDataClass.new()
	hb.offset_x = 1.0
	hb.offset_y = 0.0
	hb.width = 2.0
	hb.height = 1.5
	hb.active_frame_start = m.startup_frames + 1                          # frame 4
	hb.active_frame_end   = m.startup_frames + m.active_frames            # frame 7
	m.hitboxes = [hb]

	return m


# Requirement 4.2 — Lunge Bite
# startup 5, active 3, recovery 8, damage 28, range 2–4, Life_Steal 30%, drain 15
static func _make_lunge_bite() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "lunge_bite"
	m.display_name = "Lunge Bite"
	m.startup_frames = 5
	m.active_frames = 3
	m.recovery_frames = 8
	m.base_damage = 28
	m.range_min = 2.0
	m.range_max = 4.0
	m.has_life_steal = true
	m.life_steal_pct = 0.30
	m.life_steal_cap = 80
	m.has_drain = true
	m.blood_drain_value = 15
	m.audio_cue_key = "lunge_bite"

	var hb := HitboxDataClass.new()
	hb.offset_x = 3.0
	hb.offset_y = 0.0
	hb.width = 2.0
	hb.height = 1.5
	hb.active_frame_start = m.startup_frames + 1
	hb.active_frame_end   = m.startup_frames + m.active_frames
	m.hitboxes = [hb]

	return m


# Requirement 4.3 — Shadow Step
# startup 2, active 0, recovery 3, damage 0, movement only (teleport ≤6 units)
static func _make_shadow_step() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "shadow_step"
	m.display_name = "Shadow Step"
	m.startup_frames = 2
	m.active_frames = 0
	m.recovery_frames = 3
	m.base_damage = 0
	m.is_movement_only = true
	# range_max encodes the maximum teleport distance (6 units)
	m.range_min = 0.0
	m.range_max = 6.0
	m.audio_cue_key = "shadow_step"
	# No hitboxes — movement-only move
	m.hitboxes = []

	return m


# Requirement 4.4 — Sweeping Talon
# startup 4, active 5, recovery 6, damage 22, range 2–4, low hitbox (0–1 unit vertical)
static func _make_sweeping_talon() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "sweeping_talon"
	m.display_name = "Sweeping Talon"
	m.startup_frames = 4
	m.active_frames = 5
	m.recovery_frames = 6
	m.base_damage = 22
	m.range_min = 2.0
	m.range_max = 4.0
	m.audio_cue_key = "sweeping_talon"

	# Low hitbox: is_low = true, height covers 0–1 unit vertical (Req 12.2)
	var hb := HitboxDataClass.new()
	hb.offset_x = 3.0
	hb.offset_y = 0.0       # ground level
	hb.width = 2.0
	hb.height = 1.0         # 0–1 unit vertical
	hb.is_low = true
	hb.active_frame_start = m.startup_frames + 1
	hb.active_frame_end   = m.startup_frames + m.active_frames
	m.hitboxes = [hb]

	return m


# ---------------------------------------------------------------------------
# Special Moves
# ---------------------------------------------------------------------------

# Requirement 4.5 — Bat Swarm
# startup 6, active 8, recovery 10, damage 12/hit up to 3 hits, range 6–10
# 3 projectile bats launching on active frames 1, 3, 5; drain 10 per bat
static func _make_bat_swarm() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "bat_swarm"
	m.display_name = "Bat Swarm"
	m.startup_frames = 6
	m.active_frames = 8
	m.recovery_frames = 10
	m.base_damage = 12      # per hit
	m.range_min = 6.0
	m.range_max = 10.0
	m.projectile_count = 3
	m.has_drain = true
	m.blood_drain_value = 10  # per bat that connects
	m.audio_cue_key = "bat_swarm"

	# Requirement 12.4: 3 separate HitboxData entries, one per bat.
	# active_frame_start values are relative to move start (1-indexed).
	# Bat 1 launches on active frame 1 → move frame startup+1 = 7
	# Bat 2 launches on active frame 3 → move frame startup+3 = 9
	# Bat 3 launches on active frame 5 → move frame startup+5 = 11
	# Each bat travels forward; we give each a single-frame launch window.
	var bat1 := HitboxDataClass.new()
	bat1.offset_x = 6.0
	bat1.offset_y = 0.0
	bat1.width = 1.0
	bat1.height = 1.0
	bat1.active_frame_start = m.startup_frames + 1   # frame 7
	bat1.active_frame_end   = m.startup_frames + 8   # travels through active window

	var bat2 := HitboxDataClass.new()
	bat2.offset_x = 6.0
	bat2.offset_y = 0.0
	bat2.width = 1.0
	bat2.height = 1.0
	bat2.active_frame_start = m.startup_frames + 3   # frame 9
	bat2.active_frame_end   = m.startup_frames + 8

	var bat3 := HitboxDataClass.new()
	bat3.offset_x = 6.0
	bat3.offset_y = 0.0
	bat3.width = 1.0
	bat3.height = 1.0
	bat3.active_frame_start = m.startup_frames + 5   # frame 11
	bat3.active_frame_end   = m.startup_frames + 8

	m.hitboxes = [bat1, bat2, bat3]

	return m


# Requirement 4.6 — Hypnotic Gaze
# startup 8, active 2, recovery 12, damage 5, range 2–4, Hypnosis, drain 20
static func _make_hypnotic_gaze() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "hypnotic_gaze"
	m.display_name = "Hypnotic Gaze"
	m.startup_frames = 8
	m.active_frames = 2
	m.recovery_frames = 12
	m.base_damage = 5
	m.range_min = 2.0
	m.range_max = 4.0
	m.applies_hypnosis = true
	m.has_drain = true
	m.blood_drain_value = 20
	m.audio_cue_key = "hypnotic_gaze"

	var hb := HitboxDataClass.new()
	hb.offset_x = 3.0
	hb.offset_y = 0.0
	hb.width = 2.0
	hb.height = 1.5
	hb.active_frame_start = m.startup_frames + 1
	hb.active_frame_end   = m.startup_frames + m.active_frames
	m.hitboxes = [hb]

	return m


# Requirement 4.7 — Crimson Mist
# startup 4, active 6, recovery 9, damage 15, range 0–4, Life_Steal, linger 2f, drain 12
static func _make_crimson_mist() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "crimson_mist"
	m.display_name = "Crimson Mist"
	m.startup_frames = 4
	m.active_frames = 6
	m.recovery_frames = 9
	m.base_damage = 15
	m.range_min = 0.0
	m.range_max = 4.0
	m.has_life_steal = true
	m.life_steal_pct = 0.30
	m.life_steal_cap = 80
	m.has_drain = true
	m.blood_drain_value = 12
	m.audio_cue_key = "crimson_mist"

	# Cloud hitbox that lingers 2 extra frames after active window (Req 12.3)
	var hb := HitboxDataClass.new()
	hb.offset_x = 2.0
	hb.offset_y = 0.0
	hb.width = 4.0
	hb.height = 2.0
	hb.active_frame_start = m.startup_frames + 1
	hb.active_frame_end   = m.startup_frames + m.active_frames
	hb.lingers = true
	hb.linger_frames = 2
	m.hitboxes = [hb]

	return m


# Requirement 4.8 — Bat Form Dash
# startup 3, active 0, recovery 4, damage 0, movement only (bypass collision, ≤10 units any dir)
static func _make_bat_form_dash() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "bat_form_dash"
	m.display_name = "Bat Form Dash"
	m.startup_frames = 3
	m.active_frames = 0
	m.recovery_frames = 4
	m.base_damage = 0
	m.is_movement_only = true
	# range_max encodes maximum repositioning distance (10 units any direction)
	m.range_min = 0.0
	m.range_max = 10.0
	m.audio_cue_key = "bat_form_dash"
	# No hitboxes — movement-only move that bypasses collision
	m.hitboxes = []

	return m


# ---------------------------------------------------------------------------
# Blood Meter Abilities
# ---------------------------------------------------------------------------

# Requirement 4.9 — Blood Nova
# cost 50, startup 7, active 6, recovery 14, damage 55, burst r=4, Life_Steal, drain 0
static func _make_blood_nova() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "blood_nova"
	m.display_name = "Blood Nova"
	m.startup_frames = 7
	m.active_frames = 6
	m.recovery_frames = 14
	m.base_damage = 55
	m.range_min = 0.0
	m.range_max = 4.0       # burst radius defines effective range
	m.blood_meter_cost = 50
	m.blood_drain_value = 0
	m.has_life_steal = true
	m.life_steal_pct = 0.30
	m.life_steal_cap = 80
	m.audio_cue_key = "blood_nova"

	# Burst hitbox centered on Malachar with radius 4 (Req 12.2)
	var hb := HitboxDataClass.new()
	hb.offset_x = 0.0
	hb.offset_y = 0.0
	hb.width = 8.0           # diameter = 2 * burst_radius
	hb.height = 8.0
	hb.is_burst = true
	hb.burst_radius = 4.0
	hb.active_frame_start = m.startup_frames + 1
	hb.active_frame_end   = m.startup_frames + m.active_frames
	m.hitboxes = [hb]

	return m


# Requirement 4.10 — Eternal Drain
# cost 30, startup 6, active 10, recovery 12, damage 35, range 2–4, Life_Steal 60%, drain 0
static func _make_eternal_drain() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "eternal_drain"
	m.display_name = "Eternal Drain"
	m.startup_frames = 6
	m.active_frames = 10
	m.recovery_frames = 12
	m.base_damage = 35
	m.range_min = 2.0
	m.range_max = 4.0
	m.blood_meter_cost = 30
	m.blood_drain_value = 0
	# Life_Steal at 60% — overrides the standard 30% for this move only
	m.has_life_steal = true
	m.life_steal_pct = 0.60
	m.life_steal_cap = 80
	m.audio_cue_key = "eternal_drain"

	var hb := HitboxDataClass.new()
	hb.offset_x = 3.0
	hb.offset_y = 0.0
	hb.width = 2.0
	hb.height = 1.5
	hb.active_frame_start = m.startup_frames + 1
	hb.active_frame_end   = m.startup_frames + m.active_frames
	m.hitboxes = [hb]

	return m


# Requirement 4.11 — Lord of Bats
# cost 100, startup 10, active 15, recovery 20, damage 70, full-screen
# 8 homing projectile bats, Life_Steal, drain 0
static func _make_lord_of_bats() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "lord_of_bats"
	m.display_name = "Lord of Bats"
	m.startup_frames = 10
	m.active_frames = 15
	m.recovery_frames = 20
	m.base_damage = 70
	m.range_min = 0.0
	m.range_max = -1.0      # -1 = full-screen
	m.blood_meter_cost = 100
	m.blood_drain_value = 0
	m.has_life_steal = true
	m.life_steal_pct = 0.30
	m.life_steal_cap = 80
	m.projectile_count = 8
	m.projectile_homing = true   # bats update direction toward opponent each frame
	m.audio_cue_key = "lord_of_bats"

	# 8 HitboxData entries, one per homing bat (Req 12.2)
	# Bats are spread across the active window; each launches one frame apart.
	m.hitboxes = []
	for i in range(8):
		var hb := HitboxDataClass.new()
		hb.offset_x = 0.0   # homing — initial offset is centered; runtime updates position
		hb.offset_y = 0.0
		hb.width = 1.0
		hb.height = 1.0
		# Spread launch frames evenly across the active window (frames 11–25 of the move)
		hb.active_frame_start = m.startup_frames + 1 + i
		hb.active_frame_end   = m.startup_frames + m.active_frames
		m.hitboxes.append(hb)

	return m
