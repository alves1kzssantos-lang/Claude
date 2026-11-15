extends Node
## Gravação da prévia do modo técnico: hub, escalação real, abertura, partida, lance, gol e copa.
var main
func wait(sec): await get_tree().create_timer(sec).timeout
func _ready():
	var suite = load("res://tests/integration/match/test_match_balance.gd").new()
	Game.rng.seed = 2027
	main = load("res://main.tscn").instantiate()
	add_child(main)
	while not DataPack.loaded() or DataPack.outdated(): await get_tree().process_frame
	await wait(0.5)
	var coach = {"name":"Alves","age":35,"nat":"Brasil","skin":2,"hair":1,"haircolor":0,"beard":1,"suit":0,"rep":5.0}
	Game.new_career(5, coach, 0, 0)
	main.home(); await wait(2.5)
	main.go("squad"); await wait(2.5)
	main.home(); await wait(0.5)
	main.go("match"); await wait(2.0)
	var mv = main.body.get_child(0)
	mv.speed = 2
	mv._start()
	while mv.state == "intro": await get_tree().process_frame
	var t := 0.0
	var lances := 0
	while mv.state == "live" and t < 45.0 and lances < 3:
		await get_tree().process_frame
		t += get_process_delta_time()
		var L = mv.lance
		if L != null and is_instance_valid(L):
			lances += 1
			while is_instance_valid(L) and L.state != "done":
				if L.state == "decide" and L.user_ctrl:
					await wait(0.8)
					if is_instance_valid(L) and L.state == "decide":
						suite._auto_play(L)
				await get_tree().process_frame
			while mv.lance != null: await get_tree().process_frame
	mv._to_end(); await wait(1.0)
	mv._finish(); await wait(3.0)
	# avança até um jogo de copa e mostra a tela de resultados
	var g := 0
	while g < 40:
		g += 1
		var mt := Game.next_user_match()
		if mt.is_empty(): break
		Game.play_next(null)
		if Game.S["last_user"].get("kind", "") == "cup":
			main.go("cup_results", {"cup": Game.S["last_user"]["cup"], "stage": -1, "next": true}); await wait(3.5)
			main.go("cup", {"cup": Game.S["last_user"]["cup"], "next": false}); await wait(3.0)
			break
	main.home(); main.go("table"); await wait(2.5)
	print("PREVIEW DONE")
	Game.delete_save(5)
	get_tree().quit()
