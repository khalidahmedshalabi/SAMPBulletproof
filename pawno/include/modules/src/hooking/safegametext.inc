/*
		Safe game-text script 
		No more crash due to bad use of '~' character
*/

#include "modules\header\this_core.txt"

#if SAFE_GAMETEXT_AUTO_CHECK != 0

#include "modules\header\hooking\safegametext.txt"

// Hooked some functions to reject unsafe game-texts.
stock _HOOKED_GameTextForPlayer(playerid, string[], time, style)
{
	if(!IsSafeGametext(string))
	    return -1;

	return GameTextForPlayer(playerid, string, time, style);
}

#if defined _ALS_GameTextForPlayer
	#undef GameTextForPlayer
#else
	#define _ALS_GameTextForPlayer
#endif

#define GameTextForPlayer _HOOKED_GameTextForPlayer

stock _HOOKED_GameTextForAll(string[], time, style)
{
	if(!IsSafeGametext(string))
	    return -1;

	return GameTextForAll(string, time, style);
}

#if defined _ALS_GameTextForAll
	#undef GameTextForAll
#else
	#define _ALS_GameTextForAll
#endif

#define GameTextForAll _HOOKED_GameTextForAll

stock Text:_HOOKED_TextDrawCreate(Float:x, Float:y, text[])
{
	if(!IsSafeGametext(text))
	    return Text:INVALID_TEXT_DRAW;

	return TextDrawCreate(x, y, text);
}

#if defined _ALS_TextDrawCreate
	#undef TextDrawCreate
#else
	#define _ALS_TextDrawCreate
#endif

#define TextDrawCreate _HOOKED_TextDrawCreate

stock PlayerText:_HOOKED_CreatePlayerTextDraw(playerid, Float:x, Float:y, text[])
{
	if(!IsSafeGametext(text))
	    return PlayerText:INVALID_TEXT_DRAW;

	return CreatePlayerTextDraw(playerid, x, y, text);
}

#if defined _ALS_CreatePlayerTextDraw
	#undef CreatePlayerTextDraw
#else
	#define _ALS_CreatePlayerTextDraw
#endif

#define CreatePlayerTextDraw _HOOKED_CreatePlayerTextDraw

stock _HOOKED_TextDrawSetString(Text:text, string[])
{
	if(!IsSafeGametext(string))
	    return -1;

	return TextDrawSetString(text, string);
}

#if defined _ALS_TextDrawSetString
	#undef TextDrawSetString
#else
	#define _ALS_TextDrawSetString
#endif

#define TextDrawSetString _HOOKED_TextDrawSetString

stock _HOOKED_PlayerTextDrawSetString(playerid, PlayerText:text, string[])
{
	if(!IsSafeGametext(string))
	    return -1;

	return PlayerTextDrawSetString(playerid, text, string);
}

#if defined _ALS_PlayerTextDrawSetString
	#undef PlayerTextDrawSetString
#else
	#define _ALS_PlayerTextDrawSetString
#endif

#define PlayerTextDrawSetString _HOOKED_PlayerTextDrawSetString

#endif 