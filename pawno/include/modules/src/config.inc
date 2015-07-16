/*
	Gamemode configuration
*/

#include "modules\header\config.txt"

#include "modules\header\colors.txt"
#include "modules\header\match.txt"
#include "modules\header\global.txt"
#include "modules\header\dialogs.txt"
#include "modules\header\fields.txt"

// Functions
ShowConfigDialog(playerid) {

	new string[1700];

	string = "";

	strcat(string, ""COL_PRIM"Team Names");
	strcat(string, "\n"COL_PRIM"Team Skins");
	strcat(string, "\n"COL_PRIM"A/D Settings");
	strcat(string, "\n"COL_PRIM"Restart Server");
	strcat(string, "\n"COL_PRIM"Max Ping");
	strcat(string, "\n"COL_PRIM"Max Packetloss");
	strcat(string, "\n"COL_PRIM"Min FPS");

	if(ServerLocked == true) {
		strcat(string, "\n{FF6666}Server Locked");
	} else {
		strcat(string, "\n{66FF66}Server Unlocked");
	}

	if(AntiSpam == true) {
		strcat(string, "\n{66FF66}Anti-Spam");
	} else {
		strcat(string, "\n{FF6666}Anti-Spam");
	}

	if(AutoBal == true) {
		strcat(string, "\n{66FF66}Auto-Balance");
	} else {
		strcat(string, "\n{FF6666}Auto-Balance");
	}

	if(AutoPause == true) {
		strcat(string, "\n{66FF66}Auto-Pause");
	} else {
		strcat(string, "\n{FF6666}Auto-Pause");
	}

	if(LobbyGuns == true) {
		strcat(string, "\n{66FF66}Guns in Lobby");
	} else {
		strcat(string, "\n{FF6666}Guns in Lobby");
	}

	if(ShortCuts == true) {
		strcat(string, "\n{66FF66}Team Chat Shortcuts");
	} else {
		strcat(string, "\n{FF6666}Team Chat Shortcuts");
	}

	if(ChangeName == true) {
		strcat(string, "\n{66FF66}Change name (/changename cmd)");
	} else {
		strcat(string, "\n{FF6666}Change name (/changename cmd)");
	}

    ShowPlayerDialog(playerid, DIALOG_CONFIG, DIALOG_STYLE_LIST, ""COL_PRIM"Config Settings", string, "OK", "Cancel");
    return 1;
}

LoadConfig()
{
	new iString[128];
    new DBResult:res = db_query(sqliteconnection, "SELECT * FROM Configs");
    Skin[NON] = 0;

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Attacker Skin
    Skin[ATTACKER] = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Attacker Sub Skin
    Skin[ATTACKER_SUB] = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Defender Skin
    Skin[DEFENDER] = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Defender Sub Skin
    Skin[DEFENDER_SUB] = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Referee Skin
    Skin[REFEREE] = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Server Weather
    MainWeather = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Server Time
    MainTime = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // CP Time
    ConfigCPTime = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Round Time
    ConfigRoundTime = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Total Rounds
    TotalRounds = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Maximum Packetloss
    Max_Packetloss = floatstr(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Maximum Ping
    Max_Ping = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Minimum FPS
    Min_FPS = strval(iString);
	db_next_row(res);

    db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Main Spawn
	sscanf(iString, "p,ffffd", MainSpawn[0], MainSpawn[1], MainSpawn[2], MainSpawn[3], MainInterior);
    db_next_row(res);

    db_get_field_assoc(res, "Value", iString, sizeof(iString));
    sscanf(iString, "p,ff", RoundAR, RoundHP);
	db_next_row(res);

    db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Main Background Colour
    MAIN_BACKGROUND_COLOUR = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Main Text Colour
	sscanf(iString, "s", MAIN_TEXT_COLOUR);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Color Scheme ID
 	format( ColScheme, 10, "{%s}", iString );
 	db_next_row(res);

    db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Changename
    ChangeName = (strval(iString) == 1 ? true : false);
    db_next_row(res);

	db_free_result(res);

	printf("Server Config Loaded.");
}