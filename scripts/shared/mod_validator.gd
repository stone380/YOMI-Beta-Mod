# mod_validator.gd
# Validates mod.json metadata at load time.
# Covers Requirements: 1.2, 1.3, 1.4, 1.7

class_name ModValidator

const REQUIRED_FIELDS: Array = [
    "mod_name", "version", "author", "target_game_version",
    "characters", "audio", "changelog"
]

const CHARACTER_ID_REGEX: String = "^[a-zA-Z0-9_]{1,64}$"

## Validates the mod.json metadata dictionary.
## Returns a Dictionary with:
##   "valid": bool
##   "errors": Array of error strings (one per missing/invalid field)
static func validate_metadata(metadata: Dictionary) -> Dictionary:
    var errors: Array = []

    # Check all required fields are present and non-empty
    for field in REQUIRED_FIELDS:
        if not metadata.has(field):
            errors.append("Missing required field: '" + field + "'")
        elif metadata[field] == null:
            errors.append("Required field is null: '" + field + "'")
        elif metadata[field] is String and metadata[field].strip_edges() == "":
            errors.append("Required field is empty: '" + field + "'")
        elif metadata[field] is Array and metadata[field].size() == 0:
            errors.append("Required field is empty array: '" + field + "'")

    # Validate version format (MAJOR.MINOR.PATCH)
    if metadata.has("version") and metadata["version"] is String:
        var version_regex = RegEx.new()
        version_regex.compile("^\\d+\\.\\d+\\.\\d+$")
        if not version_regex.search(metadata["version"]):
            errors.append("Version field must be in MAJOR.MINOR.PATCH format, got: '" + metadata["version"] + "'")

    # Validate character IDs
    if metadata.has("characters") and metadata["characters"] is Array:
        var seen_ids: Array = []
        var id_regex = RegEx.new()
        id_regex.compile(CHARACTER_ID_REGEX)
        for char_entry in metadata["characters"]:
            if char_entry is Dictionary and char_entry.has("id"):
                var char_id: String = char_entry["id"]
                if not id_regex.search(char_id):
                    errors.append(
                        "Character ID '%s' is invalid. Must match [a-zA-Z0-9_]{1,64}." % char_id
                    )
                elif seen_ids.has(char_id):
                    errors.append("Duplicate character ID: '" + char_id + "'")
                else:
                    seen_ids.append(char_id)

    # Validate changelog entries
    if metadata.has("changelog") and metadata["changelog"] is Array:
        for i in range(metadata["changelog"].size()):
            var entry = metadata["changelog"][i]
            if not (entry is Dictionary):
                errors.append("Changelog entry %d is not a dictionary." % i)
                continue
            if not entry.has("version") or entry["version"] == "":
                errors.append("Changelog entry %d is missing 'version'." % i)
            if not entry.has("changes") or not (entry["changes"] is Array) or entry["changes"].size() == 0:
                errors.append("Changelog entry %d has no 'changes' items." % i)

    return {
        "valid": errors.size() == 0,
        "errors": errors
    }


## Validates a single character ID string.
## Returns true if valid, false if invalid.
static func validate_character_id(char_id: String) -> bool:
    var id_regex = RegEx.new()
    id_regex.compile(CHARACTER_ID_REGEX)
    return id_regex.search(char_id) != null
