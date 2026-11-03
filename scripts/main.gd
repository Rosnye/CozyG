extends Control
## Escena inicial de la Etapa 0.
## Sirve solo para comprobar que el proyecto corre en PC, móvil y navegador.

var _toques: int = 0

@onready var _estado: Label = $Center/Box/Status
@onready var _boton: Button = $Center/Box/Button


func _ready() -> void:
	_boton.pressed.connect(_al_tocar)


func _al_tocar() -> void:
	_toques += 1
	_estado.text = "Toques: %d" % _toques
