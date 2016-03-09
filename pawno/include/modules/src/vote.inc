/*
	Vote system
*/

#include "modules\header\vote.txt"

forward ResetVoting(votetype, bool:message);
public ResetVoting(votetype, bool:message)
{
	if(votetype < 0 || votetype >= MAX_VOTE_TYPES)
		return 0;
	
	if(votetype == VOTE_TYPE_NETCHECK)
	{
		new onplayerid = VoteData[votetype][VotingOnPlayer];
		Player[onplayerid][TempNetcheck] = false;
	}
	VoteData[votetype][VoteCount] = 0;
	foreach(new i : Player)
	{
		VoteData[votetype][PlayerVoted][i] = false;
	}
	if(message)
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s-voting "COL_PRIM"has been reset due to an error or vote timeout (%d secs)!", VoteTypeNames[votetype], VOTE_TIMEOUT_INTERVAL / 1000));
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
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", VOTE_TIMEOUT_INTERVAL, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
			PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has started {FFFFFF}add-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/voteadd %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has added to {FFFFFF}add-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/voteadd %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
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
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", VOTE_TIMEOUT_INTERVAL, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
			PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has started {FFFFFF}readd-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votereadd %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has added to {FFFFFF}readd-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votereadd %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
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
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", VOTE_TIMEOUT_INTERVAL, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
			PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has started {FFFFFF}rem-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/voterem %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has added to {FFFFFF}rem-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/voterem %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
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
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", VOTE_TIMEOUT_INTERVAL, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
			PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has started {FFFFFF}kick-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votekick %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has added to {FFFFFF}kick-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votekick %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
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
	
	if(playerid == onplayerid)
		return SendErrorMessage(playerid, "You cannot vote to netcheck yourself. Try to ask people to vote netcheck you instead!");
	
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
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", VOTE_TIMEOUT_INTERVAL, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		Player[onplayerid][TempNetcheck] = true;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
			PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has started {FFFFFF}netcheck-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votenetcheck %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has added to {FFFFFF}netcheck-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votenetcheck %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			if(Player[onplayerid][NetCheck] == 1) 
			{
				Player[onplayerid][NetCheck] = 0;
				Player[onplayerid][FPSCheck] = 0;
				Player[onplayerid][PingCheck] = 0;
				Player[onplayerid][PLCheck] = 0;
				SendClientMessageToAll(-1, sprintf(""COL_PRIM"Voting result on {FFFFFF}%s: "COL_PRIM"disabled Net-Check!", Player[onplayerid][Name]));
				db_free_result(db_query(sqliteconnection, sprintf("UPDATE Players SET NetCheck = 0 WHERE Name = '%q'", Player[onplayerid][Name])));
			} 
			else 
			{
				Player[onplayerid][NetCheck] = 1;
				Player[onplayerid][FPSCheck] = 1;
				Player[onplayerid][PingCheck] = 1;
				Player[onplayerid][PLCheck] = 1;
				SendClientMessageToAll(-1, sprintf(""COL_PRIM"Voting result on {FFFFFF}%s: "COL_PRIM"enabled Net-Check!", Player[onplayerid][Name]));
				db_free_result(db_query(sqliteconnection, sprintf("UPDATE Players SET NetCheck = 1 WHERE Name = '%q'", Player[onplayerid][Name])));
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
	
	if(!Player[playerid][Playing])
		return SendErrorMessage(playerid, "You must be playing to be able to vote on this!");
	
	new votetype = VOTE_TYPE_UNPAUSE;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	
    if(!RoundPaused) return SendErrorMessage(playerid,"Round is already running and is not paused.");
	
	// Counting players who are able to vote
	new MaxVotesNeeded = Iter_Count(PlayersInRound); 
	if(VoteData[votetype][VoteCount] < 1) // First vote?
	{
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", VOTE_TIMEOUT_INTERVAL, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
			PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has started {FFFFFF}unpause-voting "COL_PRIM"[%d/%d] [/voteunpause or press Y]", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has added to {FFFFFF}unpause-voting "COL_PRIM"[%d/%d] [/voteunpause or press Y]", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
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
	return 1;
}

PlayerVotePause(playerid)
{
	if(Current == -1) 
		return SendErrorMessage(playerid, "There's no round in progress!");
	
	if(!Player[playerid][Playing])
		return SendErrorMessage(playerid, "You must be playing to be able to vote on this!");
	
	new votetype = VOTE_TYPE_PAUSE;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	
    if(RoundPaused) return SendErrorMessage(playerid,"Round is already paused.");
	
	// Counting players who are able to vote
	new MaxVotesNeeded = Iter_Count(PlayersInRound); 
	if(VoteData[votetype][VoteCount] < 1) // First vote?
	{
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", VOTE_TIMEOUT_INTERVAL, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
			PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has started {FFFFFF}pause-voting "COL_PRIM"[%d/%d] [/votepause or press Y]", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has added to {FFFFFF}pause-voting "COL_PRIM"[%d/%d] [/votepause or press Y]", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			SendClientMessageToAll(-1, ""COL_PRIM"Pause-voting result: {FFFFFF}round has been paused!");
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
			PausePressed = GetTickCount();
			PauseRound();
		}
	}
	return 1;
}

PlayerVoteEndMatch(playerid)
{
	if(WarMode != true) 
		return SendErrorMessage(playerid, "Match mode is already disabled!");
	
	if(!(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
		return SendErrorMessage(playerid,"You must be part of one of the following teams: Attacker, Defender.");
	
	new votetype = VOTE_TYPE_ENDMATCH;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	
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
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", VOTE_TIMEOUT_INTERVAL, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
			PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has started {FFFFFF}End Match-voting "COL_PRIM"[%d/%d] [/voteendmatch]", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has added to {FFFFFF}End Match-voting "COL_PRIM"[%d/%d] [/voteendmatch]", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			SendClientMessageToAll(-1, ""COL_PRIM"End Match-voting result: {FFFFFF}match has been set to end!");
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
			if(Current != -1)
			{
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

				foreach(new i : Player) 
				{
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
				DeleteAllTeamBars();
				DeleteAllDeadBodies();
				GangZoneDestroy(CPZone);
				GangZoneDestroy(ArenaZone);
				ResetTeamLeaders();
				Iter_Clear(PlayersInRound);
			}
			SetTimer("WarEnded", 4000, 0);
		}
	}
	return 1;
}

PlayerVoteRestartRound(playerid)
{
	if(Current == -1) 
		return SendErrorMessage(playerid, "There's no round in progress!");
	
	if(AllowStartBase == false) 
		return SendErrorMessage(playerid, "Please wait.");
	
	if(!Player[playerid][Playing])
		return SendErrorMessage(playerid, "You must be playing to be able to vote on this!");
	
	new votetype = VOTE_TYPE_RESTARTROUND;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	
	// Counting players who are able to vote
	new MaxVotesNeeded = Iter_Count(PlayersInRound); 
	if(VoteData[votetype][VoteCount] < 1) // First vote?
	{
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", VOTE_TIMEOUT_INTERVAL, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
			PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has started {FFFFFF}restart round-voting "COL_PRIM"[%d/%d] [/voterr]", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has added to {FFFFFF}restart round-voting "COL_PRIM"[%d/%d] [/voterr", Player[playerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			SendClientMessageToAll(-1, ""COL_PRIM"Restart round-voting result: {FFFFFF}round has been set to restart!");
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
			AllowStartBase = false;
			if(RoundPaused == true)
			{
				TextDrawHideForAll(PauseTD);
				RoundPaused = false;
			}
			RoundUnpausing = false;

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
					Player[i][WasInTeam] = NON;

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
				HideRoundStats(i);
			}
			TextDrawHideForAll(EN_CheckPoint);
		}
	}
	return 1;
}

PlayerVoteSwitch(playerid, onplayerid)
{
	if(!(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
		return SendErrorMessage(playerid,"You must be part of one of the following teams: Attacker, Defender.");
	
	new votetype = VOTE_TYPE_SWITCH;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	if(VoteData[votetype][VoteCount] > 0 && VoteData[votetype][VotingOnPlayer] != onplayerid) 
		return SendErrorMessage(playerid, sprintf("Another switch-voting is in progress (on playerid: %d), please wait!", VoteData[votetype][VotingOnPlayer]));
	
    if(!IsPlayerConnected(onplayerid)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[onplayerid][Playing] == true) return SendErrorMessage(playerid,"That player is already playing.");
	if(Player[onplayerid][InDuel] == true) return SendErrorMessage(playerid,"That player is in a duel.");
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
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", VOTE_TIMEOUT_INTERVAL, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
			PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has started {FFFFFF}Switch-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/voteswitch %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has added to {FFFFFF}Switch-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/voteswitch %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
			Player[onplayerid][Team] = GetTeamWithLessPlayers();
			SwitchTeamFix(onplayerid);
			SendClientMessageToAll(-1, sprintf(""COL_PRIM"Voting result on {FFFFFF}%s: "COL_PRIM"switched to the team which has less players count (%s)!", Player[onplayerid][Name], TeamName[Player[onplayerid][Team]]));
		}
	}
	return 1;
}

PlayerVoteMenu(playerid, onplayerid)
{
	if(Current == -1) 
		return SendErrorMessage(playerid, "There's no round in progress!");
	
	if(!Player[playerid][Playing])
		return SendErrorMessage(playerid, "You must be playing to be able to vote on this!");
	
	new votetype = VOTE_TYPE_MENU;
	if(VoteData[votetype][PlayerVoted][playerid])
		return SendErrorMessage(playerid, "You've already voted!");
	if(VoteData[votetype][VoteCount] > 0 && VoteData[votetype][VotingOnPlayer] != onplayerid) 
		return SendErrorMessage(playerid, sprintf("Another gunmenu-voting is in progress (on playerid: %d), please wait!", VoteData[votetype][VotingOnPlayer]));
	
    if(!IsPlayerConnected(onplayerid)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[onplayerid][Playing] == false) return SendErrorMessage(playerid,"That player is not playing.");
	if(!(Player[onplayerid][Team] == ATTACKER || Player[onplayerid][Team] == DEFENDER))
		return SendErrorMessage(playerid,"That player must be part of one of the following teams: Attacker, Defender.");
	
	// Counting players who are able to vote
	new MaxVotesNeeded = Iter_Count(PlayersInRound); 
	if(VoteData[votetype][VoteCount] < 1) // First vote?
	{
		VoteData[votetype][VotingExpireTimer] = SetTimerEx("ResetVoting", VOTE_TIMEOUT_INTERVAL, false, "ib", votetype, true);
		VoteData[votetype][VoteCount] = 1;
		VoteData[votetype][VotingOnPlayer] = onplayerid;
		foreach(new i : Player)
		{
			VoteData[votetype][PlayerVoted][i] = false;
			PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
		}
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has started {FFFFFF}gunmenu-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votemenu %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
	}
	else
	{
		VoteData[votetype][VoteCount] ++;
		VoteData[votetype][PlayerVoted][playerid] = true;
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s"COL_PRIM" has added to {FFFFFF}gunmenu-voting "COL_PRIM"on {FFFFFF}%s "COL_PRIM"[%d/%d] [/votemenu %d]", Player[playerid][Name], Player[onplayerid][Name], VoteData[votetype][VoteCount], MaxVotesNeeded, onplayerid));
		if(VoteData[votetype][VoteCount] >= MaxVotesNeeded) // Enough people voted!
		{
			SendClientMessageToAll(-1, sprintf(""COL_PRIM"Voting result on {FFFFFF}%s: "COL_PRIM"shown gunmenu!", Player[onplayerid][Name]));
			KillTimer(VoteData[votetype][VotingExpireTimer]);
			ResetVoting(votetype, false);
			ShowPlayerGunmenu(onplayerid, 0);
		}
	}
	return 1;
}