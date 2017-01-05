/*
  
    Team information on the right corner
  
*/

#include "modules\header\teaminfotd.txt"

CreateTeamCornerTextDraws()
{
    // Attackers textdraws
	TeamCornerInfoFirstTD[0] = TextDrawCreate(632.000000, 360.000000, "_");
	TextDrawAlignment(TeamCornerInfoFirstTD[0], 3);
	TextDrawBackgroundColor(TeamCornerInfoFirstTD[0], 0x00000050);
	TextDrawFont(TeamCornerInfoFirstTD[0], 1);
	TextDrawLetterSize(TeamCornerInfoFirstTD[0], 0.180000, 1.000000);
	TextDrawColor(TeamCornerInfoFirstTD[0], -1);
	TextDrawSetOutline(TeamCornerInfoFirstTD[0], 1);
	TextDrawSetProportional(TeamCornerInfoFirstTD[0], 1);
	
	TeamCornerInfoSecondTD[0] = TextDrawCreate(632.000000, 324.000000, "_");
	TextDrawAlignment(TeamCornerInfoSecondTD[0], 3);
	TextDrawBackgroundColor(TeamCornerInfoSecondTD[0], 0x00000050);
	TextDrawFont(TeamCornerInfoSecondTD[0], 1);
	TextDrawLetterSize(TeamCornerInfoSecondTD[0], 0.180000, 1.000000);
	TextDrawColor(TeamCornerInfoSecondTD[0], -1);
	TextDrawSetOutline(TeamCornerInfoSecondTD[0], 1);
	TextDrawSetProportional(TeamCornerInfoSecondTD[0], 1);
	
	// Defenders textdraws
	TeamCornerInfoFirstTD[1] = TextDrawCreate(632.000000, 360.000000, "_");
	TextDrawAlignment(TeamCornerInfoFirstTD[1], 3);
	TextDrawBackgroundColor(TeamCornerInfoFirstTD[1], 0x00000050);
	TextDrawFont(TeamCornerInfoFirstTD[1], 1);
	TextDrawLetterSize(TeamCornerInfoFirstTD[1], 0.180000, 1.000000);
	TextDrawColor(TeamCornerInfoFirstTD[1], -1);
	TextDrawSetOutline(TeamCornerInfoFirstTD[1], 1);
	TextDrawSetProportional(TeamCornerInfoFirstTD[1], 1);
	
	TeamCornerInfoSecondTD[1] = TextDrawCreate(632.000000, 324.000000, "_");
	TextDrawAlignment(TeamCornerInfoSecondTD[1], 3);
	TextDrawBackgroundColor(TeamCornerInfoSecondTD[1], 0x00000050);
	TextDrawFont(TeamCornerInfoSecondTD[1], 1);
	TextDrawLetterSize(TeamCornerInfoSecondTD[1], 0.180000, 1.000000);
	TextDrawColor(TeamCornerInfoSecondTD[1], -1);
	TextDrawSetOutline(TeamCornerInfoSecondTD[1], 1);
	TextDrawSetProportional(TeamCornerInfoSecondTD[1], 1);
    return 1;
}

ShowTeamCornerInfo(playerid)
{
	if(ShowHPBars)
		return 0;
		
	switch(Player[playerid][Team])
	{
	    case ATTACKER:
		{
		    TextDrawShowForPlayer(playerid,TeamCornerInfoFirstTD[0]);
			TextDrawShowForPlayer(playerid,TeamCornerInfoSecondTD[0]);
			
			TextDrawHideForPlayer(playerid,TeamCornerInfoFirstTD[1]);
			TextDrawHideForPlayer(playerid,TeamCornerInfoSecondTD[1]);
		}
		case DEFENDER:
		{
		    TextDrawShowForPlayer(playerid,TeamCornerInfoFirstTD[1]);
			TextDrawShowForPlayer(playerid,TeamCornerInfoSecondTD[1]);
			
			TextDrawHideForPlayer(playerid,TeamCornerInfoFirstTD[0]);
			TextDrawHideForPlayer(playerid,TeamCornerInfoSecondTD[0]);
		}
	}
    return 1;
}

