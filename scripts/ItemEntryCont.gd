extends PanelContainer

var basecooldown:float = 0.0

var tween:SceneTreeTween

func _ready():
	pass
#	var tween = get_tree().create_tween().set_parallel(true)
#	tween.tween_property($BeamLinePos, "modulate:a", 1.0, durA)
#	tween.tween_property($BeamLinePos/Real, "width", width*0.5, durA)
#	tween.set_parallel(false)
#	tween.tween_callback(self, "beamFadeInTwo")

func init_cooldown_tweener():
#	print("init_cooldown_tweener")
	$Tween.connect("tween_all_completed", self, "_on_cooldown_tweener_completed")
#	$Cooldown_flash_panel.modulate.a = 0.0
		
func reset_cooldown_tweener(val):
#	print("reset_cooldown_tweener")
#	tween.interpolate_value($PC/CDProgress, "value", 1.0, val)
	$Tween.interpolate_property($PC/CDProgress, "value", 100, 0, val, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	
func _on_cooldown_tweener_completed():
#	print("_on_cooldown_tweener_completed")
	tween = get_tree().create_tween()
	tween.tween_property($Cooldown_flash_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property($Cooldown_flash_panel, "modulate:a", 0.0, 0.0)
#	$Tween.interpolate_property($Cooldown_flash_panel, "modulate:a", 0.0, 1.0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
#	$Tween.start()
