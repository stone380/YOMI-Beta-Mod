# audio_wiring.gd
# Documents the audio cue wiring architecture for the mod.
# This is a reference/documentation file — not instantiated directly.
# Covers Requirements: 13.1–13.5
#
# Audio Wiring Architecture:
#
# 1. MOVE AUDIO CUES:
#    - Each MoveData has an audio_cue_key field (e.g., "claw_swipe")
#    - On hit_landed: character script calls _play_audio_cue(move.audio_cue_key)
#    - _play_audio_cue() calls AudioLoader.get_audio_stream(cue_key)
#    - AudioLoader looks up the path in audio_manifest.json
#    - If the file exists and is a valid AudioStream, it is played
#    - If missing/corrupt/unsupported: AudioLoader returns a silent fallback AudioStreamWAV
#    - No exception is raised in any failure case (Req 13.4)
#
# 2. EMPOWERED STATE AUDIO CUES:
#    - Malachar: "blood_meter_pulse" plays when Blood Meter crosses 50 threshold
#    - Seraphiel: "radiance_meter_glow" plays when Radiance Meter crosses 50 threshold
#    - Tracked via _was_empowered flag in each character script
#    - Same fallback behavior as move audio cues
#
# 3. AUDIO FILE REQUIREMENTS (Req 13.5):
#    - Format: OGG Vorbis (.ogg) or WAV (.wav)
#    - Sample rate: 22050 Hz to 48000 Hz
#    - Channels: mono or stereo
#    - Max file size: 5 MB per file
#
# 4. FALLBACK CHAIN:
#    - Missing cue key in manifest → silent AudioStreamWAV
#    - File not found → silent AudioStreamWAV
#    - File not a valid AudioStream → silent AudioStreamWAV
#    - No AudioStreamPlayer node in scene → cue silently skipped

class_name AudioWiring
