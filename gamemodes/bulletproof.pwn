#include <a_samp>
#include <a_http>

#undef MAX_PLAYERS
#define MAX_PLAYERS      		40

//	- 	Libraries
#include <geolocation> 		// Shows player country based on IP
#include <strlib>           // String functions by Slice
#include <progress2>        // Player Progress Bar functions
#include <globalprogressbar>// Global Progress Bar functions
#include <profiler>         // Script profiler
#include <sampac> 			// THE MIGHTY NEW ANTICHEAT
#include <mSelection>       // Selection with preview models feature library

//	-	YSI Libraries (updated)
#define YSI_NO_MASTER
//#define 	_DEBUG			(7) 	// y_debug debug level
//#define FOREACH_NO_VEHICLES
//#define FOREACH_NO_LOCALS
//#define FOREACH_NO_ACTORS
#include <YSI_inc\YSI\y_stringhash> // better than strcmp in comparing strings (not recommended for long ones though)
#include <YSI_inc\YSI\y_commands>
#include <YSI_inc\YSI\y_groups>
#include <YSI_inc\YSI\y_iterate> 	// foreach and iterators
//#include <YSI_inc\YSI\y_debug>
#include <YSI_inc\YSI\y_master>

// Some SA-MP natives which are not defined by default
native gpci (playerid, serial [], len);
native IsValidVehicle(vehicleid);

/*
	If PRE_RELEASE_VERSION is defined, the version checker
	is ignored and you can no longer worry about it. It's
	to be commented out on releases though.
*/
//#define PRE_RELEASE_VERSION

#include <gBugFix> // Fix false vehicle entry as passenger (G (teleport/distance) bug)

/*
	PROTECTION:
	The following code will check whether the http destinations
	library (which is not open-source) is permitted for this c-
	-ompiler or not. If it is not, the code will empty destina-
	-tion variables to show no useful information to this coder
*/
#tryinclude "modules\header\http_destinations.txt"

#if !defined _http_destinations_included
	#define HTTP_DEST_SERVERLIST 				""
	#define HTTP_DEST_LEAGUE_SAVEPLAYER			""
	#define HTTP_DEST_LEAGUE_SAVECLANS			""
	#define HTTP_DEST_LEAGUE_CHECKPLAYER		""
	#define HTTP_DEST_LEAGUE_CHECKPLAYERPASS	""
	#define HTTP_DEST_LEAGUE_CHECKCLANS			""
	#define HTTP_DEST_LEAGUE_TOPPLAYERS			""
	#define HTTP_DEST_LEAGUE_TOPCLANS			""
	#define HTTP_DEST_LEAGUE_PLAYERPOINTS       ""
	#define HTTP_DEST_LEAGUE_LEAGUEADMINS       ""
#endif

// Server modules (note: modules that consists of hooking have to be first)
#include "modules\src\hooking\tickcount.inc"
#include "modules\src\hooking\safegametext.inc"
#include "modules\src\hooking\vehicle.inc"
#include "modules\src\hooking\commonhooking.inc"
#tryinclude "modules\src\league.inc" // The league system source code is not open
#tryinclude "modules\src\shop.inc"  // The league shop source code is not open
#include "modules\src\this_core.inc"
#include "modules\src\freecam.inc"
#include "modules\src\common.inc"
#include "modules\header\longarrays.txt"
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
#include "modules\src\match_sync.inc"
#include "modules\src\version_checker.inc"
#include "modules\src\database.inc"
#include "modules\src\duel.inc"
#include "modules\src\spectate.inc"
#include "modules\src\commands.inc"
#include "modules\src\antimacro.inc"
#include "modules\src\messagebox.inc"
#include "modules\src\deathcam.inc"
#include "modules\src\gunmenu.inc"
#if GTAV_SWITCH_MENU != 0
#include "modules\src\gunswitch.inc"
#endif
#include "modules\src\weaponbinds.inc"
#include "modules\src\ac.inc"
#include "modules\src\vote.inc"

main()
{}

public OnGameModeInit()
{
    InitScriptCoreSettings();
    InitScriptCoreVariables();
	InitScriptSecondarySettings();
	AddToServersDatabase();
	SetTimer("OnScriptUpdate", 1000, true); // Timer that is repeatedly called every second (will be using this for most global stuff)
	return 1;
}

public OnGameModeExit()
{
	db_close(sqliteconnection);
	#if MATCH_SYNC == 1
	mysql_close();
	#endif
	return 1;
}

