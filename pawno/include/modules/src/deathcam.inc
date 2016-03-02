/*
		Death camera script
*/

#include "modules\header\deathcam.txt"

forward OnPlayerDeathCameraEnd(playerid);
public OnPlayerDeathCameraEnd(playerid)
{
	if(!Player[playerid][InDeathCamera])
		return 0;
	
	SetPlayerDrunkLevel(playerid, 0);
	CancelFlyMode(playerid);
	Player[playerid][InDeathCamera] = false;
	OnPlayerSpawn(playerid);
	Player[playerid][IgnoreSpawn] = false;
	HideMessageBox(playerid, -1);
	TextDrawHideForPlayer(playerid, RedDeathScreen);
	switch(PlayerInterface[playerid][INTERFACE_HP])
	{
		case true:
		{
			PlayerTextDrawShow(playerid, HPTextDraw_TD[playerid]);
			PlayerTextDrawShow(playerid, ArmourTextDraw[playerid]);
		}
	}
	PlayerTextDrawShow(playerid, RoundKillDmgTDmg[playerid]);
	if(PlayerInterface[playerid][INTERFACE_NET])
		PlayerTextDrawShow(playerid, FPSPingPacket[playerid]);
	PlayerTextDrawShow(playerid, BaseID_VS[playerid]);
	ShowPlayerProgressBar(playerid, HealthBar[playerid]);
	ShowPlayerProgressBar(playerid, ArmourBar[playerid]);
	#if defined _league_included
	if(LeagueMode)
	{
		PlayerTextDrawShow(playerid, PlayerLeagueStatsTD[playerid]);
	}
	#endif
	if(Current != -1)
	{
		SetTimerEx("SpectateAnyPlayerT", 1000, false, "i", playerid);
	}
	return 1;
}

PlayDeathCamera(playerid, bool:deathquote)
{
	if(Player[playerid][InDeathCamera])
		return;
	
	if(deathquote)
	{
		new randWarQuote = random(MAX_WAR_QUOTES);
		MessageBox(playerid, MSGBOX_TYPE_MIDDLE, sprintf("~r~~h~~h~%s", WarQuotesAuthors[randWarQuote]), WarQuotes[randWarQuote], DEATH_CAMERA_DURATION);
	}
	
	TextDrawShowForPlayer(playerid, RedDeathScreen);
	// Hide some HUD textdraws
	PlayerTextDrawHide(playerid, RoundKillDmgTDmg[playerid]);
	PlayerTextDrawHide(playerid, HPTextDraw_TD[playerid]);
	HidePlayerProgressBar(playerid, HealthBar[playerid]);
	HidePlayerProgressBar(playerid, ArmourBar[playerid]);
	#if defined _league_included
	PlayerTextDrawHide(playerid, PlayerLeagueStatsTD[playerid]);
	#endif
	
	SetPlayerDrunkLevel(playerid, 50000);
	TogglePlayerSpectating(playerid, true);
	SetTimerEx("PlayerFlyMode", 200, false, "ib", playerid, true);
	
	Player[playerid][InDeathCamera] = true;
	SetTimerEx("OnPlayerDeathCameraEnd", DEATH_CAMERA_DURATION, false, "i", playerid);
	MessageBox(playerid, MSGBOX_TYPE_BOTTOM, "~y~~h~~h~~h~tip", "Press ~r~~h~~h~~k~~PED_FIREWEAPON~ ~w~to skip death camera!", DEATH_CAMERA_DURATION);
}