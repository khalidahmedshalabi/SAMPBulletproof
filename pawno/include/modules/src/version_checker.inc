/*
		Version checker: checks if server needs update (gamemode update)
*/

#include "modules\header\version_checker.txt"

forward ForceUserToUseNewest(index, response_code, data[]);
public ForceUserToUseNewest(index, response_code, data[])
{
    if(response_code == 200)
    {
		ForceUserToNewestVersion = (strval(data) == 0) ? false : true;
    }
    else
    {
        if(VC_ConnectionFailures < 3)
        {
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
		LatestVersion = floatstr(data);
		VersionCheckerStatus = true;
		VersionReport = ReportVersion();
    }
    else
    {
        if(VC_ConnectionFailures < 3)
        {
	        HTTP(0, HTTP_GET, VERSION_CHECKER_VERSION_URL, "", "SaveVersionInStr");
	        VC_ConnectionFailures ++;
		}
		else // Couldn't connect to the version checker server
		{
			printf("Could not connect to the Bulletproof servers to fetch latest version data.");
			#if defined _league_included
			if(LeagueAllowed)
			{
				LeagueAllowed = false;
				CancelLeagueMode();
				db_free_result(db_query(sqliteconnection, "UPDATE Configs SET Value = 0 WHERE Option = 'LeagueAllowed'"));
			}
			#endif
		}
	}
	return 1;
}

forward OnWebsiteTextChecked(index, response_code, data[]);
public OnWebsiteTextChecked(index, response_code, data[])
{
    if(response_code == 200)
    {
		GM_WEBSITE[0] = EOS;
		strcat(GM_WEBSITE, data);
    }
	return 1;
}

InitVersionChecker()
{
	VC_ConnectionFailures = 0;
	HTTP(0, HTTP_GET, VERSION_CHECKER_FORCEUSER_URL, "", "ForceUserToUseNewest");
	HTTP(0, HTTP_GET, VERSION_CHECKER_VERSION_URL, "", "SaveVersionInStr");
}

CheckWebsiteText()
{
	HTTP(0, HTTP_GET, VERSION_CHECKER_UPDATE_WEBSITE, "", "OnWebsiteTextChecked");
}

ReportVersion()
	return (LatestVersion > GM_VERSION) ? (VERSION_IS_BEHIND) : (VERSION_IS_UPTODATE);