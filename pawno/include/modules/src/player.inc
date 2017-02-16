/*
		Player related
*/

#include "modules\header\player.txt"

#include "modules\header\config.txt"
#include "modules\header\weaponshot.txt"
#include "modules\header\global.txt"
#include "modules\header\fields.txt"
#include "modules\header\freecam.txt"
#include "modules\header\longarrays.txt"
#include "modules\header\textdraws.txt"
#include "modules\header\spectate.txt"
#tryinclude "modules\header\league.txt"
#include "modules\header\weaponbinds.txt"
#include "modules\header\teamhpbars.txt"

// Checks player AKAs
GetPlayerAKA(playerid, str[], len)
{
    new IP[16];
    GetPlayerIp(playerid, IP, sizeof(IP));
	new DBResult:dbres = db_query(sqliteconnection, sprintf("SELECT `Names` FROM `AKAs` WHERE `IP` = '%s'", IP));

	if(db_num_rows(dbres) > 0)
	{
		db_get_field_assoc(dbres, "Names", str, len);
	}
	else
	{
		strcat(str, "NULL", len);
		db_free_result(db_query(sqliteconnection, sprintf("INSERT INTO `AKAs` (`IP`, `Names`) VALUES ('%s', '%s')", IP, "")));
	}
	db_free_result(dbres);
}

MatchAKA(playerid)
{
    new AKAString[256];
	GetPlayerAKA(playerid, AKAString, sizeof AKAString);

	new idx;
	do {
		idx = strfind(AKAString, ",", true, idx == 0 ? 0 : idx+1);
		new compare[MAX_PLAYER_NAME];
		new idx2 = strfind(AKAString, ",", true, idx+1);
		strmid(compare, AKAString, idx+1, (idx2 == -1 ? strlen(AKAString) : idx2) );

		if(!strcmp(compare, Player[playerid][Name], true) && strlen(Player[playerid][Name]) > 0 && strlen(compare) > 0) {
		    return 1;
		}

	} while(idx != -1);
	return 0;
}

CheckPlayerAKA(playerid)
{
	if(!MatchAKA(playerid))
	{
		new str[16];
		GetPlayerIp(playerid, str, sizeof(str));
	    new AKAString[256];
		GetPlayerAKA(playerid, AKAString, sizeof AKAString);
	    new add[MAX_PLAYER_NAME+1];
	    format(add, sizeof(add), ",%s", Player[playerid][Name]);

		if(strlen(AKAString) > 0) strcat(AKAString, add);
		else strcat(AKAString, add[1]);

		new query[128];
		format(query, sizeof(query), "UPDATE `AKAs` SET `Names` = '%q' WHERE `IP` = '%s'", AKAString, str);
		db_free_result(db_query(sqliteconnection, query));
	}
}

// Player name functions
RemoveClanTagFromName(playerid) {
    new start, end, string[MAX_PLAYER_NAME];
    format(string, MAX_PLAYER_NAME, "%s", Player[playerid][Name]);
    start = strfind(string, "[", true);
    end = strfind(string, "]", true);
    if (start >= end){
		return string;
    }else{
        strdel(string, start, end + 1);
        return string;
    }
}

// Loads nickname and name without the clan tag
InitPlayerNames(playerid)
{
	GetPlayerName(playerid, Player[playerid][Name], MAX_PLAYER_NAME);
	new NewName[MAX_PLAYER_NAME];
	NewName = RemoveClanTagFromName(playerid);

	if(strlen(NewName) != 0)
		Player[playerid][NameWithoutTag] = NewName; // Removes clan tag from the player name and stores the new name in NameWithoutTag variable.
	else
	    Player[playerid][NameWithoutTag] = Player[playerid][Name];
}

