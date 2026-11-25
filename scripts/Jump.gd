extends Node2D

const WARP_IN_ANIM_TIME: float = 0.5
const WARP_OUT_ANIM_TIME: float = 1.0
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var target_unit:Base_Unit = null
var scale_modifier:Vector2 = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func do_start_warp_in():
	warp_in_one()
	
func do_start_warp_out():
	warp_out_one()
	
func _process(delta):
	if target_unit:
		position = target_unit.global_position
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func initiate(reference):
	target_unit = reference
	var t_size = target_unit.texDim
	var warp_target_width = t_size.x * 1 + 30*2
	var warp_target_height = t_size.y * 2
	
	var scale_need_x = warp_target_width / $Sprite.texture.get_width()*2
	var scale_need_y = warp_target_height / $Sprite.texture.get_height()*2
	
	scale_modifier = Vector2(scale_need_x, scale_need_y)
#	print(scale_modifier)
	
func warp_in_one():
	print("warp_in_one(): for ", target_unit.display, ", frame ", Engine.get_idle_frames())
	target_unit.isWarping = true

	var tween = get_tree().create_tween()
#	tween.tween_property($Sprite, "scale", Vector2(10, 1), WARP_IN_ANIM_TIME)
#	tween.tween_property($Sprite, "scale", Vector2(20, 15), WARP_IN_ANIM_TIME)
	tween.tween_property($Sprite, "scale", Vector2(scale_modifier.x, scale_modifier.y), WARP_IN_ANIM_TIME)
	tween.tween_property($Sprite, "scale", Vector2(scale_modifier.x*1.25, scale_modifier.y*2), WARP_IN_ANIM_TIME)
	tween.tween_callback(self, "warp_in_two")

func warp_in_two():
	target_unit.show_unit_fully()

	target_unit.scale = Vector2.ZERO
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property($Sprite, "scale", Vector2(0, 0), WARP_IN_ANIM_TIME)
	tween.tween_property(target_unit, "scale", Vector2(1, 1), WARP_IN_ANIM_TIME)
	tween.set_parallel(false)
	tween.tween_callback(self, "warp_in_three")
	
func warp_in_three():
	$Sprite.scale = scale_modifier
	$Sprite.visible = false
	$Sprite.modulate.a = 1
	var tween = get_tree().create_tween()
	tween.tween_callback(target_unit, "on_warp_in_done")

func warp_out_one():
	print("warp_out_one(): for ", target_unit.display, ", frame ", Engine.get_idle_frames())
	
	target_unit.isWarping = true
	target_unit.do_unselect_all_weapons()
	target_unit.hide_all_control_nodes()
	target_unit.stop_delayed_explosion_effects()
	
	$Sprite.visible = true
	
	var tween = get_tree().create_tween()
	tween.tween_property($Sprite, "scale", Vector2(scale_modifier.x*1.25, scale_modifier.y*2), WARP_OUT_ANIM_TIME)
	tween.tween_callback(self, "warp_out_two")
	
func warp_out_two():
#	print("warp_out_phase_two")
	target_unit.get_node("EffectNodes").visible = false
	target_unit.get_node("ThrusterNodes").visible = false
	target_unit.get_node("Mounts").visible = false
	
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property($Sprite, "scale", Vector2(scale_modifier.x, scale_modifier.y), WARP_OUT_ANIM_TIME)
	tween.tween_property(target_unit, "scale", Vector2(0, 0), WARP_OUT_ANIM_TIME)
#	tween.tween_property($Sprites, "modulate:a", 0.0, durOut)
#	tween.tween_property($Sprites, "scale", Vector2(0, 0), durOut/2)
#	tween.tween_property($Mounts, "modulate:a", 0.0, durOut)
#	tween.tween_property($Mounts, "scale", Vector2(0, 0), durOut/2)
	tween.set_parallel(false)
	tween.tween_callback(self, "warp_out_three")
	
func warp_out_three():
#	print("warp_out_phase_three")
	var durIn = 2.0 * Globals.mod / 5
	var tween = get_tree().create_tween()
	
	tween.tween_property($Sprite, "scale", Vector2(0, 0), durIn)
	tween.tween_callback(target_unit, "on_warp_out_done")
