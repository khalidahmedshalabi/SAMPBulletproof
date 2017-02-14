#include "modules\header\duel.txt"
#include <YSI_inc\YSI\y_hooks>

hook OnPlayerDisconnect(playerid, reason)
{
	if(Player[playerid][InDuel] == true)
	{
		new iString[128];
		format(iString, sizeof(iString), "{FFFFFF}%s left server during a duel {757575}| HP %d | Armour %d", Player[playerid][Name], Player[playerid][pHealth], Player[playerid][pArmour]);
		SendClientMessageToAll(-1, iString);

		new winner = Player[playerid][challengerid];
		format(iString, sizeof(iString), "{FFFFFF}His opponent %s had {757575}%d HP and %d Armour", Player[winner][Name], Player[winner][pHealth], Player[winner][pArmour]);
		SendClientMessageToAll(-1, iString);
		Player[winner][InDuel] = false;
		Player[playerid][DuelsLost]++;
		Player[winner][DuelsWon]++;
		ResetDuellers(winner, playerid);
		UpdateDuellersStats(winner, playerid);
		Player[winner][challengerid] = -1;
	}
	return 1;
}

ResetDuellers(dueller1, dueller2, bool:respawn = true)
{
	// Teams
	Player[dueller1][Team] = Player[dueller1][TeamBeforeDuel];
	Player[dueller2][Team] = Player[dueller2][TeamBeforeDuel];
    SwitchTeamFix(dueller1, false, false);
    SwitchTeamFix(dueller2, false, false);
	// world bounds
	ResetPlayerWorldBounds(dueller1);
	ResetPlayerWorldBounds(dueller2);
	// destroy duel gangzone
	if(Player[dueller1][Duel_GangZone] == Player[dueller2][Duel_GangZone])
	{
		GangZoneDestroy(Player[dueller1][Duel_GangZone]);
	}
	else
	{
		GangZoneDestroy(Player[dueller1][Duel_GangZone]);
		GangZoneDestroy(Player[dueller2][Duel_GangZone]);
	}
	if(respawn)
	{
		// spawn
		SpawnInLobby(dueller1);
		SpawnInLobby(dueller2);
	}
}

UpdateDuellersStats(winner, loser)
{
	// announcement
	new str[144];
	format(
	str, 
	sizeof str, 
	""COL_PRIM"Duel stats: {FFFFFF}%s [W: %d / L: %d] & %s [W: %d / L: %d]", 
	Player[winner][NameWithoutTag], Player[winner][DuelsWon], Player[winner][DuelsLost],
	Player[loser][NameWithoutTag], Player[loser][DuelsWon], Player[loser][DuelsLost]
	);
	SendClientMessageToAll(-1, str);
	// database
	format(str, sizeof(str), "UPDATE Players SET DLost = %d WHERE Name = '%q'", Player[loser][DuelsLost], Player[loser][Name]);
	db_free_result(db_query(sqliteconnection, str));
	format(str, sizeof(str), "UPDATE Players SET DWon = %d WHERE Name = '%q'", Player[winner][DuelsWon], Player[winner][Name]);
	db_free_result(db_query(sqliteconnection, str));
}

