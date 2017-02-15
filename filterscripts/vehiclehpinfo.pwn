#include <a_samp>
#include <strlib>
#include <YSI_inc\YSI\y_iterate>

new PlayerText:VInfo[MAX_PLAYERS];
new Iterator:PlayersInVehicles<MAX_PLAYERS>;

forward UpdateVehicleHealthTD();
public UpdateVehicleHealthTD()
{
    foreach(new i : PlayersInVehicles)
	{
		new Float:health;
		GetVehicleHealth(GetPlayerVehicleID(i), health);
		PlayerTextDrawSetString(i, VInfo[i], sprintf("Vehicle Health: ~r~%.0f%%", (health/1000.0) * 100.0));
	}
	return 1;
}

public OnPlayerConnect(playerid)
{
    VInfo[playerid] = CreatePlayerTextDraw(playerid,153.000000, 373.000000, "_");
	PlayerTextDrawBackgroundColor(playerid,VInfo[playerid], 0x00000044);
	PlayerTextDrawFont(playerid,VInfo[playerid], 1);
	PlayerTextDrawLetterSize(playerid,VInfo[playerid], 0.200000, 0.899999);
	PlayerTextDrawColor(playerid,VInfo[playerid], -1);
	PlayerTextDrawSetOutline(playerid,VInfo[playerid], 1);
	PlayerTextDrawSetProportional(playerid,VInfo[playerid], 1);
	return 1;
}

public OnFilterScriptInit()
{
    foreach(new i : Player)
	{
	    OnPlayerConnect(i);
	}
	SetTimer("UpdateVehicleHealthTD", 2000, true);
	return 1;
}

public OnFilterScriptExit()
{
	foreach(new i : Player)
	{
	    PlayerTextDrawDestroy(i, VInfo[i]);
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    if(newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER)
	{
		PlayerTextDrawSetString(playerid,VInfo[playerid], "_");
  		PlayerTextDrawShow(playerid, VInfo[playerid]);
	    Iter_Add(PlayersInVehicles, playerid);
	}
	else if(oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER)
	{
		PlayerTextDrawHide(playerid, VInfo[playerid]);
	    Iter_Remove(PlayersInVehicles,  playerid);
    }
    return 1;
}
