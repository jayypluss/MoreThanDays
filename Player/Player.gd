extends KinematicBody2D

const WORD_LIMIT = 13000

var motion = Vector2(0, 0)
var stopped = false
var is_attacking = false

const GRAVITY = 150
const WALK_SPEED = 1000
const JUMP_SPEED = 2650
const BOOST_MULTIPLIER = 1.5
var SPRINT_MULTIPLIER = 1

signal animate

func _physics_process(delta):
    if !stopped:
        apply_gravity()
        jump()
        move()
        animate()
        move_and_slide(motion, Vector2.UP)
    
func apply_gravity():
    if motion.y > WORD_LIMIT:
        get_tree().call_group('Gamestate', 'end_game')
    if is_on_floor() and motion.y > 0:
        motion.y = 0
    if is_on_ceiling():
        motion.y = 1
    else:
        motion.y += GRAVITY


func jump():
    if Input.is_action_pressed('Jump') and is_on_floor():
        motion.y -= JUMP_SPEED
        $JumpSFX.play()
        
func move():
    var walk_direction = 0
    
    if going_left():
        walk_direction = -1
    elif going_right():
        walk_direction = 1
    else: 
        walk_direction = 0
    
    if is_on_floor():
        if Input.is_action_pressed('Sprint'):
            SPRINT_MULTIPLIER = 2
            $PlayerAnimation.speed_scale = 2
        else:
            SPRINT_MULTIPLIER = 1
            $PlayerAnimation.speed_scale = 1
        
    motion.x = walk_direction * WALK_SPEED * SPRINT_MULTIPLIER

func going_left():
    return Input.is_action_pressed('Left') and not Input.is_action_pressed('Right')
        
func going_right():
    return Input.is_action_pressed('Right') and not Input.is_action_pressed('Left')
        
func animate():
    emit_signal('animate', motion)
    
func stop():
#    print('stop')
    motion.x = 0
    stopped = true
    animate()
    
func hurt():
    position.y -= 1
    yield(get_tree(), "idle_frame")
    motion.y = -JUMP_SPEED
    $PainSFX.play()

func boost():
    position.y -= 1
    yield(get_tree(), "idle_frame")
    motion.y = -JUMP_SPEED * BOOST_MULTIPLIER

func _input(event):
    if event.is_action_pressed("Attack"):
        is_attacking = true
        $Timer.start()
        
func enterPortalAnimation(portal_body):
    position.x = portal_body.position.x
    position.y = portal_body.position.y
    $AnimationPlayer.play("portal_enter", -1, 3)
#	$AnimationPlayer.play("portal_enter_size", -1, 1)
    
    
func _on_Player_animate(motion):
#    print(motion)
    if is_attacking:
        get_node("PlayerAnimation").play("attack2")
    elif motion.y > 0 && !is_on_floor():
        $PlayerAnimation.play('jump_fall')
    elif motion.y < 0 && !is_on_floor():
        $PlayerAnimation.play('jump_up')
    elif motion.x > 0 && is_on_floor():
        $PlayerAnimation.play('walk')
        $PlayerAnimation.flip_h = false
    elif motion.x < 0 && is_on_floor():
        $PlayerAnimation.play('walk')
        $PlayerAnimation.flip_h = true
    else:
        $PlayerAnimation.play('idle')



func _on_Timer_timeout():
    is_attacking = false
    $PlayerAnimation.offset.x = 0
    $PlayerAnimation.offset.y = 0