UpdateTeamCornerInfo()
{
	if(ShowHPBars)
		return 0;
	
    // Variables for sorting	
	new temp_id;                                             // Used for swapping player ids
	new PlayersAdded[2];                                     // How many players were added to the array
	new PlayerIDs[2][MAX_PLAYERS*2];                         // Arrays that holds players' ids who are eligible to be shown
	
	// Variables for visual
	new PlayersAddedToFirstString[2];                        // Tells how many players were added to strings
	new PlayersAddedToSecondString[2];                       // Tells how many players were added to strings
	new PlayersFirstString[2][MAX_PLAYERS_STRING_SIZE];      // Strings that hold top players from arrays
	new PlayersSecondString[2][MAX_PLAYERS_STRING_SIZE];     // Strings that hold top players from arrays
	
	// Adds players to arrays
	PlayersAdded[0] = 0;
	PlayersAdded[1] = 0;
	
	foreach(new i : Player)
	{
	    if(Player[i][Team] != ATTACKER && Player[i][Team] != DEFENDER)continue;
		
		PlayerIDs[Player[i][Team]-1][PlayersAdded[Player[i][Team]-1]] = i;
		PlayersAdded[Player[i][Team]-1]++;
	}
	
	// Sorts players who are in the attackers array by damage
	for(new a=0; a < PlayersAdded[0]; a++)
	{
		for(new b=0; b < PlayersAdded[0]; b++)
		{
			if(Player[PlayerIDs[0][a]][RoundDamage] > Player[PlayerIDs[0][b]][RoundDamage])
			{
				temp_id = PlayerIDs[0][a];
				PlayerIDs[0][a] = PlayerIDs[0][b];
                PlayerIDs[0][b] = temp_id;
			}
		}
	}
	
	// Sorts players who are in the defenders array by damage
	for(new a=0; a < PlayersAdded[1]; a++)
	{
		for(new b=0; b < PlayersAdded[1]; b++)
		{
			if(Player[PlayerIDs[1][a]][RoundDamage] > Player[PlayerIDs[1][b]][RoundDamage])
			{
				temp_id = PlayerIDs[1][a];
				PlayerIDs[1][a] = PlayerIDs[1][b];
                PlayerIDs[1][b] = temp_id;
			}
		}
	}
	
	// Show top players for the first attackers textdraw
	PlayersAddedToFirstString[0] = 0;
	
    for(new i=0; i < MAX_PLAYERS_IN_TEXTDRAW; i++)
    {
	    if(i >= PlayersAdded[0])
		    break;
			
		if(Player[PlayerIDs[0][i]][Playing])
		{
		    format(PlayersFirstString[0],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~r~~h~%d ~w~- ~r~%d~n~",PlayersFirstString[0],Player[PlayerIDs[0][i]][NameWithoutTag], Player[PlayerIDs[0][i]][pHealth]+Player[PlayerIDs[0][i]][pArmour], Player[PlayerIDs[0][i]][RoundDamage]);  
		}
		else
		{
		    format(PlayersFirstString[0],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~r~~h~Dead ~w~- ~r~%d~n~",PlayersFirstString[0],Player[PlayerIDs[0][i]][NameWithoutTag], Player[PlayerIDs[0][i]][RoundDamage]);
		}	
			
        PlayersAddedToFirstString[0]++;			
	}
	
	MoveDownString(PlayersFirstString[0],PlayersAddedToFirstString[0]);
	TextDrawSetString(TeamCornerInfoFirstTD[0],PlayersFirstString[0]);
	
	// Show top players for first second textdraw
	PlayersAddedToSecondString[0] = 0;
	
    for(new i=MAX_PLAYERS_IN_TEXTDRAW; i < (MAX_PLAYERS_IN_TEXTDRAW*2); i++)
    {
	    if(i >= PlayersAdded[0])
		    break;	
			
		if(Player[PlayerIDs[0][i]][Playing])
		{
		    format(PlayersSecondString[0],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~r~~h~%d ~w~- ~r~%d~n~",PlayersSecondString[0],Player[PlayerIDs[0][i]][NameWithoutTag], Player[PlayerIDs[0][i]][pHealth]+Player[PlayerIDs[0][i]][pArmour], Player[PlayerIDs[0][i]][RoundDamage]);  
		}
		else
		{
		    format(PlayersSecondString[0],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~r~~h~Dead ~w~- ~r~%d~n~",PlayersSecondString[0],Player[PlayerIDs[0][i]][NameWithoutTag], Player[PlayerIDs[0][i]][RoundDamage]);
		}	
			
        PlayersAddedToSecondString[0]++;			
	}
	
	MoveDownString(PlayersSecondString[0],PlayersAddedToSecondString[0]);
	TextDrawSetString(TeamCornerInfoSecondTD[0],PlayersSecondString[0]);
	
	// Show top players for the first defenders textdraw
	PlayersAddedToFirstString[1] = 0;
	
    for(new i=0; i < MAX_PLAYERS_IN_TEXTDRAW; i++)
    {
	    if(i >= PlayersAdded[1])
		    break;
			
		if(Player[PlayerIDs[1][i]][Playing])
		{
		    format(PlayersFirstString[1],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~b~~h~%d ~w~- ~b~%d~n~",PlayersFirstString[1],Player[PlayerIDs[1][i]][NameWithoutTag], Player[PlayerIDs[1][i]][pHealth]+Player[PlayerIDs[1][i]][pArmour], Player[PlayerIDs[1][i]][RoundDamage]);  
		}
		else
		{
		    format(PlayersFirstString[1],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~b~~h~Dead ~w~- ~b~%d~n~",PlayersFirstString[1],Player[PlayerIDs[1][i]][NameWithoutTag], Player[PlayerIDs[1][i]][RoundDamage]);
		}	
			
        PlayersAddedToFirstString[1]++;			
	}
	
	MoveDownString(PlayersFirstString[1],PlayersAddedToFirstString[1]);
	TextDrawSetString(TeamCornerInfoFirstTD[1],PlayersFirstString[1]);
	
	// Show top players for first defenders textdraw
	PlayersAddedToSecondString[1] = 0;
	
    for(new i=MAX_PLAYERS_IN_TEXTDRAW; i < (MAX_PLAYERS_IN_TEXTDRAW*2); i++)
    {
	    if(i >= PlayersAdded[1])
		    break;	
			
		if(Player[PlayerIDs[1][i]][Playing])
		{
		    format(PlayersSecondString[1],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~b~~h~%d ~w~- ~b~%d~n~",PlayersSecondString[1],Player[PlayerIDs[1][i]][NameWithoutTag], Player[PlayerIDs[1][i]][pHealth]+Player[PlayerIDs[1][i]][pArmour], Player[PlayerIDs[1][i]][RoundDamage]);  
		}
		else
		{
		    format(PlayersSecondString[1],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~b~~h~Dead ~w~- ~b~%d~n~",PlayersSecondString[1],Player[PlayerIDs[1][i]][NameWithoutTag], Player[PlayerIDs[1][i]][RoundDamage]);
		}	
			
        PlayersAddedToSecondString[1]++;			
	}
	
	MoveDownString(PlayersSecondString[1],PlayersAddedToSecondString[1]);
	TextDrawSetString(TeamCornerInfoSecondTD[1],PlayersSecondString[1]);
    return 1;
}

MoveDownString(str[],amount)
{
	switch(amount)
	{
			case 0: format(str,MAX_PLAYERS_STRING_SIZE,"_");
			case 1: format(str,MAX_PLAYERS_STRING_SIZE,"~n~~n~~n~%s",str);
			case 2: format(str,MAX_PLAYERS_STRING_SIZE,"~n~~n~%s",str);
			case 3: format(str,MAX_PLAYERS_STRING_SIZE,"~n~%s",str);
	}  
}

HideTeamCornerInfo(playerid)
{
	if(ShowHPBars)
		return 0;

	TextDrawHideForPlayer(playerid,TeamCornerInfoFirstTD[0]);
	TextDrawHideForPlayer(playerid,TeamCornerInfoSecondTD[0]);
	TextDrawHideForPlayer(playerid,TeamCornerInfoFirstTD[1]);
	TextDrawHideForPlayer(playerid,TeamCornerInfoSecondTD[1]);
    return 1;
}

HideTeamCornerInfoForAll()
{
	if(ShowHPBars)
		return 0;

	TextDrawHideForAll(TeamCornerInfoFirstTD[0]);
	TextDrawHideForAll(TeamCornerInfoSecondTD[0]);
	TextDrawHideForAll(TeamCornerInfoFirstTD[1]);
	TextDrawHideForAll(TeamCornerInfoSecondTD[1]);
    return 1;
}