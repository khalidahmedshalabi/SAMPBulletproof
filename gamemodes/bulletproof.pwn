#pragma dynamic 3500000

#include <a_samp>
#include <a_http>
#include <maxplayers>

// Libraries
#include <geolocation> 		// Shows player country based on IP
#include <strlib>           // String functions by Slice
#include <progress2>        // Player Progress Bar functions
#include <globalprogressbar>// Global Progress Bar functions
#include <profiler>         // Script profiler
#include <sampac> 			// THE MIGHTY NEW ANTICHEAT
#include <mSelection>       // Selection with preview models feature library
#include <gBugFix>			// Fix false vehicle entry as passenger (G (teleport/distance) bug)

// YSI Libraries (updated)
#define YSI_NO_MASTER
//#define 	_DEBUG			(7) 	// y_debug debug level
#define FOREACH_NO_VEHICLES
//#define FOREACH_NO_LOCALS
#define FOREACH_NO_ACTORS
#include <YSI_inc\YSI\y_stringhash> // better than strcmp in comparing strings (not recommended for long ones though)
#include <YSI_inc\YSI\y_commands>
#include <YSI_inc\YSI\y_groups>
#include <YSI_inc\YSI\y_iterate> 	// foreach and iterators
#include <YSI_inc\YSI\y_hooks>
//#include <YSI_inc\YSI\y_debug>
#include <YSI_inc\YSI\y_master>

// Some SA-MP natives which are not defined by default
native gpci (playerid, serial [], len);
native IsValidVehicle(vehicleid);

// Server modules (find them in "/pawno/include/modules") (note: modules that consists of hooking have to be first)
#include "modules\src\hooking\tickcount.inc"
#include "modules\src\hooking\safegametext.inc"
#include "modules\src\hooking\vehicle.inc"
#include "modules\src\hooking\commonhooking.inc"
#tryinclude "modules\header\http_destinations.txt" // (closed source)
#tryinclude "modules\src\league.inc" // The league system source code is not open
#tryinclude "modules\src\shop.inc"  // The league shop source code is not open
#include "modules\src\this_core.inc"
#include "modules\src\freecam.inc"
#include "modules\src\common.inc"
#include "modules\header\longarrays.txt"
#include "modules\header\mapicons.txt"
#include "modules\src\fightstyle.inc"
#include "modules\src\dialogs.inc"
#include "modules\src\colors.inc"
#include "modules\src\textdraws.inc"
#include "modules\src\player.inc"
#include "modules\src\fields.inc"
#include "modules\src\match.inc"
#include "modules\src\config.inc"
#include "modules\src\global.inc"
//#include "modules\src\dynamic_coloring.inc"
#include "modules\src\weaponshot.inc"
#include "modules\src\version_checker.inc"
#include "modules\src\database.inc"
#include "modules\src\duel.inc"
#include "modules\src\spectate.inc"
#include "modules\src\commands.inc"
#include "modules\src\antimacro.inc"
#include "modules\src\messagebox.inc"
#include "modules\src\deathcam.inc"
#include "modules\src\gunmenu.inc"
#include "modules\src\weaponbinds.inc"
#include "modules\src\ac_addons.inc"
#include "modules\src\vote.inc"
#include "modules\src\gunonhead.inc"
#include "modules\src\teamhpbars.inc"

main()
{}

public OnGameModeInit()
{
    InitScriptCoreSettings();
	InitScriptSecondarySettings();
	AddToServersDatabase();
	SetTimer("OnScriptUpdate", 1000, true); // Timer that is repeatedly called every second (will be using this for most global stuff)
	return 1;
}

public OnGameModeExit()
{
	db_close(sqliteconnection);
	return 1;
}

