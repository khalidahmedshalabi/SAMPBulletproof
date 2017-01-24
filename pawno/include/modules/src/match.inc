/*
		Round/match related
*/

#include "modules\header\match.txt"

#include "modules\header\fields.txt"
#tryinclude "modules\header\league.txt"
#include "modules\header\messagebox.txt"
#include <YSI_inc\YSI\y_hooks>

hook OnPlayerDisconnect(playerid, reason)
{
    // If this player was in round
	if(Player[playerid][Playing] == true)
	{
        // Reset team leading status
	    PlayerNoLeadTeam(playerid);

        // Store player data temporarily in case they come back to the game again
	    StorePlayerVariables(playerid);

        // If configured to pause the round automatically
		if(AutoPause == true && RoundPaused != true && RoundUnpausing != true)
        {
    		KillTimer(UnpauseTimer);
    		RoundUnpausing = false;
    		PauseRound();
    		SendClientMessageToAll(-1, ""COL_PRIM"Round has been auto-paused.");
        }
	}
	else
		StorePlayerVariablesMin(playerid);
	
	// Resets backup request (player can be not in the round anymore and timer was not completed either)
	if(Player[playerid][AskingForHelp])
	{
		EndTeamBackupRequest(playerid,((Player[playerid][Team] == DEFENDER) ? DEFENDER_BACKUP_ICON : ATTACKER_BACKUP_ICON));
	}

	// Handle match
 	Iter_Remove(PlayersInRound, playerid);
	UpdateTeamPlayerCount(Player[playerid][Team], true, playerid);
	UpdateTeamHP(Player[playerid][Team], playerid);
	// Call OnPlayerLeaveCheckpoint to see if this player was in the checkpoint and fix issues
	if(Current != -1)
	{
        OnPlayerLeaveCheckpoint(playerid);
	}
	return 1;
}

hook OnGameModeInit()
{
	for(new i = 0; i < MAX_TEAMS; ++i)
	{
		TeamDeathIconTimer[i] = -1;
	}
	return 1;
}

forward StartRoundAutomatically();
public StartRoundAutomatically()
{
	if(!AutoRoundStarter || Current != -1 || AllowStartBase == false)
		return 0;

	new ct[2] = {0, 0};
	foreach(new i : Player)
	{
		if(noclipdata[i][FlyMode] == true || Player[i][InDuel])
			continue;

		switch(Player[i][Team])
		{
			case ATTACKER:
			{
				ct[0] ++;
			}
			case DEFENDER:
			{
				ct[1] ++;
			}
		}
	}
	if(ct[0] < 1 || ct[1] < 1)
	{
		SendClientMessageToAll(-1, ""COL_PRIM"Auto round starter error: {FFFFFF}Not enough players to start a round!");
		SendClientMessageToAll(-1, "{FFFFFF}System "COL_PRIM"will try to start a round again in 60 seconds!");
		SetTimer("StartRoundAutomatically", 60000, false);
		return 0;
	}

	BalanceTeams();
	SendClientMessageToAll(-1, "{FFFFFF}System "COL_PRIM"has balanced the teams!");

	AllowStartBase = false; // Make sure other player or you yourself is not able to start round on top of another round.
	foreach(new i : Player)
	{
		if(CanPlay(i))
		{
			TogglePlayerControllable(i, 0); // Pause all the players.
			Player[i][ToAddInRound] = true;
		}
	}
	switch(random(2))
	{
		case 0: // arena
		{
			new id = DetermineRandomRound(0, true, ARENA);
			SetTimerEx("OnArenaStart", 2000, false, "i", id);

			new str[144];
			format(str, sizeof(str), "{FFFFFF}System "COL_PRIM"has randomly started Arena: {FFFFFF}%s (ID: %d)", AName[id], id);
			SendClientMessageToAll(-1, str);
		}
		case 1: // base
		{
			new id = DetermineRandomRound(0, true, BASE);
			SetTimerEx("OnBaseStart", 2000, false, "i", id);

			new str[144];
			format(str, sizeof(str), "{FFFFFF}System "COL_PRIM"has randomly started Base: {FFFFFF}%s (ID: %d)", BName[id], id);
			SendClientMessageToAll(-1, str);
		}
	}
	return 1;
}

SetRoundAutoStart(in_seconds)
{
	if(in_seconds > 0)
	{
		SendClientMessageToAll(-1, sprintf("{FFFFFF}System "COL_PRIM"is starting another round in %d seconds!", in_seconds));
		SetTimer("StartRoundAutomatically", in_seconds * 1000, false);
	}
	else
	{
		StartRoundAutomatically();
	}
}

// Set default name for all teams
SetTeamDefaultNames()
{
	TeamName[ATTACKER] = "Alpha";
	TeamName[DEFENDER] = "Beta";
	TeamName[REFEREE] = "Referee";
	TeamName[ATTACKER_SUB] = "Alpha Sub";
	TeamName[DEFENDER_SUB] = "Beta Sub";
	return 1;
}

// Basically checks if a team lacks players, the other team should win
CheckTeamElimination()
{
	// If round is paused or there's no active round at all, we should stop the process
	if(RoundPaused || Current == -1)
		return -1;

	// Reset teams player count to 0
	PlayersAlive[ATTACKER] = 0;
	PlayersAlive[DEFENDER] = 0;
	// Loop through all players who are currently in round
	foreach(new i : PlayersInRound)
	{
		switch(Player[i][Team])
		{
			case ATTACKER:
			{
				// If they're attackers, increase attacker team player count by 1
				PlayersAlive[ATTACKER] ++;
			}
			case DEFENDER:
			{
				// If they're defenders, increase defender team player count by 1
				PlayersAlive[DEFENDER] ++;
			}
		}
	}
	
	#if ROUND_NEVER_END != 1
	// If both teams have no players
	if(PlayersAlive[ATTACKER] == 0 && PlayersAlive[DEFENDER] == 0)
	{
		EndRound(4); // Nobody wins
		return 0;
	}
	// If attacker team has no players, defenders win
	else if(PlayersAlive[ATTACKER] == 0)
	{
		EndRound(2); // Defenders Win
		return 0;
	}
	// If defender team has no players, attackers win
	else if(PlayersAlive[DEFENDER] == 0)
	{
		EndRound(3); // Attackers Win
		return 0;
	}
	#endif
	return 1;
}

/*
Summary:
Corrects the player count for a team and update textdraws then check for elimination if asked

Parameters:
teamid: the team to check
elimination_check: a bool to check for elimination
exception: the id of the player who we should ignore while looping and checking. -1 to disable
*/
UpdateTeamPlayerCount(teamid, bool:elimination_check, exception = -1)
{
	// If there's no active round, we should stop the process
	if(Current == -1 || (ArenaStarted == false && BaseStarted == false))
		return;

	// Reset team player count variable
	PlayersAlive[teamid] = 0;
	// Loop through players in round
	foreach(new i : PlayersInRound)
	{
		if(i == exception)
			continue;

		// If this player isn't in the team we want to check
		if(Player[i][Team] != teamid)
			continue; // Skip this index

		PlayersAlive[teamid] ++; // Increase team player count by 1
	}

	// Update round textdraws
	new str[150];
	switch(teamid)
	{
		case ATTACKER:
		{
			format(str, sizeof str, "~w~%d__(%d)", PlayersAlive[ATTACKER], TeamHP[ATTACKER]);
			TextDrawSetString(leftTeamData, str);
		}
		case DEFENDER:
		{
			format(str, sizeof str, "~w~(%d)__%d", TeamHP[DEFENDER], PlayersAlive[DEFENDER]);
			TextDrawSetString(rightTeamData, str);
		}
	}

	// Update attdef style round textdraws
	format(str, sizeof(str),
	"~r~~h~%s  ~r~~h~~h~%d   ~w~(~r~~h~~h~%d~w~)			   	                    			   	            ~b~~h~%s  ~b~~h~~h~%d   ~w~(~b~~h~~h~%d~w~)~n~",
	TeamName[ATTACKER], PlayersAlive[ATTACKER], TeamHP[ATTACKER], TeamName[DEFENDER], PlayersAlive[DEFENDER], TeamHP[DEFENDER]);
	TextDrawSetString(AttDef_RoundStats, str);

	// If we're asked to check team/round elimination
	#if ROUND_NEVER_END != 1
	if(elimination_check)
	{
		// If round is not paused
		if(!RoundPaused)
		{
			// Handle lack of players (or elimination)
			if(PlayersAlive[ATTACKER] == 0)
				EndRound(2); // Defenders Win
			else if(PlayersAlive[DEFENDER] == 0)
				EndRound(3); // Attackers Win
		}
	}
	#endif
}

// This updates round textdraws with correct HP info for each team
// teamid: team to check
// exception: the id of the player who we should ignore while looping and checking. -1 to disable
UpdateTeamHP(teamid, exception = -1)
{
	// If there's no active round, this call is a waste
	if(Current == -1 || (ArenaStarted == false && BaseStarted == false))
		return;

	// Reset team hp variable
	TeamHP[teamid] = 0;
	// Loop through players playing current round
	foreach(new i : PlayersInRound)
	{
		if(i == exception)
			continue;

		// If he isn't in the specified team
		if(Player[i][Team] != teamid)
			continue; // Skip this index

		// Add total HP of this player (at this index) to team total HP
		TeamHP[teamid] += Player[i][pHealth] + Player[i][pArmour];
	}
	// Update round textdraws with correct info
	new str[150];
	switch(teamid)
	{
		case ATTACKER:
		{
			format(str, sizeof str, "~w~%d__(%d)", PlayersAlive[ATTACKER], TeamHP[ATTACKER]);
			TextDrawSetString(leftTeamData, str);
		}
		case DEFENDER:
		{
			format(str, sizeof str, "~w~(%d)__%d", TeamHP[DEFENDER], PlayersAlive[DEFENDER]);
			TextDrawSetString(rightTeamData, str);
		}
	}

	// Update attdef style round textdraws
	format(str, sizeof(str),
	"~r~~h~%s  ~r~~h~~h~%d   ~w~(~r~~h~~h~%d~w~)			   	                    			   	            ~b~~h~%s  ~b~~h~~h~%d   ~w~(~b~~h~~h~%d~w~)~n~",
	TeamName[ATTACKER], PlayersAlive[ATTACKER], TeamHP[ATTACKER], TeamName[DEFENDER], PlayersAlive[DEFENDER], TeamHP[DEFENDER]);
	TextDrawSetString(AttDef_RoundStats, str);
}