// Initialize player variables
InitPlayer(playerid)
{
	Player[playerid][Level] = 0;
	UpdatePlayerAdminGroup(playerid);
	Player[playerid][Weather] = MainWeather;
	Player[playerid][Time] = MainTime;
	Player[playerid][Team] = NON;
	Player[playerid][CanNetcheck] = -1;
	Player[playerid][DMReadd] = 0;
	Player[playerid][ChatChannel] = -1;
	Player[playerid][RoundKills] = 0;
	Player[playerid][RoundDeaths] = 0;
	Player[playerid][RoundDamage] = 0;
	Player[playerid][WeaponPicked] = 0;
	Player[playerid][TotalKills] = 0;
	Player[playerid][TotalDeaths] = 0;
	Player[playerid][TotalDamage] = 0;
	Player[playerid][ACKick] = 0;
	Player[playerid][IsSpectatingID] = -1;
	Player[playerid][OutOfArena] = MAX_ZONE_LIMIT_WARNINGS;
	Player[playerid][FPSKick] = 0;
	Player[playerid][PingKick] = 0;
	Player[playerid][PacketKick] = 0;
	Player[playerid][LastVehicle] = -1;
	Player[playerid][TimesSpawned] = 0;
	Player[playerid][VWorld] = 1;
	Player[playerid][lastChat] = 0;
	Player[playerid][LastAskLeader] = 0;
	Player[playerid][LastTimeSynced] = 0;
    Player[playerid][RoundPlayed] = 0;
    Player[playerid][shotsHit] = 0;
    Player[playerid][TotalBulletsFired] = 0;
    Player[playerid][TotalshotsHit] = 0;
    Player[playerid][RconTry] = 0;
	Player[playerid][NetCheck] = 1;
	Player[playerid][FPSCheck] = 1;
	Player[playerid][PingCheck] = 1;
	Player[playerid][PLCheck] = 1;
	Player[playerid][SpectatingRound] = -1;
	InitPlayerSpectate(playerid);
	ForgetSpectator(playerid);
	Player[playerid][HitBy] = INVALID_PLAYER_ID;
	Player[playerid][HitWith] = 47;
	Player[playerid][HitSound] = 17802;
	Player[playerid][GetHitSound] = 1131;
	Player[playerid][LastEditWepLimit] = -1;
	Player[playerid][LastEditWeaponSlot] = -1;
    Player[playerid][challengerid] = -1;
	Player[playerid][duelweap1] = 0;
	Player[playerid][duelweap2] = 0;
	Player[playerid][DuelsWon] = 0;
	Player[playerid][DuelsLost] = 0;
    Player[playerid][LastMsgr] = -1;
    Player[playerid][blockedid] = -1;
    Player[playerid][FightStyle] = 4;
    SetPlayerFightingStyle(playerid, Player[playerid][FightStyle]);
    TargetInfoData[playerid][TargetInfoTimer] = -1;
	ChangingSkinOfTeam[playerid] = -1;
	Player[playerid][LastEnterVehicleAttempt] = 0;
	Player[playerid][RequestedClass] = NON;
	Player[playerid][GunmenuModdingType] = 0;
	Player[playerid][GunmenuModdingIndex] = 0;
	Player[playerid][RoundTDStyle] = 0;

    Player[playerid][Logged] = false;
    Player[playerid][IgnoreSpawn] = false;
    Player[playerid][InDM] = false;
    Player[playerid][InDuel] = false;
    Player[playerid][Playing] = false;
	Iter_Remove(PlayersInRound, playerid);
    Player[playerid][WasInCP] = false;
	Player[playerid][Spectating] = false;
	Player[playerid][BeingSpeced] = false;
	Player[playerid][WasInBase] = false;
	Player[playerid][WasInTeam] = NON;
	Player[playerid][TextDrawOnScreen] = false;
	PlayerOnInterface{playerid} = false;
	Player[playerid][Spawned] = false;
	Player[playerid][IsAFK] = false;
	Player[playerid][IsFrozen] = false;
	Player[playerid][AskingForHelp] = false;
	Player[playerid][Mute] = false;
	Player[playerid][ToAddInRound] = false;
	InitPlayerInterface(playerid);
	Player[playerid][blockedall] = false;
	Player[playerid][OnGunmenu] = false;
	Player[playerid][GunmenuStyle] = GUNMENU_STYLE_DIALOG;
	Player[playerid][AlreadyDying] = false;
	Player[playerid][TempNetcheck] = false;
	Player[playerid][MustLeaguePass] = false;
	Player[playerid][LeagueLogged] = false;
	Player[playerid][InDeathCamera] = false;
	Player[playerid][HasDeathQuote] = false;
	Player[playerid][HadParachuteBeforeFreeze] = false;

	ResetPlayerMoney(playerid);
	SetPlayerColor(playerid, 0xAAAAAAAA);
	RemoveUselessObjectsForPlayer(playerid);
	LoadPlayerTextDraws(playerid);

	for(new i = 0; i < MAX_PLAYER_BARS; i ++)
		TeamBarShownForPlayer[playerid][_:i] = false;

	ShowTeamCornerInfo(playerid);

	InitPlayerMessageBox(playerid);
	InitPlayerNames(playerid);
	InitPlayerWeaponBind(playerid);
	InitPlayerVisualDamage(playerid);
	InitPlayerVoting(playerid);

	noclipdata[playerid][cameramode] 	= 	CAMERA_MODE_NONE;
	noclipdata[playerid][lrold]	   	 	= 	0;
	noclipdata[playerid][udold]   		= 	0;
	noclipdata[playerid][noclipcammode] = 	0;
	noclipdata[playerid][lastmove]   	= 	0;
	noclipdata[playerid][accelmul]   	= 	0.0;
	noclipdata[playerid][FlyMode] 		= 	false;
	return 1;
}