public OnPlayerConnect(playerid)
{
    // Check if version is out-dated and if server owners are forced to use newest version
	if(VersionReport == VERSION_IS_BEHIND && ForceUserToNewestVersion == true)
	{
	    SendClientMessageToAll(-1, sprintf(""COL_PRIM"Version checker: {FFFFFF}the version used in this server is out-dated. You can visit "COL_PRIM"%s {FFFFFF}to get the latest version", GM_WEBSITE));
        SendClientMessageToAll(-1, sprintf(""COL_PRIM"Server version: {FFFFFF}%s "COL_PRIM"| Newest version: {FFFFFF}%s", GM_NAME, LatestVersionStr));
        SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
		return 0;
	}
    if(DatabaseLoading == true)
    {
        ClearChatForPlayer(playerid);
		SendClientMessage(playerid, -1, "Please wait! Database loading, you will be connected when it's loaded successfully.");
		SetTimerEx("OnPlayerConnect", 1000, false, "i", playerid);
		return 0; // If database is still loading, disable the player from spawning
	}
	// Check if players count exceeded the limit
	if(Iter_Count(Player) == MAX_PLAYERS)
	{
	    SendClientMessageToAll(-1, sprintf(""COL_PRIM"ID %d could't connect to the server properly. Maximum players limit exceeded!", playerid));
	    SendClientMessageToAll(-1, sprintf("MAX PLAYERS LIMIT: %d | Ask for a special and increased limit | %s", MAX_PLAYERS, GM_WEBSITE));
	    SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
	    return 0;
	}
	// Send them welcome messages
	SendClientMessage(playerid, -1, ""COL_PRIM"It's {FFFFFF}Bulletproof"COL_PRIM". Your bullets are fruitless. You can't take it down!");
	SendClientMessage(playerid, -1, ""COL_PRIM"Get started: {FFFFFF}/help "COL_PRIM"and {FFFFFF}/cmds");
	SendClientMessage(playerid, -1, ""COL_PRIM"Don't miss our updates: {FFFFFF}/checkversion");
	SendClientMessage(playerid, -1, ""COL_PRIM"Check {FFFFFF}/changelog "COL_PRIM"out to see what's up with this version!");
	SendClientMessage(playerid, -1, ""COL_PRIM"Developers: {FFFFFF}Whitetiger"COL_PRIM" & {FFFFFF}[KHK]Khalid"COL_PRIM"");
	SendClientMessage(playerid, -1, ""COL_PRIM"Contributors on GitHub: {FFFFFF}ApplePieLife"COL_PRIM", {FFFFFF}JamesCullum");
	new str[128];
	format(str,sizeof(str),""COL_PRIM"Server limits:  Min FPS = {FFFFFF}%d "COL_PRIM"| Max Ping = {FFFFFF}%d "COL_PRIM"| Max PL = {FFFFFF}%.2f", Min_FPS, Max_Ping, Float:Max_Packetloss);
	SendClientMessage(playerid, -1, str);
	
	// Initialize the new player
	InitPlayer(playerid);
	#if defined _league_included
	CheckPlayerLeagueRegister(playerid);
	#endif
	CheckPlayerAKA(playerid);
	
	// Tell everyone that he's connected
	str = "";
    GetPlayerCountry(playerid, str, sizeof(str));
	format(str, sizeof(str), "{FFFFFF}%s {757575}(ID: %d) has connected [{FFFFFF}%s{757575}]", Player[playerid][Name], playerid, str);
    SendClientMessageToAll(-1, str);

    if(AllMuted) // If everyone is muted (global mute, /muteall?), this player should be muted too
    	Player[playerid][Mute] = true;
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	// Initialize class selection mode
	Player[playerid][Team] = NON;
	Player[playerid][RequestedClass] = classid;
    SetPlayerColor(playerid, 0xAAAAAAAA);
    Player[playerid][Spawned] = false;

	// Position and camera...
 	SetPlayerSpecialAction(playerid, 68);
	SetPlayerPos(playerid, -739.8491, 486.9522, 1371.9198);
	SetPlayerFacingAngle(playerid, 243.4329);
	SetPlayerCameraPos(playerid, -734.5640, 484.6783, 1371.5766);
	SetPlayerCameraLookAt(playerid, -739.8491, 486.9522, 1371.9198);
	SetPlayerInterior(playerid, 1);

    #if defined _league_included
	// League account login check
	if(Player[playerid][MustLeaguePass] == true)
	{
	    ShowPlayerDialog(
			playerid,
			DIALOG_LEAGUE_LOGIN,
			DIALOG_STYLE_PASSWORD,
			"{FFFFFF}League Clan Login","{FFFFFF}Looks like your name is registered in our league system database.\nIf this isn't you, then please quit the game and join with another name or type your league account\nPASSWORD below to continue:",
			"Login",
			"Quit"
		);
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
		format(Query, sizeof(Query), "SELECT Name FROM Players WHERE Name = '%s'", DB_Escape(Player[playerid][Name]));
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
		    format(Query, sizeof(Query), "SELECT * FROM `Players` WHERE `Name` = '%s' AND `IP` = '%s'", DB_Escape(Player[playerid][Name]), IP);

		    // execute
			new DBResult:res = db_query(sqliteconnection, Query);

			// If result returns any registered users with the same name and IP that have connected to this server before, log them in
			if(db_num_rows(res))
			{
			    MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~g~~h~Auto-login", "You've been automatically logged in (IP is the same as last login)", 4000);
				MessageBox(playerid, MSGBOX_TYPE_TOP, "~y~select your class", "~>~ to view next class~n~~<~ to view prev class~n~~n~(SPAWN) to select the current class", 7000);
				LoginPlayer(playerid, res);
			    db_free_result(res);
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
	    new teamName[23], teamInfo[128];
	    switch(classid)
	    {
	        case 0:
	        {
	            format(teamName, sizeof teamName, "~p~~h~auto-assign");
	            format(teamInfo, sizeof teamInfo, "Auto-assign to the team with less players count");
	            SetPlayerSkin(playerid, 0);
	        }
	        case 1:
	        {
	            format(teamName, sizeof teamName, sprintf("~r~~h~%s", TeamName[ATTACKER]));
	            new ct = 0;
	            foreach(new i : Player)
	            {
	                if(Player[i][Team] != ATTACKER)
	                    continue;

					if(ct == 4)
					{
					    format(teamInfo, sizeof teamInfo, "%s...", teamInfo);
					    break;
					}
					format(teamInfo, sizeof teamInfo, "%s%s~n~", teamInfo, Player[i][NameWithoutTag]);
					ct ++;
				}
				SetPlayerSkin(playerid, Skin[ATTACKER]);
			}
			case 2:
	        {
	            format(teamName, sizeof teamName, sprintf("~b~~h~%s", TeamName[DEFENDER]));
	            new ct = 0;
	            foreach(new i : Player)
	            {
	                if(Player[i][Team] != DEFENDER)
	                    continue;

					if(ct == 4)
					{
					    format(teamInfo, sizeof teamInfo, "%s...", teamInfo);
					    break;
					}
					format(teamInfo, sizeof teamInfo, "%s%s~n~", teamInfo, Player[i][NameWithoutTag]);
					ct ++;
				}
				SetPlayerSkin(playerid, Skin[DEFENDER]);
			}
			case 3:
	        {
	            format(teamName, sizeof teamName, sprintf("~r~~h~~h~~h~%s sub", TeamName[ATTACKER]));
	            new ct = 0;
	            foreach(new i : Player)
	            {
	                if(Player[i][Team] != ATTACKER_SUB)
	                    continue;

					if(ct == 4)
					{
					    format(teamInfo, sizeof teamInfo, "%s...", teamInfo);
					    break;
					}
					format(teamInfo, sizeof teamInfo, "%s%s~n~", teamInfo, Player[i][NameWithoutTag]);
					ct ++;
				}
				SetPlayerSkin(playerid, Skin[ATTACKER_SUB]);
			}
			case 4:
	        {
	            format(teamName, sizeof teamName, sprintf("~b~~h~~h~%s sub", TeamName[DEFENDER]));
             	new ct = 0;
	            foreach(new i : Player)
	            {
	                if(Player[i][Team] != DEFENDER_SUB)
	                    continue;

					if(ct == 4)
					{
					    format(teamInfo, sizeof teamInfo, "%s...", teamInfo);
					    break;
					}
					format(teamInfo, sizeof teamInfo, "%s%s~n~", teamInfo, Player[i][NameWithoutTag]);
					ct ++;
				}
				SetPlayerSkin(playerid, Skin[DEFENDER_SUB]);
			}
			case 5:
	        {
	            format(teamName, sizeof teamName, "~y~~h~%s referee");
             	new ct = 0;
	            foreach(new i : Player)
	            {
	                if(Player[i][Team] != REFEREE)
	                    continue;

					if(ct == 4)
					{
					    format(teamInfo, sizeof teamInfo, "%s...", teamInfo);
					    break;
					}
					format(teamInfo, sizeof teamInfo, "%s%s~n~", teamInfo, Player[i][NameWithoutTag]);
					ct ++;
				}
				SetPlayerSkin(playerid, Skin[REFEREE]);
			}
	    }
	    if(strlen(teamInfo) == 0)
	        teamInfo = " ";
	    MessageBox(playerid, MSGBOX_TYPE_TOP, teamName, teamInfo, 5000);
	}
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if(Player[playerid][Spawned])
	{
	    SendErrorMessage(playerid, "Encountered an error. Switch to another class using ~<~ and ~>~ and then click the SPAWN button!");
	    return 0;
	}
	if(Player[playerid][Logged] == true) 
	{
	    if(Player[playerid][RequestedClass] > 0) // If the requested class is a valid class, not auto-assign
	    {
			new groupID = Player[playerid][RequestedClass] - 1;
			if(strlen(GroupAccessPassword[groupID]) > 0 && (strcmp(RequestedGroupPass[playerid][groupID], GroupAccessPassword[groupID]) != 0 || isnull(RequestedGroupPass[playerid][groupID])))
			{
				ShowPlayerDialog(playerid, DIALOG_GROUPACCESS, DIALOG_STYLE_INPUT, "Authorization required", "Please enter the group password:", "Submit", "Cancel");
                OnPlayerRequestClass(playerid, Player[playerid][RequestedClass]);
				return 0;
			}
		}
		HideMessageBox(playerid, MSGBOX_TYPE_TOP);
		SpawnConnectedPlayer(playerid, Player[playerid][RequestedClass]);
		return 1;
	}
	else
	{
	    OnPlayerRequestClass(playerid, Player[playerid][RequestedClass]);
	}
	return 0;
}

public OnPlayerSpawn(playerid)
{
	TextDrawHideForPlayer(playerid, DarkScreen); // This fixes dark screen getting stuck on player's screen
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
	// If they're in Anti lag zone
	if(Player[playerid][AntiLag] == true)
	{
	    // Respawn them there
	    SpawnInAntiLag(playerid);
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
	// If there's no round running, hide the round stats textdraws
	if(Current == -1)
	    HideRoundStats(playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	// Handle war mode
    if(WarMode == true)
	{
		if(Player[playerid][Playing] == true)
		{
		    PlayerNoLeadTeam(playerid);
		    StorePlayerVariables(playerid);
			if(Player[playerid][DontPause] == false && AutoPause == true && Current != -1)
			{
				KillTimer(UnpauseTimer);
				RoundUnpausing = false;
				PauseRound();
				SendClientMessageToAll(-1, ""COL_PRIM"Round has been auto-paused.");
			}
		}
		else
			StorePlayerVariablesMin(playerid);
	}
	// Reset player weapons on gunmenu
	ResetPlayerGunmenu(playerid, false);
	#if defined _league_included
	if(LeagueMode)
	{
	    SaveLeaguePlayerData(playerid);
	    SaveLeaguePlayerTotalPoints(playerid);
	}
	#endif
	// Handle match
 	Iter_Remove(PlayersInRound, playerid);
	UpdateTeamPlayerCount(Player[playerid][Team], true, playerid);
	UpdateTeamHP(Player[playerid][Team], playerid);
    DeletePlayerTeamBar(playerid);
	// Send public disconnect messages
    new iString[180];
    switch (reason){
		case 0:{
			if(Player[playerid][Playing] == false) format(iString, sizeof(iString), "{FFFFFF}%s {757575}has disconnected [{FFFFFF}Timeout{757575}]",Player[playerid][Name]);
		 	else format(iString, sizeof(iString), "{FFFFFF}%s {757575}has disconnected [{FFFFFF}Timeout{757575}] HP {FFFFFF}%d {757575}| Armour {FFFFFF}%d", Player[playerid][Name], Player[playerid][pHealth], Player[playerid][pArmour]);
		} case 1: {
			if(Player[playerid][Playing] == false) format(iString, sizeof(iString), "{FFFFFF}%s {757575}has disconnected [{FFFFFF}Leaving{757575}]",Player[playerid][Name]);
			else format(iString, sizeof(iString), "{FFFFFF}%s {757575}has disconnected [{FFFFFF}Leaving{757575}] HP {FFFFFF}%d {757575}| Armour {FFFFFF}%d", Player[playerid][Name], Player[playerid][pHealth], Player[playerid][pArmour]);
		} case 2: {
		    if(Player[playerid][Playing] == false) {
				if(Player[playerid][IsKicked] == true)format(iString, sizeof(iString), "{FFFFFF}%s {757575}has disconnected [{FFFFFF}Kicked{757575}]",Player[playerid][Name]);
				else format(iString, sizeof(iString), "{FFFFFF}%s {757575}has disconnected [{FFFFFF}Banned{757575}]",Player[playerid][Name]);
			} else {
				if(Player[playerid][IsKicked] == true)format(iString, sizeof(iString), "{FFFFFF}%s {757575}has disconnected [{FFFFFF}Kicked{757575}] HP {FFFFFF}%d {757575}| Armour {FFFFFF}%d",Player[playerid][Name], Player[playerid][pHealth], Player[playerid][pArmour]);
				else format(iString, sizeof(iString), "{FFFFFF}%s {757575}has disconnected [{FFFFFF}Banned{757575}] HP {FFFFFF}%d {757575}| Armour {FFFFFF}%d",Player[playerid][Name], Player[playerid][pHealth], Player[playerid][pArmour]);
			}
		}
	}
	SendClientMessageToAll(-1,iString);
	// Call OnPlayerLeaveCheckpoint to see if this player was in the checkpoint and fix issues
	if(Current != -1)
	{
        OnPlayerLeaveCheckpoint(playerid);
	}
	// Handle duels
	ProcessDuellerDisconnect(playerid);
	// Handle spectate
	StopSpectate(playerid);
	HandleSpectatedPlayerDisconnect(playerid);
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
	// If it's the last player in the server (server is empty now!)
	if(Iter_Count(Player) == 1)
	{
	    // Server lock check
		if(ServerLocked)
		{
		    // See if round is not paused
		    if(RoundPaused == false)
			{
			    // if permanent locking is disabled
				if(!PermLocked)
			    {
			        // Unlock the server
					SendRconCommand("password 0");
					ServerLocked = false;
				}
			}
		}
		// Version check
		ReportServerVersion();
		// Optimize and clean database
		OptimizeDatabase();
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
    // Fix invalid death reasons for antilag zone players
	if(Player[playerid][AntiLag] == true)
	{
	    if(reason == 255)
			reason = 53;
			
		if(reason == 47 || reason == 51 || reason == 53 || reason == 54)
		{
			Player[playerid][HitBy] = INVALID_PLAYER_ID;
			Player[playerid][HitWith] = 47;
		}
	}
	killerid = Player[playerid][HitBy];
	reason = Player[playerid][HitWith];
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
	else if(KillerConnected)
	{
        ShowPlayerDeathMessage(killerid, playerid);

		new killText[64];
		switch(reason)
		{
		    case WEAPON_KNIFE:
		    {
		        format(killText, sizeof(killText), "%sYou knifed %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name]);
		    }
		    case WEAPON_GRENADE:
		    {
		        format(killText, sizeof(killText), "%sYou bombed %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name]);
		    }
		    default:
		    {
				new randomInt = random(4);
				switch(randomInt)
				{
				    case 0:
				        format(killText, sizeof(killText), "%sYou raped %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name]);
		            case 1:
				        format(killText, sizeof(killText), "%sYou owned %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name]);
		            case 2:
				        format(killText, sizeof(killText), "%sYou took %s~h~%s%s's life", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name], MAIN_TEXT_COLOUR);
		            case 3:
				        format(killText, sizeof(killText), "%sYou sent %s~h~%s%s to cemetery", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name], MAIN_TEXT_COLOUR);
				}
			}
		}
		PlayerTextDrawSetString(killerid, DeathText[killerid][0], killText);
        PlayerTextDrawShow(killerid, DeathText[killerid][0]);

        switch(reason)
		{
		    case WEAPON_KNIFE:
		    {
                format(killText, sizeof(killText), "%s~h~%s%s knifed you", TDC[Player[killerid][Team]], Player[killerid][Name], MAIN_TEXT_COLOUR);
		    }
		    case WEAPON_GRENADE:
		    {
                format(killText, sizeof(killText), "%s~h~%s%s bombed you", TDC[Player[killerid][Team]], Player[killerid][Name], MAIN_TEXT_COLOUR);
		    }
		    default:
		    {
		        new randomInt = random(4);
		        switch(randomInt)
				{
				    case 0:
				        format(killText, sizeof(killText), "%s~h~%s%s owned you", TDC[Player[killerid][Team]], Player[killerid][Name], MAIN_TEXT_COLOUR);
		            case 1:
				        format(killText, sizeof(killText), "%s~h~%s%s raped you", TDC[Player[killerid][Team]], Player[killerid][Name], MAIN_TEXT_COLOUR);
		            case 2:
				        format(killText, sizeof(killText), "%s~h~%s%s murdered you", TDC[Player[killerid][Team]], Player[killerid][Name], MAIN_TEXT_COLOUR);
		            case 3:
				        format(killText, sizeof(killText), "%sKilled by %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[killerid][Team]], Player[killerid][Name]);
				}
			}
		}
        PlayerTextDrawSetString(playerid, DeathText[playerid][1], killText);
        PlayerTextDrawShow(playerid, DeathText[playerid][1]);

	    SetTimerEx("DeathMessageF", 4000, false, "ii", killerid, playerid);
		
		if(Player[playerid][Playing] == true && Player[killerid][Playing] == true)
		{
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
			else if(Player[playerid][InDuel])
			{
			    ProcessDuellerDeath(playerid, killerid, reason);
			}
		}
	}
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	AddBloodEffect(x, y, z);
	if(Player[playerid][Playing] == true)
	{
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
	    if(reason != WEAPON_KNIFE)
	    {
	        new bool:showdeathquote = true;
	        if(KillerConnected)
		    {
				showdeathquote = !Player[killerid][HasDeathQuote];
			}
	        PlayDeathCamera(playerid, x, y, z, showdeathquote);
	        SetTimerEx("SpectateAnyPlayerT", DEATH_CAMERA_DURATION + 500, false, "i", playerid);
	    }
	    else
	    {
	        // If weapon is knife then no need for death camera
	    	SetTimerEx("SpectateAnyPlayerT", 1000, false, "i", playerid);
		}
		TextDrawShowForPlayer(playerid, DarkScreen);
		switch(Player[playerid][Team])
		{
		    case ATTACKER:
		    {
		        foreach(new i : PlayersInRound)
		        {
					switch(Player[playerid][Team])
					{
					    case ATTACKER:
					    {
					        SetPlayerMapIcon(i, Player[playerid][DeathIcon], x, y, z, 23, 0, MAPICON_GLOBAL);
					        SetTimerEx("PlayerDeathIcon", 5000, false, "i", playerid);
					    }
					}
				}
		    }
		    case DEFENDER:
		    {
		        foreach(new i : PlayersInRound)
		        {
					switch(Player[playerid][Team])
					{
					    case DEFENDER:
					    {
					        SetPlayerMapIcon(i, Player[playerid][DeathIcon], x, y, z, 23, 0, MAPICON_GLOBAL);
					        SetTimerEx("PlayerDeathIcon", 5000, false, "i", playerid);
					    }
					}
		        }
			}
		}
	}
	// Hide arena out of bound warning textdraws if they're shown
	if(Player[playerid][OutOfArena] != MAX_ZONE_LIMIT_WARNINGS)
	{
		PlayerTextDrawHide(playerid, AreaCheckTD[playerid]);
		PlayerTextDrawHide(playerid, AreaCheckBG[playerid]);
	}
	// Reset variables and handle match
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
	if(Current == -1)
		HideRoundStats(playerid);
		
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
	    new ChatString[128];
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
	    new ChatString[128];
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
	#endif
	// Channel chat
	if(text[0] == '#' && Player[playerid][ChatChannel] != -1)
	{
	    new ChatString[128];
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
	
	// Colorful text
	new ChatString[128];
	if(text[0] == '^')
	{
	    if(text[1] == 'r' || text[1] == 'R') // red
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {FF0000}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}
		else if(text[1] == 'b' || text[1] == 'B') // blue
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {0000FF}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}
		else if(text[1] == 'y' || text[1] == 'Y') // yellow
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {FFFF00}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}
		else if(text[1] == 'o' || text[1] == 'O') // orange
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {FF6600}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}
		else if(text[1] == 'g' || text[1] == 'G') // green
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {33FF00}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}
		else if(text[1] == 'p' || text[1] == 'P') // pink
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {FF879C}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}

	}
	// Normal chat
	format(ChatString, sizeof(ChatString),"(%d) %s", playerid, text);
    SendPlayerMessageToAll(playerid,ChatString);
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

public OnPlayerEnterCheckpoint(playerid)
{
    if(GetPlayerVehicleID(playerid) == 0 && Player[playerid][Playing] == true)
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
						TextDrawShowForAll(EN_CheckPoint);

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
						TextDrawShowForAll(EN_CheckPoint);
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
							TextDrawShowForAll(EN_CheckPoint);
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
	if(Player[playerid][Level] >= 1 && Player[playerid][Playing] == false && Player[playerid][InDM] == false && Player[playerid][InDuel] == false && Player[playerid][Spectating] == false && Player[playerid][AntiLag] == false)
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
     	format(Str, sizeof(Str), "UPDATE Players SET Level = %d WHERE Name = '%s' AND Level != %d", Player[playerid][Level], DB_Escape(Player[playerid][Name]), Player[playerid][Level]);
    	db_free_result(db_query(sqliteconnection, Str));
        if(Player[playerid][Level] != 5)
        {
	        Player[playerid][Level] = 5;
	        UpdatePlayerAdminGroup(playerid);
			format(Str, sizeof(Str), "UPDATE Players SET Level = %d WHERE Name = '%s'", Player[playerid][Level], DB_Escape(Player[playerid][Name]));
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
	if(Player[playerid][Playing] == true && Player[forplayerid][Playing] == true)
	{
		if(Player[forplayerid][Team] != Player[playerid][Team])
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
		}
		else
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid,GetPlayerColor(playerid) | 0x00000055);
		}
	}
	else if(Player[playerid][Playing] == true && Player[forplayerid][Playing] == false)
	{
		if(Player[forplayerid][Team] != Player[playerid][Team])
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
		}
		else
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid,GetPlayerColor(playerid) | 0x00000055);
		}
	}
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	if(Player[playerid][Playing] == true && Player[forplayerid][Playing] == true)
	{
		if(Player[forplayerid][Team] != Player[playerid][Team])
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
		}
		else
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid,GetPlayerColor(playerid) | 0x00000055);
		}
	}
	else if(Player[playerid][Playing] == true && Player[forplayerid][Playing] == false)
	{
		if(Player[forplayerid][Team] != Player[playerid][Team])
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
		}
		else
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid,GetPlayerColor(playerid) | 0x00000055);
		}
	}
	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
    // Show target player info for the shooter (HP, PL, Ping and many other things)
 	ShowTargetInfo(playerid, damagedid);
    if(GetTickCount() <= Player[playerid][LastWasKnifed])
	{
	    /* Players who are being knifed can not be damaged */
	    return 1;
	}
    if(amount == 1833.33154296875)
        return 1;
    // Slit throat with a knife
    if(amount == 0.0 && GetPlayerAnimationIndex(playerid) == 748 && damagedid != INVALID_PLAYER_ID)
	{
	    // Team and distance check
     	if(GetTickCount() < Player[playerid][LastWasKnifed] || GetDistanceBetweenPlayers(playerid, damagedid) > 1.05 || (Player[damagedid][Team] == Player[playerid][Team] && Player[playerid][Playing] && Player[damagedid][Playing]))
		{
		    SetPlayerArmedWeapon(playerid, 0);
			SyncPlayer(playerid);
	    	SyncPlayer(damagedid);
	    	CheckKnifeAbuse(playerid);
	    	return 1;
		}
		OnPlayerTakeDamage(damagedid, playerid, Player[damagedid][pHealth] + Player[damagedid][pArmour], WEAPON_KNIFE, bodypart);
		return 1;
	}
	// Check if they're in antilag zone
    if(Player[damagedid][AntiLag] == false)
		return 1;
    if(playerid != INVALID_PLAYER_ID && Player[playerid][AntiLag] == false)
		return 1;

    //OnPlayerTakeDamage(damagedid, playerid, amount, weaponid, bodypart);
	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
	if(Player[playerid][AlreadyDying])
	{
		// Dead players cannot be damaged
	    SetFakeHealthArmour(playerid);
		return 1;
	}
    if(issuerid != INVALID_PLAYER_ID)
    {
        new Float:dist;
		if(!IsValidHitRange(playerid, issuerid, weaponid, dist) && GetPlayerTeam(issuerid) != GetPlayerTeam(playerid))
	    {
	    	// Weapon range exceeded
			MessageBox(issuerid, MSGBOX_TYPE_MIDDLE, "~r~~h~hit out of range", sprintf("On: %s~n~Weapon: %s~n~Hit range: %.3f~n~Max hit range (exceeded): %.3f", Player[playerid][Name], WeaponNames[weaponid], dist, WeaponRanges[weaponid]), 3000);
		    SetFakeHealthArmour(playerid);
			return 1;
	    }
	    if(Player[issuerid][PauseCount] > 4)
	    {
	        // Trying to damage while game paused
	        SendClientMessageToAll(-1, sprintf(""COL_PRIM"Rejected damage caused by {FFFFFF}%s "COL_PRIM"as they've their game paused (timeout/lag expected or pause abuse)", Player[issuerid][Name]));
	        SetFakeHealthArmour(playerid);
			return 1;
	    }
	    if(!IsValidWeaponDamageAmount(weaponid, amount))
	    {
	    	// Invalid weapon damage amount
		    SetFakeHealthArmour(playerid);
			return 1;
	    }
    }
	// <start> HP Protection for some things
	if(GetTickCount() <= Player[playerid][LastWasKnifed])
	{
	    /* Players who are being knifed can not be damaged */
	    SetFakeHealthArmour(playerid);
	    return 1;
	}
	if(Player[playerid][IsAFK])
	{
	    /* Players who are in AFK mode should not be damaged */
	    SetFakeHealthArmour(playerid);
	    return 1;
	}
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
	if(Player[playerid][Playing])
	{
	    if(Player[playerid][OnGunmenu]) // Player is picking weapons from the gunmenu
		{
		    /* Players who are picking weapons from gun-menu should not be damaged */
	    	SetFakeHealthArmour(playerid);
	    	return 1;
	 	}
	    if(weaponid == 49 || weaponid == 50 || (weaponid == 54 && Player[playerid][pArmour] > 0) || (weaponid == 54 && amount <= 10))
	    {
	        /* Cancel damage done by vehicle, explosion, heli-blades and collision (equal to or less than 10 only) */
	    	SetFakeHealthArmour(playerid);
	        return 1;
	    }
	    if(FallProtection == true) // If round fall protection is on and this player is in round
		{
			if(weaponid == 54) // If it's a collision (fell from a very high building?)
			{
			    SetFakeHealthArmour(playerid);
		    	return 1;
			}
			else // If it's not a collision, then real fire is going on maybe; check if we should turn off protection or not
			{
			    if(issuerid != INVALID_PLAYER_ID) // If someone started firing real shots
				{
					if(Player[issuerid][Team] != Player[playerid][Team]) // They're not at the same time
					{
			    		FallProtection = false; // Turn fall protection off
					}
				}
			}
		}
		#if defined _league_included
		if(LeagueMode)
		{
		    if(PlayerShop[playerid][SHOP_NINJA] && weaponid == WEAPON_COLLISION && issuerid == INVALID_PLAYER_ID)
		    {
		        /* Player has got ninja style pack from league shop */
		        SetFakeHealthArmour(playerid);
		        PlayerShop[playerid][SHOP_NINJA] = false;
				MessageBox(playerid, MSGBOX_TYPE_BOTTOM, "~p~~h~~h~ninja mode off", "You're no longer a ninja! Jump normally!", 3000);
	    		return 1;
		    }
		}
		#endif
	}
    if(weaponid == WEAPON_GRENADE)
    {
		// Handling Grenades
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
    // Slit throat with a knife
    new bool:KnifeSlitThroat = false;
    if(GetPlayerAnimationIndex(issuerid) == 748 && issuerid != INVALID_PLAYER_ID)
	{
	    // Team and distance check
	    if(GetTickCount() < Player[playerid][LastWasKnifed] || GetDistanceBetweenPlayers(playerid, issuerid) > 1.05 || (Player[issuerid][Team] == Player[playerid][Team] && Player[playerid][Playing] && Player[issuerid][Playing]))
		{
		    SetPlayerArmedWeapon(issuerid, 0);
			SyncPlayer(issuerid);
			SyncPlayer(playerid);
		    SetFakeHealthArmour(playerid);
		    CheckKnifeAbuse(issuerid);
		    return 1;
		}
		KnifeSlitThroat = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"is stabbing and slitting {FFFFFF}%s's "COL_PRIM"throat with a knife", Player[issuerid][Name], Player[playerid][Name]));
	}
 	if(issuerid == INVALID_PLAYER_ID && (IsBulletWeapon(weaponid) || IsMeleeWeapon(weaponid)))
	{
	    SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been forced to relog for having weapon bugs. {FFFFFF}(Most likely Sniper Bug)", Player[playerid][Name]));
		MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~Sniper Bug", "You likely to have Sniper Bug and a relog is needed", 3000);
		SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
 		return 1;
	}
    // <end> HP Protection for some things
    if(bodypart == 9) // If the body part that was hit is HEAD
	{
	    HandleHeadshot(playerid, issuerid, weaponid);
	}
	// Show target player info for the shooter (HP, PL, Ping and many other things)
 	ShowTargetInfo(issuerid, playerid);
	// Some checks need to be done if there's a damager
	if(issuerid != INVALID_PLAYER_ID)
	{
	    // Check whether they are in the round and in the same team or not
		if(Player[issuerid][Playing] == true && (Player[issuerid][Team] == Player[playerid][Team]))
		{
		    SetFakeHealthArmour(playerid);
			return 1;
		}
		// If the damaged player is out of the round
		if(Player[issuerid][Playing] == true && Player[playerid][Playing] == false)
		{
		    SetFakeHealthArmour(playerid);
			return 1;
		}
		// If it's a referee trying to do damage
		if(Player[issuerid][Playing] == true && Player[issuerid][Team] == REFEREE)
		{
		    SetFakeHealthArmour(playerid);
			return 1;
		}
 	}
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
	// If it's a knife kill (slitting throat)
	else if(KnifeSlitThroat != false)
	{
	    SetTimerEx("ApplyKnifeDeath", 3000, false, "d", playerid);
	}
	else // It's not a collision and the player got no armour
	    SetHP(playerid, Player[playerid][pHealth] - rounded_amount);
	// <end> Health and armour handling

	if(issuerid != INVALID_PLAYER_ID) // If the damager is a HUMAN
	{
		PlayerPlaySound(issuerid, Player[issuerid][HitSound], 0.0, 0.0, 0.0);
        PlayerPlaySound(playerid, Player[playerid][GetHitSound], 0.0, 0.0, 0.0);
        
        HandleVisualDamage(playerid, issuerid, float(rounded_amount), weaponid, bodypart);

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
            Player[issuerid][WeaponStat][weaponid] += rounded_amount;
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
					format(str, sizeof(str), "~r~~h~%d", TempDamage[ATTACKER]);
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
					format(str,sizeof(str), "~b~~h~%d", TempDamage[DEFENDER]);
					TextDrawSetString(TeamHpLose[1], str);

			        KillTimer(DefHpTimer);
			        DefHpTimer = SetTimer("HideHpTextForDef", 3000, false);
				}
		    }
		}
 	}
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
	    if(response)
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
					ClearAnimations(i);
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
    	return 1;
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
	        CallLocalFunction("OnPlayerCommandText", "ds", playerid, "/leaguestats");
	    }
	    return 1;
	}
	if(dialogid == DIALOG_LEAGUE_STATS)
	{
	    if(response)
	    {
			switch(listitem)
			{
			    case 0:
			    {
			        #if defined _league_included
					ShowLeagueAdmins(playerid);
					#else
					SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
					#endif
			    }
			    case 1: // top clans
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_CLAN);
			    }
		     	case 2: // top players
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_POINTS);
			    }
			    case 3:
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_KILLS);
			    }
			    case 4:
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_ROUNDS);
			    }
			    case 5:
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_PUNCHES);
			    }
			    case 6:
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_DAMAGE);
			    }
			    case 7:
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_SNIPER);
			    }
			    case 8:
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_DEAGLE);
			    }
			    case 9:
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_M4);
			    }
			    case 10:
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_RIFLE);
			    }
			    case 11:
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_AK);
			    }
			    case 12:
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_SPAS);
			    }
			    case 13:
			    {
			        ShowLeagueStatistics(playerid, LEAGUE_STATS_SHOTGUN);
			    }
			}
	    }
	    return 1;
	}
	if(dialogid == DIALOG_LEAGUE_CONFIRM)
	{
	    if(response)
	    	StartLeagueMode(playerid);
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
	if(dialogid == DIALOG_WEAPONBIND_MAIN)
	{
	    if(response)
	    {
	        if(listitem == 0) // Toggle
	        {
				Player[playerid][WeaponBinding] = !Player[playerid][WeaponBinding];
				new str[80];
			    format(str, sizeof(str), "UPDATE Players SET WeaponBinding = %d WHERE Name = '%s'", (Player[playerid][WeaponBinding] == true) ? (1) : (0), DB_Escape(Player[playerid][Name]));
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
			    format(str, sizeof(str), "UPDATE Players SET WeaponBind%d = %d WHERE Name = '%s'", index, weaponid, DB_Escape(Player[playerid][Name]));
			    db_free_result(db_query(sqliteconnection, str));
			    UpdatePlayerWeaponBindTextDraw(playerid);
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

		        Player[ToAddID][AntiLag] = false;

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

					Player[ToAddID][AntiLag] = false;

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
            if(listitem == 0)
            {
                if(!IsPlayerConnected(LastClickedPlayer[playerid]))
                    return 1;

                new statsSTR[4][300], namee[60], CID, Country[128];
			    CID = LastClickedPlayer[playerid];

				format(namee, sizeof(namee), "{FF3333}Player {FFFFFF}%s {FF3333}Stats", Player[CID][Name]);
				GetPlayerCountry(CID, Country, sizeof(Country));

				new TD = Player[CID][TotalDeaths];
				new RD = Player[CID][RoundDeaths];
				new MC = Player[playerid][ChatChannel];
				new YC = Player[CID][ChatChannel];

                GetPlayerFPS(CID);
				format(statsSTR[0], sizeof(statsSTR[]), "{FF0000}- {FFFFFF}Country: %s\n\n{FF0000}- {FFFFFF}Round Kills: \t\t%d\t\t{FF0000}- {FFFFFF}Total Kills: \t\t%d\t\t{FF0000}- {FFFFFF}FPS: \t\t\t%d\n{FF0000}- {FFFFFF}Round Deaths: \t%.0f\t\t{FF0000}- {FFFFFF}Total Deaths: \t\t%d\t\t{FF0000}- {FFFFFF}Ping: \t\t\t%d\n",Country,  Player[CID][RoundKills],Player[CID][TotalKills], Player[CID][FPS], RD, TD, GetPlayerPing(CID));
				format(statsSTR[1], sizeof(statsSTR[]), "{FF0000}- {FFFFFF}Round Damage: \t%d\t\t{FF0000}- {FFFFFF}Total Damage:   \t%d\t\t{FF0000}- {FFFFFF}Packet-Loss:   \t%.1f\n\n{FF0000}- {FFFFFF}Player Weather: \t%d\t\t{FF0000}- {FFFFFF}Chat Channel: \t%d\t\t\t{FF0000}- {FFFFFF}In Round: \t\t%s\n",Player[CID][RoundDamage],Player[CID][TotalDamage], GetPlayerPacketLoss(CID), Player[CID][Weather], (MC == YC ? YC : -1), (Player[CID][Playing] == true ? ("Yes") : ("No")));
				format(statsSTR[2], sizeof(statsSTR[]), "{FF0000}- {FFFFFF}Player Time: \t\t%d\t\t{FF0000}- {FFFFFF}DM ID: \t\t%d\t\t{FF0000}- {FFFFFF}Hit Sound: \t\t%d\n{FF0000}- {FFFFFF}Player NetCheck: \t%s\t{FF0000}- {FFFFFF}Player Level: \t\t%d\t\t{FF0000}- {FFFFFF}Get Hit Sound: \t\t%d\n", Player[CID][Time], (Player[CID][DMReadd] > 0 ? Player[CID][DMReadd] : -1), Player[CID][HitSound], (Player[CID][NetCheck] == 1 ? ("Enabled") : ("Disabled")), Player[CID][Level], Player[CID][GetHitSound]);
				format(statsSTR[3], sizeof(statsSTR[]), "{FF0000}- {FFFFFF}Duels Won: \t\t%d\t\t{FF0000}- {FFFFFF}Duels Lost: \t\t%d", Player[CID][DuelsWon], Player[CID][DuelsLost]);
				new TotalStr[1200];
				format(TotalStr, sizeof(TotalStr), "%s%s%s%s", statsSTR[0], statsSTR[1], statsSTR[2], statsSTR[3]);

				ShowPlayerDialog(playerid, DIALOG_CLICK_STATS, DIALOG_STYLE_MSGBOX, namee, TotalStr, "Close", "");
				return 1;
			}
            else if(listitem == 1)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/spec %d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 2)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/add %d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 3)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/remove %d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 4)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/readd %d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 5)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/givemenu %d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 6)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/goto %d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 7)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/get %d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 8)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/slap %d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 9)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/mute %d No Reason Specified", LastClickedPlayer[playerid]));
            }
            else if(listitem == 10)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/unmute %d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 11)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/kick %d No Reason Specified", LastClickedPlayer[playerid]));
            }
            else if(listitem == 12)
            {
                CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/ban %d No Reason Specified", LastClickedPlayer[playerid]));
            }
        }
	    return 1;
	}
    if(dialogid == EDITSHORTCUTS_DIALOG)
    {
        if(response)
        {
            EditingShortcutOf{playerid} = listitem;
            ShowPlayerDialog(playerid, GETVAL_DIAG, DIALOG_STYLE_INPUT, "Editing shortcut", "Please enter a text", "Done", "Cancel");
        }
        return 1;
    }
	if(dialogid == GETVAL_DIAG)
	{
	    if(response)
	    {
	        if(EditingShortcutOf{playerid} != 250)
	        {
	            switch(EditingShortcutOf{playerid})
	            {
	                case 0:
	                { format(PlayerShortcut[playerid][Shortcut1], 50, "%s", inputtext); }
	                case 1:
	                { format(PlayerShortcut[playerid][Shortcut2], 50, "%s", inputtext); }
	                case 2:
	                { format(PlayerShortcut[playerid][Shortcut3], 50, "%s", inputtext); }
	                case 3:
	                { format(PlayerShortcut[playerid][Shortcut4], 50, "%s", inputtext); }
	            }
	            EditingShortcutOf{playerid} = 250;
             	CallLocalFunction("OnPlayerCommandText", "ds", playerid, "/shortcuts");
				return 1;
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
			format(query, sizeof(query), "INSERT INTO Players (Name, Password, IP, LastSeen_Day, LastSeen_Month, LastSeen_Year) VALUES('%s', '%s', '%s', %d, %d, %d)", DB_Escape(Player[playerid][Name]), HashPass, IP, day, month, year);
			db_free_result(db_query(sqliteconnection, query));

			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~g~~h~register", sprintf("You've successfully registered your account with the password: %s", inputtext), 4000);
            MessageBox(playerid, MSGBOX_TYPE_TOP, "~y~select your class", "~>~ to view next class~n~~<~ to view prev class~n~~n~(SPAWN) to select the current class", 7000);

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
	if(dialogid == DIALOG_LEAGUE_LOGIN)
	{
	    if(response)
	    {
	        if(isnull(inputtext))
				return ShowPlayerDialog(playerid, DIALOG_LEAGUE_LOGIN, DIALOG_STYLE_PASSWORD,"{FFFFFF}League Clan Login","{FFFFFF}Type your league account password below to continue:","Login","Quit");

            if(strfind(inputtext, "%", true) != -1)
			{
			    ShowPlayerDialog(playerid, DIALOG_LEAGUE_LOGIN, DIALOG_STYLE_PASSWORD,"{FFFFFF}League Clan Login","{FFFFFF}Type your league account password below to continue:","Login","Quit");
				return SendErrorMessage(playerid, sprintf("This character '%s' is disallowed in user passwords.", "%%"));
			}
            CheckPlayerLeagueAccount(playerid, inputtext);
	    }
	    else
	    {
	        new iString[128];
			format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has been kicked for not entering league account password.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
			SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
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
			format(Query, sizeof(Query), "SELECT * FROM `Players` WHERE `Name` = '%s' AND `Password` = '%s'", DB_Escape(Player[playerid][Name]), HashPass);
		    new DBResult:res = db_query(sqliteconnection, Query);

			if(db_num_rows(res))
			{
				LoginPlayer(playerid, res);
				MessageBox(playerid, MSGBOX_TYPE_TOP, "~y~select your class", "~>~ to view next class~n~~<~ to view prev class~n~~n~(SPAWN) to select the current class", 7000);
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

            new iString[64];
			format(iString, sizeof(iString), "%sServer Pass: ~r~~h~%s", MAIN_TEXT_COLOUR, inputtext);
			TextDrawSetString(LockServerTD, iString);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has locked the server. Password: {FFFFFF}%s",Player[playerid][Name], inputtext);
			SendClientMessageToAll(-1, iString);
		}
		return 1;
	}

	if(dialogid == DIALOG_CURRENT_TOTAL)
	{
	    #if defined _league_included
	    if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
	        return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	    #endif
		if(isnull(inputtext)) return 1;
        if(!IsNumeric(inputtext)) {
            SendErrorMessage(playerid,"You can only use numeric input.");
            new iString[64];
			iString = ""COL_PRIM"Enter current round or total rounds to be played:";
    		ShowPlayerDialog(playerid, DIALOG_CURRENT_TOTAL, DIALOG_STYLE_INPUT,""COL_PRIM"Rounds Dialog",iString,"Current","Total");
			return 1;
		}

		new Value = strval(inputtext);

		if(Value < 0 || Value > 100) {
            SendErrorMessage(playerid,"Current or total rounds can only be between 0 and 100.");
            new iString[64];
			iString = ""COL_PRIM"Enter current round or total rounds to be played:";
    		ShowPlayerDialog(playerid, DIALOG_CURRENT_TOTAL, DIALOG_STYLE_INPUT,""COL_PRIM"Rounds Dialog",iString,"Current","Total");
			return 1;
		}

        new iString[128];

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
		    #if defined _league_included
      if(LeagueMode) return SendErrorMessage(playerid, "Can't do this when league mode is enabled.");
		    #endif
		    new iString[128];
		    switch(listitem) {
		        case 0: {
					iString = ""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:";
				    ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",iString,"Next","Close");
				} case 1: {
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
					    for(new j = 0; j < 55; j ++)
	    					Player[i][WeaponStat][j] = 0;
		   				Player[i][TotalKills] = 0;
						Player[i][TotalDeaths] = 0;
						Player[i][TotalDamage] = 0;
						Player[i][RoundPlayed] = 0;
					    Player[i][TotalBulletsFired] = 0;
					    Player[i][TotalshotsHit] = 0;
					}

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
		    #if defined _league_included
			if(LeagueMode)
			{
			    return SendErrorMessage(playerid, "Can't do this while league-mode is on.");
			}
			#endif
		    TeamScore[ATTACKER] = 0;
		    TeamScore[DEFENDER] = 0;
		    CurrentRound = 0;

            new iString[128];
			format(iString, sizeof(iString), "SELECT * FROM Configs WHERE Option = 'Total Rounds'");
		    new DBResult:res = db_query(sqliteconnection, iString);

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
			    //for(new j = 0; j < 55; j ++)
  				//	Player[i][WeaponStat][j] = 0;
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

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled the Match-Mode.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		}
		return 1;
	}

	if(dialogid == DIALOG_ATT_NAME) {
	    if(response) {
	        #if defined _league_included
         if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
			#endif
	        new iString[128];
			if(isnull(inputtext)) {
				iString = ""COL_PRIM"Enter {FFFFFF}Defender "COL_PRIM"Team Name Below:";
			    ShowPlayerDialog(playerid, DIALOG_DEF_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Name",iString,"Ok","Close");
				return 1;
			}
			if(strlen(inputtext) > 6) {
            	SendErrorMessage(playerid,"Team name is too long.");
				iString = ""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:";
			    ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",iString,"Next","Close");
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

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set attacker team name to: {FFFFFF}%s", Player[playerid][Name], TeamName[ATTACKER]);
			SendClientMessageToAll(-1, iString);

			iString = ""COL_PRIM"Enter {FFFFFF}Defender "COL_PRIM"Team Name Below:";
		    ShowPlayerDialog(playerid, DIALOG_DEF_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Name",iString,"Ok","Close");
		}
		return 1;
	}

	if(dialogid == DIALOG_DEF_NAME)
	{
	    if(response)
		{
	        if(isnull(inputtext)) return 1;
	        #if defined _league_included
         if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	        #endif
	        if(strlen(inputtext) > 6) {
	           	SendErrorMessage(playerid,"Team name is too long.");
	           	new iString[64];
				iString = ""COL_PRIM"Enter {FFFFFF}Defender "COL_PRIM"Team Name Below:";
			    ShowPlayerDialog(playerid, DIALOG_DEF_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Name",iString,"Ok","Close");
				return 1;
			}

			if(strfind(inputtext, "~") != -1) {
			    return SendErrorMessage(playerid,"~ not allowed.");
			}

			format(TeamName[DEFENDER], 24, inputtext);
			format(TeamName[DEFENDER_SUB], 24, "%s Sub", TeamName[DEFENDER]);

            new iString[128];
			UpdateTeamScoreTextDraw();
			UpdateRoundsPlayedTextDraw();
			UpdateTeamNameTextDraw();
		    
		    UpdateTeamNamesTextdraw();

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set defender team name to: {FFFFFF}%s", Player[playerid][Name], TeamName[DEFENDER]);
			SendClientMessageToAll(-1, iString);

		    WarMode = true;
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
		    #if defined _league_included
      if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
		    #endif
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

            #if defined _league_included
            if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
            #endif
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
		    new iString[128];
	        switch(listitem)
			{
	            case 0: {
	                #if defined _league_included
                    if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
                    #endif
	                iString = ""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:";
				    ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",iString,"Next","Close");
	            }
	            case 1: {
	                #if defined _league_included
                 if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	                #endif
	                format(iString, sizeof(iString), "%sAttacker Team\n%sDefender Team", TextColor[ATTACKER], TextColor[DEFENDER]);
	                ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_TEAM_SKIN, DIALOG_STYLE_LIST, ""COL_PRIM"Select team", iString, "OK", "Cancel");
	            }
				case 2: {
				    #if defined _league_included
        if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
				    #endif
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_AAD, DIALOG_STYLE_LIST, ""COL_PRIM"A/D Config", ""COL_PRIM"Health\n"COL_PRIM"Armour\n"COL_PRIM"Round Time\n"COL_PRIM"CP Time", "OK", "Cancel");
				}
				case 3: {
				    SendRconCommand("gmx");
				}
				case 4: {
				    #if defined _league_included
        if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
				    #endif
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_MAX_PING, DIALOG_STYLE_INPUT, ""COL_PRIM"Set max Ping", "Set the max ping:", "OK", "Cancel");
				}
				case 5: {
                    #if defined _league_included
        if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
				    #endif
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_MAX_PACKET, DIALOG_STYLE_INPUT, ""COL_PRIM"Set max Packetloss", "Set the max packetloss:", "OK", "Cancel");
				}
				case 6: {
				    #if defined _league_included
				    if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
				    #endif
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_MIN_FPS, DIALOG_STYLE_INPUT, ""COL_PRIM"Set Minimum FPS", "Set the minimum FPS:", "OK", "Cancel");
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
						format(string, sizeof string, "%s\n{FF6666}%s Sub", string, TeamName[ATTACKER]);
	 				}
				 	else
				 	{
				 	    format(string, sizeof string, "%s\n{66FF66}%s Sub", string, TeamName[ATTACKER]);
	 				}

	 				if(strlen(GroupAccessPassword[3]) > 0)
					{
						format(string, sizeof string, "%s\n{FF6666}%s Sub", string, TeamName[DEFENDER]);
	 				}
				 	else
				 	{
				 	    format(string, sizeof string, "%s\n{66FF66}%s Sub", string, TeamName[DEFENDER]);
	 				}

	 				if(strlen(GroupAccessPassword[4]) > 0)
					{
						format(string, sizeof string, "%s\n{FF6666}Referee", string);
	 				}
				 	else
				 	{
				 	    format(string, sizeof string, "%s\n{66FF66}Referee", string);
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
				    #if defined _league_included
				    if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
				    #endif
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
				    #if defined _league_included
				    if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
				    #endif
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
				case 13: {
				    if(ShortCuts == false) {
					    ShortCuts = true;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"shortcut team messages.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
				    } else {
				        ShortCuts = false;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"shortcut team messages.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}
                    ShowConfigDialog(playerid);
				}
				case 14: {
					if(ChangeName == false)
					{
					    ChangeName = true;

					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"(/changename){FFFFFF} command.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}
					else
					{
					    ChangeName = false;
					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"(/changename){FFFFFF} command.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}

					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'ChangeName'", (ChangeName == false ? 0 : 1));
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
	        case 2: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_GA_ASUB, DIALOG_STYLE_INPUT, ""COL_PRIM"ALPHA SUB PASSWORD", ""COL_PRIM"Set the password or leave empty to clear:", "OK", "Cancel"); }
	        case 3: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_GA_BSUB, DIALOG_STYLE_INPUT, ""COL_PRIM"BETA SUB PASSWORD", ""COL_PRIM"Set the password or leave empty to clear:", "OK", "Cancel"); }
	        case 4: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_GA_REF, DIALOG_STYLE_INPUT, ""COL_PRIM"REFEREE PASSWORD", ""COL_PRIM"Set the password or leave empty to clear:", "OK", "Cancel"); }
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
	
	if(dialogid == DIALOG_CONFIG_SET_GA_ASUB)
	{
	    if(!response) return ShowConfigDialog(playerid);
        if(strlen(inputtext) > MAX_GROUP_ACCESS_PASSWORD_LENGTH)
	    {
	        SendErrorMessage(playerid, "The password you entered is quite long. Try again with a shorter one!", MSGBOX_TYPE_BOTTOM);
	        return ShowConfigDialog(playerid);
	    }
		format(GroupAccessPassword[2], MAX_GROUP_ACCESS_PASSWORD_LENGTH, "%s", inputtext);
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
		format(GroupAccessPassword[3], MAX_GROUP_ACCESS_PASSWORD_LENGTH, "%s", inputtext);
	    new str[128];
		format(str, sizeof(str), "%s "COL_PRIM"has changed the beta sub group access", Player[playerid][Name]);
		SendClientMessageToAll(-1, str);
	    return ShowConfigDialog(playerid);
	}
	
	if(dialogid == DIALOG_GROUPACCESS)
	{
	    if(!response || !strlen(inputtext)) return ShowConfigDialog(playerid);
	    new groupID = Player[playerid][RequestedClass]-1;
	
	    if(strcmp(inputtext,GroupAccessPassword[groupID])!=0)
		{
			return ShowPlayerDialog(playerid, DIALOG_GROUPACCESS, DIALOG_STYLE_INPUT, "Authorization required", "Your entered password was invalid.\n\nPlease enter the group password:", "Submit", "Cancel");
  		}
  		
  		format(RequestedGroupPass[playerid][groupID], MAX_GROUP_ACCESS_PASSWORD_LENGTH, "%s", inputtext);
	  	OnPlayerRequestSpawn(playerid);
	    return 1;
	}
	
	if(dialogid == DIALOG_CONFIG_SET_GA_REF && response)
	{
	    if(!response) return ShowConfigDialog(playerid);
	    if(strlen(inputtext) > MAX_GROUP_ACCESS_PASSWORD_LENGTH)
	    {
	        SendErrorMessage(playerid, "The password you entered is quite long. Try again with a shorter one!", MSGBOX_TYPE_BOTTOM);
	        return ShowConfigDialog(playerid);
	    }
	    format(GroupAccessPassword[4], MAX_GROUP_ACCESS_PASSWORD_LENGTH, "%s", inputtext);
	    new str[128];
		format(str, sizeof(str), "%s "COL_PRIM"has changed the referee group access", Player[playerid][Name]);
		SendClientMessageToAll(-1, str);
	    return ShowConfigDialog(playerid);
	}

	if(dialogid == DIALOG_CONFIG_SET_TEAM_SKIN) {
	    if(response)
		{
			switch(listitem)
			{
				case 0: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ATT_SKIN, DIALOG_STYLE_INPUT, ""COL_PRIM"Attacker Name", ""COL_PRIM"Set the attacker skin below:", "OK", "Cancel"); }
		        case 1: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_DEF_SKIN, DIALOG_STYLE_INPUT, ""COL_PRIM"Defender Name", ""COL_PRIM"Set the defender skin below:", "OK", "Cancel"); }
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
		    #if defined _league_included
		    if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
		    #endif
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

	if(dialogid == DIALOG_CONFIG_SET_ATT_SKIN) {
	    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/teamskin 0 %s", inputtext));
	    ShowConfigDialog(playerid);
	    return 1;
	}

	if(dialogid == DIALOG_CONFIG_SET_DEF_SKIN) {
	    CallLocalFunction("OnPlayerCommandText", "ds", playerid, sprintf("/teamskin 1 %s", inputtext));
	    ShowConfigDialog(playerid);
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

	if(dialogid == DIALOG_SWITCH_TEAM) {
	    if(response) {
	        switch(listitem) {
	            case 0: {
      				SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
            		Player[playerid][Team] = ATTACKER;
				} case 1: {
				    SetPlayerColor(playerid, ATTACKER_SUB_COLOR);
				    Player[playerid][Team] = ATTACKER_SUB;
				} case 2: {
				    SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
				    Player[playerid][Team] = DEFENDER;
				} case 3: {
				    SetPlayerColor(playerid, DEFENDER_SUB_COLOR);
				    Player[playerid][Team] = DEFENDER_SUB;
				} case 4: {
				    SetPlayerColor(playerid, REFEREE_COLOR);
				    Player[playerid][Team] = REFEREE;
				}
			}
			SwitchTeamFix(playerid);
		}
		return 1;
	}

	if(dialogid == DIALOG_SWITCH_TEAM_CLASS)
	{
	    if(response)
		{
	        switch(listitem)
			{
	            case 0:
				{
      				SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
            		Player[playerid][Team] = ATTACKER;
				}
				case 1:
				{
				    SetPlayerColor(playerid, ATTACKER_SUB_COLOR);
				    Player[playerid][Team] = ATTACKER_SUB;
				}
				case 2:
				{
				    SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
				    Player[playerid][Team] = DEFENDER;
				}
				case 3:
				{
				    SetPlayerColor(playerid, DEFENDER_SUB_COLOR);
				    Player[playerid][Team] = DEFENDER_SUB;
				}
				case 4:
				{
				    SetPlayerColor(playerid, REFEREE_COLOR);
				    Player[playerid][Team] = REFEREE;
				}
			}
			SwitchTeamFix(playerid);
			SpawnPlayer(playerid);
		}
		else
		{
		    new iString[128];
			format(iString, sizeof(iString), "%s%s\n%s%s Sub\n%s%s\n%s%s Sub\n%sReferee", TextColor[ATTACKER], TeamName[ATTACKER], TextColor[ATTACKER_SUB], TeamName[ATTACKER], TextColor[DEFENDER], TeamName[DEFENDER], TextColor[DEFENDER_SUB], TeamName[DEFENDER], TextColor[REFEREE]);
			ShowPlayerDialog(playerid, DIALOG_SWITCH_TEAM_CLASS, DIALOG_STYLE_LIST, "{FFFFFF}Team Selection",iString, "Select", "Exit");
		}
		return 1;
	}
	#if defined _league_included
	// League login dialog lock - so that players can't escape the league clan login check
	if(Player[playerid][MustLeaguePass] == true)
	{
	    ShowPlayerDialog(
			playerid,
			DIALOG_LEAGUE_LOGIN,
			DIALOG_STYLE_PASSWORD,
			"{FFFFFF}League Clan Login","{FFFFFF}Looks like your name is registered in our league system database.\nIf this isn't you, then please quit the game and join with another name or type your league account\nPASSWORD below to continue:",
			"Login",
			"Quit"
		);
	}
	#endif
	return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    #if GTAV_SWITCH_MENU != 0
    if(Player[playerid][OnGunSwitch])
    {
        new index = -1;
        for(new i = 0; i < MAX_GUN_SWITCH_SLOTS; i ++)
		{
			if(!GunSwitchData[playerid][GunSwitchSlotShown][i])
				continue;
				
			if(GunSwitchData[playerid][GunSlotTextDraw][i] == playertextid)
			{
			    index = i;
				break;
			}
		}
		if(GetPlayerVehicleID(playerid) == 0)
        	SetPlayerArmedWeapon(playerid, GetWeaponIDFromModelID(GunSwitchData[playerid][GunSwitchModelID][index]));
		else
		    SetPlayerArmedWeapon(playerid, 0);
		    
		DisablePlayerGunSwitchInterface(playerid);
    }
    #endif
	return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(clickedid == Text:INVALID_TEXT_DRAW)
	{
	    #if GTAV_SWITCH_MENU != 0
	    if(Player[playerid][OnGunSwitch])
	    {
	        DisablePlayerGunSwitchInterface(playerid);
	        return 1;
	    }
		#endif
	 	TextDrawHideForPlayer(playerid, LeagueToggleTD);
        TextDrawHideForPlayer(playerid, WarModeText);
        TextDrawHideForPlayer(playerid, SettingBox);
        TextDrawHideForPlayer(playerid, LockServerTD);
        TextDrawHideForPlayer(playerid, CloseText);

        CancelSelectTextDraw(playerid);
	    return 1;
	}
	if(clickedid == LeagueToggleTD)
	{
	    CallLocalFunction("OnPlayerCommandText", "ds", playerid, "/league");
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
			    for(new j = 0; j < 55; j ++)
  					Player[i][WeaponStat][j] = 0;
   				Player[i][TotalKills] = 0;
				Player[i][TotalDeaths] = 0;
				Player[i][TotalDamage] = 0;
				Player[i][RoundPlayed] = 0;
			    Player[i][TotalBulletsFired] = 0;
			    Player[i][TotalshotsHit] = 0;
			}
            new iString[64];
			iString = ""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:";
	    	ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",iString,"Next","Close");
		} else {
		    #if defined _league_included
		    if(LeagueMode) return SendErrorMessage(playerid, "Can't do this when league mode is enabled. Use /war end instead!");
		    #endif
	    	ShowPlayerDialog(playerid, DIALOG_WAR_RESET, DIALOG_STYLE_MSGBOX,""COL_PRIM"War Dialog",""COL_PRIM"Are you sure you want to turn War Mode off?","Yes","No");
		}

		return 1;
	}

	if(clickedid == LockServerTD) {
		if(ServerLocked == false) {
		   ShowPlayerDialog(playerid, DIALOG_SERVER_PASS, DIALOG_STYLE_INPUT,""COL_PRIM"Server Password",""COL_PRIM"Enter server password below:", "Ok","Close");
		} else {
		    new iString[128];
			iString = "password 0";
			SendRconCommand(iString);

			format(iString, sizeof iString, "%sServer: ~r~Unlocked", MAIN_TEXT_COLOUR);
			TextDrawSetString(LockServerTD, iString);

			ServerLocked = false;
			PermLocked = false;

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unlocked the server.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		}
		return 1;
	}

	if(clickedid == CloseText) {
        TextDrawHideForPlayer(playerid, LeagueToggleTD);
        TextDrawHideForPlayer(playerid, WarModeText);
        TextDrawHideForPlayer(playerid, SettingBox);
        TextDrawHideForPlayer(playerid, LockServerTD);
        TextDrawHideForPlayer(playerid, CloseText);

        CancelSelectTextDraw(playerid);
        return 1;
	}

	if(PlayerOnInterface{playerid} == true) {
	    if(clickedid == Text:65535) {
	        TextDrawHideForPlayer(playerid, LeagueToggleTD);
	        TextDrawHideForPlayer(playerid, WarModeText);
	        TextDrawHideForPlayer(playerid, SettingBox);
	        TextDrawHideForPlayer(playerid, LockServerTD);
	        TextDrawHideForPlayer(playerid, CloseText);
		}
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
            MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~y~~h~Unknown Command", sprintf("~r~~h~%s ~w~is an unknown command. Check /cmds, /acmds or /cmdhelp for more info!", cmdtext), 3000);
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
	 sprintf(""COL_PRIM"Server version: {FFFFFF}%s "COL_PRIM"| Newest version: {FFFFFF}%s", GM_NAME, LatestVersionStr), "Okay", "");
	return 1;
}

YCMD:changelog(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display a list of gamemode updates");
	    return 1;
	}
	new str[1];
	ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX,""COL_PRIM"Bulletproof Changelog", str, "OK","");
	return 1;
}

