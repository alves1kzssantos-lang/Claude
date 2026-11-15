extends Node
var main
var suite
var n := 0
func wait(sec): await get_tree().create_timer(sec).timeout
func shot(name):
	await RenderingServer.frame_post_draw
	n += 1
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://production/qa/evidence/") + "campo_%02d_%s.png" % [n, name])
func _ready():
	Game.delete_save(0)
	suite = load("res://tests/integration/match/test_match_balance.gd").new()
	Game.rng.seed = 4242
	main = load("res://main.tscn").instantiate()
	add_child(main)
	while not DataPack.loaded(): await get_tree().process_frame
	var coach = {"name":"Alves","age":35,"nat":"Brasil","skin":2,"hair":1,"haircolor":0,"beard":1,"suit":0,"rep":5.0}
	Game.new_career(0, coach, 3, 0)
	main.home(); await wait(1.0)
	main.go("match"); await wait(1.5)
	var mv = main.body.get_child(0)
	mv._start()
	var t_live := 0.0
	var shots_taken := 0
	while mv.state == "live" and t_live < 55.0:
		await get_tree().process_frame
		var L = mv.lance
		if L != null and is_instance_valid(L):
			if L.user_ctrl:
				while is_instance_valid(L) and L.state != "end" and L.state != "done":
					if L.state == "decide":
						await wait(1.1)
						if is_instance_valid(L) and L.state == "decide":
							var c = L.att[L.carrier]
							if not L.shot_only and c.pos.y > 17.0 and L.moments < 2: suite._auto_play(L)
							else: L._do_shot(2.6 if L.gk.pos.x <= 0.0 else -2.6, 0.7, 0.55)
					await get_tree().process_frame
			while mv.lance != null: await get_tree().process_frame
			continue
		t_live += get_process_delta_time()
		if shots_taken < 4 and int(t_live) in [6, 18, 30, 44] and int(t_live) != int(t_live - get_process_delta_time()):
			shots_taken += 1
			await shot("ao_vivo")
	mv._on_pause(); await wait(1.2); await shot("pausa")
	main.close_modal(); mv._to_end(); await wait(0.8)
	mv._finish(); await wait(2.0)
	print("MOVIE DONE ", mv.sim.score)
	Game.delete_save(0)
	get_tree().quit()