public OnPlayerConnect(playerid)
{
    // Check if version is out-dated and if server owners are forced to use newest version
	if(VersionReport == VERSION_IS_BEHIND && ForceUserToNewestVersion == true)
	{
	    SendClientMessage(playerid, -1, ""COL_PRIM"Version checker: {FFFFFF}the version used in this server is out-dated.");
    	SendClientMessage(playerid, -1, sprintf(""COL_PRIM"Visit {FFFFFF}%s "COL_PRIM"to get the latest version", GM_WEBSITE));
		SendClientMessage(playerid, -1, sprintf(""COL_PRIM"Server version: {FFFFFF}%.2f "COL_PRIM"| Newest version: {FFFFFF}%.2f", GM_VERSION, LatestVersion));
        SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
        CallLocalFunction("OnPlayerCommandText", "ds", playerid, "/changelog");
		return 0;
	}
	// If database is still loading, temporarily disable the player from connecting
    if(DatabaseLoading == true)
    {
        ClearChatForPlayer(playerid);
		SendClientMessage(playerid, -1, "Please wait! Database loading, you will be connected when it's loaded successfully.");
		SetTimerEx("OnPlayerConnect", 1000, false, "i", playerid);
  		SetTimerEx("OnPlayerRequestClass", 1050, false, "ii", playerid, 0);
		return 0; 
	}
	// If there was a problem loading the database, warn them
	if(sqliteconnection == DB:0)
	{
	    SendClientMessage(playerid, -1, sprintf("{CC0000}Warning: {FFFFFF}database is not loaded. Make sure 'BulletproofDatabase.db' file is inside the '/scriptfiles' directory and restart. Visit %s for further help!", GM_WEBSITE));
	}
	if(CorrectDatabase == false)
	{
	    SendClientMessage(playerid, -1, sprintf("{CC0000}Warning: {FFFFFF}this server is not using the correct database. Visit %s for further help!", GM_WEBSITE));
	}
	// Check if players count exceeded the limit
	if(Iter_Count(Player) == MAX_PLAYERS)
	{
	    SendClientMessageToAll(-1, sprintf(""COL_PRIM"ID %d could't connect to the server properly. Maximum players limit exceeded!", playerid));
	    SendClientMessageToAll(-1, sprintf("MAX PLAYERS LIMIT: %d | Ask for a special and increased limit | %s", MAX_PLAYERS, GM_WEBSITE));
	    SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
	    return 0;
	}

	// Initialize the new player
	InitPlayer(playerid);
	#if defined _league_included
	CheckPlayerLeagueRegister(playerid);
	UpdateOnlinePlayersList(playerid, true);
	#endif
	CheckPlayerAKA(playerid);

	// Tell everyone that he's connected
	new str[144];
    GetPlayerCountry(playerid, str, sizeof(str));
	format(str, sizeof(str), "{FFFFFF}%s {757575}(ID: %d) has connected [{FFFFFF}%s{757575}]", Player[playerid][Name], playerid, str);
    SendClientMessageToAll(-1, str);

    if(AllMuted) // If everyone is muted (global mute, /muteall?), this player should be muted too
    	Player[playerid][Mute] = true;
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    // If database is still loading, then we must not let this player login or access data now
    if(DatabaseLoading == true)
        return 0;
        
	// Initialize class selection mode
	Player[playerid][Team] = NON;
    SetPlayerColor(playerid, 0xAAAAAAAA);
    Player[playerid][Spawned] = false;

	if(GetPlayerState(playerid) != PLAYER_STATE_SPECTATING)
    	TogglePlayerSpectating(playerid, true);
    	
	SetPlayerTime(playerid, 12, 0);
	SetPlayerInterior(playerid, MainInterior);
	
	switch(random(3))
	{
	    case 0:
	    {
	        InterpolateCameraPos(playerid, MainSpawn[0], MainSpawn[1], MainSpawn[2] + 25.0, MainSpawn[0] - 7.0, MainSpawn[1] + 7.0, MainSpawn[2] + 5.0, 15000, CAMERA_MOVE);
			InterpolateCameraLookAt(playerid, MainSpawn[0], MainSpawn[1], MainSpawn[2] + 27.0, MainSpawn[0], MainSpawn[1], MainSpawn[2], 7000, CAMERA_MOVE);
	    }
	    case 1:
	    {
	        InterpolateCameraPos(playerid, MainSpawn[0] + 5.0, MainSpawn[1] + 5.0, MainSpawn[2] + 2.0, MainSpawn[0] - 7.0, MainSpawn[1] + 7.0, MainSpawn[2] + 25.0, 15000, CAMERA_MOVE);
			InterpolateCameraLookAt(playerid, MainSpawn[0], MainSpawn[1], MainSpawn[2] + 10.0, MainSpawn[0], MainSpawn[1], MainSpawn[2], 7000, CAMERA_MOVE);
	    }
	    case 2:
	    {
	        InterpolateCameraPos(playerid, MainSpawn[0] + 10.0, MainSpawn[1] - 10.0, MainSpawn[2] + 10.0, MainSpawn[0] - 5.0, MainSpawn[1] + 5.0, MainSpawn[2] + 5.0, 15000, CAMERA_MOVE);
			InterpolateCameraLookAt(playerid, MainSpawn[0], MainSpawn[1], MainSpawn[2] + 5.0, MainSpawn[0], MainSpawn[1], MainSpawn[2], 10000, CAMERA_MOVE);
	    }
	}
        
    #if defined _league_included
	// League account login check
	if(Player[playerid][MustLeaguePass] == true)
	{
	    ShowPlayerLeagueLoginDialog(playerid);
	}
	else if(Player[playerid][MustLeagueRegister] == true)
	{
	    ShowPlayerLeagueRegisterDialog(playerid);
	}
	#endif
	// Login player
	#if defined _league_included
	else if(Player[playerid][Logged] == false)
	#else
	if(Player[playerid][Logged] == false)
	#endif
	{
		new Query[128];
		format(Query, sizeof(Query), "SELECT Name FROM Players WHERE Name = '%q'", Player[playerid][Name]);
        new DBResult:result = db_query(sqliteconnection, Query);

		if(!db_num_rows(result))
		{
		    ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,"{FFFFFF}Registration Dialog","{FFFFFF}Type your password below to register:","Register","Leave");
            db_free_result(result);
		}
		else
	 	{
	 	    db_free_result(result);
		    // Get IP
		    new IP[16];
		    GetPlayerIp(playerid, IP, sizeof(IP));

		    // Construct query to check if the player with the same name and IP has connected before to this server
		    format(Query, sizeof(Query), "SELECT * FROM `Players` WHERE `Name` = '%q' AND `IP` = '%s'", Player[playerid][Name], IP);

		    // execute
			new DBResult:res = db_query(sqliteconnection, Query);

			// If result returns any registered users with the same name and IP that have connected to this server before, log them in
			if(db_num_rows(res))
			{
			    SendClientMessage(playerid, -1, "{009933}Server account: {FFFFFF}automatically logged in!");
				LoginPlayer(playerid, res);
			    db_free_result(res);
			    new teamid = ShouldPlayerBeReadded(playerid);
				if(teamid != -1)
				{
					SetTimerEx("SpawnConnectedPlayer", 250, false, "ii", playerid, teamid);
				}
				else
				{
					ShowIntroTextDraws(playerid);
   					ShowPlayerClassSelection(playerid);
				}
			}
			else
			{
				ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,"{FFFFFF}Login Dialog","{FFFFFF}Type your password below to log in:","Login","Leave");
                db_free_result(res);
			}
		}
	}
	else
	{
	    new teamid = ShouldPlayerBeReadded(playerid);
		if(teamid != -1)
		{
			SetTimerEx("SpawnConnectedPlayer", 250, false, "ii", playerid, teamid);
		}
		else
		{
			ShowIntroTextDraws(playerid);
			ShowPlayerClassSelection(playerid);
		}
	}
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if(Player[playerid][Spawned] == false)
	{
		OnPlayerRequestClass(playerid, 0);
		return 0;
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(Player[playerid][IgnoreSpawn] == true)
	{
	    // This spawn call should be ignored (used for many things .. e.g the SyncPlayer function)
	    Player[playerid][IgnoreSpawn] = false;
	    return 1;
	}
	// If they're in a DM
	if(Player[playerid][DMReadd] > 0)
	{
	    // Re-spawn them there
	    SpawnInDM(playerid, Player[playerid][DMReadd]);
	    return 1;
	}
	// If they're selecting from gunmenu
    if(Player[playerid][OnGunmenu])
    {
        // Hide it!!!
        HidePlayerGunmenu(playerid);
    }
	// If the server sees this player frozen
    if(Player[playerid][IsFrozen])
    {
        // Tell the script he is not frozen anymore
		Player[playerid][IsFrozen] = false;
	}
	// If this player is just spawning regularly
	if(Player[playerid][Playing] == false && Player[playerid][InDM] == false && Player[playerid][InDuel] == false)
 	{
 	    // Adjust player HP
		SetHP(playerid, 100);
		SetAP(playerid, 100);

		// Unarm players from any weapons
		ResetPlayerWeapons(playerid);
		// 'playerid' is unique which means playerids can never match, hence we use that to initialize player's team
		// and workaround SAMP's built-in anti team-shooting (i.e players in the same team cannot harm each other)
		SetPlayerTeam(playerid, playerid);
	    SetPlayerScore(playerid, 0);

		// Initialize player spawn camera and position
		SetPlayerPos(playerid, MainSpawn[0] + random(3), MainSpawn[1] + random(3), MainSpawn[2] + 2);
		SetPlayerFacingAngle(playerid, MainSpawn[3]);
		SetPlayerInterior(playerid, MainInterior);
		SetPlayerVirtualWorld(playerid, 0);
		SetCameraBehindPlayer(playerid);

		ColorFix(playerid); // Fixes player color based on their team.
		RadarFix();
		SetPlayerSkin(playerid, Skin[Player[playerid][Team]]);
	}
	// Fixes the x Vs y textdraws with current team player count
	FixVsTextDraw();
	
	if(Current == -1)
	{
	    // If there's no round running, hide the round stats textdraws
	    HideRoundStats(playerid);
 	}
 	else
 	{
 	    // If there's a round running...
 	    
 	    if(ElapsedTime <= 20 && !Player[playerid][Playing] && !WarMode && (Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
 	    {
 	        SendClientMessage(playerid, -1, ""COL_PRIM"You may want to use {FFFFFF}/addme "COL_PRIM"to add yourself to the round.");
 	    }
 	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	// Send public disconnect messages
    new iString[144];
    switch (reason)
	{
		case 0:
		{
			if(Player[playerid][Playing] == false)
				format(iString, sizeof(iString), "{FFFFFF}%s {757575}has had a crash/timeout.", Player[playerid][Name]);
		 	else
			 	format(iString, sizeof(iString), "{FFFFFF}%s {757575}has had a crash/timeout {FFFFFF}(HP %d | AP %d).", Player[playerid][Name], Player[playerid][pHealth], Player[playerid][pArmour]);
		}
		case 1:
		{
			if(Player[playerid][Playing] == false)
				format(iString, sizeof(iString), "{FFFFFF}%s {757575}has quit the server.",Player[playerid][Name]);
			else
				format(iString, sizeof(iString), "{FFFFFF}%s {757575}has quit the server {FFFFFF}(HP %d | AP %d).", Player[playerid][Name], Player[playerid][pHealth], Player[playerid][pArmour]);
		}
		case 2:
		{
		    if(Player[playerid][Playing] == false)
				format(iString, sizeof(iString), "{FFFFFF}%s {757575}has been kicked or banned.",Player[playerid][Name]);
			else
				format(iString, sizeof(iString), "{FFFFFF}%s {757575}has been kicked or banned {FFFFFF}(HP %d | AP %d).",Player[playerid][Name], Player[playerid][pHealth], Player[playerid][pArmour]);
		}
	}
	SendClientMessageToAll(-1,iString);
	// Check player spawned vehicle
	if(IsValidVehicle(Player[playerid][LastVehicle]))
	{
	    foreach(new i : Player)
		{
		    if(i == playerid)
				continue;

			if(GetPlayerVehicleID(i) == Player[playerid][LastVehicle])
				goto DoNotDestroyVehicle;
		}
		DestroyVehicle(Player[playerid][LastVehicle]);
		Player[playerid][LastVehicle] = -1;
		DoNotDestroyVehicle:
	}
 	// Fixes the x Vs y textdraws with current team player count
	FixVsTextDraw(playerid);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	// todo: test if this callback should be used under any weird circumstances. e.g: falling from a large cliff, exploding while driving a car, etc...

    if(Player[playerid][AlreadyDying] == true)
        return 1; // Stop! Server-sided death system is already handling this.

	// case: died while driving a vehicle which exploded
	if(GetPlayerVehicleID(playerid) != 0)
	{
	    ServerOnPlayerDeath(playerid, INVALID_PLAYER_ID, 51);
	    return 1;
	}
	// case: died while diving with a parachute?
	if(reason == WEAPON_PARACHUTE)
	{
		ServerOnPlayerDeath(playerid, INVALID_PLAYER_ID, WEAPON_PARACHUTE);
	    return 1;
	}
	// unknown cases
	SendClientMessageToAll(-1, sprintf("DEBUG:Client:OnPlayerDeath(%d, %d, %d)", playerid, killerid, reason));
	ServerOnPlayerDeath(playerid, killerid, reason);
	return 1;
}

forward ServerOnPlayerDeath(playerid, killerid, reason);
public ServerOnPlayerDeath(playerid, killerid, reason)
{
    Player[playerid][AlreadyDying] = false; // Player is no longer dying, server-sided death is taking place
	Player[playerid][HitBy] = INVALID_PLAYER_ID;
	Player[playerid][HitWith] = 47;
	new KillerConnected = IsPlayerConnected(killerid);
	if(!KillerConnected)
	{
	    if(Player[playerid][Playing] == true)
		{
		    SendDeathMessage(INVALID_PLAYER_ID, playerid, reason);
			Player[playerid][RoundDeaths]++;
			Player[playerid][TotalDeaths]++;

			new str[64];
			format(str, sizeof(str), "%s%s {FFFFFF}has died by: {FFFFFF}%s", TextColor[Player[playerid][Team]], Player[playerid][Name], WeaponNames[reason]);
	        SendClientMessageToAll(-1, str);

            OnPlayerAmmoUpdate(playerid);
	    }
	    else if(Current == -1)
	    {
	        SendDeathMessage(INVALID_PLAYER_ID, playerid, reason);
	    }
	}
	else
	{
		switch(reason)
		{
		    case WEAPON_KNIFE:
		    {
		        PlayerTextDrawSetString(playerid, DeathText[playerid][1], sprintf("%s~h~%s%s knifed you", TDC[Player[killerid][Team]], Player[killerid][Name], MAIN_TEXT_COLOUR));
		        PlayerTextDrawSetString(killerid, DeathText[killerid][0], sprintf("%sYou knifed %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name]));
		    }
		    case WEAPON_GRENADE:
		    {
				PlayerTextDrawSetString(playerid, DeathText[playerid][1], sprintf("%s~h~%s%s bombed you", TDC[Player[killerid][Team]], Player[killerid][Name], MAIN_TEXT_COLOUR));
		        PlayerTextDrawSetString(killerid, DeathText[killerid][0], sprintf("%sYou bombed %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name]));
		    }
		    default:
			{
				switch(random(4))
				{
				    case 0:
				    {
						PlayerTextDrawSetString(playerid, DeathText[playerid][1], sprintf("%s~h~%s%s raped you", TDC[Player[killerid][Team]], Player[killerid][Name], MAIN_TEXT_COLOUR));
						PlayerTextDrawSetString(killerid, DeathText[killerid][0], sprintf("%sYou raped %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name]));
					}
					case 1:
					{
						PlayerTextDrawSetString(playerid, DeathText[playerid][1], sprintf("%s~h~%s%s owned you", TDC[Player[killerid][Team]], Player[killerid][Name], MAIN_TEXT_COLOUR));
						PlayerTextDrawSetString(killerid, DeathText[killerid][0], sprintf("%sYou owned %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name]));
					}
					case 2:
				    {
        				PlayerTextDrawSetString(playerid, DeathText[playerid][1], sprintf("%s~h~%s%s murdered you", TDC[Player[killerid][Team]], Player[killerid][Name], MAIN_TEXT_COLOUR));
					    PlayerTextDrawSetString(killerid, DeathText[killerid][0], sprintf("%sYou murdered %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name]));
					}
					case 3:
					{
						PlayerTextDrawSetString(playerid, DeathText[playerid][1], sprintf("%s~h~%s%s sent you to cemetery", TDC[Player[killerid][Team]], Player[killerid][Name], MAIN_TEXT_COLOUR));
                        PlayerTextDrawSetString(killerid, DeathText[killerid][0], sprintf("%sYou sent %s~h~%s%s to cemetery", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name], MAIN_TEXT_COLOUR));
					}
				}
			}
		}
        PlayerTextDrawShow(killerid, DeathText[killerid][0]);
        PlayerTextDrawShow(playerid, DeathText[playerid][1]);

	    SetTimerEx("DeathMessageF", 4000, false, "ii", killerid, playerid);

		if(Player[playerid][Playing] == true && Player[killerid][Playing] == true && AllowStartBase != false)
		{
		    ShowPlayerDeathMessage(killerid, playerid);
		    #if defined _league_included
		    if(LeagueMode)
		    {
		        UpdateLeaguePlayerKills(killerid, reason);
		    }
		    #endif
		    SendDeathMessage(killerid, playerid, reason);

		    Player[killerid][RoundKills]++;
		    Player[killerid][TotalKills]++;
		    Player[playerid][RoundDeaths]++;
		    Player[playerid][TotalDeaths]++;

			new str[150];
			format(str, sizeof(str), "%sKills %s%d~n~%sDamage %s%d~n~%sTotal Dmg %s%d", MAIN_TEXT_COLOUR, TDC[Player[killerid][Team]], Player[killerid][RoundKills], MAIN_TEXT_COLOUR, TDC[Player[killerid][Team]], Player[killerid][RoundDamage], MAIN_TEXT_COLOUR, TDC[Player[killerid][Team]], Player[killerid][TotalDamage]);
			PlayerTextDrawSetString(killerid, RoundKillDmgTDmg[killerid], str);
			format(str, sizeof(str), "%s%s {FFFFFF}killed %s%s {FFFFFF}with %s [%.1f ft] [%d HP]", TextColor[Player[killerid][Team]], Player[killerid][Name], TextColor[Player[playerid][Team]], Player[playerid][Name], WeaponNames[reason],GetDistanceBetweenPlayers(killerid, playerid), (Player[killerid][pHealth] + Player[killerid][pArmour]));
			SendClientMessageToAll(-1, str);

            OnPlayerAmmoUpdate(playerid);
		}
		else
		{
			if(Current == -1)
				SendDeathMessage(killerid, playerid, reason);
			if(Player[killerid][InDM] == true)
			{
				SetHP(killerid, 100);
				SetAP(killerid, 100);

				Player[playerid][VWorld] = GetPlayerVirtualWorld(killerid);
			}
		}
	}
	if(Player[playerid][Playing] == true)
	{
	    new Float:x, Float:y, Float:z;
		GetPlayerPos(playerid, x, y, z);
	    PlayersDead[Player[playerid][Team]] ++;
	    #if defined _league_included
		if(LeagueMode && PlayerShop[playerid][SHOP_EXPLOSIVE_DEATH])
		{
		    PlayerShop[playerid][SHOP_EXPLOSIVE_DEATH] = false;
		    new
				dist,
				Float:damage,
				randomAdd = randomExInt(10, 15);
		    foreach(new i : Player)
		    {
				if(!Player[i][Playing] && !Player[i][Spectating])
				    continue;

				CreateExplosionForPlayer(i, x, y, z, 7, 14.0);
				if(i != playerid)
				{
					dist = floatround(GetPlayerDistanceFromPoint(i, x, y, z));
					if(dist <= 14)
					{
						damage = float((99 / dist) + randomAdd);
						OnPlayerTakeDamage(i, playerid, damage, 47, 3);
					}
				}
			}
			SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has bombed himself while dying (/shop)", Player[playerid][Name]));
		}
		#endif
	    CreateDeadBody(playerid, killerid, reason, 0.0, x, y, z);
	    PlayerNoLeadTeam(playerid);
	    if(reason != WEAPON_KNIFE && DeathCamera != false) // if weapon is not knife and death camera system is not disabled
	    {
	        new bool:showdeathquote = true;
	        if(KillerConnected)
		    {
				showdeathquote = !Player[killerid][HasDeathQuote];
			}
	        PlayDeathCamera(playerid, x, y, z, showdeathquote);
	    }
	    else // If not
	    {
	    	SetTimerEx("SpectateAnyPlayerT", 1000, false, "i", playerid);
		}
		// Create an icon on radar where the player died
		CreateTeamDeathMapIcon(Player[playerid][Team], x, y, z);
	}
	else if(Player[playerid][InDuel])
	{
	    ProcessDuellerDeath(playerid, killerid, reason);
	}
	
	// Hide arena out of bound warning textdraws if they're shown
	if(Player[playerid][OutOfArena] != MAX_ZONE_LIMIT_WARNINGS)
	{
		PlayerTextDrawHide(playerid, AreaCheckTD[playerid]);
		PlayerTextDrawHide(playerid, AreaCheckBG[playerid]);
	}
	Player[playerid][InDM] = false;
	Player[playerid][Playing] = false;
	Iter_Remove(PlayersInRound, playerid);
	UpdateTeamPlayerCount(Player[playerid][Team], true, playerid);
	UpdateTeamHP(Player[playerid][Team], playerid);
	// Handle spectate
	foreach(new i : AllSpectators)
    {
        if(Player[i][IsSpectatingID] == playerid)
        {
            if(Player[i][Team] == REFEREE)
                SpectateAnyPlayer(i, false, true, playerid);
			else
            	SpectateAnyPlayer(i, true, true, playerid);
        }
    }
    // Reset player gunmenu selections
	ResetPlayerGunmenu(playerid, false);
	
	// Call OnPlayerLeaveCheckpoint to see if player was in CP and fix issues
	OnPlayerLeaveCheckpoint(playerid);
	
	// If he's spectating, stop it
 	if(Player[playerid][Spectating])
	    StopSpectate(playerid);
	    
	if(!Player[playerid][InDeathCamera])
	{
		OnPlayerSpawn(playerid);
		Player[playerid][IgnoreSpawn] = false;
		SpawnPlayer(playerid);
	}
	return 1;
}

public OnPlayerText(playerid, text[])
{
	// Anti spam
	if(AntiSpam == true && GetTickCount() < Player[playerid][lastChat])
	{
		SendErrorMessage(playerid, "Please wait.");
		return 0;
	}
	Player[playerid][lastChat] = GetTickCount() + 1000;

	// Team Chat
    if(text[0] == '!')
	{
	    new ChatColor;
	    switch(Player[playerid][Team])
		{
	        case REFEREE: 		ChatColor = 0xFFFF90FF;
	        case DEFENDER: 		ChatColor = 0x0088FFFF;
	        case ATTACKER: 		ChatColor = 0xFF2040FF;
	        case ATTACKER_SUB: 	ChatColor = ATTACKER_SUB_COLOR;
	        case DEFENDER_SUB: 	ChatColor = DEFENDER_SUB_COLOR;
	        case NON:
			{ SendErrorMessage(playerid,"You must be part of a team."); return 0; }
	    }
	    new ChatString[144];
		format(ChatString,sizeof(ChatString),"@ Team Chat | %s (%d) | %s", Player[playerid][Name], playerid, text[1]);

		foreach(new i : Player)
		{
			if(Player[i][Team] != NON)
			{
		        if((Player[playerid][Team] == ATTACKER || Player[playerid][Team] == ATTACKER_SUB) && (Player[i][Team] == ATTACKER || Player[i][Team] == ATTACKER_SUB))
				{ SendClientMessage(i, ChatColor, ChatString); PlayerPlaySound(i,1137,0.0,0.0,0.0); }
		        if((Player[playerid][Team] == DEFENDER || Player[playerid][Team] == DEFENDER_SUB) && (Player[i][Team] == DEFENDER || Player[i][Team] == DEFENDER_SUB))
				{ SendClientMessage(i, ChatColor, ChatString); PlayerPlaySound(i,1137,0.0,0.0,0.0); }
				if(Player[playerid][Team] == REFEREE && Player[i][Team] == REFEREE)
			   	{ SendClientMessage(i, ChatColor, ChatString); PlayerPlaySound(i,1137,0.0,0.0,0.0); }
			}
		}
	    return 0;
	}
	else
	{
	    if(Player[playerid][Mute] == true)
		{ SendErrorMessage(playerid,"You are muted, STFU."); return 0; }
	}
	// Admin chat
	if(text[0] == '@' && Player[playerid][Level] > 0)
	{
	    new ChatString[144];
        format(ChatString, sizeof(ChatString), "@ Admin Chat | %s (%d) | %s", Player[playerid][Name], playerid, text[1]);
        foreach(new i : Player) {
            if(Player[i][Level] > 0) {
                SendClientMessage(i, 0x66CC66FF, ChatString);
                PlayerPlaySound(i,1137,0.0,0.0,0.0);
			}
		}
		return 0;
	}
	#if defined _league_included
	/*
	// League admins chat
	if(text[0] == '~' && IsLeagueMod(playerid))
	{
	    new ChatString[128];
        format(ChatString, sizeof(ChatString), "@ League ADM Chat | %s (%d) | %s", Player[playerid][Name], playerid, text[1]);
        foreach(new i : Player)
		{
            if(IsLeagueMod(i))
			{
                SendClientMessage(i, 0xA8FFE5FF, ChatString);
                PlayerPlaySound(i,1137,0.0,0.0,0.0);
			}
		}
		return 0;
	}
	*/
	// League clans chat
	if(text[0] == '#')
	{
	    if(!IsPlayerInAnyClan(playerid))
	        SendErrorMessage(playerid, "You're not in any clan. Check /leaguecmds for help!");
		else
		{
		    SendMessageToLeagueClan(playerid, text);
		}
		return 0;
	}
	#endif
	// Channel chat
	if(text[0] == '^' && Player[playerid][ChatChannel] != -1)
	{
	    new ChatString[144];
        format(ChatString, sizeof(ChatString), "@ Channel Chat | %s | {FFFFFF}%d{FFCC99} | %s", Player[playerid][Name], OnlineInChannel[Player[playerid][ChatChannel]], text[1]);
        OnlineInChannel[Player[playerid][ChatChannel]] = 0;

		foreach(new i : Player)
		{
            if(Player[i][ChatChannel] == Player[playerid][ChatChannel])
			{
                SendClientMessage(i, 0xFFCC99FF, ChatString);
                PlayerPlaySound(i,1137,0.0,0.0,0.0);
                OnlineInChannel[Player[playerid][ChatChannel]]++;
			}
		}
	    return 0;
	}
	
	// Normal chat
    new ChatString[144];
	format(ChatString, sizeof(ChatString),"%s%s: {FFFFFF}(%d) %s", GetColor(GetPlayerColor(playerid)), Player[playerid][Name], playerid, text);
	SendClientMessageToAll(-1, ChatString);
	return 0;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    switch(newstate)
	{
	    case PLAYER_STATE_DRIVER:
		{
            if(Player[playerid][Team] == DEFENDER && Player[playerid][Playing] == true)
			{
				new Float:defPos[3];
				GetPlayerPos(playerid, defPos[0], defPos[1], defPos[2]);
				SetPlayerPos(playerid, defPos[0]+1.0, defPos[1]+1.0, defPos[2]+1.0);
				return 1;
			}
			SetPlayerArmedWeapon(playerid, 0);

			if(Player[playerid][BeingSpeced] == true)
			{
	            foreach(new i : PlayerSpectators[playerid])
				{
					TogglePlayerSpectating(i, 1);
					PlayerSpectateVehicle(i, GetPlayerVehicleID(playerid));
		        }
			}
			if(Player[playerid][Playing] == true && Player[playerid][WasInCP] == true)
			{
				if(IsPlayerInRangeOfPoint(playerid, 2.0, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2]))
				{
			  		OnPlayerLeaveCheckpoint(playerid);
				}
			}
		}
		case PLAYER_STATE_PASSENGER:
		{
			if(Player[playerid][Team] == DEFENDER && Player[playerid][Playing] == true)
			{
				new Float:defPos[3];
				GetPlayerPos(playerid, defPos[0], defPos[1], defPos[2]);
				SetPlayerPos(playerid, defPos[0]+1.0, defPos[1]+1.0, defPos[2]+1.0);
				return 1;
			}
			SetPlayerArmedWeapon(playerid, 0);

			if(Player[playerid][BeingSpeced] == true)
			{
	            foreach(new i : PlayerSpectators[playerid])
				{
		            TogglePlayerSpectating(i, 1);
		            PlayerSpectateVehicle(i, GetPlayerVehicleID(playerid));
	            }
			}

			if(Player[playerid][Playing] == true && Player[playerid][WasInCP] == true)
			{
				if(IsPlayerInRangeOfPoint(playerid, 2.0, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2]))
				{
			  		OnPlayerLeaveCheckpoint(playerid);
				}
			}

	    }
		case PLAYER_STATE_ONFOOT:
		{
	        if(oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER)
			{
				if(Player[playerid][BeingSpeced] == true)
				{
		            foreach(new i : PlayerSpectators[playerid])
		            {
		            	TogglePlayerSpectating(i, 1);
			            PlayerSpectatePlayer(i, playerid);
			        }
				}
				if(Current != -1 && Player[playerid][Playing] == true && Player[playerid][Team] == ATTACKER)
				{
					if(IsPlayerInRangeOfPoint(playerid, 2.0, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2]))
					{
						OnPlayerEnterCheckpoint(playerid);
					}
				}
			}
	    }
    }
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	// Update interior for whoever is spectating this player as well
	foreach(new i : PlayerSpectators[playerid])
	{
		SetPlayerInterior(i, newinteriorid);
	}
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	Player[playerid][LastEnterVehicleAttempt] = GetTickCount() + 3000;
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	Player[playerid][LastEnterVehicleAttempt] = GetTickCount() + 3000;
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	if(!IsVehicleComponentLegal(GetVehicleModel(vehicleid), componentid))
	{
	    return 0;
	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
    if(GetPlayerVehicleID(playerid) == 0 && Player[playerid][Playing] == true && (Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
	{
	    switch(GameType)
	    {
	        case BASE:
	        {
				switch(Player[playerid][Team])
				{
				    case ATTACKER:
					{
				        new Float:attPos[3];
					    GetPlayerPos(playerid, attPos[0], attPos[1], attPos[2]);
					    if(attPos[2] <= (BCPSpawn[Current][2] - 1.4))
					    	return 1;

						PlayersInCP ++;
						Player[playerid][WasInCP] = true;

						new iString[256];
						format(iString, sizeof iString, "~r~~h~~h~Players In CP");
						foreach(new i : Player)
						{
						    if(Player[i][WasInCP] == true)
							{
						        format(iString, sizeof(iString), "%s~n~~r~~h~- %s%s", iString, MAIN_TEXT_COLOUR, Player[i][Name]);
							}
						}
						TextDrawSetString(EN_CheckPoint, iString);
						TextDrawColor(timerCircleTD, 0xFF616133);
						foreach(new i : Player)
						{
						    if(!Player[i][Spawned])
						        continue;
						        
                            TextDrawShowForPlayer(i, EN_CheckPoint);
                            TextDrawShowForPlayer(i, timerCircleTD);
						}

					}
					case DEFENDER:
					{
						new Float:defPos[3];
					    GetPlayerPos(playerid, defPos[0], defPos[1], defPos[2]);
					    if(defPos[2] >= (BCPSpawn[Current][2] - 1.4))
					    {
							#if defined _league_included
							if(LeagueMode)
							{
							    if(CurrentCPTime <= 10 && CurrentCPTime > 4)
							    {
                                    AddPlayerLeaguePoints(playerid, 50, "saving CP in rather dangerous time");
							    }
							    else if(CurrentCPTime <= 4)
							    {
							        AddPlayerLeaguePoints(playerid, 100, "saving CP in a very critical time");
							    }
							}
							#endif
					    	CurrentCPTime = ConfigCPTime + 1;
				    	}
						else if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK)
						{
						    if(CurrentCPTime < ConfigCPTime)
						    	SendClientMessageToAll(-1, sprintf(""COL_PRIM"CP touch by {FFFFFF}%s "COL_PRIM"is denied due to abusing jetpack.", Player[playerid][Name]));
						}
						else
						    if(CurrentCPTime < ConfigCPTime)
						    	SendClientMessageToAll(-1, sprintf(""COL_PRIM"CP touch by {FFFFFF}%s "COL_PRIM"is denied. This might be considered as cheating or bug abusing.", Player[playerid][Name]));
					}
				}
			}
			case ARENA:
			{
			    if(!ArenaStarted)
			        return 1;

                switch(TeamCapturingCP)
			    {
			        case NON: // no one is taking CP
			        {
						TeamCapturingCP = Player[playerid][Team];
						new Float:attPos[3];
					    GetPlayerPos(playerid, attPos[0], attPos[1], attPos[2]);
					    if(attPos[2] <= (ACPSpawn[Current][2] - 1.4))
					    	return 1;

						PlayersInCP ++;
						Player[playerid][WasInCP] = true;

						new iString[256];
						format(iString, sizeof iString, "%sPlayers In CP", TDC[Player[playerid][Team]]);
						foreach(new i : Player)
						{
						    if(Player[i][WasInCP] == true && Player[playerid][Team] == Player[i][Team])
							{
						        format(iString, sizeof(iString), "%s~n~%s- %s%s", iString, TDC[Player[i][Team]], MAIN_TEXT_COLOUR, Player[i][Name]);
							}
						}
						TextDrawSetString(EN_CheckPoint, iString);
						switch(Player[playerid][Team])
						{
						    case ATTACKER:
						        TextDrawColor(timerCircleTD, 0xFF616133);
							case DEFENDER:
							    TextDrawColor(timerCircleTD, 0x9698FF33);
						}
						foreach(new i : Player)
						{
						    if(!Player[i][Spawned])
						        continue;

                            TextDrawShowForPlayer(i, EN_CheckPoint);
                            TextDrawShowForPlayer(i, timerCircleTD);
						}
			        }
					default: // cp is being taken by some team
					{
					    if(TeamCapturingCP == Player[playerid][Team])
					    {
							new Float:attPos[3];
						    GetPlayerPos(playerid, attPos[0], attPos[1], attPos[2]);
						    if(attPos[2] <= (ACPSpawn[Current][2] - 1.4))
						    	return 1;

							PlayersInCP ++;
							Player[playerid][WasInCP] = true;

							new iString[256];
							format(iString, sizeof iString, "%sPlayers In CP", TDC[Player[playerid][Team]]);
							foreach(new i : Player)
							{
							    if(Player[i][WasInCP] == true && Player[playerid][Team] == Player[i][Team])
								{
							        format(iString, sizeof(iString), "%s~n~%s- %s%s", iString, TDC[Player[i][Team]], MAIN_TEXT_COLOUR, Player[i][Name]);
								}
							}
							TextDrawSetString(EN_CheckPoint, iString);
							foreach(new i : Player)
							{
							    if(!Player[i][Spawned])
							        continue;

	                            TextDrawShowForPlayer(i, EN_CheckPoint);
							}
					    }
					    else
					    {
					        new Float:defPos[3];
						    GetPlayerPos(playerid, defPos[0], defPos[1], defPos[2]);
						    if(defPos[2] >= (ACPSpawn[Current][2] - 1.4))
						    {
						        #if defined _league_included
								if(LeagueMode)
								{
								    if(CurrentCPTime <= 10 && CurrentCPTime > 4)
								    {
	                                    AddPlayerLeaguePoints(playerid, 100, "saving CP in rather dangerous time");
								    }
								    else if(CurrentCPTime <= 4)
								    {
								        AddPlayerLeaguePoints(playerid, 200, "saving CP in a very critical time");
								    }
								}
								#endif
						    	CurrentCPTime = ConfigCPTime + 1;
					    	}
					    	else if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK)
							{
							    if(CurrentCPTime < ConfigCPTime)
							    	SendClientMessageToAll(-1, sprintf(""COL_PRIM"CP touch by {FFFFFF}%s "COL_PRIM"is denied due to abusing jetpack.", Player[playerid][Name]));
							}
							else
							    if(CurrentCPTime < ConfigCPTime)
							    	SendClientMessageToAll(-1, sprintf(""COL_PRIM"CP touch by {FFFFFF}%s "COL_PRIM"is denied. This might be considered as cheating or bug abusing.", Player[playerid][Name]));
					    }
					}
			    }
			}
		}
	}
    return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	switch(GameType)
	{
		case BASE:
		{
			if(Player[playerid][Team] == ATTACKER && Player[playerid][WasInCP] == true)
			{
				PlayersInCP --;
			 	Player[playerid][WasInCP] = false;
		        if(PlayersInCP <= 0)
				{
				    PlayersInCP = 0;
				    CurrentCPTime = ConfigCPTime + 1;
				    TextDrawHideForAll(EN_CheckPoint);
                    TextDrawColor(timerCircleTD, 0x00000033);
					foreach(new i : Player)
					{
					    if(!Player[i][Spawned])
					        continue;
					        
                        TextDrawShowForPlayer(i, timerCircleTD);
					}
				}
				else
				{
				    new cpstr[256];
					format(cpstr, sizeof cpstr, "~r~~h~~h~Players In CP");
					new ct = 0;
					foreach(new i : PlayersInRound)
					{
						if(Player[i][WasInCP] == true)
						{
							ct ++;
							format(cpstr, sizeof(cpstr), "%s~n~~r~~h~- %s%s", cpstr, MAIN_TEXT_COLOUR, Player[i][Name]);
						}
					}
					if(ct == 0) // if it stays 0 and PlayersInCP says it's more than 0 then something must be wrong
					{
						if(RecountPlayersOnCP() == 0)
							goto thatWasWrong;
					}
					TextDrawSetString(EN_CheckPoint, cpstr);

					thatWasWrong:
				}
			}
		}
		case ARENA:
		{
		    if(Player[playerid][Team] == TeamCapturingCP && Player[playerid][WasInCP] == true)
			{
				PlayersInCP --;
			 	Player[playerid][WasInCP] = false;
		        if(PlayersInCP <= 0)
				{
				    TeamCapturingCP = NON;
				    PlayersInCP = 0;
				    CurrentCPTime = ConfigCPTime + 1;
				    TextDrawHideForAll(EN_CheckPoint);
				    TextDrawColor(timerCircleTD, 0x00000033);
					foreach(new i : Player)
					{
					    if(!Player[i][Spawned])
					        continue;
					        
                        TextDrawShowForPlayer(i, timerCircleTD);
					}
				}
				else
				{
				    new cpstr[256];
					format(cpstr, sizeof cpstr, "%sPlayers In CP", TDC[Player[playerid][Team]]);
					new ct = 0;
					foreach(new i : PlayersInRound)
					{
						if(Player[i][WasInCP] == true)
						{
							ct ++;
							format(cpstr, sizeof(cpstr), "%s~n~%s- %s%s", cpstr, TDC[Player[i][Team]], MAIN_TEXT_COLOUR, Player[i][Name]);
						}
					}
					if(ct == 0) // if it stays 0 and PlayersInCP says it's more than 0 then something must be wrong
					{
						if(RecountPlayersOnCP() == 0)
							goto thatWasWrong;
					}
					TextDrawSetString(EN_CheckPoint, cpstr);

					thatWasWrong:
				}
			}
		}
	}
    return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	if(Player[playerid][Level] >= 1 && Player[playerid][Playing] == false && Player[playerid][InDM] == false && Player[playerid][InDuel] == false && Player[playerid][Spectating] == false)
	{
		SetPlayerPosFindZ(playerid, fX, fY, fZ);
	}
    return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	new Str[128], iName[MAX_PLAYER_NAME], playerid, IP[16];
	foreach(new i : Player)
	{
		GetPlayerIp(i, IP, sizeof(IP));
	    if(!strcmp(IP, ip))
		{
			GetPlayerName(i, iName, sizeof(iName));
			playerid = i;
		}
	}

    if(!success)
	{
		format(Str, sizeof(Str), "{FFFFFF}%s "COL_PRIM"has failed to log into rcon.", iName);
        SendClientMessageToAll(-1, Str);

        Player[playerid][RconTry]++;

		if(Player[playerid][RconTry] >= 2){
			format(Str, sizeof(Str), "{FFFFFF}%s "COL_PRIM"has been kicked for several fail attempts to log into rcon", iName);
			SendClientMessageToAll(-1, Str);
			SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
			return 1;
		}
		else SendClientMessage(playerid, -1, "Wrong password one more time will get you kicked.");
    }
	else
	{
     	format(Str, sizeof(Str), "UPDATE Players SET Level = %d WHERE Name = '%q' AND Level != %d", Player[playerid][Level], Player[playerid][Name], Player[playerid][Level]);
    	db_free_result(db_query(sqliteconnection, Str));
        if(Player[playerid][Level] != 5)
        {
            if(Player[playerid][Level] == 0)
			{
			    // Previous level was 0. This means it's a new admin. Guide them.
			    SendClientMessage(playerid, -1, ""COL_PRIM"Looks like you're a new admin. Type {FFFFFF}/acmds "COL_PRIM" to see a list of admin commands!");
			}
	        Player[playerid][Level] = 5;
	        UpdatePlayerAdminGroup(playerid);
			format(Str, sizeof(Str), "UPDATE Players SET Level = %d WHERE Name = '%q'", Player[playerid][Level], Player[playerid][Name]);
    		db_free_result(db_query(sqliteconnection, Str));

    		format(Str, sizeof(Str), "{FFFFFF}%s "COL_PRIM"has successfully logged into rcon and got level 5.", iName);
		}
		else
		    format(Str, sizeof(Str), "{FFFFFF}%s "COL_PRIM"has successfully logged into rcon.", iName);
		foreach(new j : Player)
		{
			if(Player[j][Level] > 4)
				SendClientMessage(j, -1, Str);
		}
	}
    return 1;
}

public OnPlayerUpdate(playerid)
{
	// Player is sending updates, hence they're not paused
	Player[playerid][PauseCount] = 0;

	// Free camera check
	if(noclipdata[playerid][cameramode] == CAMERA_MODE_FLY)
	{
		ProcessFreeCameraMovement(playerid);
		return 0;
	}
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	if(Player[playerid][Playing] == true)
	{
		if(Player[forplayerid][Team] != Player[playerid][Team])
		{
			SetPlayerMarkerForPlayer(forplayerid, playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
		}
		else
		{
			SetPlayerMarkerForPlayer(forplayerid, playerid, GetPlayerCorrectMarkerCol(playerid, forplayerid) | 0x00000055);
		}
	}
	else if(Player[playerid][InDuel] == true && Player[forplayerid][InDuel] == true)
	{
	    SetPlayerMarkerForPlayer(forplayerid, playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
	}
	else if(Player[playerid][Playing] == false && Player[forplayerid][Playing] == false)
	{
	    SetPlayerMarkerForPlayer(forplayerid, playerid, GetPlayerCorrectMarkerCol(playerid, forplayerid) | 0x00000055);
	}
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	if(Player[playerid][Playing] == true)
	{
		if(Player[forplayerid][Team] != Player[playerid][Team])
		{
			SetPlayerMarkerForPlayer(forplayerid, playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
		}
		else
		{
			SetPlayerMarkerForPlayer(forplayerid, playerid, GetPlayerCorrectMarkerCol(playerid, forplayerid) | 0x00000055);
		}
	}
	else if(Player[playerid][InDuel] == true && Player[forplayerid][InDuel] == true)
	{
	    SetPlayerMarkerForPlayer(forplayerid, playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
	}
	else if(Player[playerid][Playing] == false && Player[forplayerid][Playing] == false)
	{
	    SetPlayerMarkerForPlayer(forplayerid, playerid, GetPlayerCorrectMarkerCol(playerid, forplayerid) | 0x00000055);
	}
	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
    // Show target player info for the shooter (HP, PL, Ping and many other things)
 	ShowTargetInfo(playerid, damagedid);
    if(amount == 1833.33154296875)
        return 1;

    //OnPlayerTakeDamage(damagedid, playerid, amount, weaponid, bodypart);
	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
	// Fall protection, gunmenu protection..etc
	if(!IsLegalHit(playerid, issuerid, amount, weaponid))
	{
	    return 1;
	}
	
	// Detect explosion damage, cancel it and set grenade damage
	if(weaponid == 51)
    {
        if(issuerid == INVALID_PLAYER_ID)
        {
	        /* Protection against explosion */
	    	SetFakeHealthArmour(playerid);
	        return 1;
   		}
   		else
   		{
   		    weaponid = WEAPON_GRENADE;
   		}
    }
    
    // Handling Grenades
    if(weaponid == WEAPON_GRENADE)
    {
        if(amount > 60.0)
        {
        	amount = GRENADE_HIGH_DAMAGE;
       	}
       	else if(amount >= 30.0)
       	{
       	    amount = GRENADE_MEDIUM_DAMAGE;
       	}
       	else if(amount < 30.0)
       	{
       	    amount = GRENADE_LOW_DAMAGE;
       	}
    }
    
    // Detect headshots
    if(bodypart == 9)
	{
	    HandleHeadshot(playerid, issuerid, weaponid);
	}
	
	// Show target player info for the shooter (HP, PL, Ping and many other things)
 	ShowTargetInfo(issuerid, playerid);
 	
 	// <start> Health and armour handling
 	if(weaponid == -1)
		weaponid = Player[playerid][HitWith];

    Player[playerid][HitBy] = issuerid; // This is used in custom OnPlayerDeath to get the last player who caused damage on 'playerid'
 	Player[playerid][HitWith] = weaponid; // This is used in custom OnPlayerDeath to get the last weapon a player got hit with before death

    new rounded_amount = GetActualDamage(amount, playerid); // Fix damage if it's unreal (in other words, if damage is greater than player's health)
	if(weaponid == 54) // If it's a collision (fell or something)
	{
	    // We deal with health only leaving armour as it is.
	    SetHP(playerid, Player[playerid][pHealth] - rounded_amount);
	}
	else if(Player[playerid][pArmour] > 0) // Still got armour and it's not a collision damager
	{
	    new diff = (Player[playerid][pArmour] - rounded_amount);
		if(diff < 0)
		{
		    SetAP(playerid, 0);
		    SetHP(playerid, Player[playerid][pHealth] + diff);
		}
		else
		    SetAP(playerid, diff);
	}
	else // It's not a collision and the player got no armour
	    SetHP(playerid, Player[playerid][pHealth] - rounded_amount);
	// <end> Health and armour handling

	if(issuerid != INVALID_PLAYER_ID) // If the damager is a HUMAN
	{
		PlayerPlaySound(issuerid, Player[issuerid][HitSound], 0.0, 0.0, 0.0);
        PlayerPlaySound(playerid, Player[playerid][GetHitSound], 0.0, 0.0, 0.0);

        HandleVisualDamage(playerid, issuerid, float(rounded_amount), weaponid);

		if(Player[issuerid][Playing] == true && Player[playerid][Playing] == true)
		{
			#if defined _league_included
		    if(LeagueMode)
		    {
            	UpdateLeaguePlayerDamage(issuerid, rounded_amount, weaponid);
            	AddPlayerLeaguePoints(issuerid, rounded_amount);
            	AddPlayerLeaguePoints(playerid, -(rounded_amount));
     		}
     		#endif
			Player[issuerid][shotsHit] ++;
			Player[issuerid][RoundDamage] += rounded_amount;
			Player[issuerid][TotalDamage] += rounded_amount;
			new str[160];
			format(str, sizeof(str), "%sKills %s%d~n~%sDamage %s%d~n~%sTotal Dmg %s%d", MAIN_TEXT_COLOUR, TDC[Player[issuerid][Team]], Player[issuerid][RoundKills], MAIN_TEXT_COLOUR, TDC[Player[issuerid][Team]], Player[issuerid][RoundDamage], MAIN_TEXT_COLOUR, TDC[Player[issuerid][Team]], Player[issuerid][TotalDamage]);
			PlayerTextDrawSetString(issuerid, RoundKillDmgTDmg[issuerid], str);
		}
	}
	else // If damage is caused by something else (not a player)
	{
		if(GetPlayerState(playerid) != PLAYER_STATE_WASTED && Player[playerid][Spawned])
		{
			PlayerPlaySound(playerid, Player[playerid][GetHitSound], 0, 0, 0);
            ShowCollisionDamageTextDraw(playerid, float(rounded_amount), weaponid);
		}
	}
	// If there's a round running
	if(Current != -1)
	{
	    // Update team HP bars
	    UpdatePlayerTeamBar(playerid);
	    UpdatePlayerTeamBar(issuerid);
	    // Show team lost hp textdraws
	    if(Player[playerid][Playing] == true)
		{
		    switch(Player[playerid][Team])
		    {
		        case ATTACKER:
				{
				    new str[16];
					format(str, sizeof(str), "~w~%s", Player[playerid][NameWithoutTag]);
					TextDrawSetString(AttHpLose, str);

					TempDamage[ATTACKER] += rounded_amount;
					format(str, sizeof(str), "~r~~h~-%d", TempDamage[ATTACKER]);
					TextDrawSetString(TeamHpLose[0], str);

					KillTimer(AttHpTimer);
					AttHpTimer = SetTimer("HideHpTextForAtt", 3000, false);
				}
				case DEFENDER:
				{
				    new str[16];
					format(str, sizeof(str), "~w~%s", Player[playerid][NameWithoutTag]);
					TextDrawSetString(DefHpLose, str);

				    TempDamage[DEFENDER] += rounded_amount;
					format(str,sizeof(str), "~b~~h~-%d", TempDamage[DEFENDER]);
					TextDrawSetString(TeamHpLose[1], str);

			        KillTimer(DefHpTimer);
			        DefHpTimer = SetTimer("HideHpTextForDef", 3000, false);
				}
		    }
		}
 	}
 	CreateGunObjectOnHead(playerid, weaponid);
	return 1;
}

public OnPlayerSelectObject(playerid, type, objectid, modelid, Float:fX, Float:fY, Float:fZ)
{
	if(Player[playerid][OnGunmenu] && type == SELECT_OBJECT_PLAYER_OBJECT)
	{
	    new gunmenuIndex = -1;
		for(new i = 0; i != MAX_GUNMENU_GUNS; i ++)
		{
		    if(GunmenuData[i][GunPlayerObject][playerid] == objectid)
		    {
		        gunmenuIndex = i;
		        break;
		    }
		}
		if(gunmenuIndex != -1)
		{
		    if(GunmenuData[gunmenuIndex][GunMovingRoute][playerid] == GUN_MOVING_ROUTE_TOPLAYER)
		    {
				// object is already moving to player, so we cancel this
		        return 1;
		    }
		}
    	OnPlayerSelectGunmenuObject(playerid, objectid, modelid);
		return 1;
	}
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	if(Player[playerid][OnGunmenu] && Iter_Contains(PlayerGunObjects[playerid], objectid))
	{
		new gunmenuIndex = -1;
		for(new i = 0; i != MAX_GUNMENU_GUNS; i ++)
		{
		    if(GunmenuData[i][GunPlayerObject][playerid] == objectid)
		    {
		        gunmenuIndex = i;
		        break;
		    }
		}
		if(gunmenuIndex != -1)
		{
	    	switch(GunmenuData[gunmenuIndex][GunMovingRoute][playerid])
	    	{
	    	    case GUN_MOVING_ROUTE_UP: // was moving up
	    	    {
	    	        // move it down
	    	        new Float:x, Float:y, Float:z;
					GetPlayerObjectPos(playerid, objectid, x, y, z);
	    	        MovePlayerObject(playerid, objectid, x, y, z - GUNMENU_OBJECT_Z_CHANGES, GUNMENU_OBJECT_Z_MOVE_SPEED, -25.0, -25.0, -45.0);
					GunmenuData[gunmenuIndex][GunMovingRoute][playerid] = GUN_MOVING_ROUTE_DOWN;
	    	    }
	    	    case GUN_MOVING_ROUTE_DOWN: // was moving down
	    	    {
	    	        // move it up
                    new Float:x, Float:y, Float:z;
					GetPlayerObjectPos(playerid, objectid, x, y, z);
	    	        MovePlayerObject(playerid, objectid, x, y, z + GUNMENU_OBJECT_Z_CHANGES, GUNMENU_OBJECT_Z_MOVE_SPEED, 25.0, 25.0, 45.0);
					GunmenuData[gunmenuIndex][GunMovingRoute][playerid] = GUN_MOVING_ROUTE_UP;
	    	    }
	    	    case GUN_MOVING_ROUTE_TOPLAYER: // was moving towards player
	    	    {
	    	        // successful selection
					OnGunObjectMovedToPlayer(playerid, objectid, gunmenuIndex);
	    	    }
	    	}
 		}
	}
	return 1;
}

public OnPlayerModelSelection(playerid, response, listid, modelid)
{
	if(listid == teamskinlist)
	{
	    if(response && ChangingSkinOfTeam[playerid] != -1)
	    {
		    new iString[128];
			switch(ChangingSkinOfTeam[playerid])
			{
			    case ATTACKER:
				{
			        Skin[ATTACKER] = modelid;

					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Attacker Skin'", Skin[ATTACKER]);
				    db_free_result(db_query(sqliteconnection, iString));

			    }
				case DEFENDER:
				{
			        Skin[DEFENDER] = modelid;

					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Defender Skin'", Skin[DEFENDER]);
				    db_free_result(db_query(sqliteconnection, iString));

			    }
				case REFEREE:
				{
			        Skin[REFEREE] = modelid;

					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Referee Skin'", Skin[REFEREE]);
				    db_free_result(db_query(sqliteconnection, iString));
			    }
			}

			foreach(new i : Player)
			{
			    if(Player[i][Team] == ChangingSkinOfTeam[playerid])
				{
			        SetPlayerSkin(i, modelid);
				}
			}

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}%s "COL_PRIM"skin to: {FFFFFF}%d", Player[playerid][Name], TeamName[ChangingSkinOfTeam[playerid]], modelid);
			SendClientMessageToAll(-1, iString);
			ChangingSkinOfTeam[playerid] = -1;
	    }
	    else
	    {
	        ChangingSkinOfTeam[playerid] = -1;
			SendClientMessage(playerid, -1, "Canceled team skin selection");
		}
	}
	else if(listid == playerskinlist)
	{
	    if(response && !Player[playerid][Playing] && !Player[playerid][Spectating])
	    {
		    SetPlayerSkin(playerid, modelid);
	    }
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	#if defined _league_included
	if(dialogid == DIALOG_LEAGUE_SHOP)
	{
	    if(response)
	    {
	        PlayerSelectShopItem(playerid, listitem);
	    }
	    return 1;
	}
	if(dialogid == DIALOG_LEAGUE_STATS_SUB)
	{
	    if(!response) // "Back" button
	    {
	        ShowLeagueStatsDialog(playerid);
	    }
	    return 1;
	}
	if(dialogid == DIALOG_LEAGUE_STATS)
	{
	    if(response)
	    {
	        ShowLeagueStatistics(playerid, listitem);
	    }
	    return 1;
	}
	#endif
	if(dialogid == DIALOG_GUNMENU_MODIFY_MAIN)
	{
		if(response)
		{
        	Player[playerid][GunmenuModdingIndex] = listitem;
			ShowPlayerDialog(playerid, DIALOG_GUNMENU_MODIFY_SUB, DIALOG_STYLE_LIST, sprintf("Modifying: %s", WeaponNames[GunmenuData[listitem][GunID]]), "Weapon\nLimit\nAmmo", "Select", "Back");
		}
		return 1;
	}
	if(dialogid == DIALOG_GUNMENU_MODIFY_SUB)
	{
		if(response)
		{
		    new idx = Player[playerid][GunmenuModdingIndex];
		    switch(listitem)
		    {
		        case 0:
		        {
		            Player[playerid][GunmenuModdingType] = GUNMENU_MOD_TYPE_WEAPON;
					ShowPlayerDialog(playerid, DIALOG_GUNMENU_MODIFY_SET, DIALOG_STYLE_INPUT, "Changing weapon...", sprintf("Current weapon: %s\n\nType new weapon name below to change!", WeaponNames[GunmenuData[idx][GunID]]), "Set", "Cancel");
		        }
		        case 1:
		        {
		            Player[playerid][GunmenuModdingType] = GUNMENU_MOD_TYPE_LIMIT;
					ShowPlayerDialog(playerid, DIALOG_GUNMENU_MODIFY_SET, DIALOG_STYLE_INPUT, "Changing limit...", sprintf("Current limit of %s: %d\n\nType new limit value below to change!", WeaponNames[GunmenuData[idx][GunID]], GunmenuData[idx][GunLimit]), "Set", "Cancel");
		        }
		        case 2:
		        {
		            Player[playerid][GunmenuModdingType] = GUNMENU_MOD_TYPE_AMMO;
					ShowPlayerDialog(playerid, DIALOG_GUNMENU_MODIFY_SET, DIALOG_STYLE_INPUT, "Changing ammo...", sprintf("Current ammo of %s: %d\n\nType new limit value below to change!", WeaponNames[GunmenuData[idx][GunID]], GunmenuData[idx][GunAmmo]), "Set", "Cancel");
		        }
		    }
		}
		else
		{
		    CallLocalFunction("OnPlayerCommandText", "ds", playerid, "/gunmenumod");
		}
	    return 1;
	}
	if(dialogid == DIALOG_GUNMENU_MODIFY_SET)
	{
		if(response)
		{
		    new idx = Player[playerid][GunmenuModdingIndex];
		    switch(Player[playerid][GunmenuModdingType])
		    {
		        case GUNMENU_MOD_TYPE_WEAPON:
		        {
		            new weaponID = GetWeaponID(inputtext);
				    if(!IsValidWeapon(weaponID))
				    {
				        SendErrorMessage(playerid, "Invalid weapon", MSGBOX_TYPE_BOTTOM);
                        ShowPlayerDialog(playerid, DIALOG_GUNMENU_MODIFY_SET, DIALOG_STYLE_INPUT, "Changing weapon...", sprintf("Current weapon: %s\n\nType new weapon name below to change!", WeaponNames[GunmenuData[idx][GunID]]), "Set", "Cancel");
						return 1;
				    }
		            SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has changed gunmenu index: {FFFFFF}%d "COL_PRIM"from [%s] to [%s]", Player[playerid][Name], idx, WeaponNames[GunmenuData[idx][GunID]], WeaponNames[weaponID]));
					db_free_result(db_query(sqliteconnection, sprintf("UPDATE `Gunmenu` SET `Weapon`=%d WHERE `Weapon`=%d", weaponID, GunmenuData[idx][GunID])));
					GunmenuData[idx][GunID] = weaponID;
				}
                case GUNMENU_MOD_TYPE_LIMIT:
		        {
                    new limit = strval(inputtext);
				    if(limit < 0)
				    {
				        SendErrorMessage(playerid, "Selection limit cannot be less than 0", MSGBOX_TYPE_BOTTOM);
                        ShowPlayerDialog(playerid, DIALOG_GUNMENU_MODIFY_SET, DIALOG_STYLE_INPUT, "Changing limit...", sprintf("Current limit of %s: %d\n\nType new limit value below to change!", WeaponNames[GunmenuData[idx][GunID]], GunmenuData[idx][GunLimit]), "Set", "Cancel");
						return 1;
				    }
		            SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}%s "COL_PRIM"limit to {FFFFFF}%d", Player[playerid][Name], WeaponNames[GunmenuData[idx][GunID]], limit));
					db_free_result(db_query(sqliteconnection, sprintf("UPDATE `Gunmenu` SET `Limit`=%d WHERE `Weapon`=%d", limit, GunmenuData[idx][GunID])));
					GunmenuData[idx][GunLimit] = limit;
		        }
		        case GUNMENU_MOD_TYPE_AMMO:
		        {
                    new ammo = strval(inputtext);
				    if(ammo < 1 || ammo > 9999)
				    {
				        SendErrorMessage(playerid, "Weapon ammo must be equal to or between 1 and 9999", MSGBOX_TYPE_BOTTOM);
                        ShowPlayerDialog(playerid, DIALOG_GUNMENU_MODIFY_SET, DIALOG_STYLE_INPUT, "Changing ammo...", sprintf("Current ammo of %s: %d\n\nType new ammo value below to change!", WeaponNames[GunmenuData[idx][GunID]], GunmenuData[idx][GunAmmo]), "Set", "Cancel");
						return 1;
				    }
		            SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}%s "COL_PRIM"ammo to {FFFFFF}%d", Player[playerid][Name], WeaponNames[GunmenuData[idx][GunID]], ammo));
					db_free_result(db_query(sqliteconnection, sprintf("UPDATE `Gunmenu` SET `Ammo`=%d WHERE `Weapon`=%d", ammo, GunmenuData[idx][GunID])));
					GunmenuData[idx][GunAmmo] = ammo;
		        }
		    }
		}
	    return 1;
	}
	if(dialogid == DIALOG_GUNMENU)
	{
	    OnGunmenuDialogResponse(playerid, response, listitem);
	    return 1;
	}
	if(dialogid == DIALOG_GUNMENU_MELEE)
	{
	    if(response)
	    {
			new
				weap = MeleeWeaponsArray_ID[listitem],
				ammo = MeleeWeaponsArray_AMMO[listitem];
				
			if(DoesPlayerHaveWeapon(playerid, weap))
			{
			    RemovePlayerWeapon(playerid, weap);
			}
			else
			{
			    GivePlayerWeapon(playerid, weap, ammo);
			}
			SetTimerEx("ShowPlayerMeleeWeaponsMenu", GetPlayerPing(playerid) + 200, false, "i", playerid);
	    }
	    return 1;
	}
	if(dialogid == DIALOG_WEAPONBIND_MAIN)
	{
	    if(response)
	    {
	        if(listitem == 0) // Toggle
	        {
				Player[playerid][WeaponBinding] = !Player[playerid][WeaponBinding];
				new str[80];
			    format(str, sizeof(str), "UPDATE Players SET WeaponBinding = %d WHERE Name = '%q'", (Player[playerid][WeaponBinding] == true) ? (1) : (0), Player[playerid][Name]);
			    db_free_result(db_query(sqliteconnection, str));
	            return 1;
	        }
         	new index = listitem - 1;
			WeaponBindData[playerid][ModifyingWeaponBindIndex] = index;
			new str[140];
			format(str, sizeof str, "Key: %s+%s\nCurrent weapon: %s\n\nType weapon name or ID below to code this key bind for it", WEAPON_BIND_PRIMARY_KEY_TEXT_ALT, WeaponBindKeyText_ALT[index], WeaponNames[WeaponBindData[playerid][BindKeyWeapon][index]]);
            ShowPlayerDialog(playerid, DIALOG_WEAPONBIND_MODIFY, DIALOG_STYLE_INPUT, "Coding weapon key bind", str, "Code it", "Cancel");
	    }
	    return 1;
	}
	if(dialogid == DIALOG_WEAPONBIND_MODIFY)
	{
	    if(response)
	    {
	        if(isnull(inputtext))
	            return 1;

			new weaponid;
			if(IsNumeric(inputtext))
				weaponid = strval(inputtext);
			else
			    weaponid = GetWeaponID(inputtext);

			if(weaponid == 0 || IsValidWeapon(weaponid))
			{
			    new index = WeaponBindData[playerid][ModifyingWeaponBindIndex];
			    WeaponBindData[playerid][BindKeyWeapon][index] = weaponid;
			    new str[80];
			    format(str, sizeof(str), "UPDATE Players SET WeaponBind%d = %d WHERE Name = '%q'", index, weaponid, Player[playerid][Name]);
			    db_free_result(db_query(sqliteconnection, str));
			    ShowPlayerWeaponBindTextDraw(playerid, 5000);
			}
	    }
	    return 1;
 	}
    if(dialogid == DIALOG_REPLACE_FIRST)
	{
		if(response)
		{
			new ToAddID = -1;
			foreach(new i : Player)
			{
			    if(!strcmp(Player[i][Name], inputtext, false, strlen(inputtext)))
			    {
			        ToAddID ++;
			        REPLACE_ToAddID[playerid] = i;
			        break;
			    }
			}
			if(ToAddID > -1)
			{
			    new str[2048];
			    foreach(new i : Player)
				{
				    if(Player[i][Playing] != true)
				        continue;

					format(str, sizeof str, "%s%s\n", str, Player[i][Name]);
				}
				for(new i = 0; i < SAVE_SLOTS; i ++)
				{
					if(strlen(SaveVariables[i][pName]) > 2 && SaveVariables[i][RoundID] == Current && SaveVariables[i][ToBeAdded] == true)
					{
					    format(str, sizeof str, "%s%s\n", str, SaveVariables[i][pName]);
					}
				}
				ShowPlayerDialog(playerid, DIALOG_REPLACE_SECOND, DIALOG_STYLE_LIST, ""COL_PRIM"Player to replace", str, "Process", "Cancel");
			}
			else
				SendErrorMessage(playerid, "Player not found.");
		}
		return 1;
	}

	if(dialogid == DIALOG_REPLACE_SECOND)
	{
		if(response)
		{
		    new ToReplaceID = -1;
			foreach(new i : Player)
			{
			    if(!strcmp(Player[i][Name], inputtext, false, strlen(inputtext)))
			    {
			        ToReplaceID = i;
			        break;
			    }
			}
			if(ToReplaceID != -1)
			{
			    new ToAddID = REPLACE_ToAddID[playerid];
			    if(!IsPlayerConnected(ToAddID))
			    {
			        return SendErrorMessage(playerid, "Player is not connected anymore.");
			    }

			    if(Player[ToAddID][InDM] == true)
				{
				    Player[ToAddID][InDM] = false;
					Player[ToAddID][DMReadd] = 0;
				}

				if(Player[ToAddID][InDuel] == true)
					return SendErrorMessage(playerid,"That player is in a duel.");  //duel

				if(Player[ToAddID][LastVehicle] != -1)
				{
					DestroyVehicle(Player[ToAddID][LastVehicle]);
					Player[ToAddID][LastVehicle] = -1;
				}

				if(Player[ToAddID][Spectating] == true)
					StopSpectate(ToAddID);

				SetTimerEx("OnPlayerReplace", 500, false, "iii", ToAddID, ToReplaceID, playerid);
			}
			else
			{
			    for(new i = 0; i < SAVE_SLOTS; i ++)
				{
					if(strlen(SaveVariables[i][pName]) > 2 && !strcmp(SaveVariables[i][pName], inputtext, false, strlen(inputtext)) && SaveVariables[i][RoundID] == Current)
					{
					    ToReplaceID = i;
						break;
					}
				}
				if(ToReplaceID > -1)
				{
				    new ToAddID = REPLACE_ToAddID[playerid];
				    if(!IsPlayerConnected(ToAddID))
				    {
				        return SendErrorMessage(playerid, "Player is not connected anymore.");
				    }

					if(Player[ToAddID][InDM] == true)
					{
					    Player[ToAddID][InDM] = false;
						Player[ToAddID][DMReadd] = 0;
					}

					if(Player[ToAddID][InDuel] == true)
						return SendErrorMessage(playerid,"That player is in a duel.");  //duel

					if(Player[ToAddID][LastVehicle] != -1)
					{
						DestroyVehicle(Player[ToAddID][LastVehicle]);
						Player[ToAddID][LastVehicle] = -1;
					}

					if(Player[ToAddID][Spectating] == true)
						StopSpectate(ToAddID);
					SetTimerEx("OnPlayerInGameReplace", 500, false, "iii", ToAddID, ToReplaceID, playerid);
				}
				else
					SendErrorMessage(playerid, "Player not found.");
			}
		}
		return 1;
	}
	if(dialogid == DIALOG_THEME_CHANGE1)
	{
	    if(response)
	    {
	        ThemeChange_listitem{playerid} = listitem;
	        ShowPlayerDialog(playerid, DIALOG_THEME_CHANGE2, DIALOG_STYLE_MSGBOX, "Caution: server needs restart", "The server needs to be restarted now for the changes to be\ncompletely applied. Restart now or cancel everything?", "Restart", "Cancel");
	    }
	    return 1;
	}
	if(dialogid == DIALOG_THEME_CHANGE2)
	{
	    if(response)
	    {
	        ChangeTheme(playerid, ThemeChange_listitem{playerid});
	    }
	    return 1;
	}
	if(dialogid == PLAYERCLICK_DIALOG)
	{
	    if(response)
        {
            if(!IsPlayerConnected(LastClickedPlayer[playerid]))
            	return SendErrorMessage(playerid, "That player is not connected anymore!");

            switch(listitem)
            {
                case 0:
                {
	                new statsSTR[4][300], namee[60], CID, Country[128];
				    CID = LastClickedPlayer[playerid];

					format(namee, sizeof(namee), "{FF3333}Player {FFFFFF}%s {FF3333}Stats", Player[CID][Name]);
					GetPlayerCountry(CID, Country, sizeof(Country));

					new TD = Player[CID][TotalDeaths];
					new RD = Player[CID][RoundDeaths];
					new MC = Player[playerid][ChatChannel];
					new YC = Player[CID][ChatChannel];

	                format(statsSTR[0], sizeof(statsSTR[]), ""COL_PRIM"- {FFFFFF}Country: %s\n\n"COL_PRIM"- {FFFFFF}Round Kills: \t\t%d\t\t"COL_PRIM"- {FFFFFF}Total Kills: \t\t%d\t\t"COL_PRIM"- {FFFFFF}FPS: \t\t\t%d\n"COL_PRIM"- {FFFFFF}Round Deaths: \t%.0f\t\t"COL_PRIM"- {FFFFFF}Total Deaths: \t%d\t\t"COL_PRIM"- {FFFFFF}Ping: \t\t\t%d\n",Country,Player[CID][RoundKills],Player[CID][TotalKills], Player[CID][FPS], RD, TD, GetPlayerPing(CID));
					format(statsSTR[1], sizeof(statsSTR[]), ""COL_PRIM"- {FFFFFF}Round Damage: \t%d\t\t"COL_PRIM"- {FFFFFF}Total Damage:   \t%d\t\t"COL_PRIM"- {FFFFFF}Packet-Loss:   \t%.1f\n\n"COL_PRIM"- {FFFFFF}Player Weather: \t%d\t\t"COL_PRIM"- {FFFFFF}Chat Channel: \t%d\t\t"COL_PRIM"- {FFFFFF}In Round: \t\t%s\n",Player[CID][RoundDamage],Player[CID][TotalDamage], NetStats_PacketLossPercent(CID), Player[CID][Weather], (MC == YC ? YC : -1), (Player[CID][Playing] == true ? ("Yes") : ("No")));
					format(statsSTR[2], sizeof(statsSTR[]), ""COL_PRIM"- {FFFFFF}Player Time: \t\t%d\t\t"COL_PRIM"- {FFFFFF}DM ID: \t\t%d\t\t"COL_PRIM"- {FFFFFF}Hit Sound: \t\t%d\n"COL_PRIM"- {FFFFFF}Player NetCheck: \t%s\t"COL_PRIM"- {FFFFFF}Player Level: \t%d\t\t"COL_PRIM"- {FFFFFF}Get Hit Sound: \t%d\n", Player[CID][Time], (Player[CID][DMReadd] > 0 ? Player[CID][DMReadd] : -1), Player[CID][HitSound], (Player[CID][NetCheck] == 1 ? ("Enabled") : ("Disabled")), Player[CID][Level], Player[CID][GetHitSound]);
					format(statsSTR[3], sizeof(statsSTR[]), ""COL_PRIM"- {FFFFFF}Duels Won: \t\t%d\t\t"COL_PRIM"- {FFFFFF}Duels Lost: \t\t%d", Player[CID][DuelsWon], Player[CID][DuelsLost]);
					new TotalStr[1200];
					format(TotalStr, sizeof(TotalStr), "%s%s%s%s", statsSTR[0], statsSTR[1], statsSTR[2], statsSTR[3]);

					ShowPlayerDialog(playerid, DIALOG_CLICK_STATS, DIALOG_STYLE_MSGBOX, namee, TotalStr, "Close", "");
                }
                case 1:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/aka %d", LastClickedPlayer[playerid]));
                }
                case 2:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/spec %d", LastClickedPlayer[playerid]));
                }
                case 3:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/add %d", LastClickedPlayer[playerid]));
                }
                case 4:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/remove %d", LastClickedPlayer[playerid]));
                }
                case 5:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/readd %d", LastClickedPlayer[playerid]));
                }
                case 6:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/givemenu %d", LastClickedPlayer[playerid]));
                }
                case 7:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/goto %d", LastClickedPlayer[playerid]));
                }
                case 8:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/get %d", LastClickedPlayer[playerid]));
                }
                case 9:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/slap %d", LastClickedPlayer[playerid]));
                }
                case 10:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/mute %d No Reason Specified", LastClickedPlayer[playerid]));
                }
                case 11:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/unmute %d", LastClickedPlayer[playerid]));
                }
                case 12:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/kick %d No Reason Specified", LastClickedPlayer[playerid]));
                }
                case 13:
                {
                    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/ban %d No Reason Specified", LastClickedPlayer[playerid]));
                }
            }
        }
	    return 1;
	}
	if(dialogid == DIALOG_REGISTER) {
	    if(response) {
			if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,"{FFFFFF}Registration Dialog","{FFFFFF}Type your password below to register:","Register","Leave");

			if(strfind(inputtext, "%", true) != -1)
			{
			    ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,"{FFFFFF}Registration Dialog","{FFFFFF}Type your password below to register:","Register","Leave");
			    return SendErrorMessage(playerid, sprintf("This character '%s' is disallowed in user passwords.", "%%"));
			}

			new HashPass[140];
		    format(HashPass, sizeof(HashPass), "%d", udb_hash(inputtext));

			new IP[16];
			GetPlayerIp(playerid, IP, sizeof(IP));
			new day, month, year;
			getdate(year, month, day);
			new query[240];
			format(query, sizeof(query), "INSERT INTO Players (Name, Password, IP, LastSeen_Day, LastSeen_Month, LastSeen_Year) VALUES('%q', '%q', '%s', %d, %d, %d)", Player[playerid][Name], HashPass, IP, day, month, year);
			db_free_result(db_query(sqliteconnection, query));

            SendClientMessage(playerid, -1, sprintf("{009933}Server account: {FFFFFF}registered your account with the password: %s", inputtext));

            new teamid = ShouldPlayerBeReadded(playerid);
			if(teamid != -1)
			{
				SetTimerEx("SpawnConnectedPlayer", 250, false, "ii", playerid, teamid);
			}
			else
			{
				ShowIntroTextDraws(playerid);
				ShowPlayerClassSelection(playerid);
			}

			Player[playerid][Level] = 0;
			Player[playerid][Weather] = MainWeather;
			Player[playerid][Time] = MainTime;
            Player[playerid][Logged] = true;
		    Player[playerid][ChatChannel] = -1;
		    Player[playerid][NetCheck] = 1;
		    Player[playerid][DuelsWon] = 0;
		    Player[playerid][DuelsLost] = 0;
		}
		else
		{
			new iString[128];
			format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has been kicked from the server for not registering.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);

			SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
		}
		return 1;
	}
    #if defined _league_included
    if(dialogid == DIALOG_LEAGUE_REGISTER)
	{
	    if(response)
	    {
	        if(isnull(inputtext))
				return ShowPlayerLeagueRegisterDialog(playerid);

            if(strfind(inputtext, "%", true) != -1)
			{
			    ShowPlayerLeagueRegisterDialog(playerid);
				return SendErrorMessage(playerid, sprintf("This character '%s' is disallowed in user passwords.", "%%"));
			}
			if(strlen(inputtext) < 8)
			{
                ShowPlayerLeagueRegisterDialog(playerid);
                return SendErrorMessage(playerid, "Password must be atleast 8 characters long!");
			}
			if(strfind(inputtext, " ", true) != -1)
			{
                ShowPlayerLeagueRegisterDialog(playerid);
                return SendErrorMessage(playerid, "Password must not contain spaces!");
			}
            RegisterPlayerInLeague(playerid, inputtext);
	    }
	    else
	    {
			new iString[128];
			format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has NOT registered a league account.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);

			Player[playerid][MustLeaguePass] = false;
			Player[playerid][MustLeagueRegister] = false;
			Player[playerid][LeagueLogged] = false;
			
			OnPlayerRequestClass(playerid, 0);
			InitLeaguePlayer(playerid);
	    }
	    return 1;
	}
	if(dialogid == DIALOG_LEAGUE_LOGIN)
	{
	    if(response)
	    {
	        if(isnull(inputtext))
				return ShowPlayerLeagueLoginDialog(playerid);

            if(strfind(inputtext, "%", true) != -1)
			{
			    ShowPlayerLeagueLoginDialog(playerid);
				return SendErrorMessage(playerid, sprintf("This character '%s' is disallowed in user passwords.", "%%"));
			}
            CheckPlayerLeagueAccount(playerid, inputtext);
	    }
	    else
	    {
	        new iString[128];
			format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has NOT logged into their league account.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
			
			Player[playerid][MustLeaguePass] = false;
			Player[playerid][MustLeagueRegister] = false;
			Player[playerid][LeagueLogged] = false;
			
			OnPlayerRequestClass(playerid, 0);
			InitLeaguePlayer(playerid);
	    }
	    return 1;
	}
	#endif
	if(dialogid == DIALOG_LOGIN)
	{
	    if(response)
		{
			if(isnull(inputtext))
				return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,"{FFFFFF}Login Dialog","{FFFFFF}Type your password below to log in:","Login","Leave");

            if(strfind(inputtext, "%", true) != -1)
			{
			    ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,"{FFFFFF}Login Dialog","{FFFFFF}Type your password below to log in:","Login","Leave");
				return SendErrorMessage(playerid, sprintf("This character '%s' is disallowed in user passwords.", "%%"));
			}

			new HashPass[140];
			format(HashPass, sizeof(HashPass), "%d", udb_hash(inputtext));

            new Query[256];
			format(Query, sizeof(Query), "SELECT * FROM `Players` WHERE `Name` = '%q' AND `Password` = '%q'", Player[playerid][Name], HashPass);
		    new DBResult:res = db_query(sqliteconnection, Query);

			if(db_num_rows(res))
			{
				LoginPlayer(playerid, res);
				new teamid = ShouldPlayerBeReadded(playerid);
				if(teamid != -1)
				{
					SetTimerEx("SpawnConnectedPlayer", 250, false, "ii", playerid, teamid);
				}
				else
				{
					ShowIntroTextDraws(playerid);
   					ShowPlayerClassSelection(playerid);
				}
			}
			else
			{
		 		SendErrorMessage(playerid,"Wrong Password. Please try again.");
		 		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,"{FFFFFF}Login Dialog","{FFFFFF}Type your password below to log in:","Login","Leave");
			}
			db_free_result(res);
		}
		else
		{
            new iString[128];
			format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has been kicked from the server for not logging in.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);

			SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
		}
		return 1;
	}

	if(dialogid == DIALOG_SERVER_PASS) {
		if(response) {
		    if(isnull(inputtext)) return 1;
			if(strlen(inputtext) > MAX_SERVER_PASS_LENGH) {
				SendErrorMessage(playerid,"Server password is too long.");
			   	ShowPlayerDialog(playerid, DIALOG_SERVER_PASS, DIALOG_STYLE_INPUT,""COL_PRIM"Server Password",""COL_PRIM"Enter server password below:", "Ok","Close");
				return 1;
			}
            format(ServerPass, sizeof(ServerPass), "password %s", inputtext);
           	SendRconCommand(ServerPass);

			ServerLocked = true;
			PermLocked = false;

            new iString[144];
			format(iString, sizeof(iString), "%sServer Pass: ~r~~h~%s", MAIN_TEXT_COLOUR, inputtext);
			TextDrawSetString(LockServerTD, iString);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has locked the server. Password: {FFFFFF}%s",Player[playerid][Name], inputtext);
			SendClientMessageToAll(-1, iString);
		}
		return 1;
	}

	if(dialogid == DIALOG_CURRENT_TOTAL)
	{
		if(isnull(inputtext)) return 1;
        if(!IsNumeric(inputtext)) {
            SendErrorMessage(playerid,"You can only use numeric input.");
    		ShowPlayerDialog(playerid, DIALOG_CURRENT_TOTAL, DIALOG_STYLE_INPUT,""COL_PRIM"Rounds Dialog",""COL_PRIM"Enter current round or total rounds to be played:","Current","Total");
			return 1;
		}

		new Value = strval(inputtext);

		if(Value < 0 || Value > 100) {
            SendErrorMessage(playerid,"Current or total rounds can only be between 0 and 100.");
    		ShowPlayerDialog(playerid, DIALOG_CURRENT_TOTAL, DIALOG_STYLE_INPUT,""COL_PRIM"Rounds Dialog",""COL_PRIM"Enter current round or total rounds to be played:","Current","Total");
			return 1;
		}

        new iString[144];

	    if(response) {
	        CurrentRound = Value;
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed the current round to: {FFFFFF}%d", Player[playerid][Name], CurrentRound);
			SendClientMessageToAll(-1, iString);
		} else {
		    TotalRounds = Value;
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed the total rounds to: {FFFFFF}%d", Player[playerid][Name], TotalRounds);
			SendClientMessageToAll(-1, iString);
		}
		UpdateRoundsPlayedTextDraw();
		return 1;
	}

	if(dialogid == DIALOG_TEAM_SCORE)
	{
		if(response) {
		    switch(listitem) {
		        case 0: {
				    ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:","Next","Close");
				} case 1: {
				    new iString[128];
					format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[ATTACKER]);
				    ShowPlayerDialog(playerid, DIALOG_ATT_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Score",iString,"Next","Close");
				} case 2: {
				    TeamScore[ATTACKER] = 0;
				    TeamScore[DEFENDER] = 0;
				    CurrentRound = 0;

					UpdateTeamScoreTextDraw();
					UpdateRoundsPlayedTextDraw();
					UpdateTeamNameTextDraw();

					UpdateTeamNamesTextdraw();

					ClearPlayerVariables();

					foreach(new i : Player)
					{
		   				Player[i][TotalKills] = 0;
						Player[i][TotalDeaths] = 0;
						Player[i][TotalDamage] = 0;
						Player[i][RoundPlayed] = 0;
					    Player[i][TotalBulletsFired] = 0;
					    Player[i][TotalshotsHit] = 0;
					}

					new iString[64];
					format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has reset the scores.", Player[playerid][Name]);
					SendClientMessageToAll(-1, iString);
				}
			}
		}
		return 1;
	}

	if(dialogid == DIALOG_WAR_RESET)
	{
	    if(response)
		{
		    TeamScore[ATTACKER] = 0;
		    TeamScore[DEFENDER] = 0;
		    CurrentRound = 0;
		    
		    new DBResult:res = db_query(sqliteconnection, "SELECT * FROM Configs WHERE Option = 'Total Rounds'");

            new iString[144];
            
			db_get_field_assoc(res, "Value", iString, sizeof(iString));
    		TotalRounds = strval(iString);
			db_free_result(res);

			TeamName[ATTACKER] = "Alpha";
			TeamName[ATTACKER_SUB] = "Alpha Sub";
			TeamName[DEFENDER] = "Beta";
			TeamName[DEFENDER_SUB] = "Beta Sub";

			UpdateTeamScoreTextDraw();
			UpdateRoundsPlayedTextDraw();
			UpdateTeamNameTextDraw();


			format(iString, sizeof iString, "%sWar Mode: ~r~OFF", MAIN_TEXT_COLOUR);
			TextDrawSetString(WarModeText, iString);

			foreach(new i : Player) {
   				Player[i][TotalKills] = 0;
				Player[i][TotalDeaths] = 0;
				Player[i][TotalDamage] = 0;
				Player[i][RoundPlayed] = 0;
			    Player[i][TotalBulletsFired] = 0;
			    Player[i][TotalshotsHit] = 0;
			}

            ClearPlayerVariables();

			HideMatchScoreBoard();

			WarMode = false;
			#if defined _league_included
			UpdateOnlineMatchesList(false);
			CancelLeagueMode();
			#endif

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled the Match-Mode.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		}
		return 1;
	}

	if(dialogid == DIALOG_ATT_NAME) {
	    if(response) {
			if(isnull(inputtext)) {
			    ShowPlayerDialog(playerid, DIALOG_DEF_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Name",""COL_PRIM"Enter {FFFFFF}Defender "COL_PRIM"Team Name Below:","Ok","Close");
				return 1;
			}
			if(strlen(inputtext) > 6) {
            	SendErrorMessage(playerid,"Team name is too long.");
			    ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:","Next","Close");
				return 1;
			}

			if(strfind(inputtext, "~") != -1) {
			    return SendErrorMessage(playerid,"~ not allowed.");
			}

			format(TeamName[ATTACKER], 24, inputtext);
			format(TeamName[ATTACKER_SUB], 24, "%s Sub", TeamName[ATTACKER]);

  	 		UpdateTeamScoreTextDraw();
			UpdateRoundsPlayedTextDraw();
			UpdateTeamNameTextDraw();

		    UpdateTeamNamesTextdraw();

            new iString[144];
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set attacker team name to: {FFFFFF}%s", Player[playerid][Name], TeamName[ATTACKER]);
			SendClientMessageToAll(-1, iString);

			ShowPlayerDialog(playerid, DIALOG_DEF_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Name",""COL_PRIM"Enter {FFFFFF}Defender "COL_PRIM"Team Name Below:","Ok","Close");
		}
		return 1;
	}

	if(dialogid == DIALOG_DEF_NAME)
	{
	    if(response)
		{
	        if(isnull(inputtext)) return 1;
	        if(strlen(inputtext) > 6) {
	           	SendErrorMessage(playerid,"Team name is too long.");
			    ShowPlayerDialog(playerid, DIALOG_DEF_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Name",""COL_PRIM"Enter {FFFFFF}Defender "COL_PRIM"Team Name Below:","Ok","Close");
				return 1;
			}

			if(strfind(inputtext, "~") != -1) {
			    return SendErrorMessage(playerid,"~ not allowed.");
			}

			format(TeamName[DEFENDER], 24, inputtext);
			format(TeamName[DEFENDER_SUB], 24, "%s Sub", TeamName[DEFENDER]);

			UpdateTeamScoreTextDraw();
			UpdateRoundsPlayedTextDraw();
			UpdateTeamNameTextDraw();

		    UpdateTeamNamesTextdraw();

			new iString[144];
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set defender team name to: {FFFFFF}%s", Player[playerid][Name], TeamName[DEFENDER]);
			SendClientMessageToAll(-1, iString);

		    WarMode = true;
			#if defined _league_included
		    UpdateOnlineMatchesList(true);
		    #endif
		    format(iString, sizeof iString, "%sWar Mode: ~r~ON", MAIN_TEXT_COLOUR);
			TextDrawSetString(WarModeText, iString);

			ShowMatchScoreBoard();
		}
		return 1;
	}

	if(dialogid == DIALOG_ATT_SCORE)
	{
	    if(response)
		{
	        new iString[128];
	        if(isnull(inputtext))
			{
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[DEFENDER]);
			    ShowPlayerDialog(playerid, DIALOG_DEF_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Score",iString,"Ok","Close");
				return 1;
			}
			if(!IsNumeric(inputtext))
			{
	            SendErrorMessage(playerid,"Score can only be numerical.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FF3333}%s "COL_PRIM"Team Score Below:", TeamName[ATTACKER]);
			    ShowPlayerDialog(playerid, DIALOG_ATT_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Score",iString,"Next","Close");
				return 1;
			}
			new Score = strval(inputtext);

			if(Score < 0 || Score > 100)
			{
	            SendErrorMessage(playerid,"Score can only be between 0 and 100.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FF3333}%s "COL_PRIM"Team Score Below:", TeamName[ATTACKER]);
			    ShowPlayerDialog(playerid, DIALOG_ATT_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Score",iString,"Next","Close");
				return 1;
			}

			if((Score + TeamScore[DEFENDER]) >= TotalRounds)
			{
				SendErrorMessage(playerid,"Attacker plus defender score is bigger than or equal to total rounds.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[ATTACKER]);
			    ShowPlayerDialog(playerid, DIALOG_ATT_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Score",iString,"Next","Close");
				return 1;
			}

			TeamScore[ATTACKER] = Score;
			CurrentRound = TeamScore[ATTACKER] + TeamScore[DEFENDER];


			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set attacker team score to: {FFFFFF}%d", Player[playerid][Name], TeamScore[ATTACKER]);
			SendClientMessageToAll(-1, iString);

			UpdateTeamScoreTextDraw();
			UpdateRoundsPlayedTextDraw();
			UpdateTeamNameTextDraw();

			format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[DEFENDER]);
		    ShowPlayerDialog(playerid, DIALOG_DEF_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Score",iString,"Ok","Close");
		}
		return 1;
	}

	if(dialogid == DIALOG_DEF_SCORE)
	{
	    if(response)
		{
	        if(isnull(inputtext))
				return 1;

            new iString[128];
	        if(!IsNumeric(inputtext))
			{
	            SendErrorMessage(playerid,"Score can only be numerical.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[DEFENDER]);
			    ShowPlayerDialog(playerid, DIALOG_DEF_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Score",iString,"Ok","Close");
				return 1;
			}

			new Score = strval(inputtext);

			if(Score < 0 || Score > 100)
			{
	            SendErrorMessage(playerid,"Score can only be between 0 and 100.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[DEFENDER]);
			    ShowPlayerDialog(playerid, DIALOG_DEF_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Score",iString,"Ok","Close");
			    return 1;
			}

			if((TeamScore[ATTACKER] + Score) >= TotalRounds)
			{
	            SendErrorMessage(playerid,"Attacker plus defender score is bigger than or equal to total rounds.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[DEFENDER]);
			    ShowPlayerDialog(playerid, DIALOG_DEF_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Score",iString,"Ok","Close");
				return 1;
			}
			TeamScore[DEFENDER] = Score;
			CurrentRound = TeamScore[ATTACKER] + TeamScore[DEFENDER];

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set defender team score to: {FFFFFF}%d", Player[playerid][Name], TeamScore[DEFENDER]);
			SendClientMessageToAll(-1, iString);

			UpdateTeamScoreTextDraw();
			UpdateRoundsPlayedTextDraw();
			UpdateTeamNameTextDraw();
		}
		return 1;
	}

	if(dialogid == DIALOG_CONFIG)
	{
	    if(response)
		{
	        switch(listitem)
			{
	            case 0: {
				    ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:","Next","Close");
	            }
	            case 1: {
	                new iString[128];
	                format(iString, sizeof(iString), "%sAttacker Team\n%sDefender Team\n%sReferee Team", TextColor[ATTACKER], TextColor[DEFENDER], TextColor[REFEREE]);
	                ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_TEAM_SKIN, DIALOG_STYLE_LIST, ""COL_PRIM"Select team", iString, "OK", "Back");
	            }
				case 2: {
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_AAD, DIALOG_STYLE_LIST, ""COL_PRIM"A/D Config", ""COL_PRIM"Health\n"COL_PRIM"Armour\n"COL_PRIM"Round Time\n"COL_PRIM"CP Time", "OK", "Back");
				}
				case 3: {
				    SendRconCommand("gmx");
				}
				case 4: {
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_MAX_PING, DIALOG_STYLE_INPUT, ""COL_PRIM"Set max Ping", "Set the max ping:", "OK", "Back");
				}
				case 5: {
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_MAX_PACKET, DIALOG_STYLE_INPUT, ""COL_PRIM"Set max Packetloss", "Set the max packetloss:", "OK", "Back");
				}
				case 6: {
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_MIN_FPS, DIALOG_STYLE_INPUT, ""COL_PRIM"Set Minimum FPS", "Set the minimum FPS:", "OK", "Back");
				}
				case 7: {
				    new string[90];

					if(strlen(GroupAccessPassword[0]) > 0)
					{
						format(string, sizeof string, "{FF6666}%s", TeamName[ATTACKER]);
	 				}
				 	else
				 	{
				 	    format(string, sizeof string, "{66FF66}%s", TeamName[ATTACKER]);
	 				}

					if(strlen(GroupAccessPassword[1]) > 0)
					{
						format(string, sizeof string, "%s\n{FF6666}%s", string, TeamName[DEFENDER]);
	 				}
				 	else
				 	{
				 	    format(string, sizeof string, "%s\n{66FF66}%s", string, TeamName[DEFENDER]);
	 				}

                    if(strlen(GroupAccessPassword[2]) > 0)
					{
						format(string, sizeof string, "%s\n{FF6666}Referee", string);
	 				}
				 	else
				 	{
				 	    format(string, sizeof string, "%s\n{66FF66}Referee", string);
	 				}

	 				if(strlen(GroupAccessPassword[3]) > 0)
					{
						format(string, sizeof string, "%s\n{FF6666}%s Sub", string, TeamName[ATTACKER]);
	 				}
				 	else
				 	{
				 	    format(string, sizeof string, "%s\n{66FF66}%s Sub", string, TeamName[ATTACKER]);
	 				}

	 				if(strlen(GroupAccessPassword[4]) > 0)
					{
						format(string, sizeof string, "%s\n{FF6666}%s Sub", string, TeamName[DEFENDER]);
	 				}
				 	else
				 	{
				 	    format(string, sizeof string, "%s\n{66FF66}%s Sub", string, TeamName[DEFENDER]);
	 				}
	 				ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_GA, DIALOG_STYLE_LIST, ""COL_PRIM"Config Settings", string, "OK", "Cancel");
	 				return 1;
				}
				case 8: {
				    if(!ServerLocked) {
				        ShowPlayerDialog(playerid, DIALOG_SERVER_PASS, DIALOG_STYLE_INPUT,""COL_PRIM"Server Password",""COL_PRIM"Enter server password below:", "Ok","Close");
				    } else {
				        SendRconCommand("password 0");
				        ServerLocked = false;
				        PermLocked = false;
				    }
				}
				case 9: {
				    new iString[144];
				    if(AntiSpam == false) {
					    AntiSpam = true;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"anti-spam.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
				    } else {
				        AntiSpam = false;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"anti-spam.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}
                    ShowConfigDialog(playerid);
				}
				case 10: {
				    new iString[144];
				    if(AutoBal == false) {
					    AutoBal = true;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"auto-balance in non war mode.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
				    } else {
				        AutoBal = false;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"auto-balance in non war mode.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}
                    ShowConfigDialog(playerid);
				}
				case 11: {
				    new iString[144];
				    if(AutoPause == false) {
					    AutoPause = true;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"Auto-Pause on player disconnect in war mode.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
				    } else {
				        AutoPause = false;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"Auto-Pause on player disconnect in war mode.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}
                    ShowConfigDialog(playerid);
				}
				case 12: {
                    new iString[144];
					if(LobbyGuns == true) {
						LobbyGuns = false;
				    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"guns in lobby.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					} else {
						LobbyGuns = true;
					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"guns in lobby.", Player[playerid][Name]);
				        SendClientMessageToAll(-1, iString);
					}
				    ShowConfigDialog(playerid);
				}
				case 13:
				{
				    if(!IsACPluginLoaded())
					{
						SendErrorMessage(playerid, "Anticheat plugin is not loaded.", MSGBOX_TYPE_BOTTOM);
						ShowConfigDialog(playerid);
					}
					else if(!IsACEnabled())
					{
						SendErrorMessage(playerid, "Anticheat is not enabled.", MSGBOX_TYPE_BOTTOM);
						ShowConfigDialog(playerid);
					}
					else
					{
					    new iString[144];
					    if(DefendersSeeVehiclesBlips == false)
						{
						    DefendersSeeVehiclesBlips = true;
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"defenders see vehicle blips{FFFFFF} option.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
						}
						else
						{
						    DefendersSeeVehiclesBlips = false;
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"defenders see vehicle blips{FFFFFF} option.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
						}
					}
				}
				case 14:
				{
				    #if defined _league_included
				    new iString[144];
				    switch(LeagueAllowed)
				    {
						case false:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"league system{FFFFFF} on this server.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							SendClientMessageToAll(-1, ""COL_PRIM"Notice: {FFFFFF}the system works automatically, so you need not run any special commands. Just switch match-mode on!");
							LeagueAllowed = true;
							CheckLeagueMatchValidity(1000);
						}
						case true:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"league system{FFFFFF} on this server.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							LeagueAllowed = false;
                            CancelLeagueMode();
						}
				    }
					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'LeagueAllowed'", (LeagueAllowed == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));
					#else
					SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
					#endif
				}
				case 15:
				{
				    if(Current != -1) return SendErrorMessage(playerid, "Can't use this while a round is in progress.");
				    new iString[144];
				    switch(CPInArena)
				    {
						case false:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"Checkpoint in arena{FFFFFF} option.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							CPInArena = true;
						}
						case true:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"Checkpoint in arena{FFFFFF} option.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							CPInArena = false;
						}
					}
					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'CPInArena'", (CPInArena == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));
				    ShowConfigDialog(playerid);
				}
				case 16:
				{
				    new iString[144];
				    switch(AntiMacros)
				    {
						case false:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"Anti-macros{FFFFFF} system.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							AntiMacros = true;
						}
						case true:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"Anti-macros{FFFFFF} system.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							AntiMacros = false;
						}
					}
					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'AntiMacros'", (AntiMacros == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));
				    ShowConfigDialog(playerid);
				}
				case 17:
				{
				    new iString[144];
				    switch(DeadBodies)
				    {
						case false:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"Dead bodies{FFFFFF} option.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							DeadBodies = true;
						}
						case true:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"Dead bodies{FFFFFF} option.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							DeleteAllDeadBodies();
							DeadBodies = false;
						}
					}
					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'DeadBodies'", (DeadBodies == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));
				    ShowConfigDialog(playerid);
				}
				case 18:
				{
				    new iString[144];
				    switch(DeathCamera)
				    {
						case false:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"Death camera{FFFFFF} system.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							DeathCamera = true;
						}
						case true:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"Death camera{FFFFFF} system.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							DeathCamera = false;
						}
					}
					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'DeathCamera'", (DeathCamera == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));
				    ShowConfigDialog(playerid);
				}
				case 19:
				{
				    if(Current != -1) return SendErrorMessage(playerid, "Can't do this while a round is in progress.");
				    new iString[144];
				    switch(ShowHPBars)
				    {
						case false:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"HP Bars{FFFFFF} system.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							ShowHPBars = true;
						}
						case true:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"HP Bars{FFFFFF} system.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							ShowHPBars = false;
						}
					}
					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'ShowHPBars'", (ShowHPBars == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));
				    ShowConfigDialog(playerid);
    			}
				case 20:
				{
				    new iString[144];
				    switch(LeagueShop)
				    {
						case false:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"League Shop{FFFFFF} system.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							LeagueShop = true;
						}
						case true:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"League Shop{FFFFFF} system.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							LeagueShop = false;
						}
					}
					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'LeagueShop'", (LeagueShop == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));
				    ShowConfigDialog(playerid);
				}
				case 21:
				{
				    new iString[144];
				    switch(GunmenuRestrictions)
				    {
						case false:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"Gunmenu selection restriction.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							GunmenuRestrictions = true;
						}
						case true:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"Gunmenu selection restriction.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							GunmenuRestrictions = false;
						}
					}
				    ShowConfigDialog(playerid);
				}
				case 22:
				{
				    new iString[144];
				    switch(MeleeAllowed)
				    {
						case false:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"melee weapons menu{FFFFFF} option.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							MeleeAllowed = true;
						}
						case true:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"melee weapons menu{FFFFFF} option.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							MeleeAllowed = false;
						}
					}
					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'MeleeAllowed'", (MeleeAllowed == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));
				    ShowConfigDialog(playerid);
				}
				case 23:
				{
				    new iString[144];
				    switch(AutoRoundStarter)
				    {
						case false:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"auto round start{FFFFFF} option.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							AutoRoundStarter = true;
							if(Current == -1 && AllowStartBase != false)
							{
							    SetRoundAutoStart(0);
							}
						}
						case true:
						{
						    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"auto round start{FFFFFF} option.", Player[playerid][Name]);
							SendClientMessageToAll(-1, iString);
							AutoRoundStarter = false;
						}
					}
					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'AutoRoundStarter'", (AutoRoundStarter == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));
				    ShowConfigDialog(playerid);
				}
	        }
	    }
	    return 1;
	}


	if(dialogid == DIALOG_CONFIG_SET_GA) {
	    if(!response) return ShowConfigDialog(playerid);
	    switch(listitem)
	    {
	        case 0: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_GA_ALPHA, DIALOG_STYLE_INPUT, ""COL_PRIM"ALPHA PASSWORD", ""COL_PRIM"Set the password or leave empty to clear:", "OK", "Cancel"); }
	        case 1: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_GA_BETA, DIALOG_STYLE_INPUT, ""COL_PRIM"BETA PASSWORD", ""COL_PRIM"Set the password or leave empty to clear:", "OK", "Cancel"); }
            case 2: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_GA_REF, DIALOG_STYLE_INPUT, ""COL_PRIM"REFEREE PASSWORD", ""COL_PRIM"Set the password or leave empty to clear:", "OK", "Cancel"); }
		    case 3: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_GA_ASUB, DIALOG_STYLE_INPUT, ""COL_PRIM"ALPHA SUB PASSWORD", ""COL_PRIM"Set the password or leave empty to clear:", "OK", "Cancel"); }
	        case 4: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_GA_BSUB, DIALOG_STYLE_INPUT, ""COL_PRIM"BETA SUB PASSWORD", ""COL_PRIM"Set the password or leave empty to clear:", "OK", "Cancel"); }
     	}
	    return 1;
	}

	if(dialogid == DIALOG_CONFIG_SET_GA_ALPHA)
	{
	    if(!response) return ShowConfigDialog(playerid);
	    if(strlen(inputtext) > MAX_GROUP_ACCESS_PASSWORD_LENGTH)
	    {
	        SendErrorMessage(playerid, "The password you entered is quite long. Try again with a shorter one!", MSGBOX_TYPE_BOTTOM);
	        return ShowConfigDialog(playerid);
	    }
	    format(GroupAccessPassword[0], MAX_GROUP_ACCESS_PASSWORD_LENGTH, "%s", inputtext);
	    new str[128];
		format(str, sizeof(str), "%s "COL_PRIM"has changed the alpha group access", Player[playerid][Name]);
		SendClientMessageToAll(-1, str);
	    return ShowConfigDialog(playerid);
	}

	if(dialogid == DIALOG_CONFIG_SET_GA_BETA)
	{
	    if(!response) return ShowConfigDialog(playerid);
		if(strlen(inputtext) > MAX_GROUP_ACCESS_PASSWORD_LENGTH)
	    {
	        SendErrorMessage(playerid, "The password you entered is quite long. Try again with a shorter one!", MSGBOX_TYPE_BOTTOM);
	        return ShowConfigDialog(playerid);
	    }
	    format(GroupAccessPassword[1], MAX_GROUP_ACCESS_PASSWORD_LENGTH, "%s", inputtext);
	    new str[128];
		format(str, sizeof(str), "%s "COL_PRIM"has changed the beta group access", Player[playerid][Name]);
		SendClientMessageToAll(-1, str);
	    return ShowConfigDialog(playerid);
	}

	if(dialogid == DIALOG_CONFIG_SET_GA_REF && response)
	{
	    if(!response) return ShowConfigDialog(playerid);
	    if(strlen(inputtext) > MAX_GROUP_ACCESS_PASSWORD_LENGTH)
	    {
	        SendErrorMessage(playerid, "The password you entered is quite long. Try again with a shorter one!", MSGBOX_TYPE_BOTTOM);
	        return ShowConfigDialog(playerid);
	    }
	    format(GroupAccessPassword[2], MAX_GROUP_ACCESS_PASSWORD_LENGTH, "%s", inputtext);
	    new str[128];
		format(str, sizeof(str), "%s "COL_PRIM"has changed the referee group access", Player[playerid][Name]);
		SendClientMessageToAll(-1, str);
	    return ShowConfigDialog(playerid);
	}

	if(dialogid == DIALOG_CONFIG_SET_GA_ASUB)
	{
	    if(!response) return ShowConfigDialog(playerid);
        if(strlen(inputtext) > MAX_GROUP_ACCESS_PASSWORD_LENGTH)
	    {
	        SendErrorMessage(playerid, "The password you entered is quite long. Try again with a shorter one!", MSGBOX_TYPE_BOTTOM);
	        return ShowConfigDialog(playerid);
	    }
		format(GroupAccessPassword[3], MAX_GROUP_ACCESS_PASSWORD_LENGTH, "%s", inputtext);
	    new str[128];
		format(str, sizeof(str), "%s "COL_PRIM"has changed the alpha sub group access", Player[playerid][Name]);
		SendClientMessageToAll(-1, str);
	    return ShowConfigDialog(playerid);
	}

	if(dialogid == DIALOG_CONFIG_SET_GA_BSUB)
	{
	    if(!response) return ShowConfigDialog(playerid);
        if(strlen(inputtext) > MAX_GROUP_ACCESS_PASSWORD_LENGTH)
	    {
	        SendErrorMessage(playerid, "The password you entered is quite long. Try again with a shorter one!", MSGBOX_TYPE_BOTTOM);
	        return ShowConfigDialog(playerid);
	    }
		format(GroupAccessPassword[4], MAX_GROUP_ACCESS_PASSWORD_LENGTH, "%s", inputtext);
	    new str[128];
		format(str, sizeof(str), "%s "COL_PRIM"has changed the beta sub group access", Player[playerid][Name]);
		SendClientMessageToAll(-1, str);
	    return ShowConfigDialog(playerid);
	}

	if(dialogid == DIALOG_GROUPACCESS)
	{
	    if(!response)
		{
		    if(!Player[playerid][Spawned])
		    {
		        ShowIntroTextDraws(playerid);
				ShowPlayerClassSelection(playerid);
			}
 			return 1;
		}
	    new groupID = Player[playerid][RequestedClass];

	    if(strcmp(inputtext,GroupAccessPassword[groupID])!=0 || strlen(inputtext) == 0)
		{
			return ShowPlayerDialog(playerid, DIALOG_GROUPACCESS, DIALOG_STYLE_INPUT, "Authorization required", "Wrong password.\n\nPlease enter the group password:", "Submit", "Cancel");
  		}
  		if(Player[playerid][Spawned])
  		{
  		    switch(Player[playerid][RequestedClass])
			{
	            case 0:
				{
      				SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
            		Player[playerid][Team] = ATTACKER;
				}
				case 1:
				{
				    SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
				    Player[playerid][Team] = DEFENDER;
				}
				case 2:
				{
				    SetPlayerColor(playerid, REFEREE_COLOR);
				    Player[playerid][Team] = REFEREE;
				}
				case 3:
				{
				    SetPlayerColor(playerid, ATTACKER_SUB_COLOR);
				    Player[playerid][Team] = ATTACKER_SUB;
				}

				case 4:
				{
				    SetPlayerColor(playerid, DEFENDER_SUB_COLOR);
				    Player[playerid][Team] = DEFENDER_SUB;
				}
			}
			SwitchTeamFix(playerid);
  		}
  		else
  		{
  			RequestedGroupPass[playerid][groupID] = "";
	  		SpawnConnectedPlayer(playerid, groupID + 1);
		}
		return 1;
	}

	if(dialogid == DIALOG_CONFIG_SET_TEAM_SKIN) {
	    if(response)
		{
			switch(listitem)
			{
				case 0: { CallLocalFunction("OnPlayerCommandText", "ds", playerid, "/teamskin 0"); }
		        case 1: { CallLocalFunction("OnPlayerCommandText", "ds", playerid, "/teamskin 1"); }
				case 2: { CallLocalFunction("OnPlayerCommandText", "ds", playerid, "/teamskin 2"); }
			}
		}
		else
		{
            ShowConfigDialog(playerid);
		}
		return 1;
	}

	if(dialogid == DIALOG_CONFIG_SET_AAD) {
	    if(response)
		{
		    switch(listitem) {
		        case 0: { // set round health
		            ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ROUND_HEALTH, DIALOG_STYLE_INPUT, ""COL_PRIM"Round Health", ""COL_PRIM"Set round health:", "OK", "");
		        }
		        case 1: { // set round armour
		            ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ROUND_ARMOUR, DIALOG_STYLE_INPUT, ""COL_PRIM"Round Armour", ""COL_PRIM"Set round armour:", "OK", "");
		        }
		        case 2: { // Round time
					ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ROUND_TIME, DIALOG_STYLE_INPUT, ""COL_PRIM"Round Time", ""COL_PRIM"Set round time:", "OK", "Cancel");
		        }
		        case 3: { // CP time
		            ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_CP_TIME, DIALOG_STYLE_INPUT, ""COL_PRIM"CP Time", ""COL_PRIM"Set CP time:", "OK", "Cancel");
		        }
			}
		} else {
            ShowConfigDialog(playerid);
	    }
	    return 1;
	}

	if(dialogid == DIALOG_CONFIG_SET_ROUND_HEALTH) {
        new hp = strval(inputtext);
		if(hp <= 0 || hp > 100) {
			SendErrorMessage(playerid,"Health value can be between 0 and 100 maximum.");
			ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ROUND_HEALTH, DIALOG_STYLE_INPUT, ""COL_PRIM"Round Health", ""COL_PRIM"Set round health:", "OK", "");
			return 1;
		}

		RoundHP = hp;

		new str[128];
		format(str, sizeof(str), "%s "COL_PRIM"has changed the round health to: {FFFFFF}%d", Player[playerid][Name], RoundHP);
		SendClientMessageToAll(-1, str);

		format(str, sizeof(str), "UPDATE `Configs` SET `Value` = '%d,%d' WHERE `Option` = 'RoundHPAR'", RoundHP, RoundAR);
		db_free_result(db_query(sqliteconnection, str));

		ShowConfigDialog(playerid);
		return 1;

	}

	if(dialogid == DIALOG_CONFIG_SET_ROUND_ARMOUR) {
        new hp = strval(inputtext);
		if(hp <= 0 || hp > 100) {
			SendErrorMessage(playerid,"Armour value can be between 0 and 100 maximum.");
			ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ROUND_ARMOUR, DIALOG_STYLE_INPUT, ""COL_PRIM"Round Armour", ""COL_PRIM"Set round armour:", "OK", "");
			return 1;
		}

		RoundAR = hp;

		new str[128];
		format(str, sizeof(str), "%s "COL_PRIM"has changed the round armour to: {FFFFFF}%d", Player[playerid][Name], RoundAR);
		SendClientMessageToAll(-1, str);

		format(str, sizeof(str), "UPDATE `Configs` SET `Value` = '%d,%d' WHERE `Option` = 'RoundHPAR'", RoundHP, RoundAR);
		db_free_result(db_query(sqliteconnection, str));

		ShowConfigDialog(playerid);
		return 1;
	}

	if(dialogid == DIALOG_CONFIG_SET_ROUND_TIME) {
		if(response) {
			CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/roundtime %s", inputtext));
			ShowConfigDialog(playerid);
		} else {
            ShowConfigDialog(playerid);
		}
		return 1;
	}

	if(dialogid == DIALOG_CONFIG_SET_CP_TIME) {
	    if(response) {
	        CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/cptime %s", inputtext));
			ShowConfigDialog(playerid);
		} else {
            ShowConfigDialog(playerid);
		}
		return 1;
	}

	if(dialogid == DIALOG_CONFIG_SET_MAX_PING) {
	    if(response) {
	        CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/maxping %s", inputtext));
            ShowConfigDialog(playerid);
		} else {
            ShowConfigDialog(playerid);
		}
		return 1;
	}

	if(dialogid == DIALOG_CONFIG_SET_MAX_PACKET) {
	    if(response) {
	    	CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/maxpacket %s", inputtext));
            ShowConfigDialog(playerid);
		} else {
            ShowConfigDialog(playerid);
		}
		return 1;
	}

	if(dialogid == DIALOG_CONFIG_SET_MIN_FPS)
	{
	    if(response)
		{
		    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/minfps %s", inputtext));
			ShowConfigDialog(playerid);
		}
		else
		{
			ShowConfigDialog(playerid);
		}
		return 1;
	}

	if(dialogid == DIALOG_SWITCH_TEAM)
	{
	    if(response)
		{
		    new groupID = listitem;
		    if(strlen(GroupAccessPassword[groupID]) > 0 && (strcmp(RequestedGroupPass[playerid][groupID], GroupAccessPassword[groupID]) != 0 || isnull(RequestedGroupPass[playerid][groupID])))
			{
			    Player[playerid][RequestedClass] = listitem;
				ShowPlayerDialog(playerid, DIALOG_GROUPACCESS, DIALOG_STYLE_INPUT, "Authorization required", "Please enter the group password:", "Submit", "Cancel");
                return 1;
			}
	        switch(listitem)
			{
	            case 0:
				{
      				SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
            		Player[playerid][Team] = ATTACKER;
				}
				case 1:
				{
				    SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
				    Player[playerid][Team] = DEFENDER;
				}
				case 2:
				{
				    SetPlayerColor(playerid, REFEREE_COLOR);
				    Player[playerid][Team] = REFEREE;
				}
				case 3:
				{
				    SetPlayerColor(playerid, ATTACKER_SUB_COLOR);
				    Player[playerid][Team] = ATTACKER_SUB;
				}

				case 4:
				{
				    SetPlayerColor(playerid, DEFENDER_SUB_COLOR);
				    Player[playerid][Team] = DEFENDER_SUB;
				}
			}
			SwitchTeamFix(playerid);
		}
		return 1;
	}
    if(dialogid == DIALOG_TEAM_SELECTION)
	{
		if(response)
		{
		    if(listitem > 0) // Not auto-assign
		    {
			    new groupID = listitem - 1;
			    if(strlen(GroupAccessPassword[groupID]) > 0 && (strcmp(RequestedGroupPass[playerid][groupID], GroupAccessPassword[groupID]) != 0 || isnull(RequestedGroupPass[playerid][groupID])))
				{
				    Player[playerid][RequestedClass] = listitem;
					ShowPlayerDialog(playerid, DIALOG_GROUPACCESS, DIALOG_STYLE_INPUT, "Authorization required", "Please enter the group password:", "Submit", "Cancel");
	                return 1;
				}
			}
			SpawnConnectedPlayer(playerid, listitem);
		}
		else
		{
		    ShowIntroTextDraws(playerid);
		    ShowPlayerClassSelection(playerid);
		}
		return 1;
	}
	#if defined _league_included
	// League login dialog lock - so that players can't escape the league clan login check
	if(Player[playerid][MustLeaguePass] == true)
	{
	    ShowPlayerLeagueLoginDialog(playerid);
		return 1;
	}
	#endif
	return 0;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
	return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(clickedid == Text:INVALID_TEXT_DRAW)
	{
		if(PlayerOnInterface{playerid} == true)
		{
		    DisableMatchInterface(playerid);
		    return 1;
		}
		return 1;
	}
	if(clickedid == LeagueToggleTD)
	{
	    if(LeagueAllowed)
	    {
	        if(!WarMode)
	        	SendUsageMessage(playerid, "League is enabled on this server. All you need to do now is start a match (quicker: /war)!");
			else
			    SendUsageMessage(playerid, "League is enabled and so is match mode. Start a round with /start or /random!");
	    }
	    else
    		SendErrorMessage(playerid, "League is disabled. You can enable it from server config dialog (/config).");
		return 1;
	}

	if(clickedid == WarModeText) {
	    if(Current != -1) return SendErrorMessage(playerid,"Can't use this option while round is on.");

		if(WarMode == false) {

			MatchRoundsStarted = 0;
			for( new i = 0; i < 101; i++ )
			{
			    MatchRoundsRecord[ i ][ round__ID ] = -1;
			    MatchRoundsRecord[ i ][ round__type ] = -1;
			    MatchRoundsRecord[ i ][ round__completed ] = false;
			}

			foreach(new i : Player) {
   				Player[i][TotalKills] = 0;
				Player[i][TotalDeaths] = 0;
				Player[i][TotalDamage] = 0;
				Player[i][RoundPlayed] = 0;
			    Player[i][TotalBulletsFired] = 0;
			    Player[i][TotalshotsHit] = 0;
			}
	    	ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:","Next","Close");
		} else {
	    	ShowPlayerDialog(playerid, DIALOG_WAR_RESET, DIALOG_STYLE_MSGBOX,""COL_PRIM"War Dialog",""COL_PRIM"Are you sure you want to turn War Mode off?","Yes","No");
		}

		return 1;
	}

	if(clickedid == LockServerTD) {
		if(ServerLocked == false) {
		   ShowPlayerDialog(playerid, DIALOG_SERVER_PASS, DIALOG_STYLE_INPUT,""COL_PRIM"Server Password",""COL_PRIM"Enter server password below:", "Ok","Close");
		} else {
			SendRconCommand("password 0");

			new iString[64];
			format(iString, sizeof iString, "%sServer: ~r~Unlocked", MAIN_TEXT_COLOUR);
			TextDrawSetString(LockServerTD, iString);

			ServerLocked = false;
			PermLocked = false;

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unlocked the server.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		}
		return 1;
	}

	if(clickedid == CloseText)
	{
        DisableMatchInterface(playerid);
        return 1;
	}
	return 0;
}

