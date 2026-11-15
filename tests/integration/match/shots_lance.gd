extends Node
## Capturas do lance perto do gol (gol em cima): decisão, chute com o goleiro no pulo e gol.
## Também compara o FieldView com o desenho antigo, se res://tmp_cmp/ existir (só na verificação).
## Rodar com tela: xvfb-run ... godot --path . --rendering-driver opengl3 res://tests/shots_lance.tscn
var n := 0

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	n += 1
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://production/qa/evidence/") + "camlance_%02d_%s.png" % [n, name])


func _ready() -> void:
	Game.rng.seed = 7
	var coach = {"name": "Teste", "age": 35, "nat": "Brasil", "skin": 1, "hair": 0, "haircolor": 0, "beard": 0, "suit": 0, "rep": 5.0}
	Game.new_career(8, coach, 2, 0)
	var sim := MatchSim.new(Game.S["club"], (Game.S["club"] + 3) % 20)
	sim.minute = 30
	sim.pending = {"side": 0, "pg": 0.3}
	var lv := LanceView.new()
	lv.size = Vector2(1280, 720)
	add_child(lv)
	lv.setup(sim, 0, true)
	lv.set_process(false)
	# carrega a bola até a entrada da área
	var guard := 0
	while guard < 600:
		guard += 1
		if lv.state == "decide":
			var c: Dictionary = lv.att[lv.carrier]
			if c["pos"].y > 19.0 and lv.moments < 3:
				lv._start_run(0.9)
			else:
				break
		lv._process(1.0 / 60.0)
	for i in 90:   # câmera assenta
		lv._process(0.0001)
		lv.cam_y = lerpf(lv.cam_y, lv.cam_y, 1.0)
	for i in 60:
		lv.t = 0.0
		lv._process(1.0 / 60.0)
	await get_tree().process_frame
	await shot("decisao_gol_em_cima")
	# chute no canto: o goleiro pula
	var corner := 2.6 if lv.gk["pos"].x <= 0.0 else -2.6
	lv._do_shot(corner, 1.2, 0.7)
	var got_dive := false
	guard = 0
	while lv.state != "done" and guard < 600:
		guard += 1
		lv._process(1.0 / 60.0)
		await get_tree().process_frame
		if not got_dive and absf(lv.gk_tilt) > 0.6:
			got_dive = true
			await shot("chute_goleiro_pula")
		if lv.state == "end" and lv.t > 0.35 and lv.t < 0.37:
			await shot("fim_" + str(lv.result.get("kind", "")))
	print("LANCE SHOTS: ", lv.result)
	lv.queue_free()
	await get_tree().process_frame
	# lance da máquina com roteiro de gol: a bola entra no gol de cima
	var sim2 := MatchSim.new(Game.S["club"], (Game.S["club"] + 5) % 20)
	sim2.minute = 60
	sim2.pending = {"side": 0, "pg": 0.3}
	var lv2 := LanceView.new()
	lv2.size = Vector2(1280, 720)
	add_child(lv2)
	lv2.setup(sim2, 0, false)
	lv2.script_kind = "goal"
	lv2.set_process(false)
	var got_net := false
	guard = 0
	while lv2.state != "done" and guard < 1500:
		guard += 1
		lv2._process(1.0 / 60.0)
		await get_tree().process_frame
		if not got_net and lv2.state == "end" and lv2.result.get("goal", false) and lv2.t > 0.3:
			got_net = true
			lv2.cel_t = 0.0   # mostra a bola na rede antes da comemoração
			await get_tree().process_frame
			await shot("gol_bola_na_rede")
		if lv2.cel_t > 0.7:
			await shot("gol_comemoracao")
			break
	print("GOL SHOTS: ", lv2.result)
	lv2.queue_free()
	await get_tree().process_frame
	if ResourceLoader.exists("res://tmp_cmp/old_field.gd"):
		await _compare_field()
	Game.delete_save(8)
	get_tree().quit()


func _compare_field() -> void:
	var sim := MatchSim.new(0, 1)
	var fv := FieldView.new()
	add_child(fv)
	fv.size = Vector2(1280, 720)
	fv.setup_field(sim)
	fv.set_process(false)
	for i in 400:
		fv._process(1.0 / 60.0)
	var old = load("res://tmp_cmp/old_field.gd").new()
	add_child(old)
	old.size = Vector2(1280, 720)
	old.set_process(false)
	for k in ["sim", "teams", "bp", "referee", "kits", "cam_x", "cam_y", "owner_side", "holder", "ball_state", "ads", "me_pid", "stage_label"]:
		old.set(k, fv.get(k))
	old.visible = false
	fv.queue_redraw()
	await shot("campo_novo")
	fv.visible = false
	old.visible = true
	old.queue_redraw()
	await shot("campo_antigo")
	var a: Image = Image.load_from_file(ProjectSettings.globalize_path("res://production/qa/evidence/") + "camlance_%02d_campo_novo.png" % (n - 1))
	var b: Image = Image.load_from_file(ProjectSettings.globalize_path("res://production/qa/evidence/") + "camlance_%02d_campo_antigo.png" % n)
	var diff := 0
	var big := 0
	for y in 720:
		for x in 1280:
			var d := a.get_pixel(x, y) - b.get_pixel(x, y)
			var m := maxf(absf(d.r), maxf(absf(d.g), absf(d.b)))
			if m > 0.004:
				diff += 1
			if m > 0.15:
				big += 1
	print("COMPARE campo: %d pixels diferentes (%.3f%%), %d com diferença forte" % [diff, 100.0 * diff / (1280.0 * 720.0), big])
