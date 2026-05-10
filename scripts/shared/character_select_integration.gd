# character_select_integration.gd
# Handles character selection screen integration for mod characters.
# Called by the mod loader after characters are registered.
# Covers Requirements: 14.1–14.8

class_name CharacterSelectIntegration

const PLACEHOLDER_PORTRAIT_PATH: String = "res://assets/shared/portrait_placeholder.png"

## Registers both characters on the character select screen.
## char_select_screen: the game's character select screen node/object
## characters: Array of character script instances
static func register_on_select_screen(char_select_screen: Object, characters: Array) -> void:
	for character in characters:
		if char_select_screen != null and char_select_screen.has_method("add_character_entry"):
			char_select_screen.add_character_entry(character.get_character_id(), character)
		else:
			push_warning(
				"CharacterSelectIntegration: char_select_screen does not expose " \
				+ "add_character_entry API for character '%s'." % character.get_character_id()
			)


## Loads the portrait image for a character.
## Returns the loaded Texture2D, or a placeholder if loading fails.
## The character remains selectable regardless of portrait load result (Req 14.6).
static func load_portrait(portrait_path: String) -> Texture2D:
	if portrait_path == "" or not FileAccess.file_exists(portrait_path):
		push_warning(
			"CharacterSelectIntegration: Portrait not found at '%s'. Using placeholder." \
			% portrait_path
		)
		return _load_placeholder_portrait()
	var texture = load(portrait_path)
	if texture == null or not (texture is Texture2D):
		push_warning(
			"CharacterSelectIntegration: Failed to load portrait at '%s'. Using placeholder." \
			% portrait_path
		)
		return _load_placeholder_portrait()
	return texture


## Returns the name and lore description for hover display.
## Per Req 14.4/14.5: if either fails to load, returns null for BOTH (shown atomically).
## Returns a Dictionary with "name" and "lore" keys, or null if either is unavailable.
static func get_hover_info(character: Object) -> Dictionary:
	var char_name: String = ""
	var lore: String = ""

	# Attempt to load name
	if character.has_method("get_display_name"):
		char_name = character.get_display_name()

	# Attempt to load lore description
	if character.has_method("get_lore_description"):
		lore = character.get_lore_description()

	# If either is empty/failed, return null (show neither — Req 14.4, 14.5)
	if char_name == "" or lore == "":
		return {}

	# Enforce 80-char limit on lore
	if lore.length() > 80:
		lore = lore.substr(0, 80)

	return {
		"name": char_name,
		"lore": lore
	}


## Returns true if hover info should be displayed (both name and lore available).
static func should_show_hover_info(hover_info: Dictionary) -> bool:
	return hover_info.size() > 0 and hover_info.has("name") and hover_info.has("lore")


## Loads a placeholder portrait texture.
## Returns a minimal 128x128 grey texture if the placeholder file is also missing.
static func _load_placeholder_portrait() -> Texture2D:
	if FileAccess.file_exists(PLACEHOLDER_PORTRAIT_PATH):
		var tex = load(PLACEHOLDER_PORTRAIT_PATH)
		if tex is Texture2D:
			return tex
	# Fallback: create a minimal ImageTexture as placeholder
	var img = Image.create(128, 128, false, Image.FORMAT_RGB8)
	img.fill(Color(0.5, 0.5, 0.5))  # grey placeholder
	return ImageTexture.create_from_image(img)
