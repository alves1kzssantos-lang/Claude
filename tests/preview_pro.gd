extends Node
## Gravação da prévia: modo carreira de jogador + partida com abertura da logo.
## xvfb-run ... --write-movie prev.avi --fixed-fps 30 res://tests/preview_pro.tscn
var main
var suite
var n := 0
func wait(sec): await get_tree().create_timer(sec).timeout
func shot(name):
	await RenderingServer.frame_post_draw
	n += 1
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://production/qa/evidence/") + "jogador_%02d_%s.png" % [n, name])

func play_match(live_sec: float, tag: String) -> void:
	main.go("match"); await wait(1.4)
	var mv = main.body.get_child(0)
	mv.speed = 2
	mv._start()
	await wait(1.3); await shot(tag + "_abertura")
	while mv.state == "intro": await get_tree().process_frame
	var t_live := 0.0
	var snapped := false
	while mv.state == "live" and t_live < live_sec:
		await get_tree().process_frame
		var L = mv.lance
		if L != null and is_instance_valid(L):
			var took := false
			while is_instance_valid(L) and L.state != "end" and L.state != "done":
				if L.state == "decide" and L.user_ctrl and int(L.att[L.carrier]["p"]["id"]) == L.me_pid:
					await wait(0.9)
					if not took:
						await shot(tag + "_lance"); took = true
					if is_instance_valid(L) and L.state == "decide":
						suite._auto_play(L)
				await get_tree().process_frame
			while mv.lance != null: await get_tree().process_frame
			continue
		t_live += get_process_delta_time()
		if not snapped and t_live > 4.0:
			snapped = true
			await shot(tag + "_campo")
	mv._to_end(); await wait(1.0)
	mv._finish(); await wait(3.0)
	await shot(tag + "_nota")

func _ready():
	Game.delete_save(3)
	suite = load("res://tests/integration/match/test_match_balance.gd").new()
	Game.rng.seed = 777
	main = load("res://main.tscn").instantiate()
	add_child(main)
	while not DataPack.loaded(): await get_tree().process_frame
	await wait(1.5); await shot("carreiras")
	var sp = main._keep[3]
	main.go("pro_create", {"slot": 3})
	sp.prof["name"] = "Alves Jr"
	sp.prof["pos"] = "PE"; sp.prof["num"] = 11
	main.refresh(); await wait(1.5); await shot("criar")
	for k in 3:
		sp.prof["hstyle"] = (int(sp.prof["hstyle"]) + 1) % 6
		sp.create_tab = 1
		main.refresh(); await wait(0.6)
	sp.prof["hstyle"] = 1; sp.prof["boots"] = 2
	main.refresh(); await wait(1.0); await shot("visual")
	sp._begin(); await wait(2.5); await shot("peneira")
	await play_match(22.0, "peneira")
	main.home(); await wait(2.5); await shot("propostas")
	# assina com a melhor proposta
	var offs: Array = Pro.P()["offers"]
	var bi := 0
	for i in offs.size():
		var ok_role: bool = offs[i]["role"] in ["titular", "rotacao"]
		var bi_role: bool = offs[bi]["role"] in ["titular", "rotacao"]
		if (ok_role and not bi_role) or (ok_role == bi_role and int(offs[i]["str"]) > int(offs[bi]["str"])): bi = i
	sp._accept(bi); await wait(2.5); await shot("hub_jogos")
	for t in [1, 2, 3, 4]:
		sp.tab = t; main.refresh(); await wait(2.2)
		await shot(["", "carreira", "rede_social", "empresario", "vida"][t])
		if t == 2:
			for post_d in Pro.P()["feed"]:
				if Pro.can_reply(post_d):
					main.toast(Pro.reply(int(post_d["id"]), "provocar")); main.refresh(); break
			await wait(2.0); await shot("resposta")
	sp.tab = 0; main.home(); await wait(1.0)
	await play_match(26.0, "liga")
	main.home(); sp.tab = 2; main.refresh(); await wait(2.5); await shot("feed_pos_jogo")
	print("PREVIEW DONE")
	Game.delete_save(3)
	get_tree().quit()
