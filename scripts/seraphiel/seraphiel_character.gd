# seraphiel_character.gd
# Main Character_Script for Seraphiel the Radiant.
# Implements the duck-typed interface called by the game's combat loop.
#
# Covers Requirements: 7.1–7.8, 8.5, 9.9–9.12, 10.5, 11.1–11.7, 12.1, 12.6, 13.3, 13.4, 14.5

const MoveDataClass          = preload("res://scripts/shared/move_data.gd")
const HitboxDataClass        = preload("res://scripts/shared/hitbox_data.gd")
const HurtboxDataClass       = preload("res://scripts/shared/hurtbox_data.gd")
const AudioLoaderClass       = preload("res://scripts/shared/audio_loader.gd")
const SeraphielMovesClass    = preload("res://scripts/seraphiel/seraphiel_moves.gd")
const SeraphielMechanicsClass = preload("res://scripts/seraphiel/seraphiel_mechanics.gd")

class_name SeraphielCharacter

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var current_hp: int = 1050
var mechanics: SeraphielMechanics = SeraphielMechanicsClass.new()
var audio_loader: AudioLoader     = AudioLoaderClass.new()

# Cached move list (built once, reused each call)
var _move_list: Array = []

# Hurtbox definitions (built once in _init)
var _hurtboxes: Dictionary = {}

# Seraph's Judgment special handling (Req 9.12):
# Mirrors the Lord of Bats pattern in malachar_character.gd.
# Flag is set in on_move_selected; radiance meter is cleared in on_turn_start.
var _pending_seraphs_judgment: bool = false

# Pending heal amount for Healing Hymn / Angelic Restoration (Req 9.7, 9.10):
# Computed in on_move_selected (after Martyr's Grace multiplier is applied)
# and consumed by the combat loop / scene when the move resolves.
var _pending_heal_amount: int = 0

# Empowered threshold audio tracking (Req 13.3):
# Tracks whether Seraphiel was empowered at the end of the previous turn so we
# can detect the moment the Radiance Meter crosses the 50 threshold and play the
# activation cue exactly once per crossing.
var _was_empowered: bool = false

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

func _init() -> void:
	# Load audio manifest so cues are available at runtime.
	audio_loader.load_manifest("res://audio_manifest.json")

	# Build move list once.
	_move_list = SeraphielMovesClass.get_move_list()

	# Build hurtbox table (Req 12.1, 12.6).
	_build_hurtboxes()


func _build_hurtboxes() -> void:
	# Standing — full body height (Req 12.6)
	var standing := HurtboxDataClass.new()
	standing.state_name = "standing"
	standing.width      = 40.0
	standing.height     = 100.0
	standing.offset_x   = 0.0
	standing.offset_y   = 0.0
	_hurtboxes["standing"] = standing

	# Crouching — 60% of standing height (Req 12.6)
	var crouching := HurtboxDataClass.new()
	crouching.state_name = "crouching"
	crouching.width      = 40.0
	crouching.height     = 60.0
	crouching.offset_x   = 0.0
	crouching.offset_y   = 0.0
	_hurtboxes["crouching"] = crouching

	# Airborne — same dimensions as standing, shifted upward
	var airborne := HurtboxDataClass.new()
	airborne.state_name = "airborne"
	airborne.width      = 40.0
	airborne.height     = 100.0
	airborne.offset_x   = 0.0
	airborne.offset_y   = 20.0
	_hurtboxes["airborne"] = airborne

	# Hit stun — same as standing
	var hit_stun := HurtboxDataClass.new()
	hit_stun.state_name = "hit_stun"
	hit_stun.width      = 40.0
	hit_stun.height     = 100.0
	hit_stun.offset_x   = 0.0
	hit_stun.offset_y   = 0.0
	_hurtboxes["hit_stun"] = hit_stun


# ---------------------------------------------------------------------------
# Identity / Stats (Req 7.1–7.7, 14.5)
# ---------------------------------------------------------------------------

func get_character_id() -> String:
	return "seraphiel_the_radiant"

func get_display_name() -> String:
	return "Seraphiel the Radiant"

func get_base_hp() -> int:
	return 1050

func get_move_speed() -> float:
	return 4.0

