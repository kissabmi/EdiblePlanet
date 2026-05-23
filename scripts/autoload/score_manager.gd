## ScoreManager — handles all scoring, combos, penalties
extends Node

var score: int = 0
var combo_count: int = 0
var combo_multiplier: float = 1.0
var combo_timer: float = 0.0
var combo_timeout: float = 3.0
var max_multiplier: float = 8.0
var total_eaten: int = 0
var total_poisoned: int = 0
var total_combos: int = 0
var max_combo_chain: int = 0
var vortex_count: int = 0
var bonuses_collected: int = 0

var poison_freeze_timer: float = 0.0
var mouth_closed_timer: float = 0.0

signal score_changed(new_score: int)
signal combo_changed(multiplier: float, count: int)
signal combo_expired()
signal food_eaten(food_type: String, points: int, position: Vector2)
signal poison_hit(poison_type: String, penalty: int, position: Vector2)

func _process(delta: float) -> void:
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
			combo_multiplier = 1.0
			combo_expired.emit()
	if poison_freeze_timer > 0:
		poison_freeze_timer -= delta
	if mouth_closed_timer > 0:
		mouth_closed_timer -= delta

func add_score(points: int, pos: Vector2, is_combo: bool = false) -> void:
	if poison_freeze_timer > 0:
		return
	var actual_points: int = int(points * combo_multiplier)
	score += actual_points
	total_eaten += 1
	score_changed.emit(score)
	food_eaten.emit("", actual_points, pos)

func register_combo(pos: Vector2) -> void:
	combo_count += 1
	total_combos += 1
	if combo_count > max_combo_chain:
		max_combo_chain = combo_count
	combo_multiplier = minf(1.0 + combo_count * 1.0, max_multiplier)
	combo_timer = combo_timeout
	combo_changed.emit(combo_multiplier, combo_count)

func register_vortex() -> void:
	vortex_count += 1

func apply_poison(penalty: int, poison_type: String, pos: Vector2) -> void:
	if poison_freeze_timer > 0:
		return
	score = maxf(0, score + penalty)  # penalty is negative
	total_poisoned += 1
	score_changed.emit(score)
	poison_hit.emit(poison_type, penalty, pos)
	# Reset combo on poison
	combo_count = 0
	combo_multiplier = 1.0
	combo_timer = 0.0
	combo_expired.emit()

func apply_freeze(duration: float) -> void:
	poison_freeze_timer = duration

func close_mouth(duration: float) -> void:
	mouth_closed_timer = duration

func is_mouth_closed() -> bool:
	return mouth_closed_timer > 0

func add_bonus() -> void:
	bonuses_collected += 1

func reset() -> void:
	score = 0
	combo_count = 0
	combo_multiplier = 1.0
	combo_timer = 0.0
	total_eaten = 0
	total_poisoned = 0
	total_combos = 0
	max_combo_chain = 0
	vortex_count = 0
	bonuses_collected = 0
	poison_freeze_timer = 0.0
	mouth_closed_timer = 0.0
	score_changed.emit(0)

func get_stats() -> Dictionary:
	return {
		"score": score,
		"eaten": total_eaten,
		"poisoned": total_poisoned,
		"combos": total_combos,
		"max_combo": max_combo_chain,
		"vortexes": vortex_count,
		"bonuses": bonuses_collected
	}
