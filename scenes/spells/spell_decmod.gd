class_name SpellDecrementAttribute extends Spell

enum Targets {
	MODULUS,
	FLOOR,
	HP,
	MOVES,
	SPELL_TARGET,
	SCORE,
	DAMAGE,
	BEST_SCORE,
}

var current_target = 0
var targets = [
	Targets.MODULUS,
	Targets.FLOOR,
	Targets.HP,
	Targets.MOVES,
	Targets.SPELL_TARGET,
	Targets.SCORE,
	Targets.DAMAGE,
	Targets.BEST_SCORE,
]

func change_spell_target(offset: int, modulus: int) -> void:
	current_target = posmod(current_target + offset, modulus)

func spell_name() -> String:
	match targets[current_target]:
		0:
			return "mo-"
		1:
			return "fl-"
		2:
			return "hp-"
		3:
			return "mv-"
		4:
			return "inv"
		5:
			return "sc-"
		6:
			return "at-"
		7:
			return "bs-"
		_:
			return "err"

func hover_text() -> String:
	match targets[current_target]:
		0:
			return "sub 1 from modulus"
		1:
			return "sub 1 from floor"
		2:
			return "sub 1 from hp"
		3:
			return "sub 1 from move"
		4:
			return "could not read memory at 0x04"
		5:
			return "sub 1 from score"
		6:
			return "sub 1 from attack"
		7:
			return "sub 1 from ??Ã??"
		_:
			return "target pointer out of bounds"

func use(run: Run, grid: Grid) -> void:
	if current_target > 7:
		var rand: Spell = SpellDatabase.get_random_spell()
		rand.visible = false
		rand.use(run, grid)
	else:
		match targets[current_target]:
			0:
				run.modulus -= 1
				run.clamp_run_stuff()
				grid.clamp_stuff(run.modulus)
			1:
				run.floor = posmod(run.floor - 1, run.modulus)
				run.next_floor(true)
			2:
				grid.player.hp = posmod(grid.player.hp - 1, run.modulus)
			3:
				grid.player.moves_to_restore = posmod(grid.player.moves_to_restore - 1, run.modulus)
				grid.player.moves = posmod(grid.player.moves - 1, run.modulus)
			4:
				return
			5:
				run.score = posmod(run.score - 1, run.modulus)
			6:
				grid.player.attack_power = posmod(grid.player.attack_power - 1, run.modulus)
			7:
				Save.best_score -= 1
			_:
				return
