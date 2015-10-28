/*
		Weapon pickup on player head when taking damage
*/

#include "modules\header\gunonhead.txt"

forward DestroyPlayerHdGunObj(playerid);
public DestroyPlayerHdGunObj(playerid) 
{
	DestroyObject(PlayerHeadGunObj[playerid]);
}

CreateGunObjectOnHead(playerid, weaponid)
{
	new model = GetWeaponModelFromID(weaponid);
	if(model != -1)
	{
		DestroyObject(PlayerHeadGunObj[playerid]);
		KillTimer(HeadGunObjTimer[playerid]);
		PlayerHeadGunObj[playerid] = CreateObject(model, 0, 0, 0, 0, 0, 0);
		AttachObjectToPlayer(PlayerHeadGunObj[playerid], playerid, 0, 0, 1.35, 0, 0, 0);
		HeadGunObjTimer[playerid] = SetTimerEx("DestroyPlayerHdGunObj", 2000, 0, "i", playerid);
	}
}