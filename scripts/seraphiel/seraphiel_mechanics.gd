class_name SeraphielMechanics

var radiance_meter: int = 0
const RADIANCE_METER_MAX: int = 100
var martyrs_grace_active: bool = false
var martyrs_grace_triggered: bool = false

func reset_for_match() -> void:
	radiance_meter = 0
	martyrs_grace_active = false
	martyrs_grace_triggered = false

func add_radiance(amount: int) -> void:
	radiance_meter = min(radiance_meter + amount, RADIANCE_METER_MAX)

func spend_radiance(amount: int) -> bool:
	if radiance_meter < amount:
		return false
	radiance_meter -= amount
	return true

func check_martyrs_grace(current_hp: int) -> void:
	if not martyrs_grace_triggered and current_hp <= 300:
		martyrs_grace_triggered = true
		martyrs_grace_active = true

func apply_martyrs_grace_multiplier(base_heal: int) -> int:
	if martyrs_grace_active:
		martyrs_grace_active = false
		return int(base_heal * 1.5)
	return base_heal

func is_empowered() -> bool:
	return radiance_meter >= 50

func calculate_smite_damage(move: MoveData, opponent_status_effects: Array) -> int:
	# Smite bonus applied exactly once regardless of how many effects are active
	if opponent_status_effects.size() > 0:
		return move.smite_bonus
	return 0