YCMD:help(playerid, params[], help)
{
	if(help)
	{
	    SendCommandHelpMessage(playerid, "display some guidelines");
	    return 1;
	}
    new HelpString[1024];
	strcat(HelpString, "\t\t\t\t\t"COL_PRIM"Current Developers: {FFFFFF}Whitetiger & [KHK]Khalid");
	strcat(HelpString, "\n"COL_PRIM"This is a re-written & improved version of Att-Def GM so shoutout to all who contributed to the old GM over the world :]");
	strcat(HelpString, "\n\n"COL_PRIM"Match-Mode Help:");
	strcat(HelpString, "\n{FFFFFF}To enable Match-Mode, press 'Y' in lobby or 'H' in round and most textdraws will be clickable.");
	strcat(HelpString, "\nOr use /war if you're in a hurry! Moreover, you can click on match textdraws to set team names, score and etc");
	strcat(HelpString, "\n\n"COL_PRIM"Server Help:");
	strcat(HelpString, "\n{FFFFFF}For admin commands, type /acmds and for public commands type /cmds");
	strcat(HelpString, "\nIf you need help with a command, use /cmdhelp");
	strcat(HelpString, "\nRound can be paused by pressing 'Y' (for admins only).");
	strcat(HelpString, "\nYou can request for backup from your team by pressing 'N' in round.");
	strcat(HelpString, "\nYou can ask for pausing the round by pressing 'Y' in round.");
	ShowPlayerDialog(playerid,DIALOG_NO_RESPONSE,DIALOG_STYLE_MSGBOX,""COL_PRIM"Server Help", HelpString, "OK","");
	return 1;
}

