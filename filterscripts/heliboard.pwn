#include <a_samp>

new HeliDiscoBoard[MAX_VEHICLES]; // A global vehicles variable for board object ID assignment

// DestroyVehicle hooked for the sake of disco boards
stock _HOOKED_DestroyVehicle(vehicleid)
{
	if(HeliDiscoBoard[vehicleid] > -1) // if vehicle has a board attached to it
    {
        DestroyObject(HeliDiscoBoard[vehicleid]); // destroy it
        HeliDiscoBoard[vehicleid] = -1;
    }
	return DestroyVehicle(vehicleid); // then destroy the vehicle
}

#if defined _ALS_DestroyVehicle
	#undef DestroyVehicle
#else
	#define _ALS_DestroyVehicle
#endif

#define DestroyVehicle _HOOKED_DestroyVehicle

public OnFilterScriptInit()
{
	print("Loaded filterscript: Helicopter boards");
	// Initializing
	for(new i = 0; i < MAX_VEHICLES; i ++) // Looping through all vehicles
	{
	    HeliDiscoBoard[i] = -1; // Setting it to -1 which means this vehicle has no board attached to it
	}
	return 1;
}

public OnFilterScriptExit()
{
    print("Unloaded filterscript: Helicopter boards");
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	if(GetVehicleModel(vehicleid) == 563) // if it's our promised helicopter
	{
	    HeliDiscoBoard[vehicleid] = CreateObject(19128, 0, 0, 0, 0, 0, 0, 80); // create the board and assign its ID to our variable
		AttachObjectToVehicle(HeliDiscoBoard[vehicleid], vehicleid, 0.0, 6.299995, -1.200000, 0.000000, 0.000000, 0.000000); // attach the board to the helicopter
 	}
 	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
    if(HeliDiscoBoard[vehicleid] > -1) // if this vehicle has boards attached to it
    {
        DestroyObject(HeliDiscoBoard[vehicleid]); // Destroy it
        HeliDiscoBoard[vehicleid] = -1; // Reset our variables
    }
	return 1;
}