// This is a handler for any game running (base, arena, etc...)
forward GameLoopCallback();
public GameLoopCallback()
{
	if(Current == -1)
	{
		// If there's no active round, we kill this timer so the loop isn't called again
		KillGameLoop();
		return 0;
	}
	switch(GameType)
	{
		case BASE:
		{
			foreach(new i : PlayersInRound) // Loop through all players in round
			{
				// Plays sound when CP is being taken
				if(PlayersInCP > 0 && RoundPaused == false)
					PlayerPlaySound(i,1056,0.0,0.0,0.0);
				// Net check
				if(Player[i][NetCheck] == 1 && !Player[i][TempNetcheck])
				{
					CheckPlayerNet(i);
				}
			}
			if(BaseStarted == true)
			{
				if(RoundPaused == false)
				{
					// Handle round time
					RoundSeconds --;
					if(RoundSeconds <= 0) {
						RoundSeconds = 59;
						RoundMints--;
						if(RoundMints < 0) return EndRound(1); // Defenders Win
					}
					// Increase elapsed time
					ElapsedTime++;
					// Draw round time (and CP time if it's being taken)
					switch(PlayersInCP)
					{
						case 0:
						{
							new str[16];
							format(str, sizeof(str),"~w~%d:%02d", RoundMints,	RoundSeconds);
							TextDrawSetString(timerCenterTD , str);
							TextDrawSetString(AttDef_RoundTimer , str);
						}
						default:
						{
							new str[32];
							CurrentCPTime --;
							format(str, sizeof(str), "~w~%d:%02d / ~r~~h~%d", RoundMints,	RoundSeconds, CurrentCPTime );
							TextDrawSetString(timerCenterTD , str);
							TextDrawSetString(AttDef_RoundTimer , str);

							if(CurrentCPTime == 0)
								return EndRound(0); // Attackers Win
						}
					}

				}
			}
		}
		case ARENA:
		{
			foreach(new i : PlayersInRound) // Loop through all players in round
			{
				// Plays sound when CP is being taken
				if(PlayersInCP > 0 && RoundPaused == false)
					PlayerPlaySound(i,1056,0.0,0.0,0.0);
				// Net check
				if(Player[i][NetCheck] == 1 && !Player[i][TempNetcheck])
				{
					CheckPlayerNet(i);
				}
				// Perform zone limit check if arena is in progress
				if(ArenaStarted)
				{
					if(RoundPaused == false && IsPlayerInArea(i,AMin[Current][0], AMax[Current][0], AMin[Current][1], AMax[Current][1]) != 1)
					{
						Player[i][OutOfArena] --;

						PlayerTextDrawSetString(i, AreaCheckTD[i], sprintf("%sStay in Arena. (~r~~h~%d%s)", MAIN_TEXT_COLOUR, Player[i][OutOfArena], MAIN_TEXT_COLOUR));
						PlayerTextDrawShow(i, AreaCheckTD[i]);
						PlayerTextDrawShow(i, AreaCheckBG[i]);

						if(Player[i][OutOfArena] == 0)
						{
							SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been removed for not staying in Arena. {FFFFFF}(%d | %d)", Player[i][Name], Player[i][pHealth], Player[i][pArmour]));

							Player[i][OutOfArena] = MAX_ZONE_LIMIT_WARNINGS;

							PlayerTextDrawHide(i, AreaCheckTD[i]);
							PlayerTextDrawHide(i, AreaCheckBG[i]);
							new tmp = i;
							Iter_SafeRemove(PlayersInRound, i, i);
							RemovePlayerFromRound(tmp, false);
							break;
						}
					}
					else
					{
						if(Player[i][OutOfArena] != MAX_ZONE_LIMIT_WARNINGS)
						{
							Player[i][OutOfArena] = MAX_ZONE_LIMIT_WARNINGS;
							PlayerTextDrawHide(i, AreaCheckTD[i]);
							PlayerTextDrawHide(i, AreaCheckBG[i]);
						}
					}
				}
			}
			if(ArenaStarted == true)
			{
				if( GameType == ARENA )
				{
					if(RoundPaused == false)
					{
						RoundSeconds--;
						if(RoundSeconds <= 0)
						{
							RoundSeconds = 59;
							RoundMints--;
							if(RoundMints < 0)
							{
								if(TeamHP[ATTACKER] < TeamHP[DEFENDER]) EndRound(2);
								else if(TeamHP[DEFENDER] < TeamHP[ATTACKER]) EndRound(3);
								else if(floatround(TeamHP[ATTACKER]) == floatround(TeamHP[DEFENDER])) EndRound(4); // No one win
								return 1;
							}
						}
						ElapsedTime++;
						// Draw round time (and CP time if it's being taken)
						switch(PlayersInCP)
						{
							case 0:
							{
								new str[16];
								format(str, sizeof(str),"~w~%d:%02d", RoundMints,	RoundSeconds);
								TextDrawSetString(timerCenterTD , str);
								TextDrawSetString(AttDef_RoundTimer , str);
							}
							default:
							{
								CurrentCPTime --;
								new str[32];
								format(str, sizeof(str), "~w~%d:%02d / %s%d", RoundMints,	RoundSeconds, TDC[TeamCapturingCP], CurrentCPTime );
								TextDrawSetString(timerCenterTD , str);
								TextDrawSetString(AttDef_RoundTimer , str);

								if(CurrentCPTime == 0)
								{
									switch(TeamCapturingCP)
									{
										case ATTACKER:
										{
											return EndRound(5);
										}
										case DEFENDER:
										{
											return EndRound(6);
										}
										default:
										{
											return EndRound(4);
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return 1;
}

StartGameLoop()
{
	if(GameLoop != -1)
		return 0;

	GameLoop = SetTimer("GameLoopCallback", GAME_SPEED, true);
	return 1;
}

KillGameLoop()
{
	if(GameLoop == -1)
		return;

	KillTimer(GameLoop);
	GameLoop = -1;
}

RestartGameLoop()
{
	if(GameLoop == -1)
		return;

	KillGameLoop();
	StartGameLoop();
}

// Delete arenas that are already played from memory (so they can be started again from random arena command)
ForgetPlayedArenas()
{
	for(new i = 0; i <= TotalArenas; i ++)
		IsArenaPlayed[i] = false;
}

// Delete bases that are already played from memory (so they can be started again from random base command)
ForgetPlayedBases()
{
	for(new i = 0; i <= TotalBases; i ++)
		IsBasePlayed[i] = false;
}

/*
	DOES: Generate a random ID to start a round

	PARAMETERS:
	mode: 0 for int and ext, 1 interior only, 2 exterior only
	ignore: false to skip already played bases, true to ignore that
	type: ARENA for arena, BASE for base, ...

	RETURN:
	Random ID of mode to start
	or -1 if an error occurred

	NOTE:
	If arenas/bases created are not much enough, this function just returns the last created base/arena or 0.
*/
DetermineRandomRound(mode = 0, bool:ignore = false, type = ARENA)
{
	switch(type)
	{
		case ARENA:
		{
			if(TotalArenas <= 1)
				return TotalArenas;

			switch(mode)
			{
				case 0: // Exterior and interior
				{
					new
						timesSearched, // How many times we searched for an arena
						id = random(MAX_ARENAS); // Generate a random ID

					switch(ignore)
					{
						case false: // If we're told not to ignore arenas that's already been played
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all arenas are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE arena is already played or doesn't exist, and we haven't searched all arenas yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while((IsArenaPlayed[id] || !AExist[id]) && timesSearched < TotalArenas)
							{
								id = random(MAX_ARENAS); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalArenas)
							{
								// Once we search all arenas and find them all already played
								// We clear them and
								ForgetPlayedArenas();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this arena
							// and indicate that it's already played
							IsArenaPlayed[id] = true;
							return id;
						}
						case true: // If we can ignore already played arenas
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all arenas are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE arena doesn't exist, and we haven't searched all arenas yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while(!AExist[id] && timesSearched < TotalArenas)
							{
								id = random(MAX_ARENAS); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalArenas)
							{
								// Once we search all arenas and find them all already played
								// We clear them and
								ForgetPlayedArenas();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this arena
							// and indicate that it's already played
							IsArenaPlayed[id] = true;
							return id;
						}
					}
				}
				case 1: // Interior only
				{
					new
						timesSearched, // How many times we searched for an arena
						id = random(MAX_ARENAS); // Generate a random ID

					switch(ignore)
					{
						case false: // If we're told not to ignore arenas that's already been played
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all arenas are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE arena is already played or doesn't exist or isn't in interior, and we
							// haven't searched all arenas yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while((IsArenaPlayed[id] || !AExist[id] || AInterior[id] == 0) && timesSearched < TotalArenas)
							{
								id = random(MAX_ARENAS); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalArenas)
							{
								// Once we search all arenas and find them all already played
								// We clear them and
								ForgetPlayedArenas();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this arena
							// and indicate that it's already played
							IsArenaPlayed[id] = true;
							return id;
						}
						case true: // If we can ignore already played arenas
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all arenas are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE arena doesn't exist or is not in an interior, and we haven't searched
							// all arenas yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while((!AExist[id] || AInterior[id] == 0) && timesSearched < TotalArenas)
							{
								id = random(MAX_ARENAS); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalArenas)
							{
								// Once we search all arenas and find them all already played
								// We clear them and
								ForgetPlayedArenas();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this arena
							// and indicate that it's already played
							IsArenaPlayed[id] = true;
							return id;
						}
					}
				}
				case 2: // Exterior only
				{
					new
						timesSearched, // How many times we searched for an arena
						id = random(MAX_ARENAS); // Generate a random ID

					switch(ignore)
					{
						case false: // If we're told not to ignore arenas that's already been played
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all arenas are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE arena is already played or doesn't exist or is in interior, and we
							// haven't searched all arenas yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while((IsArenaPlayed[id] || !AExist[id] || AInterior[id] != 0) && timesSearched < TotalArenas)
							{
								id = random(MAX_ARENAS); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalArenas)
							{
								// Once we search all arenas and find them all already played
								// We clear them and
								ForgetPlayedArenas();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this arena
							// and indicate that it's already played
							IsArenaPlayed[id] = true;
							return id;
						}
						case true: // If we can ignore already played arenas
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all arenas are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE arena doesn't exist or is in an interior, and we haven't searched
							// all arenas yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while((!AExist[id] || AInterior[id] != 0) && timesSearched < TotalArenas)
							{
								id = random(MAX_ARENAS); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalArenas)
							{
								// Once we search all arenas and find them all already played
								// We clear them and
								ForgetPlayedArenas();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this arena
							// and indicate that it's already played
							IsArenaPlayed[id] = true;
							return id;
						}
					}
				}
			}
		}
		case BASE:
		{
			if(TotalBases <= 1)
				return TotalBases;

			switch(mode)
			{
				case 0: // Exterior and interior
				{
					new
						timesSearched, // How many times we searched for a base
						id = random(MAX_BASES); // Generate a random ID

					switch(ignore)
					{
						case false: // If we're told not to ignore bases that's already been played
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all bases are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE base is already played or doesn't exist, and we haven't searched all bases yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while((IsBasePlayed[id] || !BExist[id]) && timesSearched < TotalBases)
							{
								id = random(MAX_BASES); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalBases)
							{
								// Once we search all bases and find them all already played
								// We clear them and
								ForgetPlayedBases();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this base
							// and indicate that it's already played
							IsBasePlayed[id] = true;
							return id;
						}
						case true: // If we can ignore already played bases
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all bases are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE base doesn't exist, and we haven't searched all bases yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while(!BExist[id] && timesSearched < TotalBases)
							{
								id = random(MAX_BASES); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalBases)
							{
								// Once we search all bases and find them all already played
								// We clear them and
								ForgetPlayedBases();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this base
							// and indicate that it's already played
							IsBasePlayed[id] = true;
							return id;
						}
					}
				}
				case 1: // Interior only
				{
					new
						timesSearched, // How many times we searched for a base
						id = random(MAX_BASES); // Generate a random ID

					switch(ignore)
					{
						case false: // If we're told not to ignore bases that's already been played
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all bases are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE base is already played or doesn't exist or isn't in interior, and we
							// haven't searched all bases yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while((IsBasePlayed[id] || !BExist[id] || BInterior[id] == 0) && timesSearched < TotalBases)
							{
								id = random(MAX_BASES); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalBases)
							{
								// Once we search all bases and find them all already played
								// We clear them and
								ForgetPlayedBases();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this base
							// and indicate that it's already played
							IsBasePlayed[id] = true;
							return id;
						}
						case true: // If we can ignore already played bases
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all bases are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE base doesn't exist or is not in an interior, and we haven't searched
							// all bases yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while((!BExist[id] || BInterior[id] == 0) && timesSearched < TotalBases)
							{
								id = random(MAX_BASES); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalBases)
							{
								// Once we search all bases and find them all already played
								// We clear them and
								ForgetPlayedBases();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this arena
							// and indicate that it's already played
							IsBasePlayed[id] = true;
							return id;
						}
					}
				}
				case 2: // Exterior only
				{
					new
						timesSearched, // How many times we searched for an base
						id = random(MAX_BASES); // Generate a random ID

					switch(ignore)
					{
						case false: // If we're told not to ignore bases that's already been played
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all bases are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE base is already played or doesn't exist or is in interior, and we
							// haven't searched all bases yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while((IsBasePlayed[id] || !BExist[id] || BInterior[id] != 0) && timesSearched < TotalBases)
							{
								id = random(MAX_BASES); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalBases)
							{
								// Once we search all bases and find them all already played
								// We clear them and
								ForgetPlayedBases();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this base
							// and indicate that it's already played
							IsBasePlayed[id] = true;
							return id;
						}
						case true: // If we can ignore already played bases
						{
							// This 'RedoSearch' will be a start point to redo the search after a cleanup.
							// Will only happen if all arenas are already played.
							RedoSearch:
							timesSearched = 0; // We haven't searched yet so initialize it with the value 0
							// WHILE arena doesn't exist or is in an interior, and we haven't searched
							// all arenas yet
							// only then this loop will be going, if any of those statements above are false
							// the loop will break out
							while((!BExist[id] || BInterior[id] != 0) && timesSearched < TotalBases)
							{
								id = random(MAX_BASES); // Generate another ID randomly
								timesSearched ++; // We searched so increase the count by one
							}
							if(timesSearched == TotalBases)
							{
								// Once we search all BASES and find them all already played
								// We clear them and
								ForgetPlayedBases();
								goto RedoSearch; // Restart search
							}
							// If everything passes fine we return the ID of this base
							// and indicate that it's already played
							IsBasePlayed[id] = true;
							return id;
						}
					}
				}
			}
		}
	}
	return -1;
}

forward UnpauseRound();
public UnpauseRound()
{
	if(PauseStopWatchTimer != -1)
	{
		KillTimer(PauseStopWatchTimer);
		PauseStopWatchTimer = -1;
	}

	RoundUnpausing = true;
	PauseCountdown --;

	if(PauseCountdown > 0)
	{
		foreach(new i : PlayersInRound)
			PlayerPlaySound(i, 1056, 0.0, 0.0, 0.0);

		new iString[40];
		format(iString, sizeof(iString), "~g~~h~Round resuming in ~h~%d", PauseCountdown);
		TextDrawSetString(PauseTD, iString);
		TextDrawShowForAll(PauseTD);
		UnpauseTimer = SetTimer("UnpauseRound", 1000, 0);
	}
	else
	{
		foreach(new i : PlayersInRound)
		{
			PlayerPlaySound(i, 1056, 0.0, 0.0, 0.0);
			if(!Player[i][OnGunmenu])
				TogglePlayerControllable(i, 1);
			else
				TogglePlayerControllable(i, 0);

			if(!Player[i][ToGiveParachute])
				SetPlayerArmedWeapon(i, 0);
			else
			{
				GivePlayerWeapon(i, WEAPON_PARACHUTE, 1);
				SetPlayerArmedWeapon(i, WEAPON_PARACHUTE);
				Player[i][ToGiveParachute] = false;
			}
		}
	    RoundPaused = false;
	    RoundUnpausing = false;
	    TextDrawHideForAll(PauseTD);
	    RecountPlayersOnCP();
		CheckTeamElimination();
	    foreach(new g : DynamicVehicle)
		{
			if(IsAirVehicle(g))
			{
				continue;
			}
			SetVehicleVelocity(g, VehicleVelc[g][0], VehicleVelc[g][1], VehicleVelc[g][2]);
		}
		KillTimer(PauseAirVehicles_Timer);
		Iter_Clear(TempAirVehicles);

		KillTimer(TipTimerDuringPause);
		TipTimerDuringPause = -1;
	}
	return 1;
}

forward PauseAirVehicles_Handler();
public PauseAirVehicles_Handler()
{
	if(Iter_Count(TempAirVehicles) == 0)
		return KillTimer(PauseAirVehicles_Timer);

	foreach(new i : TempAirVehicles)
		SetVehiclePos(i, TempAirVehicles_Pos[i][0], TempAirVehicles_Pos[i][1], TempAirVehicles_Pos[i][2]);
	return 1;
}

forward PauseStopWatch();
public PauseStopWatch()
{
	if(PauseTimeElapsed[0] == 59)
	{
		PauseTimeElapsed[0] = 0;
		PauseTimeElapsed[1] ++;
	}
	else
		PauseTimeElapsed[0] ++;

	new str[68];
    format(str, sizeof str, "~r~~h~Round is paused!~n~~w~Time: ~r~~h~%02d:%02d ~w~Count: ~r~~h~%d", PauseTimeElapsed[1], PauseTimeElapsed[0], TotalPausesInRound);
	TextDrawSetString(PauseTD, str);
	return 1;
}

PauseRound()
{
	new airVehiclesFound = 0;
	foreach(new g : DynamicVehicle)
	{
		if(IsAirVehicle(g))
		{
			airVehiclesFound ++;
			GetVehiclePos(g, TempAirVehicles_Pos[g][0], TempAirVehicles_Pos[g][1], TempAirVehicles_Pos[g][2]);
			Iter_Add(TempAirVehicles, g);
			continue;
		}
		GetVehicleVelocity(g, VehicleVelc[g][0], VehicleVelc[g][1], VehicleVelc[g][2]);
	}
	if(airVehiclesFound != 0)
		PauseAirVehicles_Timer = SetTimer("PauseAirVehicles_Handler", 50, true);

	if(TipTimerDuringPause != -1)
		KillTimer(TipTimerDuringPause);

	TipTimerDuringPause = SetTimer("SendTipMessageToAll", 15000, false);

	if(PauseStopWatchTimer == -1)
	{
		TotalPausesInRound ++;
		PauseTimeElapsed[0] = 0;
		PauseTimeElapsed[1] = 0;
		PauseStopWatchTimer = SetTimer("PauseStopWatch", 1000, true);
	}

	foreach(new i : PlayersInRound)
	{
		TogglePlayerControllable(i, 0);
		if(GetPlayerWeapon(i) == WEAPON_PARACHUTE)
			Player[i][ToGiveParachute] = true;
	}
	TextDrawSetString(PauseTD, "_");
	TextDrawShowForAll(PauseTD);
	RoundPaused = true;
}

PlayerLeadTeam(playerid, bool:force, bool:message = true)
{
    new team = Player[playerid][Team];

    if(!force && TeamHasLeader[team] == true)
        return 0;

    TeamLeader[team] = playerid;
	TeamHasLeader[team] = true;
	if(message)
	{
		switch(team)
		{
			case ATTACKER:
			{
				foreach(new i : Player)
				{
					if(Player[i][Team] == ATTACKER || Player[i][Team] == ATTACKER_SUB)
					{
						SendClientMessage(i, -1, sprintf("%s%s {FFFFFF}is now leading the team.", TextColor[team], Player[playerid][Name]));
					}
					if(i != playerid && GetPlayerColor(i) == TEAM_LEADER_COLOUR)
						ColorFix(i);
				}
			}
			case DEFENDER:
			{
				foreach(new i : Player)
				{
					if(Player[i][Team] == DEFENDER || Player[i][Team] == DEFENDER_SUB)
					{
						SendClientMessage(i, -1, sprintf("%s%s {FFFFFF}is now leading the team.", TextColor[team], Player[playerid][Name]));
					}
					if(i != playerid && GetPlayerColor(i) == TEAM_LEADER_COLOUR)
						ColorFix(i);
				}
			}
		}
	}
	SetPlayerColor(playerid, TEAM_LEADER_COLOUR);
    RadarFix(playerid);
	return 1;
}

PlayerNoLeadTeam(playerid)
{
    new team = Player[playerid][Team];

	if(TeamHasLeader[team] == true && TeamLeader[team] == playerid)
	{
	    TeamLeader[team] = INVALID_PLAYER_ID;
		TeamHasLeader[team] = false;
		switch(team)
		{
			case ATTACKER:
			{
				foreach(new i : Player)
				{
					if(Player[i][Team] == ATTACKER || Player[i][Team] == ATTACKER_SUB)
					{
						SendClientMessage(i, -1, sprintf("%s%s {FFFFFF}is no longer leading the team.", TextColor[team], Player[playerid][Name]));
					}
				}
				EndTeamBackupRequest(playerid, ATTACKER_BACKUP_ICON);
			}
			case DEFENDER:
			{
				foreach(new i : Player)
				{
					if(Player[i][Team] == DEFENDER || Player[i][Team] == DEFENDER_SUB)
					{
						SendClientMessage(i, -1, sprintf("%s%s {FFFFFF}is no longer leading the team.", TextColor[team], Player[playerid][Name]));
					}
				}
				EndTeamBackupRequest(playerid, DEFENDER_BACKUP_ICON);
			}
		}
	}
	return 1;
}

ResetTeamLeaders()
{
	new playerid;
	for(new team = 0; team < MAX_TEAMS; team ++)
	{
	    if(TeamHasLeader[team] == true)
		{
			if(IsPlayerConnected(TeamLeader[team]))
			{
				playerid = TeamLeader[team];
				TeamLeader[team] = INVALID_PLAYER_ID;
				TeamHasLeader[team] = false;
				ColorFix(playerid);
				RadarFix(playerid);
			}
			else
			{
				TeamLeader[team] = INVALID_PLAYER_ID;
				TeamHasLeader[team] = false;
			}
		}
	}
	return 1;
}

ResetBackupRequests()
{
    foreach(new i : Player)
	{
	    if(Player[i][AskingForHelp])
		    EndTeamBackupRequest(i,((Player[i][Team] == DEFENDER) ? DEFENDER_BACKUP_ICON : ATTACKER_BACKUP_ICON));
	}
}

forward EndTeamBackupRequest(playerid, iconid);
public EndTeamBackupRequest(playerid, iconid)
{
    if(!Player[playerid][AskingForHelp])return 1;

	new team = Player[playerid][Team];
	TeamHelp[team] = false;
	Player[playerid][AskingForHelp] = false;

	foreach(new i : Player)
	{
		RemovePlayerMapIcon(i, iconid);
	}

	if(TeamHasLeader[team] == true && TeamLeader[team] == playerid)
	    PlayerLeadTeam(playerid, true, false);
	else
	{
		ColorFix(playerid);
		RadarFix(playerid);
	}
	
	UpdatePlayerTeamBar(playerid);
	return 1;
}

PlayerRequestBackup(playerid)
{
	new team = Player[playerid][Team];

	// Check if there's someone in their team already requesting backup
	if(TeamHelp[team])
		return 0; // fail

	// Calculate the player's total HP
	new totHP = Player[playerid][pHealth] + Player[playerid][pArmour];

	// Get the player's facing angle
	new Float:facingAngle;
	GetPlayerFacingAngle(playerid, facingAngle);

	// Get player's position
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);

	// Find how many players are in range
	new enemiesCt = 0;
	foreach(new i : PlayersInRound)
	{
		// in enemy team?
		if(Player[i][Team] != team)
		{
			// Check if enemy is in range
			if(IsPlayerInRangeOfPoint(i, 35.0, x, y, z))
			{
				enemiesCt ++;
			}
		}
	}
	// Inform the player that their backup request is a success
	SendClientMessage(playerid, -1, sprintf("{%s}[HELP] {FFFFFF}You have requested for backup.", (team == ATTACKER) ? ("FF6666" ): ("9999FF")));

	// Get map icon id based off the team which the player is in
	new iconID = (team == DEFENDER) ? DEFENDER_BACKUP_ICON : ATTACKER_BACKUP_ICON;

	// Set map icon for the player in the location where they requested backup
	SetPlayerMapIcon(playerid, iconID, x, y, z, 19, 0, MAPICON_GLOBAL);

	// Create a variable to hold request backup message
	new str[144];

	// Format backup request message to send it later
	format(str, sizeof(str), "{%s}[HELP] %s {FFFFFF}needs backup [Heading %s | HP %d | Enemies: %d]", (team == ATTACKER) ? ("FF6666") : ("9999FF"), Player[playerid][Name], GetCardinalPoint(facingAngle), totHP, enemiesCt);

	// This is for players who use colored markers (via /playermarkers)
	new specialStr[144];

	// Send backup request message to all teammates
	foreach(new i : PlayersInRound)
	{
		if(i == playerid)
			continue;

		if(Player[i][Team] == team)
		{
			if(!Player[i][PlayerMarkers])
				SendClientMessage(i, -1, str);
			else
			{
				format(specialStr, sizeof specialStr, "%s[HELP] %s {FFFFFF}needs backup [Heading %s | HP %d | Enemies: %d]", GetColor(GetPlayerCorrectMarkerCol(playerid, i)), Player[playerid][Name], GetCardinalPoint(facingAngle), totHP, enemiesCt);
				SendClientMessage(i, -1, specialStr);
			}

			PlayerPlaySound(i,1137,0.0,0.0,0.0);
			SetPlayerMapIcon(i, iconID, x, y, z, 19, 0, MAPICON_GLOBAL);
		}
	}

	// Set the player's color
	SetPlayerColor(playerid, team == ATTACKER ? ATTACKER_ASKING_HELP : DEFENDER_ASKING_HELP);

	// Set a timer to end backup request later
	SetTimerEx("EndTeamBackupRequest", 7000, 0, "ii", playerid, iconID);

	// Set values to tell that this team has someone requesting for backup now
	TeamHelp[team] = true;
	Player[playerid][AskingForHelp] = true;

	// Fix the players radar
	RadarFix(playerid);

	// Update the team bar so that its color changes
	UpdatePlayerTeamBar(playerid);
	return 1; // success
}

forward RemoveTeamDeathMapIcon(teamid, iconid);
public RemoveTeamDeathMapIcon(teamid, iconid)
{
	foreach(new i : Player)
	{
		RemovePlayerMapIcon(i, iconid);
	}
	TeamDeathIconTimer[teamid] = -1;
}

CreateTeamDeathMapIcon(teamid, Float:x, Float:y, Float:z)
{
	new iconID = (teamid == DEFENDER) ? DEFENDER_DEATH_ICON : ATTACKER_DEATH_ICON;

	if(TeamDeathIconTimer[teamid] != -1)
		KillTimer(TeamDeathIconTimer[teamid]);

	TeamDeathIconTimer[teamid] = SetTimerEx("RemoveTeamDeathMapIcon", 5000, false, "ii", teamid, iconID);
	foreach(new i : PlayersInRound)
	{
		if(Player[i][Team] == teamid)
		{
			SetPlayerMapIcon(i, iconID, x, y, z, 23, 0, MAPICON_GLOBAL);
		}
	}
}

forward HideHpTextForAtt();
public HideHpTextForAtt() {
	TextDrawSetString(TeamHpLose[0], " ");
	TextDrawSetString(AttHpLose, " ");
	TempDamage[ATTACKER] = 0;
	return 1;
}

forward HideHpTextForDef();
public HideHpTextForDef() {
	TextDrawSetString(TeamHpLose[1], " ");
	TextDrawSetString(DefHpLose, " ");
	TempDamage[DEFENDER] = 0;
	return 1;
}

forward DeathMessageF(killerid, playerid);
public DeathMessageF(killerid, playerid) {
	PlayerTextDrawHide(killerid, DeathText[killerid][0]);
	PlayerTextDrawHide(playerid, DeathText[playerid][1]);
	return 1;
}

forward SwapBothTeams();
public SwapBothTeams() {
    SwapTeams();
	if(PreMatchResultsShowing == false) AllowStartBase = true;
	return 1;
}

forward OnPlayerReplace(ToAddID, ToReplaceID, playerid);
public OnPlayerReplace(ToAddID, ToReplaceID, playerid) {
    new Float:Pos[4], HP[2], iString[180];

	GetPlayerPos(ToReplaceID, Pos[0], Pos[1], Pos[2]);
	GetPlayerFacingAngle(ToReplaceID, Pos[3]);

	GetHP(ToReplaceID, HP[0]);
	GetAP(ToReplaceID, HP[1]);

	new Weapons[13], Ammo[13];
	for(new i = 0; i < 13; i++){
		GetPlayerWeaponData(ToReplaceID, i, Weapons[i], Ammo[i]);
	}

	Player[ToAddID][Playing] = true;
	Player[ToAddID][WasInBase] = true;
	Iter_Add(PlayersInRound, ToAddID);

    Player[ToAddID][Team] = Player[ToReplaceID][Team];
	Player[ToAddID][WasInTeam] = Player[ToAddID][Team];
	SwitchTeamFix(ToAddID, false, false, false);
	
	SetSpawnInfo(ToAddID, Player[ToAddID][Team], Skin[Player[playerid][Team]], Pos[0], Pos[1], Pos[2]+1, Pos[3], 0, 0, 0, 0, 0, 0);
	Player[ToAddID][IgnoreSpawn] = true;
	SpawnPlayer(ToAddID);
	
	SetHP(ToAddID, HP[0]);
	SetAP(ToAddID, HP[1]);

	SetPlayerPos(ToAddID, Pos[0], Pos[1], Pos[2]+1);
	SetPlayerFacingAngle(ToAddID, Pos[3]);
	SetPlayerInterior(ToAddID, GetPlayerInterior(ToReplaceID));
	SetPlayerVirtualWorld(ToAddID, GetPlayerVirtualWorld(ToReplaceID));
	SetPlayerTeam(ToAddID, Player[ToAddID][Team]);

	ColorFix(ToAddID);


	for(new i = 0; i < 13; i++) {
		GivePlayerWeapon(ToAddID, Weapons[i], Ammo[i]);
    }

	if(Player[ToReplaceID][WeaponPicked] > 0) {
 		Player[ToAddID][WeaponPicked] = Player[ToReplaceID][WeaponPicked];
 		Player[ToReplaceID][WeaponPicked] = 0;
	}

	RemovePlayerFromRound(ToReplaceID);

    if(GameType == BASE)
	{
		SetCPForPlayer(ToAddID);
	}

	CreatePlayerTeamBar(ToAddID);
	ShowTeamBarsForPlayer(ToAddID);
	
	ShowTeamCornerInfo(ToAddID);
	UpdateTeamCornerInfo();
	
	UpdateTeamPlayerCount(Player[ToAddID][Team], false);

	if(RoundPaused == true) {
		TogglePlayerControllable(ToAddID, 0);
		TextDrawShowForAll(PauseTD);
	}

    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has replaced {FFFFFF}%s "COL_PRIM"by {FFFFFF}%s", Player[playerid][Name], Player[ToReplaceID][Name], Player[ToAddID][Name]);
	SendClientMessageToAll(-1, iString);

	UpdateRoundKillDmgTDmg(ToAddID);

    RadarFix();
    return 1;
}

forward OnPlayerInGameReplace(ToAddID, i, playerid);
public OnPlayerInGameReplace(ToAddID, i, playerid) {
	Player[ToAddID][Playing] = true;
	Player[ToAddID][WasInBase] = true;
	Iter_Add(PlayersInRound, ToAddID);

    Player[ToAddID][Team] = SaveVariables[i][pTeam];
	Player[playerid][WasInTeam] = Player[ToAddID][Team];
	SwitchTeamFix(ToAddID, false, false, false);
	
    if(SaveVariables[i][WasCrashedInStart] == false) {
		SetSpawnInfo(ToAddID, Player[ToAddID][Team], Skin[Player[playerid][Team]], SaveVariables[i][pCoords][0], SaveVariables[i][pCoords][1], SaveVariables[i][pCoords][2]+1, SaveVariables[i][pCoords][3], 0, 0, 0, 0, 0, 0);
		
		SetPlayerInterior(ToAddID, SaveVariables[i][pInterior]);
		SetPlayerVirtualWorld(ToAddID, SaveVariables[i][pVWorld]);
	} else if(Current != -1) {
	    if(GameType == BASE) {
			switch(Player[ToAddID][Team]) {
				case ATTACKER: SetSpawnInfo(ToAddID, Player[ToAddID][Team], Skin[Player[playerid][Team]], BAttackerSpawn[Current][0] + random(6), BAttackerSpawn[Current][1] + random(6), BAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
				case DEFENDER: SetSpawnInfo(ToAddID, Player[ToAddID][Team], Skin[Player[playerid][Team]], BDefenderSpawn[Current][0] + random(6), BDefenderSpawn[Current][1] + random(6), BDefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
		    }
		    SetPlayerInterior(ToAddID, BInterior[Current]);
		} else if(GameType == ARENA) {
			switch(Player[ToAddID][Team]) {
				case ATTACKER: SetSpawnInfo(ToAddID, Player[ToAddID][Team], Skin[Player[playerid][Team]],AAttackerSpawn[Current][0] + random(6), AAttackerSpawn[Current][1] + random(6), AAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
				case DEFENDER: SetSpawnInfo(ToAddID, Player[ToAddID][Team], Skin[Player[playerid][Team]],ADefenderSpawn[Current][0] + random(6), ADefenderSpawn[Current][1] + random(6), ADefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
			}
		    SetPlayerInterior(ToAddID, AInterior[Current]);
		}
		SetPlayerVirtualWorld(ToAddID, 2);
	}
	
	Player[ToAddID][IgnoreSpawn] = true;
	SpawnPlayer(ToAddID);
	
	SetHP(ToAddID, SaveVariables[i][gHealth]);
	SetAP(ToAddID, SaveVariables[i][gArmour]);

	SetPlayerTeam(ToAddID, Player[ToAddID][Team]);

	ColorFix(ToAddID);
	SetCPForPlayer(ToAddID);

	ShowPlayerGunmenu(ToAddID, 500);

	CreatePlayerTeamBar(ToAddID);
	ShowTeamBarsForPlayer(ToAddID);
	
	ShowTeamCornerInfo(ToAddID);
	UpdateTeamCornerInfo();

	UpdateTeamPlayerCount(Player[ToAddID][Team], false);

    SaveVariables[i][ToBeAdded] = false;

	new iString[160];

	if(RoundPaused == true) {
		TogglePlayerControllable(ToAddID, 0);
		TextDrawShowForAll(PauseTD);
	}
    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has replaced {FFFFFF}%s "COL_PRIM"by {FFFFFF}%s", Player[playerid][Name], SaveVariables[i][pName], Player[ToAddID][Name]);
	SendClientMessageToAll(-1, iString);

    UpdateRoundKillDmgTDmg(ToAddID);

    RadarFix();
    return 1;
}

/* Note:
	set remove_iterator to false if you're using this in a loop
	and safely remove, for example

	foreach(new i : PlayersInRound)
	{
		RemovePlayerFromRound(i, false);
		Iter_SafeRemove(PlayersInRound, i, i);
	}
*/
RemovePlayerFromRound(playerid, bool:remove_iterator = true)
{
	Player[playerid][Playing] = false;
	if(remove_iterator)
		Iter_Remove(PlayersInRound, playerid);

	if(Current != -1)
	{
	    OnPlayerLeaveCheckpoint(playerid);
	}
	Player[playerid][WasInBase] = false;
	Player[playerid][WasInTeam] = NON;
	Player[playerid][ToAddInRound] = false;
	TogglePlayerControllable(playerid, 1);
	RemovePlayerMapIcon(playerid, 59);
	
	DeletePlayerTeamBar(playerid);
	HideAllTeamBarsForPlayer(playerid);
	
	HideTeamCornerInfo(playerid);
	UpdateTeamCornerInfo();
	
	UpdateTeamPlayerCount(Player[playerid][Team], true, playerid);
	UpdateTeamHP(Player[playerid][Team], playerid);

	#if defined _league_included
	if(LeagueAllowed)
	{
		CheckLeagueMatchValidity(1000);
	}
	#endif

	DisablePlayerCheckpoint(playerid);
	SetPlayerScore(playerid, 0);
	HideDialogs(playerid);

	PlayerTextDrawHide(playerid, AreaCheckTD[playerid]);
	PlayerTextDrawHide(playerid, AreaCheckBG[playerid]);

	ResetPlayerGunmenu(playerid, false);
	PlayerNoLeadTeam(playerid);

	SpawnInLobby(playerid);
	return 1;
}

ResetPlayerRoundVariables(playerid, bool:total = false)
{
	switch(total)
	{
		case false:
		{
			Player[playerid][RoundKills] = 0;
			Player[playerid][RoundDeaths] = 0;
			Player[playerid][RoundDamage] = 0;
			Player[playerid][shotsHit] = 0;
		}
		case true:
		{
			Player[playerid][TotalKills] = 0;
			Player[playerid][TotalDeaths] = 0;
			Player[playerid][TotalDamage] = 0;
			Player[playerid][RoundPlayed] = 0;
		    Player[playerid][TotalBulletsFired] = 0;
		    Player[playerid][TotalshotsHit] = 0;
		}
	}
}

ResetRoundVariablesInSlots()
{
    for(new i = 0; i < SAVE_SLOTS; i ++)
	{
	   	if(strlen(SaveVariables[i][pName]) >= 2) 
		{
	   	    SaveVariables[i][RKills]   	=  	0;
			SaveVariables[i][RDeaths]  	= 	0;
			SaveVariables[i][RDamage] 	= 	0;
			SaveVariables[i][sWasInBase] =  false;
		}
	}
}

forward ShowPlayingPlayersGunmenu();
public ShowPlayingPlayersGunmenu()
{
	foreach(new i : PlayersInRound)
	{
		ShowPlayerGunmenu(i, 0);
	}
}

//------------------------------------------------------------------------------
// Arena System
//------------------------------------------------------------------------------

forward OnRCStart();
public OnRCStart()
{
	AutoAFKCheck(); // Checks all players and set idle players to afk mode
	RCArena = true;
	new ArenaID = 72; // That's the ID of the RC arena (interior)
	ClearKillList(); // Clears the kill-list.
    DestroyDynamicVehicles(1); // Destroys vehicles
	DeleteAllDeadBodies();
	GameType = ARENA;
	Current = ArenaID; // Current will be the ID of the base that we just started. We do this so that we can use this ID later on (e.g. check /car command for the use).
    ClearKillList(); // Clears the kill-list.
    ServerLastPlayed = Current;
    ServerLastPlayedType = 0;
	TotalPausesInRound = 0;

	ElapsedTime = 0;

	TeamCapturingCP = NON;
	PlayersInCP = 0;
 	ElapsedTime = 0;
	CurrentCPTime = ConfigCPTime + 1;
	TextDrawColor(timerCircleTD, 0x00000033);
	TextDrawSetString(AttDef_RoundStats, "_");
	TextDrawSetString(AttDef_RoundTimer, "_");
	foreach(new i : Player)
	{
		if(!Player[i][Spawned])
			continue;

		if(Player[i][RoundTDStyle] != 1)
	        continue;

		if(Player[i][RoundTDStyle] != 1)
			continue;

		TextDrawShowForPlayer(i, timerCircleTD);
	}

	ResetGunmenuSelections();

    new iString[32];
	format(iString, sizeof(iString), "%sRC BF %s(~r~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, Current, MAIN_TEXT_COLOUR);
	TextDrawSetString( leftTeamData, "_");
	TextDrawSetString( rightTeamData, "_");
	TextDrawSetString( centerTeamNames, "_");
	TextDrawSetString( timerCenterTD, "_");

	CPZone = GangZoneCreate(ACPSpawn[Current][0]-50, ACPSpawn[Current][1]-50, ACPSpawn[Current][0]+50, ACPSpawn[Current][1]+50);
	GangZoneShowForAll(CPZone, 0xFF000044);

	foreach(new i : Player)
	{
	    Player[i][LastVehicle] = -1;
		Player[i][WasInCP] = false;

		ShowRoundStats(i);


	    if(Player[i][ToAddInRound] == true)
		{
            HideEndRoundTextDraw(i);

			if(Player[i][Spectating] == true) StopSpectate(i);

			if(Player[i][InDM] == true) { //Make sure to remove player from DM, otherwise the player will have Player[playerid][Playing] = true and Player[playerid][InDM] = true, so you are saying that the player is both in Base and in DM.
			    Player[i][InDM] = false;
    			Player[i][DMReadd] = 0;
			}

	        SetPlayerVirtualWorld(i, 2); //Set player virtual world to something different that that for lobby and DM so that they don't collide with each other. e.g. You shouldn't be able to see players in lobby or DM while you are in base.
			TogglePlayerControllable(i, 0); //Pause players.

			SetPlayerInterior(i, AInterior[Current]);
			SetPlayerCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2]);
			SetPlayerCameraPos(i,ACPSpawn[Current][0]+100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80);
			SetPlayerPos(i, ACPSpawn[Current][0], ACPSpawn[Current][1], ACPSpawn[Current][2]);
		}
		PlayerTextDrawSetString(i, BaseID_VS[i], iString);
	}

	ArenaZone = GangZoneCreate(AMin[Current][0],AMin[Current][1],AMax[Current][0],AMax[Current][1]);
	format(iString, sizeof(iString), "mapname RC: %d", Current);
	SendRconCommand(iString);

	GangZoneShowForAll(ArenaZone,0x95000099);

	ViewTimer = 4;
	ViewRCForPlayers();

	format(iString, sizeof(iString), "%s: %d - %s: %d", TeamName[ATTACKER], TeamScore[ATTACKER], TeamName[DEFENDER], TeamScore[DEFENDER]);
	SetGameModeText(iString);

	if( WarMode == true )
	{
	    MatchRoundsStarted++;
	    if( MatchRoundsStarted > 100 ) MatchRoundsStarted = 1;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__type ] = 1;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__ID ] = ArenaID;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__completed ] = false;
	}
}

forward ViewRCForPlayers();
public ViewRCForPlayers()
{
	if(ViewTimer == 0)
	{
	    SpawnPlayersInRC();
	    ResetTeamLeaders();
		TextDrawSetString(centerTeamNames, " ");
	    return 1;
	}

	new iString[64];
	format(iString,sizeof(iString),"~w~RC starting in ~r~~h~%d ~w~seconds", ViewTimer);
	TextDrawSetString( centerTeamNames, iString);
	foreach(new i : Player) {
	    if(Player[i][ToAddInRound] == true) {
	        PlayerPlaySound(i,1139,0.0,0.0,0.0);
			switch(ViewTimer)
			{
			    case 4: {
					SetPlayerCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2]);
	    	   		SetPlayerCameraPos(i,ACPSpawn[Current][0],ACPSpawn[Current][1]+100,ACPSpawn[Current][2]+80);
    			} case 3: {
         			InterpolateCameraPos(i,ACPSpawn[Current][0],ACPSpawn[Current][1]+100,ACPSpawn[Current][2]+80, ACPSpawn[Current][0]-100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], 1000, CAMERA_MOVE);
		   		} case 2: {
	    	   		InterpolateCameraPos(i,ACPSpawn[Current][0]-100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80, ACPSpawn[Current][0],ACPSpawn[Current][1]-100,ACPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], 1000, CAMERA_MOVE);
				} case 1: {
					InterpolateCameraPos(i,ACPSpawn[Current][0],ACPSpawn[Current][1]-100,ACPSpawn[Current][2]+80,ACPSpawn[Current][0]+100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], 1000, CAMERA_MOVE);
				}
			}
		}
	}
	ViewTimer--;
	return SetTimer("ViewRCForPlayers", 1000, false);
}

SpawnPlayersInRC()
{
	ClearChat();
	SendClientMessageToAll(-1, sprintf(""COL_PRIM"RC Battlefield started: {FFFFFF}%s (ID: %d)", AName[Current], Current));
	foreach(new i : Player)
	{
	    if(Player[i][ToAddInRound] == true)
		{
	        if(Player[i][Spectating] == true) StopSpectate(i);

			if(!Player[i][FakePacketRenovation] && Player[i][NetCheck] && NetStats_GetConnectedTime(i) < 300000)
			{
				SetTimerEx("FakePacketRenovationEnd", 30000, false, "ifb", i, NetStats_PacketLossPercent(i), false);
				Player[i][FakePacketRenovation] = true;
			}

	        Player[i][Playing] = true;
	        Player[i][WasInBase] = true;
			Player[i][WasInTeam] = Player[i][Team];
			Iter_Add(PlayersInRound, i);

			ResetPlayerRoundVariables(i);

			PlayerPlaySound(i, 1057, 0, 0, 0);
	        SetPlayerVirtualWorld(i, 2);
	        SetPlayerInterior(i, AInterior[Current]);

			SetAP(i, RoundAR);
			SetHP(i, RoundHP);
			
			CreatePlayerTeamBar(i);
			
			ShowTeamCornerInfo(i);

			switch(Player[i][Team]) {
			    case ATTACKER: {
       				if(AInterior[Current] == 0) SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], AAttackerSpawn[Current][0] + random(6), AAttackerSpawn[Current][1] + random(6), AAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
					else SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], AAttackerSpawn[Current][0] + random(2), AAttackerSpawn[Current][1] + random(2), AAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);

			        SetPlayerColor(i, ATTACKER_PLAYING);
			        SpawnPlayer(i);
                    SetPlayerTeam(i, 1);
					
                    ShowTeamBarsForPlayer(i);
				} case DEFENDER: {
				    if(AInterior[Current] == 0) SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], ADefenderSpawn[Current][0] + random(6), ADefenderSpawn[Current][1] + random(6), ADefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
        			else SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], ADefenderSpawn[Current][0] + random(2), ADefenderSpawn[Current][1] + random(2), ADefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);

					SetPlayerColor(i, DEFENDER_PLAYING);
					SpawnPlayer(i);
					SetPlayerTeam(i, 2);
					
			        ShowTeamBarsForPlayer(i);
				}
			}
            SetCameraBehindPlayer(i);
			if(RoundPaused == false) TogglePlayerControllable(i, 1);
			else TogglePlayerControllable(i, 0);
            Player[i][ToAddInRound] = false;

			UpdateRoundKillDmgTDmg(i);
		}
	}
	
	UpdateTeamCornerInfo();

	RoundMints = ConfigRoundTime;
	RoundSeconds = 0;

	if(CheckTeamElimination() != 0)
	{
		foreach(new i:Player)
		{
			ShowRoundStats(i);
		}
		AllowStartBase = true;
		ArenaStarted = true;
		UpdateTeamPlayerCount(ATTACKER, false);
		UpdateTeamPlayerCount(DEFENDER, false);
		UpdateTeamHP(ATTACKER);
		UpdateTeamHP(DEFENDER);
		UpdateTeamNamesTextdraw();
		StartGameLoop();
		FallProtection = true;
		RadarFix();
		foreach(new i : PlayersInRound)
		{
			ResetPlayerWeapons(i);
			GivePlayerWeapon(i, WEAPON_M4, 9999);
			GivePlayerWeapon(i, WEAPON_SHOTGSPA, 9999);
			GivePlayerWeapon(i, WEAPON_DEAGLE, 9999);
		}
		#if defined _league_included
		if(LeagueAllowed)
		{
			CheckLeagueMatchValidity(1000);
		}
		#endif
	}
}

