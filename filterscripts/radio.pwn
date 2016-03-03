#include <a_samp>

#include <zcmd>

IsNumeric(const string[])
{
	new i;
	while(string[i] != '\0') //end of string
	{
		if (string[i] > '9' || string[i] < '0'){return 0;}
		i++;
	}
	return 1;
}

CMD:radio(playerid, params[])
{
	if(isnull(params))
	{
	    SendClientMessage(playerid, -1, "Usage: /radio [ID or URL]");
	    SendClientMessage(playerid, -1, "0 turn off | 1 classical | 2 pop | 3 westcoast classics | 4 hiphop | 5 country | 6 jazz");
        SendClientMessage(playerid, -1, "7 blues radio | 8 sports talk | 9 comedy talk | 10 beatles radio | 11 videogame music | 12 folk");
		return 1;
	}
	if(IsNumeric(params))
	{
		switch(strval(params))
		{
		    case 0:
		    {
		        StopAudioStreamForPlayer(playerid);
		    }
		    case 1:
		    {
				PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=103145");
		    }
		    case 2:
		    {
	            PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=389248");
		    }
		    case 3:
		    {
	            PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=271392");
		    }
		    case 4:
		    {
	            PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=8318");
		    }
		    case 5:
		    {
	            PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=557317");
		    }
		    case 6:
		    {
	            PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=709809");
		    }
	     	case 7:
		    {
	            PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=8835529");
		    }
		    case 8:
		    {
	            PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=1020811");
		    }
		    case 9:
		    {
	            PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=537303");
		    }
		    case 10:
		    {
	            PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=86386");
		    }
		    case 11:
		    {
	            PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=5266");
		    }
		    case 12:
		    {
	            PlayAudioStreamForPlayer(playerid, "http://yp.shoutcast.com/sbin/tunein-station.pls?id=138489");
		    }
		    default:
		    {
	 			SendClientMessage(playerid, -1, "Wrong radio ID");
 			 	SendClientMessage(playerid, -1, "Usage: /radio [ID or URL]");
				SendClientMessage(playerid, -1, "0 turn off | 1 classical | 2 pop | 3 westcoast classics | 4 hiphop | 5 country | 6 jazz");
				SendClientMessage(playerid, -1, "7 blues radio | 8 sports talk | 9 comedy talk | 10 beatles radio | 11 videogame music | 12 folk");
	     	}
		}
	}
	else
	{
	    PlayAudioStreamForPlayer(playerid, params);
	}
	return 1;
}
