class_name MoveData
extends Resource

# Identity
var move_id: String = ""
var display_name: String = ""

# Frame data
var startup_frames: int = 0
var active_frames: int = 0
var recovery_frames: int = 0

# Damage
var base_damage: int = 0
var smite_bonus: int = 0
var life_steal_pct: float = 0.0
var life_steal_cap: int = 80

# Range (units; -1 = full-screen)
var range_min: float = 0.0
var range_max: float = 0.0

# Resource costs / gains
var blood_meter_cost: int = 0
var blood_drain_value: int = 0
var radiance_meter_cost: int = 0
var radiance_value: int = 0

# Property flags
var has_life_steal: bool = false
var has_holy: bool = false
var has_smite: bool = false
var has_drain: bool = false
var has_armor: bool = false
var is_movement_only: bool = false
var applies_hypnosis: bool = false
var applies_blind: bool = false

# Projectile data
var projectile_count: int = 0
var projectile_homing: bool = false

# Hitbox list
var hitboxes: Array = []

# Audio cue key
var audio_cue_key: String = ""

func serialize() -> Dictionary:
	return {
		"move_id": move_id,
		"display_name": display_name,
		"startup_frames": startup_frames,
		"active_frames": active_frames,
		"recovery_frames": recovery_frames,
		"base_damage": base_damage,
		"smite_bonus": smite_bonus,
		"life_steal_pct": life_steal_pct,
		"life_steal_cap": life_steal_cap,
		"range_min": range_min,
		"range_max": range_max,
		"blood_meter_cost": blood_meter_cost,
		"blood_drain_value": blood_drain_value,
		"radiance_meter_cost": radiance_meter_cost,
		"radiance_value": radiance_value,
		"has_life_steal": has_life_steal,
		"has_holy": has_holy,
		"has_smite": has_smite,
		"has_drain": has_drain,
		"has_armor": has_armor,
		"is_movement_only": is_movement_only,
		"applies_hypnosis": applies_hypnosis,
		"applies_blind": applies_blind,
		"projectile_count": projectile_count,
		"projectile_homing": projectile_homing,
		"audio_cue_key": audio_cue_key
	}

static func deserialize(data: Dictionary) -> MoveData:
	var m := MoveData.new()
	m.move_id = data.get("move_id", "")
	m.display_name = data.get("display_name", "")
	m.startup_frames = data.get("startup_frames", 0)
	m.active_frames = data.get("active_frames", 0)
	m.recovery_frames = data.get("recovery_frames", 0)
	m.base_damage = data.get("base_damage", 0)
	m.smite_bonus = data.get("smite_bonus", 0)
	m.life_steal_pct = data.get("life_steal_pct", 0.0)
	m.life_steal_cap = data.get("life_steal_cap", 80)
	m.range_min = data.get("range_min", 0.0)
	m.range_max = data.get("range_max", 0.0)
	m.blood_meter_cost = data.get("blood_meter_cost", 0)
	m.blood_drain_value = data.get("blood_drain_value", 0)
	m.radiance_meter_cost = data.get("radiance_meter_cost", 0)
	m.radiance_value = data.get("radiance_value", 0)
	m.has_life_steal = data.get("has_life_steal", false)
	m.has_holy = data.get("has_holy", false)
	m.has_smite = data.get("has_smite", false)
	m.has_drain = data.get("has_drain", false)
	m.has_armor = data.get("has_armor", false)
	m.is_movement_only = data.get("is_movement_only", false)
	m.applies_hypnosis = data.get("applies_hypnosis", false)
	m.applies_blind = data.get("applies_blind", false)
	m.projectile_count = data.get("projectile_count", 0)
	m.projectile_homing = data.get("projectile_homing", false)
	m.audio_cue_key = data.get("audio_cue_key", "")
	return m