func get_jump_height() -> float:
	return 7.0

func get_weight_class() -> String:
	return "light"

func get_portrait_path() -> String:
	return "assets/seraphiel/portrait.png"

## Lore description — must be ≤80 characters (Req 14.5).
func get_lore_description() -> String:
	return "A fallen angel seeking redemption through divine light and holy combat."


# ---------------------------------------------------------------------------
# Move List (Req 9.1–9.12)
# ---------------------------------------------------------------------------

func get_move_list() -> Array:
	return SeraphielMovesClass.get_move_list()


# ---------------------------------------------------------------------------
# Move Selection (Req 8.2, 8.3, 9.9–9.12)
# ---------------------------------------------------------------------------

## Called by the combat loop when the player selects a move.
## Returns true if the move is accepted, false if it should be rejected
## (e.g. insufficient Radiance Meter).
func on_move_selected(move_id: String) -> bool:
	var move: MoveData = _find_move(move_id)
	if move == null:
		push_warning("SeraphielCharacter: unknown move_id '%s' in on_move_selected." % move_id)
		return false

	# Gate on Radiance Meter cost (Req 8.2, 8.3, 9.9–9.12).
	if move.radiance_meter_cost > 0:
		var accepted: bool = mechanics.spend_radiance(move.radiance_meter_cost)
		if not accepted:
			# Insufficient meter — reject the move (icon should be greyed out by UI).
			return false

	# Seraph's Judgment special handling (Req 9.12):
	# After the move executes the radiance meter must be set to 0 regardless of hit.
	# We set a pending flag here and clear the meter in on_turn_start (next turn).
	if move_id == "seraphs_judgment":
		_pending_seraphs_judgment = true

	# Healing Hymn (Req 9.7): apply Martyr's Grace multiplier to the 30 HP base heal.
	# Track the pending heal amount so the combat loop / scene can apply it.
	if move_id == "healing_hymn":
		_pending_heal_amount = mechanics.apply_martyrs_grace_multiplier(30)

	# Angelic Restoration (Req 9.10): same pattern, 80 HP base heal.
	if move_id == "angelic_restoration":
		_pending_heal_amount = mechanics.apply_martyrs_grace_multiplier(80)

	return true


# ---------------------------------------------------------------------------
# Hit Resolution (Req 7.5, 7.6, 8.1, 10.5)
# ---------------------------------------------------------------------------

## Called by the combat loop when a hit lands.
## move_id: the move that connected.
## damage_dealt: raw damage value used for meter and passive calculations.
##
## NOTE: Smite damage is calculated by the combat loop using calculate_smite_damage().
## This method handles meter gain, Martyr's Grace passive check, and audio cues only.
func on_hit_landed(move_id: String, damage_dealt: int) -> void:
	var move: MoveData = _find_move(move_id)
	if move == null:
		push_warning("SeraphielCharacter: unknown move_id '%s' in on_hit_landed — skipping." % move_id)
		return

	# 1. Radiance Meter gain from holy moves (Req 7.5, 7.6, 8.1)
	if move.has_holy and move.radiance_value > 0:
		mechanics.add_radiance(move.radiance_value)

	# 2. Martyr's Grace passive check (Req 7.8)
	mechanics.check_martyrs_grace(current_hp)

	# 3. Audio cue (Req 13.3, 13.4)
	_play_audio_cue(move.audio_cue_key)


# ---------------------------------------------------------------------------
# Turn Start (Req 8.5, 9.12)
# ---------------------------------------------------------------------------

## Called by the combat loop at the start of each of Seraphiel's turns.
func on_turn_start() -> void:
	# Seraph's Judgment post-execution meter clear (Req 9.12):
	# The flag was set in on_move_selected; we clear the meter now that the
	# move has fully resolved (active + recovery frames have elapsed).
	if _pending_seraphs_judgment:
		mechanics.radiance_meter = 0
		_pending_seraphs_judgment = false

	# Empowered threshold audio cue (Req 13.3, 13.4):
	# Play "radiance_meter_glow" exactly once when the Radiance Meter crosses
	# from below 50 to 50 or above.
	var currently_empowered: bool = is_empowered()
	if currently_empowered and not _was_empowered:
		_play_audio_cue("radiance_meter_glow")
	_was_empowered = currently_empowered

	# Empowered glow overlay (Req 8.5):
	# The combat loop / UI layer reads is_empowered() to toggle the animation.
	_update_empowered_visual()


