# seraphiel_moves.gd
# Defines all 11 MoveData instances for Seraphiel the Radiant.
# Covers Requirements 9.1–9.12, 12.2, 12.3, 12.5

# Preload shared classes so this file can be used standalone or via autoload.
const MoveDataClass = preload("res://scripts/shared/move_data.gd")
const HitboxDataClass = preload("res://scripts/shared/hitbox_data.gd")

class_name SeraphielMoves


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns the complete move list for Seraphiel as an Array of MoveData.
static func get_move_list() -> Array:
	return [
		_make_holy_strike(),
		_make_wing_buffet(),
		_make_ascend(),
		_make_halo_slam(),
		_make_feather_barrage(),
		_make_blinding_light(),
		_make_healing_hymn(),
		_make_divine_descent(),
		_make_wrath_of_heaven(),
		_make_angelic_restoration(),
		_make_seraphs_judgment(),
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
						"SeraphielMoves: animation frame count mismatch for '%s': " \
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
					"SeraphielMoves: animation entry for '%s' is missing 'frame_count' key." \
					% move.move_id
				)
		else:
			push_warning(
				"SeraphielMoves: animation_data does not yet contain an entry for move '%s'. " \
				+ "Expected total frames: %d." % [move.move_id, expected_frames]
			)

		# Warn if audio cue key is not present in the manifest.
		# The manifest check is advisory — missing cues fall back to the default hit sound.
		if move.audio_cue_key == "":
			push_warning(
				"SeraphielMoves: move '%s' has no audio_cue_key set." % move.move_id
			)


# ---------------------------------------------------------------------------
# Normal Moves
# ---------------------------------------------------------------------------

# Requirement 9.1 — Holy Strike
# startup 4, active 4, recovery 5, damage 16, range 0–2, holy, radiance 10, no cost
static func _make_holy_strike() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "holy_strike"
	m.display_name = "Holy Strike"
	m.startup_frames = 4
	m.active_frames = 4
	m.recovery_frames = 5
	m.base_damage = 16
	m.range_min = 0.0
	m.range_max = 2.0
	m.has_holy = true
	m.radiance_value = 10
	m.audio_cue_key = "holy_strike"

	# Single hitbox active for the full active window
	var hb := HitboxDataClass.new()
	hb.offset_x = 1.0
	hb.offset_y = 0.0
	hb.width = 2.0
	hb.height = 1.5
	hb.active_frame_start = m.startup_frames + 1                   # frame 5
	hb.active_frame_end   = m.startup_frames + m.active_frames     # frame 8
	m.hitboxes = [hb]

	return m


# Requirement 9.2 — Wing Buffet
# startup 3, active 5, recovery 6, damage 20, range 0–4, wide horizontal hitbox, holy, radiance 8
static func _make_wing_buffet() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "wing_buffet"
	m.display_name = "Wing Buffet"
	m.startup_frames = 3
	m.active_frames = 5
	m.recovery_frames = 6
	m.base_damage = 20
	m.range_min = 0.0
	m.range_max = 4.0
	m.has_holy = true
	m.radiance_value = 8
	m.audio_cue_key = "wing_buffet"

	# Wide horizontal hitbox (width=4.0, height=1.0) — Req 12.2
	var hb := HitboxDataClass.new()
	hb.offset_x = 2.0
	hb.offset_y = 0.0
	hb.width = 4.0
	hb.height = 1.0
	hb.active_frame_start = m.startup_frames + 1                   # frame 4
	hb.active_frame_end   = m.startup_frames + m.active_frames     # frame 8
	m.hitboxes = [hb]

	return m


# Requirement 9.3 — Ascend
# startup 2, active 0, recovery 3, damage 0, movement only (+5u up, +2u forward)
static func _make_ascend() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "ascend"
	m.display_name = "Ascend"
	m.startup_frames = 2
	m.active_frames = 0
	m.recovery_frames = 3
	m.base_damage = 0
	m.is_movement_only = true
	# range_max encodes the forward movement distance (2 units); vertical (+5u) is handled by runtime
	m.range_min = 0.0
	m.range_max = 2.0
	m.audio_cue_key = "ascend"
	# No hitboxes — movement-only move
	m.hitboxes = []

	return m