forward OnArenaStart(ArenaID);
public OnArenaStart(ArenaID)
{
	AutoAFKCheck(); // Checks all players and set idle players to afk mode
    ClearKillList(); // Clears the kill-list.
    DestroyDynamicVehicles(1); // Destroys vehicles
	DeleteAllDeadBodies();
	GameType = ARENA;
	RCArena = false;
	Current = ArenaID; // Current will be the ID of the base that we just started. We do this so that we can use this ID later on (e.g. check /car command for the use).
    ClearKillList(); // Clears the kill-list.
    ServerLastPlayed = Current;
    ServerLastPlayedType = 0;
	TotalPausesInRound = 0;

	ElapsedTime = 0;

	TeamCapturingCP = NON;
	PlayersInCP = 0;
 	ElapsedTime = 0;
	CurrentCPTime = ConfigCPTime + 1;
	TextDrawColor(timerCircleTD, 0x00000033);
	TextDrawSetString(AttDef_RoundStats, "_");
	TextDrawSetString(AttDef_RoundTimer, "_");
	foreach(new i : Player)
	{
		if(!Player[i][Spawned])
			continue;

		if(Player[i][RoundTDStyle] != 1)
	        continue;

		TextDrawShowForPlayer(i, timerCircleTD);
	}

	ResetGunmenuSelections();

    new iString[32];
	format(iString, sizeof(iString), "%sArena %s(~r~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, Current, MAIN_TEXT_COLOUR);
	TextDrawSetString( leftTeamData, "_");
	TextDrawSetString( rightTeamData, "_");
	TextDrawSetString( centerTeamNames, "_");
	TextDrawSetString( timerCenterTD, "_");

	foreach(new i : Player)
	{
	    Player[i][LastVehicle] = -1;
		Player[i][WasInCP] = false;

		ShowRoundStats(i);


	    if(Player[i][ToAddInRound] == true)
		{
            HideEndRoundTextDraw(i);

			if(Player[i][Spectating] == true) StopSpectate(i);

			if(Player[i][InDM] == true) { //Make sure to remove player from DM, otherwise the player will have Player[playerid][Playing] = true and Player[playerid][InDM] = true, so you are saying that the player is both in Base and in DM.
			    Player[i][InDM] = false;
    			Player[i][DMReadd] = 0;
			}

	        SetPlayerVirtualWorld(i, 2); //Set player virtual world to something different that that for lobby and DM so that they don't collide with each other. e.g. You shouldn't be able to see players in lobby or DM while you are in base.
			TogglePlayerControllable(i, 0); //Pause players.

			SetPlayerInterior(i, AInterior[Current]);
			SetPlayerCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2]);
			SetPlayerCameraPos(i,ACPSpawn[Current][0]+100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80);
			SetPlayerPos(i, ACPSpawn[Current][0], ACPSpawn[Current][1], ACPSpawn[Current][2]);
			SetCPForPlayer(i);
		}
		PlayerTextDrawSetString(i, BaseID_VS[i], iString);
	}

	ArenaZone = GangZoneCreate(AMin[Current][0],AMin[Current][1],AMax[Current][0],AMax[Current][1]);
	format(iString, sizeof(iString), "mapname Arena: %d", Current);
	SendRconCommand(iString);

	GangZoneShowForAll(ArenaZone,0x95000099);

	ViewTimer = 4;
	ViewArenaForPlayers();

	format(iString, sizeof(iString), "%s: %d - %s: %d", TeamName[ATTACKER], TeamScore[ATTACKER], TeamName[DEFENDER], TeamScore[DEFENDER]);
	SetGameModeText(iString);

	if( WarMode == true )
	{
	    MatchRoundsStarted++;
	    if( MatchRoundsStarted > 100 ) MatchRoundsStarted = 1;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__type ] = 1;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__ID ] = ArenaID;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__completed ] = false;
	}
    return 1;
}