LoginPlayer(playerid, DBResult:res)
{
    new iString[128];

    // Load level
    db_get_field_assoc(res, "Level", iString, sizeof(iString));
    Player[playerid][Level] = strval(iString);
	UpdatePlayerAdminGroup(playerid);

	// Load Weather
	db_get_field_assoc(res, "Weather", iString, sizeof(iString));
	Player[playerid][Weather] = strval(iString);

	// Load time
	db_get_field_assoc(res, "Time", iString, sizeof(iString));
	Player[playerid][Time] = strval(iString);

	// Load ChatChannel
	db_get_field_assoc(res, "ChatChannel", iString, sizeof(iString));
	Player[playerid][ChatChannel] = strval(iString);

	// Load NetCheck
	db_get_field_assoc(res, "NetCheck", iString, sizeof(iString));
	Player[playerid][NetCheck] = strval(iString);

	// Load HitSound
	db_get_field_assoc(res, "HitSound", iString, sizeof(iString));
	Player[playerid][HitSound] = strval(iString);

	// Load GetHitSound
	db_get_field_assoc(res, "GetHitSound", iString, sizeof(iString));
	Player[playerid][GetHitSound] = strval(iString);

	// Load Duels won
	db_get_field_assoc(res, "DWon", iString, sizeof(iString));
	Player[playerid][DuelsWon] = strval(iString);

	// Load Duels Lost
	db_get_field_assoc(res, "DLost", iString, sizeof(iString));
	Player[playerid][DuelsLost] = strval(iString);

	// Load ShowSpecs
	db_get_field_assoc(res, "InterfaceSpec", iString, sizeof(iString));
	PlayerInterface[playerid][INTERFACE_SPEC] = (strval(iString) == 0 ? false : true);

	// Load Fighting Style
	db_get_field_assoc(res, "FightStyle", iString, sizeof(iString));
	Player[playerid][FightStyle] = strval(iString);
	SetPlayerFightingStyle(playerid, Player[playerid][FightStyle]);

	// Load Death Messages
	db_get_field_assoc(res, "DeathMessage", iString, sizeof(iString));
	DeathMessageStr[playerid][0] = EOS;
	strcat(DeathMessageStr[playerid], iString, 64);
	if(strcmp("NO_DEATH_MESSAGE", DeathMessageStr[playerid], false) != 0)
		Player[playerid][HasDeathQuote] = true;

	// Load Show net textdraws
	db_get_field_assoc(res, "InterfaceNet", iString, sizeof(iString));
	PlayerInterface[playerid][INTERFACE_NET] = (strval(iString) == 0 ? false : true);

	// Load Show HP textdraws
	db_get_field_assoc(res, "InterfaceHP", iString, sizeof(iString));
	PlayerInterface[playerid][INTERFACE_HP] = (strval(iString) == 0 ? false : true);

	// Load weapon key binds
	new fieldName[12], value;
	for(new i = 0; i < MAX_WEAPON_BINDS; i ++)
	{
		format(fieldName, sizeof fieldName, "WeaponBind%d", i);
		db_get_field_assoc(res, fieldName, iString, sizeof(iString));
		value = strval(iString);
		if(value != -1)
		{
			WeaponBindData[playerid][BindKeyWeapon][i] = value;
		}
	}

	// Load Gunmenu Style
	db_get_field_assoc(res, "GunmenuStyle", iString, sizeof(iString));
	Player[playerid][GunmenuStyle] = strval(iString);

	// Load Weapon Binding
	db_get_field_assoc(res, "WeaponBinding", iString, sizeof(iString));
	Player[playerid][WeaponBinding] = (strval(iString) == 0 ? false : true);

	// Load player markers setting
	db_get_field_assoc(res, "PlayerMarkers", iString, sizeof(iString));
	Player[playerid][PlayerMarkers] = (strval(iString) == 0 ? false : true);

	// Load round textdraws style
	db_get_field_assoc(res, "RoundTDStyle", iString, sizeof(iString));
	Player[playerid][RoundTDStyle] = strval(iString);

	// Get current IP address
	new IP[16];
	GetPlayerIp(playerid, IP, sizeof(IP));

	// Update players table with new IP address for auto login if they reconnect.
	format(iString, sizeof(iString), "UPDATE `Players` SET `IP` = '%s' WHERE `Name` = '%s' AND IP != '%s'", IP, Player[playerid][Name], IP);
	db_free_result(db_query(sqliteconnection, iString));

	// Update last seen/logged in
	new day, month, year;
	getdate(year, month, day);
	format(iString, sizeof(iString), "UPDATE `Players` SET `LastSeen_Day` = %d, `LastSeen_Month` = %d, `LastSeen_Year` = %d WHERE `Name` = '%s'", day, month, year, Player[playerid][Name]);
	db_free_result(db_query(sqliteconnection, iString));

    Player[playerid][Logged] = true;
}

