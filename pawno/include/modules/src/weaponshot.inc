/*
		Weapon shots handler
		Mostly used for the Take/Give damage callbacks
*/

#include "modules\header\weaponshot.txt"


/*
	Quoted from Slice who (AFAIK) created this weapon ranges array,
	"...Note that due to various bugs, these can be exceeded, but...".
	This function (adjusts) increases the values of this array which
	hopefully will make them less buggy...

*/
AdjustWeaponRanges()
{
	for(new i = 0; i < sizeof(WeaponRanges); i ++)
	{
		if(WeaponRanges[i] == 0.0)
			continue;
		
		WeaponRanges[i] += WEAPON_RANGES_ADD;
	}
}

IsBulletWeapon(weaponid)
{
	return (WEAPON_COLT45 <= weaponid <= WEAPON_SNIPER) || weaponid == WEAPON_MINIGUN;
}

IsMeleeWeapon(weaponid)
{
	return (0 <= weaponid <= WEAPON_KATANA) || (WEAPON_DILDO <= weaponid <= WEAPON_CANE) || weaponid == 48;
}

bool:IsValidHitRange(hittedid, hitterid, weaponid, &Float:distance)
{
	if(hitterid == INVALID_PLAYER_ID)
		return true;

	if(IsBulletWeapon(weaponid)) 
	{
		new Float:x, Float:y, Float:z;
		GetPlayerPos(hitterid, x, y, z);
		distance = GetPlayerDistanceFromPoint(hittedid, x, y, z);
		if(distance > WeaponRanges[weaponid]) 
		{
			return false;
		}
	}
	return true;
}

bool:IsValidWeaponDamageAmount(weaponid, Float:amount)
{
	new Float:bullets;
	switch (weaponid) 
	{
		// The spas shotguns shoot 8 bullets, each inflicting 4.95 damage
		case WEAPON_SHOTGSPA: 
		{
			bullets = amount / 4.950000286102294921875;
	 
			if (8.0 - bullets < -0.05) 
			{
				return false;
			}
		}
	 
		// Shotguns and sawed-off shotguns shoot 15 bullets, each inflicting 3.3 damage
		case WEAPON_SHOTGUN, WEAPON_SAWEDOFF:
		{
			bullets = amount / 3.30000019073486328125;
	 
			if (15.0 - bullets < -0.05) 
			{
				return false;
			}
		}
	}
 
	if (_:bullets) 
	{
		new Float:f = floatfract(bullets);

		// The damage for each bullet has been tampered with
		if (f > 0.01 && f < 0.99) 
		{
			return false;
		}

		// Divide the damage amount by the number of bullets
		amount /= bullets;
	}

	// Check chainsaw damage
	if (weaponid == WEAPON_CHAINSAW) 
	{
		switch (amount) 
		{
			case 6.6000003814697265625,
			13.5300006866455078125,
			16.1700000762939453125,
			26.40000152587890625,
			27.060001373291015625: {}

			default:
			{
				return false;
			}
		}
	}

	// Check gun damage
	new Float:def_amount = 0.0;

	switch (weaponid) 
	{
		case WEAPON_COLT45,
		WEAPON_MP5: def_amount = 8.25;
		case WEAPON_SILENCED: def_amount = 13.200000762939453125;
		case WEAPON_DEAGLE: def_amount = 46.200000762939453125;
		case WEAPON_UZI,
		WEAPON_TEC9: def_amount = 6.6000003814697265625;
		case WEAPON_AK47,
		WEAPON_M4: def_amount = 9.90000057220458984375;
		case WEAPON_RIFLE: def_amount = 24.7500019073486328125;
		case WEAPON_SNIPER: def_amount = 41.25;
		case WEAPON_MINIGUN: def_amount = 46.200000762939453125;
		case WEAPON_VEHICLE: def_amount = 9.90000057220458984375;
	}

	if (_:def_amount && _:def_amount != _:amount) 
	{
		return false;
	}

	//todo: melee damages.
	/*
	1.32000005245208740234375
	1.650000095367431640625
	1.980000019073486328125
	2.3100001811981201171875
	2.6400001049041748046875
	2.9700000286102294921875
	3.96000003814697265625
	4.28999996185302734375
	4.62000036239624023437
	5.280000209808349609375
	6.6000003814697265625
	54.12000274658203125*/
	return true;
}

