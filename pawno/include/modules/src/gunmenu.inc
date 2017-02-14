/*

	Guns selection script

*/

#include "modules\header\gunmenu.txt"
#include <YSI_inc\YSI\y_hooks>

hook OnPlayerDisconnect(playerid, reason)
{
	// Reset player weapons on gunmenu
	ResetPlayerGunmenu(playerid, false);
	return 1;
}

LoadGunmenuData()
{
	new
		str[64],
		DBResult:res = db_query(sqliteconnection, "SELECT * FROM 'Gunmenu' ORDER BY Weapon ASC"),
		weaponID,
		idx = 0;

	do {
		db_get_field_assoc(res, "Weapon", str, sizeof(str));
		weaponID = strval(str);

		GunmenuData[idx][GunID] = weaponID;
		GunmenuData[idx][GunModel] = GetWeaponModelFromID(weaponID);

		db_get_field_assoc(res, "Limit", str, sizeof(str));
		GunmenuData[idx][GunLimit] = strval(str);

		db_get_field_assoc(res, "Ammo", str, sizeof(str));
		GunmenuData[idx][GunAmmo] = strval(str);

		idx ++;

	} while(db_next_row(res) && idx < MAX_GUNMENU_GUNS);

	db_free_result(res);
}

ResetGunmenuSelections(team = -1)
{
	switch(team)
	{
		case -1:
		{
			for(new i = 0; i < MAX_TEAMS; i ++)
			{
				for(new j = 0; j < MAX_GUNMENU_GUNS; j ++)
					GunmenuData[j][TimesSelected][i] = 0;

				foreach(new j : Player)
					for(new k = 0; k < MAX_GUNMENU_GUNS; k ++)
						if(GunmenuData[k][HasGun][j])
							GunmenuData[k][HasGun][j] = false;
			}
		}
		default:
		{
			for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
				GunmenuData[i][TimesSelected][team] = 0;

			foreach(new j : Player)
					for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
						if(GunmenuData[i][HasGun][j])
							GunmenuData[i][HasGun][j] = false;
		}
	}
}

UpdateGunmenuLimitsTextDraw(updated_team = -1)
{
	switch(updated_team)
	{
		case -1:
		{
			new str[GUNMENU_LIMIT_TEXTDRAW_SIZE];
			new i;
			for(new team = 0; team < MAX_TEAMS; team ++)
			{
				i = 0;
				format(str, sizeof str, "%s%s ~w~[%d/%d] [ammo: %d]", TDC[team], WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][team], GunmenuData[i][GunLimit]);
				i ++;
				for(; i < MAX_GUNMENU_GUNS; i ++)
				{
					format(str, sizeof str, "%s~n~%s%s ~w~[%d/%d] [ammo: %d]", str, TDC[team], WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][team], GunmenuData[i][GunLimit]);
				}
				TextDrawSetString(GunmenuLimitsTD[team], str);
			}
		}
		default:
		{
			new str[GUNMENU_LIMIT_TEXTDRAW_SIZE];
			new i = 0;
			format(str, sizeof str, "%s%s ~w~[%d/%d] [ammo: %d]", TDC[updated_team], WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][updated_team], GunmenuData[i][GunLimit], GunmenuData[i][GunAmmo]);
			i ++;
			for(; i < MAX_GUNMENU_GUNS; i ++)
			{
				format(str, sizeof str, "%s~n~%s%s ~w~[%d/%d] [ammo: %d]", str, TDC[updated_team], WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][updated_team], GunmenuData[i][GunLimit], GunmenuData[i][GunAmmo]);
			}
			TextDrawSetString(GunmenuLimitsTD[updated_team], str);
		}
	}
}

InitGunmenu()
{
	Iter_Init(PlayerGunObjects); // empty the iterator array
	LoadGunmenuData();
	ResetGunmenuSelections();
	UpdateGunmenuLimitsTextDraw();
}

