class_name SpellIncrementAttribute extends Spell

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
	print("new target")
	current_target = posmod(current_target + offset, modulus)

func spell_name() -> String:
	match targets[current_target]:
		0:
			return "mo+"
		1:
			return "fl+"
		2:
			return "hp+"
		3:
			return "mv+"
		4:
			return "inv"
		5:
			return "sc+"
		6:
			return "at+"
		7:
			return "bs+"
		_:
			return "err"

func hover_text() -> String:
	match targets[current_target]:
		0:
			return "add 1 to modulus"
		1:
			return "add 1 to floor"
		2:
			return "add 1 to hp"
		3:
			return "add 1 to move"
		4:
			return "could not read memory at 0x04"
		5:
			return "add 1 to score"
		6:
			return "add 1 to attack"
		7:
			return "add 1 to ??Ã??"
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
				run.modulus += 1
				run.clamp_run_stuff()
				grid.clamp_stuff(run.modulus)
			1:
				run.floor += 1
				run.floor %= run.modulus
				run.next_floor()
			2:
				grid.player.hp += 1
				grid.player.hp %= run.modulus
			3:
				grid.player.moves_to_restore += 1
				grid.player.moves_to_restore %= run.modulus
				
				grid.player.moves += 1
				grid.player.moves %= run.modulus
			4:
				return
			5:
				run.score += 1
				run.score %= run.modulus
			6:
				grid.player.attack_power += 1
				grid.player.attack_power %= run.modulus
			7:
				Save.best_score += 1
			_:
				return
