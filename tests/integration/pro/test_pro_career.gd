extends RefCounted
## Modo carreira de jogador (src/pro_career.gd): peneira → propostas → temporada → fim de temporada → próxima.


func run(t) -> void:
	if not DataPack.loaded():
		DataPack.import_zip("res://datapack.zip")
	Game.rng.seed = 2026
	var prof := Pro.new_profile()
	prof["name"] = "Teste Craque"
	prof["pos"] = "AC"
	Pro.start(8, prof)
	t.check(Pro.is_pro() and Pro.P()["stage"] == "peneira", "carreira começa na peneira")
	var mt := Game.next_user_match()
	t.check(mt.get("kind", "") == "trial", "próxima partida é o jogo festivo")
	t.check(Pro.me()["id"] in Game.club(Game.S["club"])["xi"], "seu jogador é titular na peneira")
	Game.play_next(null)
	t.check(Pro.P()["stage"] == "propostas", "depois da peneira vêm as propostas")
	t.check(not Pro.P()["offers"].is_empty(), "pelo menos uma proposta", "%d proposta(s), nota %.1f" % [Pro.P()["offers"].size(), Pro.P()["last"]["rating"]])
	t.check(not Pro.P()["feed"].is_empty(), "a rede social comenta a peneira")
	var o: Dictionary = Pro.P()["offers"][0]
	Pro.accept(0)
	t.check(Pro.P()["stage"] == "carreira" and Game.S["club"] == int(o["ci"]) and int(Game.S["league"]) == int(o["li"]), "assinou com o clube da proposta", o["name"])
	t.check(Pro.me()["club"] == Game.S["club"] and Pro.me().get("me", false), "jogador está no elenco do novo clube")
	Pro.hire("ze")
	t.check(Pro.agent_level() == 1, "contratou empresário")
	var games := 0
	var played := 0
	var guard := 0
	var replies := 0
	var lost_me := false
	while not Game.S["season_over"] and guard < 120:
		guard += 1
		if Game.next_user_match().is_empty():
			break
		Game.play_next(null)
		games += 1
		if float(Pro.P()["last"]["rating"]) >= 0.0:
			played += 1
		if Pro.me().is_empty() or Pro.me()["club"] != Game.S["club"]:
			lost_me = true
		for post_d in Pro.P()["feed"]:
			if Pro.can_reply(post_d) and post_d["kind"] == "xingamento" and replies < 6:
				Pro.reply(int(post_d["id"]), ["humilde", "provocar", "xingar"][replies % 3])
				replies += 1
				break
	t.check(Game.S["season_over"], "temporada de jogador termina", "%d jogos do clube, jogou %d" % [games, played])
	t.check(not lost_me, "o jogador nunca é vendido nem dispensado pela máquina")
	t.check(played > 0, "o técnico te coloca para jogar", "%d jogos, média %.2f" % [played, Pro.avg_rating()])
	t.check(Pro.avg_rating() > 4.5 and Pro.avg_rating() < 8.5, "notas numa faixa realista", "%.2f" % Pro.avg_rating())
	t.check(float(Pro.P()["money"]) > 0.0, "recebeu salário", Game.money(float(Pro.P()["money"])))
	t.check(replies > 0, "respondeu torcedores", "%d respostas" % replies)
	var rep := Pro.close_season()
	t.check(rep.has("avg") and Pro.P()["history"].size() == 1, "fim de temporada gera histórico")
	var age0: int = Pro.me()["age"]
	if Pro.P()["stage"] == "livre":
		Pro.accept(0)
	else:
		Pro.next_season()
	t.check(Pro.is_pro() and int(Pro.me()["age"]) == age0 + 1 and not Game.S["season_over"], "nova temporada começa com o jogador um ano mais velho")
	t.check(Pro.me()["club"] == Game.S["club"], "jogador continua num clube")
	Game.delete_save(8)
	Game.S = {}