//------------------------------------------------------------------------------
// Commands
//------------------------------------------------------------------------------

/*
    List of enum:
	// The majority of these are even - odd numbers return "1" not "0".
	COMMAND_ZERO_RET      = 0 , // The command returned 0.
	COMMAND_OK            = 1 , // Called corectly.
	COMMAND_UNDEFINED     = 2 , // Command doesn't exist.
	COMMAND_DENIED        = 3 , // Can't use the command.
	COMMAND_HIDDEN        = 4 , // Can't use the command don't let them know it exists.
	COMMAND_NO_PLAYER     = 6 , // Used by a player who shouldn't exist.
	COMMAND_DISABLED      = 7 , // All commands are disabled for this player.
	COMMAND_BAD_PREFIX    = 8 , // Used "/" instead of "#", or something similar.
	COMMAND_INVALID_INPUT = 10, // Didn't type "/something".
*/

public e_COMMAND_ERRORS:OnPlayerCommandReceived(playerid, cmdtext[], e_COMMAND_ERRORS:success)
{
    switch(success)
    {
        case COMMAND_UNDEFINED:
        {
            //MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~y~~h~Unknown Command", sprintf("~r~~h~%s ~w~is an unknown command. Check /cmds, /acmds or /cmdhelp for more info!", cmdtext), 3000);
			SendErrorMessage(playerid, sprintf("Unknown command: %s. Check /cmds, /acmds or /cmdhelp for more info!", cmdtext));
			return COMMAND_DENIED;
		}
		case COMMAND_DENIED:
		{
			SendErrorMessage(playerid, "Your level is not high enough to use this command!");
			return COMMAND_DENIED;
		}
    }
    // Skip spam check on shortcut commands
    if(strfind(cmdtext, "/rb", true) != -1 || strfind(cmdtext, "/ra", true) != -1 || strfind(cmdtext, "/cmdhelp", true) != -1)
	    goto skipSpamCheck;
	if(AntiSpam == true && GetTickCount() < Player[playerid][lastChat])
	{
		SendErrorMessage(playerid,"Please wait.");
		return COMMAND_DENIED;
	}
	Player[playerid][lastChat] = GetTickCount() + 1000;
	skipSpamCheck:

	// A round is starting...
   	if(AllowStartBase == false)
		return COMMAND_DENIED;

	// AFK players are not supposed to use any command
	if(Player[playerid][IsAFK] == true)
	{
	 	if(strfind(cmdtext, "/back", true) == 0)
 			return COMMAND_OK;
	 	else
		{
			SendErrorMessage(playerid,"Can't use any command during AFK mode. Type /back");
			return COMMAND_DENIED;
		}
	}
	// Normal players should not use any command while in duel
	if(Player[playerid][InDuel] == true)
	{
	 	if(strcmp(cmdtext, "/rq", true) == 0)
			return COMMAND_OK;
	 	else if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid))
	 	{
	 		SendErrorMessage(playerid, "Can't use any command in duel. Type /rq to quit duel.");
			return COMMAND_DENIED;
		}
	}
    // Players need to spawn first in order to use commands
	if(Player[playerid][Team] == NON)
	{
	    SendErrorMessage(playerid,"You need to spawn to be able to use commands.");
		return COMMAND_DENIED;
	}
	return COMMAND_OK;
}

