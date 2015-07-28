/*
	Vote system
*/

#include "modules\header\vote.txt"

forward ResetVoting(votetype, bool:message);
public ResetVoting(votetype, bool:message)
{
	if(votetype < 0 || votetype >= MAX_VOTE_TYPES)
		return 0;
	
	VoteData[votetype][VoteCount] = 0;
	foreach(new i : Player)
	{
		VoteData[votetype][PlayerVoted][i] = false;
	}
	if(message)
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s-voting "COL_PRIM"has been reset due to an error or vote timeout!", VoteTypeNames[votetype]));
	return 1;
}

InitPlayerVoting(playerid)
{
	for(new i = 0; i < MAX_VOTE_TYPES; i ++)
	{
		VoteData[i][PlayerVoted][playerid] = false;
	}
}

InitVoting()
{
	for(new i = 0; i < MAX_VOTE_TYPES; i ++)
	{
		VoteData[i][VoteCount] = 0;
	}
}

PlayerVoteAdd(playerid, onplayerid)
{
	if(Current == -1) 
		return SendErrorMessage(playerid, "There's no round in progress!");
	
	if(!(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
		return SendErrorMessage(playerid,"You must be part of one of the following teams: Attacker, Defender.");
	
	new votetype = VOTE_TYPE_ADD;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	if(VoteData[votetype][VoteCount] > 0 && VoteData[votetype][VotingOnPlayer] != onplayerid) 
		return SendErrorMessage(playerid, sprintf("Another add-voting is in progress (on playerid: %d), please wait!", VoteData[votetype][VotingOnPlayer]));
	
    if(!IsPlayerConnected(onplayerid)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[onplayerid][Playing] == true) return SendErrorMessage(playerid,"That player is already playing.");
	if(Player[onplayerid][InDuel] == true) return SendErrorMessage(playerid,"That player is in a duel.");
	if(!(Player[onplayerid][Team] == ATTACKER || Player[onplayerid][Team] == DEFENDER))
		return SendErrorMessage(playerid,"That player must be part of one of the following teams: Attacker, Defender.");
	
	// Counting players who are able to vote
	new countInTeam[2];
	foreach(new i : Player)
	{
		if(i == onplayerid)
			continue;
		
		switch(Player[i][Team])
		{
			case ATTACKER:
			{
				countInTeam[0] ++;
			}
			case DEFENDER:
			{
				countInTeam[1] ++;
			}
		}
	}
	if(countInTeam[0] == 0 || countInTeam[1] == 0)
	{
		return SendErrorMessage(playerid, "One team has no active players, so we cannot count this vote.");
	}
	new MaxVotesNeeded = countInTeam[0] + countInTeam[1]; 
	if(VoteData[votetype][VoteCount] < 1) // First vote?
	{
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", 20000, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has started {FFFFFF}add-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/voteadd %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has added to {FFFFFF}add-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/voteadd %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			SendClientMessageToAll(-1, sprintf(""COL_PRIM"Voting result on {FFFFFF}%s: "COL_PRIM"added to the round!", Player[onplayerid][Name]));
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
			if(Current != -1)
			{
				if(Player[onplayerid][Spectating] == true) StopSpectate(onplayerid);
				if(GameType == BASE) AddPlayerToBase(onplayerid);
				else if(GameType == ARENA) AddPlayerToArena(onplayerid);
			}
		}
	}
	return 1;
}

PlayerVoteReadd(playerid, onplayerid)
{
	if(Current == -1) 
		return SendErrorMessage(playerid, "There's no round in progress!");
	
	if(!(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
		return SendErrorMessage(playerid,"You must be part of one of the following teams: Attacker, Defender.");
	
	new votetype = VOTE_TYPE_READD;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	if(VoteData[votetype][VoteCount] > 0 && VoteData[votetype][VotingOnPlayer] != onplayerid) 
		return SendErrorMessage(playerid, sprintf("Another readd-voting is in progress (on playerid: %d), please wait!", VoteData[votetype][VotingOnPlayer]));
	
    if(!IsPlayerConnected(onplayerid)) return SendErrorMessage(playerid,"That player is not connected.");
	if(!Player[onplayerid][Playing])
		return SendErrorMessage(playerid,"This player is not even playing!");
	
	// Counting players who are able to vote
	new countInTeam[2];
	foreach(new i : Player)
	{
		if(i == onplayerid)
			continue;
		
		switch(Player[i][Team])
		{
			case ATTACKER:
			{
				countInTeam[0] ++;
			}
			case DEFENDER:
			{
				countInTeam[1] ++;
			}
		}
	}
	if(countInTeam[0] == 0 || countInTeam[1] == 0)
	{
		return SendErrorMessage(playerid, "One team has no active players, so we cannot count this vote.");
	}
	new MaxVotesNeeded = countInTeam[0] + countInTeam[1]; 
	if(VoteData[votetype][VoteCount] < 1) // First vote?
	{
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", 20000, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has started {FFFFFF}readd-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votereadd %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has added to {FFFFFF}readd-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votereadd %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			SendClientMessageToAll(-1, sprintf(""COL_PRIM"Voting result on {FFFFFF}%s: "COL_PRIM"re-added to the round!", Player[onplayerid][Name]));
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
			if(Current != -1)
			{
				if(Player[onplayerid][Playing] == true)
				{
					Player[onplayerid][TotalKills] = Player[onplayerid][TotalKills] - Player[onplayerid][RoundKills];
					Player[onplayerid][TotalDeaths] = Player[onplayerid][TotalDeaths] - Player[onplayerid][RoundDeaths];
					Player[onplayerid][TotalDamage] = Player[onplayerid][TotalDamage] - Player[onplayerid][RoundDamage];
				}
				DeletePlayerTeamBar(onplayerid);
				if(GameType == BASE)
					AddPlayerToBase(onplayerid);
				else if(GameType == ARENA)
					AddPlayerToArena(onplayerid);
			}
		}
	}
	return 1;
}

PlayerVoteRem(playerid, onplayerid)
{
	if(Current == -1) 
		return SendErrorMessage(playerid, "There's no round in progress!");
	
	if(!(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
		return SendErrorMessage(playerid,"You must be part of one of the following teams: Attacker, Defender.");
	
	new votetype = VOTE_TYPE_REM;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	if(VoteData[votetype][VoteCount] > 0 && VoteData[votetype][VotingOnPlayer] != onplayerid) 
		return SendErrorMessage(playerid, sprintf("Another rem-voting is in progress (on playerid: %d), please wait!", VoteData[votetype][VotingOnPlayer]));
	
    if(!IsPlayerConnected(onplayerid)) return SendErrorMessage(playerid,"That player is not connected.");
	if(!Player[onplayerid][Playing])
		return SendErrorMessage(playerid,"This player is not even playing!");
	
	// Counting players who are able to vote
	new countInTeam[2];
	foreach(new i : Player)
	{
		if(i == onplayerid)
			continue;
		
		switch(Player[i][Team])
		{
			case ATTACKER:
			{
				countInTeam[0] ++;
			}
			case DEFENDER:
			{
				countInTeam[1] ++;
			}
		}
	}
	if(countInTeam[0] == 0 || countInTeam[1] == 0)
	{
		return SendErrorMessage(playerid, "One team has no active players, so we cannot count this vote.");
	}
	new MaxVotesNeeded = countInTeam[0] + countInTeam[1]; 
	if(VoteData[votetype][VoteCount] < 1) // First vote?
	{
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", 20000, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has started {FFFFFF}rem-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/voterem %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has added to {FFFFFF}rem-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/voterem %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			SendClientMessageToAll(-1, sprintf(""COL_PRIM"Voting result on {FFFFFF}%s: "COL_PRIM"removed from the round!", Player[onplayerid][Name]));
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
			if(Current != -1)
			{
				RemovePlayerFromRound(onplayerid);
			}
		}
	}
	return 1;
}

PlayerVoteKick(playerid, onplayerid)
{	
	if(!(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
		return SendErrorMessage(playerid,"You must be part of one of the following teams: Attacker, Defender.");
	
	new votetype = VOTE_TYPE_KICK;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	if(VoteData[votetype][VoteCount] > 0 && VoteData[votetype][VotingOnPlayer] != onplayerid) 
		return SendErrorMessage(playerid, sprintf("Another kick-voting is in progress (on playerid: %d), please wait!", VoteData[votetype][VotingOnPlayer]));
	
    if(!IsPlayerConnected(onplayerid)) return SendErrorMessage(playerid,"That player is not connected.");
	
	// Counting players who are able to vote
	new countInTeam[2];
	foreach(new i : Player)
	{
		if(i == onplayerid)
			continue;
		
		switch(Player[i][Team])
		{
			case ATTACKER:
			{
				countInTeam[0] ++;
			}
			case DEFENDER:
			{
				countInTeam[1] ++;
			}
		}
	}
	if(countInTeam[0] == 0 || countInTeam[1] == 0)
	{
		return SendErrorMessage(playerid, "One team has no active players, so we cannot count this vote.");
	}
	new MaxVotesNeeded = countInTeam[0] + countInTeam[1]; 
	if(VoteData[votetype][VoteCount] < 1) // First vote?
	{
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", 20000, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has started {FFFFFF}kick-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votekick %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has added to {FFFFFF}kick-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votekick %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			SendClientMessageToAll(-1, sprintf(""COL_PRIM"Voting result on {FFFFFF}%s: "COL_PRIM"kicked from the server!", Player[onplayerid][Name]));
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
			SetTimerEx("OnPlayerKicked", 500, false, "i", onplayerid);
		}
	}
	return 1;
}

PlayerVoteNetCheck(playerid, onplayerid)
{	
	if(!(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
		return SendErrorMessage(playerid,"You must be part of one of the following teams: Attacker, Defender.");
	
	new votetype = VOTE_TYPE_NETCHECK;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	if(VoteData[votetype][VoteCount] > 0 && VoteData[votetype][VotingOnPlayer] != onplayerid) 
		return SendErrorMessage(playerid, sprintf("Another netcheck-voting is in progress (on playerid: %d), please wait!", VoteData[votetype][VotingOnPlayer]));
	
    if(!IsPlayerConnected(onplayerid)) return SendErrorMessage(playerid,"That player is not connected.");
	
	// Counting players who are able to vote
	new countInTeam[2];
	foreach(new i : Player)
	{
		if(i == onplayerid)
			continue;
		
		switch(Player[i][Team])
		{
			case ATTACKER:
			{
				countInTeam[0] ++;
			}
			case DEFENDER:
			{
				countInTeam[1] ++;
			}
		}
	}
	if(countInTeam[0] == 0 || countInTeam[1] == 0)
	{
		return SendErrorMessage(playerid, "One team has no active players, so we cannot count this vote.");
	}
	new MaxVotesNeeded = countInTeam[0] + countInTeam[1]; 
	if(VoteData[votetype][VoteCount] < 1) // First vote?
	{
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", 20000, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has started {FFFFFF}netcheck-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votenetcheck %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has added to {FFFFFF}netcheck-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votenetcheck %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			if(Player[onplayerid][NetCheck] == 1) 
			{
				Player[onplayerid][NetCheck] = 0;
				Player[onplayerid][FPSCheck] = 0;
				Player[onplayerid][PingCheck] = 0;
				Player[onplayerid][PLCheck] = 0;
				SendClientMessageToAll(-1, sprintf(""COL_PRIM"Voting result on {FFFFFF}%s: "COL_PRIM"disabled Net-Check!", Player[onplayerid][Name]));
				db_free_result(db_query(sqliteconnection, sprintf("UPDATE Players SET NetCheck = 0 WHERE Name = '%s'", DB_Escape(Player[onplayerid][Name]))));
			} 
			else 
			{
				Player[onplayerid][NetCheck] = 1;
				Player[onplayerid][FPSCheck] = 1;
				Player[onplayerid][PingCheck] = 1;
				Player[onplayerid][PLCheck] = 1;
				SendClientMessageToAll(-1, sprintf(""COL_PRIM"Voting result on {FFFFFF}%s: "COL_PRIM"enabled Net-Check!", Player[onplayerid][Name]));
				db_free_result(db_query(sqliteconnection, sprintf("UPDATE Players SET NetCheck = 1 WHERE Name = '%s'", DB_Escape(Player[onplayerid][Name]))));
			}
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
		}
	}
	return 1;
}

PlayerVoteUnpause(playerid)
{
	if(Current == -1) 
		return SendErrorMessage(playerid, "There's no round in progress!");
	
	if(!(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
		return SendErrorMessage(playerid,"You must be part of one of the following teams: Attacker, Defender.");
	
	new votetype = VOTE_TYPE_UNPAUSE;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	
    if(!RoundPaused) return SendErrorMessage(playerid,"Round is already running and is not paused.");
	
	// Counting players who are able to vote
	new countInTeam[2];
	foreach(new i : Player)
	{
		switch(Player[i][Team])
		{
			case ATTACKER:
			{
				countInTeam[0] ++;
			}
			case DEFENDER:
			{
				countInTeam[1] ++;
			}
		}
	}
	if(countInTeam[0] == 0 || countInTeam[1] == 0)
	{
		return SendErrorMessage(playerid, "One team has no active players, so we cannot count this vote.");
	}
	new MaxVotesNeeded = countInTeam[0] + countInTeam[1]; 
	if(VoteData[votetype][VoteCount] < 1) // First vote?
	{
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", 20000, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has started {FFFFFF}unpause-voting "COL_PRIM"[%d/%d] [/voteunpause or press Y]", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has added to {FFFFFF}pause-voting "COL_PRIM"[%d/%d] [/voteunpause or press Y]", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
			if(Current != -1)
			{
				if(RoundUnpausing == true)
				{
					SendClientMessageToAll(-1, ""COL_PRIM"Unpause-voting result: {FFFFFF}round is already being unpaused!");
					return 0;
				}
				PauseCountdown = 4;
				UnpauseRound();
				SendClientMessageToAll(-1, ""COL_PRIM"Unpause-voting result: {FFFFFF}round has been unpaused!");
			}
		}
	}
	return 1;
}

PlayerVotePause(playerid)
{
	if(Current == -1) 
		return SendErrorMessage(playerid, "There's no round in progress!");
	
	if(!(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
		return SendErrorMessage(playerid,"You must be part of one of the following teams: Attacker, Defender.");
	
	new votetype = VOTE_TYPE_PAUSE;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	
    if(RoundPaused) return SendErrorMessage(playerid,"Round is already paused.");
	
	// Counting players who are able to vote
	new countInTeam[2];
	foreach(new i : Player)
	{
		switch(Player[i][Team])
		{
			case ATTACKER:
			{
				countInTeam[0] ++;
			}
			case DEFENDER:
			{
				countInTeam[1] ++;
			}
		}
	}
	if(countInTeam[0] == 0 || countInTeam[1] == 0)
	{
		return SendErrorMessage(playerid, "One team has no active players, so we cannot count this vote.");
	}
	new MaxVotesNeeded = countInTeam[0] + countInTeam[1]; 
	if(VoteData[votetype][VoteCount] < 1) // First vote?
	{
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", 20000, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has started {FFFFFF}pause-voting "COL_PRIM"[%d/%d] [/votepause or press Y]", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"%s has added to {FFFFFF}pause-voting "COL_PRIM"[%d/%d] [/votepause or press Y]", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			SendClientMessageToAll(-1, ""COL_PRIM"Pause-voting result: {FFFFFF}round has been paused!");
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
			if(Current != -1)
			{
				PausePressed = GetTickCount();
				PauseRound();
			}
		}
	}
	return 1;
}