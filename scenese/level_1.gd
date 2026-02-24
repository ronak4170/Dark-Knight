extends CharacterBody2D

# =======================
# CONFIG
# =======================
@export var speed: float = 80.0
@export var max_health: int = 100
@export var damage: int = 20
@export var detection_range: float = 200.0
@export var attack_range: float = 40.0
@export var knockback_force: float = 150.0

# =======================
# STATE
# =======================
var health: int
var player: Node2D = null
var is_attacking := false
var is_dead := false

# =======================
# NODES
# =======================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

# =======================
# READY
# =======================
func _ready():
	health = max_health
	player = get_tree().get_first_node_in_group("player")

	sprite.play("idle")
	hitbox.monitoring = false

# =======================
# MAIN AI LOOP
# =======================
func _physics_process(delta):
	if is_dead or player == null:
		return

	var distance := global_position.distance_to(player.global_position)

	if distance <= attack_range:
		attack()
	elif distance <= detection_range:
		chase_player()
	else:
		idle()

# =======================
# BEHAVIOR STATES
# =======================
func idle():
	velocity = Vector2.ZERO
	if sprite.animation != "idle":
		sprite.play("idle")

func chase_player():
	var direction := (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	sprite.flip_h = direction.x < 0
	if sprite.animation != "walk":
		sprite.play("walk")

func attack():
	if is_attacking:
		return

	is_attacking = true
	velocity = Vector2.ZERO
	sprite.play("attack")

	hitbox.monitoring = true

# =======================
# DAMAGE HANDLING
# =======================
func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO):
	if is_dead:
		return

	health -= amount

	# Knockback
	if from_position != Vector2.ZERO:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * knockback_force
		move_and_slide()

	if health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	hitbox.monitoring = false

	sprite.play("death")
	await sprite.animation_finished
	queue_free()

# =======================
# SIGNALS
# =======================
func _on_animated_sprite_2d_animation_finished():
	if sprite.animation == "attack":
		is_attacking = false
		hitbox.monitoring = false

func _on_hitbox_body_entered(body):
	if is_dead:
		return

	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)

func _on_hurtbox_body_entered(body):
	if body.has_method("deal_damage"):
		take_damage(body.deal_damage(), body.global_position)
