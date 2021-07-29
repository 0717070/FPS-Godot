extends KinematicBody
var simple_audio_player = preload("res://Simple_Audio_Player.tscn")
const GRAVITY = -24.8
#GRAVITY, how strong Gravity pulls the player down
var vel = Vector3()
#vel is the KinematicBody's velocity
const MAX_SPEED = 20
#the maximum amount of speed the player can reach. Player cannot exceed this speed
const JUMP_SPEED = 18
#how high the player can jump
const ACCEL= 4.5
#the speed at which the player can accelerate. The higher the number value, the faster the player reaches maximum speed(MAX_SPEED)

const MAX_SPRINT_SPEED = 30
const SPRINT_ACCEL = 18
var is_sprinting = false

var flashlight

var dir = Vector3()

const DEACCEL= 16
#the speed at which at the player can decelerate. The higher the number value, the faster the player will stop moving
const MAX_SLOPE_ANGLE = 40
#the steepest angle the KinematicBody will register as a floor

var camera
#the camera node
var rotation_helper
#a Spatial node holding everything we want to rotate on the X axis (up and down)

var MOUSE_SENSITIVITY = 0.05
#sensitivity of the mouse

var animation_manager

var current_weapon_name = "UNARMED"
var weapons = {"UNARMED":null, "KNIFE":null, "PISTOL":null, "RIFLE":null}
const WEAPON_NUMBER_TO_NAME = {0:"UNARMED", 1:"KNIFE", 2:"PISTOL", 3:"RIFLE"}
const WEAPON_NAME_TO_NUMBER = {"UNARMED":0, "KNIFE":1, "PISTOL":2, "RIFLE":3}
var changing_weapon = false
var changing_weapon_name = "UNARMED"

var health = 100

var UI_status_label
var reloading_weapon = false
# Variable to track whether or not the player is currently trying to reload
var JOYPAD_SENSITIVITY = 2
# JOYPAD_SENSITIVITY how fast the joypad's joysticks will move the camera
const JOYPAD_DEADZONE = 0.15
#JOYPAD_DEADZONE: The dead zone for the joypad.

var mouse_scroll_value = 0
#mouse_scroll_value: The value of the mouse scroll wheel.
const MOUSE_SENSITIVITY_SCROLL_WHEEL = 0.08
#MOUSE_SENSITIVITY_SCROLL_WHEEL: How much a single scroll action increases mouse_scroll_value

func _ready():
	camera = $Rotation_Helper/Camera
	rotation_helper = $Rotation_Helper

	animation_manager = $Rotation_Helper/Model/Animation_Player
	animation_manager.callback_function = funcref(self, "fire_bullet")

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	weapons["KNIFE"] = $Rotation_Helper/Gun_Fire_Points/Knife_Point
	weapons["PISTOL"] = $Rotation_Helper/Gun_Fire_Points/Pistol_Point
	weapons["RIFLE"] = $Rotation_Helper/Gun_Fire_Points/Rifle_Point

	var gun_aim_point_pos = $Rotation_Helper/Gun_Aim_Point.global_transform.origin

	for weapon in weapons:
		var weapon_node = weapons[weapon]
		if weapon_node != null:
			weapon_node.player_node = self
			weapon_node.look_at(gun_aim_point_pos, Vector3(0, 1, 0))
			weapon_node.rotate_object_local(Vector3(0, 1, 0), deg2rad(180))

	current_weapon_name = "UNARMED"
	changing_weapon_name = "UNARMED"

	UI_status_label = $HUD/Panel/Gun_label
	flashlight = $Rotation_Helper/Flashlight

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
	process_changing_weapons(delta)
	process_UI(delta)
	process_reloading(delta) 