YCMD:cmds(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display server commands");
	    return 1;
	}
	new str[1024], cmdsInLine = 0;
	strcat(str,
		"Use ! for team chat\nPress N to request for backup in a round\nPress H to lead your team\nUse # to talk in chat channel\nUse @ for admin chat\nIf you need help with a command, use /cmdhelp\n\n");
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
	strcat(str, "Use @ for admin chat");
	#if defined _league_included
	new level;
	if(LeagueMode && IsLeagueMod(playerid))
	{
	    level = 5;
	}
	else
	{
		level = Player[playerid][Level];
	}
	#else
	new level = Player[playerid][Level];
	#endif
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
    //if(Player[playerid][Level] < 4) return SendErrorMessage(playerid,"You must be level 4 to use this command.");
    ClearAdminCommandLog();
    SendClientMessage(playerid, -1, "Admin command log has been successfully cleared!");
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
	    return SendUsageMessage(playerid,"/hud [HUD ID] [on / off]~n~~n~HUD IDs:~n~-1 = ALL~n~0 = spectators~n~1 = net stats~n~2 = hp percent");

	if(hudid < -1 || hudid == MAX_PLAYER_INTERFACE_ASPECTS)
	    return SendErrorMessage(playerid, "Invalid HUD ID");
	    
    new bool:toggle;
	if(strcmp(toggleStr, "on", true) == 0)
		toggle = true;
	else if(strcmp(toggleStr, "off", true) == 0)
		toggle = false;
	else
		return SendUsageMessage(playerid,"/hud [HUD ID] [on / off]~n~~n~HUD IDs:~n~0 = spectators~n~1 = net stats~n~2 = hp percent");
		
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

    db_free_result(db_query(sqliteconnection, sprintf("DELETE FROM Players WHERE Name = '%s'", DB_Escape(str))));
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

	format(iString, sizeof(iString), "UPDATE Players SET Level = %d WHERE Name = '%s'", lev, DB_Escape(str));
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
	new string[200];

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
	format(string, sizeof(string), "{FFFFFF}Team Chat Shortcuts = %s", (ShortCuts == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")));
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
	ShowPlayerShopDialog(playerid);
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
	    SendErrorMessage(playerid, "League mode has to be enabled!");
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
	if(Player[playerid][AntiLag] == true) return SendErrorMessage(playerid,"Can't use this command in anti-lag zone.");

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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif
	new iString[160];

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
	if(Player[playerid][AntiLag] == true) return 1;
	if(Player[playerid][Spectating] == true) return 1;

	if(noclipdata[playerid][FlyMode] == true)
	{
		CancelFlyMode(playerid);
		PlayerTextDrawShow(playerid, RoundKillDmgTDmg[playerid]);
		if(PlayerInterface[playerid][INTERFACE_NET])
			PlayerTextDrawShow(playerid, FPSPingPacket[playerid]);
		PlayerTextDrawShow(playerid, BaseID_VS[playerid]);
  		switch(PlayerInterface[playerid][INTERFACE_HP])
		{
			case true:
			{
				PlayerTextDrawShow(playerid, HPTextDraw_TD[playerid]);
				PlayerTextDrawShow(playerid, ArmourTextDraw[playerid]);
			}
		}
		ShowPlayerProgressBar(playerid, HealthBar[playerid]);
		ShowPlayerProgressBar(playerid, ArmourBar[playerid]);
	}
	else
	{
		PlayerFlyMode(playerid);
		SendClientMessage(playerid, -1, "Use /specoff to exit FreeCam!");
		PlayerTextDrawHide(playerid, RoundKillDmgTDmg[playerid]);
		PlayerTextDrawHide(playerid, FPSPingPacket[playerid]);
		PlayerTextDrawHide(playerid, BaseID_VS[playerid]);
		PlayerTextDrawHide(playerid, HPTextDraw_TD[playerid]);
		PlayerTextDrawHide(playerid, ArmourTextDraw[playerid]);
		HidePlayerProgressBar(playerid, HealthBar[playerid]);
		HidePlayerProgressBar(playerid, ArmourBar[playerid]);
	}
	LogAdminCommand("freecam", playerid, INVALID_PLAYER_ID);
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
    #if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif
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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif
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
	new iString[128];

	if(Player[playerid][InDM] == true) QuitDM(playerid);
   	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use /rq instead.");
   	if(Player[playerid][Playing] == true)
        return SendErrorMessage(playerid, "Cannot go to lobby while you're playing. Use /rem maybe?");

	if(Player[playerid][AntiLag] == true) {
	    Player[playerid][AntiLag] = false;

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has quit the Anti-Lag zone.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
	}
    SpawnPlayerEx(playerid);
	return 1;
}

YCMD:duel(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "send a duel request to a specific player.");
	    return 1;
	}
	new invitedid, Weapon1[23], Weapon2[23], duelarena[8], size;

 	if(sscanf(params, "isiss", invitedid, duelarena, size, Weapon1, Weapon2)) return SendUsageMessage(playerid,"/duel [Player ID] [default/custom] [area size] [Weapon 1] [Weapon 2]~n~~n~[custom] to play in your current zone~n~[default] for default duel arena");

	if(!IsPlayerConnected(invitedid)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[invitedid][Playing] == true) return SendErrorMessage(playerid,"That player is in a round.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"You can't duel while being in a round.");
	if(Player[invitedid][InDuel] == true) return SendErrorMessage(playerid,"That player is already dueling someone.");
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"You are already dueling someone.");
	if(Player[invitedid][challengerid] == playerid) return SendErrorMessage(playerid,"You have already invited that player for duel. Let him accept or deny your previous invite.");    //duelspamfix
	if(invitedid == playerid) return SendErrorMessage(playerid,"Can't duel with yourself.");
	
	if(isnull(duelarena) || IsNumeric(duelarena)) return
	SendUsageMessage(playerid,"/duel [Player ID] [default/custom] [area size] [Weapon 1] [Weapon 2]~n~~n~[custom] to play in your current zone~n~[default] for default duel arena");

	new duelarenaid;
    if(!strcmp(duelarena, "default", true))
	{
        duelarenaid = DEFAULT_DUEL_ARENA_ID;
	}
	else if(!strcmp(duelarena, "custom", true))
	{
        duelarenaid = 1 + DEFAULT_DUEL_ARENA_ID;
	}
	else
		return SendUsageMessage(playerid,"/duel [Player ID] [default/custom] [area size] [Weapon 1] [Weapon 2]~n~~n~[custom] to play in your current zone~n~[default] for default duel arena");

	if(size < 60)
	    return SendErrorMessage(playerid, "Size cannot be less than 60 units.");

	new WeaponID1 = GetWeaponID(Weapon1);
	if(WeaponID1 < 1 || WeaponID1 > 46 || WeaponID1 == 19 || WeaponID1 == 20 || WeaponID1 == 21) return SendErrorMessage(playerid,"Invalid Weapon Name.");
	if(WeaponID1 == 40 || WeaponID1 == 43 || WeaponID1 == 44 || WeaponID1 == 45) return SendErrorMessage(playerid,"That weapon is not allowed in duels.");

	new WeaponID2 = GetWeaponID(Weapon2);
	if(WeaponID2 < 1 || WeaponID2 > 46 || WeaponID2 == 19 || WeaponID2 == 20 || WeaponID2 == 21) return SendErrorMessage(playerid,"Invalid Weapon Name.");
	if(WeaponID2 == 40 || WeaponID2 == 43 || WeaponID2 == 44 || WeaponID2 == 45) return SendErrorMessage(playerid,"That weapon is not allowed in duels.");

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

					format(iString, sizeof(iString), "UPDATE Players SET Weather = %d WHERE Name = '%s'", Player[i][Weather], DB_Escape(Player[i][Name]));
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

					format(iString, sizeof(iString), "UPDATE Players SET Time = %d WHERE Name = '%s'", Player[i][Time], DB_Escape(Player[i][Name]));
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
	        
	        /*format(iString, sizeof(iString), "SELECT ID FROM Bases ORDER BY `ID` DESC LIMIT 1");
			new DBResult:res = db_query(sqliteconnection, iString);

			new BaseID;
			if(db_num_rows(res)) {
				db_get_field_assoc(res, "ID", iString, sizeof(iString));
	    		BaseID = strval(iString)+1;
		    }
		    db_free_result(res);*/

		    if(TotalBases > MAX_BASES)
				return SendErrorMessage(playerid,"Too many bases already created.");

            new BaseID;
			BaseID = FindFreeBaseSlot();
			format(iString, sizeof(iString), "INSERT INTO Bases (ID, AttSpawn, CPSpawn, DefSpawn, Interior, Name) VALUES (%d, 0, 0, 0, 0, 'No Name')", BaseID);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has created {FFFFFF}Base ID: %d", Player[playerid][Name], BaseID);
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

			format(iString, sizeof(iString), "UPDATE Bases SET AttSpawn = '%s' WHERE ID = %d", PositionA, baseid);
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

			format(iString, sizeof(iString), "UPDATE Bases SET DefSpawn = '%s' WHERE ID = %d", PositionB, baseid);
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

			format(iString, sizeof(iString), "UPDATE Bases SET CPSpawn = '%s', Interior = %d WHERE ID = %d", cp, GetPlayerInterior(playerid), baseid);
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

			format(iString, sizeof(iString), "UPDATE Bases SET Name = '%s' WHERE ID = %d", BaseName, baseid);
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

			format(iString, sizeof(iString), "DELETE FROM Bases WHERE ID = %d", baseid);
			db_free_result(db_query(sqliteconnection, iString));
			
			BExist[baseid] = false;

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has deleted {FFFFFF}Base ID: %d", Player[playerid][Name], baseid);
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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif
	new iString[160];

    TeamScore[ATTACKER] = 0;
    TeamScore[DEFENDER] = 0;
    CurrentRound = 0;

	UpdateTeamScoreTextDraw();
	UpdateRoundsPlayedTextDraw();
	UpdateTeamNameTextDraw();

	ClearPlayerVariables();

	foreach(new i : Player) {
	    for(new j = 0; j < 55; j ++)
			Player[i][WeaponStat][j] = 0;
		Player[i][TotalKills] = 0;
		Player[i][TotalDeaths] = 0;
		Player[i][TotalDamage] = 0;
		Player[i][RoundPlayed] = 0;
	    Player[i][TotalBulletsFired] = 0;
	    Player[i][TotalshotsHit] = 0;
	}

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

	Player[playerid][AntiLag] = false;

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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif
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
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s (%d) "COL_PRIM"temporarily disabled netcheck on him for 15 seconds. You may want to permanently disable it!", Player[playerid][Name], playerid));
		SetTimerEx("RemoveTempNetcheck", 15000, false, "i", playerid);
	}
	else
	{
		new tmp, minute;
		gettime(tmp, minute, tmp);
		if((minute - Player[playerid][CanNetcheck]) > 20)
		{
		    Player[playerid][TempNetcheck] = true;
			SendClientMessageToAll(-1, sprintf("{FFFFFF}%s (%d) "COL_PRIM"temporarily disabled netcheck on him for 15 seconds. You may want to permanently disable it!", Player[playerid][Name], playerid));
			SetTimerEx("RemoveTempNetcheck", 15000, false, "i", playerid);
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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

	format(iString, sizeof(iString), "UPDATE Players SET NetCheck = %d WHERE Name = '%s'", Player[pID][NetCheck], DB_Escape(Player[pID][Name]));
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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

YCMD:leaguestats(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display league mini scoreboard.");
	    return 1;
	}
	#if defined _league_included
	ShowPlayerDialog(playerid, DIALOG_LEAGUE_STATS, DIALOG_STYLE_LIST, "League mini scoreboard",
		"Most Active Admins/Mods\nTop Clans\nTop Players (Points)\nTop Killers\nMost Active\nTop Punchers\nTop Damage (Overall damage)\nTop Sniper\nTop Deagler\nTop M4\nTop Rifler\nTop AK\nTop Spasser\nTop Shotgun",
		"View", "Close");
	#else
	SendErrorMessage(playerid, "This version is not supported and cannot run league features.");
	#endif
	return 1;
}

YCMD:leaguehelp(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display help about league mode.");
	    return 1;
	}
	new str[550];
	strcat(str, ""COL_PRIM"How to start a league match: clan vs clan\n\n{FFFFFF}Before starting a league match between 2 clans, you have to make sure that ");
	strcat(str, "both clans are registered in the\nleague ("GM_WEBSITE") and players are registered in those clans.");
 	strcat(str, "Once done of\nclan/player registration, you can easily enable league mode by using /league clan\n\n\n");
	strcat(str, ""COL_PRIM"How to start a league match: funteams (ft)\n\n{FFFFFF}Make sure players are logged into their league accounts, enable match mode, balance teams and then /league ft");
	ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, "League mode help", str, "That's cool!", "");
	return 1;
}

