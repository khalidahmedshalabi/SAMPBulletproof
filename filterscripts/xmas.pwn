#include <a_samp>
#include <maxplayers>

#include <YSI_inc\YSI\y_commands>
#include <YSI_inc\YSI\y_iterate>

new
	bool:SpawnedOnce[MAX_PLAYERS],
	bool:NoXmasHat[MAX_PLAYERS];

public OnFilterScriptInit()
{
	foreach(new i : Player)
	{
		DeleteSnow(i);
		StopAudioStreamForPlayer(i);
	    if(IsPlayerAttachedObjectSlotUsed(i, 1))
			RemovePlayerAttachedObject(i, 1);
			
        SpawnedOnce[i] = true;
        NoXmasHat[i] = false;
        SetPlayerTime(i, 23, 0);
        CreateSnow(i);
		SendClientMessage(i, -1, "{F54C4C}Merry Christmas! Check out {FFFFFF}/xmascmds {F54C4C}for some fun!");
		GiveChristmasHat(i, random(2));
	}
	return 1;
}

public OnFilterScriptExit()
{
    foreach(new i : Player)
	{
        SetPlayerTime(i, 9, 0);
        DeleteSnow(i);
		StopAudioStreamForPlayer(i);
	    if(IsPlayerAttachedObjectSlotUsed(i, 1))
			RemovePlayerAttachedObject(i, 1);
	}
	return 1;
}

public OnPlayerConnect(playerid)
{
	SpawnedOnce[playerid] = false;
	NoXmasHat[playerid] = false;
	return 1;
}

public OnPlayerSpawn(playerid)
{
	switch(SpawnedOnce[playerid])
	{
	    case false:
	    {
	        SpawnedOnce[playerid] = true;
	        SetPlayerTime(playerid, 23, 0);
	        CreateSnow(playerid);
			//PlayRandomXmasSong(playerid);
			SendClientMessage(playerid, -1, "{F54C4C}Merry Christmas! Check out {FFFFFF}/xmascmds {F54C4C}for some fun!");
	    }
	}
	if(NoXmasHat[playerid] != true)
		GiveChristmasHat(playerid, random(2));
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	Snow_OnDisconnect(playerid);
	return 1;
}


// A christmas script - I didn't make this I just tweaked it

#define MAX_SNOW_OBJECTS    3
#define SNOW_UPDATE_INTERVAL     1000

#define MAX_SLOTS MAX_PLAYERS

#define CB:%0(%1)           forward %0(%1); public %0(%1)

new
	bool:snowOn[MAX_SLOTS char],
	snowObject[MAX_SLOTS][MAX_SNOW_OBJECTS],
	updateTimer[MAX_SLOTS char];

Snow_OnDisconnect(playerid)
{
	if(snowOn{playerid})
	{
	    for(new i = 0; i < MAX_SNOW_OBJECTS; i++)
			DestroyPlayerObject(playerid, snowObject[playerid][i]);
		snowOn{playerid} = false;
		KillTimer(updateTimer{playerid});
	}
	return 1;
}

PlayRandomXmasSong(playerid)
{
	new i = random(4);
	switch(i)
	{
	    case 0:
	    {
	        PlayAudioStreamForPlayer(playerid, "http://mp3.ecsmedia.pl/track/music/00/00/04/40/65351932/1/6_30.mp3");
	    }
	    case 1:
	    {
            PlayAudioStreamForPlayer(playerid, "http://a.tumblr.com/tumblr_lvt3rdshTe1r7b27vo1.mp3");
	    }
	    case 2:
	    {
            PlayAudioStreamForPlayer(playerid, "http://www.panicstream.com/streams/temp/xmas/ultimate/1-02%20-%20Jingle%20Bell%20Rock.mp3");
	    }
	    case 3:
	    {
            PlayAudioStreamForPlayer(playerid, "http://www.turnbacktogod.com/wp-content/uploads/2008/12/rockin-around-the-christmas-tree.mp3");
	    }
	}
	return 1;
}

CB:UpdateSnow(playerid)
{
	if(!snowOn{playerid}) return 0;
	new Float:pPos[3];
	GetPlayerPos(playerid, pPos[0], pPos[1], pPos[2]);
	for(new i = 0; i < MAX_SNOW_OBJECTS; i++)
		SetPlayerObjectPos(playerid, snowObject[playerid][i], pPos[0] + random(25), pPos[1] + random(25), pPos[2] - 5 + random(10));
	return 1;
}

CreateSnow(playerid)
{
	if(snowOn{playerid}) return 0;
	new Float:pPos[3];
	GetPlayerPos(playerid, pPos[0], pPos[1], pPos[2]);
	for(new i = 0; i < MAX_SNOW_OBJECTS; i++)
		snowObject[playerid][i] = CreatePlayerObject(playerid, 18864, pPos[0] + random(25), pPos[1] + random (25), pPos[2] - 5 + random(10), random(280), random(280), 0);
	snowOn{playerid} = true;
	updateTimer{playerid} = SetTimerEx("UpdateSnow", SNOW_UPDATE_INTERVAL, true, "i", playerid);
	return 1;
}

DeleteSnow(playerid)
{
	if(!snowOn{playerid}) return 0;
	for(new i = 0; i < MAX_SNOW_OBJECTS; i++)
		DestroyPlayerObject(playerid, snowObject[playerid][i]);
	KillTimer(updateTimer{playerid});
	snowOn{playerid} = false;
	return 1;
}

CMD:snow(playerid, params[])
{
	if(snowOn{playerid})
	{
	    DeleteSnow(playerid);
	    SendClientMessage(playerid, -1, "It's not snowing anymore now.");
	}
	else
	{
	    CreateSnow(playerid);
	    SendClientMessage(playerid, -1, "Let it snow, let it snow, let it snow!");
	}
	return 1;
}

stock GiveChristmasHat(playerid,number)
{
	switch(number)
	{
		case 0:
		{
		    if(IsPlayerAttachedObjectSlotUsed(playerid,1))
				RemovePlayerAttachedObject(playerid,1);
		    SetPlayerAttachedObject(playerid, 1, 19065, 15, -0.025, -0.04, 0.23, 0, 0, 270, 2, 2, 2);
		}
		case 1:
		{
			if(IsPlayerAttachedObjectSlotUsed(playerid,1))
				RemovePlayerAttachedObject(playerid,1);
			SetPlayerAttachedObject(playerid, 1, 19065, 2, 0.120000, 0.040000, -0.003500, 0, 100, 100, 1.4, 1.4, 1.4);
		}
	}
}

CMD:xmascmds(playerid, params[])
{
	SendClientMessage(playerid, -1, "{F54C4C}Xmas commands: {FFFFFF}/xmasmusic, /stopxmasmusic, /snow, /removehat, /gethat");
	return 1;
}


CMD:removehat(playerid, params[])
{
    NoXmasHat[playerid] = true;
    if(IsPlayerAttachedObjectSlotUsed(playerid,1))
		RemovePlayerAttachedObject(playerid,1);
	return 1;
}

CMD:gethat(playerid, params[])
{
    NoXmasHat[playerid] = false;
    GiveChristmasHat(playerid, random(2));
	return 1;
}

CMD:xmasmusic(playerid, params[])
{
	PlayRandomXmasSong(playerid);
	return 1;
}

CMD:stopxmasmusic(playerid, params[])
{
	StopAudioStreamForPlayer(playerid);
	return 1;
}
