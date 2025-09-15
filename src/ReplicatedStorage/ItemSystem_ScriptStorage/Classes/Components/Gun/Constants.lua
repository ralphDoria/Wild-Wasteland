local Constants = {
	RAY_EXCLUDE_TAG = "RayExclude",
	NON_STATIC_TAG = "NonStatic",
	FIRE_MODE = {
		SEMI = "Semi",
		AUTO = "Auto",
	},
	AMMO_ATTRIBUTE = "_ammo",
	AMMO_TYPE_ATTRIBUTE = "ammoType",
	DAMAGE_ATTRIBUTE = "damage",
	FIRE_MODE_ATTRIBUTE = "fireMode",
	MAGAZINE_SIZE_ATTRIBUTE = "magazineSize",
	RANGE_ATTRIBUTE = "range",
	RATE_OF_FIRE_ATTRIBUTE = "rateOfFire",
	RELOAD_TIME_ATTRIBUTE = "reloadTime",
	RAYS_PER_SHOT_ATTRIBUTE = "raysPerShot",
	RAY_RADIUS_ATTRIBUTE = "rayRadius",
	SPREAD_ATTRIBUTE = "spread",
	RECOIL_MIN_ATTRIBUTE = "recoilMin",
	RECOIL_MAX_ATTRIBUTE = "recoilMax",
	UNANCHORED_IMPULSE_FORCE_ATTRIBUTE = "unanchoredImpulseForce",
	AIMING_SPEED_ATTRIBUTE = "aimingSpeed",

	KEYBOARD_RELOAD_KEY_CODE = Enum.KeyCode.R,
	GAMEPAD_RELOAD_KEY_CODE = Enum.KeyCode.ButtonX,

	-- Action Manager Bind Names
    ACTION_DROP_TOOL = "Dropped",
    ACTION_RELOAD = "Reload",
    ACTION_AIM_DOWN_SIGHT = "AimDownSight",

	-- Pixel size under which a screen is considered 'small'. This is the same threshold used by the default touch UI.
	UI_SMALL_SCREEN_THRESHOLD = 500,
	-- Amount to scale the UI when on a small screen
	UI_SMALL_SCREEN_SCALE = 0.6,

	HITMARKER_SOUND_DELAY = 0.1,

	-- -- View model
	-- VIEW_MODEL_BIND_NAME = "BlasterViewModel",
	-- VIEW_MODEL_OFFSET = CFrame.new(0.9, -1.3, -1.3),
	-- VIEW_MODEL_BOBBING_SPEED = 0.4,
	-- VIEW_MODEL_BOBBING_AMOUNT = 0.05,
	-- VIEW_MODEL_BOBBING_TRANSITION_SPEED = 10,
	-- VIEW_MODEL_RELOAD_FADE_TIME = 0.1,

	-- Recoil
	RECOIL_BIND_NAME = "Recoiler",
	RECOIL_STOP_SPEED = 10,
	RECOIL_ZOOM_RETURN_SPEED = 20,
	RECOIL_DEFAULT_FOV = 70,
	-- VFX
	LASER_BEAM_VISUAL_SPEED = 200,
}

return Constants