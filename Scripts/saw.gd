extends Node2D
@export var time :float = 1
@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D


func animate():
	var tween = get_tree().create_tween().bind_node(self).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_loops()
	tween.tween_property(path_follow_2d, "progress_ratio",1, time).set_delay(0.001)
	tween.tween_property(path_follow_2d, "progress_ratio",0, time).set_delay(0.001)

func _ready() -> void:
	animate()