/*
This fixes Health/Armour bars* from going out of sync
(*) Bars which are above a player body/skin
*/
SetFakeHealthArmour(playerid)
{
	// Set fake hp (will cause hp/armour flicker unless a good syncing plugin is used)
	SetHP(playerid, Player[playerid][pHealth]);
	SetAP(playerid, Player[playerid][pArmour]);
}

SetHP(playerid, amount)
{
	new bool:WasPlaying = false;
	if(Player[playerid][Playing])
		WasPlaying = true;
	if(amount <= 0)
	{
		if(Player[playerid][AlreadyDying])
			return 0;
		
		Player[playerid][AlreadyDying] = true;
	    SetTimerEx("ServerOnPlayerDeath", SERVER_PlAYER_DEATH_DELAY, false, "iii", playerid, Player[playerid][HitBy], Player[playerid][HitWith]);
	    HidePlayerProgressBar(playerid, HealthBar[playerid]);
		Player[playerid][pHealth] = 0;
		SetPlayerScore(playerid, 0);
		SetPlayerHealth(playerid, 65536);
		SetPlayerArmedWeapon(playerid, 0);
		SetPlayerArmour(playerid, 0);
		Player[playerid][pArmour] = 0;
	}
	else
	{
		SetPlayerProgressBarValue(playerid, HealthBar[playerid], amount);
		Player[playerid][pHealth] = amount;
		SetPlayerHealth(playerid, 65536 + amount);
		if(Player[playerid][Playing])
		{
			SetPlayerScore(playerid, Player[playerid][pHealth] + Player[playerid][pArmour]);
		}
		else
		{
			if(GetPlayerScore(playerid) != 0)
				SetPlayerScore(playerid, 0);
		}
		if(Player[playerid][Spawned])
		{
			if(IsPlayerProgressBarShown(playerid, HealthBar[playerid]) == false)
				ShowPlayerProgressBar(playerid, HealthBar[playerid]);
		}
		else
		{
			if(IsPlayerProgressBarShown(playerid, HealthBar[playerid]) == true)
				HidePlayerProgressBar(playerid, HealthBar[playerid]);
		}
	}
	UpdatePlayerTeamBar(playerid);
	if(WasPlaying)
		UpdateTeamHP(Player[playerid][Team]);
	
	if(PlayerInterface[playerid][INTERFACE_HP])
	{
		if(FallProtection == false)
		{
			PlayerTextDrawSetString(playerid, HPTextDraw_TD[playerid], sprintf("%s%d", MAIN_TEXT_COLOUR, Player[playerid][pHealth]));
		}
		else
		{
			if(Player[playerid][Playing] == true)
				PlayerTextDrawSetString(playerid, HPTextDraw_TD[playerid], sprintf("%sFall Prot.", MAIN_TEXT_COLOUR));
			else
			{
				PlayerTextDrawSetString(playerid, HPTextDraw_TD[playerid], sprintf("%s%d", MAIN_TEXT_COLOUR, Player[playerid][pHealth]));
			}
		}
	}
	return 1;
}