func process_input(delta):

	# ----------------------------------
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()

	if Input.is_action_pressed("movement_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x = 1
	
#-----------------------------------------------------
	if Input.get_connected_joypads().size() > 0:

		var joypad_vec = Vector2(0, 0)

		if OS.get_name() == "Windows" or OS.get_name() == "X11":
			joypad_vec = Vector2(Input.get_joy_axis(0, 0), -Input.get_joy_axis(0, 1))
		elif OS.get_name() == "OSX":
			joypad_vec = Vector2(Input.get_joy_axis(0, 1), Input.get_joy_axis(0, 2))

		if joypad_vec.length() < JOYPAD_DEADZONE:
			joypad_vec = Vector2(0, 0)
		else:
			joypad_vec = joypad_vec.normalized() * ((joypad_vec.length() - JOYPAD_DEADZONE) / (1 - JOYPAD_DEADZONE))

		input_movement_vector += joypad_vec
#-----------------------------------------------------
	input_movement_vector = input_movement_vector.normalized()

	dir += -cam_xform.basis.z.normalized() * input_movement_vector.y
	dir += cam_xform.basis.x.normalized() * input_movement_vector.x
	# ----------------------------------

	# ----------------------------------
	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("movement_jump"):
			vel.y = JUMP_SPEED
	# ----------------------------------
	
	# ----------------------------------
	# Sprinting
	if Input.is_action_pressed("movement_sprint"):
		is_sprinting = true
	else:
		is_sprinting = false
	# ----------------------------------
	
	# ----------------------------------
	# Turning the flashlight on/off
	if Input.is_action_just_pressed("flashlight"):
		if flashlight.is_visible_in_tree():
			flashlight.hide()
		else:
			flashlight.show()
	# ----------------------------------

	# ----------------------------------
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------
	
	# ----------------------------------
	# Changing weapons.
	var weapon_change_number = WEAPON_NAME_TO_NUMBER[current_weapon_name]
	
	if Input.is_key_pressed(KEY_1):
		weapon_change_number = 0
	if Input.is_key_pressed(KEY_2):
		weapon_change_number = 1
	if Input.is_key_pressed(KEY_3):
		weapon_change_number = 2
	if Input.is_key_pressed(KEY_4):
		weapon_change_number = 3
	
	if Input.is_action_just_pressed("shift_weapon_positive"):
		weapon_change_number += 1
	if Input.is_action_just_pressed("shift_weapon_negative"):
		weapon_change_number -= 1
	
	weapon_change_number = clamp(weapon_change_number, 0, WEAPON_NUMBER_TO_NAME.size()-1)
	
	if changing_weapon == false:
		if reloading_weapon == false:
			if WEAPON_NUMBER_TO_NAME[weapon_change_number] != current_weapon_name:
				changing_weapon_name = WEAPON_NUMBER_TO_NAME[weapon_change_number]
				changing_weapon = true

				
	# ----------------------------------
	
	# ----------------------------------
	# Firing the weapons (weapons have limited amount of ammo and will stop firing when the player runs out)
	if Input.is_action_pressed("fire"):
		if changing_weapon == false:
			var current_weapon = weapons[current_weapon_name]
			if current_weapon != null:
				if current_weapon.ammo_in_weapon > 0:
					if animation_manager.current_state == current_weapon.IDLE_ANIM_NAME:
						animation_manager.set_animation(current_weapon.FIRE_ANIM_NAME)
				else:
					reloading_weapon = true
	# ----------------------------------
	# ----------------------------------
# Reloading
	if reloading_weapon == false:
		if changing_weapon == false:
			if Input.is_action_just_pressed("reload"):  #if reload has been pressed
				var current_weapon = weapons[current_weapon_name]
				if current_weapon != null: #check current weapon to make sure it is not null
					if current_weapon.CAN_RELOAD == true: #check to see whether the weapon can relaod
						var current_anim_state = animation_manager.current_state #If the weapon can reload, we then get the current animation state, and make a variable for tracking whether the player is already reloading or not.
						var is_reloading = false
						for weapon in weapons:
							var weapon_node = weapons[weapon]
							if weapon_node != null:
								if current_anim_state == weapon_node.RELOADING_ANIM_NAME:
									is_reloading = true
						if is_reloading == false:
							reloading_weapon = true #If the player is not reloading any weapon, we set reloading_weapon to true.
# ----------------------------------

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()

	vel.y += delta*GRAVITY

	var hvel = vel
	hvel.y = 0

	var target = dir
	if is_sprinting:
		target *= MAX_SPRINT_SPEED
	else:
		target *= MAX_SPEED

	var accel
	if dir.dot(hvel) > 0:
		if is_sprinting:
			accel = SPRINT_ACCEL
		else:
			accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel*delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel,Vector3(0,1,0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))


