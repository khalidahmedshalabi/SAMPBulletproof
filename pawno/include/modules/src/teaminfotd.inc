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
	
    // For sorting
	new PlayersAdded[2];                                           // How many players were added to the array
	new AttackersArray[MAX_PLAYERS][_sort_Info_];                  // Array that holds attackers info
	new DefendersArray[MAX_PLAYERS][_sort_Info_];                  // Array that holds defenders info
	
	// Variables for visual
	new PlayersAddedToFirstString[2];                              // Tells how many players were added to strings
	new PlayersAddedToSecondString[2];                             // Tells how many players were added to strings
	new PlayersFirstString[2][MAX_PLAYERS_STRING_SIZE];            // Strings that hold top players from arrays
	new PlayersSecondString[2][MAX_PLAYERS_STRING_SIZE];           // Strings that hold top players from arrays
	
	// How many players were added
	PlayersAdded[0] = 0;
	PlayersAdded[1] = 0;
	
	for(new i=0; i < MAX_PLAYERS; i++)
	{
	    AttackersArray[i][playerID] = -1;
		AttackersArray[i][playerDamage] = -1;
	    DefendersArray[i][playerID] = -1;
		DefendersArray[i][playerDamage] = -1;		
	}
	
	foreach(new i : Player)
	{
	    if(!Player[i][WasInBase])continue;
		
		switch(Player[i][Team])
		{
		    case ATTACKER:
			{
				AttackersArray[PlayersAdded[0]][playerID] = i;
				AttackersArray[PlayersAdded[0]][playerDamage] = Player[i][RoundDamage];
				PlayersAdded[0]++;
			}
			case DEFENDER:
			{
				DefendersArray[PlayersAdded[1]][playerID] = i;
				DefendersArray[PlayersAdded[1]][playerDamage] = Player[i][RoundDamage];
				PlayersAdded[1]++;
			}
		}
	}
	
	/*
	// This can be used to test textdraw look and sorting
	DefendersArray[PlayersAdded[1]][playerID] = PlayersAdded[1];
	DefendersArray[PlayersAdded[1]][playerDamage] = random(400);
	format(Player[PlayersAdded[1]][NameWithoutTag],MAX_PLAYER_NAME,"Dimitry");
	PlayersAdded[1]++;

	DefendersArray[PlayersAdded[1]][playerID] = PlayersAdded[1];
	DefendersArray[PlayersAdded[1]][playerDamage] = random(400);
	format(Player[PlayersAdded[1]][NameWithoutTag],MAX_PLAYER_NAME,"Jhon");
	PlayersAdded[1]++;
	
	DefendersArray[PlayersAdded[1]][playerID] = PlayersAdded[1];
	DefendersArray[PlayersAdded[1]][playerDamage] = random(400);
	format(Player[PlayersAdded[1]][NameWithoutTag],MAX_PLAYER_NAME,"Peter");
	PlayersAdded[1]++;
	
	DefendersArray[PlayersAdded[1]][playerID] = PlayersAdded[1];
	DefendersArray[PlayersAdded[1]][playerDamage] = random(400);
	format(Player[PlayersAdded[1]][NameWithoutTag],MAX_PLAYER_NAME,"Arnold");
	PlayersAdded[1]++;
	*/
	
	SortDeepArray(AttackersArray, playerDamage, .order = SORT_DESC);
	SortDeepArray(DefendersArray, playerDamage, .order = SORT_DESC);
	
	// Show top players for the second attackers textdraw
	PlayersAddedToSecondString[0] = 0;
    for(new i=0; i < (PlayersAdded[0]-MAX_PLAYERS_IN_TEXTDRAW); i++)
    {
	    if(i >= PlayersAdded[0] || PlayersAddedToSecondString[0] >= MAX_PLAYERS_IN_TEXTDRAW)
		    break;	
			
		if(Player[AttackersArray[i][playerID]][Playing])
		{
		    format(PlayersSecondString[0],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~r~~h~%d ~w~- ~r~%d~n~",PlayersSecondString[0],Player[AttackersArray[i][playerID]][NameWithoutTag], Player[AttackersArray[i][playerID]][pHealth]+Player[AttackersArray[i][playerID]][pArmour], AttackersArray[i][playerDamage]);  
		}
		else
		{
		    format(PlayersSecondString[0],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~r~~h~Dead ~w~- ~r~%d~n~",PlayersSecondString[0],Player[AttackersArray[i][playerID]][NameWithoutTag], AttackersArray[i][playerDamage]);
		}	
			
        PlayersAddedToSecondString[0]++;	
    }			
	
	MoveDownString(PlayersSecondString[0],PlayersAddedToSecondString[0]);
	TextDrawSetString(TeamCornerInfoSecondTD[0],PlayersSecondString[0]);
	
	// Show top players for the first attackers textdraw
	PlayersAddedToFirstString[0] = 0;
	
    for(new i=PlayersAddedToSecondString[0]; i < (MAX_PLAYERS_IN_TEXTDRAW+PlayersAddedToSecondString[0]); i++)
    {
	    if(i >= PlayersAdded[0])
		    break;
			
		if(Player[AttackersArray[i][playerID]][Playing])
		{
		    format(PlayersFirstString[0],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~r~~h~%d ~w~- ~r~%d~n~",PlayersFirstString[0],Player[AttackersArray[i][playerID]][NameWithoutTag], Player[AttackersArray[i][playerID]][pHealth]+Player[AttackersArray[i][playerID]][pArmour], AttackersArray[i][playerDamage]);  
		}
		else
		{
		    format(PlayersFirstString[0],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~r~~h~Dead ~w~- ~r~%d~n~",PlayersFirstString[0],Player[AttackersArray[i][playerID]][NameWithoutTag], AttackersArray[i][playerDamage]);
		}	
			
        PlayersAddedToFirstString[0]++;			
	}
	
	MoveDownString(PlayersFirstString[0],PlayersAddedToFirstString[0]);
	TextDrawSetString(TeamCornerInfoFirstTD[0],PlayersFirstString[0]);
	
	// Show top players for the second defenders textdraw
	PlayersAddedToSecondString[1] = 0;
    for(new i=0; i < (PlayersAdded[1]-MAX_PLAYERS_IN_TEXTDRAW); i++)
    {
	    if(i >= PlayersAdded[1] || PlayersAddedToSecondString[1] >= MAX_PLAYERS_IN_TEXTDRAW)
		    break;	
			
		if(Player[DefendersArray[i][playerID]][Playing])
		{
		    format(PlayersSecondString[1],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~b~~h~%d ~w~- ~b~%d~n~",PlayersSecondString[1],Player[DefendersArray[i][playerID]][NameWithoutTag], Player[DefendersArray[i][playerID]][pHealth]+Player[DefendersArray[i][playerID]][pArmour], DefendersArray[i][playerDamage]);  
		}
		else
		{
		    format(PlayersSecondString[1],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~b~~h~Dead ~w~- ~b~%d~n~",PlayersSecondString[1],Player[DefendersArray[i][playerID]][NameWithoutTag], DefendersArray[i][playerDamage]);
		}	
			
        PlayersAddedToSecondString[1]++;	
    }			
	
	MoveDownString(PlayersSecondString[1],PlayersAddedToSecondString[1]);
	TextDrawSetString(TeamCornerInfoSecondTD[1],PlayersSecondString[1]);
	
	// Show top players for the first defenders textdraw
	PlayersAddedToFirstString[1] = 0;
	
    for(new i=PlayersAddedToSecondString[1]; i < (MAX_PLAYERS_IN_TEXTDRAW+PlayersAddedToSecondString[1]); i++)
    {
	    if(i >= PlayersAdded[1])
		    break;
			
		if(Player[DefendersArray[i][playerID]][Playing])
		{
		    format(PlayersFirstString[1],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~b~~h~%d ~w~- ~b~%d~n~",PlayersFirstString[1],Player[DefendersArray[i][playerID]][NameWithoutTag], Player[DefendersArray[i][playerID]][pHealth]+Player[DefendersArray[i][playerID]][pArmour], DefendersArray[i][playerDamage]);  
		}
		else
		{
		    format(PlayersFirstString[1],MAX_PLAYERS_STRING_SIZE,"%s~w~| %s ~b~~h~Dead ~w~- ~b~%d~n~",PlayersFirstString[1],Player[DefendersArray[i][playerID]][NameWithoutTag], DefendersArray[i][playerDamage]);
		}	
			
        PlayersAddedToFirstString[1]++;			
	}
	
	MoveDownString(PlayersFirstString[1],PlayersAddedToFirstString[1]);
	TextDrawSetString(TeamCornerInfoFirstTD[1],PlayersFirstString[1]);
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