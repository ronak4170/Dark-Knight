extends CharacterBody2D


@export var speed : float = 300.0
@export var jump_velocity = -360.0
@export var max_jumps : int = 2
@export var double_jump_velocity : float = -300.0


@onready var animated_sprite = $AnimatedSprite2D

var animated_locked : bool = false
var direction : Vector2 = Vector2.ZERO
var was_in_air : bool = false
var jumps_left : int 

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		was_in_air = true
	else:
		jumps_left = max_jumps
		
		if was_in_air == true:
			land()
			
		was_in_air = false
		
	# Handle jump.
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		if jumps_left == max_jumps:
			jump()
		else:
			double_jump()
			
		jumps_left -= 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_vector("left", "right",  "up" , "down")
	if direction.x != 0 && animated_sprite.animation != "jump_end":
		velocity.x = direction.x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	update_animation()
	update_facing_direction()
	
func update_animation():
	if not animated_locked:
		if not is_on_floor():
			animated_sprite.play("jump_loop")
		else:
			if direction.x != 0:
				animated_sprite.play("run")
			else:
				animated_sprite.play("idle")
		
	
func update_facing_direction():
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true
		
func jump():
	velocity.y = jump_velocity
	animated_sprite.play("jump_start")
	animated_locked = true
	
func land():
	animated_sprite.play("jump_end")
	animated_locked = true
	

func _on_animated_sprite_2d_animation_finished():
	if (animated_sprite.animation == "jump_end"):
		animated_locked = false
	elif (animated_sprite.animation == "jump_start"):
		animated_locked = false
		
func double_jump():
	velocity.y = double_jump_velocity
	animated_sprite.play("jump_start")
	animated_locked = true
		
