extends CharacterBody3D

var player_id := 1
var local_player := false
var pivot: Node3D
var camera: Camera3D
var visual: Node3D
var send_accum := 0.0

func setup(id: int, is_local: bool) -> void:
	player_id = id
	local_player = is_local
	_build_avatar()
	if local_player:
		pivot = Node3D.new()
		pivot.position = Vector3(0,1.5,0)
		add_child(pivot)
		camera = Camera3D.new()
		camera.position = Vector3(0,2.3,6.5)
		camera.rotation_degrees.x = -12
		pivot.add_child(camera)
		camera.current = true

func _part(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	parent.add_child(mesh)

func _build_avatar() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.9
	shape.shape = capsule
	shape.position.y = 0.95
	add_child(shape)
	visual = Node3D.new()
	add_child(visual)
	var shirt := Color(0.18,0.45,0.85) if player_id == 1 else Color(0.9,0.28,0.23)
	_part(visual,Vector3(0,1.22,0),Vector3(0.75,0.8,0.38),shirt)
	_part(visual,Vector3(0,1.83,0),Vector3(0.42,0.45,0.42),Color(0.85,0.63,0.46))
	_part(visual,Vector3(-0.22,0.42,0),Vector3(0.25,0.8,0.28),Color(0.15,0.17,0.24))
	_part(visual,Vector3(0.22,0.42,0),Vector3(0.25,0.8,0.28),Color(0.15,0.17,0.24))
	_part(visual,Vector3(-0.52,1.2,0),Vector3(0.23,0.75,0.28),shirt)
	_part(visual,Vector3(0.52,1.2,0),Vector3(0.23,0.75,0.28),shirt)

func _physics_process(delta: float) -> void:
	if not local_player:
		return
	if not is_on_floor():
		velocity.y -= 22.0*delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = 8.0
	var x := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_LEFT))
	var z := float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_UP))
	var direction := Vector3(x,0,z).normalized()
	if pivot != null:
		direction = direction.rotated(Vector3.UP,pivot.rotation.y)
	velocity.x = direction.x*7.0
	velocity.z = direction.z*7.0
	if direction.length() > 0.1:
		visual.rotation.y = atan2(-direction.x,-direction.z) - rotation.y
	move_and_slide()
	send_accum += delta
	if send_accum >= 0.05 and multiplayer.has_multiplayer_peer():
		send_accum = 0.0
		get_parent().sync_transform.rpc_id(1,player_id,global_position,rotation.y)
		if multiplayer.is_server():
			get_parent().forward_transform.rpc(player_id,global_position,rotation.y)

func _unhandled_input(event: InputEvent) -> void:
	if not local_player or pivot == null:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pivot.rotation.y -= event.relative.x*0.003
		pivot.rotation.x = clampf(pivot.rotation.x-event.relative.y*0.002,-0.5,0.45)