SetAP(playerid, amount)
{
	if(amount <= 0)
	{
	    SetPlayerArmour(playerid, 0.0);
	    HidePlayerProgressBar(playerid, ArmourBar[playerid]);
		Player[playerid][pArmour] = 0;
		if(Player[playerid][Playing])
		{
			SetPlayerScore(playerid, Player[playerid][pHealth] + Player[playerid][pArmour]);
		}
		else
		{
			if(GetPlayerScore(playerid) != 0)
				SetPlayerScore(playerid, 0);
		}
	}
	else
	{
		SetPlayerProgressBarValue(playerid, ArmourBar[playerid], amount);
		Player[playerid][pArmour] = amount;
		SetPlayerArmour(playerid, 65536 + amount);
		if(Player[playerid][Playing])
		{
			SetPlayerScore(playerid, Player[playerid][pHealth] + Player[playerid][pArmour]);
		}
		else
		{
			if(GetPlayerScore(playerid) != 0)
				SetPlayerScore(playerid, 0);
		}
		if(Player[playerid][Spawned])
		{
			if(IsPlayerProgressBarShown(playerid, ArmourBar[playerid]) == false)
				ShowPlayerProgressBar(playerid, ArmourBar[playerid]);
		}
		else
		{
			if(IsPlayerProgressBarShown(playerid, ArmourBar[playerid]) == true)
				HidePlayerProgressBar(playerid, ArmourBar[playerid]);
		}
	}
	UpdatePlayerTeamBar(playerid);
	if(Player[playerid][Playing])
		UpdateTeamHP(Player[playerid][Team]);
	if(PlayerInterface[playerid][INTERFACE_HP])
	{
		if(Player[playerid][pArmour] > 0) 
		{
			PlayerTextDrawSetString(playerid, ArmourTextDraw[playerid], sprintf("%s~h~~h~%d", MAIN_TEXT_COLOUR, Player[playerid][pArmour]));
		} 
		else 
		{
			PlayerTextDrawSetString(playerid, ArmourTextDraw[playerid], "_");
		}
	}
	return 1;
}

GetHP(playerid, &health)
{
	health = Player[playerid][pHealth];
	return 1;
}

GetAP(playerid, &armour)
{
	armour = Player[playerid][pArmour];
	return 1;
}

/*
This is used to make sure a head-shot is legit and successful
then announce it. This function has return values as well.
Returns 0 on failure (illegal/rejected headshots) and returns 1 on success.
*/
HandleHeadshot(playerid, issuerid, weaponid)
{
	if(issuerid != INVALID_PLAYER_ID) // Headshots can't be done on their own, can they?
	{
		if(Player[playerid][Playing] == true && Player[issuerid][Playing] == true && IsTeamTheSame(Player[playerid][Team], Player[issuerid][Team]))
			return 0; // This headshot is illegal (team fire while playing?), get out of this block!

		switch(weaponid)
		{
			case WEAPON_SNIPER:
			{
				#if defined _league_included
				if(LeagueMode && Player[issuerid][Playing] && Current != -1)
				{
					AddPlayerLeaguePoints(issuerid, 50, "hitting a big head");
				}
				#endif
				MessageBox(issuerid, MSGBOX_TYPE_TOP, "~g~~h~Headshot~n~~g~~h~~h~Sniper", " ", 2000);
				SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has landed a hit on {FFFFFF}%s's "COL_PRIM"head "COL_PRIM"({FFFFFF}Sniper"COL_PRIM")", Player[issuerid][Name], Player[playerid][Name]));
			}
			case WEAPON_RIFLE:
			{
				#if defined _league_included
				if(LeagueMode && Player[issuerid][Playing] && Current != -1)
				{
					AddPlayerLeaguePoints(issuerid, 50, "hitting a big head");
				}
				#endif
				MessageBox(issuerid, MSGBOX_TYPE_TOP, "~g~~h~Headshot~n~~g~~h~~h~Rifle", " ", 2000);
				SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has landed a hit on {FFFFFF}%s's "COL_PRIM"head "COL_PRIM"({FFFFFF}Rifle"COL_PRIM")", Player[issuerid][Name], Player[playerid][Name]));
			}
			case WEAPON_DEAGLE:
			{
				#if defined _league_included
				if(LeagueMode && Player[issuerid][Playing] && Current != -1)
				{
					AddPlayerLeaguePoints(issuerid, 50, "hitting a big head");
				}
				#endif
				MessageBox(issuerid, MSGBOX_TYPE_TOP, "~g~~h~Headshot~n~~g~~h~~h~Deagle", " ", 2000);
				SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has landed a hit on {FFFFFF}%s's "COL_PRIM"head "COL_PRIM"({FFFFFF}Deagle"COL_PRIM")", Player[issuerid][Name], Player[playerid][Name]));
			}
		}
	}
	return 1;
}