public e_COMMAND_ERRORS:OnPlayerCommandPerformed(playerid, cmdtext[], e_COMMAND_ERRORS:success)
{
    return COMMAND_OK;
}

YCMD:cmdhelp(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display help about commands");
	    return 1;
	}
    if(isnull(params)) return SendUsageMessage(playerid, "/cmdhelp [Command name]");
    Command_ReProcess(playerid, params, true);
    return 1;
}

YCMD:checkversion(playerid, params[])
{
	if(!VersionCheckerStatus)
	    return SendErrorMessage(playerid, "Connection error. Try again later maybe!");

    ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Version Checker",
	 sprintf(""COL_PRIM"Server version: {FFFFFF}%.2f "COL_PRIM"| Newest version: {FFFFFF}%.2f", GM_VERSION, LatestVersion), "Okay", "");
	return 1;
}

forward ShowPlayerChangelog(index, response_code, data[]);
public ShowPlayerChangelog(index, response_code, data[])
{
	if(response_code == 200)
	{
		SendClientMessage(index, -1, sprintf(""COL_PRIM"See more at {FFFFFF}%s", GM_WEBSITE));
		ShowPlayerDialog(index, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, "Gamemode changelog", data, "Close", "");
	}
	else
	{
		SendErrorMessage(index, sprintf("Connection error. Response code: %d", response_code));
	}
	return 1;
}

YCMD:changelog(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display a list of gamemode updates");
	    return 1;
	}
	HTTP(playerid, HTTP_GET, "infinite-gaming.ml/khk/bulletproof/api/changelog.php", "", "ShowPlayerChangelog");
	return 1;
}

YCMD:help(playerid, params[], help)
{
	if(help)
	{
	    SendCommandHelpMessage(playerid, "display some guidelines");
	    return 1;
	}
	new str[583];
	strcat(str, ""COL_PRIM"Main developers: {FFFFFF}Whitetiger & [KHK]Khalid");
	strcat(str, "\n"COL_PRIM"Contributors on GitHub: {FFFFFF}ApplePieLife, JamesCullum, shendlaw, pds2k12");
	strcat(str, "\n"COL_PRIM"Project on GitHub: {FFFFFF}https://github.com/KHKKhalid/SAMPBulletproof/");
	strcat(str, "\n\n\n{FFFFFF}To see server settings: {888888}/settings");
	strcat(str, "\n{FFFFFF}For admin commands: {888888}/acmds");
	strcat(str, "\n{FFFFFF}For public commands: {888888}/cmds");
	strcat(str, "\n{FFFFFF}If you need help with a specific command: {888888}/cmdhelp");
	strcat(str, "\n{FFFFFF}Match help: {888888}/matchtips");
	strcat(str, "\n{FFFFFF}To stay updated always: {888888}/updates and /checkversion");
	strcat(str, "\n{FFFFFF}League help: {888888}/leaguecmds");
	ShowPlayerDialog(playerid,DIALOG_NO_RESPONSE,DIALOG_STYLE_MSGBOX,sprintf("%s gamemode "COL_PRIM"help+tips", GM_NAME),str,"OK","");
	return 1;
}

YCMD:matchtips(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display some guidelines about match mode");
	    return 1;
	}
	new str[1561];
	strcat(str, "\n"COL_PRIM"# {FFFFFF}To enable Match-Mode, press 'Y' in lobby or 'H' (shortcut to /match) in round and most textdraws will be clickable.");
	strcat(str, "\nOr use /war if you're in a hurry! Moreover, you can click on match textdraws to set team names, score and etc.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}Useful match cmds: /teamname, /teamskin, /tr, /cr, /resetscores, /setscore, /roundtime, /cptime, /allvs, /rr");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}To re-select your weapons in a round, type /gunmenu.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}Type /melee to get melee weapons menu while in a round.");
    strcat(str, "\n"COL_PRIM"# {FFFFFF}Want to differentiate your team-mates on radar? Use /playermarkers");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}Use /weaponbinds to code your own weapon key binds.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}To change your fight style, you can use the /fightstyle command.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}You can remove a gun by holding it and typing /remgun.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}Round can be paused by pressing 'Y' (for admins only).");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}You can request for backup from your team by pressing 'N' in round.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}You can ask for pausing the round by pressing 'Y' in round.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}To lead your team press 'H'.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}If you're lagging, you can request netcheck with /netcheckme.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}To diss whom you kill, use /deathdiss command.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}You can change your gunmenu style with /gunmenustyle.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}Type /shop to start shopping and make use of your league points.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}Type /sound to change the sound when you hit someone or get hit.");
	strcat(str, "\n"COL_PRIM"# {FFFFFF}Getting distracted by some textdraws? Try /hud");
	ShowPlayerDialog(playerid,DIALOG_NO_RESPONSE,DIALOG_STYLE_MSGBOX,""COL_PRIM"Match help & tips",str,"OK","");
	return 1;
}

YCMD:cmds(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display server commands");
	    return 1;
	}
	new str[1500], cmdsInLine = 0;
	strcat(str,
		"Use ! for team chat\nPress N to request for backup in a round\nPress H to lead your team\nUse # for league clan chat\nUse @ for admin chat\nIf you need help with a command, use /cmdhelp\n\n");
	foreach(new i : Command())
	{
		if(GetCommandLevel(i) == 0)
		{
			if(cmdsInLine == 6)
   			{
   			    cmdsInLine = 0;
   			    format(str, sizeof str, "%s\n/%s, ", str, Command_GetName(i));
   			}
   			else
   			{
				format(str, sizeof str, "%s/%s, ", str, Command_GetName(i));
			}
			cmdsInLine ++;
		}
	}
	ShowPlayerDialog(playerid,DIALOG_NO_RESPONSE,DIALOG_STYLE_MSGBOX,""COL_PRIM"Player Commands", str, "OK","");
	return 1;
}

YCMD:acmds(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display admin commands");
	    return 1;
	}
	new str[1500], cmdsInLine;
	strcat(str, "Use @ for admin chat\nIf you need help with a command, use /cmdhelp");
	new level = Player[playerid][Level];
	for(new i = 0; i < MAX_ADMIN_LEVELS; i ++)
	{
	    if(level > i)
	    {
	        format(str, sizeof str, "%s\n\nLevel %d:\n", str, i + 1);
	        cmdsInLine = 0;
			foreach(new j : Command())
			{
				if(GetCommandLevel(j) == i + 1)
				{
					if(cmdsInLine == 6)
		   			{
		   			    cmdsInLine = 0;
		   			    format(str, sizeof str, "%s\n/%s, ", str, Command_GetName(j));
		   			}
		   			else
		   			{
						format(str, sizeof str, "%s/%s, ", str, Command_GetName(j));
					}
					cmdsInLine ++;
				}
   			}
	    }
	}
	ShowPlayerDialog(playerid,DIALOG_NO_RESPONSE,DIALOG_STYLE_MSGBOX,""COL_PRIM"Admin Commands", str, "OK","");
	return 1;
}

YCMD:setcmdlevel(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set the level of a command");
	    return 1;
	}
    if(isnull(params)) return SendUsageMessage(playerid,"/setcmdlevel [Command name without /] [New level]");

    new cmd[MAX_COMMAND_NAME], level;
 	if(sscanf(params, "sd", cmd, level)) return SendUsageMessage(playerid,"/setcmdlevel [Command name without /] [New level]");
 	if(level >= MAX_ADMIN_LEVELS || level < 0) return SendErrorMessage(playerid,"Invalid level!");
	if(SetCommandLevel(cmd, level, true) != 1) return SendErrorMessage(playerid,"Invalid command!");
	SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has permitted command {FFFFFF}/%s "COL_PRIM"for only level {FFFFFF}%d"COL_PRIM" and higher.", Player[playerid][Name], cmd, level));
	return 1;
}

YCMD:clearadmcmd(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "clear the admin command log file that is in scriptfiles folder");
	    return 1;
	}
    ClearAdminCommandLog();
    SendClientMessage(playerid, -1, "Admin command log has been successfully cleared!");
	return 1;
}

YCMD:clearallaka(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "clear all players aka logs from database");
	    return 1;
	}
   	db_free_result(db_query(sqliteconnection, "DELETE FROM `AKAs`"));
    SendClientMessage(playerid, -1, "AKA logs have been successfully cleared!");
    return 1;
}

YCMD:style(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "an option to switch the style of round textdraws on your screen");
	    return 1;
	}
	HideRoundStats(playerid);
	switch(Player[playerid][RoundTDStyle])
	{
	    case 0:
		{
		    db_free_result(db_query(sqliteconnection, sprintf("UPDATE `Players` SET `RoundTDStyle`=1 WHERE `Name`='%q'", Player[playerid][Name])));
		    Player[playerid][RoundTDStyle] = 1;
		    SendClientMessage(playerid, -1, "Round textdraws style changed to new Bulletproof design.");
		}
		case 1:
		{
			db_free_result(db_query(sqliteconnection, sprintf("UPDATE `Players` SET `RoundTDStyle`=0 WHERE `Name`='%q'", Player[playerid][Name])));
		    Player[playerid][RoundTDStyle] = 0;
		    SendClientMessage(playerid, -1, "Round textdraws style changed to old-school design.");
		}
	}
	if(Current != -1)
	    ShowRoundStats(playerid);
	return 1;
}

YCMD:playermarkers(playerid, params[], help)
{
	if(help)
	{
	    SendCommandHelpMessage(playerid, "an option to switch the color of the player markers on your radar");
	    return 1;
	}
    Player[playerid][PlayerMarkers] = !Player[playerid][PlayerMarkers];
    foreach(new i : Player)
    {
        OnPlayerStreamIn(i, playerid);
    }
	switch(Player[playerid][PlayerMarkers])
	{
	    case false:
	    {
	        SendClientMessage(playerid, -1, "Changed player markers setting: you will now see marker color based on team color.");
	    }
	    case true:
	    {
	        SendClientMessage(playerid, -1, "Changed player markers setting: each player has a unique marker color on radar now.");
	    }
	}
	db_free_result(db_query(sqliteconnection, sprintf("UPDATE `Players` SET `PlayerMarkers` = '%d' WHERE `Name` = '%q'", (Player[playerid][PlayerMarkers] == true) ? (1) : (0), Player[playerid][Name])));
	return 1;
}

YCMD:voteadd(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a voting (add player to round)");
	    return 1;
	}
	new pID;
	if(sscanf(params, "i", pID))
	    return SendUsageMessage(playerid,"/voteadd [Player ID]");

	PlayerVoteAdd(playerid, pID);
	return 1;
}

YCMD:votereadd(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a voting (re-add player to round)");
	    return 1;
	}
	new pID;
	if(sscanf(params, "i", pID))
	    return SendUsageMessage(playerid,"/votereadd [Player ID]");

	PlayerVoteReadd(playerid, pID);
	return 1;
}

YCMD:voterem(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a voting (remove a player from round)");
	    return 1;
	}
	new pID;
	if(sscanf(params, "i", pID))
	    return SendUsageMessage(playerid,"/voterem [Player ID]");

	PlayerVoteRem(playerid, pID);
	return 1;
}

YCMD:votekick(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a voting (kick a player from the server)");
	    return 1;
	}
	new pID;
	if(sscanf(params, "i", pID))
	    return SendUsageMessage(playerid,"/votekick [Player ID]");

	PlayerVoteKick(playerid, pID);
	return 1;
}

YCMD:votenetcheck(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a voting (toggle netcheck on a player)");
	    return 1;
	}
	new pID;
	if(sscanf(params, "i", pID))
	    return SendUsageMessage(playerid,"/votenetcheck [Player ID]");

	PlayerVoteNetCheck(playerid, pID);
	return 1;
}

YCMD:votepause(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a voting (pause round)");
	    return 1;
	}
	PlayerVotePause(playerid);
	return 1;
}

YCMD:voteunpause(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a voting (pause round)");
	    return 1;
	}
	PlayerVoteUnpause(playerid);
	return 1;
}

YCMD:voteendmatch(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a voting (end match)");
	    return 1;
	}
	PlayerVoteEndMatch(playerid);
	return 1;
}

YCMD:voterr(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a voting (restart round)");
	    return 1;
	}
	PlayerVoteRestartRound(playerid);
	return 1;
}

YCMD:voteswitch(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a voting (switch player to team with less players)");
	    return 1;
	}
	new pID;
	if(sscanf(params, "i", pID))
	    return SendUsageMessage(playerid,"/v [Player ID]");

	PlayerVoteSwitch(playerid, pID);
	return 1;
}

YCMD:votemenu(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a voting (give menu to player)");
	    return 1;
	}
	new pID;
	if(sscanf(params, "i", pID))
	    return SendUsageMessage(playerid,"/votemenu [Player ID]");

	PlayerVoteMenu(playerid, pID);
	return 1;
}

YCMD:xmas(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle christmas mode (if filterscript is available)");
	    return 1;
	}
	if(isnull(params))
	{
	    return SendUsageMessage(playerid, "/xmas [on / off]");
	}
	if(!strcmp(params, "on", true))
	{
	    SendRconCommand("loadfs xmas");
	    SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has attempted to load Xmas filterscript!", Player[playerid][Name]));
	}
	else if(!strcmp(params, "off", true))
	{
	    SendRconCommand("unloadfs xmas");
	    SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has attempted to unload Xmas filterscript!", Player[playerid][Name]));
	}
	else
	    return SendUsageMessage(playerid, "/xmas [on / off]");
	return 1;
}

YCMD:weaponbinds(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "code your weapon bind keys");
	    return 1;
	}
    ShowPlayerWeaponBindDialog(playerid);
	return 1;
}


YCMD:hud(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle aspects of HUD");
	    return 1;
	}
    new toggleStr[4], hudid;
	if(sscanf(params, "is", hudid, toggleStr))
	{
	    SendUsageMessage(playerid,"/hud [HUD ID] [on / off]");
		return SendClientMessage(playerid, -1, ""COL_PRIM"Note: {FFFFFF}HUD IDs are (-1 = ALL) (0 = spectators) (1 = net stats) (2 = hp percent)");
	}

	if(hudid < -1 || hudid == MAX_PLAYER_INTERFACE_ASPECTS)
	    return SendErrorMessage(playerid, "Invalid HUD ID");

    new bool:toggle;
	if(strcmp(toggleStr, "on", true) == 0)
		toggle = true;
	else if(strcmp(toggleStr, "off", true) == 0)
		toggle = false;
	else
	{
	    SendUsageMessage(playerid,"/hud [HUD ID] [on / off]");
		return SendClientMessage(playerid, -1, ""COL_PRIM"Note: {FFFFFF}HUD IDs are (-1 = ALL) (0 = spectators) (1 = net stats) (2 = hp percent)");
	}

	TogglePlayerInterface(playerid, toggle, hudid);
	return 1;
}

YCMD:deleteacc(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "delete an account from the database");
	    return 1;
	}
	//if(Player[playerid][Level] < 5) return SendErrorMessage(playerid,"You must be level 5 to use this command.");
	if(isnull(params)) return SendUsageMessage(playerid,"/deleteacc [Account Name]");

    new str[MAX_PLAYER_NAME];
 	if(sscanf(params, "s", str)) return SendUsageMessage(playerid,"/deleteacc [Account Name]");

    if(strlen(str) > MAX_PLAYER_NAME) return SendErrorMessage(playerid,"Maximum name length: 24 characters.");

    db_free_result(db_query(sqliteconnection, sprintf("DELETE FROM Players WHERE Name = '%q'", str)));
    SendClientMessage(playerid, -1, "Query executed.");
	return 1;
}

YCMD:setacclevel(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change the level of an account in the database");
	    return 1;
	}
	//if(Player[playerid][Level] < 5) return SendErrorMessage(playerid,"You must be level 5 to use this command.");
	if(isnull(params)) return SendUsageMessage(playerid,"/setacclevel [Account Name] [Level]");

    new str[MAX_PLAYER_NAME], lev;
	if(sscanf(params, "sd", str, lev)) return SendUsageMessage(playerid,"/setacclevel [Account Name] [Level]");

    if(lev < 0 || lev > 5) return SendErrorMessage(playerid,"Invalid level.");
    if(strlen(str) > MAX_PLAYER_NAME) return SendErrorMessage(playerid,"Maximum name length: 24 characters.");

    new iString[128];

	format(iString, sizeof(iString), "UPDATE Players SET Level = %d WHERE Name = '%q'", lev, str);
    db_free_result(db_query(sqliteconnection, iString));

    SendClientMessage(playerid, -1, "Query executed.");
	return 1;
}

YCMD:settings(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display server settings");
	    return 1;
	}
	new string[144];

	SendClientMessage(playerid, -1, ""COL_PRIM"Server settings:");
	format(string, sizeof(string), "{FFFFFF}CP Time = "COL_PRIM"%d {FFFFFF}seconds | Round Time = "COL_PRIM"%d {FFFFFF}minutes", ConfigCPTime, ConfigRoundTime);
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}Attacker Skin = "COL_PRIM"%d {FFFFFF}| Defender Skin = "COL_PRIM"%d {FFFFFF}| Referee Skin = "COL_PRIM"%d", Skin[ATTACKER], Skin[DEFENDER], Skin[REFEREE]);
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}Min FPS = "COL_PRIM"%d {FFFFFF}| Max Ping = "COL_PRIM"%d {FFFFFF}| Max Packetloss = "COL_PRIM"%.2f", Min_FPS, Max_Ping, Float:Max_Packetloss);
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}Auto-Balance = %s {FFFFFF}| Anti-Spam = %s", (AutoBal == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")), (AntiSpam == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")));
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}Auto-Pause = %s {FFFFFF}| Guns in Lobby = %s", (AutoPause == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")), (LobbyGuns == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")));
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}League shop = %s {FFFFFF}| League mode = %s", (LeagueShop == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")), (LeagueAllowed == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")));
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}Antimacros = %s {FFFFFF}| Death camera = %s", (AntiMacros == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")), (DeathCamera == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")));
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}Melee weapons menu = %s {FFFFFF}| Dead bodies = %s", (MeleeAllowed == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")), (DeadBodies == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")));
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}CP in arenas = %s {FFFFFF}", (CPInArena == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")));
	SendClientMessage(playerid, -1, string);
	return 1;
}

YCMD:shop(playerid, params[], help)
{
	if(help)
	{
	    SendCommandHelpMessage(playerid, "enter the league shop");
	    return 1;
	}
	#if defined _league_included
	if(LeagueShop)
	    if(LeagueAllowed)
			ShowPlayerShopDialog(playerid);
		else
		    SendErrorMessage(playerid, "League mode is not enabled in this server");
	else
	    SendErrorMessage(playerid, "League shop is disabled in this server");
	#else
	SendErrorMessage(playerid, "This version/edit of Bulletproof gamemode does not support league features!");
	#endif
	return 1;
}

YCMD:usebelt(playerid, params[], help)
{
	if(help)
	{
	    SendCommandHelpMessage(playerid, "bomb yourself");
	    return 1;
	}
	#if defined _league_included
	if(LeagueMode)
	{
	    if(!PlayerShop[playerid][SHOP_EXPLOSIVE_BELT])
	    {
	        return SendErrorMessage(playerid, "You have not purchased an explosive belt from league shop (/shop).");
	    }
	    if(!Player[playerid][Playing])
	    {
	        return SendErrorMessage(playerid, "You need to be playing (in round) to use the explosive belt");
	    }
	    PlayerShop[playerid][SHOP_EXPLOSIVE_BELT] = false;
	    new Float:X, Float:Y, Float:Z;
	    GetPlayerPos(playerid, X, Y, Z);
	    new
			dist,
			Float:damage,
			randomAdd = randomExInt(10, 15);
	    foreach(new i : Player)
	    {
			if(!Player[i][Playing] && !Player[i][Spectating])
			    continue;

			CreateExplosionForPlayer(i, X, Y, Z, 7, 14.0);
			if(i != playerid)
			{
				dist = floatround(GetPlayerDistanceFromPoint(i, X, Y, Z));
				if(dist <= 14)
				{
					damage = float((99 / dist) + randomAdd);
					OnPlayerTakeDamage(i, playerid, damage, 47, 3);
				}
			}
		}
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has bombed himself using an explosive belt (/shop)", Player[playerid][Name]));
	}
	else
	{
	    SendErrorMessage(playerid, "This is not a league match!");
	}
	#else
	SendErrorMessage(playerid, "This version/edit of Bulletproof gamemode does not support league features!");
	#endif
	return 1;
}

YCMD:remgun(playerid, params[], help)
{
	if(help)
	{
	    SendCommandHelpMessage(playerid, "remove the gun you currently holding from your inventory");
	    return 1;
	}
	if(GetPlayerWeapon(playerid) == 0)
	    return SendErrorMessage(playerid, "You wanna remove your hand? Visit a doctor, we don't do surgery here!");

	RemovePlayerWeapon(playerid, GetPlayerWeapon(playerid));
	SendClientMessage(playerid, -1, sprintf("Removed %s from your gun inventory!", WeaponNames[GetPlayerWeapon(playerid)]));
	return 1;
}

YCMD:getgun(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "give you a specific weapon");
	    return 1;
	}
	if(LobbyGuns == false) return SendErrorMessage(playerid,"Guns in lobby are disabled.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't use this command while playing.");
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use /rq instead.");
	if(Player[playerid][InDM] == true) return SendErrorMessage(playerid,"Can't use this command during DM.");

	new Weapon[50], Ammo, iString[128];

 	if(sscanf(params, "sd", Weapon, Ammo))  return SendUsageMessage(playerid,"/getgun [Weapon Name] [Ammo]");

	if(Ammo < 0 || Ammo > 9999) return SendErrorMessage(playerid,"Invalid Ammo.");

	new WeaponID = GetWeaponID(Weapon);
	if(WeaponID < 1 || WeaponID > 46 || WeaponID == 19 || WeaponID == 20 || WeaponID == 21 || WeaponID == 22) return SendErrorMessage(playerid,"Invalid Weapon Name.");
	if(WeaponID == 44 || WeaponID == 45) return SendErrorMessage(playerid,"We don't do this shit around here.");

	GivePlayerWeapon(playerid, WeaponID, Ammo);

    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has given himself {FFFFFF}%s "COL_PRIM"with {FFFFFF}%d "COL_PRIM"ammo.", Player[playerid][Name], WeaponNames[WeaponID], Ammo);
	SendClientMessageToAll(-1, iString);

	return 1;
}

YCMD:lobbyguns(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle guns in lobby");
	    return 1;
	}
	new iString[128];

	if(LobbyGuns == true) {
		LobbyGuns = false;
    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"guns in lobby.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);

	} else {
		LobbyGuns = true;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"guns in lobby.", Player[playerid][Name]);
        SendClientMessageToAll(-1, iString);
	}
	LogAdminCommand("lobbyguns", playerid, INVALID_PLAYER_ID);
	return 1;
}


YCMD:autopause(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle automatic pausing on player disconnection in war mode");
	    return 1;
	}
	new iString[144];

 	if(AutoPause == true) {
		AutoPause = false;
    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"Auto-Pause on player disconnect in war mode.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);

	} else {
		AutoPause = true;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"Auto-Pause on player disconnect in war mode.", Player[playerid][Name]);
        SendClientMessageToAll(-1, iString);
	}
    LogAdminCommand("autopause", playerid, INVALID_PLAYER_ID);
	return 1;
}


YCMD:ann(playerid, params[], help)
{
	//if(Player[playerid][Level] < 2) return SendErrorMessage(playerid,"You must be a higher level admin to use this command.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "display a specific announcement to all players");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/ann [Text]");

    new str[128];
	if(sscanf(params, "s", str)) return SendUsageMessage(playerid,"/ann [Text]");

    if(strlen(str) > 127) return SendErrorMessage(playerid,"Text is too long. Maximum 128 characters allowed.");
    if(strfind(str, "`") != -1) return SendErrorMessage(playerid,"` is not allowed.");
	if(!IsSafeGametext(str))
	{
	    SendErrorMessage(playerid, "You're probably missing a '~' which can crash you and/or other clients!");
        SendClientMessage(playerid, -1, "{FFFFFF}Note: "COL_PRIM"Always leave a space between a '~' and the character 'K'");
		return 1;
	}

	KillTimer(AnnTimer);

	TextDrawSetString(AnnTD, str);
	TextDrawShowForAll(AnnTD);
	AnnTimer = SetTimer("HideAnnForAll", 5000, false);

	format(str, sizeof(str), "{FFFFFF}%s "COL_PRIM"made an announcement.", Player[playerid][Name]);
	SendClientMessageToAll(-1, str);
    LogAdminCommand("ann", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:freecam(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "free your camera so you can move freely. (Useful in movie-making?)");
	    return 1;
	}
	if(Player[playerid][Playing] == true) return 1;
	if(Player[playerid][InDM] == true) return 1;
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel.");
	if(Player[playerid][Spectating] == true && !noclipdata[playerid][FlyMode]) return 1;
	if(GetPlayerVehicleID(playerid)) return SendErrorMessage(playerid, "You cannot use this command while in vehicle.");

	if(noclipdata[playerid][FlyMode] == true)
	{
		SendClientMessage(playerid, -1, "Use /specoff to exit FreeCam!");
	}
	else
	{
		PlayerFlyMode(playerid, false);
		SendClientMessage(playerid, -1, "Use /specoff to exit FreeCam!");
		PlayerTextDrawHide(playerid, RoundKillDmgTDmg[playerid]);
		PlayerTextDrawHide(playerid, FPSPingPacket[playerid]);
		PlayerTextDrawHide(playerid, BaseID_VS[playerid]);
		PlayerTextDrawHide(playerid, HPTextDraw_TD[playerid]);
		PlayerTextDrawHide(playerid, ArmourTextDraw[playerid]);
		HidePlayerProgressBar(playerid, HealthBar[playerid]);
		HidePlayerProgressBar(playerid, ArmourBar[playerid]);
	}
	return 1;
}

YCMD:antispam(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle the server anti-spam of commands and chat.");
	    return 1;
	}
	new iString[128];

 	if(AntiSpam == true) {
		AntiSpam = false;
    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"anti-spam.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);

	} else {
		AntiSpam = true;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"anti-spam.", Player[playerid][Name]);
        SendClientMessageToAll(-1, iString);
	}
    LogAdminCommand("antispam", playerid, INVALID_PLAYER_ID);
	return 1;
}


YCMD:autobalance(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle automatic team balancing when match mode is off.");
	    return 1;
	}
	new iString[128];

 	if(AutoBal == true) {
		AutoBal = false;
    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"auto-balance in non war mode.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);

	} else {
		AutoBal = true;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"auto-balance in non war mode.", Player[playerid][Name]);
        SendClientMessageToAll(-1, iString);
	}
    LogAdminCommand("autobalance", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:gmx(playerid, params[], help)
{
	//if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a level 5 admin to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "restart your server.");
	    return 1;
	}
	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s (%d) "COL_PRIM"has set the server to restart", Player[playerid][Name], playerid);
	SendClientMessageToAll(-1, iString);

    LogAdminCommand("gmx", playerid, INVALID_PLAYER_ID);

	SendRconCommand("gmx");
	return 1;
}

YCMD:asay(playerid, params[], help)
{
    //if(Player[playerid][Level] < 2 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a level 2 admin to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "send a public message as an administrator");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/asay [Text]");
	new iString[165];
	format(iString, sizeof(iString), "{6688FF}* Admin: %s", params);
	SendClientMessageToAll(-1, iString);

	printf("%s (%d) used /asay : %s", Player[playerid][Name], playerid, params);
    LogAdminCommand("asay", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:banip(playerid,params[], help)
{
	//if(Player[playerid][Level] < 4 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a level 4 admin to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "ban a specific IP (can be used for range-bans using *).");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/banip [IP or IP range to ban]");

	new str[128];
	format(str, sizeof(str), "banip %s", params);
	SendRconCommand(str);

	SendRconCommand("reloadbans");

	format(str, sizeof(str), "%s%s (%d) "COL_PRIM"has banned IP: {FFFFFF}%s", TextColor[Player[playerid][Team]], Player[playerid][Name], playerid, params);
	SendClientMessageToAll(-1, str);
    LogAdminCommand("banip", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:lobby(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "teleport you to the lobby.");
	    return 1;
	}

	if(Player[playerid][InDM] == true) QuitDM(playerid);
   	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use /rq instead.");
   	if(Player[playerid][Playing] == true)
        return SendErrorMessage(playerid, "Cannot go to lobby while you're playing. Use /rem maybe?");
        
    SpawnPlayer(playerid);
	return 1;
}

YCMD:duel(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "send a duel request to a specific player.");
	    return 1;
	}
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"You are already dueling someone.");
	
	new invitedid, Weapon1[23], Weapon2[23], duelarena[8], sizeStr[8];
 	if(sscanf(params, "isszz", invitedid, Weapon1, Weapon2, duelarena, sizeStr))
	{
		SendUsageMessage(playerid,"/duel [Player ID] [Weapon 1] [Weapon 2] [Optional: default/custom] [Optional: area size]");
        return SendClientMessage(playerid, -1, ""COL_PRIM"Note: {FFFFFF}[custom] to play in your current place and [default] for default duel arena");
	}
	if(!IsPlayerConnected(invitedid)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[invitedid][Playing] == true) return SendErrorMessage(playerid,"That player is in a round.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"You can't duel while being in a round.");
	if(Player[invitedid][InDuel] == true) return SendErrorMessage(playerid,"That player is already dueling someone.");
	if(Player[invitedid][challengerid] == playerid) return SendErrorMessage(playerid,"You have already invited that player for duel. Let him accept or deny your previous invite.");    //duelspamfix
	//if(invitedid == playerid) return SendErrorMessage(playerid,"Can't duel with yourself.");

    new WeaponID1 = GetWeaponID(Weapon1);
	if(WeaponID1 < 1 || WeaponID1 > 46 || WeaponID1 == 19 || WeaponID1 == 20 || WeaponID1 == 21) return SendErrorMessage(playerid,"Invalid Weapon Name.");
	if(WeaponID1 == 40 || WeaponID1 == 43 || WeaponID1 == 44 || WeaponID1 == 45) return SendErrorMessage(playerid,"That weapon is not allowed in duels.");

	new WeaponID2 = GetWeaponID(Weapon2);
	if(WeaponID2 < 1 || WeaponID2 > 46 || WeaponID2 == 19 || WeaponID2 == 20 || WeaponID2 == 21) return SendErrorMessage(playerid,"Invalid Weapon Name.");
	if(WeaponID2 == 40 || WeaponID2 == 43 || WeaponID2 == 44 || WeaponID2 == 45) return SendErrorMessage(playerid,"That weapon is not allowed in duels.");

	new duelarenaid;
	if(isnull(duelarena))
	{
	    duelarenaid = DEFAULT_DUEL_ARENA_ID;
	}
	else
	{
	    if(!strcmp(duelarena, "default", true))
		{
	        duelarenaid = DEFAULT_DUEL_ARENA_ID;
		}
		else if(!strcmp(duelarena, "custom", true))
		{
	        duelarenaid = 1 + DEFAULT_DUEL_ARENA_ID;
		}
		else
		{
		    duelarenaid = DEFAULT_DUEL_ARENA_ID;
		}
 	}
 	new size;
 	if(!isnull(sizeStr))
 	{
 	    size = strval(sizeStr);
 	}
    if(size < 50)
    	size = 90;
    	
	ProcessDuelRequest(playerid, invitedid, WeaponID1, WeaponID2, duelarenaid, size);
	return 1;
}