YCMD:league(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "enable league mode.");
	    return 1;
	}
	#if defined _league_included
	if(Current != -1) return SendErrorMessage(playerid,"Can't use this command while round is on.");
	if(LeagueMode == true) return SendErrorMessage(playerid,"League-mode is already on.");
    if(WarMode == false) return SendErrorMessage(playerid,"War/match mode has to be enabled first.");
    if(isequal(TeamName[ATTACKER], TeamName[DEFENDER], true)) return SendErrorMessage(playerid, "Team names cannot be equal. Use /teamname to solve this issue!");

	new leagueTypeStr[5], playersCount;
	if(sscanf(params, "si", leagueTypeStr, playersCount))
	    return SendUsageMessage(playerid,"/league [ft / clan] [match mode (players): 3, 4, 5...]");

	if(strcmp(leagueTypeStr, "ft", true) == 0)
		LeagueMatchType = LEAGUE_MATCH_TYPE_FT;
	else if(strcmp(leagueTypeStr, "clan", true) == 0)
		LeagueMatchType = LEAGUE_MATCH_TYPE_CLAN;
	else
		return SendUsageMessage(playerid,"/league [ft / clan] [players: 3, 4, 5...]");
		
	if(playersCount < 3)
		return SendErrorMessage(playerid, "League matches cannot be less than 3v3");

	LEAGUE_MATCH_MODE = playersCount;
    CheckLeagueClans(playerid, TeamName[ATTACKER], TeamName[DEFENDER]);
    #else
    SendErrorMessage(playerid, sprintf("This version is not permitted to run league matches (developer version or an ugly edit). Visit %s to have the right version for this!", GM_WEBSITE));
    #endif
	return 1;
}


