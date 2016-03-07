/*
		Hooking some common functions
*/

#include "modules\header\player.txt"

// Add "Frozen" variable to this function
stock _H_TogglePlayerControllable(playerid, toggle)
{
	Player[playerid][IsFrozen] = !bool:toggle;
	return TogglePlayerControllable(playerid, toggle);
}
 
#if defined _ALS_TogglePlayerControllable
	#undef TogglePlayerControllable
#else
	#define _ALS_TogglePlayerControllable
#endif
 
#define TogglePlayerControllable _H_TogglePlayerControllable

// Hook SetPlayerSkin to fix skin change when in vehicle
stock _H_SetPlayerSkin(playerid, skinid)
{
	new	vehicleid = GetPlayerVehicleID(playerid);
	if(vehicleid)
	{
		new seat = GetPlayerVehicleSeat(playerid);
		ClearAnimations(playerid);
		new ret = SetPlayerSkin(playerid, skinid);
		PutPlayerInVehicle(playerid, vehicleid, seat);
		return ret;
	}
	return SetPlayerSkin(playerid, skinid);
}
 
#if defined _ALS_SetPlayerSkin
	#undef SetPlayerSkin
#else
	#define _ALS_SetPlayerSkin
#endif
 
#define SetPlayerSkin _H_SetPlayerSkin

// Hook SpawnPlayer to fix spawning player when in vehicle
stock _H_SpawnPlayer(playerid)
{
	if(GetPlayerVehicleID(playerid))
	{
		SetPlayerPos(playerid, 0.0, 0.0, 0.0);
	}
	return SpawnPlayer(playerid);
}
 
#if defined _ALS_SpawnPlayer
	#undef SpawnPlayer
#else
	#define _ALS_SpawnPlayer
#endif
 
#define SpawnPlayer _H_SpawnPlayer