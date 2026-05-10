# malachar_character.gd
# Main Character_Script for Malachar the Undying.
# Implements the duck-typed interface called by the game's combat loop.
#
# Covers Requirements: 2.1–2.7, 3.6, 5.6, 6.1–6.7, 12.1, 12.6, 13.2, 13.4, 14.4

const MoveDataClass      = preload("res://scripts/shared/move_data.gd")
const HitboxDataClass    = preload("res://scripts/shared/hitbox_data.gd")
const HurtboxDataClass   = preload("res://scripts/shared/hurtbox_data.gd")
const AudioLoaderClass   = preload("res://scripts/shared/audio_loader.gd")
const MalacharMovesClass = preload("res://scripts/malachar/malachar_moves.gd")
const MalacharMechanicsClass = preload("res://scripts/malachar/malachar_mechanics.gd")

class_name MalacharCharacter

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var current_hp: int = 950
var mechanics: MalacharMechanics = MalacharMechanicsClass.new()
var audio_loader: AudioLoader    = AudioLoaderClass.new()

# Cached move list (built once, reused each call)
var _move_list: Array = []

# Hurtbox definitions (built once in _init)
var _hurtboxes: Dictionary = {}

# Lord of Bats special handling:
# Because the game may not expose an on_move_executed callback, we track a
# pending flag set in on_move_selected and clear the blood meter in on_turn_start.
var _pending_lord_of_bats: bool = false

# Empowered threshold audio tracking (Req 13.2):
# Tracks whether Malachar was empowered at the end of the previous turn so we
# can detect the moment the Blood Meter crosses the 50 threshold and play the
# activation cue exactly once per crossing.
var _was_empowered: bool = false

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

func _init() -> void:
	# Load audio manifest so cues are available at runtime.
	audio_loader.load_manifest("res://audio_manifest.json")

	# Build move list once.
	_move_list = MalacharMovesClass.get_move_list()

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
# Identity / Stats (Req 2.1–2.7, 14.4)
# ---------------------------------------------------------------------------

func get_character_id() -> String:
	return "malachar_the_undying"

func get_display_name() -> String:
	return "Malachar the Undying"

func get_base_hp() -> int:
	return 950

func get_move_speed() -> float:
	return 4.5

func get_jump_height() -> float:
	return 5.0

func get_weight_class() -> String:
	return "medium"

func get_portrait_path() -> String:
	return "assets/malachar/portrait.png"

## Lore description — must be ≤80 characters (Req 14.4).
func get_lore_description() -> String:
	return "A centuries-old vampire lord who drains life and commands the night."


# ---------------------------------------------------------------------------
# Move List (Req 4.1–4.12)
# ---------------------------------------------------------------------------

func get_move_list() -> Array:
	return MalacharMovesClass.get_move_list()


# ---------------------------------------------------------------------------
# Move Selection (Req 3.3, 3.4, 4.9–4.12)
# ---------------------------------------------------------------------------

## Called by the combat loop when the player selects a move.
## Returns true if the move is accepted, false if it should be rejected
## (e.g. insufficient Blood Meter).
func on_move_selected(move_id: String) -> bool:
	var move: MoveData = _find_move(move_id)
	if move == null:
		push_warning("MalacharCharacter: unknown move_id '%s' in on_move_selected." % move_id)
		return false

	# Gate on Blood Meter cost (Req 3.3, 3.4, 4.9–4.12).
	if move.blood_meter_cost > 0:
		var accepted: bool = mechanics.spend_blood(move.blood_meter_cost)
		if not accepted:
			# Insufficient meter — reject the move (icon should be greyed out by UI).
			return false

	# Lord of Bats special handling (Req 4.12):
	# After the move executes the blood meter must be set to 0 regardless of hit.
	# We set a pending flag here and clear the meter in on_turn_start (next turn).
	if move_id == "lord_of_bats":
		_pending_lord_of_bats = true

	return true


# ---------------------------------------------------------------------------
# Hit Resolution (Req 2.5, 2.6, 3.1, 3.2, 5.1–5.6)
# ---------------------------------------------------------------------------

