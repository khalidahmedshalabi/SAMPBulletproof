#define FILTERSCRIPT
#include <a_samp>
#if defined FILTERSCRIPT
public OnFilterScriptInit()
{
	print("\n--------");
	print("Radio loaded");
	print("----------\n");
	return 1;
}
#endif
public OnPlayerCommandText(playerid, cmdtext[])
{
if (strcmp("/radio", cmdtext, true, 10) == 0)
	{
    SendClientMessage(playerid,-1,"{FFFFFF}Error: {01A2F7}/radio[1/10] {FFFFFF}to change radio. {01A2F7}/radio0 {FFFFFF}to turn off radio");
	return 1;
}
if (strcmp("/radio1", cmdtext, true, 10) == 0)
	{
    PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=53630");
	return 1;
}
if (strcmp("/radio2", cmdtext, true, 10) == 0)
	{
    PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=31645");
	return 1;
}
if (strcmp("/radio3", cmdtext, true, 10) == 0)
	{
    PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=12337");
	return 1;
}
if (strcmp("/radio4", cmdtext, true, 10) == 0)
	{
    PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=914897");
	return 1;
}
if (strcmp("/radio5", cmdtext, true, 10) == 0)
	{
    PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=520036");
	return 1;
}
if (strcmp("/radio6", cmdtext, true, 10) == 0)
	{
    PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=611786");
	return 1;
}
if (strcmp("/radio7", cmdtext, true, 10) == 0)
	{
    PlayAudioStreamForPlayer(playerid, "http://cent4.serverhostingcenter.com/tunein.php/theaebn/playlist.pls");
	return 1;
}
if (strcmp("/radio8", cmdtext, true, 10) == 0)
	{
    PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=48370");
	return 1;
}
if (strcmp("/radio9", cmdtext, true, 10) == 0)
	{
    PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=1564322");
	return 1;
}
if (strcmp("/radio10", cmdtext, true, 10) == 0)
	{
    PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=57352");
	return 1;
}
if (strcmp("/radio0", cmdtext, true, 10) == 0)
	{
	SendClientMessage(playerid, -1, "{FFFFFF}Radio turned {FF2222}OFF");
    StopAudioStreamForPlayer(playerid);
	return 1;
}
return 0;
}


