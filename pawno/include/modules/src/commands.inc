/*
		Commands
*/

#include "modules\header\commands.txt"

#tryinclude "modules\header\league.txt"

// Set alternative names for commands (todo: replace with a custom system)
SetAltCommands() 
{
	Command_AddAltNamed("changelog", "updates");
	Command_AddAltNamed("vr", "fix");
	Command_AddAltNamed("serverstats", "sstats");
	Command_AddAltNamed("serverpassword", "sp");
	Command_AddAltNamed("getpara", "gp");
	Command_AddAltNamed("para", "rp");
	Command_AddAltNamed("blockpm", "nopm");
	Command_AddAltNamed("blockpmall", "nopmall");
	Command_AddAltNamed("v", "car");
	Command_AddAltNamed("sync", "s");
	Command_AddAltNamed("weather", "w");
	Command_AddAltNamed("time", "t");
	Command_AddAltNamed("remgun", "rg");
	return 1;
}

// Create a group for each level
CreateAdminLevelGroups()
{
	new	str[8];
	for(new i = 0; i < MAX_ADMIN_LEVELS; i ++) // loop through all admin levels
	{
		format(str, sizeof str, "Level_%d", i); // initialize a good name
		AdminGroups[i] = Group_Create(str); // create a group for this level
	}
	return 1;
}

// Update 'CommandsLevel' array with the new level that 'commandid' has got
// This must be used when a command's level gets changed
UpdateCommandsIteratorArray(commandid, level)
{
	Iter_Clear(CommandsLevel[commandid]); // empty it because a command array should only have one value ,this command has a valid level now
	Iter_Add(CommandsLevel[commandid], level); // set a new level for this command
	return 1;
}

// Set player to the proper admin group based on his admin level
// This must be used when a player's admin level gets changed
UpdatePlayerAdminGroup(playerid)
{
	// loop through all admin groups and remove player from them (if he's in any)
	for(new i = 0; i < MAX_ADMIN_LEVELS; i ++)
	{
		if(Group_GetPlayer(AdminGroups[i], playerid)) // if he's in this group
		{
			Group_SetPlayer(AdminGroups[i], playerid, false); // remove him, his admin level changed so he shouldn't be in this admin group anymore
		}
	}
	new newlevel = Player[playerid][Level];
	Group_SetPlayer(AdminGroups[newlevel], playerid, true); // add to the proper group based on his new level
	return 1;
}

// Return the level of 'commandid'
// This function returns -2 if the iterator array is empty
// This function returns -1 if the command has more than one value
GetCommandLevel(commandid)
{
	new 
		count = 0, // how many values are found
		value;
		
	// loop through the iterator array OF ONLY 'commandid'
	// this array should only have ONE value because we always clear it before adding a new level (see UpdateCommandsIteratorArray)
	// so if there are more than 1 value or if 0 values were found
	// there must be something wrong, we return unique values (negative)
	foreach(new i : CommandsLevel[commandid])
	{
		value = i; // set it to the value we found, hopefully it'll be the only one otherwise we return errors
		count ++; // increase count of how many values are found
	}
	if(count == 0) // empty iterator array
	{
		printf("DEBUG: Error: GetCommandLevel: Returning -2, empty iterator array");
		return -2;
	}
	else if(count > 1) // found more than one value (level) for a command
	{
		printf("DEBUG: Error: GetCommandLevel: Returning -1, found more than a value. Command has different levels?");
		return -1;
	}
	// if passed, success: count is not 0 nor greater than 1 and it's pre-set to 0, so it's 1 which is very good
	// return the lovely value (level) now
	return value;
}

// Set the level of a command
// 'updatedb' should be disabled when loading commands from database (on startup?)
// otherwise it's good to enable it to update the newly set level in the database too
SetCommandLevel(command[], level, bool:updatedb)
{
	new	id = Command_GetID(command); // get the id of our command
	if(id < 0)
		return 0; // invalid command id, they start from 0.
	if(level == 0) // if this command is to be set for normal users (level 0)
	{
		Group_SetGlobalCommand(id, true); // then no need for much work just make it globally available
	}
	else
	{
		// we initialize everything by disabling this command for everyone
		Group_SetGlobalCommand(id, false);
		for(new i = 0; i < MAX_ADMIN_LEVELS; i ++) // loop through all admin levels
		{
			if(i >= level)
			{
				// Enable this command for the given level or any level that is higher than it.
				Group_SetCommand(AdminGroups[i], id, true);
			}
			else
			{
				// Disable it for lower levels
				Group_SetCommand(AdminGroups[i], id, false);
			}
		}
	}
	UpdateCommandsIteratorArray(id, level); // Update the iterator array that contains all commands ID and level
	if(updatedb)
	{
		// The command's got a new level now, tell the database about that too?
		new str[COMMAND_SQL_QUERY_SIZE];
		format(str, sizeof(str), "UPDATE Commands SET Level = %d WHERE Command = '%s'", level, command);
		db_free_result(db_query(sqliteconnection, str));
	}
	return 1;
}

// This is a core function that configures a command
// It loads a command level from the database if it exists. 
// If a command doesn't exist, it gets inserted into the database
CreateCommandConfig(cmd[], level)
{
	new query[COMMAND_SQL_QUERY_SIZE], DBResult:result;
	format(query, sizeof query, "SELECT Level FROM Commands WHERE Command='%s'", cmd);
	result = db_query(sqliteconnection, query);
	if(db_num_rows(result)) // if the command already exists
	{
		// load the level
		new str[8];
		db_get_field_assoc(result, "Level", str, sizeof(str));
		level = strval(str);
		SetCommandLevel(cmd, level, false);
	}
	else // if it doesn't exist
	{
		// insert it into the database
		format(query, sizeof query, "INSERT INTO Commands (Command, Level) VALUES ('%s', %d)", cmd, level);
		db_free_result(db_query(sqliteconnection, query));
		SetCommandLevel(cmd, level, false);
	}
	db_free_result(result);
	return 1;
}

// Initialize and load commands
LoadCommands()
{
	new ct = 0; // how many commands are found
	CreateAdminLevelGroups();
	Iter_Init(CommandsLevel);
	foreach(new i : Command())
	{
		ct ++; // increase count
		switch (YHash(Command_GetName(i), false))
		{
			/*
						Example:
								I'm releasing a new version with a new command '/crashplayer' and I want it to be for only level 4 admins
								So I do this
									
			case _I<crashplayer>:
			{
				CreateCommandConfig("crashplayer", 4); // Level param is not ignored here (unless the command is already in the database with a level)
			}
			
			*/
			default:
			{
				CreateCommandConfig(Command_GetName(i), 0); 
				// Level param could be ignored unless you you make a NEW ADMIN command in future versions (see example above)
			}
		}
	}
	printf("Commands Loaded: %d", ct);
	return 1;
}