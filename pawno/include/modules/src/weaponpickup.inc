/*
		Weapon pickup on player head when taking damage
*/

#include "modules\header\weaponpickup.txt"

stock GetWeaponModel(weaponid)
{
    new model;

    switch(weaponid)
    {
        case 1: model=331; case 2: model=333; case 3: model=334;
        case 4: model=335; case 5: model=336; case 6: model=337;
        case 7: model=338; case 8: model=339; case 9: model=341;
        case 10: model=321; case 11: model=322; case 12: model=323;
        case 13: model=324; case 14: model=325; case 15: model=326;
        case 16: model=342; case 17: model=343; case 18: model=344;
        case 22: model=346; case 23: model=347; case 24: model=348;
        case 25: model=349; case 26: model=350; case 27: model=351;
        case 28: model=352; case 29: model=353; case 30: model=355;
        case 31: model=356; case 32: model=372; case 33: model=357;
        case 34: model=358; case 35: model=359; case 36: model=360;
        case 37: model=361; case 38: model=362; case 39: model=363;
        case 41: model=365; case 42: model=366; case 46: model=371;
    }
    return model;
}

forward DestroyPlayerObj(playerid);
public DestroyPlayerObj(playerid) {
DestroyObject (PlayerObj[playerid]);
}