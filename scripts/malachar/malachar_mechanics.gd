class_name MalacharMechanics

var blood_meter: int = 0
const BLOOD_METER_MAX: int = 100
var desperate_hunger_active: bool = false
var desperate_hunger_triggered: bool = false

func reset_for_match() -> void:
	blood_meter = 0
	desperate_hunger_active = false
	desperate_hunger_triggered = false

func add_blood(amount: int) -> void:
	blood_meter = min(blood_meter + amount, BLOOD_METER_MAX)

func spend_blood(amount: int) -> bool:
	if blood_meter < amount:
		return false
	blood_meter -= amount
	return true

func apply_life_steal(raw_damage: int, life_steal_pct: float, cap: int) -> int:
	var restored = int(raw_damage * life_steal_pct)
	return min(restored, cap)

func check_desperate_hunger(current_hp: int) -> void:
	if not desperate_hunger_triggered and current_hp <= 200:
		desperate_hunger_triggered = true
		desperate_hunger_active = true

func is_empowered() -> bool:
	return blood_meter >= 50

func apply_hypnosis(opponent_state: Object) -> void:
	# Sets hypnotized flag to 1 — refreshes if already set (no stacking)
	if opponent_state != null and opponent_state.has_method("set_hypnotized"):
		opponent_state.set_hypnotized(true)
	elif opponent_state != null:
		opponent_state.set("hypnotized", true)
		opponent_state.set("hypnotized_count", 1)

func resolve_hypnosis(opponent_state: Object) -> String:
	var last_move: String = ""
	if opponent_state != null:
		last_move = opponent_state.get("last_move_id") if opponent_state.get("last_move_id") != null else ""
		opponent_state.set("hypnotized", false)
		opponent_state.set("hypnotized_count", 0)
	if last_move == "":
		return "idle"
	return last_move
