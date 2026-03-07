extends CharacterBody2D

# ── Stats ──────────────────────────────────────────────
@export var max_hp: int = 40
@export var move_speed: float = 120.0
@export var dash_speed: float = 480.0

@export var attack_damage: int = 1
@export var attack_cooldown_p1: float = 1.2
@export var attack_cooldown_p2: float = 0.7
@export var attack_hit_delay: float = 0.18  # tune to match sword swing frame

@export var invuln_duration: float = 0.35
@export var hurt_time: float = 0.25

# ── Nodes ──────────────────────────────────────────────
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hurtbox   # the Area2D your boss already has

# ── State ──────────────────────────────────────────────
var hp: int
var player: Node2D = null

var dead: bool = false
var invulnerable: bool = false
var attacking: bool = false
var hitstunned: bool = false
var phase2: bool = false

var _attack_cooldown_active: bool = false
var _dash_dir: Vector2 = Vector2.ZERO
var _dashing: bool = false


func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	_find_player()
	anim.play("Idle")


func _physics_process(delta: float) -> void:
	if dead:
		return

	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# hitstun: slide to stop
	if hitstunned:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0)
		move_and_slide()
		return

	# dashing: move in locked direction
	if _dashing:
		velocity.x = _dash_dir.x * dash_speed
		move_and_slide()
		return

	# find player
	if player == null or not is_instance_valid(player):
		_find_player()

	if player == null:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0)
		move_and_slide()
		return

	# stop if player dead
	if player.has_method("is_dead") and player.is_dead():
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0)
		move_and_slide()
		return

	# phase 2 check
	if not phase2 and hp <= max_hp / 2:
		phase2 = true
		print("BOSS PHASE 2!")

	var to_p: Vector2 = player.global_position - global_position
	var dist: float = to_p.length()

	# always face the player
	anim.flip_h = (to_p.x < 0)

	if attacking:
		# locked during attack swing — just stand still
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0)
		move_and_slide()
		return

	if dist > 80.0:
		# chase
		anim.play("Run")
		velocity.x = sign(to_p.x) * move_speed
	else:
		# in range — try to attack
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0)
		if not anim.animation.begins_with("Attack"):
			anim.play("Idle")
		if not _attack_cooldown_active:
			_pick_attack()

	move_and_slide()


func _find_player() -> void:
	var found = get_tree().get_first_node_in_group("player")
	if found != null:
		player = found as Node2D


# ── Attack selection ────────────────────────────────────

func _pick_attack() -> void:
	if attacking or dead or hitstunned:
		return

	var r: float = randf()
	# Phase 2: 25% chance to dash
	if phase2 and r < 0.25:
		_do_dash()
		return

	# Pick attack animation
	if r < 0.34:
		_do_attack("Attack1")
	elif r < 0.67:
		_do_attack("Attack2")
	else:
		_do_attack("Attack3")


func _do_attack(anim_name: String) -> void:
	attacking = true
	_attack_cooldown_active = true
	anim.play(anim_name)

	# wait for the hit frame
	await get_tree().create_timer(attack_hit_delay).timeout

	if dead or hitstunned:
		attacking = false
		_start_cooldown()
		return

	# deal damage if player is still in range
	if player and is_instance_valid(player):
		var dist: float = (player.global_position - global_position).length()
		if dist < 100.0 and player.has_method("take_damage"):
			player.take_damage(attack_damage)

	# wait for rest of animation to finish
	await anim.animation_finished

	attacking = false
	_start_cooldown()


func _do_dash() -> void:
	if player == null:
		return

	attacking = true
	_attack_cooldown_active = true
	_dashing = true
	_dash_dir = (player.global_position - global_position).normalized()
	anim.flip_h = (_dash_dir.x < 0)
	anim.play("Run")

	await get_tree().create_timer(0.35).timeout

	_dashing = false

	# damage on arrival
	if player and is_instance_valid(player):
		var dist: float = (player.global_position - global_position).length()
		if dist < 100.0 and player.has_method("take_damage"):
			player.take_damage(attack_damage)

	attacking = false
	_start_cooldown()


func _start_cooldown() -> void:
	var cd: float = attack_cooldown_p2 if phase2 else attack_cooldown_p1
	await get_tree().create_timer(cd).timeout
	_attack_cooldown_active = false


# ── Taking damage (player hits boss) ───────────────────

func take_damage(amount: int) -> void:
	if dead or invulnerable:
		return

	hp -= amount
	print("BOSS TOOK DAMAGE:", amount, " HP:", hp)

	invulnerable = true
	attacking = false
	_dashing = false

	if hp <= 0:
		_die()
		return

	hitstunned = true
	anim.play("Hurt")

	await get_tree().create_timer(hurt_time).timeout

	hitstunned = false

	await get_tree().create_timer(invuln_duration - hurt_time).timeout
	invulnerable = false

	if not dead:
		anim.play("Idle")


# ── Death ───────────────────────────────────────────────

func _die() -> void:
	dead = true
	invulnerable = true
	velocity = Vector2.ZERO

	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false

	anim.play("Dead")
	print("BOSS DIED")

	await anim.animation_finished

	# TODO: trigger win screen / open door here
	# get_tree().change_scene_to_file("res://scenes/victory.tscn")
	queue_free()
