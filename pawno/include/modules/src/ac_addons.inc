/*
		AC-related work
*/

#include "modules\header\ac_addons.txt"

public AC_OnFileExecuted(playerid, module[], md5[], bool:isCheat)
{
	// If it's a cheat file, ac is not enabled
	if(isCheat && !IsACEnabled())
	{
	    // Report it to other players
		new str[144];
		format(str, sizeof str, ""COL_PRIM"[AC] {FFFFFF}File execution report from "COL_PRIM"%s {FFFFFF}module: %s / blacklisted: Yes", Player[playerid][Name], module);
		SendClientMessageToAll(-1, str);
	}
	return 1;
}

public AC_OnImgFileModifed(playerid, filename[], md5[])
{
    // If it's a modified file, ac is not enabled
	if(!IsACEnabled())
	{
	    // Report it to other players
		new str[144];
		format(str, sizeof str, ""COL_PRIM"[AC] %s {FFFFFF}has got a modified IMG file "COL_PRIM"(%s)", Player[playerid][Name], filename);
		SendClientMessageToAll(-1, str);
	}
	return 1;
}

public AC_OnFileCalculated(playerid, filename[], md5[], bool:isCheat)
{
    // If it's a modified file, ac is not enabled
    if(isCheat && !IsACEnabled())
	{
	    // Report it to other players
		new str[144];
		format(str, sizeof str, ""COL_PRIM"[AC] {FFFFFF}File calculation report from "COL_PRIM"%s {FFFFFF}file: %s / blacklisted: Yes", Player[playerid][Name], filename);
		SendClientMessageToAll(-1, str);
	}
	return 1;
}

public AC_OnScreenshotTaken(playerid)
{
	new tick = GetTickCount();
	
	if((tick - PlayerACData[playerid][LastTakenScreenshot]) < SCREENSHOT_TAKE_INTERVAL_LIMIT)
	{
		PlayerACData[playerid][ScreenshotWarnings] ++;
		if(PlayerACData[playerid][ScreenshotWarnings] > SCREENSHOT_TAKE_MAX_WARNINGS)
		{
			new iString[144];
			format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has likely been abusing F8, so they're kicked!", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);

			SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
		}
	}
	else
	{
		PlayerACData[playerid][ScreenshotWarnings] = 0;
	}
	
	PlayerACData[playerid][LastTakenScreenshot] = tick;
	return 1;
}

public AC_OnPlayerPause(playerid, type, bool:pause)
{
	if(pause)
	{
		if(Player[playerid][Playing] && Player[playerid][WasInCP] && !RoundPaused)
		{
			new iString[144];
			format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has paused their game while in CP, so they were forced to leave it.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
			OnPlayerLeaveCheckpoint(playerid);
		}
	}
	return 1;
}

AC_FixServerHostname()
{
	if(strlen(hostname) == 0)
	{
		GetServerVarAsString("hostname", hostname, sizeof(hostname));
	}
	if(IsACPluginLoaded() && IsACEnabled())
	{
		format(hostname, sizeof hostname, "%s [AC]", hostname);
		SendRconCommand(sprintf("hostname %s", hostname));
	}
}