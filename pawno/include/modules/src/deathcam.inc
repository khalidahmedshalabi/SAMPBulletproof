/*
		Death camera script
*/

#include "modules\header\deathcam.txt"

forward OnPlayerDeathCameraEnd(playerid);
public OnPlayerDeathCameraEnd(playerid)
{
	if(!Player[playerid][InDeathCamera])
		return 0;
	
	Player[playerid][InDeathCamera] = false;
	OnPlayerSpawn(playerid);
	Player[playerid][IgnoreSpawn] = false;
	TogglePlayerSpectating(playerid, false);
	HideMessageBox(playerid, -1);
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
	return 1;
}

PlayDeathCamera(playerid, Float:deathX, Float:deathY, Float:deathZ, bool:deathquote)
{
	if(Player[playerid][InDeathCamera])
		return;
	
	if(deathquote)
	{
		new randWarQuote = random(MAX_WAR_QUOTES);
		MessageBox(playerid, MSGBOX_TYPE_MIDDLE, sprintf("~r~~h~~h~%s", WarQuotesAuthors[randWarQuote]), WarQuotes[randWarQuote], DEATH_CAMERA_DURATION);
	}
	
	// Hide some HUD textdraws
	PlayerTextDrawHide(playerid, RoundKillDmgTDmg[playerid]);
	PlayerTextDrawHide(playerid, HPTextDraw_TD[playerid]);
	HidePlayerProgressBar(playerid, HealthBar[playerid]);
	HidePlayerProgressBar(playerid, ArmourBar[playerid]);
	#if defined _league_included
	PlayerTextDrawHide(playerid, PlayerLeagueStatsTD[playerid]);
	#endif
	
	TogglePlayerSpectating(playerid, true);
	new randomCameraMove = random(3);
	switch(randomCameraMove)
	{
		// Look at the dead body at the beginning from a low height and then get higher with the camera slowly while changing X/Y position
		case 0:
		{
			InterpolateCameraPos(playerid, deathX + 1.0, deathY, deathZ, deathX, deathY + 1.0, deathZ + 2.0, DEATH_CAMERA_DURATION, CAMERA_MOVE);
		}
		// Look at the dead body at the beginning from a high level and then change X/Y position while getting lower with the camera slowly
		case 1:
		{
			InterpolateCameraPos(playerid, deathX, deathY + 1.0, deathZ + 2.0, deathX + 1.0, deathY, deathZ, DEATH_CAMERA_DURATION, CAMERA_MOVE);
		}
		// Look at the dead body at the beginning from the same level of the body and then change X/Y position while staying at the same height
		case 2:
		{
			InterpolateCameraPos(playerid, deathX - 1.0, deathY, deathZ - 0.2, deathX, deathY + 2.0, deathZ - 0.2, DEATH_CAMERA_DURATION, CAMERA_MOVE);
		}
	}
	InterpolateCameraLookAt(playerid, deathX, deathY, deathZ - 0.2, deathX, deathY, deathZ - 0.2, DEATH_CAMERA_DURATION, CAMERA_MOVE);
	Player[playerid][InDeathCamera] = true;
	SetTimerEx("OnPlayerDeathCameraEnd", DEATH_CAMERA_DURATION, false, "i", playerid);
}