# Requirement 9.4 — Halo Slam
# startup 6, active 4, recovery 8, damage 26, range 0–2, overhead hitbox, holy, radiance 12
static func _make_halo_slam() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "halo_slam"
	m.display_name = "Halo Slam"
	m.startup_frames = 6
	m.active_frames = 4
	m.recovery_frames = 8
	m.base_damage = 26
	m.range_min = 0.0
	m.range_max = 2.0
	m.has_holy = true
	m.radiance_value = 12
	m.audio_cue_key = "halo_slam"

	# Overhead hitbox that strikes downward — is_overhead = true (Req 12.2)
	var hb := HitboxDataClass.new()
	hb.offset_x = 1.0
	hb.offset_y = 1.0      # elevated position for overhead strike
	hb.width = 2.0
	hb.height = 1.5
	hb.is_overhead = true
	hb.active_frame_start = m.startup_frames + 1                   # frame 7
	hb.active_frame_end   = m.startup_frames + m.active_frames     # frame 10
	m.hitboxes = [hb]

	return m


# ---------------------------------------------------------------------------
# Special Moves
# ---------------------------------------------------------------------------

# Requirement 9.5 — Feather Barrage
# startup 5, active 10, recovery 8, damage 8/feather up to 5, range 6–10
# 5 projectile feathers in spread pattern, holy, radiance 5 per feather
static func _make_feather_barrage() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "feather_barrage"
	m.display_name = "Feather Barrage"
	m.startup_frames = 5
	m.active_frames = 10
	m.recovery_frames = 8
	m.base_damage = 8       # per feather
	m.range_min = 6.0
	m.range_max = 10.0
	m.projectile_count = 5
	m.has_holy = true
	m.radiance_value = 5    # per feather that connects
	m.audio_cue_key = "feather_barrage"

	# Requirement 12.5: 5 separate HitboxData entries, one per feather, with spread offsets.
	# offset_x varies: 6.0, 7.0, 8.0, 7.0, 6.0
	# offset_y varies: 0.0, 0.5, 0.0, -0.5, 0.0
	var feather_offsets_x: Array = [6.0, 7.0, 8.0, 7.0, 6.0]
	var feather_offsets_y: Array = [0.0, 0.5, 0.0, -0.5, 0.0]

	m.hitboxes = []
	for i in range(5):
		var hb := HitboxDataClass.new()
		hb.offset_x = feather_offsets_x[i]
		hb.offset_y = feather_offsets_y[i]
		hb.width = 0.5
		hb.height = 0.5
		hb.active_frame_start = m.startup_frames + 1                   # frame 6
		hb.active_frame_end   = m.startup_frames + m.active_frames     # frame 15
		m.hitboxes.append(hb)

	return m


# Requirement 9.6 — Blinding Light
# startup 7, active 3, recovery 10, damage 10, range 2–4
# applies blind (reduces opponent range by 2 units for next move), holy, radiance 15
static func _make_blinding_light() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "blinding_light"
	m.display_name = "Blinding Light"
	m.startup_frames = 7
	m.active_frames = 3
	m.recovery_frames = 10
	m.base_damage = 10
	m.range_min = 2.0
	m.range_max = 4.0
	m.has_holy = true
	m.applies_blind = true
	m.radiance_value = 15
	m.audio_cue_key = "blinding_light"

	var hb := HitboxDataClass.new()
	hb.offset_x = 3.0
	hb.offset_y = 0.0
	hb.width = 2.0
	hb.height = 1.5
	hb.active_frame_start = m.startup_frames + 1                   # frame 8
	hb.active_frame_end   = m.startup_frames + m.active_frames     # frame 10
	m.hitboxes = [hb]

	return m


# Requirement 9.7 — Healing Hymn
# startup 8, active 0, recovery 12, damage 0, self-targeting (restores 30 HP), holy, radiance 20
static func _make_healing_hymn() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "healing_hymn"
	m.display_name = "Healing Hymn"
	m.startup_frames = 8
	m.active_frames = 0
	m.recovery_frames = 12
	m.base_damage = 0
	m.is_movement_only = false  # self-targeting, not movement
	m.range_min = 0.0
	m.range_max = 0.0
	m.has_holy = true
	m.radiance_value = 20
	m.audio_cue_key = "healing_hymn"
	# No hitboxes — self-targeting heal move
	m.hitboxes = []

	return m


