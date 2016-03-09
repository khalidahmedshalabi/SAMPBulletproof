/*
		Makes textdraws auto fade
*/

#include "modules\header\hooking\fadefunction.txt"

#include "modules\header\config.txt"

// Hooked textdraw functions to store color, usebox, boxcolor in variables

stock Text:_HOOKED_TextDrawCreate(Float:x, Float:y, text[])
{
	new Text:_RET_TD = TextDrawCreate(x, y, text);
	HookTextDraw[_RET_TD][TDUseBox] = 0;
	return _RET_TD;
}

#if defined _ALS_TextDrawCreate
	#undef TextDrawCreate
#else
	#define _ALS_TextDrawCreate
#endif

#define TextDrawCreate _HOOKED_TextDrawCreate

stock PlayerText:_HOOKED_CreatePlayerTextDraw(playerid, Float:x, Float:y, text[])
{
	new PlayerText:_RET_PTD = CreatePlayerTextDraw(playerid, x, y, text);
	HookPlayerTextDraw[_RET_PTD][PTDUseBox] = 0;
	return _RET_PTD;
}

#if defined _ALS_CreatePlayerTextDraw
	#undef CreatePlayerTextDraw
#else
	#define _ALS_CreatePlayerTextDraw
#endif

#define CreatePlayerTextDraw _HOOKED_CreatePlayerTextDraw

stock _HOOKED_TextDrawColor(Text:text, color)
{
	HookTextDraw[text][TDColor] = color;
	return TextDrawColor(text, color);
}

#if defined _ALS_TextDrawColor
	#undef TextDrawColor
#else
	#define _ALS_TextDrawColor
#endif

#define TextDrawColor _HOOKED_TextDrawColor

stock _HOOKED_PlayerTextDrawColor(playerid, PlayerText:text, color)
{
	HookPlayerTextDraw[text][PTDColor] = color;
	return PlayerTextDrawColor(playerid, text, color);
}

#if defined _ALS_PlayerTextDrawColor
	#undef PlayerTextDrawColor
#else
	#define _ALS_PlayerTextDrawColor
#endif

#define PlayerTextDrawColor _HOOKED_PlayerTextDrawColor

stock _HOOKED_TextDrawUseBox(Text:text, use)
{
	HookTextDraw[text][TDUseBox] = use;
	return TextDrawUseBox(Text:text, use);
}

#if defined _ALS_TextDrawUseBox
	#undef TextDrawUseBox
#else
	#define _ALS_TextDrawUseBox
#endif

#define TextDrawUseBox _HOOKED_TextDrawUseBox

stock _HOOKED_PlayerTextDrawUseBox(playerid, PlayerText:text, use)
{
	HookPlayerTextDraw[text][PTDUseBox] = use;
	return PlayerTextDrawUseBox(playerid, text, use);
}

#if defined _ALS_PlayerTextDrawUseBox
	#undef PlayerTextDrawUseBox
#else
	#define _ALS_PlayerTextDrawUseBox
#endif

#define PlayerTextDrawUseBox _HOOKED_PlayerTextDrawUseBox

stock _HOOKED_TextDrawBoxColor(Text:text, color)
{
	HookTextDraw[text][TDBoxColor] = color;
	return TextDrawBoxColor(Text:text, color);
}

#if defined _ALS_TextDrawBoxColor
	#undef TextDrawBoxColor
#else
	#define _ALS_TextDrawBoxColor
#endif

#define TextDrawBoxColor _HOOKED_TextDrawBoxColor

stock _HOOKED_PlayerTextDrawBoxColor(playerid, PlayerText:text, color)
{
	HookPlayerTextDraw[text][PTDBoxColor] = color;
	return PlayerTextDrawBoxColor(playerid, text, color);
}

#if defined _ALS_PlayerTextDrawBoxColor
	#undef PlayerTextDrawBoxColor
#else
	#define _ALS_PlayerTextDrawBoxColor
#endif

#define PlayerTextDrawBoxColor _HOOKED_PlayerTextDrawBoxColor

// Now hook text draw show functions to make them fade automatically unless told not to do so...

stock _HOOKED_TextDrawShowForPlayer(playerid, Text:text, bool:fade = false)
{
	if(HookTextDraw[text][TDUseBox] == 0 && fade && TextDrawFading)
	{
		return TextDrawFadeForPlayer(playerid, text, HookTextDraw[text][TDColor], 0, DEFAULT_FADE_UPDATE_RATE, DEFAULT_FADE_DISPLAY_TIME);
	}
	else
	{
		return TextDrawShowForPlayer(playerid, text);
	}
}

#if defined _ALS_TextDrawShowForPlayer
	#undef TextDrawShowForPlayer
#else
	#define _ALS_TextDrawShowForPlayer
#endif

#define TextDrawShowForPlayer _HOOKED_TextDrawShowForPlayer

stock _HOOKED_TextDrawShowForAll(Text:text, bool:fade = false)
{
	if(HookTextDraw[text][TDUseBox] == 0 && fade && TextDrawFading)
	{
		return TextDrawFadeForAll(text, HookTextDraw[text][TDColor], 0, DEFAULT_FADE_UPDATE_RATE, DEFAULT_FADE_DISPLAY_TIME);
	}
	else
	{
		return TextDrawShowForAll(text);
	}
}

#if defined _ALS_TextDrawShowForAll
	#undef TextDrawShowForAll
#else
	#define _ALS_TextDrawShowForAll
#endif

#define TextDrawShowForAll _HOOKED_TextDrawShowForAll

stock _HOOKED_PlayerTextDrawShow(playerid, PlayerText:text, bool:fade = false)
{
	if(HookPlayerTextDraw[text][PTDUseBox] == 0 && fade && TextDrawFading)
	{
		return PlayerTextDrawFade(playerid, text, HookPlayerTextDraw[text][PTDColor], 0, DEFAULT_FADE_UPDATE_RATE, DEFAULT_FADE_DISPLAY_TIME);
	}
	else
	{
		return PlayerTextDrawShow(playerid, text);
	}
}

#if defined _ALS_PlayerTextDrawShow
	#undef PlayerTextDrawShow
#else
	#define _ALS_PlayerTextDrawShow
#endif

#define PlayerTextDrawShow _HOOKED_PlayerTextDrawShow