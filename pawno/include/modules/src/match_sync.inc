/*
		Uploads each match data somewhere so that it can be easily displayed in a website.
		It's still in beta
*/

#include "modules\header\match_sync.txt"

#if MATCH_SYNC == 1
MATCHSYNC_Init()
{
	mysql_close();
	mysql_debug(1);
 	mysql_connect("", "", "", "");
	return 1;
}

MATCHSYNC_DoesNameExist(nametocheck[])
{
	new query[70],result[128];
	format(query, sizeof(query), "SELECT SQLid FROM Players WHERE Name='%s'", nametocheck);
	mysql_query(query);
	mysql_store_result();
	if(mysql_fetch_row(result))
	{
	    mysql_free_result();
	    return 1;
 	}
 	else
 	{
 	    mysql_free_result();
  	}
	return 0;
}

MATCHSYNC_SyncPlayerKills(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof name);
	new query[70],result[128];
	format(query, sizeof(query), "SELECT Kills FROM Players WHERE Name='%s'", name);
	mysql_query(query);
	mysql_store_result();
	if(mysql_fetch_row(result))
	{
	    MATCHSYNC_Kills[playerid] = strval(result);
 	}
 	mysql_free_result();
	return 1;
}

MATCHSYNC_SyncPlayerDamage(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof name);
	new query[70],result[128];
	format(query, sizeof(query), "SELECT Damage FROM Players WHERE Name='%s'", name);
	mysql_query(query);
	mysql_store_result();
	if(mysql_fetch_row(result))
	{
	    MATCHSYNC_Damage[playerid] = strval(result);
 	}
 	mysql_free_result();
	return 1;
}

MATCHSYNC_SyncPlayerAccuracy(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof name);
	new query[70],result[128];
	format(query, sizeof(query), "SELECT Accuracy FROM Players WHERE Name='%s'", name);
	mysql_query(query);
	mysql_store_result();
	if(mysql_fetch_row(result))
	{
	    MATCHSYNC_Accuracy[playerid] = strval(result);
 	}
 	mysql_free_result();
	return 1;
}

MATCHSYNC_SyncPlayerRounds(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof name);
	new query[70],result[128];
	format(query, sizeof(query), "SELECT Rounds FROM Players WHERE Name='%s'", name);
	mysql_query(query);
	mysql_store_result();
	if(mysql_fetch_row(result))
	{
	    MATCHSYNC_Rounds[playerid] = strval(result);
 	}
 	mysql_free_result();
	return 1;
}

MATCHSYNC_SyncAllPlayers()
{
    foreach(new i : Player)
    {
        new name[MAX_PLAYER_NAME];
        GetPlayerName(i, name, sizeof name);
        if(strfind(name, "[KHK]", true, 0) != -1 || strfind(name, "[KHKr]", true, 0) != -1 || strfind(name, "[KHKa]", true, 0) != -1)
        {
            MATCHSYNC_SyncPlayerKills(i);
            MATCHSYNC_SyncPlayerDamage(i);
            MATCHSYNC_SyncPlayerAccuracy(i);
            MATCHSYNC_SyncPlayerRounds(i);
        }
    }
	return 1;
}

MATCHSYNC_InsertPlayer(playerid)
{
	new query[256];
	new _name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, _name, sizeof(_name));
	format(query, sizeof(query), "INSERT INTO Players (Name, Damage, Kills, Accuracy, Rounds) VALUES ('%s', %d, %d, %d, %d)", _name, Player[playerid][TotalDamage], Player[playerid][TotalKills], floatround(Player[playerid][TotalAccuracy]), Player[playerid][RoundPlayed]);
	mysql_query(query);
}

MATCHSYNC_UpdatePlayer(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, sizeof name);
	new query[256];
	format(query, sizeof(query), "UPDATE Players SET Damage=%d, Kills=%d, Accuracy=%d, Rounds=%d WHERE Name='%s'", MATCHSYNC_Damage[playerid], MATCHSYNC_Kills[playerid], MATCHSYNC_Accuracy[playerid], MATCHSYNC_Rounds[playerid], name);
	mysql_query(query);
	return 1;
}

#define WHEN_ROUND_END 0
#define WHEN_MATCH_END 1

