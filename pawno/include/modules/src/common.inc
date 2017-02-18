/*
		Common stuff
*/

#include "modules\header\common.txt"

#include "modules\header\player.txt"
#include "modules\header\textdraws.txt"
#include "modules\header\longarrays.txt"
#include "modules\header\colors.txt"
#include "modules\header\dialogs.txt"
#include "modules\header\match.txt"
#include "modules\header\config.txt"
#include "modules\header\global.txt"
#include "modules\header\spectate.txt"
#tryinclude "modules\header\league.txt"
#include "modules\header\weaponbinds.txt"
#include "modules\header\messagebox.txt"
#include "modules\header\deathcam.txt"

forward OnPlayerKicked(playerid);
public OnPlayerKicked(playerid) {
	Kick(playerid);
	return 1;
}

forward SendTipMessageToAll();
public SendTipMessageToAll()
{
	switch(random(16))
	{
		case 0:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Try different gunmenu styles with {FFFFFF}/gunmenustyle");
		}
		case 1:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Want to differentiate your team-mates on radar by color? Use {FFFFFF}/playermarkers");
		}
		case 2:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Use {FFFFFF}/weaponbinds "COL_TIP"to code your own weapon key binds.");
		}
		case 3:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"You can drop a gun by holding it and typing {FFFFFF}/remgun");
		}
		case 4:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"If you're lagging, you can request netcheck with {FFFFFF}/netcheckme");
		}
		case 5:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Disrespect noobs, use {FFFFFF}/deathdiss "COL_TIP"command.");
		}
		case 6:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Getting distracted by some textdraws? Try {FFFFFF}/hud");
		}
		case 7:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Enter no-clip camera mode with /freecam command.");
		}
		case 8:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Play in different duel arenas by means of 'custom' parameter in {FFFFFF}/duel "COL_TIP"command.");
		}
		case 9:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Use {FFFFFF}/cmdhelp [Command name] "COL_TIP"to get info about any command.");
		}
		case 10:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Change your hit sounds with {FFFFFF}/sound "COL_TIP"command.");
		}
		case 11:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Change your time and weather with {FFFFFF}/time "COL_TIP"and {FFFFFF}/weather "COL_TIP"commands.");
		}
		case 12:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Press 'Tab' key and click on a player for quicker operations/commands.");
		}
		case 13:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"You can change your skin with /skin while in lobby, DM or duel.");
		}
		case 14:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Switch round textdraws style with {FFFFFF}/style");
		}
		case 15:
		{
			SendClientMessageToAll(-1, ""COL_TIP_PRIM"Tips: "COL_TIP"Check {FFFFFF}/leaguecmds "COL_TIP"to know stuff about League.");
		}
	}
	return 1;
}

SendCommandHelpMessage(playerid, text[], messagebox_type = MSGBOX_TYPE_MIDDLE)
{
	if(messagebox_type < 0 || messagebox_type == MAX_MSGBOX_TYPES)
		return 0;
	MessageBox(playerid, messagebox_type, "~y~~h~Command Help", text, 5000);
	return 1;
}

SendErrorMessage(playerid, text[], messagebox_type = MSGBOX_TYPE_MIDDLE)
{
	if(messagebox_type < 0 || messagebox_type == MAX_MSGBOX_TYPES)
		return 0;

	switch(messagebox_type)
	{
		case MSGBOX_TYPE_MIDDLE:
		{
			new str[145];
			format(str, sizeof(str), "{CC0000}ERROR: {FFFFFF}%s", text);
			SendClientMessage(playerid, -1, str);
		}
		default:
		{
			PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);
			MessageBox(playerid, messagebox_type, "~r~~h~Error", text, 5000);
		}
	}
	return 1;
}

SendUsageMessage(playerid, text[], messagebox_type = MSGBOX_TYPE_MIDDLE)
{
	if(messagebox_type < 0 || messagebox_type == MAX_MSGBOX_TYPES)
		return 0;

	switch(messagebox_type)
	{
		case MSGBOX_TYPE_MIDDLE:
		{
			new str[145];
			format(str, sizeof(str), "{CCCCCC}USAGE: {FFFFFF}%s", text);
			SendClientMessage(playerid, -1, str);
		}
		default:
		{
			PlayerPlaySound(playerid, 5202, 0.0, 0.0, 0.0);
			MessageBox(playerid, messagebox_type, "~b~~h~Correct Syntax", text, 5000);
		}
	}
	return 1;
}

GetColor(color)
{
    new string[10];
    format(string,sizeof(string),"{%06x}",ShiftRGBAToRGB(color));
    return string;
}

GetPlayerCorrectMarkerCol(playerid, forplayerid)
{
	if(Player[forplayerid][PlayerMarkers] == true)
	{
		if(TeamHasLeader[Player[playerid][Team]] == true && TeamLeader[Player[playerid][Team]] == playerid)
		{
			return TEAM_LEADER_COLOUR;
		}
		else if(Player[playerid][AskingForHelp])
		{
			return (Player[playerid][Team] == ATTACKER ? ATTACKER_ASKING_HELP : DEFENDER_ASKING_HELP);
		}
		else
		{
			return PlayerColors[playerid];
		}
	}
	return GetPlayerColor(playerid);
}

// Checks all players and set idle players to afk mode
AutoAFKCheck()
{
	foreach(new i : Player)
	{
		if(Player[i][PauseCount] > 60 && !Player[i][IsAFK]) // If they've been away for more than 60 seconds
		{
			if(Player[i][Playing] == true)
				RemovePlayerFromRound(i);
			else if(Player[i][ToAddInRound] == true)
				Player[i][ToAddInRound] = false;
			else if(Player[i][Spectating] == true)
				StopSpectate(i);
			else if(Player[i][InDM] == true)
				QuitDM(i);

			Player[i][Team] = NON;
			SetPlayerColor(i, 0xAAAAAAAA);
			TogglePlayerControllable(i, 0);
			Player[i][IsAFK] = true;

			SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been set to AFK mode automatically due to one minute(+) of inactivity!", Player[i][Name]));
		}
	}
}

CreateDeadBody(playerid, killerid, reason, Float:distance = 0.0, Float:x = 0.0, Float:y = 0.0, Float:z = 0.0)
{
	if(!DeadBodies)
		return;

	if(x == 0.0 && y == 0.0 && z == 0.0)
	{
		GetPlayerPos(playerid, x, y, z);
	}
	if(distance == 0.0 && killerid != INVALID_PLAYER_ID)
	{
		distance = GetPlayerDistanceFromPoint(killerid, x, y, z);
	}
	new Float:angle;
	GetPlayerFacingAngle(playerid, angle);
	new actorid = CreateActor(GetPlayerSkin(playerid), x, y, z, angle);
	SetActorInvulnerable(actorid, 0);
	SetActorHealth(actorid, 0.0);
	new worldid = GetPlayerVirtualWorld(playerid);
	SetActorVirtualWorld(actorid, worldid);
	Iter_Add(DeadBodyActors, actorid);
	new color = 0xFFFFFFFF;
	switch(Player[playerid][Team])
	{
		case ATTACKER:
		{
			color = 0xF58E8EFF;
		}
		case DEFENDER:
		{
			color = 0x8E9CF5FF;
		}
	}
	switch(killerid)
	{
		case INVALID_PLAYER_ID:
		{
			new str[80];
			format(str, sizeof str, "Dead body of: %s\nReason: %s", Player[playerid][Name], WeaponNames[reason]);
			new Text3D:textlabel = Create3DTextLabel(str, color, x, y, z - 0.3, 20.0, worldid, 1);
			Iter_Add(DeadBodyLabels, _:textlabel);
		}
		default:
		{
			new str[140];
			format(str, sizeof str, "Dead body of: %s\nMurderer: %s\nDistance: %.1f\nReason: %s", Player[playerid][Name], Player[killerid][Name], distance, WeaponNames[reason]);
			new Text3D:textlabel = Create3DTextLabel(str, color, x, y, z - 0.3, 20.0, worldid, 1);
			Iter_Add(DeadBodyLabels, _:textlabel);
		}
	}
}

