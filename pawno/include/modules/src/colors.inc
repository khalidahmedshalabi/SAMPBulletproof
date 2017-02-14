/*
		Gamemode colors: teams, messages... etc
*/

#include "modules\header\colors.txt"

SetTeamDefaultColors()
{
	TextColor[ATTACKER] 	= 	"{FF0033}";
	TextColor[ATTACKER_SUB] = 	"{FFAAAA}";
	TextColor[DEFENDER] 	= 	"{3344FF}";
	TextColor[DEFENDER_SUB] = 	"{AAAAFF}";
	TextColor[REFEREE] 		= 	"{FFFF88}";

	TDC[NON] 				= 	"~p~";
	TDC[ATTACKER] 			= 	"~r~";
	TDC[ATTACKER_SUB] 		= 	"~r~~h~";
	TDC[DEFENDER] 			= 	"~b~";
	TDC[DEFENDER_SUB] 		= 	"~b~~h~";
	TDC[REFEREE]			= 	"~y~~h~";
	return 1;
}

SaveThemeSettings()
{
    new query[128];

	format(query, sizeof(query), "UPDATE `Configs` SET `Value` = '%s' WHERE `Option` = 'MainTextColour'", MAIN_TEXT_COLOUR);
	db_free_result(db_query(sqliteconnection, query));

	format(query, sizeof(query), "UPDATE `Configs` SET `Value` = %d WHERE `Option` = 'MainBackgroundColour'", MAIN_BACKGROUND_COLOUR);
	db_free_result(db_query(sqliteconnection, query));
	return 1;
}

ChangeTheme(playerid, listitem)
{
	switch(listitem)
	{
		case 0: // White (Background) & Black (Text)
		{
		    format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~l~");
		    MAIN_BACKGROUND_COLOUR = 0xEEEEEE11;
		}
		case 1: // Black (Background) & White (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~w~");
		    MAIN_BACKGROUND_COLOUR = 0x00000044;
		}
		case 2: // White (Background) & Red (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~r~");
		    MAIN_BACKGROUND_COLOUR = 0xEEEEEE11;
		}
		case 3: // Black (Background) & Red (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~r~");
		    MAIN_BACKGROUND_COLOUR = 0x00000044;
		}
		case 4: // White (Background) & Blue (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~b~");
		    MAIN_BACKGROUND_COLOUR = 0xEEEEEE11;
		}
		case 5: // Black (Background) & Blue (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~b~");
		    MAIN_BACKGROUND_COLOUR = 0x00000044;
		}
		case 6: // White (Background) & Green (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~g~");
		    MAIN_BACKGROUND_COLOUR = 0xEEEEEE11;
		}
		case 7: // Black (Background) & Green (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~g~");
		    MAIN_BACKGROUND_COLOUR = 0x00000044;
		}
		case 8: // White (Background) & Purple (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~p~");
		    MAIN_BACKGROUND_COLOUR = 0xEEEEEE11;
		}
		case 9: // Black (Background) & Purple (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~p~");
		    MAIN_BACKGROUND_COLOUR = 0x00000044;
		}
	}
	SaveThemeSettings();
	SendClientMessageToAll(-1, sprintf("%s has set up a new theme colour. Server is restarting so the changes can take effect.", Player[playerid][Name]));
	SendRconCommand("gmx");
	return 1;
}
