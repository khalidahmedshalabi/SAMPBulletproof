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
		ShowPlayerDeathQuote(playerid, DEATH_CAMERA_DURATION);
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

ShowPlayerDeathQuote(playerid, duration)
{
	switch(random(17))
	{
		case 0:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~George S. Patton", "The object of war is not to die for your country but to make the other bastard die for his", duration);
		}
		case 1:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Winston Churchill", "We shall defend our island, whatever the cost may be, we shall fight on the beaches, we shall fight on the landing grounds, we shall fight in the fields and in the streets, we shall fight in the hills; we shall never surrender", duration);
		}
		case 2:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Dwight D. Eisenhower", "Every gun that is made, every warship launched, every rocket fired, signifies in the final sense a theft from those who hunger and are not fed, those who are cold and are not clothed", duration);
		}
		case 3:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Jean-Paul Sartre", "When the rich wage war, it's the poor who die", duration);
		}
		case 4:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Voltaire", "It is forbidden to kill; therefore all murderers are punished unless they kill in large numbers and to the sound of trumpets", duration);
		}
		case 5:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~H. G. Wells", "If we don't end war, war will end us", duration);
		}
		case 6:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Ernest Hemingway", "In modern war... you will die like a dog for no good reason", duration);
		}
		case 7:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Bertrand Russell", "War does not determine who is right - only who is left", duration);
		}
		case 8:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~George Santayana", "Only the dead have seen the end of the war", duration);
		}
		case 9:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Unknown", "The journey of a thousand miles begins with one step, and a lot of bitching", duration);
		}
		case 10:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Bumper Sticker", "Don't tell mom I'm a pilot, she thinks I play piano in a whorehouse", duration);
		}
		case 11:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Soviet infantry manual", "Do not touch anything unnecessarily. Beware of pretty girls in dance halls and parks who may be spies, as well as bicycles, revolvers, uniforms, arms, dead horses, and men lying on roads - they are not there accidentally", duration);
		}
		case 12:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~George Wallace", "Why does the Air Force need expensive new bombers? Have the people we've been bombing over the years been complaining?", duration);
		}
		case 13:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Infantry Journal", "If the enemy is in range, so are you", duration);
		}
		case 14:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~USAF Ammo Troop", "If you see a bomb technician running, follow him", duration);
		}
		case 15:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Mark Twain", "God created war so that Americans would learn geography", duration);
		}
		case 16:
		{
			MessageBox(playerid, MSGBOX_TYPE_MIDDLE, "~r~~h~~h~Malcolm X", "Sometimes you have to pick the gun up to put the Gun down", duration);
		}
	}
}