# Requirement 9.8 — Divine Descent
# startup 4, active 6, recovery 7, damage 30, range 2–4
# downward-angled hitbox, holy, Smite +15, radiance 18
static func _make_divine_descent() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "divine_descent"
	m.display_name = "Divine Descent"
	m.startup_frames = 4
	m.active_frames = 6
	m.recovery_frames = 7
	m.base_damage = 30
	m.range_min = 2.0
	m.range_max = 4.0
	m.has_holy = true
	m.has_smite = true
	m.smite_bonus = 15
	m.radiance_value = 18
	m.audio_cue_key = "divine_descent"

	# Downward-angled hitbox: offset_y = -1.0 indicates downward angle (Req 12.2)
	var hb := HitboxDataClass.new()
	hb.offset_x = 3.0
	hb.offset_y = -1.0     # downward-angled offset
	hb.width = 2.0
	hb.height = 1.5
	hb.is_overhead = false
	hb.active_frame_start = m.startup_frames + 1                   # frame 5
	hb.active_frame_end   = m.startup_frames + m.active_frames     # frame 10
	m.hitboxes = [hb]

	return m


# ---------------------------------------------------------------------------
# Radiance Meter Abilities
# ---------------------------------------------------------------------------

# Requirement 9.9 — Wrath of Heaven
# cost 50, startup 8, active 6, recovery 16, damage 60, range 2–6
# pillar of light hitbox (tall+narrow), holy, Smite +20, radiance 0
static func _make_wrath_of_heaven() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "wrath_of_heaven"
	m.display_name = "Wrath of Heaven"
	m.startup_frames = 8
	m.active_frames = 6
	m.recovery_frames = 16
	m.base_damage = 60
	m.range_min = 2.0
	m.range_max = 6.0
	m.radiance_meter_cost = 50
	m.radiance_value = 0
	m.has_holy = true
	m.has_smite = true
	m.smite_bonus = 20
	m.audio_cue_key = "wrath_of_heaven"

	# Pillar of light hitbox: tall and narrow (width=1.5, height=8.0) — Req 12.2
	var hb := HitboxDataClass.new()
	hb.offset_x = 4.0
	hb.offset_y = 0.0
	hb.width = 1.5
	hb.height = 8.0
	hb.active_frame_start = m.startup_frames + 1                   # frame 9
	hb.active_frame_end   = m.startup_frames + m.active_frames     # frame 14
	m.hitboxes = [hb]

	return m


# Requirement 9.10 — Angelic Restoration
# cost 30, startup 6, active 0, recovery 10, damage 0, self-targeting (restores 80 HP), holy, radiance 0
static func _make_angelic_restoration() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "angelic_restoration"
	m.display_name = "Angelic Restoration"
	m.startup_frames = 6
	m.active_frames = 0
	m.recovery_frames = 10
	m.base_damage = 0
	m.range_min = 0.0
	m.range_max = 0.0
	m.radiance_meter_cost = 30
	m.radiance_value = 0
	m.has_holy = true
	m.audio_cue_key = "angelic_restoration"
	# No hitboxes — self-targeting heal move
	m.hitboxes = []

	return m


# Requirement 9.11 — Seraph's Judgment
# cost 100, startup 12, active 10, recovery 22, damage 85, full-screen (range_max=-1)
# divine beam hitbox, holy, Smite +30, radiance 0
static func _make_seraphs_judgment() -> MoveData:
	var m := MoveDataClass.new()
	m.move_id = "seraphs_judgment"
	m.display_name = "Seraph's Judgment"
	m.startup_frames = 12
	m.active_frames = 10
	m.recovery_frames = 22
	m.base_damage = 85
	m.range_min = 0.0
	m.range_max = -1.0      # -1 = full-screen
	m.radiance_meter_cost = 100
	m.radiance_value = 0
	m.has_holy = true
	m.has_smite = true
	m.smite_bonus = 30
	# audio_manifest uses "seraph_judgment" (no trailing 's') — matches audio_manifest.json
	m.audio_cue_key = "seraph_judgment"

	# Full-screen divine beam hitbox (width=20.0, height=2.0) — Req 12.2
	var hb := HitboxDataClass.new()
	hb.offset_x = 0.0
	hb.offset_y = 0.0
	hb.width = 20.0
	hb.height = 2.0
	hb.active_frame_start = m.startup_frames + 1                   # frame 13
	hb.active_frame_end   = m.startup_frames + m.active_frames     # frame 22
	m.hitboxes = [hb]

	return m
