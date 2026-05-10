# mod_loader_integration.gd
# Handles mod loading, validation, and character registration.
# Called by the game's beta mod loader when it processes this mod's zip archive.
# Does NOT modify any base game files (Req 1.8).
# Covers Requirements: 1.1, 1.3, 1.4, 1.5, 1.6, 1.8

const ModValidatorClass = preload("res://scripts/shared/mod_validator.gd")
const MalacharCharacterClass = preload("res://scripts/malachar/malachar_character.gd")
const SeraphielCharacterClass = preload("res://scripts/seraphiel/seraphiel_character.gd")

class_name ModLoaderIntegration

# Required asset paths that must exist in the mod archive
const REQUIRED_ASSETS: Array = [
	"scripts/malachar/malachar_character.gd",
	"scripts/malachar/malachar_mechanics.gd",
	"scripts/malachar/malachar_moves.gd",
	"scripts/seraphiel/seraphiel_character.gd",
	"scripts/seraphiel/seraphiel_mechanics.gd",
	"scripts/seraphiel/seraphiel_moves.gd",
	"scripts/shared/move_data.gd",
	"scripts/shared/hitbox_data.gd",
	"scripts/shared/hurtbox_data.gd",
	"scripts/shared/audio_loader.gd",
	"audio_manifest.json",
	"mod.json"
]

# Known base game character IDs (to check for conflicts)
# This list should be updated if the base game adds new characters.
const BASE_GAME_CHARACTER_IDS: Array = []

## Entry point called by the game's mod loader.
## mod_loader: the game's ModLoader instance (provides register_character API)
## mod_path: the path to the mod's root directory (extracted from zip)
## game_version: the currently running game version string
## Returns true if the mod loaded successfully, false if it was skipped.
static func load_mod(mod_loader: Object, mod_path: String, game_version: String) -> bool:
	# 1. Load and validate mod.json
	var metadata = _load_metadata(mod_path)
	if metadata == null:
		return false

	# 2. Validate metadata fields
	var validation = ModValidatorClass.validate_metadata(metadata)
	if not validation["valid"]:
		for error in validation["errors"]:
			push_error("ModLoader: " + error + " (mod: " + mod_path + ")")
		return false

	# 3. Check version compatibility
	var target_version: String = metadata.get("target_game_version", "")
	if target_version != game_version:
		push_warning(
			"ModLoader: version mismatch — mod targets %s but game is %s. " \
			+ "Showing warning dialog." % [target_version, game_version]
		)
		# Show warning dialog and wait for player choice.
		# If the mod loader provides a dialog API, use it; otherwise log and proceed.
		var proceed: bool = _show_version_mismatch_dialog(mod_loader, target_version, game_version)
		if not proceed:
			return false
		push_warning(
			"ModLoader: mod loaded under version mismatch: mod=%s game=%s" % [
				target_version, game_version
			]
		)

	# 4. Validate required assets exist
	if not _validate_assets(mod_path):
		return false

	# 5. Register characters
	var characters: Array = metadata.get("characters", [])
	for char_entry in characters:
		if not (char_entry is Dictionary):
			continue
		var char_id: String = char_entry.get("id", "")

		# Check for base game conflicts
		if BASE_GAME_CHARACTER_IDS.has(char_id):
			push_error(
				"ModLoader: character ID '%s' conflicts with a base game character. Skipping." % char_id
			)
			continue

		# Instantiate the character script
		var char_instance = _instantiate_character(char_id)
		if char_instance == null:
			push_error("ModLoader: failed to instantiate character '%s'. Skipping." % char_id)
			continue

		# Register with the game's mod loader
		if mod_loader != null and mod_loader.has_method("register_character"):
			mod_loader.register_character(char_id, char_instance)
		else:
			push_warning(
				"ModLoader: mod_loader does not expose register_character API. " \
				+ "Character '%s' may not appear on character select." % char_id
			)

	return true


## Loads and parses mod.json from the mod path.
## Returns the parsed Dictionary, or null on failure.
static func _load_metadata(mod_path: String) -> Dictionary:
	var json_path: String = mod_path.path_join("mod.json")
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("ModLoader: Missing mod.json in archive: " + mod_path)
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_error("ModLoader: mod.json is malformed or not a JSON object: " + json_path)
		return {}
	return parsed


## Validates that all required asset files exist in the mod directory.
## Returns true if all assets are present, false if any are missing.
static func _validate_assets(mod_path: String) -> bool:
	var all_present: bool = true
	for asset_path in REQUIRED_ASSETS:
		var full_path: String = mod_path.path_join(asset_path)
		if not FileAccess.file_exists(full_path):
			push_error(
				"ModLoader: Missing required asset '%s': %s" % [asset_path, full_path]
			)
			all_present = false
	return all_present


## Shows a version mismatch warning dialog.
## Returns true if the player chose to proceed, false to cancel.
static func _show_version_mismatch_dialog(
	mod_loader: Object,
	mod_version: String,
	game_version: String
) -> bool:
	# If the mod loader provides a dialog API, use it.
	if mod_loader != null and mod_loader.has_method("show_version_mismatch_dialog"):
		var choice = mod_loader.show_version_mismatch_dialog(mod_version, game_version)
		return choice == "proceed"
	# Fallback: log and proceed (no dialog available in this environment).
	push_warning(
		"ModLoader: No dialog API available. Proceeding despite version mismatch " \
		+ "(mod=%s, game=%s)." % [mod_version, game_version]
	)
	return true


## Instantiates the correct character class for the given character ID.
## Returns null if the ID is not recognized.
static func _instantiate_character(char_id: String) -> Object:
	match char_id:
		"malachar_the_undying":
			return MalacharCharacterClass.new()
		"seraphiel_the_radiant":
			return SeraphielCharacterClass.new()
		_:
			push_error("ModLoader: Unknown character ID '%s'." % char_id)
			return null