StorePlayerVariablesMin(playerid) {
    for(new i = 0; i < SAVE_SLOTS; i ++)
	{
	   	if(strlen(SaveVariables[i][pName]) < 2)
		{
	   	    SaveVariables[i][pTeam] 	= 	Player[playerid][Team];
	   	    SaveVariables[i][RKills]   	=  	Player[playerid][RoundKills];
			SaveVariables[i][RDeaths]  	= 	Player[playerid][RoundDeaths];
			SaveVariables[i][RDamage] 	= 	Player[playerid][RoundDamage];
			SaveVariables[i][TKills]   	=  	Player[playerid][TotalKills];
			SaveVariables[i][TDeaths]  	= 	Player[playerid][TotalDeaths];
			SaveVariables[i][TDamage] 	= 	Player[playerid][TotalDamage];
			SaveVariables[i][TPlayed]   =   Player[playerid][RoundPlayed];
			SaveVariables[i][sWasInBase] =  Player[playerid][WasInBase];

			#if defined _league_included
			PlayerShopSaves[i][SHOP_POINTS_DOUBLER] = PlayerShop[playerid][SHOP_POINTS_DOUBLER];
			PlayerShopSaves[i][SHOP_EXPLOSIVE_BELT] = PlayerShop[playerid][SHOP_EXPLOSIVE_BELT];
			PlayerShopSaves[i][SHOP_EXPLOSIVE_DEATH] = PlayerShop[playerid][SHOP_EXPLOSIVE_DEATH];
			PlayerShopSaves[i][SHOP_JETPACK] = PlayerShop[playerid][SHOP_JETPACK];
			PlayerShopSaves[i][SHOP_CHAINSAW] = PlayerShop[playerid][SHOP_CHAINSAW];
			PlayerShopSaves[i][SHOP_SPRAYCAN] = PlayerShop[playerid][SHOP_SPRAYCAN];
			PlayerShopSaves[i][SHOP_NINJA] = PlayerShop[playerid][SHOP_NINJA];
			#endif

			OnPlayerAmmoUpdate(playerid);
			SaveVariables[i][iAccuracy] =   floatround(Player[playerid][Accuracy], floatround_round);
			SaveVariables[i][tshotsHit] =   Player[playerid][TotalshotsHit];
			SaveVariables[i][tBulletsShot] = Player[playerid][TotalBulletsFired];

			SaveVariables[i][gHealth]  =   0;
			SaveVariables[i][gArmour]  =   0;

			SaveVariables[i][RoundID]   =   Current;
			SaveVariables[i][ToBeAdded] =   false;
			SaveVariables[i][CheckScore] = 	true;

			new weapID, weapAmmo = 0;
			GetPlayerWeaponData(playerid, 8, weapID, weapAmmo);
			if(weapID == WEAPON_GRENADE)
				SaveVariables[i][SavedGrenadeAmmo] = weapAmmo;
			else
				SaveVariables[i][SavedGrenadeAmmo] = 0;

			format(SaveVariables[i][pName], 24, Player[playerid][Name]);
			format(SaveVariables[i][pNameWithoutTag], 24, Player[playerid][NameWithoutTag]);

			if(GetPlayerWeapon(playerid) == WEAPON_PARACHUTE)
			    SaveVariables[i][HadParachute] = 1;
			else
			    SaveVariables[i][HadParachute] = 0;

			if(IsPlayerInAnyVehicle(playerid))
			{
			    SaveVariables[i][pVehicleID] = GetPlayerVehicleID(playerid);
			    SaveVariables[i][pSeatID] = GetPlayerVehicleSeat(playerid);
			}
			else
			{
			    SaveVariables[i][pVehicleID] = -1;
			    SaveVariables[i][pSeatID] = -1;
			}

			break;
		} else continue;
	}
	return 1;
}