## Called by the combat loop when a hit lands.
## move_id: the move that connected.
## damage_dealt: raw damage value (before mitigation) used for life steal calc.
func on_hit_landed(move_id: String, damage_dealt: int) -> void:
	var move: MoveData = _find_move(move_id)
	if move == null:
		push_warning("MalacharCharacter: unknown move_id '%s' in on_hit_landed — skipping." % move_id)
		return

	# 1. Life Steal (Req 2.5, 2.6)
	if move.has_life_steal:
		var restore_amount: int = mechanics.apply_life_steal(
			damage_dealt,
			move.life_steal_pct,
			move.life_steal_cap
		)
		# Desperate Hunger multiplier: 1.5× when active (Req 2.6)
		if mechanics.desperate_hunger_active:
			restore_amount = int(restore_amount * 1.5)
		current_hp = min(current_hp + restore_amount, get_base_hp())

	# 2. Blood Meter drain (Req 3.1, 3.2)
	if move.has_drain and move.blood_drain_value > 0:
		mechanics.add_blood(move.blood_drain_value)

	# 3. Hypnosis (Req 5.1–5.6) — opponent_state is not passed here; the combat
	#    loop is expected to call a separate apply_status API. We flag the move
	#    so the caller can act on it.
	#    (applies_hypnosis is readable from the MoveData by the combat loop.)

	# 4. Desperate Hunger check (Req 2.6)
	mechanics.check_desperate_hunger(current_hp)

	# 5. Audio cue (Req 13.2, 13.4)
	_play_audio_cue(move.audio_cue_key)


# ---------------------------------------------------------------------------
# Turn Start (Req 3.6)
# ---------------------------------------------------------------------------

## Called by the combat loop at the start of each of Malachar's turns.
func on_turn_start() -> void:
	# Lord of Bats post-execution meter clear (Req 4.12):
	# The flag was set in on_move_selected; we clear the meter now that the
	# move has fully resolved (active + recovery frames have elapsed).
	if _pending_lord_of_bats:
		mechanics.blood_meter = 0
		_pending_lord_of_bats = false

	# Empowered threshold audio cue (Req 13.2, 13.4):
	# Play "blood_meter_pulse" exactly once when the Blood Meter crosses from
	# below 50 to 50 or above.
	var currently_empowered: bool = is_empowered()
	if currently_empowered and not _was_empowered:
		_play_audio_cue("blood_meter_pulse")
	_was_empowered = currently_empowered

	# Empowered pulse overlay (Req 3.6):
	# The combat loop / UI layer reads is_empowered() to toggle the animation.
	# We call the helper here so any listener can react.
	_update_empowered_visual()


## Returns true when the Blood Meter is ≥50 (used by UI to toggle pulse overlay).
func is_empowered() -> bool:
	return mechanics.is_empowered()


# ---------------------------------------------------------------------------
# Hurtbox (Req 12.1, 12.6)
# ---------------------------------------------------------------------------

## Returns the HurtboxData for the given animation state.
## Falls back to "standing" for unknown states.
func get_hurtbox_state(anim_state: String) -> HurtboxData:
	if _hurtboxes.has(anim_state):
		return _hurtboxes[anim_state]
	push_warning(
		"MalacharCharacter: unknown anim_state '%s' — returning standing hurtbox." % anim_state
	)
	return _hurtboxes["standing"]


# ---------------------------------------------------------------------------
# Match Reset
# ---------------------------------------------------------------------------

## Resets all state for a fresh match (Req 2.4, 3.5).
func reset_for_match() -> void:
	mechanics.reset_for_match()
	current_hp = get_base_hp()
	_pending_lord_of_bats = false
	_was_empowered = false


## Called by the combat loop at the end of a round within a match.
## NOTE: The Blood Meter intentionally persists across rounds.
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


## Plays the audio cue for the given key via AudioLoader (Req 13.2, 13.4).
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


## Notifies the visual layer to update the empowered pulse overlay (Req 3.6).
## The actual AnimationPlayer call lives in the scene; we expose the state here.
func _update_empowered_visual() -> void:
	# The host scene connects to this character object and polls is_empowered()
	# each turn to toggle the "blood_pulse" AnimationPlayer animation.
	# No direct scene manipulation here keeps the script scene-tree-agnostic.
	pass