forward ViewArenaForPlayers();
public ViewArenaForPlayers()
{
	if(ViewTimer == 0)
	{
	    SpawnPlayersInArena();
	    ResetTeamLeaders();
		TextDrawSetString(centerTeamNames, " ");
	    return 1;
	}

	new iString[64];
	format(iString,sizeof(iString),"~w~Arena starting in ~r~~h~%d ~w~seconds", ViewTimer);
	TextDrawSetString( centerTeamNames, iString);
	foreach(new i : Player) {
	    if(Player[i][ToAddInRound] == true) {
	        PlayerPlaySound(i,1139,0.0,0.0,0.0);
			switch(ViewTimer)
			{
			    case 4: {
					SetPlayerCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2]);
	    	   		SetPlayerCameraPos(i,ACPSpawn[Current][0],ACPSpawn[Current][1]+100,ACPSpawn[Current][2]+80);
    			} case 3: {
         			InterpolateCameraPos(i,ACPSpawn[Current][0],ACPSpawn[Current][1]+100,ACPSpawn[Current][2]+80, ACPSpawn[Current][0]-100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], 1000, CAMERA_MOVE);
		   		} case 2: {
	    	   		InterpolateCameraPos(i,ACPSpawn[Current][0]-100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80, ACPSpawn[Current][0],ACPSpawn[Current][1]-100,ACPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], 1000, CAMERA_MOVE);
				} case 1: {
					InterpolateCameraPos(i,ACPSpawn[Current][0],ACPSpawn[Current][1]-100,ACPSpawn[Current][2]+80,ACPSpawn[Current][0]+100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], 1000, CAMERA_MOVE);
				}
			}
		}
	}
	ViewTimer--;
	return SetTimer("ViewArenaForPlayers", 1000, false);
}