func process_changing_weapons(delta):
	if changing_weapon == true:

		var weapon_unequipped = false
		var current_weapon = weapons[current_weapon_name]

		if current_weapon == null:
			weapon_unequipped = true
		else:
			if current_weapon.is_weapon_enabled == true:
				weapon_unequipped = current_weapon.unequip_weapon()
			else:
				weapon_unequipped = true

		if weapon_unequipped == true:

			var weapon_equiped = false
			var weapon_to_equip = weapons[changing_weapon_name]

			if weapon_to_equip == null:
				weapon_equiped = true
			else:
				if weapon_to_equip.is_weapon_enabled == false:
					weapon_equiped = weapon_to_equip.equip_weapon()
				else:
					weapon_equiped = true

			if weapon_equiped == true:
				changing_weapon = false
				current_weapon_name = changing_weapon_name
				changing_weapon_name = ""


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		#if the event of a mouse is in motion, and cursor is captured, the camera rotates based on the relative mouse motion provided by the InputEventMouseMotion

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot
		
	if event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN:
			if event.button_index == BUTTON_WHEEL_UP:
				mouse_scroll_value += MOUSE_SENSITIVITY_SCROLL_WHEEL
			elif event.button_index == BUTTON_WHEEL_DOWN:
				mouse_scroll_value -= MOUSE_SENSITIVITY_SCROLL_WHEEL

			mouse_scroll_value = clamp(mouse_scroll_value, 0, WEAPON_NUMBER_TO_NAME.size() - 1)

			if changing_weapon == false:
				if reloading_weapon == false:
					var round_mouse_scroll_value = int(round(mouse_scroll_value))
					if WEAPON_NUMBER_TO_NAME[round_mouse_scroll_value] != current_weapon_name:
						changing_weapon_name = WEAPON_NUMBER_TO_NAME[round_mouse_scroll_value]
						changing_weapon = true
						mouse_scroll_value = round_mouse_scroll_value
#if the event is an InputEventMouseButton event and that the mouse mode is MOUSE_MODE_CAPTURED. Then, we check to see if the button index is either a BUTTON_WHEEL_UP or BUTTON_WHEEL_DOWN index.
#If the event's index is indeed a button wheel index, we then check to see if it is a BUTTON_WHEEL_UP or BUTTON_WHEEL_DOWN index. Based on whether it is up or down, we add or subtract MOUSE_SENSITIVITY_SCROLL_WHEEL to/from mouse_scroll_value.
#We then check to see if the player is changing weapons or reloading. If the player is doing neither, we round mouse_scroll_value and cast it to an int.
#to see if the weapon name at round_mouse_scroll_value is not equal to the current weapon name using WEAPON_NUMBER_TO_NAME. If the weapon is different from the player's current weapon, we assign changing_weapon_name, set changing_weapon to true so the player will change weapons in process_changing_weapon, and set mouse_scroll_value to round_mouse_scroll_value.
#-------------------------------------------------------------------------
func fire_bullet():
	if changing_weapon == true:
		return

	weapons[current_weapon_name].fire_weapon()

func process_UI(delta):
	if current_weapon_name == "UNARMED" or current_weapon_name == "KNIFE":
		UI_status_label.text = "HEALTH: " + str(health)
	else:
		var current_weapon = weapons[current_weapon_name]
		UI_status_label.text = "HEALTH: " + str(health) + \
				"\nAMMO: " + str(current_weapon.ammo_in_weapon) + "/" + str(current_weapon.spare_ammo)

#if player is trying to reload
func process_reloading(delta):
	if reloading_weapon == true: 
		var current_weapon = weapons[current_weapon_name]
		if current_weapon != null: #If the current weapon is equal to null, then the current weapon is UNARMED.
			current_weapon.reload_weapon()
		reloading_weapon = false

func create_sound(sound_name, position=null):
	var audio_clone = simple_audio_player.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(audio_clone)
	audio_clone.play_sound(sound_name, position)

  # ----------------------------------
func process_view_input(delta):

   if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
	   return
   # Joypad rotation

   var joypad_vec = Vector2()
   if Input.get_connected_joypads().size() > 0:

	   if OS.get_name() == "Windows" or OS.get_name() == "X11":
		   joypad_vec = Vector2(Input.get_joy_axis(0, 2), Input.get_joy_axis(0, 3))
	   elif OS.get_name() == "OSX":
		   joypad_vec = Vector2(Input.get_joy_axis(0, 3), Input.get_joy_axis(0, 4))

	   if joypad_vec.length() < JOYPAD_DEADZONE:
		   joypad_vec = Vector2(0, 0)
	   else:
		   joypad_vec = joypad_vec.normalized() * ((joypad_vec.length() - JOYPAD_DEADZONE) / (1 - JOYPAD_DEADZONE))

	   rotation_helper.rotate_x(deg2rad(joypad_vec.y * JOYPAD_SENSITIVITY))

	   rotate_y(deg2rad(joypad_vec.x * JOYPAD_SENSITIVITY * -1))

	   var camera_rot = rotation_helper.rotation_degrees
	   camera_rot.x = clamp(camera_rot.x, -70, 70)
	   rotation_helper.rotation_degrees = camera_rot
   # ----------------------------------
