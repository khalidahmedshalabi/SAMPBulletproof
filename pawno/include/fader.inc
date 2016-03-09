/*
 * FUNCTIONS:
 * native TextDrawFadeForPlayer(playerid, Text:text, color = 0, boxcolor = 0, updaterate = 30, displaytime = 1500);
 * native TextDrawFadeForAll(Text:text, color = 0, boxcolor = 0, updaterate = 30, displaytime = 1500);
 * native PlayerTextDrawFade(playerid, PlayerText:text, color = 0, boxcolor = 0, updaterate = 30, displaytime = 1500);
 *
 * CALLBACKS:
 * public OnTextDrawFadeComplete(Text:text, forplayerid)
 * public OnPlayerTextDrawFadeComplete(playerid, PlayerText:text)
 */

#define ALPHA(%1,%2) \
	((%1 & ~0xFF) | clamp(%2, 0x00, 0xFF))

#if ! defined MAX_TEXT_DRAWS
	#define MAX_TEXT_DRAWS (256)
#endif

static gFadeTimer[Text:MAX_TEXT_DRAWS];
static gFadeAlpha[Text:MAX_TEXT_DRAWS];

stock TextDrawFadeForPlayer(playerid, Text:text, color = 0, boxcolor = 0, updaterate = 30, displaytime = 1500)
{
	if (text < Text:0 || text >= Text:MAX_TEXT_DRAWS)
	{
	    return false;
	}

	if (color == 0 && boxcolor == 0)
	{
	    return false;
	}

	if (color != 0)
		TextDrawColor(text, ALPHA(color, 0));

	if (boxcolor != 0)
		TextDrawBoxColor(text, ALPHA(boxcolor, 0));

	TextDrawShowForPlayer(playerid, text);

	gFadeAlpha[text] = 0;

	KillTimer(gFadeTimer[text]);
	gFadeTimer[text] = SetTimerEx("OnTextDrawFadeUpdate", updaterate, true, "iiiiiiii", _:text, color, boxcolor, updaterate, displaytime, 0, playerid);

	return true;
}

stock TextDrawFadeForAll(Text:text, color = 0, boxcolor = 0, updaterate = 30, displaytime = 1500)
{
	if (text < Text:0 || text >= Text:MAX_TEXT_DRAWS)
	{
	    return false;
	}

	if (color == 0 && boxcolor == 0)
	{
	    return false;
	}

	if (color != 0)
		TextDrawColor(text, ALPHA(color, 0));

	if (boxcolor != 0)
		TextDrawBoxColor(text, ALPHA(boxcolor, 0));

	TextDrawShowForAll(text);

	gFadeAlpha[text] = 0;

	KillTimer(gFadeTimer[text]);
	gFadeTimer[text] = SetTimerEx("OnTextDrawFadeUpdate", updaterate, true, "iiiiiiii", _:text, color, boxcolor, updaterate, displaytime, 0, INVALID_PLAYER_ID);

	return true;
}

forward OnTextDrawFadeUpdate(Text:text, color, boxcolor, updaterate, displaytime, type, forplayerid);
public 	OnTextDrawFadeUpdate(Text:text, color, boxcolor, updaterate, displaytime, type, forplayerid)
{
	switch (type)
	{
	    case 0:
		{
		    gFadeAlpha[text] += updaterate;

			if (color != 0)
				TextDrawColor(text, ALPHA(color, gFadeAlpha[text]));

			if (boxcolor != 0)
				TextDrawBoxColor(text, ALPHA(boxcolor, gFadeAlpha[text]));

			if (forplayerid != INVALID_PLAYER_ID)
				TextDrawShowForPlayer(forplayerid, text);
			else
				TextDrawShowForAll(text);

			if (gFadeAlpha[text] >= 255)
			{
				KillTimer(gFadeTimer[text]);
				gFadeTimer[text] = SetTimerEx("OnTextDrawFadeUpdate", displaytime, true, "iiiiiii", _:text, color, boxcolor, updaterate, displaytime, 1, forplayerid);
			}
		}

		case 1:
		{
		    gFadeAlpha[text] -= updaterate;

			if (color != 0)
				TextDrawColor(text, ALPHA(color, gFadeAlpha[text]));

			if (boxcolor != 0)
				TextDrawBoxColor(text, ALPHA(boxcolor, gFadeAlpha[text]));

			if (gFadeAlpha[text] <= 0)
			{
				KillTimer(gFadeTimer[text]);
				gFadeTimer[text] = 0;

				if (color != 0)
					TextDrawColor(text, color);

				if (boxcolor != 0)
					TextDrawBoxColor(text, color);

				CallRemoteFunction("OnTextDrawFadeComplete", "ii", _:text, forplayerid);
			}
		}
	}
	return 1;
}