StorePlayerVariables(playerid) {
	new iString[128];
	for(new i = 0; i < SAVE_SLOTS; i ++){
	   	if(strlen(SaveVariables[i][pName]) < 2){
			format(SaveVariables[i][pName], 24, Player[playerid][Name]);
			format(SaveVariables[i][pNameWithoutTag], 24, Player[playerid][NameWithoutTag]);

	       	GetPlayerPos(playerid, SaveVariables[i][pCoords][0],SaveVariables[i][pCoords][1],SaveVariables[i][pCoords][2]);
	 		GetPlayerFacingAngle(playerid, SaveVariables[i][pCoords][3]);

			if(Player[i][ToAddInRound] == false) {
				GetHP(playerid, SaveVariables[i][gHealth]);
				GetAP(playerid, SaveVariables[i][gArmour]);
			} else {
			    SaveVariables[i][gArmour] = 100;
			    SaveVariables[i][gHealth] = 100;
			}

	   	    SaveVariables[i][pTeam] = Player[playerid][Team];
	        SaveVariables[i][pInterior] = 	GetPlayerInterior(playerid);
	        SaveVariables[i][pVWorld] 	= 	GetPlayerVirtualWorld(playerid);

			SaveVariables[i][RKills]   	=  	Player[playerid][RoundKills];
			SaveVariables[i][RDeaths]  	= 	Player[playerid][RoundDeaths];
			SaveVariables[i][RDamage] 	= 	Player[playerid][RoundDamage];
			SaveVariables[i][TKills]   	=  	Player[playerid][TotalKills];
			SaveVariables[i][TDeaths]  	= 	Player[playerid][TotalDeaths];
			SaveVariables[i][TDamage] 	= 	Player[playerid][TotalDamage];
			SaveVariables[i][TPlayed]   =   Player[playerid][RoundPlayed];
			SaveVariables[i][sWasInBase] =  Player[playerid][WasInBase];

			#if defined _league_included
			PlayerShopSaves[i][SHOP_POINTS_DOUBLER] = PlayerShop[playerid][SHOP_POINTS_DOUBLER];
			PlayerShopSaves[i][SHOP_EXPLOSIVE_BELT] = PlayerShop[playerid][SHOP_EXPLOSIVE_BELT];
			PlayerShopSaves[i][SHOP_EXPLOSIVE_DEATH] = PlayerShop[playerid][SHOP_EXPLOSIVE_DEATH];
			PlayerShopSaves[i][SHOP_JETPACK] = PlayerShop[playerid][SHOP_JETPACK];
			PlayerShopSaves[i][SHOP_CHAINSAW] = PlayerShop[playerid][SHOP_CHAINSAW];
			PlayerShopSaves[i][SHOP_SPRAYCAN] = PlayerShop[playerid][SHOP_SPRAYCAN];
			PlayerShopSaves[i][SHOP_NINJA] = PlayerShop[playerid][SHOP_NINJA];
			#endif

			OnPlayerAmmoUpdate(playerid);
			SaveVariables[i][iAccuracy] =  floatround(Player[playerid][Accuracy], floatround_round);
			SaveVariables[i][tshotsHit] =   Player[playerid][TotalshotsHit];
			SaveVariables[i][tBulletsShot] = Player[playerid][TotalBulletsFired];

			for(new j = 0; j < MAX_GUNMENU_GUNS; j ++)
			{
				SaveVariables[i][HadGunmenuGun][j] = GunmenuData[j][HasGun][playerid];
			}

			SaveVariables[i][RoundID]   =   Current;
			SaveVariables[i][ToBeAdded] =   true;
			SaveVariables[i][CheckScore] = 	true;

			new weapID, weapAmmo = 0;
			GetPlayerWeaponData(playerid, 8, weapID, weapAmmo);
			if(weapID == WEAPON_GRENADE)
				SaveVariables[i][SavedGrenadeAmmo] = weapAmmo;
			else
				SaveVariables[i][SavedGrenadeAmmo] = 0;

			if(GetPlayerWeapon(playerid) == WEAPON_PARACHUTE)
			    SaveVariables[i][HadParachute] = 1;
			else
			    SaveVariables[i][HadParachute] = 0;

			if(IsPlayerInAnyVehicle(playerid))
			{
			    SaveVariables[i][pVehicleID] = GetPlayerVehicleID(playerid);
			    SaveVariables[i][pSeatID] = GetPlayerVehicleSeat(playerid);
			}
			else
			{
			    SaveVariables[i][pVehicleID] = -1;
			    SaveVariables[i][pSeatID] = -1;
			}

			if(Current != -1 && (AllowStartBase == false || ElapsedTime < 20) && (Player[i][ToAddInRound] || Player[i][Playing]))
				SaveVariables[i][WasCrashedInStart] = true;

	        format(iString,sizeof(iString),"{FFFFFF}%s's "COL_PRIM"data saved.", Player[playerid][Name]);
	    	SendClientMessageToAll(-1, iString);
	    	break;
        } else continue;
	}
}

// Note: this function returns team id if the player is supposed to be re-added to round, otherwise -1
ShouldPlayerBeReadded(playerid)
{
	for(new i = 0; i < SAVE_SLOTS; i ++)
	{
		if( strlen( SaveVariables[i][pName] ) >= 2 && strcmp( SaveVariables[i][pName], Player[playerid][Name], true ) == 0 )
		{
			if(SaveVariables[i][RoundID] != Current || Current == -1 || SaveVariables[i][ToBeAdded] == false)
			{
				return -1;
			}
			else
			{
				return SaveVariables[i][pTeam];
			}
		}
	}
	return -1;
}