/*
This function is used to get the actual/realistic
damage that could be done on a player. An example of use,
a player has 30 HP and he's hit with a deagle which makes
nearly 46 damage. Here comes the use of this function,
it detects that and adjust the amount of damage reported
to an actual amount (30 in our example, not 46)

In addition to that, it converts the amount from a float value to an integer value.
*/
GetActualDamage(Float:amount, playerid)
{
	/*
	PARAMETERS:
	playerid is the player who got damaged.
	amount is the amount of damage done on 'playerid' which is expected to be unreal.
	*/
	new amt = floatround(amount, floatround_round);
	if(Player[playerid][pHealth] > 0)  // If they're not dead
	{
		if(Player[playerid][pArmour] > 0)
		{
			// If this damage is not real and has to be cut
			if(amt > Player[playerid][pHealth] + Player[playerid][pArmour])
			{
				// Cut it and return the actual damage
				return (Player[playerid][pHealth] + Player[playerid][pArmour]);
			}
		}
		else
		{
			if(amt > Player[playerid][pHealth]) // If this damage is not real and has to be cut
			{
				// Cut it and return the actual damage
				return Player[playerid][pHealth];
			}
		}
	}
	return amt; // Damage is already real, send it back!
}

// Initializes iterators arrays for taken/given damage script
InitVisualDamage()
{	
	Iter_Init(PlayersDamaged);
	Iter_Init(PlayersDamagedBy);
}

InitPlayerVisualDamage(playerid)
{
	for(new i = 0; i < MAX_VISUAL_DAMAGES; i ++)
	{
		VisualDamage[playerid][ShownTakenDamage][i] = false;
		VisualDamage[playerid][ShownGivenDamage][i] = false;
	}
	Iter_Clear(PlayersDamaged[playerid]);
	Iter_Clear(PlayersDamagedBy[playerid]);
	Iter_Remove(PlayerHasGVisualDmg, playerid);
	Iter_Remove(PlayerHasTVisualDmg, playerid);
	
}
	