forward OnTextDrawFadeComplete(Text:text, forplayerid);
public OnTextDrawFadeComplete(Text:text, forplayerid)
{
	// The callback function must be implemented at least once, otherwise CallRemoteFunction makes the server act crazy...
	return 1;
}

#if ! defined MAX_PLAYER_TEXT_DRAWS
	#define MAX_PLAYER_TEXT_DRAWS (256)
#endif

static pFadeTimer[MAX_PLAYERS][PlayerText:MAX_PLAYER_TEXT_DRAWS];
static pFadeAlpha[MAX_PLAYERS][PlayerText:MAX_PLAYER_TEXT_DRAWS];

stock PlayerTextDrawFade(playerid, PlayerText:text, color = 0, boxcolor = 0, updaterate = 30, displaytime = 1500)
{
	if (text < PlayerText:0 || text >= PlayerText:MAX_PLAYER_TEXT_DRAWS)
	{
	    return false;
	}

	if (color == 0 && boxcolor == 0)
	{
	    return false;
	}

	if (color != 0)
		PlayerTextDrawColor(playerid, text, ALPHA(color, 0));

	if (boxcolor != 0)
		PlayerTextDrawBoxColor(playerid, text, ALPHA(boxcolor, 0));

	PlayerTextDrawShow(playerid, text);

	pFadeAlpha[playerid][text] = 0;

	KillTimer(pFadeTimer[playerid][text]);
	pFadeTimer[playerid][text] = SetTimerEx("OnPlayerTextDrawFadeUpdate", updaterate, true, "iiiiiiii", playerid, _:text, color, boxcolor, updaterate, displaytime, 0);

	return true;
}

forward OnPlayerTextDrawFadeUpdate(playerid, PlayerText:text, color, boxcolor, updaterate, displaytime, type);
public 	OnPlayerTextDrawFadeUpdate(playerid, PlayerText:text, color, boxcolor, updaterate, displaytime, type)
{
	switch (type)
	{
	    case 0:
		{
		    pFadeAlpha[playerid][text] += updaterate;

			if (color != 0)
				PlayerTextDrawColor(playerid, text, ALPHA(color, pFadeAlpha[playerid][text]));

			if (boxcolor != 0)
				PlayerTextDrawBoxColor(playerid, text, ALPHA(boxcolor, pFadeAlpha[playerid][text]));

			PlayerTextDrawShow(playerid, text);

			if (pFadeAlpha[playerid][text] >= 255)
			{
				KillTimer(pFadeTimer[playerid][text]);
				pFadeTimer[playerid][text] = SetTimerEx("OnPlayerTextDrawFadeUpdate", displaytime, true, "iiiiiii", playerid, _:text, color, boxcolor, updaterate, displaytime, 1);
			}
		}

		case 1:
		{
		    pFadeAlpha[playerid][text] -= updaterate;

			if (color != 0)
				PlayerTextDrawColor(playerid, text, ALPHA(color, pFadeAlpha[playerid][text]));

			if (boxcolor != 0)
				PlayerTextDrawBoxColor(playerid, text, ALPHA(boxcolor, pFadeAlpha[playerid][text]));

			if (pFadeAlpha[playerid][text] <= 0)
			{
				KillTimer(pFadeTimer[playerid][text]);
				pFadeTimer[playerid][text] = 0;

				if (color != 0)
					PlayerTextDrawColor(playerid, text, color);

				if (boxcolor != 0)
					PlayerTextDrawBoxColor(playerid, text, color);

				CallRemoteFunction("OnPlayerTextDrawFadeComplete", "ii", playerid, _:text);
			}
		}
	}
	return 1;
}

forward OnPlayerTextDrawFadeComplete(playerid, PlayerText:text);
public OnPlayerTextDrawFadeComplete(playerid, PlayerText:text)
{
	// The callback function must be implemented at least once, otherwise CallRemoteFunction makes the server act crazy...
	return 1;
}

#undef ALPHA