ShowPlayerGunmenuModification(playerid)
{
	new str[GUNMENU_LIMIT_DIALOG_SIZE];
	format(str, sizeof str, "Weapon\tAmmo\tLimit");
	for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
	{
		format(str, sizeof str, "%s\n{50EB50}%s\t%d\t%d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][GunAmmo], GunmenuData[i][GunLimit]);
	}
	ShowPlayerDialog(playerid, DIALOG_GUNMENU_MODIFY_MAIN, DIALOG_STYLE_TABLIST_HEADERS, "Gunmenu Modification Mode", str, "Modify", "Cancel");
}

DestroyPlayerGunObjects(playerid)
{
	if(Iter_Count(PlayerGunObjects[playerid]) == 0 || Player[playerid][GunmenuStyle] != GUNMENU_STYLE_OBJECT)
		return;

	foreach(new i : PlayerGunObjects[playerid])
	{
		DestroyPlayerObject(playerid, i);
	}
	Iter_Clear(PlayerGunObjects[playerid]);
}

ResetPlayerGunmenu(playerid, bool:showagain)
{
	new team = Player[playerid][Team];
	for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
	{
		if(GunmenuData[i][HasGun][playerid])
		{
			GunmenuData[i][HasGun][playerid] = false;
			if(GunmenuData[i][TimesSelected][team] > 0)
				GunmenuData[i][TimesSelected][team] --;
		}
	}
	DestroyPlayerGunObjects(playerid);
	ResetPlayerWeapons(playerid);
	UpdateGunmenuLimitsTextDraw(team);
	if(showagain)
		ShowPlayerGunmenu(playerid, 0);
}

ShowGunmenuHelp(playerid)
{
	SendClientMessage(playerid, -1, ""COL_PRIM"Help: {FFFFFF}type /matchtips to display some guidelines you may need while playing!");
}

HidePlayerGunmenu(playerid)
{
	if(!Player[playerid][OnGunmenu])
		return;

	switch(Player[playerid][GunmenuStyle])
	{
		case GUNMENU_STYLE_OBJECT:
		{
			if((Player[playerid][Playing] == true || Player[playerid][Spectating]) && Current != -1)
			{
				SetCPForPlayer(playerid);
			}
			KillTimer(GunmenuData[playerid][GunFreezePlane]);
			TextDrawHideForPlayer(playerid, GunmenuLimitsTD[Player[playerid][Team]]);
			DestroyPlayerGunObjects(playerid);
			CancelEdit(playerid);
		}
	}
	SetCameraBehindPlayer(playerid);
	SetPlayerArmedWeapon(playerid, 0);
	if(!RoundPaused)
		TogglePlayerControllable(playerid, 1);
	else
		TogglePlayerControllable(playerid, 0);
	Player[playerid][OnGunmenu] = false;
}

ShowGunmenuDialog(playerid)
{
	switch(GameType)
	{
		case BASE:
		{
			new team = Player[playerid][Team];
			new str[GUNMENU_LIMIT_DIALOG_SIZE];
			
			format(str, sizeof str, "{FFFFFF}Weapon\t{FFFFFF}Ammo\t{FFFFFF}Picked / Limit");
			
			for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
			{
				// Do some coloring for items
				if(GunmenuData[i][HasGun][playerid]) // already got this weapon
				{
					format(str, sizeof str, "%s\n{FFFFFF}%s\t{FFFFFF}%d\t{FFFFFF}%d / %d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][GunAmmo], GunmenuData[i][TimesSelected][team], GunmenuData[i][GunLimit]);
				}
				else if(GunmenuData[i][TimesSelected][team] < GunmenuData[i][GunLimit]) // available
				{
					if(i%2 == 0)
					{
					    if(team == ATTACKER) format(str, sizeof str, "%s\n{FF2222}%s\t{FF2222}%d\t{FF2222}%d / %d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][GunAmmo], GunmenuData[i][TimesSelected][team], GunmenuData[i][GunLimit]);
						else format(str, sizeof str, "%s\n{5555FF}%s\t{5555FF}%d\t{5555FF}%d / %d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][GunAmmo], GunmenuData[i][TimesSelected][team], GunmenuData[i][GunLimit]);
						
					}
					else
					{
                        if(team == ATTACKER) format(str, sizeof str, "%s\n{FF4444}%s\t{FF4444}%d\t{FF4444}%d / %d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][GunAmmo], GunmenuData[i][TimesSelected][team], GunmenuData[i][GunLimit]);
						else format(str, sizeof str, "%s\n{7777FF}%s\t{7777FF}%d\t{7777FF}%d / %d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][GunAmmo], GunmenuData[i][TimesSelected][team], GunmenuData[i][GunLimit]);
					}
					
				}
				else // unavailable
				{
					format(str, sizeof str, "%s\n{696969}%s\t{696969}%d\t{696969}%d / %d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][GunAmmo], GunmenuData[i][TimesSelected][team], GunmenuData[i][GunLimit]);
				}
			}
			
			ShowPlayerDialog(playerid, DIALOG_GUNMENU, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Select your weapons:", str, "Pick", "Reset");
		}
		case ARENA:
		{
			new team = Player[playerid][Team];
			new str[800];
			
			format(str, sizeof str, "{FFFFFF}Weapon\t{FFFFFF}Times Picked");
			
			for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
			{
				// Do some coloring for items
				if(GunmenuData[i][HasGun][playerid]) // already got this weapon
				{
					format(str, sizeof str, "%s\n{FFFFFF}%s\t{FFFFFF}%d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][team]);
				}
				else if(GunmenuData[i][GunLimit] <= 0) // not available
				{
					format(str, sizeof str, "%s\n{696969}%s\t{696969}%d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][team]);
				}
				else // available
				{
				    if(i%2 == 0)
					{
					    if(team == ATTACKER) format(str, sizeof str, "%s\n{FF2222}%s\t{FF2222}%d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][team]);
					    else format(str, sizeof str, "%s\n{5555FF}%s\t{5555FF}%d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][team]);
					}
					else
					{
					    if(team == ATTACKER) format(str, sizeof str, "%s\n{FF4444}%s\t{FF4444}%d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][team]);
					    else format(str, sizeof str, "%s\n{7777FF}%s\t{7777FF}%d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][team]);
					}
				}
			}
			
			ShowPlayerDialog(playerid, DIALOG_GUNMENU, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Select your weapons:", str, "Pick", "Reset");
		}
	}
}

forward FreezePlayerPlane(playerid, planeid);
public FreezePlayerPlane(playerid, planeid)
{
	if(GetPlayerVehicleID(playerid) != planeid)
		KillTimer(GunmenuData[playerid][GunFreezePlane]);
	else
		SetVehiclePos(planeid, TempAirVehicles_Pos[planeid][0], TempAirVehicles_Pos[planeid][1], TempAirVehicles_Pos[planeid][2]);
	return 1;
}

forward ShowPlayerGunmenu(playerid, delay);
public ShowPlayerGunmenu(playerid, delay)
{
	if(Player[playerid][OnGunmenu])
		HidePlayerGunmenu(playerid);

	if(delay > 0)
	{
		SetTimerEx("ShowPlayerGunmenu", delay, false, "ii", playerid, 0);
		return 1;
	}
	Player[playerid][OnGunmenu] = true; // Indicate that they're on the gunmenu selection mode
	ResetPlayerGunmenu(playerid, false);
	switch(Player[playerid][GunmenuStyle])
	{
		case GUNMENU_STYLE_DIALOG:
		{
			ShowGunmenuDialog(playerid);
		}
		case GUNMENU_STYLE_OBJECT:
		{
			new
				veh = GetPlayerVehicleID(playerid),
				bool:InAirVehicle = false;
			if(IsAirVehicle(veh))
			{
				InAirVehicle = true;
				GetVehiclePos(veh, TempAirVehicles_Pos[veh][0], TempAirVehicles_Pos[veh][1], TempAirVehicles_Pos[veh][2]);
				GunmenuData[playerid][GunFreezePlane] = SetTimerEx("FreezePlayerPlane", 50, true, "ii", playerid, veh);
			}
			TextDrawShowForPlayer(playerid, GunmenuLimitsTD[Player[playerid][Team]]);
			DisablePlayerCheckpoint(playerid); // Checkpoints seem to make object selection gitched, disable them temporarily
			SendClientMessage(playerid, -1, ""COL_PRIM"Type {FFFFFF}/reset "COL_PRIM"to restart selection!");
			// Create gun objects for them... (I'm not a math teacher so don't expect heavy documentation)
			Iter_Clear(PlayerGunObjects[playerid]); // Clear gunmenu objects iterator
			// We're going to generate points as a function of this angle
			// Basically we will be going from 0 to 360 since it's a circle
			// Let's start from 0
			new Float:angle = 0.0;

			new
				i = 0, // index
				objectID, // player object ID
				bool:MoveObjectUp = true, // whether this object should start moving to up or to down
				Float:x,  // object X
				Float:y,  // object Y
				Float:z,  // object Z
				Float:angle_change = 360.0 / float(MAX_GUNMENU_GUNS);

			new Float:centerX, Float:centerY, Float:radius = GUNMENU_OBJECTS_CIRCLE_RADIUS, Float:camHeight = 3.65;
			GetPlayerPos(playerid, centerX, centerY, z); // we need the z value only from player
			new Float:originZ = z;
			if(veh)
			{
				radius = GUNMENU_OBJECTS_CIRCLE_RADIUS_INVEHICLE;
				new modelid = GetVehicleModel(veh);
				if(InAirVehicle)
				{
					// air vehicles
					camHeight = 12.0;
					z += 1.1;
				}
				else if
				(
					// bigger vehicles IDs
					modelid == 403 || modelid == 406 || modelid == 407 || modelid == 408 || modelid == 431 || modelid == 433 || modelid == 437 || modelid == 443
					|| modelid == 444 || modelid == 486 || modelid == 514 || modelid == 515 || modelid == 524 || modelid == 532 || modelid == 544 || modelid == 573
					|| modelid == 578
				)
				{
					camHeight = 15.0;
					z += 5.1;
				}
				else
				{
					// regular vehicles
					camHeight = 12.0;
					z += 0.3; // make sure objects won't be stuck underground
				}
			}
			else
			{
				z += 0.3; // make sure objects won't be stuck underground
			}
			// Init selection mode
			TogglePlayerControllable(playerid, 0);
			SetPlayerCameraPos(playerid, centerX + 2.0, centerY - 2.0, originZ + camHeight);
			SetPlayerCameraLookAt(playerid, centerX, centerY, originZ);
			SelectObject(playerid); // Enables mouse cursor so they can select guns (objects)
			while(i != MAX_GUNMENU_GUNS)
			{
				// Specify points as a function of angle
				x = centerX + (radius * floatcos(angle, degrees));
				y = centerY + (radius * floatsin(angle, degrees));
				// Alright, we know where this object should be created now, so let's do create it
				switch(MoveObjectUp)
				{
					// This object should start at a low level and then get higher
					case true:
					{
						objectID = CreatePlayerObject(playerid, GunmenuData[i][GunModel], x, y, z, -25.0, -25.0, -45.0, 0.0); // create object for player
						GunmenuData[i][GunMovingRoute][playerid] = GUN_MOVING_ROUTE_DOWN; // yeah, it's going down
						MoveObjectUp = false;
					}
					// This object should start at high level and then get lower
					case false:
					{
						objectID = CreatePlayerObject(playerid, GunmenuData[i][GunModel], x, y, z + GUNMENU_OBJECT_Z_CHANGES, 25.0, 25.0, 45.0, 0.0); // create object for player
						GunmenuData[i][GunMovingRoute][playerid] = GUN_MOVING_ROUTE_UP; // yeah, it's going up
						MoveObjectUp = true;
					}
				}
				GunmenuData[i][GunPlayerObject][playerid] = objectID;
				Iter_Add(PlayerGunObjects[playerid], objectID); // Add to iterator array
				OnPlayerObjectMoved(playerid, objectID);
				// Increase the angle to make sure there's a moderate space between each gun object
				// As mentioned before, we get points as a function of angle, hence we got to change
				// it every time and for each object otherwise objects will overlap and look terrible
				angle += angle_change;
				// Done, increase index and iterate
				i ++;
			}
		}
	}
	return 1;
}

bool:IsGunSelectionOkay(playerid, weaponid, index)
{
	new messagebox_type;
	switch(Player[playerid][GunmenuStyle])
	{
		case GUNMENU_STYLE_DIALOG:
		{
			messagebox_type = MSGBOX_TYPE_BOTTOM;
		}
		case GUNMENU_STYLE_OBJECT:
		{
			messagebox_type = MSGBOX_TYPE_MIDDLE;
		}
	}
	// Check whether this weapon slot is free or not
	if(DoesPlayerHaveWeaponInSlot(playerid, GetWeaponSlot(weaponid)))
	{
		SendErrorMessage(playerid, "You've already got a weapon in this slot", messagebox_type);
		return false;
	}
	new team = Player[playerid][Team]; // Player team
	// Each game type has its own rules and settings so we have to do some more checks...
	switch(GameType)
	{
		case BASE:
		{
			// Check if limit exceeded
			if(GunmenuData[index][TimesSelected][team] >= GunmenuData[index][GunLimit])
			{
				SendErrorMessage(playerid, sprintf("This weapon is no longer available because limit has exceeded. [%d/%d]", GunmenuData[index][GunLimit], GunmenuData[index][GunLimit]), messagebox_type);
				return false;
			}
			if(GunmenuRestrictions) // If gunmenu selection restriction is present
			{
				// Make sure players won't have Spas and Sniper/Deagle/M4
				if(weaponid == WEAPON_SHOTGSPA)
				{
					if(DoesPlayerHaveWeapon(playerid, WEAPON_SNIPER))
					{
						SendErrorMessage(playerid, "You cannot get spas and sniper!", messagebox_type);
						return false;
					}
					else if(DoesPlayerHaveWeapon(playerid, WEAPON_DEAGLE))
					{
						SendErrorMessage(playerid, "You cannot get spas and deagle!", messagebox_type);
						return false;
					}
					else if(DoesPlayerHaveWeapon(playerid, WEAPON_M4))
					{
						SendErrorMessage(playerid, "You cannot get spas and M4!", messagebox_type);
						return false;
					}
				}
				// Make sure players won't have Sniper and Spas/Deagle/M4
				else if(weaponid == WEAPON_SNIPER)
				{
					if(DoesPlayerHaveWeapon(playerid, WEAPON_SHOTGSPA))
					{
						SendErrorMessage(playerid, "You cannot get spas and sniper!", messagebox_type);
						return false;
					}
					else if(DoesPlayerHaveWeapon(playerid, WEAPON_DEAGLE))
					{
						SendErrorMessage(playerid, "You cannot get sniper and deagle!", messagebox_type);
						return false;
					}
					else if(DoesPlayerHaveWeapon(playerid, WEAPON_M4))
					{
						SendErrorMessage(playerid, "You cannot get sniper and M4!", messagebox_type);
						return false;
					}
				}
				// Make sure players won't have Deagle and Spas/Sniper/M4
				else if(weaponid == WEAPON_DEAGLE)
				{
					if(DoesPlayerHaveWeapon(playerid, WEAPON_SHOTGSPA))
					{
						SendErrorMessage(playerid, "You cannot get spas and deagle!", messagebox_type);
						return false;
					}
					else if(DoesPlayerHaveWeapon(playerid, WEAPON_SNIPER))
					{
						SendErrorMessage(playerid, "You cannot get deagle and sniper!", messagebox_type);
						return false;
					}
					else if(DoesPlayerHaveWeapon(playerid, WEAPON_M4))
					{
						SendErrorMessage(playerid, "You cannot get deagle and M4!", messagebox_type);
						return false;
					}
				}
				// Make sure players won't have M4 and Spas/Deagle/Sniper/Rifle
				else if(weaponid == WEAPON_M4)
				{
					if(DoesPlayerHaveWeapon(playerid, WEAPON_SHOTGSPA))
					{
						SendErrorMessage(playerid, "You cannot get M4 and spas!", messagebox_type);
						return false;
					}
					else if(DoesPlayerHaveWeapon(playerid, WEAPON_DEAGLE))
					{
						SendErrorMessage(playerid, "You cannot get M4 and deagle!", messagebox_type);
						return false;
					}
					else if(DoesPlayerHaveWeapon(playerid, WEAPON_SNIPER))
					{
						SendErrorMessage(playerid, "You cannot get m4 and sniper!", messagebox_type);
						return false;
					}
					else if(DoesPlayerHaveWeapon(playerid, WEAPON_RIFLE))
					{
						SendErrorMessage(playerid, "You cannot get rifle and m4!", messagebox_type);
						return false;
					}
				}
				// Make sure players won't have Rifle and M4
				else if(weaponid == WEAPON_RIFLE)
				{
					if(DoesPlayerHaveWeapon(playerid, WEAPON_M4))
					{
						SendErrorMessage(playerid, "You cannot get rifle and M4!", messagebox_type);
						return false;
					}
				}
			}
		}
		case ARENA:
		{
			// Check if limit exceeded
			if(GunmenuData[index][GunLimit] <= 0)
			{
				SendErrorMessage(playerid, "This weapon is disabled", messagebox_type);
				return false;
			}
			// Make sure players won't have Spas in Arenas
			if(weaponid == WEAPON_SHOTGSPA)
			{
				SendErrorMessage(playerid, "Spas is not allowed in Arenas!", messagebox_type);
				return false;
			}
		}
	}
	return true;
}

OnGunmenuDialogResponse(playerid, response, listitem)
{
	switch(response)
	{
		case 0: // Clicked  "Reset"
		{
			ResetPlayerGunmenu(playerid, true);
			MessageBox(playerid, MSGBOX_TYPE_TOP, "~g~~h~Inventory", "Your weapon inventory is empty now", 3000);
		}
		case 1: // Clicked "Pick"
		{
			if(IsGunSelectionOkay(playerid, GunmenuData[listitem][GunID], listitem))
			{
				GivePlayerGunmenuWeapon(playerid, listitem);
				PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);
			}
			else
			{
				ShowGunmenuDialog(playerid);
			}
		}
	}
}

OnGunObjectMovedToPlayer(playerid, objectid, index)
{
	SetPlayerArmedWeapon(playerid, GunmenuData[index][GunID]);
	new tmpWeapID, tmpAmmo, slot;
	slot = GetWeaponSlot(GunmenuData[index][GunID]);
	new str[256];
	format(str, sizeof str, "~w~");
	for(new i = 1; i < 13; i ++)
	{
		if(i == slot)
		{
			tmpWeapID = GunmenuData[index][GunID];
			tmpAmmo = GunmenuData[index][GunAmmo];
		}
		else
			GetPlayerWeaponData(playerid, i, tmpWeapID, tmpAmmo);

		if(tmpWeapID == 0)
			continue;

		if(tmpWeapID == GunmenuData[index][GunID])
		{
			format(str, sizeof str, "%s~g~~h~~h~%s ~h~(newly added)~w~~n~", str, WeaponNames[tmpWeapID]);
		}
		else
			format(str, sizeof str, "%s%s~n~", str, WeaponNames[tmpWeapID]);
	}
	MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~b~~h~~h~added to gun inventory", str, 4000);
	if(IsBulletWeapon(GunmenuData[index][GunID]))
	{
		ApplyAnimation(playerid, "PYTHON", "python_reload", 4.1, 0, 0, 0, 0, 0, 1);
		PlayerPlaySound(playerid, 36401, 0.0, 0.0, 0.0);
	}
	Iter_Remove(PlayerGunObjects[playerid], objectid);
	DestroyPlayerObject(playerid, objectid);
	DestroyPlayerObject(playerid, GunmenuData[index][GunFlamePlayerObject][playerid]);
	return 1;
}

GivePlayerGunmenuWeapon(playerid, index)
{
	new
		weaponid = GunmenuData[index][GunID],
		team = Player[playerid][Team];
	if(DoesPlayerHaveWeapon(playerid, weaponid))
		RemovePlayerWeapon(playerid, weaponid);

	GunmenuData[index][HasGun][playerid] = true; // Indicate that they have this weapon now from gunmenu
	GunmenuData[index][TimesSelected][team] ++; // Indicate how many times this weapon is selected in this team (by increasing 1 everytime a player selects)
	GivePlayerWeapon(playerid, weaponid, GunmenuData[index][GunAmmo]);
	SetPlayerArmedWeapon(playerid, 0);
	// Update limits for other players (for both styles: dialog and objects)
	UpdateGunmenuLimitsTextDraw(Player[playerid][Team]);
	// Count how many weapons they've got so far
	new ct = 0;
	for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
	{
		if(GunmenuData[i][HasGun][playerid])
			ct ++;
	}
	// Check if they've selected enough weapons
	if(ct >= 2)
	{
		OnPlayerFinishGunmenu(playerid);
	}
	else if(Player[playerid][GunmenuStyle] == GUNMENU_STYLE_DIALOG)
		ShowGunmenuDialog(playerid);
}

OnPlayerSelectGunmenuObject(playerid, objectid, modelid)
{
	// Having got modelid here, we can make a very smart guess :P
	// Basically we will loop through all gunmenu slots and pick the
	// one that has the same modelid as the one we've got here
	new gunmenuIndex = -1;
	for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
	{
		if(GunmenuData[i][GunModel] == modelid)
		{
			// Alright, we've found the slot that has the same modelid
			// Let's store it in our variable because we're gonna need
			// it outside of this loop
			gunmenuIndex = i;
			// we aren't searching for the slot anymore so let's break outta loop
			break;
		}
	}
	if(gunmenuIndex == -1)
	{
		//printf("DEBUG: error from gunmenu: couldn't find the slot for modelid: %d", modelid);
		return 0;
	}
	if(IsGunSelectionOkay(playerid, GunmenuData[gunmenuIndex][GunID], gunmenuIndex))
	{
		GivePlayerGunmenuWeapon(playerid, gunmenuIndex);
		SelectObject(playerid);
		PlayerPlaySound(playerid, 5203, 0.0, 0.0, 0.0);
		// Movement
		if(IsPlayerObjectMoving(playerid, objectid))
			StopPlayerObject(playerid, objectid);
		new
			Float:x[2], Float:y[2], Float:z[2],
			Float:rotX, Float:rotY, Float:rotZ;
		GetPlayerPos(playerid, x[0], y[0], z[0]);
		GetPlayerObjectPos(playerid, objectid, x[1], y[1], z[1]);
		GetPlayerObjectRot(playerid, objectid, rotX, rotY, rotZ);
		GunmenuData[gunmenuIndex][GunMovingRoute][playerid] = GUN_MOVING_ROUTE_TOPLAYER;
		GunmenuData[gunmenuIndex][GunFlamePlayerObject][playerid] = CreatePlayerObject(playerid, 18689, x[1], y[1], z[1] - 1.3, 0.0, 0.0, 0.0, 0.0); // flame effect object
		// todo: color model
		//for(new i = 0; i != 10; i ++)
		//	SetPlayerObjectMaterial(playerid, objectid, i, 3858, "ottos_glass", "carshowroom1", 0xFF000000);
		MovePlayerObject(
			playerid,
			GunmenuData[gunmenuIndex][GunFlamePlayerObject][playerid],
			x[0],
			y[0],
			z[1] - 1.3,
			GetPlayerDistanceFromPoint(playerid, x[1], y[1], z[1])
			);
		MovePlayerObject(
			playerid,
			objectid,
			x[0],
			y[0],
			z[1],
			GetPlayerDistanceFromPoint(playerid, x[1], y[1], z[1]),
			rotX,
			rotY,
			rotZ + 180.0
			);
	}
	return 1;
}

OnPlayerFinishGunmenu(playerid)
{
	HidePlayerGunmenu(playerid);
	new str[200];
	format(str, sizeof str, "%s%s {FFFFFF}has finished equiping their inventory (%s", TextColor[Player[playerid][Team]], Player[playerid][NameWithoutTag], TextColor[Player[playerid][Team]]);
	new ct = 0, weap;
	for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
	{
		if(GunmenuData[i][HasGun][playerid])
		{
			weap = GunmenuData[i][GunID];
			if(weap == 0)
				continue;

			if(ct == 0)
			{
				format(str, sizeof str, "%s%s", str, WeaponNames[weap]);
				ct ++;
			}
			else
				format(str, sizeof str, "%s / %s", str, WeaponNames[weap]);
		}
	}
	format(str, sizeof str, "%s{FFFFFF})", str);
	foreach(new i : Player)
	{
		if(IsTeamTheSame(Player[playerid][Team], Player[i][Team]))
		{
			SendClientMessage(i, -1, str);
		}
	}
	ShowGunmenuHelp(playerid);
	SetTimerEx("AimbotCheck", 3000, false, "i", playerid);
}

forward ShowPlayerMeleeWeaponsMenu(playerid);
public ShowPlayerMeleeWeaponsMenu(playerid)
{
	new str[256], weap;
	for(new i = 0; i != sizeof MeleeWeaponsArray_ID; ++i)
	{
		weap = MeleeWeaponsArray_ID[i];
		format(str, sizeof str, "%s\n%s%s", str, (DoesPlayerHaveWeapon(playerid, weap) ? ("{DB5858}"):("{50EB50}")), WeaponNames[weap]);
	}
	ShowPlayerDialog(playerid, DIALOG_GUNMENU_MELEE, DIALOG_STYLE_LIST, "Melee weapons", str, "Get", "Close");
}
