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