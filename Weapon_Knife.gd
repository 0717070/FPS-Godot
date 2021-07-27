extends Spatial

const DAMAGE = 40

const IDLE_ANIM_NAME = "Knife_idle"
const FIRE_ANIM_NAME = "Knife_fire"

var is_weapon_enabled = false

var player_node = null
var ammo_in_weapon = 1
# ammo_in_weapon= the ammount of ammo currently in the Knife
var spare_ammo = 1
# spare_ammo = the ammount of ammo reserved for the Knife
const AMMO_IN_MAG = 1
# AMMO_IN_MAG = The amount of ammo in a fully reloaded weapon/magazine

const CAN_RELOAD = false
#CAN_RELOAD = to track whether this weapon can be reloaded
const CAN_REFILL = false
#CAN_REFILL = to track whether we can refill this weapon's spare ammo

const RELOADING_ANIM_NAME = ""
#RELOADING_ANIM_NAME = The name of the reloading animation for this weapon. since the knife cannot reload, the RELOADING_ANIM_NAME is left as an empty string

func _ready():
	pass

func fire_weapon():
	var area = $Area
	var bodies = area.get_overlapping_bodies()

	for body in bodies:
		if body == player_node:
			continue

		if body.has_method("bullet_hit"):
			body.bullet_hit(DAMAGE, area.global_transform)

func equip_weapon():
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		is_weapon_enabled = true
		return true

	if player_node.animation_manager.current_state == "Idle_unarmed":
		player_node.animation_manager.set_animation("Knife_equip")

	return false

func unequip_weapon():

	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		player_node.animation_manager.set_animation("Knife_unequip")

	if player_node.animation_manager.current_state == "Idle_unarmed":
		is_weapon_enabled = false
		return true

	return false

#reloading weapon v (knife does not need to reload)
func reload_weapon():
	return false