DeleteAllDeadBodies()
{
	if(!DeadBodies)
		return;

	if(Iter_Count(DeadBodyLabels) != 0)
	{
		foreach(new i : DeadBodyLabels)
		{
			Delete3DTextLabel(Text3D:i);
		}
		Iter_Clear(DeadBodyLabels);
	}
	if(Iter_Count(DeadBodyActors) != 0)
	{
		foreach(new i : DeadBodyActors)
			DestroyActor(i);

		Iter_Clear(DeadBodyActors);
	}
}

CheckPlayerNet(playerid)
{
	if(Player[playerid][FPS] < Min_FPS && Player[playerid][PauseCount] < 5 && Player[playerid][FPSCheck] == 1)
	{
		Player[playerid][FPSKick] ++;
		SendClientMessage(playerid, -1, sprintf("{FF756D}Low FPS! Warning %d/7 - use /netcheckme", Player[playerid][FPSKick]));

		if (Player[playerid][FPSKick] == 7)
		{
			SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been kicked from the server .: {FFFFFF}Low FPS | %d/%d "COL_PRIM":.", Player[playerid][Name], Player[playerid][FPS], Min_FPS));
			SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
		}
	}
	else
	{
		Player[playerid][FPSKick] = 0;
	}

	if(NetStats_PacketLossPercent(playerid) >= Max_Packetloss && Player[playerid][FakePacketRenovation] == false && Player[playerid][PLCheck] == 1)
	{
		Player[playerid][PacketKick]++;
		SendClientMessage(playerid, -1, sprintf("{FF756D}High PL! Warning %d/15 - use /netcheckme", Player[playerid][PacketKick]));

		if(Player[playerid][PacketKick] == 15)
		{
			SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been kicked from the server .: {FFFFFF}High Packetloss | %.2f/%.2f "COL_PRIM":.", Player[playerid][Name], NetStats_PacketLossPercent(playerid), Max_Packetloss));
			SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
		}
	}
	else
	{
		Player[playerid][PacketKick] = 0;
	}

	if(GetPlayerPing(playerid) >= Max_Ping && Player[playerid][PingCheck] == 1)
	{
		Player[playerid][PingKick]++;
		SendClientMessage(playerid, -1, sprintf("{FF756D}High Ping! Warning %d/10 - use /netcheckme", Player[playerid][PingKick]));

		if(Player[playerid][PingKick] == 10)
		{
			SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been kicked from the server .: {FFFFFF}High Ping | %d/%d "COL_PRIM":.", Player[playerid][Name], GetPlayerPing(playerid), Max_Ping));
			SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
		}
	}
	else
	{
		Player[playerid][PingKick] = 0;
	}
}

bool:IsValidWeapon(weaponid)
{
    if((weaponid > 0 && weaponid < 19) || (weaponid > 21 && weaponid < 47) && weaponid != 40)
		return true;
    return false;
}

IsValidSkin(skinid)
	return (!(skinid < 0 || skinid > 299 || skinid == 74 || skinid >= 265 && skinid <= 272));

stock GetPlayerSpeed(playerid)
{
    new Float:velocity[4];
    GetPlayerVelocity(playerid,velocity[0],velocity[1],velocity[2]);
    velocity[3] = floatsqroot(floatpower(floatabs(velocity[0]), 2.0) + floatpower(floatabs(velocity[1]), 2.0) + floatpower(floatabs(velocity[2]), 2.0)) * 179.28625;
    return floatround(velocity[3]);
}

ShowPlayerClassSelection(playerid)
{
	new
		str[320],
		ct[5];

	foreach(new i : Player)
	{
		if(i == playerid)
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
			case REFEREE:
			{
				ct[2] ++;
			}
			case ATTACKER_SUB:
			{
				ct[3] ++;
			}
			case DEFENDER_SUB:
			{
				ct[4] ++;
			}
		}
	}
	format(str, sizeof(str),
		"Team\tAccessibility\tMembers Count\n{FFFFFF}Auto-assign\tN/A\tN/A\n%s%s{FFFFFF}\t%s\t%d\n%s%s{FFFFFF}\t%s\t%d\n%s%s{FFFFFF}\t%s\t%d\n%s%s{FFFFFF}\t%s\t%d\n%s%s{FFFFFF}\t%s\t%d",
		TextColor[ATTACKER], TeamName[ATTACKER], strlen(GroupAccessPassword[ATTACKER - 1]) > 0 ? ("{FF6666}Locked (password required)") : ("{66FF66}Open"), ct[0],
		TextColor[DEFENDER], TeamName[DEFENDER], strlen(GroupAccessPassword[DEFENDER - 1]) > 0 ? ("{FF6666}Locked (password required)") : ("{66FF66}Open"), ct[1],
		TextColor[REFEREE], TeamName[REFEREE], strlen(GroupAccessPassword[REFEREE - 1]) > 0 ? ("{FF6666}Locked (password required)") : ("{66FF66}Open"), ct[2],
		TextColor[ATTACKER_SUB], TeamName[ATTACKER_SUB], strlen(GroupAccessPassword[ATTACKER_SUB - 1]) > 0 ? ("{FF6666}Locked (password required)") : ("{66FF66}Open"), ct[3],
		TextColor[DEFENDER_SUB], TeamName[DEFENDER_SUB], strlen(GroupAccessPassword[DEFENDER_SUB - 1]) > 0 ? ("{FF6666}Locked (password required)") : ("{66FF66}Open"), ct[4]);

	ShowPlayerDialog(playerid, DIALOG_TEAM_SELECTION, DIALOG_STYLE_TABLIST_HEADERS, "Team Selection", str, "Spawn", "");
}

forward SpawnConnectedPlayer(playerid, team);
public SpawnConnectedPlayer(playerid, team)
{
	switch(team)
	{
		case 0: // auto-assign
		{
			switch(WarMode)
			{
				case false:
				{
					Player[playerid][Team] = GetTeamWithLessPlayers();
				}
				case true:
				{
					if(strfind(Player[playerid][Name], TeamName[ATTACKER], true) != -1)
						Player[playerid][Team] = ATTACKER;
					else if(strfind(Player[playerid][Name], TeamName[DEFENDER], true) != -1)
						Player[playerid][Team] = DEFENDER;
					else
						Player[playerid][Team] = GetTeamWithLessPlayers();
				}
			}
		}
		case 1:
		{
			Player[playerid][Team] = ATTACKER;
		}
		case 2:
		{
			Player[playerid][Team] = DEFENDER;
		}
		case 3:
		{
			Player[playerid][Team] = REFEREE;
		}
		case 4:
		{
			Player[playerid][Team] = ATTACKER_SUB;
		}
		case 5:
		{
			Player[playerid][Team] = DEFENDER_SUB;
		}
	}

	SwitchTeamFix(playerid, false, false, false);
	SetPlayerWeather(playerid, Player[playerid][Weather]);
	SetPlayerTime(playerid, Player[playerid][Time], 0);

	ShowPlayerProgressBar(playerid, HealthBar[playerid]);
	switch(PlayerInterface[playerid][INTERFACE_HP])
	{
		case true:
		{
			PlayerTextDrawShow(playerid, HPTextDraw_TD[playerid]);
			PlayerTextDrawShow(playerid, ArmourTextDraw[playerid]);
		}
		case false:
		{
			PlayerTextDrawHide(playerid, HPTextDraw_TD[playerid]);
			PlayerTextDrawHide(playerid, ArmourTextDraw[playerid]);
		}
	}
	PlayerTextDrawShow(playerid, BaseID_VS[playerid]);

	switch(PlayerInterface[playerid][INTERFACE_NET])
	{
		case true:
		{
			PlayerTextDrawShow(playerid, FPSPingPacket[playerid]);
		}
		case false:
		{
			PlayerTextDrawHide(playerid, FPSPingPacket[playerid]);
		}
	}
	PlayerTextDrawShow(playerid, RoundKillDmgTDmg[playerid]);

	if(Current != -1)
	{
		ShowRoundStats(playerid);
	}

	if(PlayerInterface[playerid][INTERFACE_SPEC])
	{
		PlayerTextDrawShow(playerid, WhoSpec[playerid]);
	}
	else
	{
		PlayerTextDrawHide(playerid, WhoSpec[playerid]);
	}

	TextDrawShowForPlayer(playerid, TeamHpLose[0]);
	TextDrawShowForPlayer(playerid, TeamHpLose[1]);
	TextDrawShowForPlayer(playerid, AttHpLose);
	TextDrawShowForPlayer(playerid, DefHpLose);

	PlayerTextDrawShow(playerid, TD_RoundSpec[playerid]);
	PlayerTextDrawShow(playerid, HPTextDraw_TD[playerid]);
	PlayerTextDrawShow(playerid, ArmourTextDraw[playerid]);
	PlayerTextDrawShow(playerid, BaseID_VS[playerid]);
	#if defined _league_included
	if(LeagueMode)
	{
		if(Player[playerid][LeagueLogged])
		{
			RefreshPlayerLeagueData(playerid);
			PlayerTextDrawShow(playerid, PlayerLeagueStatsTD[playerid]);
		}
	}
	HideIntroTextDraws(playerid);
	#endif

	if(WarMode == true)
	{
		ShowMatchScoreBoard(playerid);
	}

	Player[playerid][Spawned] = true;
	SpawnInLobby(playerid);

	HideAllTeamBarsForPlayer(playerid);

	LoadPlayerVariables(playerid);
	return 1;
}