YCMD:setleagueplayers(playerid, params[], help)
{
	//if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
    if(help)
	{
	    SendCommandHelpMessage(playerid, "set league players mode (e.g 3v3, 4v4 ...)");
	    return 1;
	}
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	if(!LeagueMode)
	    return SendErrorMessage(playerid, "League mode is not enabled!");
	if(isnull(params))
	    return SendUsageMessage(playerid, "/setleagueplayers [number]");
	new value = strval(params);
	if(value < 3)
	    return SendErrorMessage(playerid, "League matches cannot be less than 3v3");
	if(value == LEAGUE_MATCH_MODE)
	    return SendErrorMessage(playerid, sprintf("League mode is already set to %dv%d", value, value));

	LEAGUE_MATCH_MODE = value;
	SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has set league mode to: {FFFFFF} %d Vs. %d", Player[playerid][Name], value, value));
	if(Current == -1)
	{
		if(IsEnoughPlayersForLeague(TeamName[ATTACKER], TeamName[DEFENDER]))
		{
			SendClientMessageToAll(-1, " ");
			SendClientMessageToAll(-1, " ");
			SendClientMessageToAll(-1, ""COL_PRIM"There are enough players in each team now to start...");
			SendClientMessageToAll(-1, ""COL_PRIM"A new round is automatically starting in {FFFFFF}7 seconds");
			if(CurrentRound == (TotalRounds - 1))
			{
				KillTimer(LeagueRoundStarterTimer);
				LeagueRoundStarterTimer = SetTimerEx("StartAnotherLeagueRound", 7000, false, "db", ARENA, true);
			}
			else if(CurrentRound < (TotalRounds - 1))
			{
				KillTimer(LeagueRoundStarterTimer);
				LeagueRoundStarterTimer = SetTimerEx("StartAnotherLeagueRound", 7000, false, "db", BASE, true);
			}
		}
	}
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

	new iString[160], TeamAName[7], TeamBName[7];
	if(sscanf(params, "zz", TeamAName, TeamBName)) return SendUsageMessage(playerid,"/war ([Team A] [Team B]) (end)");
	if(strcmp(TeamAName, "end", true) == 0 && isnull(TeamBName) && WarMode == true)
	{
		#if defined _league_included
	    if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
	        return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
		#endif
		SetTimer("WarEnded", 5000, 0);
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has set the match to end!", Player[playerid][Name]));
		SendClientMessageToAll(-1, ""COL_PRIM"Preparing End Match Results..");
		SendClientMessageToAll(-1, ""COL_PRIM"If you missed the results screen by hiding the current textdraws, type {FFFFFF}/showagain");
		SendClientMessageToAll(-1, ""COL_PRIM"Type {FFFFFF}/weaponstats "COL_PRIM"to see a list of players weapon statistics.");

		return 1;
	} else if(isnull(TeamBName)) return SendUsageMessage(playerid,"/war ([Team A] [Team B]) (end)");

    if(WarMode == true) return SendErrorMessage(playerid,"War-mode is already on.");
	if(strlen(TeamAName) > 6 || strlen(TeamBName) > 6) return SendErrorMessage(playerid,"Team name is too long.");
	if(strfind(TeamAName, "~") != -1 || strfind(TeamBName, "~") != -1) return SendErrorMessage(playerid,"~ not allowed.");
 	#if defined _league_included
    if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
        return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif

	format(TeamName[ATTACKER], 7, TeamAName);
	format(TeamName[ATTACKER_SUB], 11, "%s Sub", TeamName[ATTACKER]);
	format(TeamName[DEFENDER], 7, TeamBName);
	format(TeamName[DEFENDER_SUB], 11, "%s Sub", TeamName[DEFENDER]);
	UpdateTeamScoreTextDraw();
	UpdateRoundsPlayedTextDraw();
	UpdateTeamNameTextDraw();
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
	RoundPaused = false;
    format(iString, sizeof iString, "%sWar Mode: ~r~ON", MAIN_TEXT_COLOUR);
	TextDrawSetString(WarModeText, iString);

    new toTeam = ATTACKER, oppositeTeam = DEFENDER;
	new
    	MyVehicle = -1,
		Seat;
		
	foreach(new i : Player)
	{
	    for(new j = 0; j < 55; j ++)
			Player[i][WeaponStat][j] = 0;
		Player[i][TotalKills] = 0;
		Player[i][TotalDeaths] = 0;
		Player[i][TotalDamage] = 0;
		Player[i][RoundPlayed] = 0;
	    Player[i][TotalBulletsFired] = 0;
	    Player[i][TotalshotsHit] = 0;
	    
		if(Player[i][InDuel] == true || Player[i][IsAFK])
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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif
	new iString[160], TeamID, TeamNamee[24];
	if(sscanf(params, "ds", TeamID, TeamNamee)) return SendUsageMessage(playerid,"/teamname [Team ID] [Name] (0 = Attacker | 1 = Defender)");

	if(TeamID < 0 || TeamID > 1) return SendErrorMessage(playerid,"Invalid Team ID.");
	if(strlen(TeamNamee) > 6) return SendErrorMessage(playerid,"Team name is too long.");
	if(strfind(TeamNamee, "~") != -1) return SendErrorMessage(playerid,"~ not allowed.");

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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/freeze [Player ID]");

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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif
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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif

	new cpTime = strval(params);
	if(cpTime < 1 || cpTime > 60) return SendErrorMessage(playerid,"CP time can't be lower than 1 or higher than 60 seconds.");

	ConfigCPTime = cpTime;
 	CurrentCPTime = ConfigCPTime + 1;

	new iString[160];
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
	new iString[128];
	format(iString, sizeof(iString), ""COL_PRIM"Last Played: {FFFFFF}%d "COL_PRIM"| Requested by {FFFFFF}%s", ServerLastPlayed, Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif

	new str[2048];
	foreach(new i : Player)
	{
	    if(Player[i][InDuel] == true || Player[i][Playing] == true)
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

YCMD:pchannel(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display players in a channel.");
	    return 1;
	}
	if(Player[playerid][ChatChannel] != -1) {
		new iString[356];
		iString = "{FF3333}Players in channel:\n\n";

		foreach(new i : Player) {
		    if(Player[i][ChatChannel] == Player[playerid][ChatChannel]) {
		        format(iString, sizeof(iString), "%s{FF3333} - {FFFFFF}%s (%d)\n", iString, Player[i][Name], i);
			}
		}

		ShowPlayerDialog(playerid,DIALOG_NO_RESPONSE,DIALOG_STYLE_MSGBOX,"{FFFFFF}Players In Channel", iString, "Close","");
	} else {
    	SendErrorMessage(playerid,"You are not in any channel.");
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
	new iString[128];
	if(isnull(params)) {
		if(Player[playerid][ChatChannel] != -1) {
		    format(iString, sizeof(iString), "{FFFFFF}>> "COL_PRIM"Current chat channel ID: {FFFFFF}%d", Player[playerid][ChatChannel]);
		    SendClientMessage(playerid, -1, iString);
		} else {
			SendUsageMessage(playerid,"/chatchannel [Channel ID]");
		}
		return 1;
	}

	new Channel = strval(params);
	if(Channel <= -1 || Channel > 1000) return SendErrorMessage(playerid,"Invalid channel ID.");

	Player[playerid][ChatChannel] = Channel;

	format(iString, sizeof(iString), "UPDATE Players SET ChatChannel = %d WHERE Name = '%s'", Channel, DB_Escape(Player[playerid][Name]));
    db_free_result(db_query(sqliteconnection, iString));

	foreach(new i : Player) {
	    if(Player[i][ChatChannel] == Player[playerid][ChatChannel] && i != playerid) {
	        format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has joined this chat channel.", Player[playerid][Name]);
	        SendClientMessage(i, -1, iString);
		} else {
	        format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has joined a chat channel.", Player[playerid][Name]);
	        SendClientMessage(i, -1, iString);
		}
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
	GivePlayerWeapon(playerid, PARACHUTE, 1);
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

	new recieverid, text[180];

	if(sscanf(params,"is",recieverid, text)) return SendUsageMessage(playerid,"/pm [Player ID] [Text]");
	if(!IsPlayerConnected(recieverid)) return SendErrorMessage(playerid,"Player not connected.");

	if(Player[recieverid][blockedid] == playerid) return SendErrorMessage(playerid,"That player has blocked PMs from you.");
	if(Player[recieverid][blockedall] == true) return SendErrorMessage(playerid,"That player has blocked PMs from everyone.");

	new String[180];
	format(String,sizeof(String),"{FFCC00}*** PM from %s (%d): %s",Player[playerid][Name], playerid, text);
	SendClientMessage(recieverid,-1,String);
	SendClientMessage(recieverid,-1,""COL_PRIM"Use {FFFFFF}/r [Message]"COL_PRIM" to reply");

	Player[recieverid][LastMsgr] = playerid;

	format(String,sizeof(String),"{FF9900}*** PM to %s (%d): %s",Player[recieverid][Name], recieverid, text);
	SendClientMessage(playerid,-1,String);

	PlayerPlaySound(recieverid,1054,0,0,0);

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

	new replytoid, text[180];
    replytoid = Player[playerid][LastMsgr];

   	if(!IsPlayerConnected(replytoid)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[playerid][LastMsgr] == -1) return SendErrorMessage(playerid,"That player is not connected.");

	if(Player[replytoid][blockedid] == playerid) return SendErrorMessage(playerid,"That player has blocked PMs from you.");
	if(Player[replytoid][blockedall] == true) return SendErrorMessage(playerid,"That player has blocked PMs from everyone.");


	sscanf(params, "s", text);

	if(isnull(text)) return SendUsageMessage(playerid,"/r [Message]");
	if(strlen(text) > 100) return SendErrorMessage(playerid,"Message length should be less than 100 characters.");

	new String[180];
	format(String,sizeof(String),"{FFCC00}*** PM from %s (%d): %s",Player[playerid][Name], playerid, text);
	SendClientMessage(replytoid,-1,String);
	format(String,sizeof(String),"{FF9900}*** PM to %s (%d): %s",Player[replytoid][Name], replytoid, text);
	SendClientMessage(playerid,-1,String);

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
  	Player[playerid][blockedall] = true;
  	SendClientMessage(playerid,-1,""COL_PRIM"You have blocked PMs from everyone.");
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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif
	if(isnull(params)) return SendUsageMessage(playerid,"/maxpacket [Maximum Packetloss]");

	new Float:iPacket = floatstr(params);
	if(iPacket <= 0 || iPacket > 4) return SendErrorMessage(playerid,"Packetloss value can be between 0 and 4 maximum.");

	Max_Packetloss = iPacket;

	new iString[160];
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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/maxping [Maximum Ping]");

	new iPacket = strval(params);
	if(iPacket <= 0 || iPacket > 400) return SendErrorMessage(playerid,"Ping limit can be between 0 and 400 maximum.");

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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif
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
    #if defined _league_included
    if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
    #endif

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
		if(Player[i][InDuel] == true)
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
    new iString[160], pID[2];
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

    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has moved {FFFFFF}%s "COL_PRIM"to {FFFFFF}%s", Player[playerid][Name], Player[pID[0]][Name], Player[pID[1]][Name]);
    SendClientMessageToAll( -1, iString);
    LogAdminCommand("move", playerid, pID[0]);
    return 1;
}

YCMD:shortcuts(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "edit your shortcut messages.");
	    return 1;
	}
	ShowPlayerDialog(playerid, EDITSHORTCUTS_DIALOG, DIALOG_STYLE_LIST, "Editing shortcuts", sprintf("Num2: %s\nNum4: %s\nNum6: %s\nNum8: %s", PlayerShortcut[playerid][Shortcut1], PlayerShortcut[playerid][Shortcut2], PlayerShortcut[playerid][Shortcut3], PlayerShortcut[playerid][Shortcut4]), "Edit", "Cancel");
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
		        SendClientMessageToAll(-1, sprintf("{FFFFF}%s "COL_PRIM"has spawned a jetpack from league shop (/shop)", Player[playerid][Name]));
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
	    SendCommandHelpMessage(playerid, "set a message to be shown for players whom you kill.");
	    return 1;
	}
    if(isnull(params)) return SendUsageMessage(playerid,"/deathdiss [Message]");
	if(strlen(params) <= 3) return SendErrorMessage(playerid,"Too short!");
	if(strlen(params) >= 64) return SendErrorMessage(playerid,"Too long!");

	new iString[128];
	format(DeathMessageStr[playerid], 64, "%s", params);
	format(iString, sizeof(iString), "UPDATE `Players` SET `DeathMessage` = '%s' WHERE `Name` = '%s'", DB_Escape(params), DB_Escape(Player[playerid][Name]) );
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
	format(iString, sizeof(iString), "UPDATE `Players` SET `FightStyle` = '%d' WHERE `Name` = '%s'", Player[playerid][FightStyle], DB_Escape(Player[playerid][Name]) );
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
    	SendClientMessageToAll(-1, sprintf(""COL_PRIM"Fake PL renovation on {FFFFFF}%s "COL_PRIM"has ended - Old: {FFFFFF}%.1f "COL_PRIM" | Current: {FFFFFF}%.1f", Player[playerid][Name], fakepacket, GetPlayerPacketLoss(playerid)));
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
	new pID, interv;
	if(sscanf(params, "id", pID, interv)) return SendUsageMessage(playerid,"/fakepacket [Player ID] [Time in minutes]");
	if(interv <= 0 || interv > 5)  return SendErrorMessage(playerid,"Invalid (Min: 1 | Max: 5).");
	if(Player[pID][FakePacketRenovation])  return SendErrorMessage(playerid,"Player is already on fake packetloss renovation.");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(NetStats_PacketLossPercent(pID) == 0.0) return SendErrorMessage(playerid, "That player has 0.0% packet-loss");

	SetTimerEx("FakePacketRenovationEnd", interv * 60 * 1000, false, "ifb", pID, GetPlayerPacketLoss(pID), true);
	Player[pID][FakePacketRenovation] = true;

	new str[150];
	format(str, sizeof str, "{FFFFFF}%s "COL_PRIM"has started fake packetloss renovation on {FFFFFF}%s "COL_PRIM" - Interval: {FFFFFF}%d min(s).",Player[playerid][Name], Player[pID][Name], interv);
	SendClientMessageToAll(-1, str);

    LogAdminCommand("fakepacket", playerid, pID);
	return 1;
}

SetWeaponStatsString()
{
	format(WeaponStatsStr, sizeof WeaponStatsStr, "");
	foreach(new i : Player)
	{
	    if((Player[i][WeaponStat][WEAPON_DEAGLE] + Player[i][WeaponStat][WEAPON_SHOTGUN] + Player[i][WeaponStat][WEAPON_M4] + Player[i][WeaponStat][WEAPON_SHOTGSPA] + Player[i][WeaponStat][WEAPON_RIFLE] + Player[i][WeaponStat][WEAPON_SNIPER] + Player[i][WeaponStat][WEAPON_AK47] + Player[i][WeaponStat][WEAPON_MP5] + Player[i][WeaponStat][0]) <= 0)
			continue;

		format(WeaponStatsStr, sizeof WeaponStatsStr, "%s{0066FF}%s {D6D6D6}[Deagle: %d] [Shotgun: %d] [M4: %d] [Spas: %d] [Rifle: %d] [Sniper: %d] [AK: %d] [MP5: %d] [Punch: %d] [Rounds: %d]\n",
			WeaponStatsStr, Player[i][Name], Player[i][WeaponStat][WEAPON_DEAGLE], Player[i][WeaponStat][WEAPON_SHOTGUN], Player[i][WeaponStat][WEAPON_M4], Player[i][WeaponStat][WEAPON_SHOTGSPA], Player[i][WeaponStat][WEAPON_RIFLE], Player[i][WeaponStat][WEAPON_SNIPER], Player[i][WeaponStat][WEAPON_AK47], Player[i][WeaponStat][WEAPON_MP5], Player[i][WeaponStat][0], Player[i][RoundPlayed]);
	}

	for(new i = 0; i < SAVE_SLOTS; i ++)
	{
		if(strlen(SaveVariables[i][pName]) > 2)
		{
		    if((SaveVariables[i][WeaponStat][WEAPON_DEAGLE] + SaveVariables[i][WeaponStat][WEAPON_SHOTGUN] + SaveVariables[i][WeaponStat][WEAPON_M4] + SaveVariables[i][WeaponStat][WEAPON_SHOTGSPA] + SaveVariables[i][WeaponStat][WEAPON_RIFLE] + SaveVariables[i][WeaponStat][WEAPON_SNIPER] + SaveVariables[i][WeaponStat][WEAPON_AK47] + SaveVariables[i][WeaponStat][WEAPON_MP5] + SaveVariables[i][WeaponStat][0]) <= 0)
				continue;

			format(WeaponStatsStr, sizeof WeaponStatsStr, "%s{0066FF}%s {D6D6D6}[Deagle: %d] [Shotgun: %d] [M4: %d] [Spas: %d] [Rifle: %d] [Sniper: %d] [AK: %d] [MP5: %d] [Punch: %d] [Rounds: %d]\n",
				WeaponStatsStr, SaveVariables[i][pName], SaveVariables[i][WeaponStat][WEAPON_DEAGLE], SaveVariables[i][WeaponStat][WEAPON_SHOTGUN], SaveVariables[i][WeaponStat][WEAPON_M4], SaveVariables[i][WeaponStat][WEAPON_SHOTGSPA], SaveVariables[i][WeaponStat][WEAPON_RIFLE], SaveVariables[i][WeaponStat][WEAPON_SNIPER], SaveVariables[i][WeaponStat][WEAPON_AK47], SaveVariables[i][WeaponStat][WEAPON_MP5], SaveVariables[i][WeaponStat][0], SaveVariables[i][TPlayed]);
		}
	}
	return 1;
}

YCMD:weaponstats(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "display everyone's weapon statistics.");
	    return 1;
	}
	ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, "Players Weapon Statistics", WeaponStatsStr, "Close", "");
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

	Skin[ATTACKER] = 53;
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Attacker Skin'", 53);
    db_free_result(db_query(sqliteconnection, iString));

	Skin[DEFENDER] = 230;
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Defender Skin'", 230);
    db_free_result(db_query(sqliteconnection, iString));

	Skin[REFEREE] = 51;
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Referee Skin'", 51);
    db_free_result(db_query(sqliteconnection, iString));


	foreach(new i : Player) {
	    if(Player[i][Team] == ATTACKER) {
	        SetPlayerSkin(i, Skin[ATTACKER]);
			ClearAnimations(i);
		}
		if(Player[i][Team] == DEFENDER) {
	        SetPlayerSkin(i, Skin[DEFENDER]);
			ClearAnimations(i);
		}
		if(Player[i][Team] == REFEREE) {
	        SetPlayerSkin(i, Skin[REFEREE]);
			ClearAnimations(i);
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
	ClearAnimations(Params[0]);

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
	#if defined _league_included
	if(Current == -1 && LeagueMode)
	{
		if(IsEnoughPlayersForLeague(TeamName[ATTACKER], TeamName[DEFENDER]))
		{
			SendClientMessageToAll(-1, " ");
			SendClientMessageToAll(-1, " ");
			SendClientMessageToAll(-1, ""COL_PRIM"There are enough players in each team now to start...");
			SendClientMessageToAll(-1, ""COL_PRIM"A new round is automatically starting in {FFFFFF}7 seconds");
			if(CurrentRound == (TotalRounds - 1))
			{
				KillTimer(LeagueRoundStarterTimer);
				LeagueRoundStarterTimer = SetTimerEx("StartAnotherLeagueRound", 7000, false, "db", ARENA, true);
			}
			else if(CurrentRound < (TotalRounds - 1))
			{
				KillTimer(LeagueRoundStarterTimer);
				LeagueRoundStarterTimer = SetTimerEx("StartAnotherLeagueRound", 7000, false, "db", BASE, true);
			}
		}
	}
	#endif
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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif
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
	format(iString, sizeof(iString), "UPDATE Players SET Password = '%s' WHERE Name = '%s'", HashPass, DB_Escape(Player[playerid][Name]));
    db_free_result(db_query(sqliteconnection, iString));

	format(HashPass, sizeof(HashPass), "Your password is changed to: %s", params);
	SendClientMessage(playerid, -1, HashPass);
	return 1;
}

YCMD:changename(playerid,params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "change your user account name.");
	    return 1;
	}
    if(!ChangeName)
		return SendErrorMessage(playerid, "/changename command is disabled in this server.");
	if(Player[playerid][Logged] == false)
		return SendErrorMessage(playerid,"You must be logged in.");
	if(Player[playerid][Mute])
		return SendErrorMessage(playerid, "Cannot use this command when you're muted.");
	if(isnull(params))
		return SendUsageMessage(playerid,"/changename [New Name]");
	if(strlen(params) <= 1)
		return SendErrorMessage(playerid,"Name cannot be that short idiot!!");

	switch(SetPlayerName(playerid,params))
	{
	    case 1:
	    {
	        //success
	        new iString[128],
				DBResult: result
			;

			format( iString, sizeof(iString), "SELECT * FROM `Players` WHERE `Name` = '%s'", DB_Escape(params) );
			result = db_query(sqliteconnection, iString);

			if(db_num_rows(result) > 0)
			{
			    db_free_result(result);
			    //name in Use in DB.
			    SetPlayerName( playerid, Player[playerid][Name] );
			    return SendErrorMessage(playerid,"Name already registered!");
			}
			else
			{
			    db_free_result(result);
			    //name changed successfully!!

				format(iString, sizeof(iString),">> {FFFFFF}%s "COL_PRIM"has changed name to {FFFFFF}%s",Player[playerid][Name],params);
				SendClientMessageToAll(-1,iString);

				format(iString, sizeof(iString), "UPDATE `Players` SET `Name` = '%s' WHERE `Name` = '%s'", DB_Escape(params), DB_Escape(Player[playerid][Name]) );
				db_free_result(db_query(sqliteconnection, iString));

				format( Player[playerid][Name], MAX_PLAYER_NAME, "%s", params );

			    new NewName[MAX_PLAYER_NAME];
				NewName = RemoveClanTagFromName(playerid);

				if(strlen(NewName) != 0)
					Player[playerid][NameWithoutTag] = NewName;
				else
					Player[playerid][NameWithoutTag] = Player[playerid][Name];

				#if defined _league_included
                CheckPlayerLeagueRegister(playerid);
                #endif
			    return 1;
			}
	    }
		case 0: return SendErrorMessage(playerid,"You're already using that name.");
		case -1: return SendErrorMessage(playerid,"Either Name is too long, already in use or has invalid characters.");
	}
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
	if(Player[playerid][AntiLag] == true) return SendErrorMessage(playerid,"Can't heal in anti-lag zone.");
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif

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

    //if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a level 3 admin to do that.");
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

    AKAString = "";
	AKAString = GetPlayerAKA(pID);
	format(AKAString, sizeof(AKAString), "{FFFFFF}%s", AKAString);

	new title[50];
	format(title, sizeof(title), ""COL_PRIM"%s's AKA", Player[pID][Name]);
    ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX,title,AKAString,"Close","");

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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
    #if defined _league_included
    if(LeagueMode)
    {
        FixPlayerLeagueTeam(playerid);
        if(Current == -1)
        {
			if(IsEnoughPlayersForLeague(TeamName[ATTACKER], TeamName[DEFENDER]))
			{
				SendClientMessageToAll(-1, " ");
				SendClientMessageToAll(-1, " ");
				SendClientMessageToAll(-1, ""COL_PRIM"Teams are ready now...");
				SendClientMessageToAll(-1, ""COL_PRIM"A new round is automatically starting in {FFFFFF}7 seconds");
				if(CurrentRound == (TotalRounds - 1))
				{
				    KillTimer(LeagueRoundStarterTimer);
					LeagueRoundStarterTimer = SetTimerEx("StartAnotherLeagueRound", 7000, false, "db", ARENA, true);
				}
				else if(CurrentRound < (TotalRounds - 1))
				{
				    KillTimer(LeagueRoundStarterTimer);
					LeagueRoundStarterTimer = SetTimerEx("StartAnotherLeagueRound", 7000, false, "db", BASE, true);
				}
			}
	        FixVsTextDraw();
   		}
    }
    else
    {
    #endif
		format(iString, sizeof(iString), "%s%s\n%s%s Sub\n%s%s\n%s%s Sub\n%sReferee", TextColor[ATTACKER], TeamName[ATTACKER], TextColor[ATTACKER_SUB], TeamName[ATTACKER], TextColor[DEFENDER], TeamName[DEFENDER], TextColor[DEFENDER_SUB], TeamName[DEFENDER], TextColor[REFEREE]);
		ShowPlayerDialog(playerid, DIALOG_SWITCH_TEAM, DIALOG_STYLE_LIST, "{FFFFFF}Team Selection",iString, "Select", "");
    #if defined _league_included
	}
	#endif
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif

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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif

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
    #if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled. Use /afk if you're going away!");
	#endif
	if(Player[playerid][Spectating] == true) StopSpectate(playerid);

	new iString[128];
	format(iString, sizeof(iString), "%s%s\n%s%s Sub\n%s%s\n%s%s Sub\n%sReferee", TextColor[ATTACKER], TeamName[ATTACKER], TextColor[ATTACKER_SUB], TeamName[ATTACKER], TextColor[DEFENDER], TeamName[DEFENDER], TextColor[DEFENDER_SUB], TeamName[DEFENDER], TextColor[REFEREE]);
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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

