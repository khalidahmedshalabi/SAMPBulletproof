/*
		Gamemode core
*/

#include "modules\header\this_core.txt"

#include "modules\header\match.txt"
#include "modules\header\colors.txt"
#include "modules\header\config.txt"
#include "modules\header\global.txt"
#include "modules\header\weaponshot.txt"
#include <YSI_inc\YSI\y_hooks>

hook OnPlayerDisconnect(playerid, reason)
{
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
		// Website check
		CheckWebsiteText();
		// Version check
		InitVersionChecker();
		// Optimize and clean database
		OptimizeDatabase();
		#if defined _league_included
		// Empty server on league live trackers as well
		InitOnlineMatchesList();
		#endif
	}
	return 1;
}
InitScriptCoreSettings()
{
	LoadDatabase();
	UsePlayerPedAnims(); // Player movement
	AllowInteriorWeapons(1); // Allow weapons in interiors
	DisableInteriorEnterExits(); // Disables entering interiors (e.g. Burger shots)
	EnableStuntBonusForAll(0); // If you stunt you won't get any points (Value = 0)
	SetNameTagDrawDistance(DRAW_DISTANCE); // Distance to see other players name and Hp
	EnableVehicleFriendlyFire(); // Enable friendly fire for team vehicles
	SetGravity(0.008); // Gravity
	SetWorldTime(MainTime); // Sets server time
	SetWeather(MainWeather); // Sets server weather
	return 1;
}

CheckServerHostname()
{
	GetServerVarAsString("hostname", hostname, sizeof(hostname));
}

InitScriptSecondarySettings()
{
	// Init some global variables
	GameType = BASE;
    ServerLastPlayed = -1;
    ServerLastPlayedType = -1;
    Current = -1;

	// Settings
	FixGamemodeText(); // Text that appears on 'Mode' column when you click on a server in samp.exe
    SendRconCommand("mapname Lobby");
	lagcompmode = GetServerVarAsInt("lagcompmode");
	CheckServerHostname();
	#if defined _league_included
	InitOnlineMatchesList();
	#endif
	SendRconCommand("stream_distance 400.0");
	SendRconCommand("stream_rate 50");
	SetTeamDefaultColors();
    SetTeamDefaultNames();
    SetAltCommands();
	InitVersionChecker();
    InitSpectate();
	InitVisualDamage();
	InitGunmenu();
	InitVoting();
	AdjustWeaponRanges();

	CreateObject(3095, 268.74, 1884.21, 16.07,   0.00, 0.00, 0.00); // block area 51

	// Match recording (rounds)
	MatchRoundsStarted = 0;
	for( new i = 0; i < 101; i++ )
	{
	    MatchRoundsRecord[ i ][ round__ID ] = -1;
	    MatchRoundsRecord[ i ][ round__type ] = -1;
	    MatchRoundsRecord[ i ][ round__completed ] = false;
	}
	format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~w~");
    MAIN_BACKGROUND_COLOUR = 0x00000044;

	teamskinlist = LoadModelSelectionMenu("skins.txt");
	playerskinlist = LoadModelSelectionMenu("skins.txt");
	return 1;
}

AddToServersDatabase()
{
	#if defined HTTP_DEST_SERVERLIST
	if(!strcmp(hostname, "BulletproofDatabase Home Test Server", true) || !strcmp(hostname, "BulletproofDatabase Home Test Server [ACv2 ENABLED]", true))
		return;

	new ServerIP[30];
    GetServerVarAsString("bind", ServerIP, sizeof(ServerIP));

    new port = GetServerVarAsInt("port");

    if(!strlen(ServerIP)) ServerIP = "noip";

    new post[256];
    format(post, sizeof(post), "IP=%s&Port=%d&HostName=%s", ServerIP, port, hostname);
    HTTP(0, HTTP_POST, HTTP_DEST_SERVERLIST, post, "");
	#endif
}

FixGamemodeText()
{
	SetGameModeText(sprintf("%s v%.2f", GM_NAME, GM_VERSION));
}
