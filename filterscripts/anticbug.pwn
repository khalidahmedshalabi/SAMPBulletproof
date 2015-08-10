/*

	Anti-cbug script by WhiteTiger
	
	http://forum.sa-mp.com/showthread.php?t=145416

*/

#include <a_samp>

#define COLOR_RED 0xAA3333AA

#undef MAX_PLAYERS
#define MAX_PLAYERS 500 // Change to you're servers max player count.

#define MAX_SLOTS 48

new NotMoving[MAX_PLAYERS];
new WeaponID[MAX_PLAYERS];
new CheckCrouch[MAX_PLAYERS];
new Ammo[MAX_PLAYERS][MAX_SLOTS];

new aWeaponNames[][32] = {
	{"Fist"}, // 0
	{"Brass Knuckles"}, // 1
	{"Golf Club"}, // 2
	{"Night Stick"}, // 3
	{"Knife"}, // 4
	{"Baseball Bat"}, // 5
	{"Shovel"}, // 6
	{"Pool Cue"}, // 7
	{"Katana"}, // 8
	{"Chainsaw"}, // 9
	{"Purple Dildo"}, // 10
	{"Vibrator"}, // 11
	{"Vibrator"}, // 12
	{"Vibrator"}, // 13
	{"Flowers"}, // 14
	{"Cane"}, // 15
	{"Grenade"}, // 16
	{"Teargas"}, // 17
	{"Molotov"}, // 18
	{" "}, // 19
	{" "}, // 20
	{" "}, // 21
	{"Colt 45"}, // 22
	{"Silenced Pistol"}, // 23
	{"Deagle"}, // 24
	{"Shotgun"}, // 25
	{"Sawns"}, // 26
	{"Spas"}, // 27
	{"Uzi"}, // 28
	{"MP5"}, // 29
	{"AK47"}, // 30
	{"M4"}, // 31
	{"Tec9"}, // 32
	{"Country Rifle"}, // 33
	{"Sniper Rifle"}, // 34
	{"Rocket Launcher"}, // 35
	{"Heat-Seeking Rocket Launcher"}, // 36
	{"Flamethrower"}, // 37
	{"Minigun"}, // 38
	{"Satchel Charge"}, // 39
	{"Detonator"}, // 40
	{"Spray Can"}, // 41
	{"Fire Extinguisher"}, // 42
	{"Camera"}, // 43
	{"Night Vision Goggles"}, // 44
	{"Infrared Vision Goggles"}, // 45
	{"Parachute"}, // 46
	{"Fake Pistol"} // 47
};

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Simple & Accurate Anti-C-Bug by Whitetiger.");
	print("--------------------------------------\n");
	return 1;
}

