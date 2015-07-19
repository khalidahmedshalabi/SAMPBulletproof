/*

	Guns selection script

*/

#include "modules\header\gunmenu.txt"

LoadGunmenuData()
{
	// todo: use database
	new idx = 0;
	GunmenuData[idx][GunID] = WEAPON_KNIFE;
	GunmenuData[idx][GunModel] = 335;
	GunmenuData[idx][GunLimit] = MAX_PLAYERS;
	GunmenuData[idx][GunAmmo] = 1;
	idx ++;
	GunmenuData[idx][GunID] = WEAPON_GRENADE;
	GunmenuData[idx][GunModel] = 342;
	GunmenuData[idx][GunLimit] = MAX_PLAYERS;
	GunmenuData[idx][GunAmmo] = GRENADE_AMMO;
	idx ++;
	GunmenuData[idx][GunID] = WEAPON_TEARGAS;
	GunmenuData[idx][GunModel] = 343;
	GunmenuData[idx][GunLimit] = MAX_PLAYERS;
	GunmenuData[idx][GunAmmo] = 1;
	idx ++;
	GunmenuData[idx][GunID] = WEAPON_SILENCED;
	GunmenuData[idx][GunModel] = 347;
	GunmenuData[idx][GunLimit] = MAX_PLAYERS;
	GunmenuData[idx][GunAmmo] = 9999;
	idx ++;
	GunmenuData[idx][GunID] = WEAPON_DEAGLE;
	GunmenuData[idx][GunModel] = 348;
	GunmenuData[idx][GunLimit] = 1;
	GunmenuData[idx][GunAmmo] = 9999;
	idx ++;
	GunmenuData[idx][GunID] = WEAPON_SHOTGUN;
	GunmenuData[idx][GunModel] = 349;
	GunmenuData[idx][GunLimit] = MAX_PLAYERS;
	GunmenuData[idx][GunAmmo] = 9999;
	idx ++;
	GunmenuData[idx][GunID] = WEAPON_SHOTGSPA;
	GunmenuData[idx][GunModel] = 351;
	GunmenuData[idx][GunLimit] = 1;
	GunmenuData[idx][GunAmmo] = 9999;
	idx ++;
	GunmenuData[idx][GunID] = WEAPON_MP5;
	GunmenuData[idx][GunModel] = 353;
	GunmenuData[idx][GunLimit] = MAX_PLAYERS;
	GunmenuData[idx][GunAmmo] = 9999;
	idx ++;
	GunmenuData[idx][GunID] = WEAPON_AK47;
	GunmenuData[idx][GunModel] = 355;
	GunmenuData[idx][GunLimit] = MAX_PLAYERS;
	GunmenuData[idx][GunAmmo] = 9999;
	idx ++;
	GunmenuData[idx][GunID] = WEAPON_M4;
	GunmenuData[idx][GunModel] = 356;
	GunmenuData[idx][GunLimit] = MAX_PLAYERS;
	GunmenuData[idx][GunAmmo] = 9999;
	idx ++;
	GunmenuData[idx][GunID] = WEAPON_RIFLE;
	GunmenuData[idx][GunModel] = 357;
	GunmenuData[idx][GunLimit] = MAX_PLAYERS;
	GunmenuData[idx][GunAmmo] = 9999;
	idx ++;
	GunmenuData[idx][GunID] = WEAPON_SNIPER;
	GunmenuData[idx][GunModel] = 358;
	GunmenuData[idx][GunLimit] = 1;
	GunmenuData[idx][GunAmmo] = 9999;
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
	#if GTAV_SWITCH_MENU != 0
	MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~b~~h~~h~gunmenu help", "Changed mind? Type /gunmenu again!~n~Code your own weapon key binds by using ~r~~h~/weaponbinds~n~Press ~r~~h~~k~~VEHICLE_ENTER_EXIT~ ~w~for quicker gun switching", 4000);
	#else
	MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~b~~h~~h~gunmenu help", "Changed mind? Type /gunmenu again!~n~Code your own weapon key binds by using ~r~~h~/weaponbinds", 4000);
	#endif
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
		case GUNMENU_STYLE_DIALOG:
		{
			HideDialogs(playerid);
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
			new str[GUNMENU_LIMIT_DIALOG_SIZE];
			format(str, sizeof str, "Weapon\tAmmo\tPicked / Limit\n{FFFFFF}Reset my weapons and restart selections!");
			new team = Player[playerid][Team];
			for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
			{
				// Do some coloring for items
				if(GunmenuData[i][HasGun][playerid]) // already got this weapon
				{
					format(str, sizeof str, "%s\n{DB5858}%s\t%d\t%d / %d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][GunAmmo], GunmenuData[i][TimesSelected][team], GunmenuData[i][GunLimit]);
				}
				else if(GunmenuData[i][TimesSelected][team] < GunmenuData[i][GunLimit]) // available
				{
					format(str, sizeof str, "%s\n{50EB50}%s\t%d\t%d / %d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][GunAmmo], GunmenuData[i][TimesSelected][team], GunmenuData[i][GunLimit]);
				}
				else // unavailable
				{
					format(str, sizeof str, "%s\n{696969}%s\t%d\t%d / %d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][GunAmmo], GunmenuData[i][TimesSelected][team], GunmenuData[i][GunLimit]);
				}
			}
			ShowPlayerDialog(playerid, DIALOG_GUNMENU, DIALOG_STYLE_TABLIST_HEADERS, "Gunmenu", str, "Pick", "Done");
		}
		case ARENA:
		{
			new str[550];
			format(str, sizeof str, "Weapon\tTimes Picked\n{FFFFFF}Reset my weapons and restart selections!");
			new team = Player[playerid][Team];
			for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
			{
				// Do some coloring for items
				if(GunmenuData[i][HasGun][playerid]) // already got this weapon
				{
					format(str, sizeof str, "%s\n{DB5858}%s\t%d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][team]);
				}
				else // available
				{
					format(str, sizeof str, "%s\n{50EB50}%s\t%d", str, WeaponNames[GunmenuData[i][GunID]], GunmenuData[i][TimesSelected][team]);
				}
			}
			ShowPlayerDialog(playerid, DIALOG_GUNMENU, DIALOG_STYLE_TABLIST_HEADERS, "Gunmenu", str, "Pick", "Done");
		}
	}
}

forward FreezePlayerPlane(playerid, planeid);
public FreezePlayerPlane(playerid, planeid)
{
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
			SendClientMessage(playerid, -1, ""COL_PRIM"Type {FFFFFF}/done "COL_PRIM"when you finish selecting guns or {FFFFFF}/reset "COL_PRIM"to restart selection");
			// Create gun objects for them... (I'm not a math teacher so don't explain heavy documentation)
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
			if(GunmenuData[index][TimesSelected][team] == GunmenuData[index][GunLimit])
			{
				SendErrorMessage(playerid, sprintf("This weapon is no longer available because limit has exceeded. [%d/%d]", GunmenuData[index][GunLimit], GunmenuData[index][GunLimit]), messagebox_type);
				return false;
			}
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
		case ARENA:
		{
			// Make sure players won't have Spas in Arenas
			if(weaponid == WEAPON_SHOTGSPA)
			{
				SendErrorMessage(playerid, "Spas is not allowed in Arenas!", messagebox_type);
				return false;
			}
			// Make sure players won't have more than 2 bullet weapons in Arenas
			if(IsBulletWeapon(weaponid))
			{
				new ct = 0;
				for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
				{
					if(IsBulletWeapon(GunmenuData[i][GunID]) && GunmenuData[i][HasGun][playerid])
						ct ++;
				}
				if(ct >= 2)
				{
					SendErrorMessage(playerid, "You cannot have more than 2 weapons in Arenas!", messagebox_type);
					return false;
				}
			}
		}
	}
	return true;
}

OnGunmenuDialogResponse(playerid, response, listitem)
{
	switch(response)
	{
		case 0: // Clicked  "Done"
		{
			HidePlayerGunmenu(playerid);
			new str[200];
			format(str, sizeof str, "%s%s {FFFFFF}has finished equiping their inventory (%s", TextColor[Player[playerid][Team]], Player[playerid][NameWithoutTag], TextColor[Player[playerid][Team]]);
			new w, a, ct;
			for(new i = 0; i < 13; i ++)
			{
			    GetPlayerWeaponData(playerid, i, w, a);
			    if(w == 0)
			        continue;

	      		if(ct == 0)
	      		{
	      		    format(str, sizeof str, "%s%s", str, WeaponNames[w]);
	                ct ++;
				}
	      		else
			    	format(str, sizeof str, "%s / %s", str, WeaponNames[w]);


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
			ShowPlayerWeaponBindTextDraw(playerid, 5000);
		}
		case 1: // Clicked "Pick"
		{
			switch(listitem)
			{
				case 0: // Reset
				{
					ResetPlayerGunmenu(playerid, true);
					MessageBox(playerid, MSGBOX_TYPE_TOP, "~g~~h~~h~emptied inventory", " ", 3000);
				}
				default: // Picked a weapon
				{
					new gunmenuIndex = listitem - 1;
					if(IsGunSelectionOkay(playerid, GunmenuData[gunmenuIndex][GunID], gunmenuIndex))
					{
						GivePlayerGunmenuWeapon(playerid, gunmenuIndex);
						PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);
					}
					else
					{
						ShowGunmenuDialog(playerid);
					}
				}
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
	foreach(new i : Player)
	{
		if(Player[i][OnGunmenu] && Player[i][GunmenuStyle] == GUNMENU_STYLE_DIALOG)
			ShowGunmenuDialog(playerid);
	}
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