ProcessDuelRequest(duel_host, duel_guest, weapon1, weapon2, arena, size)
{
	Player[duel_guest][challengerid] = duel_host;
	Player[duel_guest][duelweap1] = weapon1;
	Player[duel_guest][duelweap2] = weapon2;
	Player[duel_guest][DuelRequestedArena] = arena;
	Player[duel_guest][Duel_Size] = size;
	switch(arena)
	{
		case DEFAULT_DUEL_ARENA_ID:
		{
			Player[duel_guest][Duel_X] = DEFAULT_DUEL_ARENA_X;
			Player[duel_guest][Duel_Y] = DEFAULT_DUEL_ARENA_Y;
			Player[duel_guest][Duel_Interior] = DEFAULT_DUEL_ARENA_INTERIOR;
		}
		default:
		{
			new Float:waste;
			GetPlayerPos(duel_host, Player[duel_guest][Duel_X], Player[duel_guest][Duel_Y], waste);
			Player[duel_guest][Duel_Interior] = GetPlayerInterior(duel_host);
		}
	}

	new iString[130];
	format(iString, sizeof(iString), "%s%s {FFFFFF}challenged %s%s {FFFFFF}to a duel with: %s and %s", TextColor[Player[duel_host][Team]], Player[duel_host][Name], TextColor[Player[duel_guest][Team]], Player[duel_guest][Name], WeaponNames[weapon1], WeaponNames[weapon2]);
	SendClientMessageToAll(-1, iString);
	SendClientMessage(duel_guest, -1, "{FF8800}Type {FFFFFF}/yes {FF8800}to accept the duel challenge or {FFFFFF}/no {FF8800}to deny the duel challenge.");
    PlayerPlaySound(duel_guest,1137,0.0,0.0,0.0);
}

DetermineDuelArena(Float:centerx, Float:centery, size, &Float:minx, &Float:miny, &Float:maxx, &Float:maxy)
{
	minx = centerx - float(size);
	miny = centery - float(size);
	maxx = centerx + float(size);
	maxy = centery + float(size);
}

forward FixPosZ(playerid);
public FixPosZ(playerid)
{
	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(playerid, X, Y, Z);
    SetPlayerPosFindZ(playerid, X, Y, 1000.0);
	SetPlayerInterior(playerid, GetPlayerInterior(playerid));
	return 1;
}

PositionPlayersInDuel(playerid_1, playerid_2, Float:centerx, Float:centery, size)
{
	new Float:tmp = float(size) / 3.0;
	SetPlayerPosFindZ(playerid_1, centerx + tmp, centery + tmp, 1000.0);
	SetPlayerPosFindZ(playerid_2, centerx - tmp, centery - tmp, 1000.0);
	SetTimerEx("FixPosZ", 1000, false, "i", playerid_1);
	SetTimerEx("FixPosZ", 1000, false, "i", playerid_2);
	GetPlayerFacingAngle(playerid_1, tmp);
	SetPlayerFacingAngle(playerid_2, tmp + 180.0);
	SetCameraBehindPlayer(playerid_1);
	SetCameraBehindPlayer(playerid_2);
}

StartDuel(dueller1, dueller2, weapon1, weapon2, Float:centerx, Float:centery, arena_size, interior)
{
	if(Player[dueller1][Spectating] == true) StopSpectate(dueller1);
	if(Player[dueller2][Spectating] == true) StopSpectate(dueller2);
	ResetPlayerWeapons(dueller1);
	ResetPlayerWeapons(dueller2);
	SetPlayerVirtualWorld(dueller1, dueller1+10);
	SetPlayerVirtualWorld(dueller2, dueller1+10);
	SetHP(dueller1, 100);
	SetHP(dueller2, 100);
	SetAP(dueller1, 100);
	SetAP(dueller2, 100);
	GameTextForPlayer(dueller1, "~r~~h~rape!!!", 3000, 6);
	GameTextForPlayer(dueller2, "~r~~h~rape!!!", 3000, 6);
	SetPlayerColor(dueller1, 0xFAB18488);
	SetPlayerColor(dueller2, 0xFAB18488);
	SetPlayerSkin(dueller1, Skin[Player[dueller1][Team]]);
	SetPlayerSkin(dueller2, Skin[Player[dueller2][Team]]);
	Player[dueller1][TeamBeforeDuel] = Player[dueller1][Team];
	Player[dueller2][TeamBeforeDuel] = Player[dueller2][Team];
	Player[dueller1][ToAddInRound] = false;
	Player[dueller2][ToAddInRound] = false;
	Player[dueller1][InDuel] = true;
	Player[dueller2][InDuel] = true;
	Player[dueller1][challengerid] = dueller2;
	Player[dueller2][challengerid] = dueller1;
	Player[dueller1][Team] = REFEREE;
	Player[dueller2][Team] = REFEREE;
	
	if(weapon1 == weapon2)
	{
		GivePlayerWeapon(dueller1, weapon1, 9999);
		GivePlayerWeapon(dueller2, weapon1, 9999);
	}
	else
	{
		GivePlayerWeapon(dueller1, weapon1, 9999);
		GivePlayerWeapon(dueller1, weapon2, 9999);
		GivePlayerWeapon(dueller2, weapon1, 9999);
		GivePlayerWeapon(dueller2, weapon2, 9999);
	}
	PlayerPlaySound(dueller1,3200,0.0,0.0,0.0);
	PlayerPlaySound(dueller2,3200,0.0,0.0,0.0);
	SetPlayerInterior(dueller1, interior);
	SetPlayerInterior(dueller2, interior);
	PositionPlayersInDuel(dueller1, dueller2, centerx, centery, arena_size);
	RadarFix(dueller1);
	RadarFix(dueller2);
	new Float:zoneX[2], Float:zoneY[2];
	DetermineDuelArena(centerx, centery, arena_size, zoneX[0], zoneY[0], zoneX[1], zoneY[1]);
	new gangzone = GangZoneCreate(zoneX[0], zoneY[0], zoneX[1], zoneY[1]);
	GangZoneShowForPlayer(dueller1, gangzone, 0xFFA50066);
	GangZoneShowForPlayer(dueller2, gangzone, 0xFFA50066);
	Player[dueller1][Duel_GangZone] = gangzone;
	Player[dueller2][Duel_GangZone] = gangzone;
	SetPlayerWorldBounds(dueller1, zoneX[1], zoneX[0], zoneY[1], zoneY[0]);
	SetPlayerWorldBounds(dueller2, zoneX[1], zoneX[0], zoneY[1], zoneY[0]);
}