public OnFilterScriptExit()
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if((newkeys & KEY_FIRE) && (oldkeys & KEY_CROUCH) && !((oldkeys & KEY_FIRE) || (newkeys & KEY_HANDBRAKE)) || (oldkeys & KEY_FIRE) && (newkeys & KEY_CROUCH) && !((newkeys & KEY_FIRE) || (newkeys & KEY_HANDBRAKE)) ) {
        switch(GetPlayerWeapon(playerid)) {
		    case 23..25, 27, 29..34, 41: {
		        if(Ammo[playerid][GetPlayerWeapon(playerid)] > GetPlayerAmmo(playerid)) {
					OnPlayerCBug(playerid);
				}
				return 1;
			}
		}
	}

	if(CheckCrouch[playerid] == 1) {
		switch(WeaponID[playerid]) {
		    case 23..25, 27, 29..34, 41: {
		    	if((newkeys & KEY_CROUCH) && !((newkeys & KEY_FIRE) || (newkeys & KEY_HANDBRAKE)) && GetPlayerSpecialAction(playerid) != SPECIAL_ACTION_DUCK ) {
		    		if(Ammo[playerid][GetPlayerWeapon(playerid)] > GetPlayerAmmo(playerid)) {
						OnPlayerCBug(playerid);
					}
		    	}
		    }
		}
	}

	//if(newkeys & KEY_CROUCH || (oldkeys & KEY_CROUCH)) return 1;

	else if(((newkeys & KEY_FIRE) && (newkeys & KEY_HANDBRAKE) && !((newkeys & KEY_SPRINT) || (newkeys & KEY_JUMP))) ||
	(newkeys & KEY_FIRE) && !((newkeys & KEY_SPRINT) || (newkeys & KEY_JUMP)) ||
	(NotMoving[playerid] && (newkeys & KEY_FIRE) && (newkeys & KEY_HANDBRAKE)) ||
	(NotMoving[playerid] && (newkeys & KEY_FIRE)) ||
	(newkeys & KEY_FIRE) && (oldkeys & KEY_CROUCH) && !((oldkeys & KEY_FIRE) || (newkeys & KEY_HANDBRAKE)) ||
	(oldkeys & KEY_FIRE) && (newkeys & KEY_CROUCH) && !((newkeys & KEY_FIRE) || (newkeys & KEY_HANDBRAKE)) ) {
		SetTimerEx("CrouchCheck", 3000, 0, "d", playerid);
		CheckCrouch[playerid] = 1;
		WeaponID[playerid] = GetPlayerWeapon(playerid);
		Ammo[playerid][GetPlayerWeapon(playerid)] = GetPlayerAmmo(playerid);
		return 1;
	}

	return 1;
}

public OnPlayerUpdate(playerid)
{
	new Keys, ud, lr;
	GetPlayerKeys(playerid, Keys, ud, lr);
	if(CheckCrouch[playerid] == 1) {
		switch(WeaponID[playerid]) {
		    case 23..25, 27, 29..34, 41: {
		    	if((Keys & KEY_CROUCH) && !((Keys & KEY_FIRE) || (Keys & KEY_HANDBRAKE)) && GetPlayerSpecialAction(playerid) != SPECIAL_ACTION_DUCK ) {
		    		if(Ammo[playerid][GetPlayerWeapon(playerid)] > GetPlayerAmmo(playerid)) {
						OnPlayerCBug(playerid);
					}
		    	}
		    	//else SendClientMessage(playerid, COLOR_RED, "Failed in onplayer update");
		    }
		}
	}

	if(!ud && !lr) { NotMoving[playerid] = 1; /*OnPlayerKeyStateChange(playerid, Keys, 0);*/ }
	else { NotMoving[playerid] = 0; /*OnPlayerKeyStateChange(playerid, Keys, 0);*/ }

	return 1;
}

forward OnPlayerCBug(playerid);
public OnPlayerCBug(playerid) {
	/*new playername[MAX_PLAYER_NAME];
	GetPlayerName(playerid, playername, sizeof(playername));
	new str2[128];
	format(str2, sizeof(str2), "Automatic system has kicked %s for Crouch bugging with weapon (%s!)", playername, aWeaponNames[WeaponID[playerid]]);
	SendClientMessageToAll(COLOR_RED, str2);
	CheckCrouch[playerid] = 0;
	Kick(playerid);*/
	new playername[MAX_PLAYER_NAME];
	GetPlayerName(playerid, playername, sizeof(playername));
	new str2[128];
	format(str2, sizeof(str2), "Automatic system has slapped %s for Crouch bugging with weapon (%s!)", playername, aWeaponNames[WeaponID[playerid]]);
	SendClientMessageToAll(COLOR_RED, str2);
	new Float:Pos[3];
	GetPlayerPos(playerid,Pos[0],Pos[1],Pos[2]);
	SetPlayerPos(playerid,Pos[0],Pos[1],Pos[2]+2.5);
	PlayerPlaySound(playerid,1190,0.0,0.0,0.0);
	CheckCrouch[playerid] = 0;
	return 1;
}

forward CrouchCheck(playerid);
public CrouchCheck(playerid) {
	CheckCrouch[playerid] = 0;
	return 1;
}