SpawnInLobby(playerid)
{
    SetSpawnInfo(playerid, playerid, Skin[Player[playerid][Team]], MainSpawn[0] + random(3), MainSpawn[1] + random(3), MainSpawn[2] + 2, 0, 0, 0, 0, 0, 0, 0);
	if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)TogglePlayerSpectating(playerid, false);
	else SpawnPlayer(playerid);
}

ShowPlayerDeathMessage(killerid, playerid)
{
	if(!Player[killerid][HasDeathQuote] || !DeathCamera)
	{
	    return 0;
	}
	MessageBox(playerid, MSGBOX_TYPE_MIDDLE, sprintf("%s~h~%s ~w~is dissing you", TDC[Player[killerid][Team]], Player[killerid][Name]), sprintf("%s", DeathMessageStr[killerid]), DEATH_CAMERA_DURATION);
	return 1;
}

udb_hash(buf[]) {
    new length=strlen(buf);
    new s1 = 1;
    new s2 = 0;
    new n;
    for (n=0; n<length; n++)
    {
       s1 = (s1 + buf[n]) % 65521;
       s2 = (s2 + s1)     % 65521;
    }
    return (s2 << 16) + s1;
}

RecountPlayersOnCP()
{
	PlayersInCP = 0;

	if(GameType == BASE || (GameType == ARENA && CPInArena))
	{
		foreach(new i : PlayersInRound)
		{
			Player[i][WasInCP] = false;
	    	if(IsPlayerInCheckpoint(i))
	    	{
	        	OnPlayerEnterCheckpoint(i);
			}
		}
	}

	if(PlayersInCP == 0)
	{
		TeamCapturingCP = NON;
	    CurrentCPTime = ConfigCPTime + 1;
	    TextDrawHideForAll(EN_CheckPoint);
		TextDrawColor(timerCircleTD, 0x00000033);
		foreach(new i : Player)
		{
			if(!Player[i][Spawned])
				continue;

			if(Player[i][RoundTDStyle] != 1)
	            continue;

			TextDrawShowForPlayer(i, timerCircleTD);
		}
	}
	return PlayersInCP;
}

RemoveVendingMachinesForPlayer(playerid)
{
	RemoveBuildingForPlayer(playerid, 955, 0.0, 0.0, 0.0, 20000.0); // CJ_EXT_SPRUNK
	RemoveBuildingForPlayer(playerid, 956, 0.0, 0.0, 0.0, 20000.0); // CJ_EXT_CANDY
	RemoveBuildingForPlayer(playerid, 1209, 0.0, 0.0, 0.0, 20000.0); // vendmach
	RemoveBuildingForPlayer(playerid, 1302, 0.0, 0.0, 0.0, 20000.0); // vendmachfd
	RemoveBuildingForPlayer(playerid, 1775, 0.0, 0.0, 0.0, 20000.0); // CJ_SPRUNK1
	RemoveBuildingForPlayer(playerid, 1776, 0.0, 0.0, 0.0, 20000.0); // CJ_CANDYVENDOR
	RemoveBuildingForPlayer(playerid, 1977, 0.0, 0.0, 0.0, 20000.0); // vendin3
}

RemoveUselessObjectsForPlayer(playerid)
{
	RemoveVendingMachinesForPlayer(playerid);
    RemoveBuildingForPlayer(playerid, 1220, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1221, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1230, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1299, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1421, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1448, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1449, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1450, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1440, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1421, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1438, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1338, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1219, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1676, 0.0, 0.0, 0.0, 6000.0); // exploding gas tank
	RemoveBuildingForPlayer(playerid, 1686, 0.0, 0.0, 0.0, 6000.0);
	return 1;
}
/*
randomExFloat(Float:min, Float:max)
{
	new rand = random(floatround(max-min, floatround_round))+floatround(min, floatround_round);
	return rand;
}
*/
randomExInt(min, max)
{
	return random(max-min) + min;
}

/*
Function: LogAdminCommand
cmd[]: the entered command
adminid: the admin who enters the command
playerid: the player who the command hits (use INVALID_PLAYER_ID to ignore this)
*/
LogAdminCommand(cmd[], adminid, playerid)
{
	new File:log = fopen("admin_command_log.txt", io_append);
	new Year, Month, Day;
	getdate(Year, Month, Day);
	new Hours, Minutes, Seconds;
	gettime(Hours, Minutes, Seconds);
  	if(playerid != INVALID_PLAYER_ID)
  	{
		fwrite(log, sprintf("[%02d/%02d/%d][%02d:%02d:%02d] %s [%d] has used the command (/%s) at %s [%d]. \r\n", Day, Month, Year, Hours, Minutes, Seconds, Player[adminid][Name], adminid, cmd, Player[playerid][Name], playerid));
   	}
  	else
	{
		fwrite(log, sprintf("[%02d/%02d/%d][%02d:%02d:%02d] %s [%d] has used the command (/%s). \r\n", Day, Month, Year, Hours, Minutes, Seconds, Player[adminid][Name], adminid, cmd));
  	}
  	fclose(log);
  	return 1;
}

ClearAdminCommandLog()
{
    new File:log = fopen("admin_command_log.txt", io_write);
    fwrite(log, "");
    fclose(log);
	return 1;
}

forward HideTargetInfo(playerid);
public HideTargetInfo(playerid)
{
    TargetInfoData[playerid][TargetInfoTimer] = -1;
	PlayerTextDrawHide(playerid, TargetInfoData[playerid][TargetInfoTD]);
	return 1;
}

ShowTargetInfo(playerid, targetid)
{
	if(targetid == INVALID_PLAYER_ID || playerid == INVALID_PLAYER_ID)
		return 1;

	if(targetid == TargetInfoData[playerid][TargetInfoLastTarget] && GetTickCount() < TargetInfoData[playerid][TargetInfoLastTick])
		return 1;

	new str[128];
	format(str, sizeof str, "%sName: %s%s~n~%sPing: %s%d   %sFPS: %s%d~n~%sPL: %s%.1f   %sHP: %s%d",
		MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], Player[targetid][NameWithoutTag], MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]],
		GetPlayerPing(targetid), MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], Player[targetid][FPS], MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], NetStats_PacketLossPercent(targetid), MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], (Player[targetid][pHealth] + Player[targetid][pArmour]));

	PlayerTextDrawSetString(playerid, TargetInfoData[playerid][TargetInfoTD], str);
	PlayerTextDrawShow(playerid, TargetInfoData[playerid][TargetInfoTD]);
	TargetInfoData[playerid][TargetInfoLastTick] = GetTickCount() + 2000;
	TargetInfoData[playerid][TargetInfoLastTarget] = targetid;

	if(TargetInfoData[playerid][TargetInfoTimer] == -1)
	{
		 TargetInfoData[playerid][TargetInfoTimer] = SetTimerEx("HideTargetInfo", 5000, false, "i", playerid);
	}
	return 1;
}

