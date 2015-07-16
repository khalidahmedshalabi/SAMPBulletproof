/*
		Vehicle functions hooking
*/

#include "modules\header\hooking\vehicle.txt"

stock _HOOKED_CreateVehicle(modelid, Float:spawn_x, Float:spawn_y, Float:spawn_z, Float:angle, color1, color2, respawn_delay, addsiren=0)
{
	new _CreateVehicle_Return;
	_CreateVehicle_Return = CreateVehicle(modelid, spawn_x, spawn_y, spawn_z, angle, color1, color2, respawn_delay, addsiren);
	if(_CreateVehicle_Return != INVALID_VEHICLE_ID)
	{
		Iter_Add(DynamicVehicle, _CreateVehicle_Return);
	}
	return _CreateVehicle_Return;
}

#if defined _ALS_CreateVehicle
	#undef CreateVehicle
#else
	#define _ALS_CreateVehicle
#endif

#define CreateVehicle _HOOKED_CreateVehicle

// IMPORTANT NOTE
// IF YOU'RE GOING TO USE DestroyVehicle IN A LOOP 
// OVER DynamicVehicle ITERATOR ARRAY
// MAKE remove AS FALSE, NOT TRUE
// AND USE Iter_Clear(DynamicVehicle) RIGHT AFTER
// THE LOOP IS FINISHED, THAT'S MUCH SAFER

stock _HOOKED_DestroyVehicle(vehicleid, bool:remove = true)
{
	new _DestroyVehicle_Return;
	_DestroyVehicle_Return = DestroyVehicle(vehicleid);
	if(_DestroyVehicle_Return)
	{
		if(remove)
		{
			Iter_Remove(DynamicVehicle, vehicleid);
		}
	}
	return _DestroyVehicle_Return;
}

#if defined _ALS_DestroyVehicle
	#undef DestroyVehicle
#else
	#define _ALS_DestroyVehicle
#endif

#define DestroyVehicle _HOOKED_DestroyVehicle