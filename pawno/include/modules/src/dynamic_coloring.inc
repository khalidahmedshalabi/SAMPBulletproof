/*	
	Written by Niko Boy
	Linking function to make a new string that would
	reformat string by replacing COL_PRIM by selected
	color layout
*/

#include "modules\header\dynamic_coloring.txt"

//#define formatz(%1,%2,%3) format(%1,%2,%3),format_fix_color(%1)
//======================================================
/* Changes Occurance of COL_PRIM to value contained in ColScheme */
/* Dont change value of COL_PRIM define */
format_fix_color(string[])
{
	new l = 0 , len = 0;
	loop_again:
	l = strfind(string,COL_PRIM,true,l+len);
	if( l != -1 )
	{
	    //printf("%s string // %d // %d", string, l, len );
		len = strlen(COL_PRIM);
		strdel(string,l,l+len);
		strins(string,ColScheme,l, strlen(string) + 10);
		goto loop_again;
	}
	else return 1;
    return 0;
}
// did made this code snippet from editing of Ryder`'s SendFormatMessage!
_reformat(string[], const iLen, const szFormat[], { Float, _ }: ...) {
    new
        iArgs = (numargs() - 3) << 2
    ;
    //printf("string: %s // len : %d, %s", string, iLen, szFormat );
    if(iArgs) {
        static
            s_iAddr1,
            s_iAddr2
        ;
        #emit ADDR.PRI szFormat
        #emit STOR.PRI s_iAddr1

        for(s_iAddr2 = s_iAddr1 + iArgs, iArgs += 12; s_iAddr2 != s_iAddr1; s_iAddr2 -= 4) {
            #emit LOAD.PRI s_iAddr2
            #emit LOAD.I
            #emit PUSH.PRI
        }
		//load into primary register
		#emit LOAD.S.PRI string

		//push arguments in order 3 , 2 , 1 respectively
        #emit PUSH.S szFormat // 3
        #emit PUSH.S iLen // 2
        #emit PUSH.PRI  //1 . push information from primary register into stack >.>
        #emit PUSH.S iArgs // number of args
        #emit SYSREQ.C format
		// called ^ native function in format: format( string, ilen,szformat )
        #emit LCTRL 4
        #emit LOAD.S.ALT iArgs
        #emit ADD.C 4
        #emit ADD
        #emit SCTRL 4

        //strcat(string,s_szBuf,iLen);
		//printf("INSIDE reformat1 : %s",string);
		format_fix_color(string);
		//printf("INSIDE reformat2 : %s",string);
        return 1;
    }
    else
    {
        format(string,iLen,szFormat);
    }
    return 0;
}

#if defined _ALS_format
    #undef format
#else
    #define _ALS_format
#endif
// Reroute future calls to our function.
#define format _reformat

//======================================================
fixColor_SendClientMessage(playerid,color,mess[])
{
    format_fix_color(mess);
	SendClientMessage(playerid,color,mess);
	return 1;
}
#if defined _ALS_SendClientMessage
    #undef SendClientMessage
#else
    #define _ALS_SendClientMessage
#endif
// Reroute future calls to our function.
#define SendClientMessage fixColor_SendClientMessage

//======================================================
fixColor_SendClientMessageToAll(color,mess[])
{
    format_fix_color(mess);
	SendClientMessageToAll(color,mess);
	return 1;
}
#if defined _ALS_SendClientMessageToAll
    #undef SendClientMessageToAll
#else
    #define _ALS_SendClientMessageToAll
#endif
// Reroute future calls to our function.
#define SendClientMessageToAll fixColor_SendClientMessageToAll