SpawnPlayersInArena()
{
	ClearChat();
	SendClientMessageToAll(-1, sprintf(""COL_PRIM"Arena has completely started: {FFFFFF}%s (ID: %d)", AName[Current], Current));
	foreach(new i : Player)
	{
	    if(Player[i][ToAddInRound] == true)
		{
	        if(Player[i][Spectating] == true) StopSpectate(i);

			if(!Player[i][FakePacketRenovation] && Player[i][NetCheck] && NetStats_GetConnectedTime(i) < 300000)
			{
				SetTimerEx("FakePacketRenovationEnd", 30000, false, "ifb", i, NetStats_PacketLossPercent(i), false);
				Player[i][FakePacketRenovation] = true;
			}

	        Player[i][Playing] = true;
	        Player[i][WasInBase] = true;
			Player[i][WasInTeam] = Player[i][Team];
			Iter_Add(PlayersInRound, i);

			ResetPlayerRoundVariables(i);

			PlayerPlaySound(i, 1057, 0, 0, 0);
	        SetPlayerVirtualWorld(i, 2);
	        SetPlayerInterior(i, AInterior[Current]);

			SetAP(i, RoundAR);
			SetHP(i, RoundHP);
			
			CreatePlayerTeamBar(i);
			
			ShowTeamCornerInfo(i);

			SetCPForPlayer(i);

			switch(Player[i][Team]) {
			    case ATTACKER: {
       				if(AInterior[Current] == 0) SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], AAttackerSpawn[Current][0] + random(6), AAttackerSpawn[Current][1] + random(6), AAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
					else SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], AAttackerSpawn[Current][0] + random(2), AAttackerSpawn[Current][1] + random(2), AAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);

			        SetPlayerColor(i, ATTACKER_PLAYING);
			        SpawnPlayer(i);
                    SetPlayerTeam(i, 1);
					
                    ShowTeamBarsForPlayer(i);
					
					if(IsACPluginLoaded() && IsACEnabled())
						TogglePlayerVehicleBlips(i, true);
				} case DEFENDER: {
				    if(AInterior[Current] == 0) SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], ADefenderSpawn[Current][0] + random(6), ADefenderSpawn[Current][1] + random(6), ADefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
        			else SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], ADefenderSpawn[Current][0] + random(2), ADefenderSpawn[Current][1] + random(2), ADefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);

					SetPlayerColor(i, DEFENDER_PLAYING);
					SpawnPlayer(i);
					SetPlayerTeam(i, 2);
					
			        ShowTeamBarsForPlayer(i);

					if(IsACPluginLoaded() && IsACEnabled())
						TogglePlayerVehicleBlips(i, DefendersSeeVehiclesBlips);
				}
			}
            SetCameraBehindPlayer(i);
			if(RoundPaused == false) TogglePlayerControllable(i, 1);
			else TogglePlayerControllable(i, 0);
            Player[i][ToAddInRound] = false;

			UpdateRoundKillDmgTDmg(i);
		}
	}
	ResetRoundVariablesInSlots();
	
	UpdateTeamCornerInfo();

	RoundMints = ConfigRoundTime;
	RoundSeconds = 0;

	if(CheckTeamElimination() != 0)
	{
		foreach(new i:Player)
		{
			ShowRoundStats(i);
		}
		AllowStartBase = true;
		ArenaStarted = true;
		UpdateTeamPlayerCount(ATTACKER, false);
		UpdateTeamPlayerCount(DEFENDER, false);
		UpdateTeamHP(ATTACKER);
		UpdateTeamHP(DEFENDER);
		UpdateTeamNamesTextdraw();
		StartGameLoop();
		FallProtection = true;
		RadarFix();
		#if defined _league_included
		if(LeagueAllowed)
		{
			CheckLeagueMatchValidity(1000);
		}
		#endif
		SetTimer("ShowPlayingPlayersGunmenu", 1000, false);
	}
}

forward AddPlayerToArena(playerid);
public AddPlayerToArena(playerid)
{
	if(Player[playerid][Spectating] == true) {
		StopSpectate(playerid);
		SetTimerEx("AddPlayerToArena", 500, false, "i", playerid);
		return 1;
	}

	if(Player[playerid][InDM] == true) { //Make sure to remove player from DM, otherwise the player will have Player[playerid][Playing] = true and Player[playerid][InDM] = true, so you are saying that the player is both in Base and in DM.
	    Player[playerid][InDM] = false;
		Player[playerid][DMReadd] = 0;
	}

	if(Player[playerid][LastVehicle] != -1) {
		DestroyVehicle(Player[playerid][LastVehicle]);
		Player[playerid][LastVehicle] = -1;
	}

	if(!Player[playerid][FakePacketRenovation] && Player[playerid][NetCheck] && NetStats_GetConnectedTime(playerid) < 300000)
	{
		SetTimerEx("FakePacketRenovationEnd", 30000, false, "ifb", playerid, NetStats_PacketLossPercent(playerid), false);
		Player[playerid][FakePacketRenovation] = true;
	}

    Player[playerid][Playing] = true;
    Player[playerid][WasInBase] = true;
	Player[playerid][WasInTeam] = Player[playerid][Team];
	Iter_Add(PlayersInRound, playerid);
	UpdateTeamPlayerCount(Player[playerid][Team], false);
    Player[playerid][ToAddInRound] = false;
	ResetPlayerRoundVariables(playerid);

	PlayerPlaySound(playerid, 1057, 0, 0, 0);
	SetCameraBehindPlayer(playerid);

	SetAP(playerid, RoundAR);
	SetHP(playerid, RoundHP);
	
	CreatePlayerTeamBar(playerid);
	
	ShowTeamCornerInfo(playerid);
	UpdateTeamCornerInfo();
	
	SetPlayerVirtualWorld(playerid, 2);
	SetPlayerInterior(playerid, AInterior[Current]);
	if(!RCArena)
		SetCPForPlayer(playerid);

	switch(Player[playerid][Team]) {
	    case ATTACKER: {
	        SetSpawnInfo(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], AAttackerSpawn[Current][0] + random(2), AAttackerSpawn[Current][1] + random(2), AAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
			SetPlayerMapIcon(playerid, 59, AAttackerSpawn[Current][0], AAttackerSpawn[Current][1], AAttackerSpawn[Current][2], 59, 0, MAPICON_GLOBAL);

			SpawnPlayer(playerid);
	        SetPlayerColor(playerid, ATTACKER_PLAYING);

            SetPlayerTeam(playerid, 1);
			
            ShowTeamBarsForPlayer(playerid);
			
			if(IsACPluginLoaded() && IsACEnabled())
				TogglePlayerVehicleBlips(playerid, true);
		} case DEFENDER: {
		    SetSpawnInfo(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], ADefenderSpawn[Current][0] + random(2), ADefenderSpawn[Current][1] + random(2), ADefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);

			SpawnPlayer(playerid);
	        SetPlayerColor(playerid, DEFENDER_PLAYING);
	        SetPlayerTeam(playerid, 2);
			
	        ShowTeamBarsForPlayer(playerid);
			
			if(IsACPluginLoaded() && IsACEnabled())
				TogglePlayerVehicleBlips(playerid, DefendersSeeVehiclesBlips);
		} case REFEREE: {
	        SetSpawnInfo(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], ACPSpawn[Current][0] + random(2), ACPSpawn[Current][1] + random(2), ACPSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
			SpawnPlayer(playerid);
	        SetPlayerColor(playerid, REFEREE_COLOR);
	        SetPlayerTeam(playerid, 3);
		}
	}

	#if defined _league_included
	if(LeagueAllowed)
	{
		CheckLeagueMatchValidity(1000);
	}
	#endif

	if(RoundPaused == false) TogglePlayerControllable(playerid, 1);
	else TogglePlayerControllable(playerid, 0);

	if(!RCArena)
		ShowPlayerGunmenu(playerid, 500);
	else
	{
		ResetPlayerWeapons(playerid);
		GivePlayerWeapon(playerid, WEAPON_M4, 9999);
		GivePlayerWeapon(playerid, WEAPON_SHOTGSPA, 9999);
		GivePlayerWeapon(playerid, WEAPON_DEAGLE, 9999);
	}


	UpdateRoundKillDmgTDmg(playerid);

	RadarFix();
	return 1;
}

//------------------------------------------------------------------------------
// Base System
//------------------------------------------------------------------------------

forward OnBaseStart(BaseID);
public OnBaseStart(BaseID)
{
	AutoAFKCheck(); // Checks all players and set idle players to afk mode
	ClearKillList(); // Clears the kill-list.
    DestroyDynamicVehicles(1); // Destroys vehicles
	DeleteAllDeadBodies();
	GameType = BASE;
	RCArena = false;
	Current = BaseID; // Current will be the ID of the base that we just started. We do this so that we can use this ID later on (e.g. check /car command for the use).
   	ClearKillList(); // Clears the kill-list.
    ServerLastPlayed = Current;
    ServerLastPlayedType = 1;
	TotalPausesInRound = 0;

	TeamCapturingCP = NON;
	PlayersInCP = 0;
 	ElapsedTime = 0;
	CurrentCPTime = ConfigCPTime + 1;
	TextDrawColor(timerCircleTD, 0x00000033);
	TextDrawSetString(AttDef_RoundStats, "_");
	TextDrawSetString(AttDef_RoundTimer, "_");
	foreach(new i : Player)
	{
		if(!Player[i][Spawned])
			continue;

		if(Player[i][RoundTDStyle] != 1)
			continue;

		TextDrawShowForPlayer(i, timerCircleTD);
	}

	ResetGunmenuSelections();

    new iString[32];
	format(iString, sizeof(iString), "%sBase %s(~r~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, Current, MAIN_TEXT_COLOUR);

	TextDrawSetString( leftTeamData, "_");
	TextDrawSetString( rightTeamData, "_");
	TextDrawSetString( centerTeamNames, "_");
	TextDrawSetString( timerCenterTD, "_");

	ViewBaseCamPos[0] = BCPSpawn[Current][0];
	ViewBaseCamPos[1] = BCPSpawn[Current][1];
	ViewBaseCamPos[2] = BCPSpawn[Current][2];
	ViewTimer = 9;

	CPZone = GangZoneCreate(BCPSpawn[Current][0]-50, BCPSpawn[Current][1]-50, BCPSpawn[Current][0]+50, BCPSpawn[Current][1]+50);
	GangZoneShowForAll(CPZone, 0xFF000044);

	foreach(new i : Player) {
		Player[i][LastVehicle] = -1;

		ShowRoundStats(i);
		Player[i][WasInCP] = false;

	    if(Player[i][ToAddInRound] == true) {

			if(Player[i][Team] != ATTACKER && Player[i][Team] != DEFENDER && Player[i][Team] != REFEREE)
			{
			    Player[i][ToAddInRound] = false;
			    continue;
	        }
            HideEndRoundTextDraw(i);

			if(Player[i][Spectating] == true) StopSpectate(i);
			if(Player[i][InDM] == true) { // Make sure to remove player from DM, otherwise the player will have Player[playerid][Playing] = true and Player[playerid][InDM] = true, so you are saying that the player is both in Base and in DM.
			    Player[i][InDM] = false;
    			Player[i][DMReadd] = 0;
			}

			Player[i][Playing] = true;
			Iter_Add(PlayersInRound, i);

	        SetPlayerVirtualWorld(i, 2); // Set player virtual world to something different that that for lobby and DM so that they don't collide with each other. e.g. You shouldn't be able to see players in lobby or DM while you are in base.
	        SetPlayerInterior(i, BInterior[Current]);
			TogglePlayerControllable(i, 0); //Pause players.
			SetPlayerCameraLookAt(i,BCPSpawn[Current][0],BCPSpawn[Current][1],BCPSpawn[Current][2]);
			SetPlayerCameraPos(i,BCPSpawn[Current][0],BCPSpawn[Current][1],BCPSpawn[Current][2]);
			SetPlayerPos(i, BCPSpawn[Current][0]+10, BCPSpawn[Current][1]+10, BCPSpawn[Current][2]);
			SetCPForPlayer(i); // Set checkpoint location and size.
		}
		PlayerTextDrawSetString(i, BaseID_VS[i], iString);
	}
	ViewBaseForPlayers();

	format(iString, sizeof(iString), "mapname Base: %d", Current); //Will change the map name in samp.exe to your base id (e.g. Base: 4)
	SendRconCommand(iString);

	format(iString, sizeof(iString), "%s: %d - %s: %d", TeamName[ATTACKER], TeamScore[ATTACKER], TeamName[DEFENDER], TeamScore[DEFENDER]);
	SetGameModeText(iString);

	if( WarMode == true )
	{
	    MatchRoundsStarted++;
	    if( MatchRoundsStarted > 100 ) MatchRoundsStarted = 1;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__type ] = 0;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__ID ] = BaseID;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__completed ] = false;
	}
    return 1;
}

