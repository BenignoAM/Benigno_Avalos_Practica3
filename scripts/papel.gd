extends Area2D

signal recogido
signal expirado

var tiempo_vida: float = 6.5
var tiempo_total: float = 6.5
@onready var sprite = $Sprite2D

func _ready():
	# Detectar cuando las tijeras (Player) tocan el papel
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta):
	tiempo_vida -= delta
	
	if tiempo_vida <= 0:
		emit_signal("expirado")
		queue_free()
		return
	
	# Parpadeo dinámico: se vuelve más rápido conforme se acaba el tiempo
	var progreso = 1.0 - (tiempo_vida / tiempo_total) # De 0.0 a 1.0
	var frecuencia = lerp(4.0, 30.0, progreso) # Aumenta la velocidad del parpadeo
	sprite.modulate.a = 0.2 if sin(tiempo_vida * frecuencia) > 0 else 1.0

func _on_body_entered(body):
	# Si tu Player es CharacterBody2D o RigidBody2D
	if body.is_in_group("player") or body.name == "Player":
		_recolectar()

func _on_area_entered(area):
	# Si tu Player es Area2D (como en el tutorial oficial de Godot)
	if area.is_in_group("player") or area.name == "Player":
		_recolectar()

func _recolectar():
	emit_signal("recogido")
	queue_free()
