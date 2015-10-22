/*
		Gamemode core
*/

#include "modules\header\this_core.txt"

#include "modules\header\match.txt"
#include "modules\header\colors.txt"
#include "modules\header\config.txt"
#include "modules\header\global.txt"
#include "modules\header\weaponshot.txt"

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
	AC_FixServerHostname();
}

InitScriptSecondarySettings()
{
	SetGameModeText(GM_NAME); // Text that appears on 'Mode' column when you click on a server in samp.exe
    SendRconCommand("mapname Lobby");
	CheckServerHostname();
	SendRconCommand("stream_distance 400.0");
	SendRconCommand("stream_rate 50");
	#if MATCH_SYNC == 1
    MATCHSYNC_Init();
	#endif
	SetTeamDefaultColors();
    SetTeamDefaultNames();
    SetAltCommands();
	InitVersionChecker(false, true);
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
	format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~l~");
    MAIN_BACKGROUND_COLOUR = 0xEEEEEE33;

	teamskinlist = LoadModelSelectionMenu("skins.txt");
	return 1;
}

InitScriptCoreVariables()
{
	GameType = BASE;
    ServerLastPlayed = -1;
    ServerLastPlayedType = -1;
    Current = -1;
	return 1;
}

AddToServersDatabase()
{
	if(!strcmp(hostname, "Bulletproof Home Test Server", true))
		return;
	
	new ServerIP[30];
    GetServerVarAsString("bind", ServerIP, sizeof(ServerIP));
	
    new port = GetServerVarAsInt("port");

    if(!strlen(ServerIP)) ServerIP = "noip";

    new post[256];
    format(post, sizeof(post), "IP=%s&Port=%d&HostName=%s", ServerIP, port, hostname);
    HTTP(0, HTTP_POST, HTTP_DEST_SERVERLIST, post, "");
}