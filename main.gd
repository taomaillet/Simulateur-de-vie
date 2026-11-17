extends Node3D

const PORT := 24567
const SPEED := 7.0
const PLAYER_SCRIPT = preload("res://player.gd")
var players: Dictionary = {}
var my_id := 1
var world_time := 10.0
var connected := false
var menu: Control
var status_label: Label
var ip_edit: LineEdit
var hud: Label
var sun: DirectionalLight3D
var environment: WorldEnvironment

func _ready() -> void:
	_build_world()
	_build_ui()
	_spawn_player(1)
	_set_mouse(false)

func _make_box(pos: Vector3, size: Vector3, color: Color, collision := true) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	if collision:
		var shape := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = size
		shape.shape = b
		body.add_child(shape)

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.53, 0.73, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.8, 0.9)
	env.ambient_light_energy = 0.7
	environment = WorldEnvironment.new()
	environment.environment = env
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 1.2
	add_child(sun)
	_make_box(Vector3(0,-0.6,0), Vector3(220,1,220), Color(0.24,0.51,0.28))
	for i in range(-2,3):
		_make_box(Vector3(i*32,0.01,0),Vector3(9,0.08,200),Color(0.16,0.17,0.19),false)
		_make_box(Vector3(0,0.015,i*32),Vector3(200,0.08,9),Color(0.16,0.17,0.19),false)
		for j in range(-9,10):
			_make_box(Vector3(i*32,0.065,j*10),Vector3(0.18,0.02,4),Color(0.95,0.88,0.56),false)
			_make_box(Vector3(j*10,0.065,i*32),Vector3(4,0.02,0.18),Color(0.95,0.88,0.56),false)
	var colors := [Color(0.75,0.74,0.7),Color(0.55,0.66,0.78),Color(0.79,0.6,0.49),Color(0.85,0.81,0.65)]
	for x in range(-2,2):
		for z in range(-2,2):
			for dx in [-10.0,10.0]:
				for dz in [-10.0,10.0]:
					var h := float(5 + posmod(abs(x*7+z*11+int(dx)+int(dz)), 4)*3)
					var p := Vector3(x*32+16+dx,h/2,z*32+16+dz)
					_make_box(p,Vector3(9,h,9),colors[posmod(x*3+z+int(dx),colors.size())])
					_make_box(p+Vector3(0,h/2+0.15,0),Vector3(9.5,0.3,9.5),Color(0.19,0.21,0.25))
					for level in range(1,int(h/3)+1):
						_make_box(Vector3(p.x,p.y-h/2+level*2.5,p.z+4.56),Vector3(5.5,1.1,0.08),Color(0.35,0.7,0.85),false)
	for x in range(-2,3):
		for z in range(-2,3):
			if (x+z)%2 == 0:
				_make_box(Vector3(x*32+7,1.5,z*32+7),Vector3(0.5,3,0.5),Color(0.38,0.25,0.13))
				_make_box(Vector3(x*32+7,4,z*32+7),Vector3(4,4,4),Color(0.13,0.43,0.17),false)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	menu = PanelContainer.new()
	menu.position = Vector2(18,18)
	menu.custom_minimum_size = Vector2(310,0)
	layer.add_child(menu)
	var column := VBoxContainer.new()
	menu.add_child(column)
	var title := Label.new()
	title.text = "REAL LIFE 3D  |  Version 0.3"
	column.add_child(title)
	var solo := Button.new()
	solo.text = "Jouer en solo"
	column.add_child(solo)
	solo.pressed.connect(_solo)
	var host := Button.new()
	host.text = "Heberger une partie (20 joueurs)"
	column.add_child(host)
	host.pressed.connect(_host)
	ip_edit = LineEdit.new()
	ip_edit.placeholder_text = "IP de ton ami (ex : 192.168.1.20)"
	column.add_child(ip_edit)
	var join := Button.new()
	join.text = "Rejoindre une partie"
	column.add_child(join)
	join.pressed.connect(_join)
	status_label = Label.new()
	status_label.text = "Choisis un mode de jeu."
	column.add_child(status_label)
	hud = Label.new()
	hud.position = Vector2(18,245)
	hud.add_theme_color_override("font_color",Color.WHITE)
	layer.add_child(hud)
	var help := Label.new()
	help.text = "ZQSD / WASD : marcher   |   Souris : camera   |   Espace : sauter   |   Echap : souris/menu"
	help.position = Vector2(18,680)
	help.add_theme_color_override("font_color",Color.WHITE)
	layer.add_child(help)

