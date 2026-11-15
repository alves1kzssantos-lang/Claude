extends RefCounted
## Testes das regras do árbitro (src/referee.gd).


func run(t) -> void:
	# defensores: goleiro em 1 m, zaga em 18 m
	var defs := [1.0, 18.0, 18.5, 19.0, 25.0]
	t.check(Referee.offside_line(defs, 30.0) == 18.0, "linha = penúltimo defensor")
	t.check(Referee.is_offside(Vector2(0, 15), Vector2(0, 30), defs), "atacante atrás da zaga está impedido")
	t.check(not Referee.is_offside(Vector2(0, 18.1), Vector2(0, 30), defs), "na mesma linha não está impedido")
	t.check(not Referee.is_offside(Vector2(0, 15), Vector2(0, 14), defs), "atrás da bola não está impedido")
	t.check(not Referee.is_offside(Vector2(0, 55), Vector2(0, 60), [1.0, 58.0]), "no próprio campo não está impedido")
	t.check(Referee.in_box(Vector2(10, 10)), "dentro da área")
	t.check(not Referee.in_box(Vector2(21, 10)), "fora da área (lado)")
	t.check(not Referee.in_box(Vector2(0, 17)), "fora da área (frente)")

	# faltas na área viram pênalti; longe e com bola, às vezes vantagem
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ref := Referee.new(rng)
	t.check(ref.restart_for_foul(Vector2(0, 12), true) == "penalti", "falta na área = pênalti")
	var adv := 0
	var direct := 0
	for i in 400:
		var r1 := ref.restart_for_foul(Vector2(0, 40), true)
		if r1 == "vantagem":
			adv += 1
		if ref.restart_for_foul(Vector2(0, 25), false) == "falta_direta":
			direct += 1
	t.check(adv > 90 and adv < 200, "vantagem acontece às vezes", "%d de 400" % adv)
	t.check(direct == 400, "falta perto da área sem vantagem = falta direta")
	var cards := {"": 0, "amarelo": 0, "vermelho": 0}
	for i in 2000:
		cards[ref.card_for_foul()] += 1
	t.check(cards["amarelo"] > 300 and cards["amarelo"] < 600, "amarelos por falta", str(cards))
	t.check(cards["vermelho"] > 2 and cards["vermelho"] < 30, "vermelhos diretos raros", str(cards))
