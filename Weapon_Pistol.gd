extends Spatial

const DAMAGE = 15

const IDLE_ANIM_NAME = "Pistol_idle"
const FIRE_ANIM_NAME = "Pistol_fire"

var is_weapon_enabled = false

var bullet_scene = preload("Bullet_Scene.tscn")

var player_node = null

var ammo_in_weapon = 10
# ammo_in_weapon= the ammount of ammo currently in the pistol
var spare_ammo = 20
# spare_ammo = the ammount of ammo reserved for the pistol
const AMMO_IN_MAG = 10
# AMMO_IN_MAG = The amount of ammo in a fully reloaded weapon/magazine
const CAN_RELOAD = true
#CAN_RELOAD = to track whether this weapon can be reloaded
const CAN_REFILL = true
#CAN_REFILL = to track whether we can refill this weapon's spare ammo

const RELOADING_ANIM_NAME = "Pistol_reload"
#RELOADING_ANIM_NAME = The name of the reloading animation for this weapon.
func _ready():
	pass

func fire_weapon():
	var clone = bullet_scene.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(clone)

	clone.global_transform = self.global_transform
	clone.scale = Vector3(4, 4, 4)
	clone.BULLET_DAMAGE = DAMAGE
	
	ammo_in_weapon -= 1
	player_node.create_sound("Pistol_shot", self.global_transform.origin)

func equip_weapon():
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		is_weapon_enabled = true
		return true

	if player_node.animation_manager.current_state == "Idle_unarmed":
		player_node.animation_manager.set_animation("Pistol_equip")

	return false

func unequip_weapon():
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		if player_node.animation_manager.current_state != "Pistol_unequip":
			player_node.animation_manager.set_animation("Pistol_unequip")

	if player_node.animation_manager.current_state == "Idle_unarmed":
		is_weapon_enabled = false
		return true
	else:
		return false

func reload_weapon():
	var can_reload = false

	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		can_reload = true

	if spare_ammo <= 0 or ammo_in_weapon == AMMO_IN_MAG:
		can_reload = false

	if can_reload == true:
		var ammo_needed = AMMO_IN_MAG - ammo_in_weapon

		if spare_ammo >= ammo_needed:
			spare_ammo -= ammo_needed
			ammo_in_weapon = AMMO_IN_MAG
		else:
			ammo_in_weapon += spare_ammo
			spare_ammo = 0

		player_node.animation_manager.set_animation(RELOADING_ANIM_NAME)
		player_node.create_sound("Gun_cock", player_node.camera.global_transform.origin)

		return true

	return false