func _solo() -> void:
	menu.hide()
	connected = true
	_set_mouse(true)

func _host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT,20)
	if err != OK:
		status_label.text = "Impossible d'ouvrir le serveur : " + str(err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_peer_joined)
	multiplayer.peer_disconnected.connect(_peer_left)
	menu.hide()
	connected = true
	_set_mouse(true)

func _join() -> void:
	if ip_edit.text.strip_edges().is_empty():
		status_label.text = "Entre une adresse IP."
		return
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip_edit.text.strip_edges(),PORT)
	if err != OK:
		status_label.text = "Connexion impossible : " + str(err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_disconnected)
	status_label.text = "Connexion en cours..."

func _on_connected() -> void:
	my_id = multiplayer.get_unique_id()
	_spawn_player(my_id)
	menu.hide()
	connected = true
	_set_mouse(true)
	request_players.rpc_id(1)

func _on_failed() -> void:
	status_label.text = "Connexion echouee. Verifie l'IP et le pare-feu."

func _on_disconnected() -> void:
	connected = false
	menu.show()
	_set_mouse(false)
	status_label.text = "Serveur deconnecte. Relance le jeu pour rejouer."

func _peer_joined(id: int) -> void:
	_spawn_player(id)
	announce_player.rpc(id)

func _peer_left(id: int) -> void:
	if players.has(id):
		players[id].queue_free()
		players.erase(id)

@rpc("any_peer","reliable")
func request_players() -> void:
	if not multiplayer.is_server():
		return
	for id in players.keys():
		announce_player.rpc_id(multiplayer.get_remote_sender_id(),id)

@rpc("authority","call_remote","reliable")
func announce_player(id: int) -> void:
	_spawn_player(id)

func _spawn_player(id: int) -> void:
	if players.has(id):
		return
	var p := CharacterBody3D.new()
	p.name = "Player_" + str(id)
	p.set_script(PLAYER_SCRIPT)
	p.position = Vector3(0,2,float(players.size())*3)
	add_child(p)
	players[id] = p
	p.setup(id,id == my_id)

@rpc("any_peer","unreliable")
func sync_transform(id: int, pos: Vector3, yaw: float) -> void:
	if multiplayer.get_remote_sender_id() != id:
		return
	if players.has(id) and id != my_id:
		players[id].global_position = pos
		players[id].rotation.y = yaw
	if multiplayer.is_server():
		forward_transform.rpc(id,pos,yaw)

@rpc("authority","call_remote","unreliable")
func forward_transform(id: int, pos: Vector3, yaw: float) -> void:
	if id != my_id and players.has(id):
		players[id].global_position = pos
		players[id].rotation.y = yaw

func _process(delta: float) -> void:
	world_time = fmod(world_time + delta*0.015,24.0)
	var daylight := clampf(sin((world_time-6.0)/12.0*PI),0.08,1.0)
	sun.light_energy = daylight*1.3
	environment.environment.ambient_light_energy = 0.22+daylight*0.65
	environment.environment.background_color = Color(0.05,0.08,0.17).lerp(Color(0.53,0.73,0.95),daylight)
	hud.text = "Heure : %02d:%02d\nJoueurs : %d\nMode : %s" % [int(world_time),int(fmod(world_time*60.0,60.0)),players.size(),"En jeu" if connected else "Menu"]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_set_mouse(false)
			menu.show()
		else:
			menu.hide()
			_set_mouse(true)

func _set_mouse(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
