class_name AudioLoader

var _manifest: Dictionary = {}
var _cache: Dictionary = {}
var _fallback_stream: AudioStream = null

func load_manifest(manifest_path: String) -> void:
	var file = FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		push_warning("AudioLoader: manifest not found at " + manifest_path)
		return
	var text = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_warning("AudioLoader: failed to parse manifest at " + manifest_path)
		return
	_manifest = parsed

func get_audio_stream(cue_key: String) -> AudioStream:
	if _cache.has(cue_key):
		return _cache[cue_key]
	var path = _find_path(cue_key)
	if path == "":
		return _load_fallback()
	if not FileAccess.file_exists(path):
		push_warning("AudioLoader: audio file not found: " + path)
		return _load_fallback()
	var stream = load(path)
	if stream == null or not stream is AudioStream:
		push_warning("AudioLoader: failed to load audio stream: " + path)
		return _load_fallback()
	_cache[cue_key] = stream
	return stream

func _find_path(cue_key: String) -> String:
	for section in _manifest.values():
		if section is Dictionary and section.has(cue_key):
			return section[cue_key]
	return ""

func _load_fallback() -> AudioStream:
	if _fallback_stream != null:
		return _fallback_stream
	# Return a silent placeholder AudioStreamWAV as fallback
	var wav = AudioStreamWAV.new()
	wav.data = PackedByteArray()
	_fallback_stream = wav
	return _fallback_stream
