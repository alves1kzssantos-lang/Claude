extends RefCounted
## Testes da física da bola (src/ball_physics.gd).


func run(t) -> void:
	# passe rasteiro para e não anda para trás
	var b := BallPhysics.new()
	b.place(Vector2(0, 40))
	b.kick_ground(Vector2(0, 20), 18.0)
	var last_y := 40.0
	var back := false
	for i in 600:
		b.step(1.0 / 60.0)
		if b.pos.y > last_y + 0.0001:
			back = true
		last_y = b.pos.y
	t.check(not back, "rasteiro anda só para frente")
	t.check(b.speed() < 0.01, "rasteiro para sozinho", "vel %.3f" % b.speed())
	t.check(not b.in_air(), "rasteiro fica no chão")

	# passe alto cai perto do alvo
	for target in [Vector2(10, 25), Vector2(-18, 12), Vector2(0, 5)]:
		b.place(Vector2(0, 40))
		var tt := b.kick_lofted(target, 4.0)
		var landed := Vector2.ZERO
		var top := 0.0
		for i in 600:
			b.step(1.0 / 240.0)
			top = maxf(top, b.z)
			if b.z <= 0.0 and i > 5:
				landed = b.pos
				break
		var err := landed.distance_to(target)
		t.check(err < 1.6, "passe alto cai perto de %s" % target, "erro %.2f m, voo %.2f s" % [err, tt])
		t.check(absf(top - 4.0) < 0.5, "passe alto chega na altura pedida", "%.2f m" % top)

	# leitura da linha do gol
	t.check(BallPhysics.classify_crossing(0.0, 1.0) == "gol", "meio do gol = gol")
	t.check(BallPhysics.classify_crossing(2.0, 3.5) == "por_cima", "acima do travessão = por cima")
	t.check(BallPhysics.classify_crossing(6.0, 0.5) == "fora", "longe do poste = fora")
	t.check(BallPhysics.classify_crossing(3.66, 1.0) == "trave", "na linha do poste = trave")
	t.check(BallPhysics.classify_crossing(1.0, 2.44) == "travessao", "na altura do travessão = travessão")

	# previsão de cruzamento da linha bate com a simulação
	b.place(Vector2(2, 16))
	b.kick_shot(Vector2(0.5, 0) - Vector2(2, 16), 25.0, 2.0)
	var pred := b.goal_line_crossing()
	var real := {}
	for i in 600:
		var prev := b.pos
		var ph := b.z
		b.step(1.0 / 120.0)
		if b.pos.y <= 0.0:
			real = {"x": b.pos.x, "z": ph}
			break
	t.check(not pred.is_empty() and absf(pred["x"] - real["x"]) < 0.15 and absf(pred["z"] - real["z"]) < 0.25,
		"previsão do chute na linha do gol", "prev %s real %s" % [pred, real])