forward ViewBaseForPlayers();
public ViewBaseForPlayers()
{
	if(Current == -1)
		return 1;

	if(ViewTimer == 0)
	{
	    SpawnPlayersInBase();
	    ResetTeamLeaders();
		TextDrawSetString(centerTeamNames, " ");
	    return 1;
	}

	new Float:LastCamPos[3];

	switch(ViewTimer)
	{
		case 9:
		{
			LastCamPos[0] = ViewBaseCamPos[0];
			LastCamPos[1] = ViewBaseCamPos[1];
			LastCamPos[2] = ViewBaseCamPos[2];
			ViewBaseCamPos[0] = BCPSpawn[Current][0] + 50.0;
			ViewBaseCamPos[1] = BCPSpawn[Current][1] - 20.0;
			ViewBaseCamPos[2] = BCPSpawn[Current][2] + 70.0;

			foreach(new i : Player)
			{
				if(Player[i][ToAddInRound] == true)
				{
					PlayerPlaySound(i,1139,0.0,0.0,0.0);
					InterpolateCameraPos(i, LastCamPos[0], LastCamPos[1], LastCamPos[2], ViewBaseCamPos[0], ViewBaseCamPos[1], ViewBaseCamPos[2], 3000, CAMERA_MOVE);
					InterpolateCameraLookAt(i, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 3000, CAMERA_MOVE);
				}
			}
		}
		case 6:
		{
			LastCamPos[0] = ViewBaseCamPos[0];
			LastCamPos[1] = ViewBaseCamPos[1];
			LastCamPos[2] = ViewBaseCamPos[2];
			ViewBaseCamPos[0] = BCPSpawn[Current][0] - 20.0;
			ViewBaseCamPos[1] = BCPSpawn[Current][1] + 50.0;
			ViewBaseCamPos[2] = BCPSpawn[Current][2] + 15.0;

			foreach(new i : Player)
			{
				if(Player[i][ToAddInRound] == true)
				{
					PlayerPlaySound(i,1139,0.0,0.0,0.0);
					InterpolateCameraPos(i, LastCamPos[0], LastCamPos[1], LastCamPos[2], ViewBaseCamPos[0], ViewBaseCamPos[1], ViewBaseCamPos[2], 3000, CAMERA_MOVE);
					InterpolateCameraLookAt(i, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 3000, CAMERA_MOVE);
				}
			}
		}
		case 3:
		{
			LastCamPos[0] = ViewBaseCamPos[0];
			LastCamPos[1] = ViewBaseCamPos[1];
			LastCamPos[2] = ViewBaseCamPos[2];
			ViewBaseCamPos[0] = BCPSpawn[Current][0] + 5.0;
			ViewBaseCamPos[1] = BCPSpawn[Current][1] - 5.0;
			ViewBaseCamPos[2] = BCPSpawn[Current][2] + 3.0;

			foreach(new i : Player)
			{
				if(Player[i][ToAddInRound] == true)
				{
					PlayerPlaySound(i,1139,0.0,0.0,0.0);
					InterpolateCameraPos(i, LastCamPos[0], LastCamPos[1], LastCamPos[2], ViewBaseCamPos[0], ViewBaseCamPos[1], ViewBaseCamPos[2], 3000, CAMERA_MOVE);
					InterpolateCameraLookAt(i, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 3000, CAMERA_MOVE);
				}
			}
		}
		default:
		{
			foreach(new i : Player)
			{
				if(Player[i][ToAddInRound] == true)
					PlayerPlaySound(i,1139,0.0,0.0,0.0);
			}
		}
	}
	new iString[64];
	format(iString,sizeof(iString),"~w~Base starting in ~r~~h~%d ~w~seconds", ViewTimer);
	TextDrawSetString( centerTeamNames, iString);

	ViewTimer --;
	return SetTimer("ViewBaseForPlayers", 1000, false);
}

SpawnPlayersInBase()
{
	ClearChat();
	SendClientMessageToAll(-1, sprintf(""COL_PRIM"Base has completely started: {FFFFFF}%s (ID: %d)", BName[Current], Current));
	SendClientMessageToAll(-1, sprintf(""COL_PRIM"Current base set: {FFFFFF}%s. "COL_PRIM"Type {FFFFFF}/loadbases "COL_PRIM"to switch base sets!", CurrentBaseSet));
	foreach(new i : Player)
	{
	    if(Player[i][ToAddInRound] == true)
		{
			if(Player[i][InDM] == true)
			{ //Make sure to remove player from DM, otherwise the player will have Player[playerid][Playing] = true and Player[playerid][InDM] = true, so you are saying that the player is both in Base and in DM.
			    Player[i][InDM] = false;
    			Player[i][DMReadd] = 0;
			}

            if(Player[i][Spectating] == true)
				StopSpectate(i);

			if(!Player[i][FakePacketRenovation] && Player[i][NetCheck] && NetStats_GetConnectedTime(i) < 300000)
			{
				SetTimerEx("FakePacketRenovationEnd", 30000, false, "ifb", i, NetStats_PacketLossPercent(i), false);
				Player[i][FakePacketRenovation] = true;
			}

	        Player[i][Playing] = true;
	        Player[i][WasInBase] = true;
			Player[i][WasInTeam] = Player[i][Team];
			Iter_Add(PlayersInRound, i);
			ResetPlayerRoundVariables(i);

			PlayerPlaySound(i, 1057, 0, 0, 0);
			SetCameraBehindPlayer(i);

			SetAP(i, RoundAR);
			SetHP(i, RoundHP);
			
			CreatePlayerTeamBar(i);
			
			ShowTeamCornerInfo(i);

	        SetPlayerVirtualWorld(i, 2); //Set player virtual world to something different that that for lobby and DM so that they don't collide with each other. e.g. You shouldn't be able to see players in lobby or DM while you are in base.
	        SetPlayerInterior(i, BInterior[Current]);

			switch(Player[i][Team]) {
			    case ATTACKER: {
			        if(BInterior[Current] == 0) SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], BAttackerSpawn[Current][0] + random(6), BAttackerSpawn[Current][1] + random(6), BAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
					else SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], BAttackerSpawn[Current][0] + random(2), BAttackerSpawn[Current][1] + random(2), BAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);

					Player[i][IgnoreSpawn] = true;
					SetCPForPlayer(i);
				    SetPlayerColor(i, ATTACKER_PLAYING);
				    SpawnPlayer(i);
           			SetPlayerMapIcon(i, 59, BAttackerSpawn[Current][0], BAttackerSpawn[Current][1], BAttackerSpawn[Current][2], 59, 0, MAPICON_GLOBAL);
                    SetPlayerTeam(i, ATTACKER);
					
                    ShowTeamBarsForPlayer(i);
					
					if(IsACPluginLoaded() && IsACEnabled())
						TogglePlayerVehicleBlips(i, true);
				} case DEFENDER: {
			        if(BInterior[Current] == 0) SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], BDefenderSpawn[Current][0] + random(6), BDefenderSpawn[Current][1] + random(6), BDefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
					else  SetSpawnInfo(i, Player[i][Team], Skin[Player[i][Team]], BDefenderSpawn[Current][0] + random(2), BDefenderSpawn[Current][1] + random(2), BDefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);

					Player[i][IgnoreSpawn] = true;
					SetCPForPlayer(i);
					SetPlayerColor(i, DEFENDER_PLAYING);
					SpawnPlayer(i);
			        SetPlayerTeam(i, DEFENDER);
					
			        ShowTeamBarsForPlayer(i);
					
					if(IsACPluginLoaded() && IsACEnabled())
						TogglePlayerVehicleBlips(i, DefendersSeeVehiclesBlips);
				}
			}

			if(RoundPaused == false) TogglePlayerControllable(i, 1);
			else TogglePlayerControllable(i, 0);
			Player[i][ToAddInRound] = false;

			UpdateRoundKillDmgTDmg(i);
		}
	}
	ResetRoundVariablesInSlots();
	
	UpdateTeamCornerInfo();
	
	RoundMints = ConfigRoundTime;
	RoundSeconds = 0;

	if(CheckTeamElimination() != 0)
	{
		foreach(new i:Player)
		{
			ShowRoundStats(i);
		}
		AllowStartBase = true;
		BaseStarted = true;
		UpdateTeamPlayerCount(ATTACKER, false);
		UpdateTeamPlayerCount(DEFENDER, false);
		UpdateTeamHP(ATTACKER);
		UpdateTeamHP(DEFENDER);
		UpdateTeamNamesTextdraw();
		StartGameLoop();
		FallProtection = true;
		RadarFix();
		#if defined _league_included
		if(LeagueAllowed)
		{
			CheckLeagueMatchValidity(1000);
		}
		#endif
		SetTimer("ShowPlayingPlayersGunmenu", 1000, false);
	}
    return 1;
}

forward AddPlayerToBase(playerid);
public AddPlayerToBase(playerid)
{
	if(Player[playerid][Spectating] == true) {
		StopSpectate(playerid);
		SetTimerEx("AddPlayerToBase", 500, false, "i", playerid);
		return 1;
	}

	if(Player[playerid][InDM] == true) { //Make sure to remove player from DM, otherwise the player will have Player[playerid][Playing] = true and Player[playerid][InDM] = true, so you are saying that the player is both in Base and in DM.
	    Player[playerid][InDM] = false;
		Player[playerid][DMReadd] = 0;
	}
	if(Player[playerid][LastVehicle] != -1) {
		DestroyVehicle(Player[playerid][LastVehicle]);
		Player[playerid][LastVehicle] = -1;
	}

	if(Player[playerid][WasInBase] == false) {
		ResetPlayerRoundVariables(playerid);
	}

	if(!Player[playerid][FakePacketRenovation] && Player[playerid][NetCheck] && NetStats_GetConnectedTime(playerid) < 300000)
	{
		SetTimerEx("FakePacketRenovationEnd", 30000, false, "ifb", playerid, NetStats_PacketLossPercent(playerid), false);
		Player[playerid][FakePacketRenovation] = true;
	}

    Player[playerid][Playing] = true;
    Player[playerid][WasInBase] = true;
	Player[playerid][WasInTeam] = Player[playerid][Team];
	Iter_Add(PlayersInRound, playerid);
	UpdateTeamPlayerCount(Player[playerid][Team], false);

	PlayerPlaySound(playerid, 1057, 0, 0, 0);
	SetCameraBehindPlayer(playerid);

	SetAP(playerid, RoundAR);
	SetHP(playerid, RoundHP);
	
	CreatePlayerTeamBar(playerid);
	
	ShowTeamCornerInfo(playerid);
	UpdateTeamCornerInfo();

    SetPlayerVirtualWorld(playerid, 2); //Set player virtual world to something different that that for lobby and DM so that they don't collide with each other. e.g. You shouldn't be able to see players in lobby or DM while you are in base.
    SetPlayerInterior(playerid, BInterior[Current]);

	switch(Player[playerid][Team]) {
	    case ATTACKER: {
	        SetSpawnInfo(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], BAttackerSpawn[Current][0] + random(2), BAttackerSpawn[Current][1] + random(2), BAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
			SpawnPlayer(playerid);
			SetCPForPlayer(playerid);
	        SetPlayerColor(playerid, ATTACKER_PLAYING);
   			SetPlayerMapIcon(playerid, 59, BAttackerSpawn[Current][0], BAttackerSpawn[Current][1], BAttackerSpawn[Current][2], 59, 0, MAPICON_GLOBAL);
            SetPlayerTeam(playerid, ATTACKER);
			
            ShowTeamBarsForPlayer(playerid);
			
			if(IsACPluginLoaded() && IsACEnabled())
				TogglePlayerVehicleBlips(playerid, true);
		} case DEFENDER: {
	        SetSpawnInfo(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], BDefenderSpawn[Current][0] + random(2), BDefenderSpawn[Current][1] + random(2), BDefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
			SpawnPlayer(playerid);
			SetCPForPlayer(playerid);
	        SetPlayerColor(playerid, DEFENDER_PLAYING);
	        SetPlayerTeam(playerid, DEFENDER);
			
	        ShowTeamBarsForPlayer(playerid);
			
			if(IsACPluginLoaded() && IsACEnabled())
				TogglePlayerVehicleBlips(playerid, DefendersSeeVehiclesBlips);
		} case REFEREE: {
	        SetSpawnInfo(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], BCPSpawn[Current][0] + random(2), BCPSpawn[Current][1] + random(2), BCPSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
			SpawnPlayer(playerid);
			SetCPForPlayer(playerid);
	        SetPlayerColor(playerid, REFEREE_COLOR);
	        SetPlayerTeam(playerid, REFEREE);
		}
	}

	#if defined _league_included
	if(LeagueAllowed)
	{
		CheckLeagueMatchValidity(1000);
	}
	#endif

	if(RoundPaused == false) TogglePlayerControllable(playerid, 1);
	else TogglePlayerControllable(playerid, 0);

    Player[playerid][ToAddInRound] = false;

	ShowPlayerGunmenu(playerid, 500);

	UpdateRoundKillDmgTDmg(playerid);

	RadarFix();
	return 1;
}