YCMD:yes(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "accept a duel request.");
	    return 1;
	}
	new pID = Player[playerid][challengerid];

	if(Player[playerid][challengerid] == -1) return SendErrorMessage(playerid,"No one has invited you to a duel.");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[pID][Playing] == true) return SendErrorMessage(playerid,"That player is in a round.");
	if(Player[pID][InDuel] == true) return SendErrorMessage(playerid,"That player is already dueling someone else.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"You can't duel while being in a round.");

    new iString[128];
	format(iString, sizeof(iString), "%s%s {FFFFFF}accepted the duel challenge by %s%s", TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[pID][Team]], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);

	StartDuel(pID, playerid, Player[playerid][duelweap1], Player[playerid][duelweap2], Player[playerid][Duel_X], Player[playerid][Duel_Y], Player[playerid][Duel_Size], Player[playerid][Duel_Interior]);
	return 1;
}


YCMD:no(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "deny a duel request.");
	    return 1;
	}
	if(Player[playerid][InDuel] == true)
		return SendErrorMessage(playerid,"You are in a duel anyway");

	new pID;
	pID = Player[playerid][challengerid];

	if(Player[playerid][challengerid] == -1) return SendErrorMessage(playerid,"No one has invited you to a duel.");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

    new iString[128];
	format(iString, sizeof(iString), "%s%s {FFFFFF}denied the duel challenge by %s%s", TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[pID][Team]], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);

	Player[playerid][challengerid] = -1;
	return 1;
}

YCMD:rq(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "get you out of a duel.");
	    return 1;
	}
	if(Player[playerid][InDuel] == false) {
		return SendErrorMessage(playerid,"You are not in a duel");

	}
	else
	{
	    PlayerDuelQuit(playerid);
	}
	return 1;
}

YCMD:limit(playerid, params[], help)
{
    //if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 5 or rcon admin.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set a limit for weather and time.");
	    return 1;
	}
	new Command[64], aLimit, CommandID, iString[128];
	if(sscanf(params, "sd", Command, aLimit)) return SendUsageMessage(playerid,"/limit [weather | time] [Limit]");

	if(strcmp(Command, "weather", true) == 0) CommandID = 1;
	else if(strcmp(Command, "time", true) == 0) CommandID = 2;
	else return SendUsageMessage(playerid,"/limit [weather | time] [Limit]");

    if(aLimit < 10 || aLimit > 9999) return SendErrorMessage(playerid,"Invalid limit.");

	switch(CommandID) {
	    case 1: { //Weather
			WeatherLimit = aLimit;

			foreach(new i : Player) {
			    if(Player[i][Weather] > WeatherLimit) {

					Player[i][Weather] = 0;
					SetPlayerWeather(i, Player[i][Weather]);

					format(iString, sizeof(iString), "UPDATE Players SET Weather = %d WHERE Name = '%q'", Player[i][Weather], Player[i][Name]);
				    db_free_result(db_query(sqliteconnection, iString));
				}
			}

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed weather limit to: {FFFFFF}%d", Player[playerid][Name], WeatherLimit);
			SendClientMessageToAll(-1, iString);

	    } case 2: { //Time
	        TimeLimit = aLimit;

	        foreach(new i : Player) {
				if(Player[i][Time] > TimeLimit) {

				    Player[i][Time] = 12;
				    SetPlayerTime(playerid, Player[i][Time], 12);

					format(iString, sizeof(iString), "UPDATE Players SET Time = %d WHERE Name = '%q'", Player[i][Time], Player[i][Name]);
				    db_free_result(db_query(sqliteconnection, iString));
				}
			}

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed time limit to: {FFFFFF}%d",Player[playerid][Name], TimeLimit);
			SendClientMessageToAll(-1, iString);
	    }
	}
	LogAdminCommand("limit", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:config(playerid, params[], help) {
    //if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 5 or rcon admin.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display server configuration for you to modify.");
	    return 1;
	}
	ShowConfigDialog(playerid);
    LogAdminCommand("config", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:loadbases(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "load another set of bases from the database.");
	    return 1;
	}
	if(Current != -1) return SendErrorMessage(playerid,"Can't use this command while round is active.");
	new baseset = 0;
	if(sscanf(params, "d", baseset))
	{
	    SendUsageMessage(playerid, "/loadbases [base set id]");
	    SendClientMessage(playerid, -1, "Available base set IDs:");
		SendClientMessage(playerid, -1, "0 = new & updated bulletproof bases");
		SendClientMessage(playerid, -1, "1 = old bulletproof bases (includes some oldschool bases)");
		SendClientMessage(playerid, -1, "2 = attdef bases (mainly TeK bases)");
		return 1;
	}
	if(baseset < 0 || baseset > 2)
	{
	    SendErrorMessage(playerid, "Invalid base set ID.");
	    SendClientMessage(playerid, -1, "Available base set IDs:");
		SendClientMessage(playerid, -1, "0 = new & updated bulletproof bases");
		SendClientMessage(playerid, -1, "1 = old bulletproof bases (includes some oldschool bases)");
		SendClientMessage(playerid, -1, "2 = attdef bases (mainly TeK bases)");
		return 1;
	}
    CurrentBaseSet[0] = EOS;
	switch(baseset)
	{
	    case 0:
	    {
	        strcat(CurrentBaseSet, "NewBulletproofBases");
	    }
	    case 1:
	    {
            strcat(CurrentBaseSet, "OldBulletproofBases");
	    }
	    case 2:
	    {
            strcat(CurrentBaseSet, "AttdefBases");
	    }
	}
	db_free_result(db_query(sqliteconnection, sprintf("UPDATE `Configs` SET `Value`='%s' WHERE `Option`='CurrentBaseSet'", CurrentBaseSet)));
	LoadBases();
	SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has loaded base set ID: {FFFFFF}%d | %s", Player[playerid][Name], baseset, CurrentBaseSet));
	return 1;
}

YCMD:base(playerid, params[], help)
{
	//if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 5 or rcon admin.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "create a new base.");
	    return 1;
	}
    if(Current != -1) return SendErrorMessage(playerid,"Can't use this command while round is active.");

	new Params[2][64], BaseName[128], iString[256], CommandID;
	if(sscanf(params, "szz", Params[0], Params[1], BaseName)) return SendUsageMessage(playerid,"/base [create | att | def | cp | name | delete]");

	if(strcmp(Params[0], "create", true) == 0) CommandID = 1;
	else if(strcmp(Params[0], "att", true) == 0) CommandID = 2;
	else if(strcmp(Params[0], "def", true) == 0) CommandID = 3;
	else if(strcmp(Params[0], "cp", true) == 0) CommandID = 4;
	else if(strcmp(Params[0], "name", true) == 0) CommandID = 5;
	else if(strcmp(Params[0], "delete", true) == 0) CommandID = 6;
	else return SendUsageMessage(playerid,"/base [create | att | def | cp | name | delete]");

	switch(CommandID) {
	    case 1: {
		    if(TotalBases > MAX_BASES)
				return SendErrorMessage(playerid,"Too many bases already created. You can use /loadbases to create this base in another set.");

            new BaseID;
			BaseID = FindFreeBaseSlot();
			format(iString, sizeof(iString), "INSERT INTO `%s` (ID, AttSpawn, CPSpawn, DefSpawn, Interior, Name) VALUES (%d, 0, 0, 0, 0, 'No Name')", CurrentBaseSet, BaseID);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has created base ID: {FFFFFF}%d "COL_PRIM"| in base set: {FFFFFF}%s", Player[playerid][Name], BaseID, CurrentBaseSet);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
	    } case 2: {
	        if(isnull(Params[1]) || !IsNumeric(Params[1])) return SendUsageMessage(playerid,"/base [att] [Base ID]");

			new baseid;
			baseid = strval(Params[1]);

			if(baseid > MAX_BASES) return SendErrorMessage(playerid,"That base doesn't exist.");
			if(!BExist[baseid]) return SendErrorMessage(playerid,"That base doesn't exist.");

			new Float:P[3], PositionA[128];
			GetPlayerPos(playerid, P[0], P[1], P[2]);
			format(PositionA, sizeof(PositionA), "%.0f,%.0f,%.0f", P[0], P[1], P[2]);

			format(iString, sizeof(iString), "UPDATE `%s` SET AttSpawn = '%s' WHERE ID = %d", CurrentBaseSet, PositionA, baseid);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has configured Attacker position for {FFFFFF}Base ID: %d", Player[playerid][Name], baseid);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
	    } case 3: {
	        if(isnull(Params[1]) || !IsNumeric(Params[1])) return SendUsageMessage(playerid,"/base [def] [Base ID]");

			new baseid;
			baseid = strval(Params[1]);

			if(baseid > MAX_BASES) return SendErrorMessage(playerid,"That base doesn't exist.");
			if(!BExist[baseid]) return SendErrorMessage(playerid,"That base doesn't exist.");

			new Float:P[3], PositionB[128];
			GetPlayerPos(playerid, P[0], P[1], P[2]);
			format(PositionB, sizeof(PositionB), "%.0f,%.0f,%.0f", P[0], P[1], P[2]);

			format(iString, sizeof(iString), "UPDATE `%s` SET DefSpawn = '%s' WHERE ID = %d", CurrentBaseSet, PositionB, baseid);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has configured Defender position for {FFFFFF}Base ID: %d", Player[playerid][Name], baseid);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
	    } case 4: {
	        if(isnull(Params[1]) || !IsNumeric(Params[1])) return SendUsageMessage(playerid,"/base [cp] [Base ID]");

			new baseid;
			baseid = strval(Params[1]);

			if(baseid > MAX_BASES) return SendErrorMessage(playerid,"That base doesn't exist.");
			if(!BExist[baseid]) return SendErrorMessage(playerid,"That base doesn't exist.");

			new Float:P[3], cp[128];
			GetPlayerPos(playerid, P[0], P[1], P[2]);
			format(cp, sizeof(cp), "%.0f,%.0f,%.0f", P[0], P[1], P[2]);

			format(iString, sizeof(iString), "UPDATE `%s` SET CPSpawn = '%s', Interior = %d WHERE ID = %d", CurrentBaseSet, cp, GetPlayerInterior(playerid), baseid);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has configured CP/Interior position for {FFFFFF}Base ID: %d", Player[playerid][Name], baseid);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
	    } case 5: {
	        if(isnull(Params[1]) || !IsNumeric(Params[1])) return SendUsageMessage(playerid,"/base [name] [Base ID] [Name]");
			if(isnull(BaseName)) return SendUsageMessage(playerid,"/base [name] [Base ID] [Name]");

			new baseid;
			baseid = strval(Params[1]);

			if(baseid > MAX_BASES) return SendErrorMessage(playerid,"That base doesn't exist.");
			if(!BExist[baseid]) return SendErrorMessage(playerid,"That base doesn't exist.");

			format(iString, sizeof(iString), "UPDATE `%s` SET Name = '%s' WHERE ID = %d", CurrentBaseSet, BaseName, baseid);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has configured Name for {FFFFFF}Base ID: %d", Player[playerid][Name], baseid);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
	    } case 6: {
	        if(isnull(Params[1]) || !IsNumeric(Params[1])) return SendUsageMessage(playerid,"/base [delete] [Base ID]");

			new baseid;
			baseid = strval(Params[1]);

			if(baseid > MAX_BASES) return SendErrorMessage(playerid,"That base doesn't exist.");
			if(!BExist[baseid]) return SendErrorMessage(playerid,"That base doesn't exist.");

			format(iString, sizeof(iString), "DELETE FROM `%s` WHERE ID = %d", CurrentBaseSet, baseid);
			db_free_result(db_query(sqliteconnection, iString));

			BExist[baseid] = false;

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has deleted {FFFFFF}Base ID: %d from base set: %s", Player[playerid][Name], baseid, CurrentBaseSet);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
		}
	}
	return 1;
}

YCMD:permlock(playerid, params[], help)
{
    //if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle server permanent lock status.");
	    return 1;
	}

	if(ServerLocked == false)
	{
	    SendErrorMessage(playerid,"Server must be locked first. Use /lock !");
	}
	else
	{
		new iString[128];
	    if(PermLocked == true)
		{
			PermLocked = false;
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled the server permanent lock!",Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		}
		else
		{
		    PermLocked = true;
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has made the server lock permanent!",Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		}
	}
	LogAdminCommand("permlock", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:lock(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "lock the server.");
	    return 1;
	}
	new iString[128];
	if(ServerLocked == false) {

	    if(isnull(params)) return SendUsageMessage(playerid,"/lock [Password]");
		if(strlen(params) > MAX_SERVER_PASS_LENGH) return SendErrorMessage(playerid,"Server password is too long.");

        format(ServerPass, sizeof(ServerPass), "password %s", params);
        SendRconCommand(ServerPass);

		ServerLocked = true;
		PermLocked = false;

		format(iString, sizeof(iString), "%sServer Pass: ~r~%s", MAIN_TEXT_COLOUR, params);
		TextDrawSetString(LockServerTD, iString);

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has locked the server. Password: {FFFFFF}%s",Player[playerid][Name], params);
		SendClientMessageToAll(-1, iString);

	} else {

		SendRconCommand("password 0");
		TextDrawSetString(LockServerTD, sprintf("%sServer: ~r~Unlocked", MAIN_TEXT_COLOUR));

		ServerLocked = false;
		PermLocked = false;

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unlocked the server.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
	}
    LogAdminCommand("lock", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:unlock(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "unlock the server.");
	    return 1;
	}
	if(ServerLocked == false) return SendErrorMessage(playerid,"Server is not locked.");

	new iString[128];
	SendRconCommand("password 0");
	TextDrawSetString(LockServerTD, sprintf("%sServer: ~r~Unlocked", MAIN_TEXT_COLOUR));

	ServerLocked = false;
	PermLocked = false;

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unlocked the server.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("unlock", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:resetscores(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "reset team scores.");
	    return 1;
	}
	
    TeamScore[ATTACKER] = 0;
    TeamScore[DEFENDER] = 0;
    CurrentRound = 0;

	UpdateTeamScoreTextDraw();
	UpdateRoundsPlayedTextDraw();
	UpdateTeamNameTextDraw();

	ClearPlayerVariables();

	foreach(new i : Player) {
		Player[i][TotalKills] = 0;
		Player[i][TotalDeaths] = 0;
		Player[i][TotalDamage] = 0;
		Player[i][RoundPlayed] = 0;
	    Player[i][TotalBulletsFired] = 0;
	    Player[i][TotalshotsHit] = 0;
	}
    new iString[64];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has reset the scores.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
	return 1;
}

YCMD:view(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "put you in base/arena spectator mode.");
	    return 1;
	}
	if(Current != -1) return SendErrorMessage(playerid,"Can't use while round is on.");

	new Params[64], Round, CommandID, iString[256];
	if(sscanf(params, "sd", Params, Round)) return SendUsageMessage(playerid,"/view [base | arena] [Round ID]");

	if(strcmp(Params, "base", true) == 0) CommandID = 1;
	else if(strcmp(Params, "arena", true) == 0) CommandID = 2;
	else return SendUsageMessage(playerid,"/view [base | arena] [Round ID]");

	if(Player[playerid][InDM] == true) {
	    Player[playerid][InDM] = false;
    	Player[playerid][DMReadd] = 0;
	}
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use /rq instead.");

	if(Player[playerid][Spectating] == true) StopSpectate(playerid);

	Player[playerid][SpectatingRound] = Round;
	switch (CommandID) {
	    case 1: { //base
			if(Round > MAX_BASES) return SendErrorMessage(playerid,"That base does not exist.");
			if(!BExist[Round]) return SendErrorMessage(playerid,"That base does not exist.");

	        SetPlayerInterior(playerid, BInterior[Round]);
			SetPlayerCameraLookAt(playerid,BCPSpawn[Round][0],BCPSpawn[Round][1],BCPSpawn[Round][2]);
	   		SetPlayerCameraPos(playerid,BCPSpawn[Round][0]+100,BCPSpawn[Round][1],BCPSpawn[Round][2]+80);
			SetPlayerPos(playerid, BCPSpawn[Round][0], BCPSpawn[Round][1], BCPSpawn[Round][2]);

			Player[playerid][SpectatingType] = BASE;
			format(iString, sizeof(iString), "%sBase ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, BName[Round], Round, MAIN_TEXT_COLOUR);
			PlayerTextDrawSetString(playerid, TD_RoundSpec[playerid], iString);

	    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"is spectating Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[Round], Round);
	    } case 2: { // Arena
			if(Round > MAX_ARENAS) return SendErrorMessage(playerid,"That arena does not exist.");
			if(!AExist[Round]) return SendErrorMessage(playerid,"That arena does not exist.");

			SetPlayerCameraLookAt(playerid,ACPSpawn[Round][0],ACPSpawn[Round][1],ACPSpawn[Round][2]);
	   		SetPlayerCameraPos(playerid,ACPSpawn[Round][0]+100,ACPSpawn[Round][1],ACPSpawn[Round][2]+80);
			SetPlayerPos(playerid, ACPSpawn[Round][0], ACPSpawn[Round][1], ACPSpawn[Round][2]);
			SetPlayerInterior(playerid, AInterior[Round]);

			Player[playerid][SpectatingType] = ARENA;
			format(iString, sizeof(iString), "%sArena ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, AName[Round], Round, MAIN_TEXT_COLOUR);
			PlayerTextDrawSetString(playerid, TD_RoundSpec[playerid], iString);

	    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"is spectating Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[Round], Round);
	    }

	}
	SendClientMessageToAll(-1, iString);
	SendClientMessage(playerid, -1, "Switch between rounds using LMB & RMB. Go normal mode using /specoff. Press Jump key to spawn in CP.");
	Player[playerid][Spectating] = true;

	return 1;
}

forward RemoveTempNetcheck(playerid);
public RemoveTempNetcheck(playerid)
{
    Player[playerid][TempNetcheck] = false;
	return 1;
}

YCMD:netcheckme(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "temporarily netcheck yourself until an admin does it for you");
	    return 1;
	}
	if(Player[playerid][TempNetcheck] != false)
	{
	    SendErrorMessage(playerid, "Netcheck is already temporarily disabled on you");
	    return 1;
	}
	if(!Player[playerid][NetCheck])
	{
	    SendErrorMessage(playerid, "You've already got netcheck disabled on you");
	    return 1;
	}
	if(Player[playerid][CanNetcheck] == -1)
	{
		new tmp;
		gettime(tmp, Player[playerid][CanNetcheck], tmp);
		Player[playerid][TempNetcheck] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s (%d) "COL_PRIM"requests permanent net-check.", Player[playerid][Name], playerid));
		SendClientMessage(playerid, -1, ""COL_PRIM"You've been temporarily netchecked for 15 seconds only.");
		SetTimerEx("RemoveTempNetcheck", 15000, false, "i", playerid);
	}
	else
	{
		new tmp, minute;
		gettime(tmp, minute, tmp);
		if((minute - Player[playerid][CanNetcheck]) > 20)
		{
		    Player[playerid][TempNetcheck] = true;
   			SendClientMessageToAll(-1, sprintf("{FFFFFF}%s (%d) "COL_PRIM"requests permanent net-check.", Player[playerid][Name], playerid));
			SendClientMessage(playerid, -1, ""COL_PRIM"You've been temporarily netchecked for 15 seconds only.");
			Player[playerid][CanNetcheck] = minute;
		}
		else
			SendErrorMessage(playerid, "You must wait 20 minutes before you can netcheck yourself again");
	}
	return 1;
}

YCMD:netcheck(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle net status check on a specific player.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/netcheck [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");

	new iString[130];
	if(Player[pID][NetCheck] == 1) {
	    Player[pID][NetCheck] = 0;
	    Player[pID][FPSCheck] = 0;
	    Player[pID][PingCheck] = 0;
	    Player[pID][PLCheck] = 0;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled Net-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	} else {
	    Player[pID][NetCheck] = 1;
	    Player[pID][FPSCheck] = 1;
	    Player[pID][PingCheck] = 1;
	    Player[pID][PLCheck] = 1;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has enabled Net-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	}
	SendClientMessageToAll(-1, iString);

	format(iString, sizeof(iString), "UPDATE Players SET NetCheck = %d WHERE Name = '%q'", Player[pID][NetCheck], Player[pID][Name]);
    db_free_result(db_query(sqliteconnection, iString));

    LogAdminCommand("netcheck", playerid, pID);
	return 1;
}

YCMD:fpscheck(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle FPS status check on a specific player.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/fpscheck [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][NetCheck] == 0) return SendErrorMessage(playerid, "That player has netcheck disabled on him.");

	new iString[128];
	if(Player[pID][FPSCheck] == 1) {
	    Player[pID][FPSCheck] = 0;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled FPS-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	} else {
	    Player[pID][FPSCheck] = 1;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has enabled FPS-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	}
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("fpscheck", playerid, pID);
	return 1;
}

YCMD:pingcheck(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle ping status check on a specific player.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/pingcheck [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][NetCheck] == 0) return SendErrorMessage(playerid, "That player has netcheck disabled on him.");

	new iString[128];
	if(Player[pID][PingCheck] == 1) {
	    Player[pID][PingCheck] = 0;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled Ping-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	} else {
	    Player[pID][PingCheck] = 1;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has enabled Ping-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	}
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("pingcheck", playerid, pID);
	return 1;
}

YCMD:plcheck(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle packet-loss status check on a specific player.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/plcheck [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][NetCheck] == 0) return SendErrorMessage(playerid, "That player has netcheck disabled on him.");

	new iString[128];
	if(Player[pID][PLCheck] == 1) {
	    Player[pID][PLCheck] = 0;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled PL-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	} else {
	    Player[pID][PLCheck] = 1;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has enabled PL-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	}
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("plcheck", playerid, pID);
	return 1;
}

YCMD:leaguecmds(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display league commands.");
	    return 1;
	}
	#if defined _league_included
	SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"is viewing the commands of league {FFFFFF}(/leaguecmds)", Player[playerid][Name]));
	ShowPlayerDialog(playerid,
		DIALOG_NO_RESPONSE,
		DIALOG_STYLE_TABLIST_HEADERS,
		"League commands",
		"Command\tInfo\n\
		/leaguestats\tTo show statistics of league\n\
		/createclan\tRegister a league clan\n\
		/joinclan\tJoin a league clan\n\
		/clanapps\tView clan join requests\n\
		/acceptclan\tAccept players in your league clan\n\
		/claninfo\tGet info about a league clan\n\
		/kickclan\tKick someone from your league clan (You can kick yourself)\n\
		/setcoleader\tSet someone as coleader for your clan (to remove coleader, use /setcoleader none)",
		"OK", "");
	#else
	SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
	#endif
	return 1;
}

YCMD:claninfo(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "view clan info.");
	    return 1;
	}
    #if defined _league_included
	if(isnull(params))
		return SendUsageMessage(playerid,"/claninfo [Clan Tag]");

    if(strlen(params) > 6)
	    return SendErrorMessage(playerid,"A clan tag must be very short");

	if(strfind(params, " ", true) != -1 || strfind(params, "[", true) != -1 || strfind(params, "]", true) != -1)
	    return SendErrorMessage(playerid,"Spaces and brackets [] are not allowed in a clan tag");

	ClanInfo(playerid, params);
	#else
	SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
	#endif
	return 1;
}

YCMD:acceptclan(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "accept someone in your clan.");
	    return 1;
	}
    #if defined _league_included
    if(!IsPlayerInAnyClan(playerid))
	    return SendErrorMessage(playerid, "You're not in a clan.");
	new NameToAccept[MAX_PLAYER_NAME];
	if(sscanf(params, "s", NameToAccept))
		return SendUsageMessage(playerid,"/acceptclan [Player Name]");

	AcceptClan(playerid, NameToAccept);
	#else
	SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
	#endif
	return 1;
}

YCMD:setcoleader(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "Set someone as coleader for your own clan.");
	    return 1;
	}
    #if defined _league_included
    if(!IsPlayerInAnyClan(playerid))
	    return SendErrorMessage(playerid, "You're not in a clan.");
	new NameToCo[MAX_PLAYER_NAME];
	if(sscanf(params, "s", NameToCo))
		return SendUsageMessage(playerid,"/setcoleader [Player Name] ");

	SetCoLeader(playerid, NameToCo);
	#else
	SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
	#endif
	return 1;
}

YCMD:kickclan(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "kick someone from your clan.");
	    return 1;
	}
    #if defined _league_included
    if(!IsPlayerInAnyClan(playerid))
	    return SendErrorMessage(playerid, "You're not in a clan.");
	new NameToKick[MAX_PLAYER_NAME];
	if(sscanf(params, "s", NameToKick))
		return SendUsageMessage(playerid,"/kickclan [Player Name]");

	KickClan(playerid, NameToKick);
	#else
	SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
	#endif
	return 1;
}

YCMD:clanapps(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "view clan join requests.");
	    return 1;
	}
    #if defined _league_included
    if(!IsPlayerInAnyClan(playerid))
	    return SendErrorMessage(playerid, "You're not in a clan.");

	ViewClanApps(playerid);
	#else
	SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
	#endif
	return 1;
}

YCMD:joinclan(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "join a league clan.");
	    return 1;
	}
    #if defined _league_included
    if(IsPlayerInAnyClan(playerid))
	    return SendErrorMessage(playerid, "You're already in a clan.");
	    
	if(isnull(params))
		return SendUsageMessage(playerid,"/createclan [Clan Tag]");

    if(strlen(params) > 6)
	    return SendErrorMessage(playerid,"A clan tag must be very short");

	if(strfind(params, " ", true) != -1 || strfind(params, "[", true) != -1 || strfind(params, "]", true) != -1)
	    return SendErrorMessage(playerid,"Spaces and brackets [] are not allowed in a clan tag");

	JoinClan(playerid, params);
	#else
	SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
	#endif
	return 1;
}

YCMD:createclan(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "register a league clan.");
	    return 1;
	}
    #if defined _league_included
    if(IsPlayerInAnyClan(playerid))
	    return SendErrorMessage(playerid, "You're already in a clan.");

	if(isnull(params))
		return SendUsageMessage(playerid,"/createclan [Clan Tag]");
		
    if(strlen(params) > 6)
	    return SendErrorMessage(playerid,"A clan tag must be very short");
	    
	if(strfind(params, " ", true) != -1 || strfind(params, "[", true) != -1 || strfind(params, "]", true) != -1)
	    return SendErrorMessage(playerid,"Spaces and brackets [] are not allowed in a clan tag");

	CreateClan(playerid, params);
	#else
	SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
	#endif
	return 1;
}

YCMD:leaguestats(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display league mini scoreboard.");
	    return 1;
	}
	#if defined _league_included
	SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"is viewing the statistics of league {FFFFFF}(/leaguestats)", Player[playerid][Name]));
	ShowLeagueStatsDialog(playerid);
	#else
	SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
	#endif
	return 1;
}

YCMD:war(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a match quickly.");
	    return 1;
	}
	if(Current != -1) return SendErrorMessage(playerid,"Can't use this command while round is on.");

	new TeamAName[7], TeamBName[7];
	if(sscanf(params, "zz", TeamAName, TeamBName)) return SendUsageMessage(playerid,"/war ([Team A] [Team B]) (end)");
	if(strcmp(TeamAName, "end", true) == 0 && isnull(TeamBName) && WarMode == true)
	{
		SetTimer("WarEnded", 5000, 0);
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has set the match to end!", Player[playerid][Name]));
		SendClientMessageToAll(-1, ""COL_PRIM"Preparing End Match Results..");
		SendClientMessageToAll(-1, ""COL_PRIM"If you missed the results screen by hiding the current textdraws, type {FFFFFF}/showagain");

		return 1;
	} else if(isnull(TeamBName)) return SendUsageMessage(playerid,"/war ([Team A] [Team B]) (end)");

    if(WarMode == true) return SendErrorMessage(playerid,"War-mode is already on.");
	if(strlen(TeamAName) > 6 || strlen(TeamBName) > 6) return SendErrorMessage(playerid,"Team name is too long.");
	if(strfind(TeamAName, "~") != -1 || strfind(TeamBName, "~") != -1) return SendErrorMessage(playerid,"~ not allowed.");
 	
	format(TeamName[ATTACKER], 7, TeamAName);
	format(TeamName[ATTACKER_SUB], 11, "%s Sub", TeamName[ATTACKER]);
	format(TeamName[DEFENDER], 7, TeamBName);
	format(TeamName[DEFENDER_SUB], 11, "%s Sub", TeamName[DEFENDER]);
	UpdateTeamScoreTextDraw();
	UpdateRoundsPlayedTextDraw();
	UpdateTeamNameTextDraw();
	new iString[144];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has enabled the Match-Mode.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
	UpdateTeamNamesTextdraw();

	MatchRoundsStarted = 0;
	for( new i = 0; i < 101; i++ )
	{
	    MatchRoundsRecord[ i ][ round__ID ] = -1;
	    MatchRoundsRecord[ i ][ round__type ] = -1;
	    MatchRoundsRecord[ i ][ round__completed ] = false;
	}

	WarMode = true;
	#if defined _league_included
	UpdateOnlineMatchesList(true);
	#endif
	RoundPaused = false;
    format(iString, sizeof iString, "%sWar Mode: ~r~ON", MAIN_TEXT_COLOUR);
	TextDrawSetString(WarModeText, iString);

    new toTeam = ATTACKER, oppositeTeam = DEFENDER;
	new
    	MyVehicle = -1,
		Seat;

	foreach(new i : Player)
	{
		Player[i][TotalKills] = 0;
		Player[i][TotalDeaths] = 0;
		Player[i][TotalDamage] = 0;
		Player[i][RoundPlayed] = 0;
	    Player[i][TotalBulletsFired] = 0;
	    Player[i][TotalshotsHit] = 0;

		if(Player[i][InDuel] == true || Player[i][IsAFK] || !Player[i][Spawned])
	        continue;

		MyVehicle = -1;
		switch(strfind(Player[i][Name], TeamName[ATTACKER], true))
		{
		    case -1: // tag not found
		    {
		        if(Player[i][Team] != oppositeTeam)
		        {
		            if(IsPlayerInAnyVehicle(i))
					{
						MyVehicle = GetPlayerVehicleID(i);
						Seat = GetPlayerVehicleSeat(i);
					}
		        	Player[i][Team] = oppositeTeam;
					SwitchTeamFix(i, false, false);
					if(MyVehicle != -1)
		    			PutPlayerInVehicle(i, MyVehicle, Seat);
	        	}
		    }
			default: // found tag
			{
			    if(Player[i][Team] != toTeam)
		        {
		            if(IsPlayerInAnyVehicle(i))
					{
						MyVehicle = GetPlayerVehicleID(i);
						Seat = GetPlayerVehicleSeat(i);
					}
		        	Player[i][Team] = toTeam;
					SwitchTeamFix(i, false, false);
					if(MyVehicle != -1)
		    			PutPlayerInVehicle(i, MyVehicle, Seat);
	        	}
			}
		}
	}
	ShowMatchScoreBoard();
	return 1;
}


YCMD:teamname(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change the name of a team.");
	    return 1;
	}
	new TeamID, TeamNamee[24];
	if(sscanf(params, "ds", TeamID, TeamNamee)) return SendUsageMessage(playerid,"/teamname [Team ID] [Name] (0 = Attacker | 1 = Defender)");

	if(TeamID < 0 || TeamID > 1) return SendErrorMessage(playerid,"Invalid Team ID.");
	if(strlen(TeamNamee) > 6) return SendErrorMessage(playerid,"Team name is too long.");
	if(strfind(TeamNamee, "~") != -1) return SendErrorMessage(playerid,"~ not allowed.");

    new iString[144];
	switch(TeamID) {
	    case 0: {
			format(TeamName[ATTACKER], 24, TeamNamee);
			format(TeamName[ATTACKER_SUB], 24, "%s Sub", TeamName[ATTACKER]);
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set attacker team name to: {FFFFFF}%s", Player[playerid][Name], TeamName[ATTACKER]);
			SendClientMessageToAll(-1, iString);
	    } case 1: {
			format(TeamName[DEFENDER], 24, TeamNamee);
			format(TeamName[DEFENDER_SUB], 24, "%s Sub", TeamName[DEFENDER]);
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set defender team name to: {FFFFFF}%s", Player[playerid][Name], TeamName[DEFENDER]);
			SendClientMessageToAll(-1, iString);
	    }
	}
	
	#if defined _league_included
	if(WarMode)
    	UpdateOnlineMatchesList(true);
    #endif

	UpdateTeamNamesTextdraw();
	UpdateTeamNameTextDraw();
	return 1;
}


YCMD:tr(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set total rounds of the current match.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/tr [Total Rounds]");

	new Value = strval(params);
	if(Value < CurrentRound || Value < 1 || Value > 100) return SendErrorMessage(playerid,"Invalid total rounds.");

	TotalRounds = Value;

	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed the total rounds to: {FFFFFF}%d", Player[playerid][Name], TotalRounds);
	SendClientMessageToAll(-1, iString);

	UpdateRoundsPlayedTextDraw();
	return 1;
}

YCMD:cr(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set the current round of the current match.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/cr [Current Round]");

	new Value = strval(params);
	if(Value > TotalRounds || Value < 0) return SendErrorMessage(playerid,"Invalid current round.");

	CurrentRound = Value;

	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed the current round to: {FFFFFF}%d", Player[playerid][Name], CurrentRound);
	SendClientMessageToAll(-1, iString);

	UpdateRoundsPlayedTextDraw();
	return 1;
}

YCMD:serverpassword(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display server password for everyone connected.");
	    return 1;
	}
	if(ServerLocked)
	{
		new str[128];
		format(str, sizeof(str), ""COL_PRIM"Current Server Password: {FFFFFF}%s", ServerPass[9]);
		SendClientMessageToAll(-1, str);
	}
	return 1;
}

YCMD:freeze(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "freeze a player.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/freeze [Player ID]");

	new pID = strval(params);
 	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isnt connected.");

	TogglePlayerControllable(pID, 0);

	new iString[128];
    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has frozen {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);

    LogAdminCommand("freeze", playerid, pID);
	return 1;
}

YCMD:giveweapon(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "give a weapon to a specific player.");
	    return 1;
	}
	new pID, Weapon[50], Ammo, iString[180];

 	if(sscanf(params, "isd", pID, Weapon, Ammo))  return SendUsageMessage(playerid,"/giveweapon [Player ID] [Weapon Name] [Ammo]");

	if(Ammo < 0 || Ammo > 9999) return SendErrorMessage(playerid,"Invalid Ammo.");

	new WeaponID = GetWeaponID(Weapon);
	if(WeaponID < 1 || WeaponID > 46 || WeaponID == 19 || WeaponID == 20 || WeaponID == 21 || WeaponID == 22) return SendErrorMessage(playerid,"Invalid Weapon Name.");
	if(WeaponID == 44 || WeaponID == 45) return SendErrorMessage(playerid,"We don't do this shit around here.");

	GivePlayerWeapon(pID, WeaponID, Ammo);

    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has given {FFFFFF}%s "COL_PRIM"| Weapon: {FFFFFF}%s "COL_PRIM"- Ammo: {FFFFFF}%d", Player[playerid][Name], Player[pID][Name], WeaponNames[WeaponID], Ammo);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("giveweapon", playerid, pID);
	return 1;
}

YCMD:giveallgun(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "give everyone a specific weapon.");
	    return 1;
	}
 	new iString[180], Ammo, Weapon[50];
 	if(sscanf(params, "sd", Weapon, Ammo))  return SendUsageMessage(playerid,"/giveallgun [Weapon Name] [Ammo]");

	if(Ammo < 0 || Ammo > 9999) return SendErrorMessage(playerid,"Invalid Ammo.");

	new weapon = GetWeaponID(Weapon);
 	if(weapon < 1 || weapon > 46 || weapon == 19 || weapon == 20 || weapon == 21 || weapon == 22) return SendErrorMessage(playerid,"Invalid weapon name.");
	if(weapon == 44 || weapon == 45) return SendErrorMessage(playerid,"We don't do this shit around here.");

    foreach(new i : Player) {
    	if(Player[i][InDM] == false && Player[i][InDuel] == false  && Player[i][Spectating] == false) {
			GivePlayerWeapon(i, weapon, Ammo);
		}
	}

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has given everyone | Weapon: {FFFFFF}%s "COL_PRIM"- Ammo: {FFFFFF}%d",Player[playerid][Name] ,WeaponNames[weapon], Ammo);
 	SendClientMessageToAll(-1, iString);
    LogAdminCommand("giveallgun", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:unfreeze(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "unfreeze a player.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/unfreeze [Player ID]");

	new pID = strval(params);
 	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isnt connected.");

	TogglePlayerControllable(pID, 1);


	new iString[128];
    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has unfrozen {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);

    LogAdminCommand("unfreeze", playerid, pID);
	return 1;
}

