# visual_effects.gd
# Implements special visual effects for Malachar and Seraphiel.
# All methods are static helpers called by the scene layer.
# Covers Requirements: 3.6, 4.11, 6.4, 6.5, 8.5, 9.11, 10.5, 11.4, 11.5

class_name VisualEffects

# ---------------------------------------------------------------------------
# Malachar Effects
# ---------------------------------------------------------------------------

## Bat Form Dash opacity tween (Req 6.4):
## Tweens sprite alpha 1.0→0.0 over startup_frames, then 0.0→1.0 over recovery_frames.
## sprite: the character's Sprite2D node
## startup_frames: number of startup frames
## recovery_frames: number of recovery frames
## frame_duration: seconds per frame
static func bat_form_dash_opacity(
	sprite: Node,
	startup_frames: int,
	recovery_frames: int,
	frame_duration: float
) -> void:
	if sprite == null:
		return
	var tween = sprite.create_tween()
	var fade_out_time: float = startup_frames * frame_duration
	var fade_in_time: float = recovery_frames * frame_duration
	tween.tween_property(sprite, "modulate:a", 0.0, fade_out_time)
	tween.tween_property(sprite, "modulate:a", 1.0, fade_in_time)


## Lord of Bats screen darkening overlay (Req 6.5):
## Shows a full-screen ColorRect at ≤60% alpha during active frames.
## overlay: a ColorRect node covering the full viewport
## active_frames: number of active frames
## frame_duration: seconds per frame
static func lord_of_bats_overlay(
	overlay: Node,
	active_frames: int,
	frame_duration: float
) -> void:
	if overlay == null:
		return
	# Set color to black at 60% alpha (≤60% as required)
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.visible = true
	var active_duration: float = active_frames * frame_duration
	var tween = overlay.create_tween()
	tween.tween_interval(active_duration)
	tween.tween_callback(func(): overlay.visible = false)


## Blood Meter pulse overlay (Req 3.6):
## Starts or stops the blood_pulse AnimationPlayer animation based on empowered state.
## anim_player: the AnimationPlayer node on Malachar's sprite
## is_empowered: whether the Blood Meter is >= 50
static func update_blood_meter_pulse(anim_player: Node, is_empowered: bool) -> void:
	if anim_player == null:
		return
	if is_empowered:
		if not anim_player.is_playing() or anim_player.current_animation != "blood_pulse":
			anim_player.play("blood_pulse")
	else:
		if anim_player.current_animation == "blood_pulse":
			anim_player.stop()


## Hypnosis indicator (Req 5.6):
## Shows or hides the purple eye icon above the opponent's sprite.
## icon_node: the Sprite2D or TextureRect node for the hypnosis icon
## is_hypnotized: whether the opponent is currently hypnotized
static func update_hypnosis_indicator(icon_node: Node, is_hypnotized: bool) -> void:
	if icon_node == null:
		return
	icon_node.visible = is_hypnotized


# ---------------------------------------------------------------------------
# Seraphiel Effects
# ---------------------------------------------------------------------------

## Seraph's Judgment white flash overlay (Req 11.4):
## Shows a full-screen ColorRect at ≥90% alpha during active frames.
## overlay: a ColorRect node covering the full viewport
## active_frames: number of active frames
## frame_duration: seconds per frame
static func seraphs_judgment_flash(
	overlay: Node,
	active_frames: int,
	frame_duration: float
) -> void:
	if overlay == null:
		return
	# Set color to white at 90% alpha (≥90% as required)
	overlay.color = Color(1.0, 1.0, 1.0, 0.9)
	overlay.visible = true
	var active_duration: float = active_frames * frame_duration
	var tween = overlay.create_tween()
	tween.tween_interval(active_duration)
	tween.tween_callback(func(): overlay.visible = false)


## Healing particle effect (Req 11.5):
## Activates a CPUParticles2D node with ≥8 golden particles rising during recovery frames.
## particles: the CPUParticles2D node
## recovery_frames: number of recovery frames
## frame_duration: seconds per frame
static func healing_particles(
	particles: Node,
	recovery_frames: int,
	frame_duration: float
) -> void:
	if particles == null:
		return
	# Configure particle properties to ensure ≥8 particles, golden color, rising direction
	particles.amount = max(particles.amount, 8)
	particles.color = Color(1.0, 0.85, 0.0, 1.0)  # golden
	particles.direction = Vector2(0.0, -1.0)        # rising (upward in Godot 2D)
	particles.emitting = true
	var recovery_duration: float = recovery_frames * frame_duration
	var tween = particles.create_tween()
	tween.tween_interval(recovery_duration)
	tween.tween_callback(func(): particles.emitting = false)


## Radiance Meter glow overlay (Req 8.5):
## Starts or stops the radiance_glow AnimationPlayer animation based on empowered state.
## anim_player: the AnimationPlayer node on Seraphiel's sprite
## is_empowered: whether the Radiance Meter is >= 50
static func update_radiance_glow(anim_player: Node, is_empowered: bool) -> void:
	if anim_player == null:
		return
	if is_empowered:
		if not anim_player.is_playing() or anim_player.current_animation != "radiance_glow":
			anim_player.play("radiance_glow")
	else:
		if anim_player.current_animation == "radiance_glow":
			anim_player.stop()


## Smite golden flash (Req 10.5):
## Tweens the opponent's sprite modulate to gold and back over 8–12 frames.
## opponent_sprite: the opponent's Sprite2D node
## frame_duration: seconds per frame
## flash_frames: number of frames for the flash (must be 8–12)
static func smite_golden_flash(
	opponent_sprite: Node,
	frame_duration: float,
	flash_frames: int = 10
) -> void:
	if opponent_sprite == null:
		return
	# Clamp flash_frames to 8–12 range
	flash_frames = clamp(flash_frames, 8, 12)
	var flash_duration: float = flash_frames * frame_duration
	var half_duration: float = flash_duration * 0.5
	var tween = opponent_sprite.create_tween()
	tween.tween_property(
		opponent_sprite, "modulate",
		Color(1.0, 0.85, 0.0, 1.0),  # gold
		half_duration
	)
	tween.tween_property(
		opponent_sprite, "modulate",
		Color(1.0, 1.0, 1.0, 1.0),  # back to normal
		half_duration
	)