// This basically checks if a damage textdraw has been shown for a specific/pre-defined time, then hide it
// Usually placed in a frequently called timer
CheckVisualDamageTextDraws()
{
	if(Iter_Count(PlayerHasGVisualDmg) != 0) // If there are players with given-damage textdraws
	{
		new 
			tick = GetTickCount(), // current tick count
			ct; 				// will be used to indicate whether a iterator slot should be removed or not
							
		foreach(new i : PlayerHasGVisualDmg) // Loop through all players that has given-damage textdraw shown for them
		{
			new cur = i;
			ct = 0; // initialize the variable every time
			for(new j = 0; j < MAX_VISUAL_DAMAGES; j ++) // Loop through all the damage textdraws a single player can have
			{
				// Check if this textdraw (by slot) is still shown while enough (PRE-DEFINED: HIDE_DAMAGE_TEXTDRAW_AFTER) time has passed
				if(VisualDamage[cur][ShownGivenDamage][j] == true)
				{
					if((tick - VisualDamage[cur][GivenDamageTick]) > HIDE_DAMAGE_TEXTDRAW_AFTER)
					{
						VisualDamage[cur][ShownGivenDamage][j] = false; // Indicates that it's hidden now
						if(VisualDamage[cur][DamagingWho][j] != NO_DAMAGER_UNIQUE_ID)
							Iter_Remove(PlayersDamaged[cur], VisualDamage[cur][DamagingWho][j]); // Remove the player whom this player put damage on
						PlayerTextDrawSetString(cur, DoingDamage[cur][j], "_"); // Hide it
						ct ++; // Increase count of textdraws found
					}
				}
			}
			if(ct != 0) // If found any textdraws, that should be hidden, shown to this player
				Iter_SafeRemove(PlayerHasGVisualDmg, cur, i); // Safely remove him from the iterator array.
		}
	}
	if(Iter_Count(PlayerHasTVisualDmg) != 0) // If there are players with taken-damage textdraws
	{
		new 
			tick = GetTickCount(), // current tick count
			ct;					// will be used to indicate whether a iterator slot should be removed or not
			
		foreach(new i : PlayerHasTVisualDmg)  // Loop through all players that has taken-damage textdraw shown for them
		{
			new cur = i;
			ct = 0; // initialize the variable every time
			for(new j = 0; j < MAX_VISUAL_DAMAGES; j ++) // Loop through all the damage textdraws a single player can have
			{
				// Check if this textdraw (by slot) is still shown while enough (PRE-DEFINED: HIDE_DAMAGE_TEXTDRAW_AFTER) time has passed
				if(VisualDamage[cur][ShownTakenDamage][j] == true)
				{
					if((tick - VisualDamage[cur][TakenDamageTick]) > HIDE_DAMAGE_TEXTDRAW_AFTER)
					{
						VisualDamage[cur][ShownTakenDamage][j] = false; // Indicates that it's hidden now
						if(VisualDamage[cur][WhoDamaging][j] != NO_DAMAGER_UNIQUE_ID)
							Iter_Remove(PlayersDamagedBy[cur], VisualDamage[cur][WhoDamaging][j]); // Remove the player whom this player put damage on
						PlayerTextDrawSetString(cur, GettingDamaged[cur][j], "_"); // Hide it
						ct ++; // Increase count of textdraws found
					}
				}
			}
			if(ct != 0) // If found any textdraws, that should be hidden, shown to this player
				Iter_SafeRemove(PlayerHasTVisualDmg, cur, i); // Safely remove him from the iterator array.
		}
	}
	return 1;
}

// Basically this enables spectators to see given/taken damage done by whom they are spectating
/*
PARAMETERS:
playerid: the player who has taken/given damage textdraws changed
index: the index of the damage textdraw (maximum limit MAX_VISUAL_DAMAGES)
str: this is a string with info about the damage update
damagetype: 0 for given damage, 1 for taken damage or collision
currenttick: current count tick
*/
ShowVisualDamageForSpectators(playerid, index, str[], damagetype, currenttick)
{
	// See if this player got spectators, if not then we have no one 
	// to show textdraws for hence we return/stop the function process
	if(!Player[playerid][BeingSpeced] || Iter_Count(PlayerSpectators[playerid]) == 0)
		return;
	
	switch(damagetype)
	{
		case 0: // Given damage
		{
			foreach(new i : PlayerSpectators[playerid]) // Loop through the array that contains this player's spectators
			{
				VisualDamage[i][ShownGivenDamage][index] = true; // Indicate that they have a given-damage textdraw
				VisualDamage[i][GivenDamageTick][index] = currenttick; // Set the time when this textdraw was shown on screen
				PlayerTextDrawSetString(i, DoingDamage[i][index], str); // Update textdraw with correct info
				PlayerPlaySound(i, Player[i][HitSound], 0.0, 0.0, 0.0); // Play damage sound
				Iter_Add(PlayerHasGVisualDmg, i); // Add this player to the array that holds the IDs of the players who has given-damage textdraws
			}
		}
		case 1: // Taken damage
		{
			foreach(new i : PlayerSpectators[playerid]) // Loop through the array that contains this player's spectators
			{
				VisualDamage[i][ShownTakenDamage][index] = true; // Indicate that they have a taken-damage textdraw
				VisualDamage[i][TakenDamageTick][index] = currenttick; // Set the time when this textdraw was shown on screen
				PlayerTextDrawSetString(i, GettingDamaged[i][index], str); // Update textdraw with correct info
				PlayerPlaySound(i, Player[i][GetHitSound], 0.0, 0.0, 0.0); // Play damage sound
				Iter_Add(PlayerHasTVisualDmg, i); // Add this player to the array that holds the IDs of the players who has taken-damage textdraws
			}
		}
	}
}