YCMD:roundtime(playerid,params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "set the round time.");
	    return 1;
	}
	if(Current != -1) return SendErrorMessage(playerid,"Can't use the command while round is on.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/roundtime [Mints (1 - 30)]");

	new rTime = strval(params);
	if(rTime < 1 || rTime > 30) return SendErrorMessage(playerid,"Round time can't be lower than 1 or higher than 30 mints.");

	ConfigRoundTime = rTime;

	new iString[128];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Round Time'", rTime);
    db_free_result(db_query(sqliteconnection, iString));

    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has changed the round time to: {FFFFFF}%d mints", Player[playerid][Name], rTime);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("roundtime", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:cptime(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "set the time needed to capture a checkpoint.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/cptime [Seconds (1 - 60)]");

	new cpTime = strval(params);
	if(cpTime < 1 || cpTime > 60) return SendErrorMessage(playerid,"CP time can't be lower than 1 or higher than 60 seconds.");

	ConfigCPTime = cpTime;
 	CurrentCPTime = ConfigCPTime + 1;

	new iString[144];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'CP Time'", cpTime);
    db_free_result(db_query(sqliteconnection, iString));

    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has changed the CP time to: {FFFFFF}%d seconds", Player[playerid][Name], cpTime);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("cptime", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:lastplayed(playerid,params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display the ID of the last played round.");
	    return 1;
	}
	if(Current < 0)
	{
	    SendErrorMessage(playerid, "Invalid round ID.");
	    return 1;
	}
	SendClientMessageToAll(-1, sprintf(""COL_PRIM"Last Played: {FFFFFF}%d "COL_PRIM"| Requested by {FFFFFF}%s "COL_PRIM"| Type {FFFFFF}/start last "COL_PRIM"to start it!", ServerLastPlayed, Player[playerid][Name]));
	return 1;
}

YCMD:rounds(playerid,params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display a record of rounds of a match.");
	    return 1;
	}
	new str1[1024];
	for( new id = 0; id < 101; id++ ) {
	    if( MatchRoundsRecord[ id ][ round__ID ] != -1 ) {
	        switch( MatchRoundsRecord[ id ][ round__type ] ) {
	    /*base*/case 0: format( str1, sizeof(str1), "%s\n{FFFFFF}%d.%s%s [ID:%d]", str1, id, (MatchRoundsRecord[ id ][ round__completed ]) ? ("") : ("{FAF62D}"), BName[ MatchRoundsRecord[ id ][ round__ID ] ], MatchRoundsRecord[ id ][ round__ID ] );
	   /*arena*/case 1: format( str1, sizeof(str1), "%s\n{B5B5B5}%d.%s%s [ID:%d]", str1, id, (MatchRoundsRecord[ id ][ round__completed ]) ? ("") : ("{FAF62D}"), AName[ MatchRoundsRecord[ id ][ round__ID ] ], MatchRoundsRecord[ id ][ round__ID ] );
				default: format( str1, sizeof(str1), "%s\nWadaffuq?", str1 );
	        }
	    }
	}
	ShowPlayerDialog( playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, "Rounds played in current/last match", str1, "Close", "" );
	return 1;
}


YCMD:dance(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "shake your fucking ass.");
	    return 1;
	}
	if(Current != -1) return SendErrorMessage(playerid,"Can't use this command while in round.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/dance [1-4]");

	new dID = strval(params);
	if(dID < 1 || dID > 4) return SendErrorMessage(playerid,"Invalid dance ID.");

	switch(dID) {
		case 1: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE1);
		case 2: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE2);
		case 3: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE3);
		case 4: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE4);
	}
	return 1;
}

YCMD:piss(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "piss.");
	    return 1;
	}
	SetPlayerSpecialAction(playerid, 68);
	return 1;
}


YCMD:resetallguns(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "reset guns of all players.");
	    return 1;
	}
	foreach(new i : Player) {
	    if(Player[i][InDM] == false && Player[i][InDuel] == false && Player[i][Spectating] == false) {
	    	ResetPlayerWeapons(i);
		}
	}

	new iString[64];
    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has reset everyone's weapons.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("resetallguns", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:replace(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "replace players whether they're connected to the server or not.");
	    return 1;
	}
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");
	
	new str[2048];
	foreach(new i : Player)
	{
	    if(Player[i][InDuel] == true || Player[i][IsAFK] || !Player[i][Spawned])
	        continue;

		format(str, sizeof str, "%s%s\n", str, Player[i][Name]);
	}
	ShowPlayerDialog(playerid, DIALOG_REPLACE_FIRST, DIALOG_STYLE_LIST, ""COL_PRIM"Player to add", str, "Process", "Cancel");
	LogAdminCommand("replace", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:cc(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "clear the chat.");
	    return 1;
	}
    ClearChat();

    new iString[128];
    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has cleared chat.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("cc", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:vworld(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "teleport you to a virtual world.");
	    return 1;
	}
	if(Player[playerid][InDM] == false) return SendErrorMessage(playerid,"Can't use this command while you are not in a DM.");
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't use this command while playing.");
	if(Player[playerid][Spectating] == true) return 1;

    if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/vworld [World ID]");

	new vID = strval(params);
	if(vID <= 5) return SendErrorMessage(playerid,"Pick a virtual world above 5.");

	SetPlayerVirtualWorld(playerid, vID);
	return 1;
}

YCMD:skin(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "view a catalog of different skins.");
	    return 1;
	}
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't use this command while playing.");
	if(Player[playerid][Spectating] == true) return 1;

    ShowModelSelectionMenu(playerid, playerskinlist, "Select a skin", 0x000000BB, 0x44444499, 0x99999999);
	return 1;
}

YCMD:pchannel(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display players in a channel.");
	    return 1;
	}
	if(Player[playerid][ChatChannel] != -1)
	{
		new iString[200];

		foreach(new i : Player)
		{
		    if(Player[i][ChatChannel] == Player[playerid][ChatChannel])
			{
		        format(iString, sizeof(iString), "%s%s (%d)\n", iString, Player[i][Name], i);
			}
		}

		ShowPlayerDialog(playerid,DIALOG_NO_RESPONSE,DIALOG_STYLE_MSGBOX,""COL_PRIM"Players in current channel", iString, "Close","");
	}
	else
	{
    	SendErrorMessage(playerid,"You are not in any channel. To join one, use /cchannel");
	}

	return 1;
}

YCMD:cchannel(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "enable you to join a chat channel.");
	    return 1;
	}
	if(isnull(params))
	{
		if(Player[playerid][ChatChannel] != -1)
		{
		    new iString[128];
		    format(iString, sizeof(iString), ""COL_PRIM"Current chat channel ID: {FFFFFF}%d"COL_PRIM". To join another one use /cchannel [Channel ID]", Player[playerid][ChatChannel]);
		    SendClientMessage(playerid, -1, iString);
		}
		else
		{
			SendUsageMessage(playerid,"/cchannel [Channel ID]");
		}
		return 1;
	}

	new Channel = strval(params);
	if(Channel < 0 || Channel > MAX_CHANNELS)
		return SendErrorMessage(playerid, sprintf("Invalid channel ID (Maximum chat channels: %d)", MAX_CHANNELS));

	Player[playerid][ChatChannel] = Channel;

    new str[144];

	format(str, sizeof(str), "UPDATE Players SET ChatChannel = %d WHERE Name = '%q'", Channel, Player[playerid][Name]);
    db_free_result(db_query(sqliteconnection, str));
    
    SendClientMessage(playerid, -1, ""COL_PRIM"You've joined the chat channel, to know who else is here, type {FFFFFF}/pchannel. "COL_PRIM"Use ^ symbol to chat!");

	format(str, sizeof(str), "{FFFFFF}%s "COL_PRIM"has joined chat channel ID: {FFFFFF}%d.", Player[playerid][Name], Channel);
	foreach(new i : Player)
	{
	    SendClientMessage(i, -1, str);
	}
	return 1;
}

YCMD:muteall(playerid, params[], help)
{
    //if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "mute everyone.");
	    return 1;
	}
	foreach(new i : Player)
		Player[i][Mute] = true;
	AllMuted = true;
	new admName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, admName, sizeof(admName));
	SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has muted everyone! (Press {FFFFFF}Y "COL_PRIM"to ask for round pause)", admName));
    LogAdminCommand("muteall", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:unmuteall(playerid, params[], help)
{
    //if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "unmute everyone.");
	    return 1;
	}
	foreach(new i : Player)
		Player[i][Mute] = false;
	AllMuted = false;
	new admName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, admName, sizeof(admName));
	SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has unmuted everyone!", admName));
    LogAdminCommand("unmuteall", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:mute(playerid,params[], help)
{
	//if(Player[playerid][Level] < 2 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "mute a specific player.");
	    return 1;
	}
	new pID, Reason[128], iString[180];
    if(sscanf(params, "is", pID, Reason)) return SendUsageMessage(playerid,"/mute [Player ID] [Reason]");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isnt connected.");

	if(Player[pID][Mute] == true) return SendErrorMessage(playerid,"That player is already muted.");
	//if(Player[playerid][Level] <= Player[pID][Level] && playerid != pID) return SendErrorMessage(playerid,"That player is higher admin level than you.");

	Player[pID][Mute] = true;


	if(strlen(Reason)) format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has muted {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}%s",Player[playerid][Name],Player[pID][Name], Reason);
	else format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has muted {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}No reason given.",Player[playerid][Name],Player[pID][Name]);
	SendClientMessageToAll(-1,iString);
    LogAdminCommand("mute", playerid, pID);
	return 1;
}

YCMD:unmute(playerid, params[], help)
{
	//if(Player[playerid][Level] < 2 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "unmute a specific player.");
	    return 1;
	}
	new pID = strval(params);

	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isnt connected.");
	if(Player[pID][Mute] == false) return SendErrorMessage(playerid,"That player is not muted.");

	Player[pID][Mute] = false;

	new iString[128];
	format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has unmuted {FFFFFF}%s",Player[playerid][Name],Player[pID][Name]);
	SendClientMessageToAll(-1,iString);
    LogAdminCommand("unmute", playerid, pID);
	return 1;
}

YCMD:slap(playerid,params[], help)
{
	//if(Player[playerid][Level] < 2 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "slap a player ass a few meters in the air.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/slap [Player ID]");

	new sid = strval(params);
    if(!IsPlayerConnected(sid)) return SendErrorMessage(playerid,"That player isnt connected.");

    new Float:Pos[3];
	GetPlayerPos(sid,Pos[0],Pos[1],Pos[2]);
	SetPlayerPos(sid,Pos[0],Pos[1],Pos[2]+10);

	PlayerPlaySound(playerid,1190,0.0,0.0,0.0);
	PlayerPlaySound(sid,1190,0.0,0.0,0.0);

	new iString[128];
	format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has slapped {FFFFFF}%s",Player[playerid][Name],Player[sid][Name]);
	SendClientMessageToAll(-1,iString);
	LogAdminCommand("slap", playerid, sid);
	return 1;
}


YCMD:explode(playerid,params[], help)
{
	//if(Player[playerid][Level] < 2 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "explode a specific player.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/explode [Player ID]");

	new eid = strval(params);
  	if(!IsPlayerConnected(eid)) return SendErrorMessage(playerid,"That Player Isn't Connected.");

	new Float:Pos[3];
	GetPlayerPos(eid, Pos[0], Pos[1], Pos[2]);
	CreateExplosion(Pos[0], Pos[1], Pos[2], 7, 6.0);

	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has exploded {FFFFFF}%s",Player[playerid][Name],Player[eid][Name]);
	SendClientMessageToAll(-1, iString);
	LogAdminCommand("explode", playerid, eid);
	return 1;
}

YCMD:getpara(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "give you a parachute.");
	    return 1;
	}
	GivePlayerWeapon(playerid, WEAPON_PARACHUTE, 1);
    SendClientMessage(playerid, -1, "{FFFFFF}Parachute given.");
	return 1;
}

YCMD:para(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "get rid of your parachute.");
	    return 1;
	}
	RemovePlayerWeapon(playerid, 46);
    SendClientMessage(playerid, -1, "{FFFFFF}Parachute removed.");
	return 1;
}

YCMD:fixcp(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "re-load the checkpoint for you.");
	    return 1;
	}
	if(RCArena == true) return SendErrorMessage(playerid, "There are no checkpoints in RC arenas!");
	if(GameType == ARENA && !CPInArena) return SendErrorMessage(playerid, "Checkpoint in arenas option is disabled in this server");
	if(Player[playerid][Playing])
	{
        SetTimerEx("SetCPForPlayer", 1000, false, "i", playerid);
	}
	return 1;
}


YCMD:pm(playerid,params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "send a private message to a specific player.");
	    return 1;
	}
    if(Player[playerid][Mute] == true) return SendErrorMessage(playerid,"You are muted.");

	new recieverid, message[144];

	if(sscanf(params,"is",recieverid, message)) return SendUsageMessage(playerid,"/pm [Player ID] [Message]");
	if(!IsPlayerConnected(recieverid)) return SendErrorMessage(playerid,"Player not connected.");
	
	if(Player[recieverid][blockedid] == playerid) return SendErrorMessage(playerid,"That player has blocked PMs from you.");
	if(Player[recieverid][blockedall] == true) return SendErrorMessage(playerid,"That player has blocked PMs from everyone.");
	if(Player[recieverid][Mute] == true) return SendErrorMessage(playerid, "That player is currently muted and can not reply!");
	if(strlen(message) > 103) return SendErrorMessage(playerid, "This message is quite long (max: 103 characters).");
	
	new str[144];
	format(str, sizeof(str), "PM from %s (%d): %s", Player[playerid][Name], playerid, message);
	SendClientMessage(recieverid, 0x90C3D4FF, str);
	
	SendClientMessage(recieverid, -1, ""COL_PRIM"Use {FFFFFF}/r [Message]"COL_PRIM" to reply quicker!");
	Player[recieverid][LastMsgr] = playerid;

	format(str, sizeof(str),"PM to %s (%d): %s", Player[recieverid][Name], recieverid, message);
	SendClientMessage(playerid, 0x79A4B3FF, str);

	PlayerPlaySound(recieverid, 1054, 0, 0, 0);
	return 1;
}

YCMD:r(playerid,params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "reply to someone's private message to you.");
	    return 1;
	}
	
    if(Player[playerid][Mute] == true) return SendErrorMessage(playerid,"You are muted.");
    if(Player[playerid][LastMsgr] == -1) return SendErrorMessage(playerid,"You have not received any private messages since last login.");

	new replytoid = Player[playerid][LastMsgr];
	if(!IsPlayerConnected(replytoid)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[replytoid][blockedid] == playerid) return SendErrorMessage(playerid,"That player has blocked PMs from you.");
	if(Player[replytoid][blockedall] == true) return SendErrorMessage(playerid,"That player has blocked PMs from everyone.");

	if(isnull(params)) return SendUsageMessage(playerid,"/r [Message]");
	if(strlen(params) > 103) return SendErrorMessage(playerid, "This message is quite long (max: 103 characters).");
	
	new str[144];
	format(str, sizeof(str), "PM from %s (%d): %s", Player[playerid][Name], playerid, params);
	SendClientMessage(replytoid, 0x90C3D4FF, str);

	format(str, sizeof(str),"PM to %s (%d): %s", Player[replytoid][Name], replytoid, params);
	SendClientMessage(playerid, 0x79A4B3FF, str);

    Player[replytoid][LastMsgr] = playerid;

	PlayerPlaySound(replytoid,1054,0,0,0);
	return 1;
}

YCMD:blockpm(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "block private messages from a specific player.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/blockpm [Player ID]");

	new pID = strval(params);
  	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

  	Player[playerid][blockedid] = pID;

	new String[128];
  	format(String,sizeof(String),""COL_PRIM"You have blocked PMs from {FFFFFF}%s", Player[pID][Name]);
  	SendClientMessage(playerid,-1,String);

	return 1;
}

YCMD:blockpmall(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "block private messages from everyone.");
	    return 1;
	}
	switch(Player[playerid][blockedall])
	{
	    case false:
	    {
    		Player[playerid][blockedall] = true;
  			SendClientMessage(playerid,-1,""COL_PRIM"You have blocked PMs from everyone. To unblock type /blockpmall one more time!");
	    }
	    case true:
	    {
	    	Player[playerid][blockedall] = false;
  			SendClientMessage(playerid,-1,""COL_PRIM"PMs enabled!");
	    }
	}
	return 1;
}

YCMD:admins(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display online admins.");
	    return 1;
	}
	new iString[356] = '\0';

	foreach(new i : Player) {
	    if(Player[i][Level] > 0) {
	    	format(iString, sizeof(iString), "%s{FFFFFF}%s ({FF3333}%d{FFFFFF})\n", iString, Player[i][Name], Player[i][Level]);
		}
	}

	format(iString, sizeof(iString), "%s\n\n"COL_PRIM"Rcon Admins\n", iString);

	foreach(new i : Player) {
	    if(IsPlayerAdmin(i)) {
	    	format(iString, sizeof(iString), "%s{FFFFFF}%s\n", iString, Player[i][Name]);
		}
	}

	if(strlen(iString) < 2) ShowPlayerDialog(playerid,DIALOG_NO_RESPONSE,DIALOG_STYLE_MSGBOX,"{FFFFFF}Admins Online", "No Admins online.","Ok","");
	else ShowPlayerDialog(playerid,DIALOG_NO_RESPONSE,DIALOG_STYLE_MSGBOX,"{FFFFFF}Admins Online", iString,"Ok","");

	return 1;
}

YCMD:connstats( playerid, params[], help)
{
    //if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher level admin to do that.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "fetch connection statistics of a player.");
	    return 1;
	}
	new pID = INVALID_PLAYER_ID;

	if( sscanf(params, "d", pID) ) return SendUsageMessage(playerid,"/connStats <playerid>");
	if( !IsPlayerConnected(pID) ) return SendErrorMessage(playerid,"** Invalid PlayerID! ");

	new szString[80];
	format(szString, sizeof(szString), "(%d)%s's current connection status: %i.", pID, Player[pID][Name], NetStats_ConnectionStatus(pID) );
	SendClientMessage(playerid, -1, szString);
	return 1;
}

YCMD:serverstats(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "fetch server network statistics.");
	    return 1;
	}
	new stats[450];
	GetNetworkStats(stats, sizeof(stats)); // get the servers networkstats
	ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, "Server Network Stats", stats, "Close", "");
	return 1;
}

YCMD:maxpacket(playerid, params[], help)
{
    //if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set maximum packet-loss limit.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/maxpacket [Maximum Packetloss]");

	new Float:iPacket = floatstr(params);
	if(iPacket <= 0 || iPacket > 10) return SendErrorMessage(playerid,"Packetloss value can be between 0 and 10 maximum.");

	Max_Packetloss = iPacket;

	new iString[144];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %.2f WHERE Option = 'Maximum Packetloss'", iPacket);
    db_free_result(db_query(sqliteconnection, iString));

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed maximum packet-loss to: {FFFFFF}%.2f", Player[playerid][Name], iPacket);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("maxpacket", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:maxping(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "set maximum ping limit.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/maxping [Maximum Ping]");

	new iPacket = strval(params);
	if(iPacket <= 0 || iPacket > 500) return SendErrorMessage(playerid,"Ping limit can be between 0 and 500 maximum.");

	Max_Ping = iPacket;

	new iString[128];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Maximum Ping'", Max_Ping);
    db_free_result(db_query(sqliteconnection, iString));

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed maximum ping limit to: {FFFFFF}%d", Player[playerid][Name], iPacket);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("maxping", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:minfps(playerid, params[], help)
{
    //if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set minimum FPS limit.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/minfps [Minimum FPS]");

	new iPacket = strval(params);
	if(iPacket < 20 || iPacket > 90) return SendErrorMessage(playerid,"FPS limit can be between 20 and 90 maximum.");

	Min_FPS = iPacket;

	new iString[128];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Minimum FPS'", Min_FPS);
    db_free_result(db_query(sqliteconnection, iString));

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed minimum FPS limit to: {FFFFFF}%d", Player[playerid][Name], iPacket);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("minfps", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:allvs(playerid,params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set everyone versus a specific team.");
	    return 1;
	}
    if(Current != -1) return SendErrorMessage(playerid,"Can't use while round is active.");
    if(isnull(params)) return SendUsageMessage(playerid,"/allvs [Team ID | 0 = Attacker, 1 = Defender] [Tag/Name]");

	new toTeam, TempTeamName[6];
	sscanf(params, "is", toTeam, TempTeamName);
    if(toTeam < 0 || toTeam > 1)
		return SendErrorMessage(playerid,"Available teams: 0 for attacker and 1 for defender");

    switch(toTeam)
    {
        case 0:
            toTeam = ATTACKER;
		case 1:
		    toTeam = DEFENDER;
    }

	new oppositeTeam;
	switch(toTeam)
	{
	    case ATTACKER:
	        oppositeTeam = DEFENDER;
		case DEFENDER:
			oppositeTeam = ATTACKER;
	}
	new
		ct[2],
    	MyVehicle = -1,
		Seat;

	ct[0] = 0;
	ct[1] = 0;
	foreach(new i : Player)
	{
		if(Player[i][InDuel] == true || Player[i][IsAFK] || !Player[i][Spawned])
	        continue;

		if(Player[i][Team] != ATTACKER && Player[i][Team] != DEFENDER)
		    continue;

		MyVehicle = -1;
		switch(strfind(Player[i][Name], TempTeamName, true))
		{
		    case -1: // tag not found
		    {
		        if(Player[i][Team] != oppositeTeam)
		        {
		            if(IsPlayerInAnyVehicle(i))
					{
						MyVehicle = GetPlayerVehicleID(i);
						Seat = GetPlayerVehicleSeat(i);
					}
		        	Player[i][Team] = oppositeTeam;
					SwitchTeamFix(i, false, false);
					ct[0] ++;
					if(MyVehicle != -1)
		    			PutPlayerInVehicle(i, MyVehicle, Seat);
	        	}
		    }
			default: // found tag
			{
			    if(Player[i][Team] != toTeam)
		        {
		            if(IsPlayerInAnyVehicle(i))
					{
						MyVehicle = GetPlayerVehicleID(i);
						Seat = GetPlayerVehicleSeat(i);
					}
		        	Player[i][Team] = toTeam;
					SwitchTeamFix(i, false, false);
					ct[1] ++;
					if(MyVehicle != -1)
		    			PutPlayerInVehicle(i, MyVehicle, Seat);
	        	}
			}
		}
	}
    MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~b~~h~~h~all-vs result", sprintf("%d players were swapped to the team you specified whilst %d were swapped to the opposite team", ct[1], ct[0]), 4000);

    new str[128];
    format(str, sizeof(str),"{FFFFFF}%s "COL_PRIM"has changed the teams to {FFFFFF}\"%s\" vs all.", Player[playerid][Name], TempTeamName);
    SendClientMessageToAll(-1, str);
    return 1;
}


YCMD:move(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "teleport a player to another player.");
	    return 1;
	}
    new pID[2];
    if(sscanf(params, "dd", pID[0], pID[1])) return SendUsageMessage(playerid,"/move [PlayerToMove ID] [PlayerToMoveTo ID]");
	if(!IsPlayerConnected(pID[0]) || !IsPlayerConnected(pID[1])) return SendErrorMessage(playerid,"One of the player IDs you used is not connected.");

    new Float:Pos[3];
    GetPlayerPos(pID[1], Pos[0], Pos[1], Pos[2]);

    SetPlayerInterior(pID[0], GetPlayerInterior(pID[1]));
    SetPlayerVirtualWorld(pID[0], GetPlayerVirtualWorld(pID[1]));

    if(GetPlayerState(pID[0]) == 2) {
	    SetVehiclePos(GetPlayerVehicleID(pID[0]), Pos[0]+3, Pos[1], Pos[2]);
		LinkVehicleToInterior(GetPlayerVehicleID(pID[0]),GetPlayerInterior(pID[1]));
	    SetVehicleVirtualWorld(GetPlayerVehicleID(pID[0]),GetPlayerVirtualWorld(pID[1]));
    }
    else SetPlayerPos(pID[0], Pos[0]+2, Pos[1], Pos[2]);

    new iString[144];
    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has moved {FFFFFF}%s "COL_PRIM"to {FFFFFF}%s", Player[playerid][Name], Player[pID[0]][Name], Player[pID[1]][Name]);
    SendClientMessageToAll( -1, iString);
    LogAdminCommand("move", playerid, pID[0]);
    return 1;
}

YCMD:jetpack(playerid,params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "spawn a jetpack.");
	    return 1;
	}
	if(Player[playerid][Playing] == true)
	{
	    #if !defined _league_included
	    return SendErrorMessage(playerid,"Can't use this command in round.");
		#else
		if(LeagueMode)
		{
		    if(!PlayerShop[playerid][SHOP_JETPACK])
		    {
		        return SendErrorMessage(playerid, "You have not purchased a jetpack from league shop (/shop)!");
		    }
		    else
		    {
		        PlayerShop[playerid][SHOP_JETPACK] = false;
		        SetPlayerSpecialAction(playerid, 2);
		        SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has spawned a jetpack from league shop (/shop)", Player[playerid][Name]));
		        return 1;
		    }
		}
		else
		{
		    return SendErrorMessage(playerid,"Can't use this command in round.");
		}
		#endif
	}

    new pID = strval(params);
	if(isnull(params)) pID = playerid;

    if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

	new iString[128];
    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"gave a jetpack to {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);

    SetPlayerSpecialAction(pID, 2);
    return 1;
}

YCMD:deathdiss(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set a disrespect message to be shown for players whom you kill.");
	    return 1;
	}
    if(isnull(params)) return SendUsageMessage(playerid,"/deathdiss [Disrespect Message]");
	if(strlen(params) <= 3) return SendErrorMessage(playerid,"Too short!");
	if(strlen(params) >= 32) return SendErrorMessage(playerid,"Too long!");

	DeathMessageStr[playerid][0] = EOS;
	strcat(DeathMessageStr[playerid], params, 32);

    new iString[128];
	format(iString, sizeof(iString), "UPDATE `Players` SET `DeathMessage` = '%q' WHERE `Name` = '%q'", params, Player[playerid][Name]);
	db_free_result(db_query(sqliteconnection, iString));
	Player[playerid][HasDeathQuote] = true;
	SendClientMessage(playerid, -1, "Death diss message has been changed successfully!");
	return 1;
}

YCMD:fightstyle(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change your fighting style.");
	    return 1;
	}
    if(isnull(params) || !IsNumeric(params))
	{
		SendUsageMessage(playerid,"/fightstyle [FightStyle ID]");
		SendClientMessage(playerid, -1, "0 Normal | 1 Boxing | 2 KungFu | 3 Knee-head | 4 Grab-kick | 5 Elbow-kick");
		return 1;
	}
	new fsID = strval(params);
	if(fsID < 0 || fsID > 5) return SendErrorMessage(playerid,"Invalid FightStyle ID (From 0 to 5 are valid)");

	Player[playerid][FightStyle] = FightStyleIDs[fsID];
	SetPlayerFightingStyle(playerid, Player[playerid][FightStyle]);
	new iString[128];
	format(iString, sizeof(iString), "UPDATE `Players` SET `FightStyle` = '%d' WHERE `Name` = '%q'", Player[playerid][FightStyle], Player[playerid][Name]);
	db_free_result(db_query(sqliteconnection, iString));
	SendClientMessage(playerid, -1, sprintf(""COL_PRIM"FightStyle changed to: {FFFFFF}%s", FightStyleNames[fsID]));
	return 1;
}

YCMD:reloaddb(playerid, params[], help)
{
    //if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "re-load the server database. This might have dangerous results.");
	    return 1;
	}
	if(DatabaseSetToReload == true)
		return SendErrorMessage(playerid, "Database is already set to reload.");
	SetDatabaseToReload(playerid);
	return 1;
}

forward FakePacketRenovationEnd(playerid, Float:fakepacket, bool:message);
public FakePacketRenovationEnd(playerid, Float:fakepacket, bool:message)
{
	if(!Player[playerid][FakePacketRenovation] || !IsPlayerConnected(playerid))
	    return 0;

    Player[playerid][FakePacketRenovation] = false;
    if(message)
    {
        new Float:currPacket = NetStats_PacketLossPercent(playerid);
        if(currPacket >= fakepacket)
        {
            new str[144];
            format(str, sizeof str, ""COL_PRIM"Fake PL renovation on {FFFFFF}%s "COL_PRIM"has failed - Old: {FFFFFF}%.2f "COL_PRIM" | Current: {FFFFFF}%.2f", Player[playerid][Name], fakepacket, currPacket);
            SendClientMessageToAll(-1, str);
		}
        else
        {
			new str[144];
	        format(str, sizeof str, ""COL_PRIM"Fake PL renovation on {FFFFFF}%s "COL_PRIM"has ended - Old: {FFFFFF}%.2f "COL_PRIM" | Current: {FFFFFF}%.2f", Player[playerid][Name], fakepacket, currPacket);
	    	SendClientMessageToAll(-1, str);
  		}
	}
	return 1;
}

YCMD:fakepacket(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "disable packet-loss status check on a player for a specific time.");
	    return 1;
	}
	new pID, interv;
	if(sscanf(params, "id", pID, interv)) return SendUsageMessage(playerid,"/fakepacket [Player ID] [Time in minutes]");
	if(interv <= 0 || interv > 5)  return SendErrorMessage(playerid,"Invalid (Min: 1 | Max: 5).");
	if(Player[pID][FakePacketRenovation])  return SendErrorMessage(playerid,"Player is already on fake packetloss renovation.");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(NetStats_PacketLossPercent(pID) == 0.0) return SendErrorMessage(playerid, "That player has 0.0% packet-loss");

	SetTimerEx("FakePacketRenovationEnd", interv * 60 * 1000, false, "ifb", pID, NetStats_PacketLossPercent(pID), true);
	Player[pID][FakePacketRenovation] = true;

	new str[144];
	format(str, sizeof str, "{FFFFFF}%s "COL_PRIM"has started fake packetloss renovation on {FFFFFF}%s "COL_PRIM" - Interval: {FFFFFF}%d min(s).",Player[playerid][Name], Player[pID][Name], interv);
	SendClientMessageToAll(-1, str);

    LogAdminCommand("fakepacket", playerid, pID);
	return 1;
}

YCMD:alladmins(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display a list of all server admins (offline and online).");
	    return 1;
	}
    new DBResult:res = db_query(sqliteconnection, "SELECT * FROM Players WHERE LEVEL < 6 AND LEVEL > 0 ORDER BY Level DESC");
    if(db_num_rows(res))
    {
		new holdStr[MAX_PLAYER_NAME];
		new bigStr[1024];
		new namesInLine = 0;

		do
		{
		    if(namesInLine == 8)
		    {
		        namesInLine = 0;
		        db_get_field_assoc(res, "Name", holdStr, sizeof(holdStr));
				format(bigStr, sizeof bigStr, "%s\n%s", bigStr, holdStr);
				db_get_field_assoc(res, "Level", holdStr, sizeof(holdStr));
				format(bigStr, sizeof bigStr, "%s [%d], ", bigStr, strval(holdStr));
		    }
		    else
		    {
			    db_get_field_assoc(res, "Name", holdStr, sizeof(holdStr));
				format(bigStr, sizeof bigStr, "%s%s", bigStr, holdStr);
				db_get_field_assoc(res, "Level", holdStr, sizeof(holdStr));
				format(bigStr, sizeof bigStr, "%s [%d], ", bigStr, strval(holdStr));
			}
			namesInLine ++;
		}
		while(db_next_row(res));
		db_free_result(res);
		ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, "All Server Admins", bigStr, "Okay", "");
	}
	else
	{
	    ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, "All Server Admins", "No admins found...", "Okay", "");
	}
	return 1;
}

/* Changes Occurance of COL_PRIM to value contained in ColScheme */
YCMD:chatcolor(playerid,params[], help)
{
	SendErrorMessage(playerid, "This command is not available in this version of gamemode.");
	/*
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change the server main color (of messages and dialogs).");
	    return 1;
	}
	new col[7];

	if( !isnull(params) && !strcmp(params,"01A2F8",true) )
	{
		params[0] = '\0';
	    strcat(params,"01A2F7",7);
	}
	if( strlen(params) != 6 || sscanf(params,"h",col) )
	{
	    SendErrorMessage(playerid,"Please Enter a Valid Hex color code.");
	    new bigString[512];
	    new colorList[] = // enter as much colors here
		{
		    0x01BA2F8FF, 0x0044FFFF, 0xF36164FF
		};
	    strcat( bigString, "\t\tSyntax: /ChatColor ColorCode || E.g: /ChatColor 0044FF\t\t\t\n{EBEBEB}Some Examples:\n",sizeof(bigString) );

		for(new i = 0, tmpint = 0; i < sizeof(colorList); i++)
		{
			tmpint = colorList[i] >> 8 & 0x00FFFFFF;
			format( bigString, sizeof(bigString), "%s{%06x}%06x   ", bigString, tmpint, tmpint );
			if( i == 9 ) strcat( bigString, "\n", sizeof(bigString) );
		}

		strcat( bigString, "\n\nHex Code need to have 6 Digits and can contain only number from 0 - 9 and letters A - F", sizeof(bigString) );
   	    strcat( bigString, "\n\t{01A2F8}You can get some color codes from websites like: Www.ColorPicker.Com \n\t\t{37B6FA}Notice: In-Game Colors might appear different from website.\n", sizeof(bigString) );

		ShowPlayerDialog(playerid,DIALOG_NO_RESPONSE,DIALOG_STYLE_MSGBOX, "Hints for the command.", bigString, "Close", "" );
		return 1;
	}
    //if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 4 or rcon admin.");

	format(ColScheme,10,"{%06x}", col);
	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}Chat Color to "COL_PRIM"%06x", Player[playerid][Name], col );
	SendClientMessageToAll(-1, iString);

	format(iString, sizeof(iString), "UPDATE `Configs` SET `Value` = '%06x' WHERE `Option` = 'ChatColor'", col);
    db_free_result(db_query(sqliteconnection, iString));*/
	return 1;
}


YCMD:themes(playerid, params[], help)
{
    //if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 5 or rcon admin.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change the theme color of your server.");
	    return 1;
	}
    new str[512];
	strcat(str, "White (Background) & Black (Text)\n");
	strcat(str, "Black (Background) & White (Text)\n");
	strcat(str, "White (Background) & Red (Text)\n");
	strcat(str, "Black (Background) & Red (Text)\n");
	strcat(str, "White (Background) & Blue (Text)\n");
	strcat(str, "Black (Background) & Blue (Text)\n");
	strcat(str, "White (Background) & Green (Text)\n");
	strcat(str, "Black (Background) & Green (Text)\n");
	strcat(str, "White (Background) & Purple (Text)\n");
	strcat(str, "Black (Background) & Purple (Text)");

	ShowPlayerDialog(playerid, DIALOG_THEME_CHANGE1, DIALOG_STYLE_LIST, "{0044FF} Theme colour menu", str, "Select", "Cancel");
	return 1;
}

YCMD:defaultskins(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "reset team skins to default.");
	    return 1;
	}
	new iString[128];

	Skin[ATTACKER] = 170;
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Attacker Skin'", 170);
    db_free_result(db_query(sqliteconnection, iString));

	Skin[DEFENDER] = 177;
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Defender Skin'", 177);
    db_free_result(db_query(sqliteconnection, iString));

	Skin[REFEREE] = 51;
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Referee Skin'", 51);
    db_free_result(db_query(sqliteconnection, iString));


	foreach(new i : Player) {
	    if(Player[i][Team] == ATTACKER) {
	        SetPlayerSkin(i, Skin[ATTACKER]);
		}
		if(Player[i][Team] == DEFENDER) {
	        SetPlayerSkin(i, Skin[DEFENDER]);
		}
		if(Player[i][Team] == REFEREE) {
	        SetPlayerSkin(i, Skin[REFEREE]);
		}
	}

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}skins "COL_PRIM"to default.", Player[playerid][Name] );
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("defaultskins", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:teamskin(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change the skin of a team.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/teamskin [Team ID | 0 Attacker | 1 Defender | 2 Referee]");
	if(strval(params) < 0 || strval(params) > 2) return SendErrorMessage(playerid,"Invalid team ID.");
	if(ChangingSkinOfTeam[playerid] != -1) return SendErrorMessage(playerid,"You're already changing team skins.");

	ChangingSkinOfTeam[playerid] = strval(params) + 1;
	switch(ChangingSkinOfTeam[playerid])
	{
	    case ATTACKER:
	    {
	        ShowModelSelectionMenu(playerid, teamskinlist, "Select Attacker Team Skin", 0xFA1E1EBB, 0xFFA8A899, 0xFCCACAAA);
	    }
	    case DEFENDER:
	    {
	        ShowModelSelectionMenu(playerid, teamskinlist, "Select Defender Team Skin", 0x323FF0BB, 0x9097F599, 0xDCDEF7AA);
	    }
	    case REFEREE:
	    {
	        ShowModelSelectionMenu(playerid, teamskinlist, "Select Referee Team Skin", 0xDCF72ABB, 0xEAF79299, 0xEBF2BBAA);
	    }
	    default:
	        ShowModelSelectionMenu(playerid, teamskinlist, "Select Team Skin");
	}
    LogAdminCommand("teamskin", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:setteam(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set the team of a player.");
	    return 1;
	}
	new Params[2];
	if(sscanf(params, "dd", Params[0], Params[1])) return SendUsageMessage(playerid,"/setteam [Player ID] [Team ID | 0 Att | 1 Def | 2 Ref | 3 Att_Sub | 4 Def_Sub]");

	if(Params[1] < 0 || Params[1] > 4) return SendErrorMessage(playerid,"Invalid team ID.");
	if(!IsPlayerConnected(Params[0])) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[Params[0]][Playing] == true) return SendErrorMessage(playerid,"That player is playing.");

	new MyVehicle = -1;
	new Seat;

	if(IsPlayerInAnyVehicle(Params[0])) {
		MyVehicle = GetPlayerVehicleID(Params[0]);
		Seat = GetPlayerVehicleSeat(Params[0]);
	}

	Player[Params[0]][Team] = Params[1]+1;
	SetPlayerSkin(Params[0], Skin[Params[1]+1]);
	ColorFix(Params[0]);

	if(Current != -1)
	{
		ShowTeamBarsForPlayer(Params[0]);
	}

	if(MyVehicle != -1) {
	    PutPlayerInVehicle(Params[0], MyVehicle, Seat);
	}
	SwitchTeamFix(Params[0], false, true);

    new iString[150];
	format(iString, sizeof(iString), "%sKills %s%d~n~%sDamage %s%d~n~%sTotal Dmg %s%d", MAIN_TEXT_COLOUR, TDC[Player[Params[0]][Team]], Player[Params[0]][RoundKills], MAIN_TEXT_COLOUR, TDC[Player[Params[0]][Team]], Player[Params[0]][RoundDamage], MAIN_TEXT_COLOUR, TDC[Player[Params[0]][Team]], Player[Params[0]][TotalDamage]);
	PlayerTextDrawSetString(Params[0], RoundKillDmgTDmg[Params[0]], iString);

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has switched {FFFFFF}%s "COL_PRIM"to: {FFFFFF}%s", Player[playerid][Name], Player[Params[0]][Name], TeamName[Params[1]+1]);
	SendClientMessageToAll(-1, iString);
	return 1;
}

YCMD:setscore(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "set the score of a team.");
	    return 1;
	}
	if(!WarMode) return SendErrorMessage(playerid, "Warmode is not enabled.");

	new TeamID, Score;
	if(sscanf(params, "dd", TeamID, Score)) return SendUsageMessage(playerid,"/setscore [Team ID (0 Att | 1 Def)] [Score]");

	if(TeamID < 0 || TeamID > 1) return SendErrorMessage(playerid,"Invalid team ID.");
	if(Score < 0 || Score > 100) return SendErrorMessage(playerid,"Score can only be between 0 and 100.");

	new iString[128];
	if(TeamID == 0) {
		if((Score + TeamScore[DEFENDER]) >= TotalRounds) return SendErrorMessage(playerid,"Attacker plus defender score is bigger than or equal to the total rounds.");
		TeamScore[ATTACKER] = Score;
        format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set attacker team score to: {FFFFFF}%d", Player[playerid][Name], TeamScore[ATTACKER]);
	} else {
   		if((Score + TeamScore[ATTACKER]) >= TotalRounds) return SendErrorMessage(playerid,"Attacker plus defender score is bigger than or equal to the total rounds.");
		TeamScore[DEFENDER] = Score;
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set defender team score to: {FFFFFF}%d", Player[playerid][Name], TeamScore[DEFENDER]);
	}
 	SendClientMessageToAll(-1, iString);

    CurrentRound = TeamScore[ATTACKER] + TeamScore[DEFENDER];

	UpdateTeamScoreTextDraw();

    LogAdminCommand("setscore", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:changepass(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change your user account password (not league account password).");
	    return 1;
	}
	if(Player[playerid][Logged] == false) return SendErrorMessage(playerid,"You must be logged in.");
	if(isnull(params)) return SendUsageMessage(playerid,"/changepass [New Password]");
	if(strlen(params) < 3) return SendErrorMessage(playerid,"Password too short (Minimum 3 characters).");

	new HashPass[140];
	format(HashPass, sizeof(HashPass), "%d", udb_hash(params));

	new iString[356];
	format(iString, sizeof(iString), "UPDATE Players SET Password = '%q' WHERE Name = '%q'", HashPass, Player[playerid][Name]);
    db_free_result(db_query(sqliteconnection, iString));

	format(HashPass, sizeof(HashPass), "Your password is changed to: %s", params);
	SendClientMessage(playerid, -1, HashPass);
	return 1;
}