forward HideAnnForAll();
public HideAnnForAll()
{
	TextDrawHideForAll(AnnTD);
}

CanPlay(playerid)
{
    if(Player[playerid][InDuel] == true || Player[playerid][IsAFK] || !Player[playerid][Spawned])
		return 0;

    if(!(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
		return 0; // can not play

	return 1; // can play
}

IsValidSound(soundid) {
	for(new i=0; i < sizeof(ValidSounds); ++i) {
		if(ValidSounds[i] == soundid) return 1;
	}
	return 0;
}

GetWeaponID(weaponname[]) {
    for(new i = 0; i < 55; ++i) {
        if(strfind(WeaponNames[i], weaponname, true) != -1)
        return i;
    }
    return -1;
}
/*
GetWeaponIDFromModelID(modelid)
{
	new weaponid = 0xFFFF;
	switch(modelid)
	{
		case 373:
		{
			weaponid = 0;
		}
		case 331:
		{
			weaponid = 1;
		}
		case 333:
		{
			weaponid = 2;
		}
		case 334:
		{
			weaponid = 3;
		}
		case 335:
		{
			weaponid = 4;
		}
		case 336:
		{
			weaponid = 5;
		}
		case 337:
		{
			weaponid = 6;
		}
		case 338:
		{
			weaponid = 7;
		}
		case 339:
		{
			weaponid = 8;
		}
		case 341:
		{
			weaponid = 9;
		}
		case 321:
		{
			weaponid = 10;
		}
		case 322:
		{
			weaponid = 11;
		}
		case 323:
		{
			weaponid = 12;
		}
		case 324:
		{
			weaponid = 13;
		}
		case 325:
		{
			weaponid = 14;
		}
		case 326:
		{
			weaponid = 15;
		}
		case 342:
		{
			weaponid = 16;
		}
		case 343:
		{
			weaponid = 17;
		}
		case 344:
		{
			weaponid = 18;
		}
		case 346:
		{
			weaponid = 22;
		}
		case 347:
		{
			weaponid = 23;
		}
		case 348:
		{
			weaponid = 24;
		}
		case 349:
		{
			weaponid = 25;
		}
		case 350:
		{
			weaponid = 26;
		}
		case 351:
		{
			weaponid = 27;
		}
		case 352:
		{
			weaponid = 28;
		}
		case 353:
		{
			weaponid = 29;
		}
		case 355:
		{
			weaponid = 30;
		}
		case 356:
		{
			weaponid = 31;
		}
		case 372:
		{
			weaponid = 32;
		}
		case 357:
		{
			weaponid = 33;
		}
		case 358:
		{
			weaponid = 34;
		}
		case 359:
		{
			weaponid = 35;
		}
		case 360:
		{
			weaponid = 36;
		}
		case 361:
		{
			weaponid = 37;
		}
		case 362:
		{
			weaponid = 38;
		}
		case 363:
		{
			weaponid = 39;
		}
		case 364:
		{
			weaponid = 40;
		}
		case 365:
		{
			weaponid = 41;
		}
		case 366:
		{
			weaponid = 42;
		}
		case 367:
		{
			weaponid = 43;
		}
		case 368:
		{
			weaponid = 44;
		}
		case 369:
		{
			weaponid = 45;
		}
		case 371:
		{
			weaponid = 46;
		}
	}
	return weaponid;
}*/

GetWeaponModelFromID(weaponid)
{
    new model = -1;
    switch(weaponid)
    {
        case 1: model=331; case 2: model=333; case 3: model=334;
        case 4: model=335; case 5: model=336; case 6: model=337;
        case 7: model=338; case 8: model=339; case 9: model=341;
        case 10: model=321; case 11: model=322; case 12: model=323;
        case 13: model=324; case 14: model=325; case 15: model=326;
        case 16: model=342; case 17: model=343; case 18: model=344;
        case 22: model=346; case 23: model=347; case 24: model=348;
        case 25: model=349; case 26: model=350; case 27: model=351;
        case 28: model=352; case 29: model=353; case 30: model=355;
        case 31: model=356; case 32: model=372; case 33: model=357;
        case 34: model=358; case 35: model=359; case 36: model=360;
        case 37: model=361; case 38: model=362; case 39: model=363;
        case 41: model=365; case 42: model=366; case 46: model=371;
    }
    return model;
}

sscanf(string[], format[], {Float,_}:...)
{
	#if defined isnull
		if (isnull(string))
	#else
		if (string[0] == 0 || (string[0] == 1 && string[1] == 0))
	#endif
		{
			return format[0];
		}
	#pragma tabsize 4
	new
		formatPos = 0,
		stringPos = 0,
		paramPos = 2,
		paramCount = numargs(),
		delim = ' ';
	while (string[stringPos] && string[stringPos] <= ' ')
	{
		stringPos++;
	}
	while (paramPos < paramCount && string[stringPos])
	{
		switch (format[formatPos++])
		{
			case '\0':
			{
				return 0;
			}
			case 'i', 'd':
			{
				new
					neg = 1,
					num = 0,
					ch = string[stringPos];
				if (ch == '-')
				{
					neg = -1;
					ch = string[++stringPos];
				}
				do
				{
					stringPos++;
					if ('0' <= ch <= '9')
					{
						num = (num * 10) + (ch - '0');
					}
					else
					{
						return -1;
					}
				}
				while ((ch = string[stringPos]) > ' ' && ch != delim);
				setarg(paramPos, 0, num * neg);
			}
			case 'h', 'x':
			{
				new
					num = 0,
					ch = string[stringPos];
				do
				{
					stringPos++;
					switch (ch)
					{
						case 'x', 'X':
						{
							num = 0;
							continue;
						}
						case '0' .. '9':
						{
							num = (num << 4) | (ch - '0');
						}
						case 'a' .. 'f':
						{
							num = (num << 4) | (ch - ('a' - 10));
						}
						case 'A' .. 'F':
						{
							num = (num << 4) | (ch - ('A' - 10));
						}
						default:
						{
							return -1;
						}
					}
				}
				while ((ch = string[stringPos]) > ' ' && ch != delim);
				setarg(paramPos, 0, num);
			}
			case 'c':
			{
				setarg(paramPos, 0, string[stringPos++]);
			}
			case 'f':
			{

				new changestr[256], changepos = 0, strpos = stringPos;
				while(changepos < 16 && string[strpos] && string[strpos] != delim)
				{
					changestr[changepos++] = string[strpos++];
    				}
				changestr[changepos] = '\0';
				setarg(paramPos,0,_:floatstr(changestr));
			}
			case 'p':
			{
				delim = format[formatPos++];
				continue;
			}
			case '\'':
			{
				new
					end = formatPos - 1,
					ch;
				while ((ch = format[++end]) && ch != '\'') {}
				if (!ch)
				{
					return -1;
				}
				format[end] = '\0';
				if ((ch = strfind(string, format[formatPos], false, stringPos)) == -1)
				{
					if (format[end + 1])
					{
						return -1;
					}
					return 0;
				}
				format[end] = '\'';
				stringPos = ch + (end - formatPos);
				formatPos = end + 1;
			}
			case 'u':
			{
				new
					end = stringPos - 1,
					id = 0,
					bool:num = true,
					ch;
				while ((ch = string[++end]) && ch != delim)
				{
					if (num)
					{
						if ('0' <= ch <= '9')
						{
							id = (id * 10) + (ch - '0');
						}
						else
						{
							num = false;
						}
					}
				}
				if (num && IsPlayerConnected(id))
				{
					setarg(paramPos, 0, id);
				}
				else
				{
					#if !defined foreach
						#define foreach(%1,%2) for (new %2 = 0; %2 < MAX_PLAYERS; %2++) if (IsPlayerConnected(%2))
						#define __SSCANF_FOREACH__
					#endif
					string[end] = '\0';
					num = false;
					new
						name[MAX_PLAYER_NAME];
					id = end - stringPos;
					foreach (new playerid : Player)
					{
						GetPlayerName(playerid, name, sizeof (name));
						if (!strcmp(name, string[stringPos], true, id))
						{
							setarg(paramPos, 0, playerid);
							num = true;
							break;
						}
					}
					if (!num)
					{
						setarg(paramPos, 0, INVALID_PLAYER_ID);
					}
					string[end] = ch;
					#if defined __SSCANF_FOREACH__
						#undef foreach
						#undef __SSCANF_FOREACH__
					#endif
				}
				stringPos = end;
			}
			case 's', 'z':
			{
				new
					i = 0,
					ch;
				if (format[formatPos])
				{
					while ((ch = string[stringPos++]) && ch != delim)
					{
						setarg(paramPos, i++, ch);
					}
					if (!i)
					{
						return -1;
					}
				}
				else
				{
					while ((ch = string[stringPos++]))
					{
						setarg(paramPos, i++, ch);
					}
				}
				stringPos--;
				setarg(paramPos, i, '\0');
			}
			default:
			{
				continue;
			}
		}
		while (string[stringPos] && string[stringPos] != delim && string[stringPos] > ' ')
		{
			stringPos++;
		}
		while (string[stringPos] && (string[stringPos] == delim || string[stringPos] <= ' '))
		{
			stringPos++;
		}
		paramPos++;
	}
	do
	{
		if ((delim = format[formatPos++]) > ' ')
		{
			if (delim == '\'')
			{
				while ((delim = format[formatPos++]) && delim != '\'') {}
			}
			else if (delim != 'z')
			{
				return delim;
			}
		}
	}
	while (delim > ' ');
	return 0;
}

OnPlayerAmmoUpdate(playerid)
{
	if(Player[playerid][Playing] == true)
	{
	    new weapons;
		new Ammo, TotalShots, Float:accuracy;

		for(new k=2; k < 8; ++k)
		{
			GetPlayerWeaponData(playerid, k, weapons, Ammo);
			if(Ammo > 10)
			{
				TotalShots += (9999 - Ammo);
			}
		}

		if(TotalShots == 0)
			accuracy = 0.0;
		else
			accuracy = floatmul(100.0, floatdiv(Player[playerid][shotsHit], TotalShots));

		Player[playerid][TotalBulletsFired] += TotalShots;
  		Player[playerid][TotalshotsHit] += Player[playerid][shotsHit];
		Player[playerid][Accuracy] = accuracy;
		Player[playerid][TotalAccuracy] += accuracy;
	}
}

GetWeaponSlot(weaponid)
{
	new slot;
	switch(weaponid)
	{
		case 0,1: slot = 0;
		case 2 .. 9: slot = 1;
		case 10 .. 15: slot = 10;
		case 16 .. 18, 39: slot = 8;
		case 22 .. 24: slot =2;
		case 25 .. 27: slot = 3;
		case 28, 29, 32: slot = 4;
		case 30, 31: slot = 5;
		case 33, 34: slot = 6;
		case 35 .. 38: slot = 7;
		case 40: slot = 12;
		case 41 .. 43: slot = 9;
		case 44 .. 46: slot = 11;
	}
	return slot;
}

bool:DoesPlayerHaveWeaponInSlot(playerid, slot)
{
	new wep, ammo;
	GetPlayerWeaponData(playerid, slot, wep, ammo);
	if(ammo > 0)
		return true;
	return false;
}

bool:DoesPlayerHaveWeapon(playerid, weaponid)
{
	new wep, ammo;
	GetPlayerWeaponData(playerid, GetWeaponSlot(weaponid), wep, ammo);
	if(wep == weaponid && ammo > 0)
	{
		return true;
	}
	return false;
}

RemovePlayerWeapon(playerid, weaponid)
{
	if(!DoesPlayerHaveWeapon(playerid, weaponid))
		return 0;

	new plyWeapons[12];
	new plyAmmo[12], armedID;

	new wep, ammo;
	for(new slot = 0; slot != 12; slot++)
	{
		GetPlayerWeaponData(playerid, slot, wep, ammo);

		if(wep != weaponid)
		{
			GetPlayerWeaponData(playerid, slot, plyWeapons[slot], plyAmmo[slot]);
		}
	}

	armedID = GetPlayerWeapon(playerid);

	ResetPlayerWeapons(playerid);
	for(new slot = 0; slot != 12; slot++)
	{
		GivePlayerWeapon(playerid, plyWeapons[slot], plyAmmo[slot]);
	}

	if( armedID != weaponid ) SetPlayerArmedWeapon(playerid,armedID); //give last armedweapon
	else SetPlayerArmedWeapon(playerid,0);//give fist if player armed weapon was knife
	return 1;
}

GetCardinalPoint(Float:degree)
{
    // this function return a string that contain the Cardinal point of a heading direction

	// Create string and initialize it to hold the direction text
    new CardinalPoint[11];
	CardinalPoint[0] = EOS;

	/*
		From SA:MP wiki

		"Angles are reversed in GTA:SA; 90 degrees would be
		East in the real world, but in GTA:SA 90 degrees is
		in fact West. North and South are still 0/360 and 180
	*/
	degree = 360.0 - degree; // correct conversion

    // each cardinal point cover 45degree (45 X 8 = 360)
    if(337.5 <= degree <= 360) strcat(CardinalPoint,"North");
    else if(0 <= degree <= 22.5) strcat(CardinalPoint,"North");
    else if(22.5 <= degree <= 67.5) strcat(CardinalPoint,"North East");
    else if(67.5 <= degree <= 112.5) strcat(CardinalPoint,"East");
    else if(112.5 <= degree <= 157.5) strcat(CardinalPoint,"South East");
    else if(157.5 <= degree <= 202.5) strcat(CardinalPoint,"South");
    else if(202.5 <= degree <= 247.5) strcat(CardinalPoint,"South West");
    else if(247.5 <= degree <= 292.5) strcat(CardinalPoint,"West");
    else if(292.5 <= degree <= 337.5) strcat(CardinalPoint,"North West");
    else strcat(CardinalPoint,"Unknown"); // error

    return CardinalPoint;// we return our string
}

SwapTeams()
{
	new MyVehicle = -1;
	new Seat;
	new Iterator:ToFixSwitch<MAX_PLAYERS>;
	foreach(new i : Player) {
		if(Player[i][Team] == ATTACKER) Player[i][Team] = DEFENDER;
		else if(Player[i][Team] == ATTACKER_SUB) Player[i][Team] = DEFENDER_SUB;
		else if(Player[i][Team] == DEFENDER) Player[i][Team] = ATTACKER;
        else if(Player[i][Team] == DEFENDER_SUB) Player[i][Team] = ATTACKER_SUB;

		MyVehicle = GetPlayerVehicleID(i);
		if(MyVehicle)
		{
			Seat = GetPlayerVehicleSeat(i);
		}

		if(MyVehicle != -1) {
		    PutPlayerInVehicle(i, MyVehicle, Seat);
		}
		Iter_Add(ToFixSwitch, i);
	}

    for(new i=0; i < SAVE_SLOTS; ++i) {
        if(strlen(SaveVariables[i][pName]) > 2) {
			if(SaveVariables[i][pTeam] == ATTACKER) SaveVariables[i][pTeam] = DEFENDER;
			else if(SaveVariables[i][pTeam] == DEFENDER) SaveVariables[i][pTeam] = ATTACKER;
        }
    }

	new TempScore;
	TempScore = TeamScore[ATTACKER];
	TeamScore[ATTACKER] = TeamScore[DEFENDER];
	TeamScore[DEFENDER] = TempScore;

	new TempName[24];
	TempName = TeamName[ATTACKER];
	TeamName[ATTACKER] = TeamName[DEFENDER];
	TeamName[DEFENDER] = TempName;
	TempName = TeamName[ATTACKER_SUB];
	TeamName[ATTACKER_SUB] = TeamName[DEFENDER_SUB];
	TeamName[DEFENDER_SUB] = TempName;

	UpdateTeamScoreTextDraw();
	UpdateTeamNameTextDraw();

	// Fix player teams after switching
	foreach(new i : ToFixSwitch)
	{
		SwitchTeamFix(i, false, false);
	}
	Iter_Clear(ToFixSwitch);

	new iString[144];
	format(iString, sizeof(iString), "{FFFFFF}Teams are swapped - {FF0033}Attackers: {FFFFFF}%s | {3344FF}Defenders: {FFFFFF}%s", TeamName[ATTACKER], TeamName[DEFENDER]);
	SendClientMessageToAll(-1, iString);
	FixVsTextDraw();
	return 1;
}

forward DoAutoBalance();
public DoAutoBalance() {
    BalanceTeams();
	if(PreMatchResultsShowing == false) AllowStartBase = true;
	SendClientMessageToAll(-1, ""COL_PRIM"Teams have been auto-balanced.");
}

forward DontAutoBalance();
public DontAutoBalance() {
	if(PreMatchResultsShowing == false) AllowStartBase = true;
}

BalanceTeams() {

	new TotalAttackers;
	new TotalDefenders;

	foreach(new i : Player)
	{
		if(Player[i][Spawned] == true && Player[i][InDuel] == false && (Player[i][Team] == ATTACKER || Player[i][Team] == DEFENDER))
		{
			new tid = random(2);
			if (tid == 0)
			{
				Player[i][Team] = DEFENDER;
			    TotalDefenders++;
			}
			else if (tid == 1)
			{
		 		Player[i][Team] = ATTACKER;
			    TotalAttackers++;
			}
			SwitchTeamFix(i, false, false);
		}
	}

    new Divisor = floatround((TotalDefenders + TotalAttackers) / 2);

	foreach(new i : Player)
	{
		if(Player[i][InDuel] == false && (Player[i][Team] == ATTACKER || Player[i][Team] == DEFENDER))
		{
			new randomnum = random(2);
			switch(randomnum)
			{
				case 0:
				{
		    		if(TotalDefenders <= Divisor) {
		       	 		if(Player[i][Team] == ATTACKER) TotalAttackers--;
						Player[i][Team] = DEFENDER;
		        		TotalDefenders++;
						SwitchTeamFix(i, false, false);

					} else if(TotalAttackers <= Divisor) {
		        		if(Player[i][Team] == DEFENDER) TotalDefenders--;
					 	Player[i][Team] = ATTACKER;
						TotalAttackers++;
						SwitchTeamFix(i, false, false);
					}
				}
				case 1:
				{
			    	if(TotalAttackers <= Divisor) {
		        		if(Player[i][Team] == DEFENDER) TotalDefenders--;
					 	Player[i][Team] = ATTACKER;
						TotalAttackers++;
						SwitchTeamFix(i, false, false);

					} else if(TotalDefenders <= Divisor) {
		       	 		if(Player[i][Team] == ATTACKER) TotalAttackers--;
						Player[i][Team] = DEFENDER;
		        		TotalDefenders++;
						SwitchTeamFix(i, false, false);
		    		}
				}
			}
			if(TotalDefenders == TotalAttackers)
				break;
		}
	}
	FixVsTextDraw();
	return 1;
}

SwitchTeamFix(playerid, bool:message = true, bool:fixvs = true, bool:changeskin = true)
{
	new iString[160];
	if(message)
	{
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has switched to: {FFFFFF}%s", Player[playerid][Name], TeamName[Player[playerid][Team]]);
		SendClientMessageToAll(-1, iString);
	}

	UpdateRoundKillDmgTDmg(playerid);

	ColorFix(playerid);
	if(fixvs && Current == -1)
		FixVsTextDraw();

	if(changeskin)
	{
	    SetPlayerSkin(playerid, Skin[Player[playerid][Team]]);
	}

	SetCameraBehindPlayer(playerid);
	HideAllTeamBarsForPlayer(playerid);
	#if defined _league_included
	UpdatePlayerLeaguePointTextDraw(playerid);
	#endif
}

GetTeamWithLessPlayers()
{
    new attacker, defender;
	switch(Current)
	{
		case -1:
		{
			foreach(new i : Player)
			{
				switch(Player[i][Team])
				{
					case DEFENDER:
					{
						defender ++;
					}
					case ATTACKER:
					{
						attacker ++;
					}
				}
			}
		}
		default:
		{
			foreach(new i : PlayersInRound)
			{
				switch(Player[i][Team])
				{
					case DEFENDER:
					{
						defender ++;
					}
					case ATTACKER:
					{
						attacker ++;
					}
				}
			}
		}
	}
    return (defender <= attacker) ? DEFENDER : ATTACKER;
}

EnableMatchInterface(playerid)
{
	SelectTextDraw(playerid, 0xFF0000FF);
	TextDrawShowForPlayer(playerid, LeagueToggleTD);
	TextDrawShowForPlayer(playerid, WarModeText);
	TextDrawShowForPlayer(playerid, SettingBox);
	TextDrawShowForPlayer(playerid, LockServerTD);
	TextDrawShowForPlayer(playerid, CloseText);
	PlayerOnInterface{playerid} = true;
}

DisableMatchInterface(playerid)
{
	CancelSelectTextDraw(playerid);
	TextDrawHideForPlayer(playerid, LeagueToggleTD);
	TextDrawHideForPlayer(playerid, WarModeText);
	TextDrawHideForPlayer(playerid, SettingBox);
	TextDrawHideForPlayer(playerid, LockServerTD);
	TextDrawHideForPlayer(playerid, CloseText);
	PlayerOnInterface{playerid} = false;
}

IsPlayerInArea(playerid, Float:minx, Float:maxx, Float:miny, Float:maxy) {
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    if (x > minx && x < maxx && y > miny && y < maxy) return 1;
    return 0;
}

HideDialogs(playerid)
{
	ShowPlayerDialog(playerid, -1, 0, " ", " ", " ", " ");
	return 1;
}
/*
GetPlayerHighestScores(array[][rankingEnum], left, right)
{
    new
        tempLeft = left,
        tempRight = right,
        pivot = array[(left + right) / 2][player_Score],
        tempVar
    ;
    while(tempLeft <= tempRight)
    {
        while(array[tempLeft][player_Score] > pivot) tempLeft++;
        while(array[tempRight][player_Score] < pivot) tempRight--;

        if(tempLeft <= tempRight)
        {
            tempVar = array[tempLeft][player_Score], array[tempLeft][player_Score] = array[tempRight][player_Score], array[tempRight][player_Score] = tempVar;
            tempVar = array[tempLeft][player_ID], array[tempLeft][player_ID] = array[tempRight][player_ID], array[tempRight][player_ID] = tempVar;
//			format(tempVarStr, sizeof(tempVarStr), array[tempLeft][player_Name]); format(array[tempLeft][player_Name], MAX_PLAYER_NAME, array[tempRight][player_Name]); format(array[tempRight][player_Name], MAX_PLAYER_NAME, tempVarStr);
            //tempVarStr = array[tempLeft][player_Name], array[tempLeft][player_Name] = array[tempRight][player_Name], array[tempRight][player_Name] = tempVarStr;
            tempVar = array[tempLeft][player_Kills], array[tempLeft][player_Kills] = array[tempRight][player_Kills], array[tempRight][player_Kills] = tempVar;
            tempVar = array[tempLeft][player_Deaths], array[tempLeft][player_Deaths] = array[tempRight][player_Deaths], array[tempRight][player_Deaths] = tempVar;
            tempVar = array[tempLeft][player_Team], array[tempLeft][player_Team] = array[tempRight][player_Team], array[tempRight][player_Team] = tempVar;
            tempLeft++, tempRight--;
        }
    }
    if(left < tempRight) GetPlayerHighestScores(array, left, tempRight);
    if(tempLeft < right) GetPlayerHighestScores(array, tempLeft, right);
}*/

GetPlayerHighestScores2(array[][rankingEnum], names[][MAX_PLAYER_NAME], left, right)
{
    new
        tempLeft = left,
        tempRight = right,
        pivot = array[(left + right) / 2][player_Score],
        tempVar,
		tempVarStr[MAX_PLAYER_NAME]
    ;
    while(tempLeft <= tempRight)
    {
        while(array[tempLeft][player_Score] > pivot) tempLeft++;
        while(array[tempRight][player_Score] < pivot) tempRight--;

        if(tempLeft <= tempRight)
        {
            tempVar = array[tempLeft][player_Score], array[tempLeft][player_Score] = array[tempRight][player_Score], array[tempRight][player_Score] = tempVar;
            tempVar = array[tempLeft][player_ID], array[tempLeft][player_ID] = array[tempRight][player_ID], array[tempRight][player_ID] = tempVar;
            tempVarStr = names[tempLeft], names[tempLeft] = names[tempRight], names[tempRight] = tempVarStr;
            tempVar = array[tempLeft][player_Kills], array[tempLeft][player_Kills] = array[tempRight][player_Kills], array[tempRight][player_Kills] = tempVar;
            tempVar = array[tempLeft][player_Deaths], array[tempLeft][player_Deaths] = array[tempRight][player_Deaths], array[tempRight][player_Deaths] = tempVar;
            tempVar = array[tempLeft][player_Team], array[tempLeft][player_Team] = array[tempRight][player_Team], array[tempRight][player_Team] = tempVar;
            tempVar = array[tempLeft][player_TPlayed], array[tempLeft][player_TPlayed] = array[tempRight][player_TPlayed], array[tempRight][player_TPlayed] = tempVar;
            tempVar = array[tempLeft][player_HP], array[tempLeft][player_HP] = array[tempRight][player_HP], array[tempRight][player_HP] = tempVar;
            tempVar = array[tempLeft][player_Acc], array[tempLeft][player_Acc] = array[tempRight][player_Acc], array[tempRight][player_Acc] = tempVar;
			tempVar = array[tempLeft][player_Overall], array[tempLeft][player_Overall] = array[tempRight][player_Overall], array[tempRight][player_Overall] = tempVar;
            tempLeft++, tempRight--;
        }
    }
    if(left < tempRight) GetPlayerHighestScores2(array, names, left, tempRight);
    if(tempLeft < right) GetPlayerHighestScores2(array, names, tempLeft, right);


}

forward SetCPForPlayer(playerid);
public SetCPForPlayer(playerid)
{
	switch(GameType)
	{
		case BASE:
		{
			SetPlayerCheckpoint(playerid, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 2);
			GangZoneShowForPlayer(playerid, CPZone, 0xFF000044);
		}
		case ARENA:
		{
			if(!CPInArena)
				return 0;
			SetPlayerCheckpoint(playerid, ACPSpawn[Current][0], ACPSpawn[Current][1], ACPSpawn[Current][2], 2);
			GangZoneShowForPlayer(playerid, CPZone, 0x00000033);
		}
	}
	return 1;
}

forward RespawnInVehicleAfterComeBack(playerid, vehicleid, seatid);
public RespawnInVehicleAfterComeBack(playerid, vehicleid, seatid)
{
    new ct = 0;
	foreach(new k : Player)
	{
		if(GetPlayerVehicleID(k) == vehicleid && GetPlayerVehicleSeat(k) == seatid)
	    	ct ++;
	}
    if(ct == 0)
    {
        PutPlayerInVehicle(playerid, vehicleid, seatid);
	}
	return 1;
}

bool:IsTeamTheSame(team1, team2)
{
	if(team1 == team2)
	    return true;
	else if((team1 == DEFENDER || team2 == DEFENDER) && (team1 == DEFENDER_SUB || team2 == DEFENDER_SUB))
		return true;
	else if((team1 == ATTACKER || team2 == ATTACKER) && (team1 == ATTACKER_SUB || team2 == ATTACKER_SUB))
		return true;
	else
	    return false;
}

ResetPlayerWorldBounds(playerid)
{
	SetPlayerWorldBounds(playerid, 20000.0000, -20000.0000, 20000.0000, -20000.0000);
}

ColorFix(playerid) {
	if(Player[playerid][Playing] == true) {

	    switch(Player[playerid][Team]) {
	        case ATTACKER: SetPlayerColor(playerid, ATTACKER_PLAYING);
	        case DEFENDER: SetPlayerColor(playerid, DEFENDER_PLAYING);
	        case REFEREE: SetPlayerColor(playerid, REFEREE_COLOR);
		}

		new team = Player[playerid][Team];
		if(TeamHasLeader[team] == true && TeamLeader[team] == playerid)
		    PlayerLeadTeam(playerid, true, false);
	} else {
	    switch(Player[playerid][Team]) {
	        case ATTACKER: SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
	        case DEFENDER: SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
	        case REFEREE: SetPlayerColor(playerid, REFEREE_COLOR);
	        case ATTACKER_SUB: SetPlayerColor(playerid, ATTACKER_SUB_COLOR);
	        case DEFENDER_SUB: SetPlayerColor(playerid, DEFENDER_SUB_COLOR);
		}
	}
}

RadarFix(playerid = INVALID_PLAYER_ID)
{
	if(playerid == INVALID_PLAYER_ID) // if markers need a global update
	{
		foreach(new i : Player)
		{
			foreach(new x : Player)
			{
				OnPlayerStreamIn(i, x);
			}
		}
	}
	else // if only one player's color is changed and needs updating
	{
		foreach(new i : Player)
		{
			OnPlayerStreamIn(playerid, i);
		}
	}
    return 1;
}

ClearChat()
{
	PP_LOOP<10>(SendClientMessageToAll(-1, " ");)()
	return 1;
}

ClearChatForPlayer(playerid)
{
	PP_LOOP<10>(SendClientMessage(playerid, -1, " ");)()
}

GetVehicleModelID(vehiclename[])
{
	for(new i = 0; i < 211; i++){
        if(strfind(aVehicleNames[i], vehiclename, true) != -1)
        return i + 400;
    } return -1;
}

bool:IsAirVehicle(vehicleid)
{
	if(vehicleid == 0 || vehicleid == INVALID_VEHICLE_ID)
		return false;

	switch(GetVehicleModel(vehicleid))
	{
		case
			417,
			425,
			447,
			460,
			469,
			476,
			487,
			488,
			497,
			511,
			512,
			513,
			519,
			520,
			548,
			553,
			563,
			577,
			592,
			593:
		{
			return true;
		}
	}
	return false;
}

ClearKillList() {
	for(new i = 0; i < 5; i++) {
	    SendDeathMessage(255, 50, 255);
	}
}

/*
	whatvehicles:
	0 to destroy all dynamic (spawned) vehicles
	1 to destroy unoccupied vehicles only
	2 to destroy occupied vehicles only
*/
DestroyDynamicVehicles(whatvehicles)
{
	switch(whatvehicles)
	{
		case 0: // all
		{
			foreach(new i : DynamicVehicle)
			{
				DestroyVehicle(i, false);
				Iter_SafeRemove(DynamicVehicle, i, i);
			}
		}
		case 1: // unoccupied only
		{
			new bool:foundDriver;
			foreach(new i : DynamicVehicle)
			{
				foundDriver = false;
				foreach(new j : Player)
				{
					if(GetPlayerVehicleID(j) == i && GetPlayerState(j) == PLAYER_STATE_DRIVER)
					{
						foundDriver = true;
						break;
					}
				}
				switch(foundDriver)
				{
					case false:
					{
						DestroyVehicle(i, false);
						Iter_SafeRemove(DynamicVehicle, i, i);
					}
				}
			}
		}
		case 2: // occupied only
		{
			new bool:foundDriver;
			foreach(new i : DynamicVehicle)
			{
				foundDriver = false;
				foreach(new j : Player)
				{
					if(GetPlayerVehicleID(j) == i && GetPlayerState(j) == PLAYER_STATE_DRIVER)
					{
						foundDriver = true;
						break;
					}
				}
				switch(foundDriver)
				{
					case true:
					{
						DestroyVehicle(i, false);
						Iter_SafeRemove(DynamicVehicle, i, i);
					}
				}
			}
		}
	}
	return 1;
}

forward ForceRespectate(playerid);
public ForceRespectate(playerid)
{
	foreach(new i : PlayerSpectators[playerid])
		SpectatePlayer(i, playerid);
}

SyncPlayer(playerid)
{
	// Restrictions
	if(RoundPaused == true && Player[playerid][Playing]) return 1;
	if(Player[playerid][OnGunmenu] == true) return SendErrorMessage(playerid, "Can't sync while in gunmenu");
	if((GetTickCount() - Player[playerid][LastTimeSynced]) < 1000) return 1;
	if(AllowStartBase == false) return 1;
	if(GetPlayerVehicleID(playerid)) return 1;
	if(Player[playerid][IsAFK] == true || Player[playerid][IsFrozen]) return SendErrorMessage(playerid, "Can't sync while frozen or in AFK mode");

	// Set spectators to re-spectate
	if(Player[playerid][BeingSpeced])
		SetTimerEx("ForceRespectate", 1000, false, "i", playerid);

	// Store info before re-spawn
	new Float:Pos[4], CurrWep;
	CurrWep = GetPlayerWeapon(playerid);
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	GetPlayerFacingAngle(playerid, Pos[3]);
	new Weapons[13][2];
	for(new i = 0; i < 13; i++)
		GetPlayerWeaponData(playerid, i, Weapons[i][0], Weapons[i][1]);

	// Set spawn info and spawn player
	SetSpawnInfo(playerid, GetPlayerTeam(playerid), GetPlayerSkin(playerid), Pos[0], Pos[1], Pos[2]-0.4, Pos[3], 0, 0, 0, 0, 0, 0);
	Player[playerid][IgnoreSpawn] = true;
	SpawnPlayer(playerid);

	// Set info back after re-spawn
	SetHP(playerid, Player[playerid][pHealth]);
	SetAP(playerid, Player[playerid][pArmour]);
	SetPlayerInterior(playerid, GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(playerid));
	for(new i = 0; i < 13; i ++)
	    GivePlayerWeapon(playerid, Weapons[i][0], Weapons[i][1]);
	SetPlayerArmedWeapon(playerid, CurrWep);

	// Update tick count
	Player[playerid][LastTimeSynced] = GetTickCount();
	return 1;
}

IsNumeric(string[]){
    for (new i = 0, j = strlen(string); i < j; i++){
    	if (string[i] > '9' || string[i] < '0') return 0;
    }
    return 1;
}

GetPlayerFPS(playerid) {
	new drunk2 = GetPlayerDrunkLevel(playerid);
	if(drunk2 < 100){
	    SetPlayerDrunkLevel(playerid,2000);
	}else{
	    if(Player[playerid][DLlast] != drunk2){
	        new fps = Player[playerid][DLlast] - drunk2;
	        if((fps > 0) )// && (fps < 200))
   				Player[playerid][FPS] = fps;
			Player[playerid][DLlast] = drunk2;
		}
	}
	return Player[playerid][FPS];
}

FixVsTextDraw(exception = -1)
{
	if(Current == -1)
	{
		new str[32];
		new ct[2];
		foreach(new i : Player)
		{
			if(i == exception)
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
	    format(str, sizeof(str), "  ~r~%d  %sVs  ~b~~h~%d", ct[0], MAIN_TEXT_COLOUR, ct[1]);
		foreach(new i : Player)
			PlayerTextDrawSetString(i, BaseID_VS[i], str);
	}
	return 1;
}

Float:GetDistanceBetweenPlayers(playerid, toplayerid)
{
	if(playerid == INVALID_PLAYER_ID || toplayerid == INVALID_PLAYER_ID)
		return -1.0;

	new Float:Pos[2][3];
	GetPlayerPos(playerid, Pos[0][0], Pos[0][1], Pos[0][2]);
	GetPlayerPos(toplayerid, Pos[1][0], Pos[1][1], Pos[1][2]);
	return floatsqroot(floatpower(floatabs(floatsub(Pos[1][0], Pos[0][0])),2) + floatpower(floatabs(floatsub(Pos[1][1], Pos[0][1])),2) + floatpower(floatabs(floatsub(Pos[1][2], Pos[0][2])),2));
}

SpawnInDM(playerid, DMID)
{
	Player[playerid][InDM] = true;

	ResetPlayerWeapons(playerid); // Reset all player weapons

	SetSpawnInfo(playerid, playerid, Skin[Player[playerid][Team]], DMSpawn[DMID][0]+random(2), DMSpawn[DMID][1]+random(2), DMSpawn[DMID][2], DMSpawn[DMID][3], DMWeapons[DMID][0], 9999, DMWeapons[DMID][1], 9999, DMWeapons[DMID][2], 9999);
	SetPlayerInterior(playerid, DMInterior[DMID]);

	Player[playerid][IgnoreSpawn] = true; //Make sure you ignore OnPlayerSpawn, else you will just spawn in lobby (because u are about to use SpawnPlayer).
	SpawnPlayer(playerid); //Spawns players, in this case we have SetSpawnInfo (but still you need to make sure OnPlayerSpawn is ignored);

	SetPlayerVirtualWorld(playerid, Player[playerid][VWorld]); // Put player in a different virtual world so that if you create a DM in your lobby and you join the DM, you won't be able to see other players in the lobby.
	SetHP(playerid, 100);
	SetAP(playerid, 100);
	return 1;
}

QuitDM(playerid)
{
	if(Player[playerid][Playing] == true) return 1;
	if(Player[playerid][InDM] == false) return 1;

    Player[playerid][InDM] = false;
    Player[playerid][DMReadd] = 0;
    SpawnInLobby(playerid);
    return 1;
}

// Checks whether an integer is even or odd
#define IsOdd(%0) ((%0)&1)
#define IsEven(%0) (!IsOdd(%0))

IsSafeGametext(text[])
{
	new cnt = 0;
	for(new i = 0, j = strlen(text); i < j; i ++)
	{
		if(text[i] == '~')
			cnt ++;
	}
	if(!IsEven(cnt))
		return 0;
	return 1;
}

// Function written by Slice to help fix vehicle bad modding (tweaked it a little bit)
IsVehicleComponentLegal(vehiclemodel, componentid)
{
	// These is the only case with componentids > 1191 (saves ~1kb in the array)
	if (vehiclemodel == 576 && (componentid == 1192 || componentid == 1193))
		return true;

	new s_LegalMods[][] = {
		{54273792, 0, 16776704, 7, 0, 0},
		{35268602, 0, 16776704, 7, 245760, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{37431173, 0, 16776704, 7, 0, 0},
		{45893379, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{62531466, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{42862474, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{36767556, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{36177722, 0, 16776704, 7, 0, 0},
		{45958913, 0, 16776704, 7, 0, 0},
		{37365632, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{36177786, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{41560010, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{42084234, 0, 16776704, 7, 245760, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{37619648, 0, 16776704, 7, 0, 0},
		{57685808, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{52242293, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{46024584, 0, 16776704, 7, 245760, 0},
		{33621873, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{43651022, 0, 16776704, 7, 49152, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{54011648, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{37717909, 0, 16776704, 7, 0, 0},
		{43976588, 0, 16776704, 7, 245760, 0},
		{43395050, 0, 16776704, 7, 245760, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{37144450, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{43917258, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, -67107785, 0, 35389440},
		{33556224, 0, 16776704, 67002375, 0, 0},
		{33556224, 0, 16776704, 7047, 1, 31457280},
		{0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{60688338, 0, 16776704, 7, 245760, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{37537536, 0, 16776704, 7, 196608, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{59639766, 0, 16776704, 7, 245760, 0},
		{37553929, 0, 16776704, 7, 49152, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{43917194, 0, 16776704, 7, 245760, 0},
		{43779962, 0, 16776704, 7, 245760, 0},
		{45942636, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, -512, 7, 0, 504},
		{33556224, 0, 16777214, 7, -1073741824, 8199},
		{-33552640, 3, 16776704, 7, 15360, 1536},
		{-838859008, -8388608, 16776705, 7, 1006632960, 0},
		{33556224, 1020, 16776704, 7, 3932160, 6144},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 8380416, 16776704, 7, 62914560, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 71, 62, 1006632960},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 7168, 16776704, 15, 0, 245760},
		{33556224, 0, 16776704, 7, 960, -1073741824},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{43386818, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{51849201, 0, 16776704, 7, 196608, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{0, 0, 0, 0, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{39200752, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{60688322, 0, 16776704, 7, 245760, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0},
		{33556224, 0, 16776704, 7, 0, 0}
	};
	if (1000 <= componentid <= 1191 && 400 <= vehiclemodel <= 611) {
		componentid -= 1000;
		vehiclemodel -= 400;

		return (s_LegalMods[vehiclemodel][componentid >>> 5] & 1 << (componentid & 31)) || false;
	}
	return false;
}