## Returns true when the Radiance Meter is ≥50 (used by UI to toggle glow overlay).
func is_empowered() -> bool:
	return mechanics.is_empowered()


# ---------------------------------------------------------------------------
# Smite Damage (Req 10.1–10.5)
# ---------------------------------------------------------------------------

## Public method delegating to SeraphielMechanics.
## The combat loop calls this to determine the Smite bonus for a given move.
## move: the MoveData being executed.
## opponent_status_effects: Array of active negative status effects on the opponent.
## Returns the smite bonus damage (0 if no status effects or move has no Smite property).
func calculate_smite_damage(move: MoveData, opponent_status_effects: Array) -> int:
	if not move.has_smite:
		return 0
	return mechanics.calculate_smite_damage(move, opponent_status_effects)


# ---------------------------------------------------------------------------
# Hurtbox (Req 12.1, 12.6)
# ---------------------------------------------------------------------------

## Returns the HurtboxData for the given animation state.
## Falls back to "standing" for unknown states.
func get_hurtbox_state(anim_state: String) -> HurtboxData:
	if _hurtboxes.has(anim_state):
		return _hurtboxes[anim_state]
	push_warning(
		"SeraphielCharacter: unknown anim_state '%s' — returning standing hurtbox." % anim_state
	)
	return _hurtboxes["standing"]


# ---------------------------------------------------------------------------
# Match Reset
# ---------------------------------------------------------------------------

## Resets all state for a fresh match (Req 7.4, 8.4).
func reset_for_match() -> void:
	mechanics.reset_for_match()
	current_hp = get_base_hp()
	_pending_seraphs_judgment = false
	_pending_heal_amount = 0
	_was_empowered = false


## Called by the combat loop at the end of a round within a match.
## NOTE: The Radiance Meter intentionally persists across rounds.
## Do NOT call reset_for_match() here. Meters only reset between matches (Req 3.5 / 8.4).
func on_round_end() -> void:
	pass  # Meters persist — no reset between rounds.


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

## Looks up a MoveData by move_id from the cached move list.
## Returns null if not found.
func _find_move(move_id: String) -> MoveData:
	for move in _move_list:
		if move.move_id == move_id:
			return move
	return null


## Plays the audio cue for the given key via AudioLoader (Req 13.3, 13.4).
## Falls back to the default hit sound if the cue is missing or corrupt.
func _play_audio_cue(cue_key: String) -> void:
	if cue_key == "":
		return
	var stream: AudioStream = audio_loader.get_audio_stream(cue_key)
	if stream == null:
		return
	# The combat loop / scene tree is responsible for routing the stream to an
	# AudioStreamPlayer node. We expose the stream via a signal or direct call
	# depending on the mod loader's audio API. Here we emit a best-effort call
	# that the host scene can connect to.
	# If the host provides an audio bus node named "CharacterAudio", use it.
	# Otherwise the cue is silently skipped (no crash — Req 13.4).
	var audio_node = _get_audio_player()
	if audio_node != null and audio_node.has_method("play_stream"):
		audio_node.play_stream(stream)


## Attempts to locate an AudioStreamPlayer in the scene tree.
## Returns null if unavailable (graceful degradation).
func _get_audio_player() -> Object:
	# In a Godot scene context this would be something like:
	#   return get_node_or_null("/root/CharacterAudio")
	# Since this script may run outside a full scene tree (e.g. in tests),
	# we guard with a null check.
	if not is_instance_valid(self) or not has_method("get_node_or_null"):
		return null
	return call("get_node_or_null", "/root/CharacterAudio")


## Notifies the visual layer to update the empowered glow overlay (Req 8.5).
## The actual AnimationPlayer call lives in the scene; we expose the state here.
func _update_empowered_visual() -> void:
	# The host scene connects to this character object and polls is_empowered()
	# each turn to toggle the "radiance_glow" AnimationPlayer animation.
	# No direct scene manipulation here keeps the script scene-tree-agnostic.
	pass