new bool:AlreadyEndingRound = false;

forward NotEndingRound();
public NotEndingRound()
{
    AlreadyEndingRound = false;
    return 1;
}

EndRound(WinID) //WinID: 0 = CP, 1 = RoundTime, 2 = NoAttackersLeft, 3 = NoDefendersLeft, 4 = Nobody, 5 = Arena:Attackers took cp, 6 = Arena:Defenders took cp
{
	if(AlreadyEndingRound == true)
	    return 0;

    AlreadyEndingRound = true;

	switch(GameType) {
	    case BASE: {
			BaseStarted = false;
	    } case ARENA: {
			ArenaStarted = false;
	    }
	}


	if( WarMode == true )
	{
		if( MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__ID ] == Current )
		{
		    MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__completed ] = true;
		}
	}

    ElapsedTime = 0;
	TeamCapturingCP = NON;
    PlayersInCP = 0;
    MatchEnded = false;
	FallProtection = false;
    RoundPaused = false;
    RoundUnpausing = false;

	PlayersAlive[ATTACKER] = 0;
	PlayersAlive[DEFENDER] = 0;

	PlayersDead[ATTACKER] = 0;
	PlayersDead[DEFENDER] = 0;

    GangZoneDestroy(CPZone);
	GangZoneDestroy(ArenaZone);
	
	ResetBackupRequests();

	new iString[256], TopString[3][128];

	TextDrawHideForAll(EN_CheckPoint);

	new winnerid = -1;
	if(WinID == 0 || WinID == 3 ||  WinID == 5)
	{
		format(iString, sizeof(iString), "~n~~r~~h~%s ~w~Won The Round", TeamName[ATTACKER]);
		winnerid = ATTACKER;
		if(WarMode == true) TeamScore[ATTACKER]++;
	}
	else if(WinID == 1 || WinID == 2 || WinID == 6)
	{
		format(iString, sizeof(iString), "~n~~b~~h~%s ~w~Won The Round", TeamName[DEFENDER]);
		winnerid = DEFENDER;
		if(WarMode == true) TeamScore[DEFENDER]++;
 	}
	else if(WinID == 4)
	{
		iString = "~n~~w~No One Won, Same Team HPs";
	}
	TextDrawSetString(topTextScore, iString);

	UpdateTeamScoreTextDraw();
	UpdateTeamNameTextDraw();

	if(WarMode == true) {
		CurrentRound ++;
		UpdateRoundsPlayedTextDraw();
	}
	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tKill\t\t\t\tHP\t\t\t\tAcc\t\t\tDmg";
	TextDrawSetString(leftText, iString);
	TextDrawSetString(rightText, iString);

	SendRconCommand("mapname Lobby");
	FixGamemodeText();


	new
	    playerScores[MAX_PLAYERS][rankingEnum],
	    index,
	    p,
	    names[MAX_PLAYERS][MAX_PLAYER_NAME]
	;

	new Float: ahpleft,
		Float: dhpleft,
	    aalive, dalive
	;

	foreach(new i : Player)
	{
		HideRoundStats(i);
		if(Player[i][Spawned] == true)
		{
			if(Player[i][WasInBase] == true)
			{
				if(Player[i][Playing] == true)
				{
					OnPlayerAmmoUpdate(i);

					if(Player[i][Team] == ATTACKER) {
						ahpleft = ahpleft + (Player[i][pHealth] + Player[i][pArmour]);
						aalive++;
					} else if(Player[i][Team] == DEFENDER) {
						dhpleft = dhpleft + (Player[i][pHealth] + Player[i][pArmour]);
						dalive++;
					}
					#if defined _league_included
					if(LeagueMode && (WinID == 0 || WinID == 6 || WinID == 5))
					{
						if(Player[i][WasInCP])
						{
							AddPlayerLeaguePoints(i, 200, "capturing the CP");
						}
					}
					#endif
				}
				#if defined _league_included
				if(Player[i][WasInTeam] == winnerid)
				{
					AddPlayerLeaguePoints(i, 150);
				}
				else
				{
					AddPlayerLeaguePoints(i, -100);
				}
				#endif
				playerScores[index][player_Score] = Player[i][RoundDamage];
				playerScores[index][player_Team] = Player[i][Team];
				playerScores[index][player_Kills] = Player[i][RoundKills];
				playerScores[index][player_Deaths] = Player[i][RoundDeaths];
				playerScores[index][player_HP] = Player[i][pHealth] + Player[i][pArmour];
				playerScores[index][player_Acc] = floatround(Player[i][Accuracy], floatround_round);

				if(playerScores[index][player_Deaths] > 0)
					playerScores[index][player_Overall] = playerScores[index][player_Score] + playerScores[index][player_Kills] + playerScores[index][player_Acc];
				else
					playerScores[index][player_Overall] = playerScores[index][player_Score] + playerScores[index][player_HP] + playerScores[index][player_Kills] + playerScores[index][player_Acc];

				format(names[index], MAX_PLAYER_NAME, Player[i][NameWithoutTag]);

				playerScores[index++][player_ID] = i;
				p ++;

				Player[i][RoundPlayed] ++;
				#if defined _league_included
				if(LeagueMode)
				{
					// Increase rounds played in league
					IncreasePlayerLeagueRounds(i);
					if(PlayerShop[i][SHOP_POINTS_DOUBLER])
					{
						// Double points for who bought the points doubler from league shop
						PlayerShop[i][SHOP_POINTS_DOUBLER] = false;
						new roundPoints = GetPlayerLeagueRoundPoints(i);
						if(roundPoints > 0)
							AddPlayerLeaguePoints(i, roundPoints * 2);
					}
				}
				#endif
			}
			Player[i][WasInCP] = false;
			Player[i][ToAddInRound] = false;
			
			if(Player[i][Spectating] == true)
				StopSpectate(i);
				
			Player[i][WasInBase] = false;
			Player[i][WasInTeam] = NON;
			Player[i][WeaponPicked] = 0;
			Player[i][TimesSpawned] = 0;
			RemovePlayerMapIcon(i, 59);
			if(IsACPluginLoaded() && IsACEnabled())
				TogglePlayerVehicleBlips(i, true);

			PlayerTextDrawHide(i, AreaCheckTD[i]);
			PlayerTextDrawHide(i, AreaCheckBG[i]);

			if(Player[i][InDuel] == false) {
				SetHP(i, 100);
				SetAP(i, 100);
			}

			if(Player[i][InDeathCamera])
				OnPlayerDeathCameraEnd(i);

			if(Player[i][Playing] == true)
			{
				Player[i][Playing] = false;
				SpawnInLobby(i);
				PlayerTextDrawHide(i, DeathText[i][0]);
				PlayerTextDrawHide(i, DeathText[i][1]);
			}

			if(Player[i][InDuel] == false)
				ShowEndRoundTextDraw(i);
			DisablePlayerCheckpoint(i);
			SetPlayerScore(i, 0);
			HideDialogs(i);
			HidePlayerGunmenu(i);
		}
	}

	for(new i=0; i < SAVE_SLOTS; ++i) {
		if(strlen(SaveVariables[i][pName]) > 2 && Current == SaveVariables[i][RoundID] && SaveVariables[i][CheckScore] == true) {
	    	playerScores[index][player_Score] = SaveVariables[i][RDamage];
	    	playerScores[index][player_Team] = SaveVariables[i][pTeam];
	    	playerScores[index][player_Kills] = SaveVariables[i][RKills];
	    	playerScores[index][player_Deaths] = SaveVariables[i][RDeaths];
			playerScores[index][player_HP] = SaveVariables[i][gHealth] + SaveVariables[i][gArmour];
			playerScores[index][player_Acc] = SaveVariables[i][iAccuracy];

			if(playerScores[index][player_Deaths] > 0)
				playerScores[index][player_Overall] = playerScores[index][player_Score] + playerScores[index][player_Kills] + playerScores[index][player_Acc];
			else
				playerScores[index][player_Overall] = playerScores[index][player_Score] + playerScores[index][player_HP] + playerScores[index][player_Kills] + playerScores[index][player_Acc];

			format(names[index], MAX_PLAYER_NAME, SaveVariables[i][pNameWithoutTag]);

	   	    SaveVariables[i][RKills]   	=  	0;
			SaveVariables[i][RDeaths]  	= 	0;
			SaveVariables[i][RDamage] 	= 	0;

			SaveVariables[i][RoundID]   =   -1;
            SaveVariables[i][CheckScore] = false;

			index++;
			p++;
		}
	}

	Current = -1;

	GetPlayerHighestScores2(playerScores, names, 0, index-1);

	new topkill, topkillID = -1,
		Float: topDmg, topDmgID = -1,
		topAcc, topAccID = -1,
		topOverall, topOverallID = -1
	;

	for(new i = 0; i != p; ++i) {

	    if( playerScores[i][player_Kills] > topkill && playerScores[i][player_Kills] > 0 )
	    {
            topkill = playerScores[i][player_Kills];
            topkillID = i;
	    }
	    if( playerScores[i][player_Score] > topDmg && playerScores[i][player_Score] > 0  )
	    {
            topDmg = playerScores[i][player_Score];
            topDmgID = i;
	    }
	    if( playerScores[i][player_Acc] > topAcc && playerScores[i][player_Acc] > 0  )
	    {
            topAcc = playerScores[i][player_Acc];
            topAccID = i;
	    }
		if( playerScores[i][player_Overall] > topOverall && playerScores[i][player_Score] > 0 && playerScores[i][player_Team] == winnerid)
	    {
            topOverall = playerScores[i][player_Overall];
            topOverallID = i;
	    }

	    if(playerScores[i][player_Team] == ATTACKER || playerScores[i][player_Team] == ATTACKER_SUB) {
	        format(AttList, sizeof(AttList), "%s~w~%s~n~", AttList, names[i]);
		    format(AttKills, sizeof(AttKills), "%s~w~%d~n~", AttKills, playerScores[i][player_Kills]);
		    if(playerScores[i][player_Deaths] > 0) {
				format(AttDeaths, sizeof(AttDeaths), "%s~w~Dead~n~", AttDeaths);
			} else {
				format(AttDeaths, sizeof(AttDeaths), "%s~w~%d~n~", AttDeaths, playerScores[i][player_HP]);
			}
	        format(AttDamage, sizeof(AttDamage), "%s~w~%d~n~", AttDamage, playerScores[i][player_Score]);
            format(AttAcc, sizeof(AttAcc), "%s~w~%d%%~n~", AttAcc, playerScores[i][player_Acc]);

		} else if(playerScores[i][player_Team] == DEFENDER || playerScores[i][player_Team] == DEFENDER_SUB) {
	        format(DefList, sizeof(DefList), "%s~w~%s~n~", DefList, names[i]);
	        format(DefKills, sizeof(DefKills), "%s~w~%d~n~", DefKills, playerScores[i][player_Kills]);
	        if(playerScores[i][player_Deaths] > 0) {
				format(DefDeaths, sizeof(DefDeaths), "%s~w~Dead~n~", DefDeaths);
			} else {
				format(DefDeaths, sizeof(DefDeaths), "%s~w~%d~n~", DefDeaths, playerScores[i][player_HP]);
			}

	        format(DefDamage, sizeof(DefDamage), "%s~w~%d~n~", DefDamage, playerScores[i][player_Score]);
	        format(DefAcc, sizeof(DefAcc), "%s~w~%d%%~n~", DefAcc, playerScores[i][player_Acc]);

		}

		if(i == 0) format(TopString[0], 128, "%s1st         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
		else if(i == 1) format(TopString[1], 128, "%s2nd         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
		else if(i == 2) format(TopString[2], 128, "%s3rd         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);

	}

	iString = "";

	if( topkillID >= 0 ) format( iString, sizeof(iString) , "~w~~h~Most Kills: %s~h~~h~%s ~w~~h~%d_____", TDC[playerScores[topkillID][player_Team]], names[topkillID] , topkill  );
	else format( iString, sizeof(iString) , "~w~~h~Most Kills: None_____" );
	if( topDmgID >= 0 ) format( iString, sizeof(iString) , "%s~w~~h~Most Dmg: %s~h~~h~%s ~w~~h~%.0f_____", iString, TDC[playerScores[topDmgID][player_Team]], names[topDmgID] , topDmg  );
	else format( iString, sizeof(iString) , "%s~w~~h~Most Dmg: None_____", iString );
    if( topAccID >= 0 ) format( iString, sizeof(iString) , "%s~w~~h~Top Acc: %s~h~~h~%s ~w~~h~%d%%", iString, TDC[playerScores[topAccID][player_Team]], names[topAccID] , topAcc  );
	else format( iString, sizeof(iString) , "%s~w~~h~Top Acc: None", iString );
	TextDrawSetString( leftTop, iString );

    iString = "";

    switch( WinID )
	{
	    case 0: format( iString, sizeof(iString), "~r~~h~Attackers ~w~captured the ~b~~h~Checkpoint");
	    case 3: format( iString, sizeof(iString), "~r~~h~~h~Attackers ~w~won by ~r~%.0f hp ~w~and ~r~~h~%d players alive" , ahpleft, aalive);
	    case 1, 2: format( iString, sizeof(iString), "~b~~h~~h~Defenders ~w~won by ~b~%.0f hp ~w~and ~b~~h~%d players alive" ,dhpleft, dalive);
		case 5: format( iString, sizeof(iString), "~r~~h~%s ~w~captured the ~r~~h~Checkpoint", TeamName[ATTACKER]);
		case 6: format( iString, sizeof(iString), "~b~~h~%s ~w~captured the ~b~~h~Checkpoint", TeamName[DEFENDER]);
	}

	TextDrawSetString( teamWonHow, iString);
	TextDrawSetString(leftNames, AttList);
	TextDrawSetString(leftKills, AttKills);
	TextDrawSetString(leftHP, AttDeaths);
	TextDrawSetString(leftAcc, AttAcc);
	TextDrawSetString(leftDmg, AttDamage);

	TextDrawSetString(rightNames, DefList);
	TextDrawSetString(rightKills, DefKills);
	TextDrawSetString(rightHP, DefDeaths);
	TextDrawSetString(rightAcc, DefAcc);
	TextDrawSetString(rightDmg, DefDamage);

	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
    SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, "{FFFFFF}---------------------------------------------------------------");
    SendClientMessageToAll(-1, "{FFFFFF}Top Players:");
	SendClientMessageToAll(-1, TopString[0]);
	SendClientMessageToAll(-1, TopString[1]);
	SendClientMessageToAll(-1, TopString[2]);
	SendClientMessageToAll(-1, "{FFFFFF}---------------------------------------------------------------");
	SendClientMessageToAll(-1, " ");
	if(topOverallID != -1 && winnerid != -1)
		SendClientMessageToAll(-1, sprintf("{FFFFFF}Man of the round is: %s%s", TextColor[playerScores[topOverallID][player_Team]], names[topOverallID]));

	#if defined _league_included
	UpdateOnlineMatchesList(WarMode);
	if(LeagueMode)
	{
		OnLeagueRoundEnd();
	}
	#endif

	AllowStartBase = false;

	if(WarMode == true) {
    	SetTimer("SwapBothTeams",2500,0);
	}

	if(WarMode == false) {
		if(AutoBal == true) {
			SetTimer("DoAutoBalance",2500,0);
		} else {
			SetTimer("DontAutoBalance",2500,0);
		}
	}


	if(CurrentRound >= TotalRounds && CurrentRound != 0) {
		SetTimer("WarEnded", 5000, 0);
		SendClientMessageToAll(-1, ""COL_PRIM"Preparing End Match Results..");
		SendClientMessageToAll(-1, ""COL_PRIM"If you missed the results, type {FFFFFF}/showagain");
	}
	AttList = "";
	AttKills = "";
	AttDeaths = "";
	AttDamage = "";
	AttAcc = "";
	DefList = "";
	DefKills = "";
	DefDeaths = "";
	DefDamage = "";
	DefAcc = "";
	
	DeleteAllTeamBars();
	HideTeamCornerInfoForAll();
	
	DeleteAllDeadBodies();
    ResetTeamLeaders();
	Iter_Clear(PlayersInRound);

	if(AutoRoundStarter)
		SetRoundAutoStart(20);

    SetTimer("NotEndingRound", 3000, false);

	switch(random(4))
	{
		case 2:
			SetTimer("SendTipMessageToAll", 7000, false);

	}
	return 1;
}

forward WarEnded();
public WarEnded()
{
    ClearKillList(); // Clears the kill-list.

	new iString[256], TopString[3][128];

	new winnerid = -1;

    if(TeamScore[ATTACKER] > TeamScore[DEFENDER])
	{
		winnerid = ATTACKER;
 		format(iString, sizeof(iString),"~r~%s ~w~Won The Match~n~~r~%s ~h~%d		~b~~h~%s ~h~%d", TeamName[ATTACKER], TeamName[ATTACKER], TeamScore[ATTACKER], TeamName[DEFENDER], TeamScore[DEFENDER]);
	}
	else if(TeamScore[DEFENDER] > TeamScore[ATTACKER])
	{
		winnerid = DEFENDER;
	    format(iString,sizeof(iString),"~b~~h~%s ~w~Won The Match~n~~b~~h~%s ~h~%d		~r~%s ~h~%d", TeamName[DEFENDER], TeamName[DEFENDER], TeamScore[DEFENDER], TeamName[ATTACKER], TeamScore[ATTACKER]);
	}
	else
	{
	    format(iString,sizeof(iString),"~w~No One Won The Match~n~~r~%s ~h~%d		~b~~h~%s ~h~%d", TeamName[ATTACKER], TeamScore[ATTACKER], TeamName[DEFENDER], TeamScore[DEFENDER]);
	}
    TextDrawSetString(topTextScore, iString);

	MatchEnded = true;

	CurrentRound = 0;
	format(iString, sizeof(iString), "SELECT * FROM Configs WHERE Option = 'Total Rounds'");
    new DBResult:res = db_query(sqliteconnection, iString);

	db_get_field_assoc(res, "Value", iString, sizeof(iString));
	TotalRounds = strval(iString);
	db_free_result(res);

	UpdateRoundsPlayedTextDraw();

    WarMode = false;

    HideMatchScoreBoard();

	iString = sprintf("%sWar Mode: ~r~~h~OFF", MAIN_TEXT_COLOUR);
	TextDrawSetString(WarModeText, iString);

	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tK\t\t\tD\t\t\tP\t\t\tAcc\t\t\tDmg";	TextDrawSetString(leftText, iString);
	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t K\t\t\tD\t\t\tP\t\t\tAcc\t\t\tDmg";
	TextDrawSetString(rightText, iString);

	new
	    playerScores[MAX_PLAYERS][rankingEnum],
	    index,
	    p,
	    names[MAX_PLAYERS][MAX_PLAYER_NAME]
	;


	foreach(new i : Player)
	{
		if(Player[i][TotalDamage] > 0)
		{
			playerScores[index][player_Score] = Player[i][TotalDamage];
			playerScores[index][player_Team] = Player[i][Team];
			playerScores[index][player_Kills] = Player[i][TotalKills];
			playerScores[index][player_Deaths] = Player[i][TotalDeaths];
			playerScores[index][player_TPlayed] = Player[i][RoundPlayed];
			playerScores[index][player_HP] = Player[i][pHealth] + Player[i][pArmour];

			new Float:nTotalAccuracy;
			if(Player[i][TotalBulletsFired] == 0) nTotalAccuracy = 0.0;
			else nTotalAccuracy = floatmul(100.0, floatdiv(Player[i][TotalshotsHit], Player[i][TotalBulletsFired]));
			playerScores[index][player_Acc] = floatround(nTotalAccuracy, floatround_round);

			if(playerScores[index][player_TPlayed] > 0)
				playerScores[index][player_Overall] = (playerScores[index][player_Score] / playerScores[index][player_TPlayed]) + playerScores[index][player_Kills] + playerScores[index][player_TPlayed] + playerScores[index][player_Acc] - playerScores[index][player_Deaths];
			else
				playerScores[index][player_Overall] = 0;

			format(names[index], MAX_PLAYER_NAME, Player[i][NameWithoutTag]);

			printf("overall of %s[%d]: %d", names[index], index, playerScores[index][player_Overall]);

		    playerScores[index++][player_ID] = i;
		    p++;
		}
		if(Player[i][Spectating] == true) StopSpectate(i);

		if(Player[i][InDuel] == false) ShowEndRoundTextDraw(i);

	}
	for(new i=0; i < SAVE_SLOTS; ++i) {
		if(strlen(SaveVariables[i][pName]) > 2 && SaveVariables[i][TDamage] > 0) {
	    	playerScores[index][player_Score] = SaveVariables[i][TDamage];
	    	playerScores[index][player_Team] = SaveVariables[i][pTeam];
	    	playerScores[index][player_Kills] = SaveVariables[i][TKills];
	    	playerScores[index][player_Deaths] = SaveVariables[i][TDeaths];
	    	playerScores[index][player_TPlayed] = SaveVariables[i][TPlayed];
	    	playerScores[index][player_HP] = SaveVariables[i][gHealth] + SaveVariables[i][gArmour];

			new Float:nTotalAccuracy;
			if(SaveVariables[i][tBulletsShot] == 0) nTotalAccuracy = 0.0;
			else nTotalAccuracy = floatmul(100.0, floatdiv(SaveVariables[i][tshotsHit], SaveVariables[i][tBulletsShot]));
			playerScores[index][player_Acc] = floatround(nTotalAccuracy, floatround_round);

			if(playerScores[index][player_TPlayed] > 0)
				playerScores[index][player_Overall] = (playerScores[index][player_Score] / playerScores[index][player_TPlayed]) + playerScores[index][player_Kills] + playerScores[index][player_TPlayed] + playerScores[index][player_Acc] - playerScores[index][player_Deaths];
			else
				playerScores[index][player_Overall] = 0;

	    	format(names[index], MAX_PLAYER_NAME, SaveVariables[i][pNameWithoutTag]);

	   	    SaveVariables[i][RKills]   	=  	0;
			SaveVariables[i][RDeaths]  	= 	0;
			SaveVariables[i][RDamage] 	= 	0;

			SaveVariables[i][RoundID]   =   -1;
			index++;
			p++;
		}
	}

	GetPlayerHighestScores2(playerScores, names, 0, index-1);

	new topkill, topkillID = -1,
		Float: topDmg, topDmgID = -1,
		topAcc, topAccID = -1,
		topOverall, topOverallID = -1
	;

	for(new i = 0; i != p; ++i) {

		if( playerScores[i][player_Kills] > topkill && playerScores[i][player_Kills] > 0 )
	    {
            topkill = playerScores[i][player_Kills];
            topkillID = i;
	    }
	    if( playerScores[i][player_Score] > topDmg && playerScores[i][player_Score] > 0  )
	    {
            topDmg = playerScores[i][player_Score];
            topDmgID = i;
	    }
	    if( playerScores[i][player_Acc] > topAcc && playerScores[i][player_Acc] > 0  )
	    {
            topAcc = playerScores[i][player_Acc];
            topAccID = i;
	    }
		if( playerScores[i][player_Overall] > topOverall && playerScores[i][player_Overall] != 0 && playerScores[i][player_Score] > 0 && playerScores[i][player_TPlayed] > 0  && playerScores[i][player_Team] == winnerid)
		{
			topOverall = playerScores[i][player_Overall];
			topOverallID = i;
		}

	    if(playerScores[i][player_Team] == ATTACKER || playerScores[i][player_Team] == ATTACKER_SUB) {
	        format(AttList, sizeof(AttList), "%s~w~%s~n~", AttList, names[i]);
		    format(AttKills, sizeof(AttKills), "%s~w~%d~n~", AttKills, playerScores[i][player_Kills]);
	        format(AttDeaths, sizeof(AttDeaths), "%s~w~%d~n~", AttDeaths, playerScores[i][player_Deaths]);
	        format(AttPlayed, sizeof(AttPlayed), "%s~w~%d~n~", AttPlayed, playerScores[i][player_TPlayed]);
	        format(AttDamage, sizeof(AttDamage), "%s~w~%d~n~", AttDamage, playerScores[i][player_Score]);
	        format(AttAcc, sizeof(AttAcc), "%s~w~%d%%~n~", AttAcc, playerScores[i][player_Acc]);


		} else if(playerScores[i][player_Team] == DEFENDER || playerScores[i][player_Team] == DEFENDER_SUB) {
	        format(DefList, sizeof(DefList), "%s~w~%s~n~", DefList, names[i]);
	        format(DefKills, sizeof(DefKills), "%s~w~%d~n~", DefKills, playerScores[i][player_Kills]);
	        format(DefDeaths, sizeof(DefDeaths), "%s~w~%d~n~", DefDeaths, playerScores[i][player_Deaths]);
	        format(DefPlayed, sizeof(DefPlayed), "%s~w~%d~n~", DefPlayed, playerScores[i][player_TPlayed]);
	        format(DefDamage, sizeof(DefDamage), "%s~w~%d~n~", DefDamage, playerScores[i][player_Score]);
	        format(DefAcc, sizeof(DefAcc), "%s~w~%d%%~n~", DefAcc, playerScores[i][player_Acc]);



		}
		if(i == 0) format(TopString[0], 128, "%s1st         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
		else if(i == 1) format(TopString[1], 128, "%s2nd         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
		else if(i == 2) format(TopString[2], 128, "%s3rd         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
	}


	iString = "";

	if( topAccID >= 0 ) format( iString, sizeof(iString) , "~w~~h~Most Kills: %s~h~~h~%s ~w~~h~%d_____", TDC[playerScores[topkillID][player_Team]], names[topkillID] , topkill  );
	else format( iString, sizeof(iString) , "~w~~h~Most Kills: None_____" );
	if( topDmgID >= 0 ) format( iString, sizeof(iString) , "%s~w~~h~Most Dmg: %s~h~~h~%s ~w~~h~%.0f_____", iString, TDC[playerScores[topDmgID][player_Team]], names[topDmgID] , topDmg  );
	else format( iString, sizeof(iString) , "%s~w~~h~Most Dmg: None_____", iString );
    if( topAccID >= 0 ) format( iString, sizeof(iString) , "%s~w~~h~Top Acc: %s~h~~h~%s ~w~~h~%d%%", iString, TDC[playerScores[topAccID][player_Team]], names[topAccID] , topAcc  );
	else format( iString, sizeof(iString) , "%s~w~~h~Top Acc: None", iString );
	TextDrawSetString( leftTop, iString );

	TextDrawSetString(leftPlayed, AttPlayed );
	TextDrawSetString(leftNames, AttList);
	TextDrawSetString(leftKills, AttKills);
	TextDrawSetString(leftDeaths, AttDeaths);
	TextDrawSetString(leftAcc, AttAcc);
	TextDrawSetString(leftDmg, AttDamage);

	TextDrawSetString(rightNames, DefList);
	TextDrawSetString(rightKills, DefKills);
	TextDrawSetString(rightDeaths, DefDeaths);
	TextDrawSetString(rightAcc, DefAcc);
	TextDrawSetString(rightDmg, DefDamage);
	TextDrawSetString(rightPlayed, DefPlayed );

	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
    SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, "{FFFFFF}---------------------------------------------------------------");
    SendClientMessageToAll(-1, "{FFFFFF}Top Players:");
	SendClientMessageToAll(-1, TopString[0]);
	SendClientMessageToAll(-1, TopString[1]);
	SendClientMessageToAll(-1, TopString[2]);
	SendClientMessageToAll(-1, "{FFFFFF}---------------------------------------------------------------");
	SendClientMessageToAll(-1, " ");
	if(topOverallID != -1 && winnerid != -1)
		SendClientMessageToAll(-1, sprintf("{FFFFFF}Man of the match is: %s%s",  TextColor[playerScores[topOverallID][player_Team]], names[topOverallID]));

	#if defined _league_included
	UpdateOnlineMatchesList(false);
	if(LeagueMode)
	{
		if(TeamScore[ATTACKER] > 0 || TeamScore[DEFENDER] > 0)
		{
			if(TeamScore[ATTACKER] > TeamScore[DEFENDER])
				OnLeagueMatchEnd(ATTACKER);
			else if(TeamScore[DEFENDER] > TeamScore[ATTACKER])
				OnLeagueMatchEnd(DEFENDER);
			else
				OnLeagueMatchEnd(-1);
		}
	}
	#endif

	TeamName[ATTACKER] = "Alpha";
	TeamName[ATTACKER_SUB] = "Alpha Sub";
	TeamName[DEFENDER] = "Beta";
	TeamName[DEFENDER_SUB] = "Beta Sub";

    TeamScore[ATTACKER] = 0;
    TeamScore[DEFENDER] = 0;

	UpdateTeamScoreTextDraw();
	UpdateRoundsPlayedTextDraw();
	UpdateTeamNameTextDraw();

	foreach(new i : Player)
	{
		ResetPlayerRoundVariables(i, true);
	}

	ClearPlayerVariables();
	ForgetPlayedBases();
	ForgetPlayedArenas();

	AttList = "";
	AttKills = "";
	AttDeaths = "";
	AttPlayed = "";
	AttAcc = "";
	AttDamage = "";

	DefList = "";
	DefKills = "";
	DefDeaths = "";
	DefPlayed = "";
	DefAcc = "";
	DefDamage = "";
	return 1;
}
