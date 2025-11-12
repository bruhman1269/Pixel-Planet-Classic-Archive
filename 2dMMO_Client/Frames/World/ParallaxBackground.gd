extends ParallaxBackground

func _ready() -> void:
	Global.backgroundNode = self
	SetBackground(Global.WorldData.Background, false)

func SetBackground(id, sfx = true):
	
	if id == 1:
		$ParallaxLayer.visible = false
		$ParallaxLayer2.visible = false
		$ParallaxLayer3.visible = false
		$ParallaxLayer4.visible = false
		
	else:
		$ParallaxLayer.visible = true
		$ParallaxLayer2.visible = true
		$ParallaxLayer3.visible = true
		$ParallaxLayer4.visible = true
	
	if sfx:
		$AnimationPlayer.play("change")
		$BGChangeSFX.play()
	
	$"%Background".get_node("Background").frame = id
	
	$ParallaxLayer/Sprite.frame = id
	$ParallaxLayer2/Sprite.frame = id
	$ParallaxLayer3/Sprite.frame = id
	$ParallaxLayer4/Sprite.frame = id
