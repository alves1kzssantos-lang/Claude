extends Node
## Executor de testes simples (sem plugin).
## Rodar: godot --headless --path . res://tests/run_tests.tscn
## Sai com código 0 se tudo passar, 1 se algo falhar.

const SUITES := [
	"res://tests/unit/physics/test_ball_physics.gd",
	"res://tests/unit/referee/test_referee.gd",
	"res://tests/integration/match/test_match_balance.gd",
	"res://tests/integration/match/test_field_view.gd",
	"res://tests/integration/cups/test_cups_season.gd",
	"res://tests/integration/pro/test_pro_career.gd",
]

var failed := 0
var passed := 0


func check(cond: bool, name: String, info: String = "") -> void:
	if cond:
		passed += 1
		print("  ok   ", name, ("  (" + info + ")") if info != "" else "")
	else:
		failed += 1
		print("  FALHOU ", name, ("  (" + info + ")") if info != "" else "")


func _ready() -> void:
	for path in SUITES:
		print("== ", path.get_file())
		var suite = load(path).new()
		await suite.run(self)
	print("\nRESULTADO: %d passaram, %d falharam" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
