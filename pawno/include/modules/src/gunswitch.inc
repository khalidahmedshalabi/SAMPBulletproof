/*
		Alternative Gun Switching
*/

#include "modules\header\gunswitch.txt"

CreateGunSwitchGlobalTextDraws()
{
	GunSwitchMainCircles[0] = TextDrawCreate(225.000000, 14.000000, "ld_pool:ball");
	TextDrawAlignment(GunSwitchMainCircles[0], 3);
	TextDrawBackgroundColor(GunSwitchMainCircles[0], 255);
	TextDrawFont(GunSwitchMainCircles[0], 4);
	TextDrawLetterSize(GunSwitchMainCircles[0], 0.039999, 0.199999);
	TextDrawColor(GunSwitchMainCircles[0], -1195853773);
	TextDrawSetOutline(GunSwitchMainCircles[0], 0);
	TextDrawSetProportional(GunSwitchMainCircles[0], 1);
	TextDrawSetShadow(GunSwitchMainCircles[0], 1);
	TextDrawUseBox(GunSwitchMainCircles[0], 1);
	TextDrawBoxColor(GunSwitchMainCircles[0], -1195853773);
	TextDrawTextSize(GunSwitchMainCircles[0], 246.000000, 260.000000);

	GunSwitchMainCircles[1] = TextDrawCreate(277.000000, 75.000000, "ld_pool:ball");
	TextDrawAlignment(GunSwitchMainCircles[1], 3);
	TextDrawBackgroundColor(GunSwitchMainCircles[1], 255);
	TextDrawFont(GunSwitchMainCircles[1], 4);
	TextDrawLetterSize(GunSwitchMainCircles[1], 0.039999, 0.199999);
	TextDrawColor(GunSwitchMainCircles[1], -1970631937);
	TextDrawSetOutline(GunSwitchMainCircles[1], 0);
	TextDrawSetProportional(GunSwitchMainCircles[1], 1);
	TextDrawSetShadow(GunSwitchMainCircles[1], 1);
	TextDrawUseBox(GunSwitchMainCircles[1], 1);
	TextDrawBoxColor(GunSwitchMainCircles[1], -1701143484);
	TextDrawTextSize(GunSwitchMainCircles[1], 143.000000, 137.000000);
}

CreateGunSwitchTextDraws(playerid)
{
	new const Float:angle_change = 360.0 / float(MAX_GUN_SWITCH_SLOTS);
	new 
		Float:x,
		Float:y,
		Float:angle = 0.0;
	for(new i = 0; i < MAX_GUN_SWITCH_SLOTS; i ++)
	{
		x = gunSwitchCenterX + (GUN_SWITCH_CIRCLE_RADIUS * floatcos(angle, degrees));
		y = gunSwitchCenterY + (GUN_SWITCH_CIRCLE_RADIUS * floatsin(angle, degrees));
		GunSwitchData[playerid][GunSlotTextDraw][i] = CreatePlayerTextDraw(playerid, x, y, "_");
		PlayerTextDrawFont(playerid, GunSwitchData[playerid][GunSlotTextDraw][i], TEXT_DRAW_FONT_MODEL_PREVIEW);
		PlayerTextDrawUseBox(playerid, GunSwitchData[playerid][GunSlotTextDraw][i], 0);
		PlayerTextDrawBackgroundColor(playerid, GunSwitchData[playerid][GunSlotTextDraw][i], 0x00000000);
		PlayerTextDrawTextSize(playerid, GunSwitchData[playerid][GunSlotTextDraw][i], 60.0, 50.0);
		PlayerTextDrawSetPreviewModel(playerid, GunSwitchData[playerid][GunSlotTextDraw][i], -1);
		PlayerTextDrawSetPreviewRot(playerid, GunSwitchData[playerid][GunSlotTextDraw][i], 0.0, 0.0, 0.0, 2.0);
		PlayerTextDrawSetSelectable(playerid, GunSwitchData[playerid][GunSlotTextDraw][i], 1);
		angle += angle_change;
	}
}

forward DisablePlayerGunSwitchInterface(playerid);
public DisablePlayerGunSwitchInterface(playerid)
{
	if(!Player[playerid][OnGunSwitch])
		return 0;
	
	for(new i = 0; i < MAX_GUN_SWITCH_SLOTS; i ++)
	{
		if(!GunSwitchData[playerid][GunSwitchSlotShown][i])
			continue;
		
		PlayerTextDrawHide(playerid, GunSwitchData[playerid][GunSlotTextDraw][i]);
		GunSwitchData[playerid][GunSwitchSlotShown][i] = false;
	}
	for(new i = 0; i < sizeof GunSwitchMainCircles; i ++)
	{
		TextDrawHideForPlayer(playerid, GunSwitchMainCircles[i]);
	}
	TextDrawHideForPlayer(playerid, DarkScreen);
	CancelSelectTextDraw(playerid);
	Player[playerid][OnGunSwitch] = false;
	return 1;
}

EnablePlayerGunSwitchInterface(playerid)
{
	if(IsPlayerInAnyVehicle(playerid))
		return;
	
	if(Player[playerid][OnGunmenu])
		return;
	
	if(Player[playerid][LastEnterVehicleAttempt] > GetTickCount())
		return;
	
	if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK)
		return;
	
	// climbing animations
	if(GetPlayerAnimationIndex(playerid) == 1061 || GetPlayerAnimationIndex(playerid) == 1062 || GetPlayerAnimationIndex(playerid) == 1063 || GetPlayerAnimationIndex(playerid) == 1064 || GetPlayerAnimationIndex(playerid) == 1065 || GetPlayerAnimationIndex(playerid) == 1066)   
		return;

	if(Player[playerid][OnGunSwitch])
		DisablePlayerGunSwitchInterface(playerid);
	
	new tmpWeapon, tmpAmmo, ct = 0, modelid;
	new i = 0;
	while(i != MAX_GUN_SWITCH_SLOTS && ct != MAX_GUN_SWITCH_SLOTS)
	{
		GetPlayerWeaponData(playerid, i, tmpWeapon, tmpAmmo);
		if(tmpAmmo > 0)
		{
			modelid = GetWeaponModelFromID(tmpWeapon);
			PlayerTextDrawSetPreviewModel(playerid, GunSwitchData[playerid][GunSlotTextDraw][ct], modelid);
			GunSwitchData[playerid][GunSwitchModelID][ct] = modelid;
			PlayerTextDrawShow(playerid, GunSwitchData[playerid][GunSlotTextDraw][ct]);
			GunSwitchData[playerid][GunSwitchSlotShown][ct] = true;
			ct ++;
		}
		i ++;
	}
	if(ct != 0)
	{
		for(i = 0; i < sizeof GunSwitchMainCircles; i ++)
		{
			TextDrawShowForPlayer(playerid, GunSwitchMainCircles[i]);
		}
		TextDrawShowForPlayer(playerid, DarkScreen);
		SelectTextDraw(playerid, 0xFF000044);
		Player[playerid][OnGunSwitch] = true;
	}
}