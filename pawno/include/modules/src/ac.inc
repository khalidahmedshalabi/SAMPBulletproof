/*
		AC-related work
*/

#include "modules\header\ac.txt"

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

public AC_OnFileCalculated(playerid, filename[], md5[], bool:isCheat)
{
	if(isCheat)
	{
		new str[180];
		format(str, sizeof str, "{FFFFFF}["COL_PRIM"AC{FFFFFF}] File calculation report from {FFFFFF}%s "COL_PRIM"/ module: {FFFFFF}%s "COL_PRIM"/ blacklisted: {FFFFFF}Yes", Player[playerid][Name], filename);
		SendClientMessageToAll(-1, str);
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
		format(hostname, sizeof hostname, "%s [AC-v2 ENABLED]", hostname);
		SendRconCommand(sprintf("hostname %s", hostname));
	}
}