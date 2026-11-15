extends Node
## Medição de custo por quadro do LanceView e do FieldView: _process e _draw (µs).
## Rodar: godot --headless --path . res://tests/bench_draw.tscn
## (com --rendering-driver opengl3 sob xvfb também mostra draw calls por quadro)

const SUITE := "res://tests/integration/match/test_match_balance.gd"


class LanceBench extends LanceView:
	var draw_us: int = 0
	var draws: int = 0
	func _draw() -> void:
		var t0 := Time.get_ticks_usec()
		super()
		draw_us += Time.get_ticks_usec() - t0
		draws += 1


class FieldBench extends FieldView:
	var draw_us: int = 0
	var draws: int = 0
	func _draw() -> void:
		var t0 := Time.get_ticks_usec()
		super()
		draw_us += Time.get_ticks_usec() - t0
		draws += 1


func _ready() -> void:
	var suite = load(SUITE).new()
	Game.rng.seed = 4321
	var coach = {"name": "Teste", "age": 35, "nat": "Brasil", "skin": 1, "hair": 0, "haircolor": 0, "beard": 0, "suit": 0, "rep": 5.0}
	Game.new_career(8, coach, 2, 0)
	var dt := 1.0 / 60.0
	var quick: bool = "--quick" in OS.get_cmdline_user_args()
	# ---- lances
	var proc_us := 0
	var frames := 0
	var ldraw := 0
	var lcount := 0
	var dcalls := 0
	var dframes := 0
	for k in (4 if quick else 30):
		var sim := MatchSim.new(Game.S["club"], (Game.S["club"] + 1 + k % 19) % 20)
		sim.minute = 30
		sim.pending = {"side": 0, "pg": 0.3}
		var lv := LanceBench.new()
		lv.size = Vector2(1280, 720)
		lv.set_process(false)
		add_child(lv)
		lv.size = Vector2(1280, 720)
		lv.setup(sim, k % 2, k % 3 != 0)
		var guard := 0
		var dec := 0
		while lv.state != "done" and guard < 2000:
			guard += 1
			if lv.state == "decide" and lv.user_ctrl:
				dec += 1
				if dec > 20:   # alguns quadros na tela de decisão (cinza)
					suite._auto_play(lv)
					dec = 0
			var t0 := Time.get_ticks_usec()
			lv._process(dt)
			proc_us += Time.get_ticks_usec() - t0
			frames += 1
			await get_tree().process_frame
			var dc := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			if dc > 0:
				dcalls += dc
				dframes += 1
		ldraw += lv.draw_us
		lcount += lv.draws
		lv.queue_free()
	print("LANCE  process %.0f µs/quadro | draw %.0f µs/quadro (%d desenhos) | draw calls %.0f/quadro" % [
		proc_us / float(frames), ldraw / float(maxi(lcount, 1)), lcount, dcalls / float(maxi(dframes, 1))])
	# ---- campo ao vivo
	var sim2 := MatchSim.new(0, 1)
	var fv := FieldBench.new()
	fv.set_process(false)
	add_child(fv)
	fv.size = Vector2(1280, 720)
	fv.setup_field(sim2)
	var fproc := 0
	var ff := 0
	dcalls = 0
	dframes = 0
	var acc := 0.0
	for i in (400 if quick else 1800):
		acc += dt
		if acc >= 1.0 and not sim2.finished:
			acc -= 1.0
			for e in sim2.step():
				if e["type"] == "chance":
					fv.show_chance(e["side"])
				elif e["type"] == "goal":
					fv.kickoff(1 - e["side"])
			fv.feed_minute(sim2.last_side)
		var t1 := Time.get_ticks_usec()
		fv._process(dt)
		fproc += Time.get_ticks_usec() - t1
		ff += 1
		await get_tree().process_frame
		var dc2 := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		if dc2 > 0:
			dcalls += dc2
			dframes += 1
	print("CAMPO  process %.0f µs/quadro | draw %.0f µs/quadro (%d desenhos) | draw calls %.0f/quadro" % [
		fproc / float(ff), fv.draw_us / float(maxi(fv.draws, 1)), fv.draws, dcalls / float(maxi(dframes, 1))])
	fv.queue_free()
	Game.delete_save(8)
	get_tree().quit()