YCMD:done(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "finish selecting of gunmenu.");
	    return 1;
	}
	if(Player[playerid][OnGunmenu])
	{
	    if(Player[playerid][GunmenuStyle] == GUNMENU_STYLE_OBJECT)
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
	#if defined _league_included
    if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
        return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
    #endif
    ShowPlayerGunmenuModification(playerid);
	return 1;
}

YCMD:spas(playerid, params[], help)
{
	if(help)
	{
	    SendCommandHelpMessage(playerid, "toggle spas selection in gunmenu.");
	}
	#if defined _league_included
    if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
        return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
    #endif
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
		            SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"was automatically shown the gunmenu because they had Spas."));
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
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has showed weapon menu for himself.", Player[playerid][Name]);
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
	    return SendUsageMessage(playerid,"/gunmenustyle [dialog / object]");
	    
    new style;
	if(strcmp(styleStr, "dialog", true) == 0)
		style = GUNMENU_STYLE_DIALOG;
	else if(strcmp(styleStr, "object", true) == 0)
		style = GUNMENU_STYLE_OBJECT;
	else
		return SendUsageMessage(playerid,"/gunmenustyle [dialog / object]");
		
	Player[playerid][GunmenuStyle] = style;
   	db_free_result(db_query(sqliteconnection, sprintf("UPDATE Players SET GunmenuStyle = %d WHERE Name = '%s'", style, DB_Escape(Player[playerid][Name]))));
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
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif

	foreach(new i : Player) {
		if(Player[i][Playing] == false && Player[i][InDuel] == false && (Player[i][Team] == ATTACKER || Player[i][Team] == DEFENDER)) {
			if(GameType == BASE) AddPlayerToBase(i);
		    else if(GameType == ARENA) AddPlayerToArena(i);
		}
	}

    new iString[64];
    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has added everyone to the round.", Player[playerid][Name]);
    SendClientMessageToAll(-1, iString);

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
	#if defined _league_included
    if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
    #endif
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