// Creates a bubble above a player's head with damages they take
SetPlayerDamageBubble(playerid)
{
	new str[DAMAGE_BUBBLE_STRING_LENGTH];
	for(new i = 0; i != MAX_VISUAL_DAMAGES; i ++) // Loop through all visual damages a player could take
	{
		// Check if there's a taken damage in this slot
		if(VisualDamage[playerid][ShownTakenDamage][i] == false)
			continue;
		
		if(VisualDamage[playerid][WhoDamaging][i] != NO_DAMAGER_UNIQUE_ID)
		{
			format(str, sizeof str, "%s%s / %s / -%.0f\n", 
			str, 
			Player[VisualDamage[playerid][WhoDamaging][i]][NameWithoutTag], 
			WeaponNames[VisualDamage[playerid][TakenDamageWeapon][i]], 
			VisualDamage[playerid][TDamageTaken][i]);
		}
		else
		{
			format(str, sizeof str, "%s%s / -%.0f\n", 
			str,
			WeaponNames[VisualDamage[playerid][TakenDamageWeapon][i]], 
			VisualDamage[playerid][TDamageTaken][i]);
		}
	}
	SetPlayerChatBubble(playerid, str, 0xFFFFFFEE, 30.0, 3000);
}

// This shows taken and given damage textdraws on damager/damaged player's screen
// Mainly used under On Player Damage callbacks
HandleVisualDamage(playerid, issuerid, Float:amount, weaponid)
{
	new 
		bool:doneOfGivenDmg = false,	// Indicate whether we're done of showing given-damage textdraws or not
		bool:doneOfTakenDmg = false,	// Indicate whether we're done of showing taken-damage textdraws or not
		str[128],						// A string to write the damage info in
		col[7] = "~r~~h~",				// Color of HP remaining of the damaged player (default red)
		tick = GetTickCount(),				// Current tick count
		totHP = (Player[playerid][pHealth] + Player[playerid][pArmour]); // HP remaining of the damaged player
	
	if(totHP >= 100) // If HP remaining is more than 99, then color of text shouldn't be red
		format(col, sizeof col, "%s", MAIN_TEXT_COLOUR); // Set it to server default text color
	
	for(new i = 0; i < MAX_VISUAL_DAMAGES; i ++)
	{
		if(doneOfGivenDmg && doneOfTakenDmg)
			break;
		
		if(doneOfGivenDmg == false) // If we're still not done of given-damage
		{
			if(Iter_Contains(PlayersDamaged[issuerid], playerid)) // If player's already got a damage textdraw, just add to it
			{
				// If this textdraw (of this slot) is shown and the damaged player is the same (the same player of this slot)
				if(VisualDamage[issuerid][ShownGivenDamage][i] == true && VisualDamage[issuerid][DamagingWho][i] == playerid)
				{
					VisualDamage[issuerid][TDamageGiven][i] += amount; // Add to total given damage
					VisualDamage[issuerid][GivenDamageWeapon][i] = weaponid;
					format(str, sizeof(str), "~g~~h~%s	%s/ -%.0f ~g~~h~%s %s[%s~h~%d%s]",  // Write correct damage info into our string
						Player[playerid][NameWithoutTag], MAIN_TEXT_COLOUR, VisualDamage[issuerid][TDamageGiven][i], 
						WeaponNames[weaponid], MAIN_TEXT_COLOUR, col, totHP, MAIN_TEXT_COLOUR);
					PlayerTextDrawSetString(issuerid, DoingDamage[issuerid][i], str); // Update the textdraw with correct info
					VisualDamage[issuerid][GivenDamageTick][i] = tick; // When the last time this damage textdraw was shown
					ShowVisualDamageForSpectators(issuerid, i, str, 0, tick); // Show these textdraws to anyone spectating this player
					doneOfGivenDmg = true; // Useful, tell the loop that we're done of given damage of the damager
				}
			}
			else // If this player has no damage textdraw, then we should be creating a new one
			{
				if(VisualDamage[issuerid][ShownGivenDamage][i] == false) // If this slot has no shown damage textdraws, then let's create one here
				{
					VisualDamage[issuerid][ShownGivenDamage][i] = true; // Point out that this slot has a shown damage textdraw
					VisualDamage[issuerid][TDamageGiven][i] = amount; // Set the given damage
					VisualDamage[issuerid][GivenDamageWeapon][i] = weaponid;
					VisualDamage[issuerid][DamagingWho][i] = playerid; // Assign the ID of the damaged player to the issuer variable
					Iter_Add(PlayersDamaged[issuerid], playerid); // Add this player to damaged players list of the issuer/damager
					Iter_Add(PlayerHasGVisualDmg, issuerid);
					format(str, sizeof(str), "~g~~h~%s	%s/ -%.0f ~g~~h~%s %s[%s~h~%d%s]", 
						Player[playerid][NameWithoutTag], MAIN_TEXT_COLOUR, VisualDamage[issuerid][TDamageGiven][i], 
						WeaponNames[weaponid], MAIN_TEXT_COLOUR, col, totHP, MAIN_TEXT_COLOUR);
					PlayerTextDrawSetString(issuerid, DoingDamage[issuerid][i], str); // Update the textdraw with the correct info
					VisualDamage[issuerid][GivenDamageTick][i] = tick; // When the last time this damage textdraw was shown
					ShowVisualDamageForSpectators(issuerid, i, str, 0, tick); // Show these textdraws to anyone spectating this player
					doneOfGivenDmg = true; // Useful, tell the loop that we're done of given damage of the damager
				}
			}	
		}
		if(doneOfTakenDmg == false)
		{
			if(Iter_Contains(PlayersDamagedBy[playerid], issuerid)) // we should add
			{
				if(VisualDamage[playerid][ShownTakenDamage][i] == true && VisualDamage[playerid][WhoDamaging][i] == issuerid) // add
				{
					VisualDamage[playerid][TDamageTaken][i] += amount;
					VisualDamage[playerid][TakenDamageWeapon][i] = weaponid;
					format(str, sizeof(str), "~r~~h~%s	%s/ -%.0f ~r~~h~%s %s[%s~h~%d%s]", 
						Player[issuerid][NameWithoutTag], MAIN_TEXT_COLOUR, VisualDamage[playerid][TDamageTaken][i], 
						WeaponNames[weaponid], MAIN_TEXT_COLOUR, col, totHP, MAIN_TEXT_COLOUR);
					PlayerTextDrawSetString(playerid, GettingDamaged[playerid][i], str);
					VisualDamage[playerid][TakenDamageTick][i] = tick;
					ShowVisualDamageForSpectators(playerid, i, str, 1, tick);
					SetPlayerDamageBubble(playerid);
					doneOfTakenDmg = true;
				}
			}
			else // we should make new
			{
				if(VisualDamage[playerid][ShownTakenDamage][i] == false) // new
				{
					VisualDamage[playerid][ShownTakenDamage][i] = true;
					VisualDamage[playerid][TDamageTaken][i] = amount;
					VisualDamage[playerid][TakenDamageWeapon][i] = weaponid;
					VisualDamage[playerid][WhoDamaging][i] = issuerid;
					Iter_Add(PlayersDamagedBy[playerid], issuerid);
					Iter_Add(PlayerHasTVisualDmg, playerid);
					format(str, sizeof(str), "~r~~h~%s	%s/ -%.0f ~r~~h~%s %s[%s~h~%d%s]", 
						Player[issuerid][NameWithoutTag], MAIN_TEXT_COLOUR, VisualDamage[playerid][TDamageTaken][i], 
						WeaponNames[weaponid], MAIN_TEXT_COLOUR, col, totHP, MAIN_TEXT_COLOUR);
					PlayerTextDrawSetString(playerid, GettingDamaged[playerid][i], str);
					VisualDamage[playerid][TakenDamageTick][i] = tick;
					ShowVisualDamageForSpectators(playerid, i, str, 1, tick);
					SetPlayerDamageBubble(playerid);
					doneOfTakenDmg = true;
				}
			}	
		}
	}
}

