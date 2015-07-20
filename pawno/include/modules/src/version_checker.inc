/*
		Version checker: checks if server needs update (gamemode update)
*/

#include "modules\header\version_checker.txt"

InitVersionChecker(timer, moreinfo)
{
	#if defined PRE_RELEASE_VERSION
	#pragma unused timer
	#pragma unused moreinfo
	VersionCheckerStatus = false;
	#else
	if(timer)
	{
		SetTimer("ReportServerVersion", 1 * 60 * 60 * 1000, true);
	}
	if(moreinfo)
	{
	    HTTP(1, HTTP_GET, VERSION_CHECKER_FORCEUSER_URL, "", "ForceUserToUseNewest");
	}
	VC_ConnectionFailures = 0;
	HTTP(0, HTTP_GET, VERSION_CHECKER_VERSION_URL, "", "SaveVersionInStr");
	#endif
}

forward ReportServerVersion_Delayed();
public ReportServerVersion_Delayed()
{
    if(!VersionCheckerStatus)
    {
        if(VC_ConnectionFailures < 3)
        {
            SetTimer("ReportServerVersion_Delayed", 2000, false);
        }
	    return 0;
	}
	    
    if(VersionReport == VERSION_IS_BEHIND)
 	{
     	SendClientMessageToAll(-1, sprintf(""COL_PRIM"Version checker: {FFFFFF}the version used in this server is out-dated. You can visit "COL_PRIM"%s {FFFFFF}to get the latest version", GM_WEBSITE));
        SendClientMessageToAll(-1, sprintf(""COL_PRIM"Server version: {FFFFFF}%s "COL_PRIM"| Newest version: {FFFFFF}%s", GM_NAME, LatestVersionStr));
	}
	return 1;
}

forward ReportServerVersion();
public ReportServerVersion()
{
	if(!VersionCheckerStatus)
	    return 0;

    HTTP(0, HTTP_GET, VERSION_CHECKER_VERSION_URL, "", "SaveVersionInStr");
    HTTP(1, HTTP_GET, VERSION_CHECKER_FORCEUSER_URL, "", "ForceUserToUseNewest");
    SetTimer("ReportServerVersion_Delayed", 2000, false);
	return 1;
}

forward ForceUserToUseNewest(index, response_code, data[]);
public ForceUserToUseNewest(index, response_code, data[])
{
    if(response_code == 200)
    {
		new value = strval(data);
		if(value == 0)
		{
		    ForceUserToNewestVersion = false;
		}
		else if(value == 1)
		{
		    ForceUserToNewestVersion = true;
		}
    }
    else
    {
        if(VC_ConnectionFailures < 3)
        {
	        ForceUserToNewestVersion = true;
	        HTTP(1, HTTP_GET, VERSION_CHECKER_FORCEUSER_URL, "", "ForceUserToUseNewest");
	        VC_ConnectionFailures ++;
	 	}
	}
	return 1;
}

forward SaveVersionInStr(index, response_code, data[]);
public SaveVersionInStr(index, response_code, data[])
{
    if(response_code == 200)
    {
		format(LatestVersionStr, sizeof LatestVersionStr, "%s", data);
		VersionCheckerStatus = true;
		VersionReport = ReportVersion();
    }
    else
    {
        if(VC_ConnectionFailures < 3)
        {
	        VersionCheckerStatus = false;
	        HTTP(0, HTTP_GET, VERSION_CHECKER_VERSION_URL, "", "SaveVersionInStr");
	        VC_ConnectionFailures ++;
		}
		else // Couldn't connect to the version checker server
		{
			printf("Could not connect to the Bulletproof servers to fetch latest version data.");
		}
	}
	return 1;
}

ReportVersion()
{
	if(!VersionCheckerStatus)
		return -1;

	if(strcmp(GM_NAME, LatestVersionStr, true) != 0)
	{
		return VERSION_IS_BEHIND;
	}
	return VERSION_IS_UPTODATE;
}