LoadPlayerVariables(playerid)
{
 	new iString[160];

	for(new i = 0; i < SAVE_SLOTS; i ++)
	{
		if( strlen( SaveVariables[i][pName] ) >= 2 && strcmp( SaveVariables[i][pName], Player[playerid][Name], true ) == 0 )
		{
			if(SaveVariables[i][RoundID] != Current || Current == -1)
			{
				Player[playerid][TotalKills] 		= 	SaveVariables[i][TKills];
				Player[playerid][TotalDeaths] 		= 	SaveVariables[i][TDeaths];
				Player[playerid][TotalDamage] 		= 	SaveVariables[i][TDamage];
                Player[playerid][RoundPlayed] 		= 	SaveVariables[i][TPlayed];
                Player[playerid][Accuracy]      	=   SaveVariables[i][iAccuracy];
			 	Player[playerid][TotalshotsHit]		=	SaveVariables[i][tshotsHit];
			 	Player[playerid][TotalBulletsFired] = 	SaveVariables[i][tBulletsShot];

				#if defined _league_included
				PlayerShop[playerid][SHOP_POINTS_DOUBLER] = PlayerShopSaves[i][SHOP_POINTS_DOUBLER];
				PlayerShop[playerid][SHOP_EXPLOSIVE_BELT] = PlayerShopSaves[i][SHOP_EXPLOSIVE_BELT];
				PlayerShop[playerid][SHOP_EXPLOSIVE_DEATH] = PlayerShopSaves[i][SHOP_EXPLOSIVE_DEATH];
				PlayerShop[playerid][SHOP_JETPACK] = PlayerShopSaves[i][SHOP_JETPACK];
				PlayerShop[playerid][SHOP_CHAINSAW] = PlayerShopSaves[i][SHOP_CHAINSAW];
				PlayerShop[playerid][SHOP_SPRAYCAN] = PlayerShopSaves[i][SHOP_SPRAYCAN];
				PlayerShop[playerid][SHOP_NINJA] = PlayerShopSaves[i][SHOP_NINJA];

				if(PlayerShop[playerid][SHOP_CHAINSAW])
				{
					GivePlayerWeapon(playerid, WEAPON_CHAINSAW, 1);
				}
				if(PlayerShop[playerid][SHOP_SPRAYCAN])
				{
					GivePlayerWeapon(playerid, WEAPON_SPRAYCAN, 9999);
				}
				#endif

                ResetSaveVariables(i);

				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has spawned as: {FFFFFF}%s", Player[playerid][Name], TeamName[Player[playerid][Team]]);
				SendClientMessageToAll(-1, iString);

				UpdateRoundKillDmgTDmg(playerid);
				return 1;
			}
			else if(SaveVariables[i][ToBeAdded] == false)
			{
				Player[playerid][TotalKills] 		= 	SaveVariables[i][TKills];
				Player[playerid][TotalDeaths] 		= 	SaveVariables[i][TDeaths];
				Player[playerid][TotalDamage] 		= 	SaveVariables[i][TDamage];
				Player[playerid][RoundPlayed] 		= 	SaveVariables[i][TPlayed];
				Player[playerid][Accuracy]      	=   SaveVariables[i][iAccuracy];
			 	Player[playerid][TotalshotsHit]		=	SaveVariables[i][tshotsHit];
			 	Player[playerid][TotalBulletsFired] = 	SaveVariables[i][tBulletsShot];
				Player[playerid][RoundKills]        =   SaveVariables[i][RKills];
				Player[playerid][RoundDeaths]       =	SaveVariables[i][RDeaths];
				Player[playerid][RoundDamage]       =	SaveVariables[i][RDamage];
				Player[playerid][WasInBase]         =   SaveVariables[i][sWasInBase];

				#if defined _league_included
				PlayerShop[playerid][SHOP_POINTS_DOUBLER] = PlayerShopSaves[i][SHOP_POINTS_DOUBLER];
				PlayerShop[playerid][SHOP_EXPLOSIVE_BELT] = PlayerShopSaves[i][SHOP_EXPLOSIVE_BELT];
				PlayerShop[playerid][SHOP_EXPLOSIVE_DEATH] = PlayerShopSaves[i][SHOP_EXPLOSIVE_DEATH];
				PlayerShop[playerid][SHOP_JETPACK] = PlayerShopSaves[i][SHOP_JETPACK];
				PlayerShop[playerid][SHOP_CHAINSAW] = PlayerShopSaves[i][SHOP_CHAINSAW];
				PlayerShop[playerid][SHOP_SPRAYCAN] = PlayerShopSaves[i][SHOP_SPRAYCAN];
				PlayerShop[playerid][SHOP_NINJA] = PlayerShopSaves[i][SHOP_NINJA];

				if(PlayerShop[playerid][SHOP_CHAINSAW])
				{
					GivePlayerWeapon(playerid, WEAPON_CHAINSAW, 1);
				}
				if(PlayerShop[playerid][SHOP_SPRAYCAN])
				{
					GivePlayerWeapon(playerid, WEAPON_SPRAYCAN, 9999);
				}
				#endif

                ResetSaveVariables(i);

				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has spawned as: {FFFFFF}%s", Player[playerid][Name], TeamName[Player[playerid][Team]]);
				SendClientMessageToAll(-1, iString);

				UpdateRoundKillDmgTDmg(playerid);
				return 1;
			}

			Player[playerid][Playing] = true;
			Player[playerid][WasInBase] = true;
			Iter_Add(PlayersInRound, playerid);

	        Player[playerid][Team] = SaveVariables[i][pTeam];
			Player[playerid][WasInTeam] = Player[playerid][Team];

			Player[playerid][RoundKills] 	= 	SaveVariables[i][RKills];
			Player[playerid][RoundDeaths] 	= 	SaveVariables[i][RDeaths];
			Player[playerid][RoundDamage] 	= 	SaveVariables[i][RDamage];
			Player[playerid][TotalKills] 	= 	SaveVariables[i][TKills];
			Player[playerid][TotalDeaths] 	= 	SaveVariables[i][TDeaths];
			Player[playerid][TotalDamage] 	= 	SaveVariables[i][TDamage];
			Player[playerid][RoundPlayed] 	= 	SaveVariables[i][TPlayed];
			Player[playerid][Accuracy]      =   SaveVariables[i][iAccuracy];
		 	Player[playerid][TotalshotsHit]	=	SaveVariables[i][tshotsHit];
		 	Player[playerid][TotalBulletsFired] = SaveVariables[i][tBulletsShot];

    	 	if(SaveVariables[i][WasCrashedInStart] == false) {
			 	SetSpawnInfo(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], SaveVariables[i][pCoords][0], SaveVariables[i][pCoords][1], SaveVariables[i][pCoords][2]+1, SaveVariables[i][pCoords][3], 0, 0, 0, 0, 0, 0);

			 	SetPlayerInterior(playerid, SaveVariables[i][pInterior]);
			 	SetPlayerVirtualWorld(playerid, SaveVariables[i][pVWorld]);
		 	} else if(Current != -1) {
	    	 	if(GameType == BASE) {
				 	switch(Player[playerid][Team]) {
					 	case ATTACKER: SetSpawnInfo(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], BAttackerSpawn[Current][0] + random(6), BAttackerSpawn[Current][1] + random(6), BAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
					 	case DEFENDER: SetSpawnInfo(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], BDefenderSpawn[Current][0] + random(6), BDefenderSpawn[Current][1] + random(6), BDefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
		    	 	}
		    	 	SetPlayerInterior(playerid, BInterior[Current]);
			 	} else if(GameType == ARENA) {
				 	switch(Player[playerid][Team]) {
					 	case ATTACKER: SetSpawnInfo(playerid, Player[playerid][Team], Skin[Player[playerid][Team]],AAttackerSpawn[Current][0] + random(6), AAttackerSpawn[Current][1] + random(6), AAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
					 	case DEFENDER: SetSpawnInfo(playerid, Player[playerid][Team], Skin[Player[playerid][Team]],ADefenderSpawn[Current][0] + random(6), ADefenderSpawn[Current][1] + random(6), ADefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
				 	}
		    	 	SetPlayerInterior(playerid, AInterior[Current]);
			 	}
			 	SetPlayerVirtualWorld(playerid, 2);
		 	}

			Player[playerid][IgnoreSpawn] = true;
	        SpawnPlayer(playerid);

			ShowTeamBarsForPlayer(playerid);
			CreatePlayerTeamBar(playerid);

			ShowTeamCornerInfo(playerid);
			UpdateTeamCornerInfo();

			UpdateTeamPlayerCount(Player[playerid][Team], false);
			SetHP(playerid, SaveVariables[i][gHealth]);
			SetAP(playerid, SaveVariables[i][gArmour]);
			UpdateTeamHP(Player[playerid][Team]);

			ColorFix(playerid);
			SetPlayerTeam(playerid, Player[playerid][Team]);
   			RadarFix();
			SetCPForPlayer(playerid);

	        if(GameType == BASE)
			{
				new team = Player[playerid][Team];
				new ct = 0;
				for(new j = 0; j < MAX_GUNMENU_GUNS; j ++)
				{
					if(SaveVariables[i][HadGunmenuGun][j])
					{
						if(GunmenuData[j][TimesSelected][team] == GunmenuData[j][GunLimit])
						{
							ct = -1;
							ResetPlayerGunmenu(playerid, false);
							ShowPlayerGunmenu(playerid, 500);
							SendErrorMessage(playerid, sprintf("This weapon is no longer available because limit has exceeded. [%d/%d]", GunmenuData[j][GunLimit], GunmenuData[j][GunLimit]));
							break;
						}
						else
						{
							ct ++;
							GivePlayerWeapon(playerid, GunmenuData[j][GunID], GunmenuData[j][GunAmmo]);
							GunmenuData[j][HasGun][playerid] = true;
							GunmenuData[j][TimesSelected][team] --;
						}
					}
				}
				if(ct == 0)
				{
					ResetPlayerGunmenu(playerid, false);
					ShowPlayerGunmenu(playerid, 500);
				}
                if(SaveVariables[i][HadParachute] == 1)
				{
				    GivePlayerWeapon(playerid, WEAPON_PARACHUTE, 1);
				    SetPlayerArmedWeapon(playerid, WEAPON_PARACHUTE);
				}
				else
					SetPlayerArmedWeapon(playerid, 0);

				if(SaveVariables[i][pVehicleID] != -1)
				{
				    SetTimerEx("RespawnInVehicleAfterComeBack", 500, false, "ddd", playerid, SaveVariables[i][pVehicleID], SaveVariables[i][pSeatID]);
				}
			}
			else if(GameType == ARENA)
			{
				new team = Player[playerid][Team];
				for(new j = 0; j < MAX_GUNMENU_GUNS; j ++)
				{
					if(SaveVariables[i][HadGunmenuGun][j])
					{
						GivePlayerWeapon(playerid, GunmenuData[j][GunID], GunmenuData[j][GunAmmo]);
						GunmenuData[j][HasGun][playerid] = true;
						GunmenuData[j][TimesSelected][team] --;
					}
				}
				GangZoneShowForPlayer(playerid, ArenaZone, 0x95000099);
			}
			if(RoundPaused == true) {
				TogglePlayerControllable(playerid, 0);
				TextDrawShowForAll(PauseTD);
			}
			else
				TogglePlayerControllable(playerid, 1);

			#if defined _league_included
			if(LeagueAllowed)
			{
				CheckLeagueMatchValidity(1000);
			}
			#endif

	        format(iString,sizeof(iString),""COL_PRIM"Re-added player {FFFFFF}%s. "COL_PRIM"Data fetched successfully.", Player[playerid][Name]);
	    	SendClientMessageToAll(-1, iString);

			if(!Player[playerid][FakePacketRenovation] && Player[playerid][NetCheck] && NetStats_GetConnectedTime(playerid) < 300000)
			{
				SetTimerEx("FakePacketRenovationEnd", 30000, false, "ifb", playerid, NetStats_PacketLossPercent(playerid), false);
				Player[playerid][FakePacketRenovation] = true;
			}

			UpdateRoundKillDmgTDmg(playerid);

			SaveVariables[i][PauseWait] = false;

			ResetSaveVariables(i);
	    	return 1;
		}
	}
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has spawned as: {FFFFFF}%s", Player[playerid][Name], TeamName[Player[playerid][Team]]);
	SendClientMessageToAll(-1, iString);
	return 1;
}

ResetSaveVariables(index) {

    SaveVariables[index][pCoords][0] = 0.0;
	SaveVariables[index][pCoords][1] = 0.0;
	SaveVariables[index][pCoords][2] = 0.0;
	SaveVariables[index][pCoords][3] = 0.0;

	format(SaveVariables[index][pName], 24, "");

	SaveVariables[index][gHealth] = 0;
	SaveVariables[index][gArmour] = 0;
	SaveVariables[index][pInterior] = 0;
	SaveVariables[index][pVWorld] = 0;
    SaveVariables[index][pTeam] = 0;
    SaveVariables[index][RKills] = 0;
	SaveVariables[index][RDeaths] = 0;
    SaveVariables[index][RDamage] = 0;
    SaveVariables[index][TKills] = 0;
    SaveVariables[index][TDeaths] = 0;
    SaveVariables[index][TDamage] = 0;
	SaveVariables[index][sWasInBase] = false;
    SaveVariables[index][RoundID] = -1;
    SaveVariables[index][WasCrashedInStart] = false;
    SaveVariables[index][ToBeAdded] = false;
    SaveVariables[index][CheckScore] = false;
    SaveVariables[index][PauseWait] = false;
    SaveVariables[index][pVehicleID] = -1;
    SaveVariables[index][pSeatID] = -1;
    SaveVariables[index][HadParachute] = 0;
	SaveVariables[index][SavedGrenadeAmmo] = 0;
	for(new i = 0; i < MAX_GUNMENU_GUNS; i ++)
		SaveVariables[index][HadGunmenuGun][i] = false;

	#if defined _league_included
	PlayerShopSaves[index][SHOP_POINTS_DOUBLER] = false;
	PlayerShopSaves[index][SHOP_EXPLOSIVE_BELT] = false;
	PlayerShopSaves[index][SHOP_EXPLOSIVE_DEATH] = false;
	PlayerShopSaves[index][SHOP_JETPACK] = false;
	PlayerShopSaves[index][SHOP_CHAINSAW] = false;
	PlayerShopSaves[index][SHOP_SPRAYCAN] = false;
	PlayerShopSaves[index][SHOP_NINJA] = false;
	#endif
}

ClearPlayerVariables()
{
	for(new i = 0; i < SAVE_SLOTS; i ++) {
		ResetSaveVariables(i);
	}
}