// This is used when no damager is found, for example damage done by collision or explosion etc..
ShowCollisionDamageTextDraw(playerid, Float:amount, weaponid)
{
	new 
		str[128], 
		col[7] = "~r~~h~",
		tick = GetTickCount(),
		freeSlot = -1,
		totHP = (Player[playerid][pHealth] + Player[playerid][pArmour]);
	
	if(totHP >= 100) 
		format(col, sizeof col, "%s", MAIN_TEXT_COLOUR);
	
	for(new i = 0; i < MAX_VISUAL_DAMAGES; i ++) // Loop through all damage textdraws a single player may have
	{
		// If there's already a collision damage textdraw shown, add to it
		if(VisualDamage[playerid][ShownTakenDamage][i] == true && VisualDamage[playerid][WhoDamaging][i] == NO_DAMAGER_UNIQUE_ID)
		{
			VisualDamage[playerid][TDamageTaken][i] += amount; // Add to damage
			VisualDamage[playerid][TakenDamageWeapon][i] = weaponid;
			format(str, sizeof(str), "%s-%.0f ~r~~h~%s %s[%s~h~%d%s]",  // Format the string with correct damage info
				MAIN_TEXT_COLOUR, VisualDamage[playerid][TDamageTaken][i], 
				WeaponNames[weaponid], MAIN_TEXT_COLOUR, col, totHP, MAIN_TEXT_COLOUR);
			PlayerTextDrawSetString(playerid, GettingDamaged[playerid][i], str); // Update damage textdraw with correct damage info
			VisualDamage[playerid][TakenDamageTick][i] = tick; // When the last time this damage textdraw was shown
			ShowVisualDamageForSpectators(playerid, i, str, 1, tick); // Show this update to the spectators of this player as well
			SetPlayerDamageBubble(playerid);
			return;
		}
		else // If there's no collision damage textdraw shown
		{
			if(VisualDamage[playerid][ShownTakenDamage][i] ==  false && freeSlot == -1)
				freeSlot = i; // Point out that this slot is free and can be used when this loop finishes
		}
	}
	if(freeSlot != -1) // If there's a free slot for damage textdraw
	{
		// There were no collision damage textdraws found
		// we may want to create a new one and here comes
		// the use of 'freeSlot' variable we initialized.
		VisualDamage[playerid][ShownTakenDamage][freeSlot] = true; // Indicate that this slot has a shown taken damage textdraw
		VisualDamage[playerid][TDamageTaken][freeSlot] = amount; // Set the damage amount
		VisualDamage[playerid][TakenDamageWeapon][freeSlot] = weaponid;
		VisualDamage[playerid][WhoDamaging][freeSlot] = NO_DAMAGER_UNIQUE_ID; // This unique ID means a COLLISION (or generally non-damager damages)
		Iter_Add(PlayerHasTVisualDmg, playerid); // Add this player to the array that holds the IDs of the players who has a taken-damage textdraw shown
		format(str, sizeof(str), "%s-%.0f ~r~~h~%s %s[%s~h~%d%s]",  // Format the string with correct damage info
			MAIN_TEXT_COLOUR, VisualDamage[playerid][TDamageTaken][freeSlot], 
			WeaponNames[weaponid], MAIN_TEXT_COLOUR, col, totHP, MAIN_TEXT_COLOUR);
		PlayerTextDrawSetString(playerid, GettingDamaged[playerid][freeSlot], str); // Update the textdraw with the correct info
		VisualDamage[playerid][TakenDamageTick][freeSlot] = tick; // When the last time this damage textdraw was shown
		ShowVisualDamageForSpectators(playerid, freeSlot, str, 1, tick); // Show this update to the spectators of this player as well
		SetPlayerDamageBubble(playerid);
	}
}