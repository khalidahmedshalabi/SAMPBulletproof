/*
		Fields related: bases, arenas... etc
*/

#include "modules\header\fields.txt"

/*FindFreeArenaSlot()
{
	for(new i = 1; i < MAX_ARENAS; i ++)
		if(!AExist[i])
			return i;
		
	return TotalArenas + 1;
}*/

FindFreeBaseSlot()
{
	for(new i = 1; i < MAX_BASES; i ++)
		if(!BExist[i])
			return i;
		
	return TotalBases + 1;
}

LoadBases()
{
	new iString[64];
    TotalBases = 0;

	new DBResult:res = db_query(sqliteconnection, sprintf("SELECT * FROM `%s` ORDER BY ID ASC", CurrentBaseSet));

    for(new i = 0; i < MAX_BASES; i++) BExist[i] = false;
    new i;
	do {
		db_get_field_assoc(res, "ID", iString, sizeof(iString));
		i = strval(iString);

	    db_get_field_assoc(res, "AttSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", BAttackerSpawn[i][0], BAttackerSpawn[i][1], BAttackerSpawn[i][2]);

	    db_get_field_assoc(res, "DefSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", BDefenderSpawn[i][0], BDefenderSpawn[i][1], BDefenderSpawn[i][2]);

	    db_get_field_assoc(res, "CPSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", BCPSpawn[i][0], BCPSpawn[i][1], BCPSpawn[i][2]);
	    
		db_get_field_assoc(res, "Interior", iString, sizeof(iString));
		BInterior[i] = strval(iString);

	    db_get_field_assoc(res, "Name", BName[i], MAX_FIELD_NAME);

	    TotalBases++;
		BExist[i] = true;

	} while(db_next_row(res));

	db_free_result(res);

	SendClientMessageToAll(-1, sprintf(""COL_PRIM"Bases Loaded: {FFFFFF}%d "COL_PRIM"| Current base set: {FFFFFF}%s", TotalBases, CurrentBaseSet));
	printf("Bases Loaded: %d (from table: %s)", TotalBases, CurrentBaseSet);
}

LoadArenas()
{
    new iString[64];
	TotalArenas = 0;

	new DBResult:res = db_query(sqliteconnection, "SELECT * FROM Arenas ORDER BY ID ASC");

    for(new i = 0; i < MAX_ARENAS; i++) AExist[i] = false;
	new i;
	do {
		db_get_field_assoc(res, "ID", iString, sizeof(iString));
		i = strval(iString);

		db_get_field_assoc(res, "AttSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", AAttackerSpawn[i][0], AAttackerSpawn[i][1], AAttackerSpawn[i][2]);

	    db_get_field_assoc(res, "DefSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", ADefenderSpawn[i][0], ADefenderSpawn[i][1], ADefenderSpawn[i][2]);

	    db_get_field_assoc(res, "CPSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", ACPSpawn[i][0], ACPSpawn[i][1], ACPSpawn[i][2]);

	    db_get_field_assoc(res, "Max", iString, sizeof(iString));
	    sscanf(iString, "p,ff", AMax[i][0], AMax[i][1]);

	    db_get_field_assoc(res, "Min", iString, sizeof(iString));
	    sscanf(iString, "p,ff", AMin[i][0], AMin[i][1]);

		db_get_field_assoc(res, "Interior", iString, sizeof(iString));
	    AInterior[i] = strval(iString);

	    db_get_field_assoc(res, "Name", AName[i], MAX_FIELD_NAME);

	    AExist[i] = true;
	    TotalArenas++;
	} while(db_next_row(res));
	
	db_free_result(res);

	SendClientMessageToAll(-1, sprintf(""COL_PRIM"Arenas Loaded: {FFFFFF}%d", TotalArenas));
	printf("Arenas Loaded: %d", TotalArenas);
}

LoadDMs()
{
	new iString[64], TotalDMs;

	new DBResult:res = db_query(sqliteconnection, "SELECT * FROM DMs ORDER BY ID ASC");

	for(new i = 0; i < MAX_DMS; i++) DMExist[i] = false;
	new i;
	do {
		db_get_field_assoc(res, "ID", iString, sizeof(iString));
		i = strval(iString);

	    db_get_field_assoc(res, "Spawn", iString, sizeof(iString));
	    sscanf(iString, "p,ffff", DMSpawn[i][0], DMSpawn[i][1], DMSpawn[i][2], DMSpawn[i][3]);

		db_get_field_assoc(res, "Interior", iString, sizeof(iString));
		DMInterior[i] = strval(iString);

		for(new j = 0; j < 3; ++j) {
		    new str[10], Str[128];
		    format(str, sizeof(str), "Wep%d", j+1);
            db_get_field_assoc(res, str, Str, 128);
			DMWeapons[i][j] = strval(Str);
		}
		DMExist[i] = true;

	    //db_next_row(res);
	    TotalDMs++;
	} while(db_next_row(res));
	
	db_free_result(res);

	printf("DMs Loaded: %d", TotalDMs);
}