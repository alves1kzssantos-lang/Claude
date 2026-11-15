extends Node
## Capturas da partida (campo ao vivo, lance, comemoração) para production/qa/evidence/.
var main
var n := 0
func wait(sec): await get_tree().create_timer(sec).timeout
func shot(name):
	await RenderingServer.frame_post_draw
	n += 1
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://production/qa/evidence/") + "wsc_%02d_%s.png" % [n, name])
func _ready():
	var suite = load("res://tests/integration/match/test_match_balance.gd").new()
	Game.rng.seed = 99
	main = load("res://main.tscn").instantiate()
	add_child(main)
	while not DataPack.loaded() or DataPack.outdated(): await get_tree().process_frame
	print("pack ok"); await wait(0.5)
	var coach = {"name":"Alves","age":35,"nat":"Brasil","skin":2,"hair":1,"haircolor":0,"beard":1,"suit":0,"rep":5.0}
	Game.new_career(6, coach, 0, 0)
	main.home(); await wait(0.8); await shot("hub")
	main.go("match"); await wait(1.0)
	var mv = main.body.get_child(0)
	print("start"); mv._start(); await wait(1.4); await shot("abertura"); print("abertura ok")
	while mv.state == "intro": await get_tree().process_frame
	print("live"); await wait(3.0); await shot("campo"); print("campo ok")
	var got_lance := false
	var got_goal := false
	var guard := 0.0
	while mv.state == "live" and guard < 120.0 and not (got_lance and got_goal):
		await get_tree().process_frame
		guard += get_process_delta_time()
		if mv.field != null and mv.field.cel_t > 0.6 and not got_goal:
			got_goal = true
			await shot("gol_campo")
		var L = mv.lance
		if L != null and is_instance_valid(L):
			while is_instance_valid(L) and L.state != "done":
				if L.state == "decide" and L.user_ctrl:
					await wait(0.4)
					if not got_lance:
						got_lance = true
						await shot("lance_decisao")
					if is_instance_valid(L) and L.state == "decide":
						suite._auto_play(L)
				if is_instance_valid(L) and L.cel_t > 0.7 and not got_goal:
					got_goal = true
					await shot("gol_lance")
				await get_tree().process_frame
	print("SHOTS DONE lance=", got_lance, " gol=", got_goal)
	Game.delete_save(6)
	get_tree().quit()
