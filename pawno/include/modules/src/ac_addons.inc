/*
		AC-related work
*/

#include "modules\header\ac_addons.txt"

public AC_OnFileExecuted(playerid, module[], md5[], bool:isCheat)
{
	if(isCheat)
	{
		new str[180];
		format(str, sizeof str, "{FFFFFF}["COL_PRIM"AC{FFFFFF}] File execution report from {FFFFFF}%s "COL_PRIM"/ module: {FFFFFF}%s "COL_PRIM"/ blacklisted: {FFFFFF}Yes", Player[playerid][Name], module);
		SendClientMessageToAll(-1, str);
	}
	return 1;
}

public AC_OnImgFileModifed(playerid, filename[], md5[])
{
	new str[180];
	format(str, sizeof str, "{FFFFFF}["COL_PRIM"AC{FFFFFF}] {FFFFFF}%s "COL_PRIM"has got a modified IMG file {FFFFFF}(%s)", Player[playerid][Name], filename);
	SendClientMessageToAll(-1, str);
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
			new iString[128];
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

AC_FixServerHostname()
{
	if(strlen(hostname) == 0)
	{
		GetServerVarAsString("hostname", hostname, sizeof(hostname));
	}
	if(IsACPluginLoaded() && IsACEnabled())
	{
		format(hostname, sizeof hostname, "%s [ACv2 ENABLED]", hostname);
		SendRconCommand(sprintf("hostname %s", hostname));
	}
}