YCMD:heal(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "restore your health and armour.");
	    return 1;
	}
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't heal while playing.");
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel.");

	SetHP(playerid, 100);
	SetAP(playerid, 100);
	return 1;
}


YCMD:rr(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "restart a round.");
	    return 1;
	}
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Please wait.");

	AllowStartBase = false;
	if(RoundPaused == true)
		TextDrawHideForAll(PauseTD);
    RoundPaused = false;
    RoundUnpausing = false;

	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set the round to restart. Round restarting...", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

 	ResetGunmenuSelections();

	if(GameType == BASE) {
	    BaseStarted = false;
		SetTimerEx("OnBaseStart", 4000, false, "i", Current);
	} else if(GameType == ARENA) {
	    ArenaStarted = false;
		SetTimerEx("OnArenaStart", 4000, false, "i", Current);
	}

	foreach(new i : Player)
	{
	    if(Player[i][OnGunmenu])
	        HidePlayerGunmenu(i);
	    if(CanPlay(i))
		{
			if(Player[i][Spectating] == true) StopSpectate(i);
			Player[i][WasInCP] = false;

			Player[i][WasInBase] = false;
			Player[i][WasInTeam] = NON;
			Player[i][WeaponPicked] = 0;
			Player[i][TimesSpawned] = 0;

			HideDialogs(i);
            DisablePlayerCheckpoint(i);
            RemovePlayerMapIcon(i, 59);

			PlayerTextDrawHide(i, AreaCheckTD[i]);
			PlayerTextDrawHide(i, AreaCheckBG[i]);
			TogglePlayerControllable(i, 0);
			Player[i][ToAddInRound] = true;
		}
	}

	foreach(new i:Player)
	{
		HideRoundStats(i);
	}
    TextDrawHideForAll(EN_CheckPoint);
	return 1;
}

YCMD:aka(playerid, params[], help) {

    if(help)
	{
	    SendCommandHelpMessage(playerid, "fetch AKA data of a player.");
	    return 1;
	}
	new pID;
    if(sscanf(params, "u", pID)) {
        pID = playerid;
    }
    if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");

    new AKAString[256];
	GetPlayerAKA(pID, AKAString, sizeof AKAString);

	new title[39];
	format(title, sizeof(title), ""COL_PRIM"%s's AKA", Player[pID][Name]);
    ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, title, AKAString, "Close", "");
    return 1;
}


YCMD:afk(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "switch to AFK mode.");
	    return 1;
	}
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid, "You cannot switch to AFK mode while playing");
	if(Player[playerid][Spectating] == true) StopSpectate(playerid);
	if(Player[playerid][InDM] == true) QuitDM(playerid);
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use /rq first");

	Player[playerid][Team] = NON;
	SetPlayerColor(playerid, 0xAAAAAAAA);
	TogglePlayerControllable(playerid, 0);
	Player[playerid][IsAFK] = true;

	new iString[64];
 	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set himself to AFK mode.", Player[playerid][Name]);
 	SendClientMessageToAll(-1, iString);
	return 1;
}

YCMD:setafk(playerid, params[], help)
{
    //if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "force someone to go into AFK mode.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/setafk [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][Playing] == true) return SendErrorMessage(playerid, "You cannot switch this player to AFK mode as he's playing");
	if(Player[pID][Spectating] == true) StopSpectate(pID);
	if(Player[pID][InDM] == true) QuitDM(pID);
	if(Player[pID][InDuel] == true) return SendErrorMessage(playerid,"That player is in a duel");

	Player[pID][Team] = NON;
	SetPlayerColor(pID, 0xAAAAAAAA);
	TogglePlayerControllable(pID, 0);
	Player[pID][IsAFK] = true;

	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set {FFFFFF}%s "COL_PRIM"to AFK mode.", Player[playerid][Name], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("setafk", playerid, pID);
	return 1;
}

YCMD:back(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "get you out of AFK mode.");
	    return 1;
	}
	if(Player[playerid][IsAFK] != true)
	    return SendErrorMessage(playerid,"You are not AFK?");
	Player[playerid][Team] = REFEREE;
    TogglePlayerControllable(playerid, 1);
    Player[playerid][IsAFK] = false;
    SetHP(playerid, 100);
	new iString[128];
 	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"is back from AFK mode.", Player[playerid][Name]);
 	SendClientMessageToAll(-1, iString);
	format(iString, sizeof(iString), "%s%s\n%s%s\n%sReferee\n%s%s Sub\n%s%s Sub", TextColor[ATTACKER], TeamName[ATTACKER], TextColor[DEFENDER], TeamName[DEFENDER], TextColor[REFEREE], TextColor[ATTACKER_SUB], TeamName[ATTACKER], TextColor[DEFENDER_SUB], TeamName[DEFENDER]);
	ShowPlayerDialog(playerid, DIALOG_SWITCH_TEAM, DIALOG_STYLE_LIST, "{FFFFFF}Team Selection",iString, "Select", "");
	return 1;
}

YCMD:swap(playerid, params[], help)
{
 	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
 	if(help)
	{
	    SendCommandHelpMessage(playerid, "swap the teams.");
	    return 1;
	}
	if(Current != -1) return SendErrorMessage(playerid,"Can't swap while round is active.");

	SwapTeams();

	new iString[64];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has swapped the teams.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

	return 1;
}

YCMD:balance(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "balance the teams.");
	    return 1;
	}
	if(Current != -1) return SendErrorMessage(playerid,"Can't balance when round is active.");

	BalanceTeams();

	new iString[64];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has balanced the teams.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
	return 1;
}

YCMD:switch(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change your team.");
	    return 1;
	}
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't switch while playing.");
	if(Player[playerid][Spectating] == true) StopSpectate(playerid);

	new iString[128];
	format(iString, sizeof(iString), "%s%s\n%s%s\n%sReferee\n%s%s Sub\n%s%s Sub", TextColor[ATTACKER], TeamName[ATTACKER], TextColor[DEFENDER], TeamName[DEFENDER], TextColor[REFEREE], TextColor[ATTACKER_SUB], TeamName[ATTACKER], TextColor[DEFENDER_SUB], TeamName[DEFENDER]);
	ShowPlayerDialog(playerid, DIALOG_SWITCH_TEAM, DIALOG_STYLE_LIST, "{FFFFFF}Team Selection",iString, "Select", "Exit");
    return 1;
}


YCMD:mainspawn(playerid, params[], help)
{
 	//if(Player[playerid][Level] < 4 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
 	if(help)
	{
	    SendCommandHelpMessage(playerid, "change server main spawn position.");
	    return 1;
	}
	GetPlayerPos(playerid, MainSpawn[0], MainSpawn[1], MainSpawn[2]);
	GetPlayerFacingAngle(playerid, MainSpawn[3]);
	MainInterior = GetPlayerInterior(playerid);

	new iString[128], query[256];
	format(iString, sizeof(iString), "%.0f,%.0f,%.0f,%.0f,%d", MainSpawn[0], MainSpawn[1], MainSpawn[2], MainSpawn[3], MainInterior);
	format(query, sizeof(query), "UPDATE Configs SET Value = '%s' WHERE Option = 'Main Spawn'", iString);
    db_free_result(db_query(sqliteconnection, query));

    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed the main spawn location.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("mainspawn", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:givemenu(playerid, params[], help)
{
 	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
 	if(help)
	{
	    SendCommandHelpMessage(playerid, "show weapon menu to a specific player.");
	    return 1;
	}
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/givemenu [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[pID][Playing] == false) return SendErrorMessage(playerid,"That player isn't playing.");
	if(Player[pID][OnGunmenu] == true) return SendErrorMessage(playerid,"That player is already selecting weapons.");

    new iString[128];
    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has showed {FFFFFF}%s "COL_PRIM"weapon menu.", Player[playerid][Name], Player[pID][Name]);
    SendClientMessageToAll(-1, iString);
	ShowPlayerGunmenu(pID, 0);
	return 1;
}

YCMD:reset(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "reset gunmenu selections.");
	    return 1;
	}
	if(Player[playerid][OnGunmenu])
	{
	    if(Player[playerid][GunmenuStyle] == GUNMENU_STYLE_OBJECT)
	    {
	    	ResetPlayerGunmenu(playerid, true);
		}
		else
		{
			SendErrorMessage(playerid, "This command is available only in gunmenu objects style.");
		}
	}
	else
	    SendErrorMessage(playerid, "You're not selecting weapons from gunmenu");
	return 1;
}

YCMD:gunmenumod(playerid, params[], help)
{
	if(help)
	{
	    SendCommandHelpMessage(playerid, "put you in gunmenu modification mode.");
	    return 1;
	}
    ShowPlayerGunmenuModification(playerid);
	return 1;
}

YCMD:spas(playerid, params[], help)
{
	if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle spas selection in gunmenu.");
	}
	// Find the index of Spas in gunmenu
	new idx = -1;
	for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
	{
	    if(GunmenuData[i][GunID] == WEAPON_SHOTGSPA)
	    {
			idx = i;
			break;
	    }
	}
	if(idx == -1)
	{
	    SendErrorMessage(playerid, "Spas doesn't exist in the gunmenu.");
	    return 1;
	}
	if(GunmenuData[idx][GunLimit] > 0)
	{
	    SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}Spas "COL_PRIM"limit to {FFFFFF}0", Player[playerid][Name]));
		db_free_result(db_query(sqliteconnection, sprintf("UPDATE `Gunmenu` SET `Limit`=0 WHERE `Weapon`=%d", GunmenuData[idx][GunID])));
		GunmenuData[idx][GunLimit] = 0;
        // If there's a round in progress
		if(Current != -1)
		{
		    // Loop through all players who are in round
		    foreach(new i : PlayersInRound)
		    {
		        // The following code checks if this player (i) has this gun (spas)
		        if(GunmenuData[idx][HasGun][i])
		        {
		            // Show them gunmenu
		            ShowPlayerGunmenu(i, 0);
		            SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"was automatically shown the gunmenu because they had Spas.", Player[i][Name]));
		        }
		    }
		}
	}
	else
	{
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}Spas "COL_PRIM"limit to {FFFFFF}1", Player[playerid][Name]));
		db_free_result(db_query(sqliteconnection, sprintf("UPDATE `Gunmenu` SET `Limit`=1 WHERE `Weapon`=%d", GunmenuData[idx][GunID])));
		GunmenuData[idx][GunLimit] = 1;
	}
	return 1;
}

YCMD:melee(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display the melee weapon menu.");
	    return 1;
	}
	if(!MeleeAllowed) return SendErrorMessage(playerid,"Melee weapons menu is disabled.");
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");
	if(Player[playerid][Playing] == false) return SendErrorMessage(playerid,"You are not playing.");
	if(RCArena == true) return SendErrorMessage(playerid, "You cannot get gunmenu in RC arenas");
	if(ElapsedTime <= 30 && Player[playerid][Team] != REFEREE)
	{
	    new iString[128];
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has displayed melee weapons menu (/melee).", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
		ShowPlayerMeleeWeaponsMenu(playerid);
	}
	else
	{
		SendErrorMessage(playerid,"Too late to show yourself melee weapons menu.");
	}
	return 1;
}

YCMD:gunmenu(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display the weapon menu.");
	    return 1;
	}
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");
	if(Player[playerid][Playing] == false) return SendErrorMessage(playerid,"You are not playing.");
	if(RCArena == true) return SendErrorMessage(playerid, "You cannot get gunmenu in RC arenas");
	if(ElapsedTime <= 30 && Player[playerid][Team] != REFEREE)
	{
	    new iString[128];
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has displayed gunmenu (/gunmenu).", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
		ShowPlayerGunmenu(playerid, 0);
	}
	else
	{
		SendErrorMessage(playerid,"Too late to show yourself weapon menu.");
	}
	return 1;
}

YCMD:gunmenustyle(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change your gunmenu style.");
	    return 1;
	}
	if(Player[playerid][OnGunmenu])
		return SendErrorMessage(playerid,"You cannot change style while selecting from gunmenu.");

	new styleStr[7];
	if(sscanf(params, "s", styleStr))
	{
	    return SendUsageMessage(playerid,"/gunmenustyle [dialog / object]");
 	}

    new style;
	if(strcmp(styleStr, "dialog", true) == 0)
		style = GUNMENU_STYLE_DIALOG;
	else if(strcmp(styleStr, "object", true) == 0)
		style = GUNMENU_STYLE_OBJECT;
	else
		return SendUsageMessage(playerid,"/gunmenustyle [dialog / object]");

	Player[playerid][GunmenuStyle] = style;
   	db_free_result(db_query(sqliteconnection, sprintf("UPDATE Players SET GunmenuStyle = %d WHERE Name = '%q'", style, Player[playerid][Name])));
   	SendClientMessage(playerid, -1, sprintf("Changed gunmenu style to: %s", styleStr));
	return 1;
}

YCMD:addall(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "add everyone to the round.");
	    return 1;
	}
	if(Current == -1)
		return SendErrorMessage(playerid,"Round is not active.");
		
	new bool:addDead = strcmp(params, "dead", true) == 0 ? true : false;
	new ct = 0;
	switch(WarMode)
	{
	    case true:
	    {
	        foreach(new i : Player)
			{
			    if(addDead && Player[i][WasInBase])
					continue;
					
				if(Player[i][Playing] == false && Player[i][InDuel] == false && (Player[i][Team] == ATTACKER || Player[i][Team] == DEFENDER))
				{
					switch(GameType)
					{
					    case BASE:
					    {
					        AddPlayerToBase(i);
					    }
						case ARENA:
						{
							AddPlayerToArena(i);
						}
					}
					ct ++;
				}
			}
	    }
	    case false:
	    {
	        foreach(new i : Player)
			{
			    if(addDead && Player[i][WasInBase])
					continue;
					
				if(Player[i][Playing] == false && Player[i][InDuel] == false && (Player[i][Team] == ATTACKER || Player[i][Team] == DEFENDER))
				{
				    Player[i][Team] = GetTeamWithLessPlayers();
				    SwitchTeamFix(i, false, false);
					switch(GameType)
					{
					    case BASE:
					    {
					        AddPlayerToBase(i);
					    }
						case ARENA:
						{
							AddPlayerToArena(i);
						}
					}
					ct ++;
				}
			}
	    }
	}
	if(ct == 0)
	{
	    switch(addDead)
	    {
	        case true:
	        {
	            SendErrorMessage(playerid, "Found no players which could be added to the round!");
	        }
	        case false:
	        {
	            SendErrorMessage(playerid, "No players to add! Did you want to add dead players? Use /addall dead");
	        }
	    }
	}
	else
	{
		if(!addDead)
		{
		    SendUsageMessage(playerid, "to also add players who died, you can type /addall dead");
		}
	    new iString[64];
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has added everyone to the round.", Player[playerid][Name]);
	    SendClientMessageToAll(-1, iString);
  	}
	return 1;
}

YCMD:add(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "add a specific player to the round.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/add [Player ID]");
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][Playing] == true) return SendErrorMessage(playerid,"That player is already playing.");
	if(Player[pID][InDuel] == true) return SendErrorMessage(playerid,"That player is in a duel.");
	if(Player[pID][Team] == ATTACKER || Player[pID][Team] == DEFENDER || Player[pID][Team] == REFEREE) {
	    if(Player[pID][Spectating] == true) StopSpectate(pID);  //no more need to ask players to do /specoff in order to add them
		if(GameType == BASE) AddPlayerToBase(pID);
		else if(GameType == ARENA) AddPlayerToArena(pID);

	    new iString[128];
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has added {FFFFFF}%s "COL_PRIM"to the round.", Player[playerid][Name], Player[pID][Name]);
	    SendClientMessageToAll(-1, iString);

	} else {
	    SendErrorMessage(playerid,"That player must be part of one of the following teams: Attacker, Defender or Referee.");
	}
    LogAdminCommand("add", playerid, pID);
	return 1;
}

YCMD:addme(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "add yourself to the round.");
	    return 1;
	}
	if(Player[playerid][Team] != ATTACKER && Player[playerid][Team] != DEFENDER) return SendErrorMessage(playerid, "You must be either in attacker or defender team");
	if(WarMode == true) return SendErrorMessage(playerid, "Cannot do this when match mode is enabled.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"You're already playing.");
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"You cannot use this command while in a duel.");
	if(ElapsedTime > 20) return SendErrorMessage(playerid, "It's late. You cannot add yourself now.");
	    
    Player[playerid][Team] = GetTeamWithLessPlayers();
 	SwitchTeamFix(playerid, false, false);
	    
    if(Player[playerid][Spectating] == true) StopSpectate(playerid);
	if(GameType == BASE) AddPlayerToBase(playerid);
	else if(GameType == ARENA) AddPlayerToArena(playerid);

    new iString[144];
    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has added himself to the round {FFFFFF}(/addme).", Player[playerid][Name]);
    SendClientMessageToAll(-1, iString);
	return 1;
}

YCMD:readd(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "re-add a player to the round.");
	    return 1;
	}
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");

	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(isnull(params)) return SendUsageMessage(playerid,"/readd [Player ID]");
	if(!IsNumeric(params)) return SendUsageMessage(playerid,"/readd [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][Team] == ATTACKER || Player[pID][Team] == DEFENDER || Player[pID][Team] == REFEREE)
	{
		if(Player[pID][Playing] == true)
		{
		    Player[pID][TotalKills] = Player[pID][TotalKills] - Player[pID][RoundKills];
		    Player[pID][TotalDeaths] = Player[pID][TotalDeaths] - Player[pID][RoundDeaths];
			Player[pID][TotalDamage] = Player[pID][TotalDamage] - Player[pID][RoundDamage];
		}
		DeletePlayerTeamBar(pID);
		if(GameType == BASE)
			AddPlayerToBase(pID);
		else if(GameType == ARENA)
			AddPlayerToArena(pID);

	    new iString[128];
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has re-added {FFFFFF}%s "COL_PRIM"to the round.", Player[playerid][Name], Player[pID][Name]);
	    SendClientMessageToAll(-1, iString);
	    LogAdminCommand("readd", playerid, pID);
	}
	else
	{
    	SendErrorMessage(playerid,"That player must be part of one of the following teams: Attacker, Defender or Referee.");
	}
	return 1;
}

YCMD:rem(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "remove yourself from the round.");
	    return 1;
	}
	if(Player[playerid][Playing] == false) return SendErrorMessage(playerid,"You are not playing.");
	if(ElapsedTime > 60) return SendErrorMessage(playerid,"Too late to remove yourself.");

    new iString[128], HP[2];
    GetHP(playerid, HP[0]);
    GetAP(playerid, HP[1]);

    format(iString, sizeof(iString), "{FFFFFF}%s (%d) "COL_PRIM"removed himself from round. {757575}HP %d | Armour %d", Player[playerid][Name], playerid, HP[0], HP[1]);
    SendClientMessageToAll(-1, iString);

	RemovePlayerFromRound(playerid);
    return 1;
}


YCMD:remove(playerid, params[], help)
{
 	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
 	if(help)
	{
	    SendCommandHelpMessage(playerid, "remove a specific player from the round.");
	    return 1;
	}
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/remove [Player ID]");

	new pID = strval(params);

    new iString[128], HP[2];
    GetHP(pID, HP[0]);
    GetAP(pID, HP[1]);

	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[pID][Playing] == false) return SendErrorMessage(playerid,"That player is not playing.");

    format(iString, sizeof(iString), "{FFFFFF}%s (%d) "COL_PRIM"removed {FFFFFF}%s (%d) "COL_PRIM"from round. {757575}HP %d | Armour %d", Player[playerid][Name], playerid, Player[pID][Name], pID, HP[0], HP[1]);
    SendClientMessageToAll(-1, iString);

	RemovePlayerFromRound(pID);
    LogAdminCommand("remove", playerid, pID);
    return 1;
}


YCMD:end(playerid, params[], help)
{
   	//if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
   	if(help)
	{
	    SendCommandHelpMessage(playerid, "kill the currently active round.");
	    return 1;
	}
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Please Wait.");
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");

	Current = -1;
	#if defined _league_included
	UpdateOnlineMatchesList(WarMode);
	#endif
	if(RoundPaused == true)
		TextDrawHideForAll(PauseTD);

	RoundPaused = false;
	FallProtection = false;
	TeamCapturingCP = NON;
    PlayersInCP = 0;

	PlayersAlive[ATTACKER] = 0;
	PlayersAlive[DEFENDER] = 0;
	
	PlayersDead[ATTACKER] = 0;
	PlayersDead[DEFENDER] = 0;

    RoundUnpausing = false;

	foreach(new i : Player) {

        if(Player[i][InDuel] == true || Player[i][IsAFK] || !Player[i][Spawned])
	        continue;
	        
		Player[i][Playing] = false;
		Player[i][WasInCP] = false;
		if(Player[i][Spectating] == true)
			StopSpectate(i);
		Player[i][WasInBase] = false;
		Player[i][WasInTeam] = NON;
		Player[i][WeaponPicked] = 0;
		Player[i][TimesSpawned] = 0;

		TogglePlayerControllable(i, 0);
		RemovePlayerMapIcon(i, 59);

		SpawnPlayer(i);

		DisablePlayerCheckpoint(i);
		SetPlayerScore(i, 0);
		HideDialogs(i);

		PlayerTextDrawHide(i, AreaCheckTD[i]);
		PlayerTextDrawHide(i, AreaCheckBG[i]);
	}

	foreach(new i:Player)
	{
		HideRoundStats(i);
	}
	TextDrawHideForAll(EN_CheckPoint);

 	ResetGunmenuSelections();

	BaseStarted = false;
	ArenaStarted = false;

    SendRconCommand("mapname Lobby");
	FixGamemodeText();

	new iString[64];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has ended the round.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

	DeleteAllTeamBars();
	DeleteAllDeadBodies();
    GangZoneDestroy(CPZone);
	GangZoneDestroy(ArenaZone);
	ResetTeamLeaders();
    Iter_Clear(PlayersInRound);
    
    if(AutoRoundStarter)
		SetRoundAutoStart(20);
		
    LogAdminCommand("end", playerid, INVALID_PLAYER_ID);
	return 1;
}


YCMD:ban(playerid, params[], help)
{
	//if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "ban a specific player from the server.");
	    return 1;
	}
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Can't ban now. Please wait.");

	new pID, Reason[128], iString[256];
	if(sscanf(params, "ds", pID, Reason)) return SendUsageMessage(playerid,"/ban [Player ID] [Reason]");

	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(strlen(Reason) > 128) return SendErrorMessage(playerid,"Reason is too big.");

    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has banned {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name], /*IP,*/ Reason);
	SendClientMessageToAll(-1, iString);

	DontPauseRound = true;

	format(iString, sizeof(iString), "%s - %s", Player[playerid][Name], Reason);
	BanEx(pID, iString);

    LogAdminCommand("ban", playerid, pID);
	return 1;
}

YCMD:unbanip(playerid,params[], help)
{
	//if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "unban a specific IP or a range.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/unbanip [IP]");

	new iString[128];
	format(iString, sizeof(iString), "unbanip %s", params);
	SendRconCommand(iString);
	SendRconCommand("reloadbans");

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unbanned IP: {FFFFFF}%s",Player[playerid][Name], params);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("unbanip", playerid, INVALID_PLAYER_ID);
	return 1;
}

YCMD:kick(playerid, params[], help)
{
	//if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "kick a specific player from the server.");
	    return 1;
	}
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Can't kick now. Please wait.");

	new Params[2][128], iString[180];
	sscanf(params, "ss", Params[0], Params[1]);
	if(isnull(Params[0]) || !IsNumeric(Params[0])) return SendUsageMessage(playerid,"/kick [Player ID] [Reason]");
	new pID = strval(Params[0]);

	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

	new bool:GiveReason;
	if(isnull(Params[1])) GiveReason = false;
	else GiveReason = true;

	if(GiveReason == false) {
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has kicked {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}No Reason Given", Player[playerid][Name], Player[pID][Name]);
		SendClientMessageToAll(-1, iString);
	} else {
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has kicked {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name], Params[1]);
		SendClientMessageToAll(-1, iString);
	}

    DontPauseRound = true;
    SetTimerEx("OnPlayerKicked", 500, false, "i", pID);
    LogAdminCommand("kick", playerid, pID);
	return 1;
}


YCMD:healall(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "restore everyone's health.");
	    return 1;
	}
	if(Current == -1) return SendErrorMessage(playerid,"There is no active round.");

	foreach(new i : Player) {
	    if(Player[i][Playing] == true) {
	        SetHP(i, RoundHP);
		}
	}

	new iString[64];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has healed everyone.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

	return 1;
}

YCMD:armourall(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "restore everyone's armour.");
	    return 1;
	}
	if(Current == -1) return SendErrorMessage(playerid,"There is no active round.");

	foreach(new i : Player) {
	    if(Player[i][Playing] == true) {
	        SetAP(i, 100);
		}
	}
	new iString[64];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has armoured everyone.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
	return 1;
}

YCMD:sethp(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set a player health to a specific value.");
	    return 1;
	}
	new pID, Amount;
	if(sscanf(params, "id", pID, Amount)) return SendUsageMessage(playerid,"/sethp [Player ID] [Amount]");
	if(Amount < 0 || Amount > 100)  return SendErrorMessage(playerid,"Invalid amount.");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

	SetHP(pID, Amount);


	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set {FFFFFF}%s's "COL_PRIM"HP to: {FFFFFF}%d", Player[playerid][Name], Player[pID][Name], Amount);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("sethp", playerid, pID);
	return 1;
}

YCMD:setarmour(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set a player armour to a specific value.");
	    return 1;
	}
	new pID, Amount;
	if(sscanf(params, "id", pID, Amount)) return SendUsageMessage(playerid,"/setarmour [Player ID] [Amount]");
	if(Amount < 0 || Amount > 100)  return SendErrorMessage(playerid,"Invalid amount.");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

	SetAP(pID, Amount);

	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set {FFFFFF}%s's "COL_PRIM"Armour to: {FFFFFF}%d", Player[playerid][Name], Player[pID][Name], Amount);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("setarmour", playerid, pID);
	return 1;
}

YCMD:pause(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "pause the currently active round.");
	    return 1;
	}
	if(Current == -1) return SendErrorMessage(playerid,"There is no active round.");

	new iString[144];
	if(RoundPaused == false)
	{
	    if(RoundUnpausing == true)
			return SendErrorMessage(playerid,"Round is unpausing, please wait.");

		PausePressed = GetTickCount();

	    PauseRound();

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has paused the current round.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
	}
	else
	{
		if((GetTickCount() - PausePressed) < 3000)
			return SendErrorMessage(playerid,"Please Wait.");
		if(RoundUnpausing == true)
			return 1;


		PauseCountdown = 4;
	    UnpauseRound();

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unpaused the current round.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
	}

	return 1;
}

YCMD:unpause(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "resume the currently active round.");
	    return 1;
	}
	if(RoundUnpausing == true) return SendErrorMessage(playerid,"Round is already unpausing.");
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(RoundPaused == false) return SendErrorMessage(playerid,"Round is not paused.");

	PauseCountdown = 4;
	UnpauseRound();

	new iString[144];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unpaused the current round.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
	return 1;
}

YCMD:showagain(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display round or match results.");
	    return 1;
	}
    ShowEndRoundTextDraw(playerid);
    return 1;
}

YCMD:match(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You Need To Be An Admin.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle match mode.");
	    return 1;
	}
	EnableMatchInterface(playerid);
	return 1;
}

YCMD:goto(playerid,params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You Need To Be An Admin.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "teleport you to a player.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/goto [Player ID]");
	new gid = strval(params);

	if(!IsPlayerConnected(gid) || gid == INVALID_PLAYER_ID) return SendErrorMessage(playerid,"Player isn't connected.");
	if(gid == playerid) return SendErrorMessage(playerid,"Can't go to yourself.");
	new Float:x, Float:y, Float:z;
	GetPlayerPos(gid,x,y,z);
	SetPlayerInterior(playerid,GetPlayerInterior(gid));
	SetPlayerVirtualWorld(playerid,GetPlayerVirtualWorld(gid));

	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
	    SetVehiclePos(GetPlayerVehicleID(playerid),x+2,y,z);
		LinkVehicleToInterior(GetPlayerVehicleID(playerid),GetPlayerInterior(gid));
	    SetVehicleVirtualWorld(GetPlayerVehicleID(playerid),GetPlayerVirtualWorld(gid));
	}
	else SetPlayerPos(playerid,x+1,y,z);

	new tstr[128];
	format(tstr,180,"{FFFFFF}%s "COL_PRIM"has teleported to {FFFFFF}%s",Player[playerid][Name],Player[gid][Name]);
	SendClientMessageToAll(-1,tstr);
    LogAdminCommand("goto", playerid, gid);
	return 1;
}

YCMD:get(playerid,params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You Need To Be An Admin.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "teleport a player to you.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/get [Player ID]");
	new gid = strval(params);

	if(!IsPlayerConnected(gid) || gid == INVALID_PLAYER_ID) return SendErrorMessage(playerid,"Player isn't connected.");
	if(gid == playerid) return SendErrorMessage(playerid,"Can't get yourself.");

	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid,x,y,z);

	if(GetPlayerState(gid) == PLAYER_STATE_DRIVER) {
	    SetVehiclePos(GetPlayerVehicleID(gid),x+2,y,z);
		LinkVehicleToInterior(GetPlayerVehicleID(gid),GetPlayerInterior(playerid));
	    SetVehicleVirtualWorld(GetPlayerVehicleID(gid),GetPlayerVirtualWorld(playerid));
	}
	else SetPlayerPos(gid,x+1,y,z);

	SetPlayerInterior(gid,GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(gid,GetPlayerVirtualWorld(playerid));

	new iString[128];
	format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has teleported {FFFFFF}%s "COL_PRIM"to himself.",Player[playerid][Name],Player[gid][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("get", playerid, gid);
	return 1;
}


YCMD:spec(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "enable you to spectate someone.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/spec [Player ID]");
	new specid = strval(params);
	if(!IsPlayerConnected(specid)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(specid == playerid) return SendErrorMessage(playerid,"Can't spectate yourself.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't spectate while you are playing.");
	if(Player[specid][Spectating] == true) return SendErrorMessage(playerid,"That player is spectating someone else.");
	if(GetPlayerState(specid) != 1 && GetPlayerState(specid) != 2 && GetPlayerState(specid) != 3) return SendErrorMessage(playerid,"That player is not spawned.");
	if(Current != -1 && Player[playerid][Team] != REFEREE && !IsTeamTheSame(Player[specid][Team], Player[playerid][Team])) return SendErrorMessage(playerid,"You can only spectate your own team.");
    if(Iter_Count(PlayerSpectators[specid]) == MAX_PLAYER_SPECTATORS)

	if(Player[playerid][InDM] == true) {
	    Player[playerid][InDM] = false;
		Player[playerid][DMReadd] = 0;
	}

	SpectatePlayer(playerid, specid);
	return 1;
}

YCMD:specoff(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "turn off spectate mode.");
	    return 1;
	}
	if(Player[playerid][Spectating] == true || noclipdata[playerid][FlyMode] == true)
	{
 		StopSpectate(playerid);
		return 1;
	}
	else
	{
 		SendClientMessage(playerid,-1,"{FFFFFF}Error: "COL_PRIM"You are not spectating anyone.");
	}
	return 1;
}

YCMD:vc(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change your vehicle paint.");
	    return 1;
	}
	new color1, color2;
    if(sscanf(params, "ii", color1, color2))
	{
		return SendUsageMessage(playerid, "/vc [colour1] [colour2]");
	}
	if(!GetPlayerVehicleID(playerid))
	{
		return SendErrorMessage(playerid, "You are not in any vehicle!");
	}
	if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
	{
	    return SendErrorMessage(playerid, "You have to be the driver!");
	}
	ChangeVehicleColor(GetPlayerVehicleID(playerid), color1, color2);
    return 1;
}

YCMD:vr(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "repair your vehicle.");
	    return 1;
	}
    if(!IsPlayerInAnyVehicle(playerid))
		return SendErrorMessage(playerid, "You aren't in any vehicle");

	new Float:Pos[3];
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);

	if(Player[playerid][Playing] == true)
	{
		if(Pos[0] > BAttackerSpawn[Current][0] + 150 || Pos[0] < BAttackerSpawn[Current][0] - 150 || Pos[1] > BAttackerSpawn[Current][1] + 150 || Pos[1] < BAttackerSpawn[Current][1] - 150)
		{
			return SendErrorMessage(playerid,"You are too far from attacker spawn."); //If attacker is too far away from his spawn.
		}
	}
	RepairVehicle(GetPlayerVehicleID(playerid));
    SendClientMessage(playerid, -1, "Vehicle repaired.");
    return 1;
}



YCMD:acar(playerid, params[], help)
{
	////if(Player[playerid][Level] < 4 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher level admin to do that.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "spawn a car as an administrator (including blocked vehicles).");
	    return 1;
	}
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't use this command in rounds");
	if(isnull(params)) return SendUsageMessage(playerid,"/acar [Vehicle Name]");
	if(Player[playerid][Spectating] == true) return 1;
    if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel.");
	if(Player[playerid][Playing] == true && Player[playerid][TimesSpawned] >= 3) return SendErrorMessage(playerid,"You have spawned the maximum number of vehicles.");
	if(IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendErrorMessage(playerid,"Can't spawn a vehicle while you are not the driver.");

	new veh;

	if(IsNumeric(params))
	    veh = strval(params);
	else
		veh = GetVehicleModelID(params);
    if(veh < 400 || veh > 611) return SendErrorMessage(playerid,"Invalid Vehicle Name."); //In samp there is no vehile with ID below 400 or above 611

	if(Player[playerid][Playing] == false) {
		if(IsPlayerInAnyVehicle(playerid)) {
			RemovePlayerFromVehicle(playerid);
			DestroyVehicle(GetPlayerVehicleID(playerid));
			Player[playerid][LastVehicle] = -1;
		}

		if(Player[playerid][LastVehicle] != -1) {
			DestroyVehicle(Player[playerid][LastVehicle]);
			Player[playerid][LastVehicle] = -1;
		}
	}

	new Float:Pos[4];
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	GetPlayerFacingAngle(playerid, Pos[3]);

	if(IsPlayerInAnyVehicle(playerid)) {
		DestroyVehicle(GetPlayerVehicleID(playerid)); //If you are already in a vehicle and use /car, it will destroy that vehicle first and spawn the new one.
	}

 	new MyVehicle = CreateVehicle(veh, Pos[0], Pos[1], Pos[2], Pos[3], -1, -1, -1); //Creates the specific vehicle u were looking for (veh).

	new plate[MAX_PLAYER_NAME];
	format(plate, sizeof(plate), "%s", Player[playerid][NameWithoutTag]);
    SetVehicleNumberPlate(MyVehicle, plate);
    SetVehicleToRespawn(MyVehicle);

    LinkVehicleToInterior(MyVehicle, GetPlayerInterior(playerid)); //Links vehicle interior to the current player interior.
	SetVehicleVirtualWorld(MyVehicle, GetPlayerVirtualWorld(playerid)); //Sets vehicle virtual world the the current virtual world of the player.
	PutPlayerInVehicle(playerid, MyVehicle, 0); //Puts player in the driver seat.

	if(Player[playerid][Playing] == false) Player[playerid][LastVehicle] = GetPlayerVehicleID(playerid);
	else Player[playerid][TimesSpawned] ++;

    switch(veh)
	{
	    case 560: // Sultan mods (most spawned car)
	    {
	        for(new i = 1026; i <= 1033; i++)
			{
	            AddVehicleComponent(MyVehicle, i);
			}
			AddVehicleComponent(MyVehicle, 1138);
	  		AddVehicleComponent(MyVehicle, 1141);
		}
		case 565: // Flash mods
		{
		    for(new i = 1045; i <= 1054; i++)
			{
		        AddVehicleComponent(MyVehicle, i);
			}
		}
		case 535: // Slamvan
		{
		    for(new i = 1110; i <= 1122; i++)
			{
		        AddVehicleComponent(MyVehicle, i);
			}
		}
	}
	AddVehicleComponent(MyVehicle, 1025); // Offroad wheels
	AddVehicleComponent(MyVehicle, 1087); // Hydraulics

	new iString[128];
   	format(iString, sizeof(iString), "%s%s{FFFFFF} has spawned a(n) %s%s {FFFFFF}as admin",TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[playerid][Team]], aVehicleNames[veh-400]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("acar", playerid, INVALID_PLAYER_ID);
	return 1;
}


