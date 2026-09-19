extends Node

@export var mob_scene: PackedScene
var score: int = 0

const PapelEscena = preload("res://scenes/papel.tscn")
var papel_timer: Timer

func _ready():
	# Creamos el temporizador del papel mediante código
	papel_timer = Timer.new()
	papel_timer.one_shot = true
	papel_timer.timeout.connect(_spawnear_papel)
	add_child(papel_timer)

func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	papel_timer.stop()
	get_tree().call_group(&"papel", &"queue_free")
	$HUD.show_game_over()
	$Music.stop()
	$DeathSound.play()

func new_game():
	get_tree().call_group(&"mobs", &"queue_free")
	get_tree().call_group(&"papel", &"queue_free")
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$Music.play()
	
	# Inicia la cuenta regresiva aleatoria del papel (10 a 20 segundos)
	_programar_siguiente_papel(randf_range(10.0, 20.0))

func _on_MobTimer_timeout():
	var mob = mob_scene.instantiate()

	var mob_spawn_location = get_node(^"MobPath/MobSpawnLocation")
	mob_spawn_location.progress_ratio = randf()

	mob.position = mob_spawn_location.position

	var direction = mob_spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	add_child(mob)

func _on_ScoreTimer_timeout():
	score += 1
	$HUD.update_score(score)

func _on_StartTimer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()

# --- LÓGICA DE LA MECÁNICA: PAPEL ---

func _programar_siguiente_papel(segundos: float):
	papel_timer.wait_time = segundos
	papel_timer.start()

func _spawnear_papel():
	var papel = PapelEscena.instantiate()
	papel.add_to_group(&"papel")
	
	# Calcula un punto aleatorio dentro del área de juego visible
	var screen_size = get_viewport().get_visible_rect().size
	papel.position = Vector2(
		randf_range(60, screen_size.x - 60),
		randf_range(60, screen_size.y - 60)
	)
	
	papel.recogido.connect(_on_papel_recogido)
	papel.expirado.connect(_on_papel_expirado)
	add_child(papel)

func _on_papel_expirado():
	# Si no se recoge a tiempo, espera 3.5 segundos antes de calcular el nuevo tiempo
	await get_tree().create_timer(3.5).timeout
	_programar_siguiente_papel(randf_range(10.0, 20.0))

func _on_papel_recogido():
	# 1. Pausar la generación de nuevas rocas
	$MobTimer.stop()
	
	# 2. Envolver y destruir todas las rocas activas en pantalla
	var rocas = get_tree().get_nodes_in_group(&"mobs")
	for roca in rocas:
		var col = roca.find_child("CollisionShape2D")
		if col:
			col.set_deferred("disabled", true)
		
		# Animación: se aclaran a tono papel, rotan y se comprimen a cero
		var tween = create_tween()
		tween.parallel().tween_property(roca, "modulate", Color(2.0, 2.0, 2.0, 0.4), 1.5)
		tween.parallel().tween_property(roca, "scale", Vector2.ZERO, 1.5)
		tween.parallel().tween_property(roca, "rotation", roca.rotation + 6.28, 1.5)
		tween.tween_callback(roca.queue_free)
	
	# 3. Ventana de gracia de 3 segundos sin rocas
	await get_tree().create_timer(3.0).timeout
	$MobTimer.start()
	
	# 4. Esperar 3.5 segundos tras el reinicio antes de planificar el próximo papel
	await get_tree().create_timer(3.5).timeout
	_programar_siguiente_papel(randf_range(10.0, 20.0))