PlayerDuelQuit(playerid)
{
	new winner, iString[128], HPs[2];
	GetHP(playerid, HPs[0]);
	GetAP(playerid, HPs[1]);
	winner = Player[playerid][challengerid];

	format(iString, sizeof(iString), "%s%s {FFFFFF}rage-quit from a duel | {757575}HP %d | Armour %d", TextColor[Player[playerid][TeamBeforeDuel]], Player[playerid][Name], HPs[0], HPs[1]);
	SendClientMessageToAll(-1,iString);

	Player[playerid][InDuel] = false;
	Player[winner][InDuel] = false;
	Player[playerid][DuelsLost]++;
	Player[winner][DuelsWon]++;
	ResetDuellers(playerid, winner);
	UpdateDuellersStats(winner, playerid);

	Player[playerid][challengerid] = -1;
	Player[winner][challengerid] = -1;
}

ProcessDuellerDeath(playerid, killerid, reason)
{
	if(killerid == -1 || killerid == INVALID_PLAYER_ID)
		killerid = Player[playerid][challengerid];
	
	new str[128];
	new HP[2];
	GetHP(killerid, HP[0]);
	GetAP(killerid, HP[1]);
	format(str, sizeof(str), "%s%s "COL_PRIM"raped %s%s "COL_PRIM"in a duel with %s | {FFFFFF}%d HP", TextColor[Player[killerid][TeamBeforeDuel]], Player[killerid][Name], TextColor[Player[playerid][TeamBeforeDuel]], Player[playerid][Name], WeaponNames[reason], (HP[0] + HP[1]));
	SendClientMessageToAll(-1, str);
	Player[playerid][challengerid] = -1;
	Player[killerid][challengerid] = -1;
	Player[playerid][duelweap1] = 0;
	Player[playerid][duelweap2] = 0;
	Player[killerid][duelweap1] = 0;
	Player[killerid][duelweap2] = 0;
	Player[playerid][ToAddInRound] = true;
	Player[killerid][ToAddInRound] = true;
	Player[playerid][DuelsLost]++;
	Player[killerid][DuelsWon]++;

	Player[playerid][InDuel] = false;
	Player[killerid][InDuel] = false;
	ResetDuellers(playerid, killerid, false);
	SpawnInLobby(killerid);
	UpdateDuellersStats(killerid, playerid);
}