YCMD:v(playerid, params[], help)
{
	if(help)
	{
	    SendCommandHelpMessage(playerid, "spawn a vehicle.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/v [Vehicle name or ID]");
	if(Player[playerid][Spectating] == true) return 1;
	if(RoundPaused == true && Player[playerid][Playing] == true) return 1;
	if(Player[playerid][InDM] == true) return SendErrorMessage(playerid,"You can't spawn vehicle in DM.");
    if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel.");
	if(Player[playerid][Playing] == true && Player[playerid][TimesSpawned] >= 3) return SendErrorMessage(playerid,"You have spawned the maximum number of vehicles.");
	if(IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendErrorMessage(playerid,"Can't spawn a vehicle while you are not the driver.");

   	new veh;

	if(IsNumeric(params))
	    veh = strval(params);
	else
		veh = GetVehicleModelID(params);

    if(veh < 400 || veh > 611) return SendErrorMessage(playerid,"Invalid Vehicle Name."); //In samp there is no vehile with ID below 400 or above 611

	//Block some vehiles that u don't like e.g. Tank, hunter. It wil be annoying in lobby. To search for more vehicle IDs try samp wiki.
	if(veh == 407 || veh == 425 || veh == 430 || veh == 432 || veh == 435 || veh == 441 || veh == 447 || veh == 449) return SendErrorMessage(playerid,"This vehicle is blocked.");
	if(veh == 450 || veh == 464 || veh == 465 || veh == 476 || veh == 501 || veh == 512 || veh == 520 || veh == 537) return SendErrorMessage(playerid,"This vehicle is blocked.");
	if(veh == 538 || veh == 564 || veh == 569 || veh == 570 || veh == 577 || veh == 584 || veh == 590 || veh == 591) return SendErrorMessage(playerid,"This vehicle is blocked.");
	if(veh == 592 || veh == 594 || veh == 601 || veh == 606 || veh == 607 || veh == 608 || veh == 610 || veh == 611) return SendErrorMessage(playerid,"This vehicle is blocked.");

//	Allowed vehicles:	472=Coastguard	544=Firetruck LA	553=Nevada	595=Launch

	new Float:Pos[4];
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	GetPlayerFacingAngle(playerid, Pos[3]);

	if(Player[playerid][Playing] == true) {
		if(Player[playerid][Team] == DEFENDER || Player[playerid][Team] == REFEREE) return SendErrorMessage(playerid,"Only attackers can spawn vehicle.");
        if(BInterior[Current] != 0) return SendErrorMessage(playerid,"You can't spawn vehicle in interior base.");
		if(Pos[0] > BAttackerSpawn[Current][0] + 100 || Pos[0] < BAttackerSpawn[Current][0] - 100 || Pos[1] > BAttackerSpawn[Current][1] + 100 || Pos[1] < BAttackerSpawn[Current][1] - 100) {
			return SendErrorMessage(playerid,"You are too far from attacker spawn."); //If attacker is too far away from his spawn.
		}
	}

	if(IsPlayerInAnyVehicle(playerid)) {
		Player[playerid][LastVehicle] = -1;
		DestroyVehicle(GetPlayerVehicleID(playerid)); //If you are already in a vehicle and use /car, it will destroy that vehicle first and spawn the new one.
	}

	if(Player[playerid][Playing] == false) {
		if(Player[playerid][LastVehicle] != -1) {

		    new bool:InVehicle = false;
		    foreach(new i : Player) {
		    	if(i != playerid && IsPlayerInVehicle(i, Player[playerid][LastVehicle])) {
			        InVehicle = true;
				}
			}

			if(InVehicle == false) {
				DestroyVehicle(Player[playerid][LastVehicle]);
			}

			Player[playerid][LastVehicle] = -1;
		}
	}
    new MyVehicle = CreateVehicle(veh, Pos[0], Pos[1], Pos[2], Pos[3], -1, -1, -1); //Creates the specific vehicle u were looking for (veh).
    new plate[MAX_PLAYER_NAME];
	format(plate, sizeof(plate), "%s", Player[playerid][NameWithoutTag]);
	SetVehicleNumberPlate(MyVehicle, plate);
    LinkVehicleToInterior(MyVehicle, GetPlayerInterior(playerid)); //Links vehicle interior to the current player interior.
	SetVehicleVirtualWorld(MyVehicle, GetPlayerVirtualWorld(playerid)); //Sets vehicle virtual world the the current virtual world of the player.
	PutPlayerInVehicle(playerid, MyVehicle, 0); //Puts player in the driver seat.

	if(Player[playerid][Playing] == false) Player[playerid][LastVehicle] = GetPlayerVehicleID(playerid);
	else Player[playerid][TimesSpawned] ++;


	switch(veh)
	{
	    case 560: // Sultan mods (most spawned car)
	    {
	        for(new i = 1026; i <= 1033; i++)
			{
	            AddVehicleComponent(MyVehicle, i);
			}
			AddVehicleComponent(MyVehicle, 1138);
	  		AddVehicleComponent(MyVehicle, 1141);
		}
		case 565: // Flash mods
		{
		    for(new i = 1045; i <= 1054; i++)
			{
		        AddVehicleComponent(MyVehicle, i);
			}
		}
		case 535: // Slamvan
		{
		    for(new i = 1110; i <= 1122; i++)
			{
		        AddVehicleComponent(MyVehicle, i);
			}
		}
	}
	AddVehicleComponent(MyVehicle, 1025); // Offroad wheels
	AddVehicleComponent(MyVehicle, 1087); // Hydraulics

	if(Player[playerid][Playing] == true) {
		new iString[84];
		format(iString, sizeof(iString), "%s%s{FFFFFF} has spawned a(n) %s%s",TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[playerid][Team]], aVehicleNames[veh-400]);

		foreach(new i : Player)
		{
    		if(IsTeamTheSame(Player[i][Team], Player[playerid][Team]))
				SendClientMessage(i, -1, iString);
		}
	}
	return 1;
}

YCMD:ra(playerid,params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a random arena.");
	    return 1;
	}
    CallLocalFunction("OnPlayerCommandText", "ds", playerid, "/random arena");
	return 1;
}

YCMD:rb(playerid,params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "start a random base.");
	    return 1;
	}
    CallLocalFunction("OnPlayerCommandText", "ds", playerid, "/random base");
	return 1;
}

YCMD:random(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "start a random round.");
	    return 1;
	}
	if(Current != -1) return SendErrorMessage(playerid,"A round is in progress, please wait for it to end.");
	if(AllowStartBase == false)	return SendErrorMessage(playerid,"Please wait.");

	if(isnull(params) || IsNumeric(params))
		return SendUsageMessage(playerid,"/random [base | arena]");

	if(strcmp(params, "base", true) == 0)
	{
	    new BaseID = DetermineRandomRound(2, false, BASE);

		AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		SetTimerEx("OnBaseStart", 4000, false, "i", BaseID);

        new iString[144];
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[BaseID], BaseID);
		SendClientMessageToAll(-1, iString);
	}
	else if(strcmp(params, "arena", true) == 0)
	{
		new ArenaID = DetermineRandomRound(2, false, ARENA);

		AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		SetTimerEx("OnArenaStart", 4000, false, "i", ArenaID);

        new iString[144];
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
		SendClientMessageToAll(-1, iString);
	}
	else
		return SendUsageMessage(playerid,"/random [base | arena]");

	foreach(new i : Player) {
	    if(CanPlay(i)) {
	        TogglePlayerControllable(i, 0); // Pause all the players.
			Player[i][ToAddInRound] = true;
		}
	}
	return 1;
}

YCMD:randomint(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "start a random round in an interior.");
	    return 1;
	}
	if(Current != -1) return SendErrorMessage(playerid,"A round is in progress, please wait for it to end.");
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Please wait.");

	if(isnull(params) || IsNumeric(params))
		return SendUsageMessage(playerid,"/randomint [base | arena]");
		
	if(strcmp(params, "base", true) == 0)
	{
	    new BaseID = DetermineRandomRound(1, false, BASE);

		AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		SetTimerEx("OnBaseStart", 4000, false, "i", BaseID);

		new iString[144];
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started interior Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[BaseID], BaseID);
		SendClientMessageToAll(-1, iString);

		GameType = BASE;
	}
	else if(strcmp(params, "arena", true) == 0)
	{
	    new ArenaID = DetermineRandomRound(1, false, ARENA);

		AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		SetTimerEx("OnArenaStart", 4000, false, "i", ArenaID);

        new iString[144];
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started interior Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
		SendClientMessageToAll(-1, iString);
	}
	else
		return SendUsageMessage(playerid,"/randomint [base | arena]");

	foreach(new i : Player) {
	    if(CanPlay(i)) {
	        TogglePlayerControllable(i, 0); // Pause all the players.
	        Player[i][ToAddInRound] = true;
		}
	}
	return 1;
}

YCMD:start(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "start a round.");
	    return 1;
	}
	if(Current != -1) return SendErrorMessage(playerid,"A round is in progress, please wait for it to end.");
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Please wait.");

	new Params[2][64], CommandID;
	sscanf(params, "ss", Params[0], Params[1]);

	if(isnull(Params[0]) || IsNumeric(Params[0])) return
	SendUsageMessage(playerid,"/start [base | arena | rc | last] [ID]");

	if(!strcmp(Params[0], "rc", true))
	{
	    AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		SetTimer("OnRCStart", 2000, false);

		new iString[144];
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started RC Battlefield round (Interior: 72)", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
	}
	else if(!strcmp(Params[0], "last", true))
	{
		if(ServerLastPlayed > -1 && ServerLastPlayedType > -1)
		{
		    if(ServerLastPlayedType == 1)
			{
				new BaseID = ServerLastPlayed;

				if(BaseID > MAX_BASES) return SendErrorMessage(playerid,"The last played base does not exist.");
				if(!BExist[BaseID]) return SendErrorMessage(playerid,"The last played base does not exist.");

				AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
				SetTimerEx("OnBaseStart", 2000, false, "i", BaseID);

                new iString[144];
				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started the last played Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[BaseID], BaseID);
				SendClientMessageToAll(-1, iString);

				GameType = BASE;
				goto skipped;

			}
			else if(ServerLastPlayedType == 0)
			{

				new ArenaID = ServerLastPlayed;

				if(ArenaID > MAX_ARENAS) return SendErrorMessage(playerid,"The last played arena does not exist.");
				if(!AExist[ArenaID]) return SendErrorMessage(playerid,"The last played arena does not exist.");

				GameType = ARENA;

				AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
				SetTimerEx("OnArenaStart", 2000, false, "i", ArenaID);

                new iString[144];
				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started the last played Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
				SendClientMessageToAll(-1, iString);
				goto skipped;
			}
		}
		else
		    return SendErrorMessage(playerid, "No bases/arenas have been played lately!");
	}
	else if(strcmp(Params[0], "base", true) == 0) CommandID = 1;
	else if(strcmp(Params[0], "arena", true) == 0) CommandID = 2;
	else return
	SendUsageMessage(playerid,"/start [base | arena | rc | last] [ID]");

	if(!IsNumeric(Params[1])) return SendErrorMessage(playerid,"Base/Arena ID can only be numerical.");

	if(CommandID == 1) {
		new BaseID = strval(Params[1]);

		if(BaseID > MAX_BASES) return SendErrorMessage(playerid,"That base does not exist.");
		if(!BExist[BaseID]) return SendErrorMessage(playerid,"That base does not exist.");

		AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		SetTimerEx("OnBaseStart", 2000, false, "i", BaseID);

        new iString[144];
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[BaseID], BaseID);
		SendClientMessageToAll(-1, iString);

	} else if(CommandID == 2) {

		new ArenaID = strval(Params[1]);

		if(ArenaID > MAX_ARENAS) return SendErrorMessage(playerid,"That arena does not exist.");
		if(!AExist[ArenaID]) return SendErrorMessage(playerid,"That arena does not exist.");

		AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		SetTimerEx("OnArenaStart", 2000, false, "i", ArenaID);

        new iString[144];
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
		SendClientMessageToAll(-1, iString);
	}
	skipped:

	foreach(new i : Player) {
	    if(CanPlay(i)) {
	        TogglePlayerControllable(i, 0); // Pause all the players.
			Player[i][ToAddInRound] = true;
		}
	}

	return 1;
}

YCMD:sync(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "re-sync you (restore stamina and other stuff).");
	    return 1;
	}
	SyncPlayer(playerid);
	return 1;
}

YCMD:setlevel(playerid, params[], help)
{
	//if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 5 or rcon admin.");
	if(help)
	{
	    SendCommandHelpMessage(playerid, "change the level of a player.");
	    return 1;
	}
	new GiveID, LEVEL;
	if(sscanf(params, "id", GiveID, LEVEL)) return SendUsageMessage(playerid,"/setlevel [Player ID] [Level]");

	if(!IsPlayerConnected(GiveID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[GiveID][Logged] == false) return SendErrorMessage(playerid,"That player is not logged in.");
	if(LEVEL < 0 || LEVEL > 5) return SendErrorMessage(playerid,"Invalid level.");
	if(Player[GiveID][Level] == LEVEL) return SendErrorMessage(playerid,"That player is already this level.");

	if(Player[GiveID][Level] == 0)
	{
	    // Previous level was 0. This means it's a new admin. Guide them.
	    SendClientMessage(GiveID, -1, ""COL_PRIM"Looks like you're a new admin. Type {FFFFFF}/acmds "COL_PRIM" to see a list of admin commands!");
	}

	new iString[128];

	format(iString, sizeof(iString), "UPDATE Players SET Level = %d WHERE Name = '%q' AND Level != %d", LEVEL, Player[GiveID][Name], LEVEL);
    db_free_result(db_query(sqliteconnection, iString));

	Player[GiveID][Level] = LEVEL;
	UpdatePlayerAdminGroup(GiveID);

	format(iString,sizeof(iString),"{FFFFFF}\"%s\" "COL_PRIM"has set {FFFFFF}\"%s\"'s "COL_PRIM"level to: {FFFFFF}%d", Player[playerid][Name], Player[GiveID][Name], LEVEL);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("setlevel", playerid, GiveID);
	return 1;
}

YCMD:weather(playerid,params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change your weather.");
	    return 1;
	}
    if(isnull(params)) return SendUsageMessage(playerid,"/weather [ID]");
	if(!IsNumeric(params)) return SendErrorMessage(playerid,"You need to put a number for weather id.");

	new myweather;
	myweather = strval(params);
	if(myweather < 0 || myweather > WeatherLimit) return SendErrorMessage(playerid,"Invalid weather ID.");

	SetPlayerWeather(playerid, myweather);
    Player[playerid][Weather] = myweather;

    new iString[128];


	format(iString, sizeof(iString), "UPDATE Players SET Weather = %d WHERE Name = '%q'", myweather, Player[playerid][Name]);
    db_free_result(db_query(sqliteconnection, iString));

    format(iString, sizeof(iString), "{FFFFFF}Weather changed to: %d", myweather);
    SendClientMessage(playerid, -1, iString);

    return 1;
}

YCMD:testsound(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "test a sound ID.");
	    return 1;
	}
 	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/testsound [Sound ID]");

	new Val = strval(params);
	if(!IsValidSound(Val)) return SendErrorMessage(playerid,"This sound ID is not valid. Type 'samp sound id' on Google for more.");

	PlayerPlaySound(playerid, Val, 0, 0, 0);
	return 1;
}

YCMD:sound(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change your sound hit ID.");
	    return 1;
	}
	new Option[16], Value[64], CommandID;
	if(sscanf(params, "sz",Option, Value))
	{
	    SendUsageMessage(playerid,"/sound [hit | gethit] [Sound ID | default]");
	    SendClientMessage(playerid, -1, "Use /testsound to test a sound ID before using it. Type 'samp sound id' on Google for more.");
	    return 1;
	}

	if(strcmp(Option, "hit", true) == 0) CommandID = 1;
	else if(strcmp(Option, "gethit", true) == 0) CommandID = 2;
	else
	{
	    SendUsageMessage(playerid,"/sound [hit | gethit] [Sound ID | default]");
	    SendClientMessage(playerid, -1, "Use /testsound to test a sound ID before using it. Type 'samp sound id' on Google for more.");
	    return 1;
	}

	new iString[128];
	switch(CommandID)
	{
	    case 1:
		{
			if(isnull(Value)) return SendUsageMessage(playerid,"/sound [hit] [Sound ID | default]");
	        if(!IsNumeric(Value))
			{
	            if(strcmp(Value, "default", true) == 0)
				{
	                Player[playerid][HitSound] = 17802;
				}
				else
				{
				    SendUsageMessage(playerid,"/sound [hit | gethit] [Sound ID | default]");
				    SendClientMessage(playerid, -1, "Use /testsound to test a sound ID before using it. Type 'samp sound id' on Google for more.");
				    return 1;
				}
			}
		 	else
			{
			    new Val = strval(Value);
			    if(!IsValidSound(Val)) return SendErrorMessage(playerid,"This sound ID is not valid. Type 'samp sound id' on Google for more.");

			    Player[playerid][HitSound] = Val;
			}
			format(iString, sizeof(iString), "UPDATE Players SET HitSound = %d WHERE Name = '%q'", Player[playerid][HitSound], Player[playerid][Name]);
		    db_free_result(db_query(sqliteconnection, iString));

			PlayerPlaySound(playerid, Player[playerid][HitSound], 0, 0, 0);
	    }
		case 2:
		{
	        if(isnull(Value)) 
			{
			    SendUsageMessage(playerid,"/sound [hit | gethit] [Sound ID | default]");
			    SendClientMessage(playerid, -1, "Use /testsound to test a sound ID before using it. Type 'samp sound id' on Google for more.");
			    return 1;
			}
	        if(!IsNumeric(Value))
			{
	            if(strcmp(Value, "default", true) == 0)
				{
	                Player[playerid][GetHitSound] = 1131;
				}
				else
				{
				    SendUsageMessage(playerid,"/sound [hit | gethit] [Sound ID | default]");
				    SendClientMessage(playerid, -1, "Use /testsound to test a sound ID before using it. Type 'samp sound id' on Google for more.");
				    return 1;
				}
			}
			else
			{
			    new Val = strval(Value);
			    if(!IsValidSound(Val)) return SendErrorMessage(playerid,"This sound ID is not valid. Type 'samp sound id' on Google for more.");

			    Player[playerid][GetHitSound] = Val;
			}
			format(iString, sizeof(iString), "UPDATE Players SET GetHitSound = %d WHERE Name = '%q'", Player[playerid][GetHitSound], Player[playerid][Name]);
		    db_free_result(db_query(sqliteconnection, iString));

			PlayerPlaySound(playerid, Player[playerid][GetHitSound], 0, 0, 0);
	    }
	}


	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed his {FFFFFF}%s "COL_PRIM"to {FFFFFF}ID: %d", Player[playerid][Name], (CommandID == 1 ? ("Hit Sound") : ("Get Hit Sound")), (CommandID == 1 ? Player[playerid][HitSound] : Player[playerid][GetHitSound]));
	SendClientMessageToAll(-1, iString);
	return 1;
}

YCMD:time(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change your day time.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/time [Hour]");
	if(!IsNumeric(params)) return SendErrorMessage(playerid,"You need to put a number for weather id.");
    if(Player[playerid][Logged] == false) return SendErrorMessage(playerid,"You need to log in.");

	new mytime;
	mytime = strval(params);
	if(mytime < 0 || mytime > TimeLimit) return SendErrorMessage(playerid,"Invalid time.");

	SetPlayerTime(playerid, mytime, 0);
	Player[playerid][Time] = mytime;

	new iString[128];

	format(iString, sizeof(iString), "UPDATE Players SET Time = %d WHERE Name = '%q'", mytime, Player[playerid][Name]);
    db_free_result(db_query(sqliteconnection, iString));

    format(iString, sizeof(iString), "{FFFFFF}Time changed to: %d", mytime);
    SendClientMessage(playerid, -1, iString);
    return 1;
}

YCMD:dm(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "teleport you to a deathmatch arena.");
	    return 1;
	}
	if(isnull(params)) return SendUsageMessage(playerid,"/dm [DM ID]");
	if(!IsNumeric(params)) return SendErrorMessage(playerid,"DM id can only be numeric.");
	if(Player[playerid][Playing] == true) return 1;

	new DMID = strval(params);

	// Here I also added '=' after '>' so that if the DMID was Bigger than or Equal to MAX_DMS then you get that error message.
	// Without this '=' (equal sign) if you type /dm 15 it will say the command is unkown which is a script error.
	if(DMID >= MAX_DMS) return SendErrorMessage(playerid,"Invalid DM id."); // If you don't use this line and later on you use 'crashdetect' plugin for ur gamemode, it will give you an error.
	if(DMExist[DMID] == false) return SendErrorMessage(playerid,"This DM does not exist.");

	if(Player[playerid][Spectating] == true) StopSpectate(playerid);

	ResetPlayerWeapons(playerid); // Reset all player weapons
	SetPlayerVirtualWorld(playerid, 1); // Put player in a different virtual world so that if you create a DM in your lobby and you join the DM, you won't be able to see other players in the lobby.
	SetHP(playerid, 100);
	SetAP(playerid, 100);

	Player[playerid][InDM] = true; // Keep a record of what is the player current status.
	Player[playerid][DMReadd] = DMID;
	Player[playerid][VWorld] = 1;

	// format for SetPlayerSpawn(Playerid, Team, Skin, X, Y, X, Angle, Weapon 1, Weapon 1 Ammo, Weapon 2, Weapon 2 Ammo, Weapon 3, Weapon 3 Ammo)
	// I suggest you use SetPlayerSpawn most of the time instead of 'SetPlayerPos' And 'SetPlayerSkin' because using 'SetPlayerSkin' and 'SpawnPlayer' at the same time will crash the player in random even if the player has 100% orginal GTA.
	SetSpawnInfo(playerid, playerid, Skin[Player[playerid][Team]], DMSpawn[DMID][0]+random(2), DMSpawn[DMID][1]+random(2), DMSpawn[DMID][2], DMSpawn[DMID][3], DMWeapons[DMID][0], 9999, DMWeapons[DMID][1], 9999, DMWeapons[DMID][2], 9999);
	Player[playerid][IgnoreSpawn] = true; //Make sure you ignore OnPlayerSpawn, else you will just spawn in lobby (because u are about to use SpawnPlayer).
	SpawnPlayer(playerid); //Spawns players, in this case we have SetSpawnInfo (but still you need to make sure OnPlayerSpawn is ignored);
	SetPlayerInterior(playerid, DMInterior[DMID]);
	SetPlayerTeam(playerid, playerid);

	new iString[140];

    if(DMWeapons[DMID][1] == 0 && DMWeapons[DMID][2] == 0) format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has entered DM %d {FFFFFF}(%s).", Player[playerid][Name], DMID, WeaponNames[DMWeapons[DMID][0]]); // If the second and third weapons are punch or no weapons then it'll show you just one weapon instead of saying (Deagle - Punch - Punch)
	else if(DMWeapons[DMID][2] == 0) format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has entered DM %d {FFFFFF}(%s - %s).", Player[playerid][Name], DMID, WeaponNames[DMWeapons[DMID][0]], WeaponNames[DMWeapons[DMID][1]]); //If only the third weapons is punch then it'll show two weapons e.g. (Deagle - Shotgun) instead of (Deagle - Shotgun - Punch)
	else format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has entered DM %d {FFFFFF}(%s - %s - %s).", Player[playerid][Name], DMID, WeaponNames[DMWeapons[DMID][0]], WeaponNames[DMWeapons[DMID][1]], WeaponNames[DMWeapons[DMID][2]] ); //If all the weapons are known then it'll show u all three weapons e.g. (Deagle - Shotgun - Sniper)

	SendClientMessageToAll(-1, iString); // Send the formatted message to everyone.

	if(Player[playerid][BeingSpeced] == true)
	{
	    foreach(new i : Player)
		{
	        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
	            StopSpectate(i);
			}
		}
	}
	return 1;
}

YCMD:dmq(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "get you out of a deathmatch arena.");
	    return 1;
	}
	QuitDM(playerid);
	return 1;

}

YCMD:int(playerid,params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "teleport you to an interior.");
	    return 1;
	}
	if(Player[playerid][Playing] == true) return SendClientMessage(playerid, -1, "{FFFFFF}Error: "COL_PRIM"Can't use while round is active.");
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel.");
	if(isnull(params) || !IsNumeric(params)) return SendClientMessage(playerid, -1, "{FFFFFF}USAGE: "COL_PRIM"/int [1-147]");

	new id = strval(params);
	if(id <= 0 || id > 147) return SendClientMessage(playerid,-1 ,"{FFFFFF}USAGE: "COL_PRIM"/int [1-147]");

	if(Player[playerid][Spectating] == true) StopSpectate(playerid);
	if(Player[playerid][InDM] == true) QuitDM(playerid);
	if(Player[playerid][Spectating] == true) StopSpectate(playerid);

 	if(IsPlayerInAnyVehicle(playerid)) {
  	    new vehicleid = GetPlayerVehicleID(playerid);
		foreach(new i : Player) {
  	        if(vehicleid == GetPlayerVehicleID(i)) {
				SetPlayerInterior(i, Interiors[id][int_interior]);
			}
  	    }
		SetVehiclePos(GetPlayerVehicleID(playerid), Interiors[id][int_x], Interiors[id][int_y], Interiors[id][int_z]);
		SetVehicleZAngle(GetPlayerVehicleID(playerid), 0.0);
    	LinkVehicleToInterior(GetPlayerVehicleID(playerid), Interiors[id][int_interior]);
    	SetCameraBehindPlayer(playerid);
    } else {
		SetPlayerPos(playerid,Interiors[id][int_x], Interiors[id][int_y], Interiors[id][int_z]);
		SetPlayerFacingAngle(playerid, Interiors[id][int_a]);
		SetPlayerInterior(playerid, Interiors[id][int_interior]);
		SetCameraBehindPlayer(playerid);
	}

	new iString[144];
	format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has entered Interior ID: {FFFFFF}%d",Player[playerid][Name],id);
	SendClientMessageToAll(-1,iString);
	return 1;
}

// End of commands!

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	// - High priority key functions
	if(newkeys == 160 && GetPlayerVehicleID(playerid) == 0)
	{
	    switch(GetWeaponSlot(GetPlayerWeapon(playerid)))
	    {
	        case 0, 1, 8, 11:
	        {
	            SyncPlayer(playerid);
	            return 1;
	        }
	    }
	}
	if(AntiMacros == true && CheckPlayerSprintMacro(playerid, newkeys, oldkeys) == true)
	    return 1;

    if(PRESSED(4)) // key fire
	{
	    if(Player[playerid][TextDrawOnScreen])
	    {
	    	HideEndRoundTextDraw(playerid);
	    	return 1;
		}
		if(Player[playerid][InDeathCamera])
		{
		    OnPlayerDeathCameraEnd(playerid);
		    return 1;
		}
	}
    if(Player[playerid][Spectating] == true && noclipdata[playerid][FlyMode] == false && Player[playerid][SpectatingRound] == -1)
	{
		if(newkeys == 4)
		{
			if(Current != -1)
			{
				SpectateNextTeamPlayer(playerid);
			}
			else
			{
			    SpectateNextPlayer(playerid);
			}
		}
		else if(newkeys == 128)
		{
			if(Current != -1)
			{
				SpectatePreviousTeamPlayer(playerid);
			}
			else
			{
			    SpectatePreviousPlayer(playerid);
			}
		}
		return 1;
	}
	if(Current != -1 && Player[playerid][Playing] == true)
	{
	    if(PRESSED(131072) && AllowStartBase == true)
		{
		    if(PlayerRequestBackup(playerid))
		        return 1;
		}
	    // Lead team
	    if(PRESSED(262144) && AllowStartBase == true)
        {
            if(GetPlayerVehicleID(playerid))
                return 1;

            if((GetTickCount() - Player[playerid][LastAskLeader]) < 5000)
			{
				SendErrorMessage(playerid,"Please wait.");
				return 0;
			}
            new team = Player[playerid][Team];
			if(TeamHasLeader[team] != true)
            {
                PlayerLeadTeam(playerid, false, true);
           	}
           	else
           	{
           	    if(TeamLeader[team] == playerid) // off
      	    	{
                    PlayerNoLeadTeam(playerid);
           	    }
           	    else
           	    	SendErrorMessage(playerid, "Your team already has a leader!");
           	}
           	Player[playerid][LastAskLeader] = GetTickCount();
           	return 1;
        }
        // Pause/unpause or ask for pause/unpause
        if(PRESSED(65536))
        {
			if(Player[playerid][Level] > 0)
			{
			    switch(RoundPaused)
	            {
	                case true:
	                {
	                    new iString[144];
                        if((GetTickCount() - PausePressed) < 3000)
							return SendErrorMessage(playerid,"Please Wait.");
						if(RoundUnpausing == true) return 1;

						PauseCountdown = 4;
					    UnpauseRound();

						format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unpaused the current round.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
						return 1;
	                }
	                case false:
	                {
	                    new iString[144];
	                    if(RoundUnpausing == true) return SendErrorMessage(playerid,"Round is unpausing, please wait.");

						PausePressed = GetTickCount();

					    PauseRound();

						format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has paused the current round.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
						return 1;
	                }
	            }
			}
			else
			{
			    switch(RoundPaused)
	            {
	                case true:
	                {
	                    if((GetTickCount() - Player[playerid][lastChat]) < 10000)
						{
							SendErrorMessage(playerid,"Please wait.");
							return 0;
						}
						foreach(new i : Player)
						    PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
						Player[playerid][lastChat] = GetTickCount();
						SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"is asking for an unpause!", Player[playerid][Name]));
						return 1;
	                }
	                case false:
	                {
	                    if((GetTickCount() - Player[playerid][lastChat]) < 10000)
						{
							SendErrorMessage(playerid,"Please wait.");
							return 0;
						}
						foreach(new i : Player)
						    PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
						Player[playerid][lastChat] = GetTickCount();
						SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"is asking for a pause!", Player[playerid][Name]));
						return 1;
	                }
	            }
			}
		}
	}
	if(Current == -1 && Player[playerid][Playing] == false && LobbyGuns == false && PRESSED(4))
	{
	    SendErrorMessage(playerid,"DM is disabled in the lobby");
	    TogglePlayerControllable(playerid, 0);
	    TogglePlayerControllable(playerid, 1);
		return 0;
 	}
 	
	// - Low priority key functions

    if(CheckKeysForWeaponBind(playerid, newkeys, oldkeys) == 1)
	    return 1;

	if(GetPlayerVehicleID(playerid) && PRESSED(KEY_FIRE) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
 		AddVehicleComponent(GetPlayerVehicleID(playerid), 1010);
		return 1;
	}

	if(Player[playerid][SpectatingRound] != -1)
	{
	    new iString[128];
	    switch(Player[playerid][SpectatingType]) {
	        case BASE: {
	            if(newkeys == 4) {
				    new searching;
				    for(new i = Player[playerid][SpectatingRound]+1; i <= MAX_BASES; i++) {
						if(searching > 1) {
							break;
						}
				    	if(i == MAX_BASES) {
							i = 1;
				            searching++;
						}
						if(BExist[i] == true) {
						    Player[playerid][SpectatingRound] = i;
					        SetPlayerInterior(playerid, BInterior[i]);
							SetPlayerCameraLookAt(playerid,BCPSpawn[i][0],BCPSpawn[i][1],BCPSpawn[i][2]);
					   		SetPlayerCameraPos(playerid,BCPSpawn[i][0]+100,BCPSpawn[i][1],BCPSpawn[i][2]+80);
							SetPlayerPos(playerid, BCPSpawn[i][0], BCPSpawn[i][1], BCPSpawn[i][2]);
							format(iString, sizeof(iString), "%sBase ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, BName[i], i, MAIN_TEXT_COLOUR);
							PlayerTextDrawSetString(playerid, TD_RoundSpec[playerid], iString);
						 	break;
						}
					}
				} else if(newkeys == 128) {
				    new searching;
					for(new i = Player[playerid][SpectatingRound]-1; i >= 0; i--)
					{
						if(searching > 1) {
						    break;
						}
						if(i == 0) {
							i = MAX_BASES - 1;
				            searching++;
						}

						if(BExist[i] == true) {
						    Player[playerid][SpectatingRound] = i;
					        SetPlayerInterior(playerid, BInterior[i]);
							SetPlayerCameraLookAt(playerid,BCPSpawn[i][0],BCPSpawn[i][1],BCPSpawn[i][2]);
					   		SetPlayerCameraPos(playerid,BCPSpawn[i][0]+100,BCPSpawn[i][1],BCPSpawn[i][2]+80);
							SetPlayerPos(playerid, BCPSpawn[i][0], BCPSpawn[i][1], BCPSpawn[i][2]);

							format(iString, sizeof(iString), "%sBase ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, BName[i], i, MAIN_TEXT_COLOUR);
							PlayerTextDrawSetString(playerid, TD_RoundSpec[playerid], iString);
						 	break;
						}
					}
				}
	        } case ARENA: {
	            if(newkeys == 4) {
				    new searching;
				    for(new i = Player[playerid][SpectatingRound]+1; i <= MAX_ARENAS; i++) {
						if(searching > 1) {
							break;
						}
				    	if(i == MAX_ARENAS) {
							i = 0;
				            searching++;
						}
						if(AExist[i] == true) {
						    Player[playerid][SpectatingRound] = i;
							SetPlayerCameraLookAt(playerid,ACPSpawn[Player[playerid][SpectatingRound]][0],ACPSpawn[Player[playerid][SpectatingRound]][1],ACPSpawn[Player[playerid][SpectatingRound]][2]);
					   		SetPlayerCameraPos(playerid,ACPSpawn[Player[playerid][SpectatingRound]][0]+100,ACPSpawn[Player[playerid][SpectatingRound]][1],ACPSpawn[Player[playerid][SpectatingRound]][2]+80);
							SetPlayerPos(playerid, ACPSpawn[Player[playerid][SpectatingRound]][0], ACPSpawn[Player[playerid][SpectatingRound]][1], ACPSpawn[Player[playerid][SpectatingRound]][2]);
							SetPlayerInterior(playerid, AInterior[Player[playerid][SpectatingRound]]);

							format(iString, sizeof(iString), "%sArena ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, AName[Player[playerid][SpectatingRound]], Player[playerid][SpectatingRound], MAIN_TEXT_COLOUR);
							PlayerTextDrawSetString(playerid, TD_RoundSpec[playerid], iString);
						 	break;
						}
					}
				} else if(newkeys == 128) {
				    new searching;
					for(new i = Player[playerid][SpectatingRound]-1; i >= 0; i--) {
						if(searching > 1) {
						    break;
						}
						if(i == 0) {
							i = MAX_ARENAS - 1;
				            searching++;
						}

						if(AExist[i] == true) {
						    Player[playerid][SpectatingRound] = i;
							SetPlayerCameraLookAt(playerid,ACPSpawn[Player[playerid][SpectatingRound]][0],ACPSpawn[Player[playerid][SpectatingRound]][1],ACPSpawn[Player[playerid][SpectatingRound]][2]);
					   		SetPlayerCameraPos(playerid,ACPSpawn[Player[playerid][SpectatingRound]][0]+100,ACPSpawn[Player[playerid][SpectatingRound]][1],ACPSpawn[Player[playerid][SpectatingRound]][2]+80);
							SetPlayerPos(playerid, ACPSpawn[Player[playerid][SpectatingRound]][0], ACPSpawn[Player[playerid][SpectatingRound]][1], ACPSpawn[Player[playerid][SpectatingRound]][2]);
							SetPlayerInterior(playerid, AInterior[Player[playerid][SpectatingRound]]);

							format(iString, sizeof(iString), "%sArena ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, AName[Player[playerid][SpectatingRound]], Player[playerid][SpectatingRound], MAIN_TEXT_COLOUR);
							PlayerTextDrawSetString(playerid, TD_RoundSpec[playerid], iString);
						 	break;
						}
					}
				}

			}
		}
		if(newkeys == 32)
		{
		    switch(Player[playerid][SpectatingType])
			{
				case BASE: format(iString, sizeof(iString), ""COL_PRIM"Spectating Base: {FFFFFF}%s (ID: %d)", BName[Player[playerid][SpectatingRound]], Player[playerid][SpectatingRound]);
				case ARENA: format(iString, sizeof(iString), ""COL_PRIM"Spectating Arena: {FFFFFF}%s (ID: %d)", AName[Player[playerid][SpectatingRound]], Player[playerid][SpectatingRound]);
			}
		    SendClientMessage(playerid, -1, iString);
			SetCameraBehindPlayer(playerid);
		    Player[playerid][SpectatingRound] = -1;
		    PlayerTextDrawSetString(playerid, TD_RoundSpec[playerid], "_");
		    Player[playerid][Spectating] = false;
		}
		return 1;
	}
	if(Current == -1)
	{
		if(PRESSED(KEY_YES) && Player[playerid][Level] > 1 && GetPlayerVehicleID(playerid) == 0)
		{
			EnableMatchInterface(playerid);
			return 1;
		}
		else if(PRESSED(131072) && GetPlayerVehicleID(playerid) == 0)
		{
			ShowEndRoundTextDraw(playerid);
  			return 1;
		}
	}
	return 1;
}

// OnScriptUpdate - interval: 1000 ms
forward OnScriptUpdate();
public OnScriptUpdate()
{
    CheckVisualDamageTextDraws(); // This basically hides damage textdraws that should be hidden

    foreach(new i : Player)
	{
	    // AFK Variable Update
	    Player[i][PauseCount] ++;

		// Get & update player FPS
	    GetPlayerFPS(i);

	    // Show target info
	    ShowTargetInfo(i, GetPlayerTargetPlayer(i));


		// Update net info textdraws
		if(PlayerInterface[i][INTERFACE_NET])
		{
  			PlayerTextDrawSetString(i, FPSPingPacket[i], sprintf("%sFPS %s%d %sPing %s%d %sPacketLoss %s%.1f%%", MAIN_TEXT_COLOUR, TDC[Player[i][Team]], Player[i][FPS], MAIN_TEXT_COLOUR, TDC[Player[i][Team]], GetPlayerPing(i), MAIN_TEXT_COLOUR, TDC[Player[i][Team]], NetStats_PacketLossPercent(i)));
		}
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
    ShowPlayerDialog(playerid, PLAYERCLICK_DIALOG, DIALOG_STYLE_LIST, sprintf("Clicked ID: %d", clickedplayerid), "Getinfo\nAKA\nSpec\nAdd\nRemove\nReadd\nGunmenu\nGo\nGet\nSlap\nMute\nUnmute\nKick\nBan", "Select", "Cancel");
	LastClickedPlayer[playerid] = clickedplayerid;
	return 1;
}