MATCHSYNC_UpdateAllPlayers(when)
{
	if(WarMode == true)
	{
	    if((strlen(TeamName[ATTACKER]) <= 3 && !strcmp(TeamName[ATTACKER], "KHK", true, 3)) || (strlen(TeamName[DEFENDER]) <= 3 && !strcmp(TeamName[DEFENDER], "KHK", true, 3)))
		{
		    SendClientMessageToAll(-1, ""COL_PRIM"Match-sync: {FFFFFF}Syncing all players data before updating!");
			MATCHSYNC_SyncAllPlayers();
			SendClientMessageToAll(-1, ""COL_PRIM"Match-sync: {FFFFFF}Updating all players data...");
		    foreach(new i : Player)
		    {
		        new name[MAX_PLAYER_NAME];
		        GetPlayerName(i, name, sizeof name);
		        if(strfind(name, "[KHK]", true, 0) != -1 || strfind(name, "[KHKr]", true, 0) != -1 || strfind(name, "[KHKa]", true, 0) != -1)
		        {
		            if(MATCHSYNC_DoesNameExist(name) == 0)
	 					MATCHSYNC_InsertPlayer(i);
					else
					{
					    switch(when)
					    {
					        case WHEN_MATCH_END:
					        {
					            if(Player[i][RoundKills] == 0 && Player[i][RoundDamage] == 0 && floatround(Player[i][Accuracy]) == 0)
									goto skipped;
								MATCHSYNC_Kills[i] += Player[i][TotalKills];
								MATCHSYNC_Damage[i] += Player[i][TotalDamage];
								MATCHSYNC_Accuracy[i] += floatround(Player[i][TotalAccuracy]); // null
								MATCHSYNC_Rounds[i] += Player[i][RoundPlayed];
							}
							case WHEN_ROUND_END:
							{
							    if(Player[i][RoundKills] == 0 && Player[i][RoundDamage] == 0 && floatround(Player[i][Accuracy]) == 0)
									goto skipped;
							    MATCHSYNC_Kills[i] += Player[i][RoundKills];
								MATCHSYNC_Damage[i] += Player[i][RoundDamage];
								MATCHSYNC_Accuracy[i] += floatround(Player[i][Accuracy]);
								MATCHSYNC_Rounds[i] ++;
							}
						}
						MATCHSYNC_UpdatePlayer(i);
						skipped:
					}
		        }
		    }
		    SendClientMessageToAll(-1, ""COL_PRIM"Match-sync: {FFFFFF}Synced and updated all players data successfully!");
		}
	}
	return 1;
}

MATCHSYNC_InsertMatchStats()
{
    SendClientMessageToAll(-1, ""COL_PRIM"Match-sync: {FFFFFF}Uploading match stats to the MySQL database!");
	new winnerName[16], loserName[16], score[16];
	if(TeamScore[ATTACKER] > TeamScore[DEFENDER])
	{
	    format(winnerName, sizeof winnerName, "%s", TeamName[ATTACKER]);
	    format(loserName, sizeof loserName, "%s", TeamName[DEFENDER]);
	    format(score, sizeof score, "%d:%d", TeamScore[ATTACKER], TeamScore[DEFENDER]);
	}
	else if(TeamScore[DEFENDER] > TeamScore[ATTACKER])
	{
	    format(winnerName, sizeof winnerName, "%s", TeamName[DEFENDER]);
	    format(loserName, sizeof loserName, "%s", TeamName[ATTACKER]);
	    format(score, sizeof score, "%d:%d", TeamScore[DEFENDER], TeamScore[ATTACKER]);
	}
	else
	{
	    format(winnerName, sizeof winnerName, "%s", TeamName[ATTACKER]);
	    format(loserName, sizeof loserName, "%s", TeamName[DEFENDER]);
	    format(score, sizeof score, "%d:%d", TeamScore[ATTACKER], TeamScore[DEFENDER]);
	}
	new date[64];
    new Year, Month, Day;
	getdate(Year, Month, Day);
	new Hours, Minutes, Seconds;
	gettime(Hours, Minutes, Seconds);
	format(date, sizeof date, "[%02d/%02d/%d]:[%02d:%02d:%02d]", Day, Month, Year, Hours, Minutes, Seconds);
	new alAC[16];

 	format(alAC, sizeof alAC, "Was Off");

	new query[300];
	format(query, sizeof(query), "INSERT INTO Matches (TeamA, TeamB, Score, DateTime, AC) VALUES ('%s', '%s', '%s', '%s', '%s')", winnerName, loserName, score, date, alAC);
	mysql_query(query);
	SendClientMessageToAll(-1, ""COL_PRIM"Match-sync: {FFFFFF}Match stats has been uploaded successfully!");
}
#endif