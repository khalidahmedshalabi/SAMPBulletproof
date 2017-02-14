/*
		Hooking some common functions
*/

#include "modules\header\player.txt"

// Add "Frozen" variable to this function and fix parachute bug
stock _H_TogglePlayerControllable(playerid, toggle)
{
    if(!toggle)
	{
	    if(GetPlayerWeapon(playerid) == WEAPON_PARACHUTE)
		{
		    Player[playerid][HadParachuteBeforeFreeze] = true;
		}
	}
	else
	{
	    if(Player[playerid][HadParachuteBeforeFreeze])
		{
		    GivePlayerWeapon(playerid,WEAPON_PARACHUTE,9999);
		    Player[playerid][HadParachuteBeforeFreeze] = false;
		}
	}

	Player[playerid][IsFrozen] = !bool:toggle;
	return TogglePlayerControllable(playerid, toggle);
}
 
#if defined _ALS_TogglePlayerControllable
	#undef TogglePlayerControllable
#else
	#define _ALS_TogglePlayerControllable
#endif
 
#define TogglePlayerControllable _H_TogglePlayerControllable

// Hook SetPlayerSkin to fix crashes
stock _H_SetPlayerSkin(playerid, skinid)
{
    if(GetPlayerSkin(playerid) == skinid)return 1;
	if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)return 1;

    // Set spectators to re-spectate
    if(Player[playerid][BeingSpeced])
        SetTimerEx("ForceRespectate", 1000, false, "i", playerid);
 
    // Store info before re-spawn
    new Float:__Pos[4], __CurrWep;
    __CurrWep = GetPlayerWeapon(playerid);
    GetPlayerPos(playerid, __Pos[0], __Pos[1], __Pos[2]);
    GetPlayerFacingAngle(playerid, __Pos[3]);
   
    // Fixes vehicle bug
    if(IsPlayerInAnyVehicle(playerid))
        SetPlayerPos(playerid, __Pos[0], __Pos[1], __Pos[2]+2);
 
    new __Weapons[13][2];
    for(new i = 0; i < 13; i++)
        GetPlayerWeaponData(playerid, i, __Weapons[i][0], __Weapons[i][1]);
 
    // Set spawn info and spawn player
    SetSpawnInfo(playerid, GetPlayerTeam(playerid), skinid, __Pos[0], __Pos[1], __Pos[2]-0.4, __Pos[3], 0, 0, 0, 0, 0, 0);
    Player[playerid][IgnoreSpawn] = true;
    SpawnPlayer(playerid);
 
    // Set info back after re-spawn
    SetHP(playerid, Player[playerid][pHealth]);
    SetAP(playerid, Player[playerid][pArmour]);
    SetPlayerInterior(playerid, GetPlayerInterior(playerid));
    SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(playerid));
 
    for(new i = 0; i < 13; i ++)
        GivePlayerWeapon(playerid, __Weapons[i][0], __Weapons[i][1]);
    SetPlayerArmedWeapon(playerid, __CurrWep);
	return 1;
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

// Hook GetPlayerWeaponData to fix a bug: "old weapons with no ammo left are still returned"
stock _H_GetPlayerWeaponData(playerid, slot, &weapons, &ammo)
{
	// This reuses the "slot" variable so we don't have to declare a new one
	// and can put all the code in a single statement.
	return
		slot = GetPlayerWeaponData(playerid, slot, weapons, ammo),
		weapons = ammo ? weapons : 0,
		slot;
}

#if defined _ALS_GetPlayerWeaponData
	#undef GetPlayerWeaponData
#else
	#define _ALS_GetPlayerWeaponData
#endif
 
#define GetPlayerWeaponData _H_GetPlayerWeaponData