YCMD:readd(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "re-add a player to the round.");
	    return 1;
	}
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");
	#if defined _league_included
    if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
    #endif

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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif

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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif

	Current = -1;
	if(RoundPaused == true)
		TextDrawHideForAll(PauseTD);

	RoundPaused = false;
	FallProtection = false;
	TeamCapturingCP = NON;
    PlayersInCP = 0;

	PlayersAlive[ATTACKER] = 0;
	PlayersAlive[DEFENDER] = 0;

    RoundUnpausing = false;

	foreach(new i : Player) {

		Player[i][Playing] = false;
		Player[i][WasInCP] = false;
		if(Player[i][Spectating] == true)
			StopSpectate(i);
		Player[i][WasInBase] = false;
		Player[i][WeaponPicked] = 0;
		Player[i][TimesSpawned] = 0;

		TogglePlayerControllable(i, 0);
		RemovePlayerMapIcon(i, 59);

		SpawnPlayerEx(i);

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
	SetGameModeText(GM_NAME);

	new iString[64];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has ended the round.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

	DeleteAllTeamBars();
	DeleteAllDeadBodies();
    GangZoneDestroy(CPZone);
	GangZoneDestroy(ArenaZone);
	ResetTeamLeaders();
    Iter_Clear(PlayersInRound);
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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif

    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has banned {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name], /*IP,*/ Reason);
	SendClientMessageToAll(-1, iString);

	Player[pID][DontPause] = true;

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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif

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

    Player[pID][DontPause] = true;
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
	
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
	
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif

	new iString[64];
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif

	PauseCountdown = 4;
	UnpauseRound();

	new iString[64];
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
	EnableInterface(playerid);
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
	#if defined _league_included
	if(LeagueMode && !(IsLeagueMod(playerid) || IsLeagueAdmin(playerid)))
 		return SendErrorMessage(playerid, "You do not have league admin/mod power to do this.");
	#endif
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
	Player[playerid][AntiLag] = false;

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
    if(!IsPlayerInAnyVehicle(playerid)) return 1;

	new Float:Pos[4];
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	GetPlayerFacingAngle(playerid, Pos[3]);

	if(Player[playerid][Playing] == true)
	{
		if(Pos[0] > BAttackerSpawn[Current][0] + 100 || Pos[0] < BAttackerSpawn[Current][0] - 100 || Pos[1] > BAttackerSpawn[Current][1] + 100 || Pos[1] < BAttackerSpawn[Current][1] - 100)
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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif

	new Params[64], iString[128], CommandID;
	sscanf(params, "s", Params);


	if(isnull(Params) || IsNumeric(Params)) return

	SendUsageMessage(playerid,"/random [base | arena]");

	if(strcmp(Params, "base", true) == 0) CommandID = 1;
	else if(strcmp(Params, "arena", true) == 0) CommandID = 2;
	else return
	SendUsageMessage(playerid,"/random [base | arena]");

	switch(CommandID) {
		case 1: {
		    new BaseID = DetermineRandomRound(2, false, BASE);

			AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
			SetTimerEx("OnBaseStart", 4000, false, "i", BaseID);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[BaseID], BaseID);
			SendClientMessageToAll(-1, iString);
		} case 2: {
		    new ArenaID = DetermineRandomRound(2, false, ARENA);

			AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
			SetTimerEx("OnArenaStart", 4000, false, "i", ArenaID);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
			SendClientMessageToAll(-1, iString);
		}
	}

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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif

	new Params[64], iString[160], CommandID;
	sscanf(params, "s", Params);
	if(isnull(Params) || IsNumeric(Params)) return
	
	SendUsageMessage(playerid,"/randomint [base | arena]");

	if(strcmp(Params, "base", true) == 0) CommandID = 1;
	else if(strcmp(Params, "arena", true) == 0) CommandID = 2;
	else return
	SendUsageMessage(playerid,"/randomint [base | arena]");

	switch(CommandID) {
		case 1: {
		    new BaseID = DetermineRandomRound(1, false, BASE);

			AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
			SetTimerEx("OnBaseStart", 4000, false, "i", BaseID);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started interior Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[BaseID], BaseID);
			SendClientMessageToAll(-1, iString);

			GameType = BASE;
		} case 2: {
		    new ArenaID = DetermineRandomRound(1, false, ARENA);

			AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
			SetTimerEx("OnArenaStart", 4000, false, "i", ArenaID);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started interior Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
			SendClientMessageToAll(-1, iString);
		}
	}

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
	#if defined _league_included
	if(LeagueMode) return SendErrorMessage(playerid, "Can't use this when league mode is enabled.");
	#endif

	new Params[2][64], iString[160], CommandID;
	sscanf(params, "ss", Params[0], Params[1]);

	if(isnull(Params[0]) || IsNumeric(Params[0])) return
	SendUsageMessage(playerid,"/start [base | arena | rc | last] [ID]");

	if(!strcmp(Params[0], "rc", true))
	{
	    AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		SetTimer("OnRCStart", 2000, false);

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

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[BaseID], BaseID);
		SendClientMessageToAll(-1, iString);

	} else if(CommandID == 2) {

		new ArenaID = strval(Params[1]);

		if(ArenaID > MAX_ARENAS) return SendErrorMessage(playerid,"That arena does not exist.");
		if(!AExist[ArenaID]) return SendErrorMessage(playerid,"That arena does not exist.");

		AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		SetTimerEx("OnArenaStart", 2000, false, "i", ArenaID);

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

	new iString[128];

	format(iString, sizeof(iString), "UPDATE Players SET Level = %d WHERE Name = '%s' AND Level != %d", LEVEL, DB_Escape(Player[GiveID][Name]), LEVEL);
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


	format(iString, sizeof(iString), "UPDATE Players SET Weather = %d WHERE Name = '%s'", myweather, DB_Escape(Player[playerid][Name]));
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
	if(!IsValidSound(Val)) return SendErrorMessage(playerid,"This sound ID is not valid.");

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
	if(sscanf(params, "sz",Option, Value)) return SendUsageMessage(playerid,"/sound [hit | gethit] [Sound ID | default]");

	if(strcmp(Option, "hit", true) == 0) CommandID = 1;
	else if(strcmp(Option, "gethit", true) == 0) CommandID = 2;
	else return SendUsageMessage(playerid,"/sound [hit | gethit] [Sound ID | default]");

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
				else return SendUsageMessage(playerid,"/sound [hit] [Sound ID | default]");
			}
		 	else
			{
			    new Val = strval(Value);
			    if(!IsValidSound(Val)) return SendErrorMessage(playerid,"This sound ID is not valid.");

			    Player[playerid][HitSound] = Val;
			}
			format(iString, sizeof(iString), "UPDATE Players SET HitSound = %d WHERE Name = '%s'", Player[playerid][HitSound], DB_Escape(Player[playerid][Name]));
		    db_free_result(db_query(sqliteconnection, iString));

			PlayerPlaySound(playerid, Player[playerid][HitSound], 0, 0, 0);
	    }
		case 2:
		{
	        if(isnull(Value)) return SendUsageMessage(playerid,"/sound [gethit] [Sound ID | default]");
	        if(!IsNumeric(Value))
			{
	            if(strcmp(Value, "default", true) == 0)
				{
	                Player[playerid][GetHitSound] = 1131;
				}
				else return SendUsageMessage(playerid,"/sound [gethit] [Sound ID | default]");
			}
			else
			{
			    new Val = strval(Value);
			    if(!IsValidSound(Val)) return SendErrorMessage(playerid,"This sound ID is not valid.");

			    Player[playerid][GetHitSound] = Val;
			}
			format(iString, sizeof(iString), "UPDATE Players SET GetHitSound = %d WHERE Name = '%s'", Player[playerid][GetHitSound], DB_Escape(Player[playerid][Name]));
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

	format(iString, sizeof(iString), "UPDATE Players SET Time = %d WHERE Name = '%s'", mytime, DB_Escape(Player[playerid][Name]));
    db_free_result(db_query(sqliteconnection, iString));

    format(iString, sizeof(iString), "{FFFFFF}Time changed to: %d", mytime);
    SendClientMessage(playerid, -1, iString);
    return 1;
}

YCMD:antilag(playerid, params[], help)
{
    if(help)
	{
	    SendCommandHelpMessage(playerid, "teleport you to the anti-lag zone.");
	    return 1;
	}
	new iString[64];
	if(Player[playerid][AntiLag] == true) {
	    Player[playerid][AntiLag] = false;
	    SpawnPlayerEx(playerid);

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has quit the Anti-Lag zone.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
	    return 1;
	}

	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't use this command while playing.");
    if(Player[playerid][Spectating] == true) StopSpectate(playerid);
	if(Player[playerid][InDM] == true) {
	    Player[playerid][InDM] = false;
    	Player[playerid][DMReadd] = 0;
	}
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel.");

	Player[playerid][AntiLag] = true;
	SpawnInAntiLag(playerid);

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has joined Anti-Lag zone.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

	if(Player[playerid][BeingSpeced] == true) {
	    foreach(new i : Player) {
	        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
	            StopSpectate(i);
			}
		}
	}
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
	if(Player[playerid][AntiLag] == true) Player[playerid][AntiLag] = false;

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
	Player[playerid][IgnoreSpawn] = true; //Make sure you ignore OnPlayerSpawn, else you will just spawn in lobby (because u are about to use SpawnPlayerEx).
	SpawnPlayerEx(playerid); //Spawns players, in this case we have SetSpawnInfo (but still you need to make sure OnPlayerSpawn is ignored);
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
	if(Player[playerid][AntiLag] == true) Player[playerid][AntiLag] = false;


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

	new iString[160];
	format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has entered Interior ID: {FFFFFF}%d "COL_PRIM"| Interior: {FFFFFF}%d",Player[playerid][Name],id,id,Interiors[id][int_interior]);
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
	if(CheckPlayerSprintMacro(playerid, newkeys, oldkeys) == true)
	    return 1;

    if(Player[playerid][TextDrawOnScreen] == true && PRESSED(4))
	{
	    HideEndRoundTextDraw(playerid);
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
	    if(PRESSED(131072) && AllowStartBase == true && Player[playerid][Playing] == true)
		{
		    if(Player[playerid][Team] == ATTACKER && TeamHelp[ATTACKER] == false)
			{
                new iString[160];
                new totHP = Player[playerid][pHealth] + Player[playerid][pArmour];
				foreach(new i : Player)
				{
				    if((Player[i][Playing] == true || GetPlayerState(i) == PLAYER_STATE_SPECTATING) && i != playerid && Player[i][Team] == ATTACKER)
					{
						format(iString, sizeof(iString), "{FF6666}[HELP] {FFFFFF}%s {FF6666}needs a backup [Distance %.0f ft / HP %d]", Player[playerid][Name], GetDistanceBetweenPlayers(i, playerid), totHP);
					    SendClientMessage(i, -1, iString);
					    PlayerPlaySound(i,1137,0.0,0.0,0.0);
					}
				}
				TeamHelp[ATTACKER] = true;
				Player[playerid][AskingForHelp] = true;
				SetPlayerColor(playerid, ATTACKER_ASKING_HELP);

				SendClientMessage(playerid, -1, "{FF6666}[HELP] {FFFFFF}You have requested for backup.");
				Player[playerid][AskingForHelpTimer] = SetTimerEx("AttackerAskingHelp", 7000, 0, "i", playerid);
				RadarFix(playerid);
				UpdatePlayerTeamBar(playerid);
				return 1;
			}
			else if(Player[playerid][Team] == DEFENDER && TeamHelp[DEFENDER] == false)
			{
                new iString[160];
                new totHP = Player[playerid][pHealth] + Player[playerid][pArmour];
				foreach(new i : Player)
				{
				    if((Player[i][Playing] == true || GetPlayerState(i) == PLAYER_STATE_SPECTATING) && i != playerid && Player[i][Team] == DEFENDER)
					{
				    	format(iString, sizeof(iString), "{9999FF}[HELP] {FFFFFF}%s {9999FF}needs a backup [Distance %.0f ft / HP %d]", Player[playerid][Name], GetDistanceBetweenPlayers(i, playerid), totHP);
					    SendClientMessage(i, -1, iString);
					    PlayerPlaySound(i,1137,0.0,0.0,0.0);
					}
				}
				TeamHelp[DEFENDER] = true;
				Player[playerid][AskingForHelp] = true;
				SetPlayerColor(playerid, DEFENDER_ASKING_HELP);

				SendClientMessage(playerid, -1, "{9999FF}[HELP] {FFFFFF}You have requested for backup.");
				Player[playerid][AskingForHelpTimer] = SetTimerEx("DefenderAskingHelp", 7000, 0, "i", playerid);
                RadarFix(playerid);
                UpdatePlayerTeamBar(playerid);
                return 1;
			}
		}
	    // Lead team
	    if(PRESSED(262144) && AllowStartBase == true && Player[playerid][Playing] == true)
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
            #if defined _league_included
			if(LeagueMode)
			{
			    if(IsLeagueMod(playerid) || IsLeagueAdmin(playerid))
			    {
                    switch(RoundPaused)
		            {
		                case true:
		                {
		                    new iString[160];
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
		                    new iString[160];
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
		                    PlayerVoteUnpause(playerid);
							return 1;
		                }
		                case false:
		                {
		                    PlayerVotePause(playerid);
							return 1;
		                }
		            }
			    }
			}
			else
			{
			    if(Player[playerid][Level] > 0)
				{
				    switch(RoundPaused)
		            {
		                case true:
		                {
		                    new iString[160];
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
		                    new iString[160];
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
			#else
			if(Player[playerid][Level] > 0)
			{
			    switch(RoundPaused)
	            {
	                case true:
	                {
	                    new iString[160];
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
	                    new iString[160];
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
			#endif
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
    CheckKnifeSync(playerid, newkeys);
	    
    if(CheckKeysForWeaponBind(playerid, newkeys, oldkeys) == 1)
	    return 1;

    #if GTAV_SWITCH_MENU != 0
	if(newkeys & 16 && !(newkeys & KEY_HANDBRAKE))
	{
        EnablePlayerGunSwitchInterface(playerid);
	    return 1;
	}
	#endif
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
		if(PRESSED(KEY_YES) && Player[playerid][Level] > 1)
		{
			EnableInterface(playerid);
			return 1;
		}
		else if(PRESSED(131072))
		{
		    if(GetPlayerVehicleID(playerid) == 0)
		    {
				ShowEndRoundTextDraw(playerid);
		    	return 1;
   			}
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
	    ShowTargetInfo(i, GetPlayerTargetPlayer(i));
		// Update net info textdraws
		GetPlayerFPS(i);
		if(PlayerInterface[i][INTERFACE_NET])
  			PlayerTextDrawSetString(i, FPSPingPacket[i], sprintf("%sFPS %s%d %sPing %s%d %sPacketLoss %s%.1f%%", MAIN_TEXT_COLOUR, TDC[Player[i][Team]], Player[i][FPS], MAIN_TEXT_COLOUR, TDC[Player[i][Team]], GetPlayerPing(i), MAIN_TEXT_COLOUR, TDC[Player[i][Team]], GetPlayerPacketLoss(i)));
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
    ShowPlayerDialog(playerid, PLAYERCLICK_DIALOG, DIALOG_STYLE_LIST, sprintf("Clicked ID: %d", clickedplayerid), "Getinfo\nSpec\nAdd\nRemove\nReadd\nGunmenu\nGo\nGet\nSlap\nMute\nUnmute\nKick\nBan", "Select", "Cancel");
	LastClickedPlayer[playerid] = clickedplayerid;
	return 1;
}
