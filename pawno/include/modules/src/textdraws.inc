/*
		All textdraws: Global, per-player and 3D
*/

#include "modules\header\textdraws.txt"

#include "modules\header\weaponshot.txt"

// Match scoreboard textdraws
LoadMatchScoreTextDraws()
{
	/*
	// Credits: [U]27 aka [U]jay
	ScoreBoardBoxTD[0] = TextDrawCreate(474.000000, 7.000000, "-");
	TextDrawBackgroundColor(ScoreBoardBoxTD[0], 255);
	TextDrawFont(ScoreBoardBoxTD[0], 1);
	TextDrawLetterSize(ScoreBoardBoxTD[0], 11.000005, 14.000000);
	TextDrawColor(ScoreBoardBoxTD[0], 255);
	TextDrawSetOutline(ScoreBoardBoxTD[0], 0);
	TextDrawSetProportional(ScoreBoardBoxTD[0], 1);
	TextDrawSetShadow(ScoreBoardBoxTD[0], 1);

	ScoreBoardBoxTD[1] = TextDrawCreate(524.000000, 43.000000, "-");
	TextDrawBackgroundColor(ScoreBoardBoxTD[1], 255);
	TextDrawFont(ScoreBoardBoxTD[1], 1);
	TextDrawLetterSize(ScoreBoardBoxTD[1], 4.299998, 10.000000);
	TextDrawColor(ScoreBoardBoxTD[1], 255);
	TextDrawSetOutline(ScoreBoardBoxTD[1], 0);
	TextDrawSetProportional(ScoreBoardBoxTD[1], 1);
	TextDrawSetShadow(ScoreBoardBoxTD[1], 1);

	RoundsPlayed = TextDrawCreate(523.000000, 111.000000, "~Y~ ro~H~un~H~ds: 0/9");
	TextDrawBackgroundColor(RoundsPlayed, 0x00000033);
	TextDrawFont(RoundsPlayed, 1);
	TextDrawLetterSize(RoundsPlayed, 0.269998, 1.199998);
	TextDrawColor(RoundsPlayed, 1600086015);
	TextDrawSetOutline(RoundsPlayed, 1);
	TextDrawSetProportional(RoundsPlayed, 1);
	TextDrawSetSelectable(RoundsPlayed, 0);

	TeamAttackerTD = TextDrawCreate(499.000000, 83.000000, "~r~~h~~h~alpha");
	TextDrawAlignment(TeamAttackerTD, 1);
	TextDrawBackgroundColor(TeamAttackerTD, 0x00000000);
	TextDrawFont(TeamAttackerTD, 1);
	TextDrawLetterSize(TeamAttackerTD, 0.200000, 1.000000);
	TextDrawColor(TeamAttackerTD, -1);
	TextDrawSetOutline(TeamAttackerTD, 1);
	TextDrawSetProportional(TeamAttackerTD, 1);
	TextDrawSetSelectable(TeamAttackerTD, 0);

	TeamDefenderTD = TextDrawCreate(610.000000, 83.000000, "~b~~h~~h~beta");
	TextDrawAlignment(TeamDefenderTD, 3);
	TextDrawBackgroundColor(TeamDefenderTD, 0x00000000);
	TextDrawFont(TeamDefenderTD, 1);
	TextDrawLetterSize(TeamDefenderTD, 0.200000, 1.000000);
	TextDrawColor(TeamDefenderTD, -430226433);
	TextDrawSetOutline(TeamDefenderTD, 1);
	TextDrawSetProportional(TeamDefenderTD, 1);
	TextDrawSetSelectable(TeamDefenderTD, 0);

	MatchVersusTD = TextDrawCreate(539.000000, 82.000000, "v~H~e~H~rs~H~us");
	TextDrawBackgroundColor(MatchVersusTD, 255);
	TextDrawFont(MatchVersusTD, 2);
	TextDrawLetterSize(MatchVersusTD, 0.189998, 0.999998);
	TextDrawColor(MatchVersusTD, 1600086015);
	TextDrawSetOutline(MatchVersusTD, 1);
	TextDrawSetProportional(MatchVersusTD, 1);
	TextDrawSetSelectable(MatchVersusTD, 0);

	TeamScoreText = TextDrawCreate(536.000000, 94.000000, "0     0");
	TextDrawBackgroundColor(TeamScoreText, 255);
	TextDrawFont(TeamScoreText, 3);
	TextDrawLetterSize(TeamScoreText, 0.310000, 1.299996);
	TextDrawColor(TeamScoreText, -1);
	TextDrawSetOutline(TeamScoreText, 1);
	TextDrawSetProportional(TeamScoreText, 1);
	TextDrawSetSelectable(TeamScoreText, 0);

	MatchScoreBoardSprite = TextDrawCreate(547.000000, 94.000000, "hud:radar_race");
	TextDrawBackgroundColor(MatchScoreBoardSprite, 0);
	TextDrawFont(MatchScoreBoardSprite, 4);
	TextDrawLetterSize(MatchScoreBoardSprite, 0.379999, -0.100000);
	TextDrawColor(MatchScoreBoardSprite, -1);
	TextDrawSetOutline(MatchScoreBoardSprite, 1);
	TextDrawSetProportional(MatchScoreBoardSprite, 1);
	TextDrawUseBox(MatchScoreBoardSprite, 1);
	TextDrawBoxColor(MatchScoreBoardSprite, 255);
	TextDrawTextSize(MatchScoreBoardSprite, 16.000000, 16.000000);
	TextDrawSetSelectable(MatchScoreBoardSprite, 0);*/

	RoundsPlayed = TextDrawCreate(555.000000, 114.000000, "_");
	TextDrawAlignment(RoundsPlayed, 2);
	TextDrawFont(RoundsPlayed, 1);
	TextDrawLetterSize(RoundsPlayed, 0.330000, 1.65000);
	TextDrawBackgroundColor(RoundsPlayed,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(RoundsPlayed, 16711935);
	TextDrawSetOutline(RoundsPlayed, 1);
	TextDrawSetProportional(RoundsPlayed, 1);
	TextDrawTextSize(RoundsPlayed, 20, 100);
	TextDrawSetSelectable(RoundsPlayed, 1);

    TeamScoreText = TextDrawCreate(557.000000, 100.000000,"_");
	TextDrawFont(TeamScoreText, 1);
	TextDrawLetterSize(TeamScoreText, 0.330000, 1.650000);
	TextDrawBackgroundColor(TeamScoreText,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(TeamScoreText,-65281);
	TextDrawSetOutline(TeamScoreText, 1);
    TextDrawSetProportional(TeamScoreText, 1);
    TextDrawAlignment(TeamScoreText,2);
	TextDrawTextSize(TeamScoreText, 20, 200);
	TextDrawSetSelectable(TeamScoreText, 1);
}

LoadTextDraws()
{
	TextDrawCreate(-1000.0, -1000.0, "_");

	AnnTD = TextDrawCreate(320.000000, 120.000000, "_");
	TextDrawBackgroundColor(AnnTD, MAIN_BACKGROUND_COLOUR);
	TextDrawFont(AnnTD, 2);
	TextDrawLetterSize(AnnTD, 0.449999, 2.000000);
	TextDrawColor(AnnTD, 0xFFFFFFFF);
	TextDrawSetOutline(AnnTD, 1);
	TextDrawSetProportional(AnnTD, 1);
	TextDrawAlignment(AnnTD, 2);

	LoadMatchScoreTextDraws();

	SettingBox = TextDrawCreate(125.000000, 282.500000, "~n~~n~~n~~n~~n~");
	TextDrawAlignment(SettingBox, 2);
	TextDrawFont(SettingBox, 1);
	TextDrawLetterSize(SettingBox, 0.31, 1.45);
	TextDrawBackgroundColor(SettingBox,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(SettingBox, 16711935);
	TextDrawSetOutline(SettingBox, 1);
	TextDrawSetProportional(SettingBox, 1);
	TextDrawSetShadow(SettingBox,0);
	TextDrawTextSize(SettingBox, 20, 120);
	TextDrawUseBox(SettingBox, 1);
	TextDrawBoxColor(SettingBox, 0x00000033);

	WarModeText = TextDrawCreate(125.000000, 285.000000, sprintf("%sWar\tMode:\t~r~OFF", MAIN_TEXT_COLOUR));
	TextDrawAlignment(WarModeText, 2);
	TextDrawFont(WarModeText, 1);
	TextDrawLetterSize(WarModeText, 0.31, 1.45);
	TextDrawBackgroundColor(WarModeText,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(WarModeText, 16711935);
	TextDrawSetOutline(WarModeText, 1);
	TextDrawSetProportional(WarModeText, 1);
	TextDrawSetShadow(WarModeText,0);
	TextDrawTextSize(WarModeText, 20, 150);
	TextDrawSetSelectable(WarModeText, 1);

	LeagueToggleTD = TextDrawCreate(125.000000, 300.000000, sprintf("%sGo\tLeague", MAIN_TEXT_COLOUR));
	TextDrawAlignment(LeagueToggleTD, 2);
	TextDrawFont(LeagueToggleTD, 1);
	TextDrawLetterSize(LeagueToggleTD, 0.31, 1.45);
	TextDrawBackgroundColor(LeagueToggleTD,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(LeagueToggleTD, 16711935);
	TextDrawSetOutline(LeagueToggleTD, 1);
	TextDrawSetProportional(LeagueToggleTD, 1);
	TextDrawSetShadow(LeagueToggleTD,0);
	TextDrawTextSize(LeagueToggleTD, 20, 150);
	TextDrawSetSelectable(LeagueToggleTD, 1);

	LockServerTD = TextDrawCreate(125.000000, 315.000000, sprintf("%sServer:\t~r~Unlocked", MAIN_TEXT_COLOUR));
	TextDrawAlignment(LockServerTD, 2);
	TextDrawFont(LockServerTD, 1);
	TextDrawLetterSize(LockServerTD, 0.31, 1.45);
	TextDrawBackgroundColor(LockServerTD,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(LockServerTD, 16711935);
	TextDrawSetOutline(LockServerTD, 1);
	TextDrawSetProportional(LockServerTD, 1);
	TextDrawSetShadow(LockServerTD,0);
	TextDrawTextSize(LockServerTD, 30, 200);
	TextDrawSetSelectable(LockServerTD, 1);

	CloseText = TextDrawCreate(125.000000, 330.000000, sprintf("%sClose Settings", MAIN_TEXT_COLOUR));
	TextDrawAlignment(CloseText, 2);
	TextDrawFont(CloseText, 1);
	TextDrawLetterSize(CloseText, 0.31, 1.45);
	TextDrawBackgroundColor(CloseText,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(CloseText, 16711935);
	TextDrawSetOutline(CloseText, 1);
	TextDrawSetProportional(CloseText, 1);
	TextDrawSetShadow(CloseText,0);
	TextDrawTextSize(CloseText, 30, 200);
	TextDrawSetSelectable(CloseText, 1);

//  - End Round TextDraw -


	EN_AttackerBox = TextDrawCreate(178.500000 + ATTACKER_CHANGES_X, 176.00000 + ATTACKER_CHANGES_Y, "~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~");
	TextDrawAlignment(EN_AttackerBox, 2);
	TextDrawFont(EN_AttackerBox, 1);
	TextDrawLetterSize(EN_AttackerBox, 0.31, 1.45);
	TextDrawBackgroundColor(EN_AttackerBox,0xFF444444);
	TextDrawColor(EN_AttackerBox, 16711935);
	TextDrawSetOutline(EN_AttackerBox, 1);
	TextDrawSetProportional(EN_AttackerBox, 1);
	TextDrawSetShadow(EN_AttackerBox,0);
	TextDrawTextSize(EN_AttackerBox, 20, 180);
	TextDrawUseBox(EN_AttackerBox, 1);
	TextDrawBoxColor(EN_AttackerBox, 0xFF444444);

	EN_DefenderBox = TextDrawCreate(460.000000 + DEFENDER_CHANGES_X, 176.00000 + DEFENDER_CHANGES_Y, "~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~");
	TextDrawAlignment(EN_DefenderBox, 2);
	TextDrawFont(EN_DefenderBox, 1);
	TextDrawLetterSize(EN_DefenderBox, 0.31, 1.45);
	TextDrawBackgroundColor(EN_DefenderBox,0x3388FF44);
	TextDrawColor(EN_DefenderBox, 16711935);
	TextDrawSetOutline(EN_DefenderBox, 1);
	TextDrawSetProportional(EN_DefenderBox, 1);
	TextDrawSetShadow(EN_DefenderBox,0);
	TextDrawTextSize(EN_DefenderBox, 20, 180); //20, 220
	TextDrawUseBox(EN_DefenderBox, 1);
	TextDrawBoxColor(EN_DefenderBox, 0x3388FF44);

    RoundTextdrawsCreate();

	ResultTextdrawsCreate();

	EN_CheckPoint = TextDrawCreate(182.000000, 280.000000, "_");
	TextDrawAlignment(EN_CheckPoint, 1);
	TextDrawBackgroundColor(EN_CheckPoint, MAIN_BACKGROUND_COLOUR);
	TextDrawFont(EN_CheckPoint, 1);
	TextDrawLetterSize(EN_CheckPoint, 0.18000, 0.9);
	TextDrawColor(EN_CheckPoint, -1);
	TextDrawSetOutline(EN_CheckPoint, 1);
	TextDrawSetProportional(EN_CheckPoint, 1);

//  - End of Round Textdraw -

	DarkScreen = TextDrawCreate(727.000000, -2.000000, "~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~");
	TextDrawBackgroundColor(DarkScreen, 255);
	TextDrawFont(DarkScreen, 3);
	TextDrawLetterSize(DarkScreen, 0.500000, 1.000000);
	TextDrawColor(DarkScreen, -1);
	TextDrawSetOutline(DarkScreen, 1);
	TextDrawSetProportional(DarkScreen, 1);
	TextDrawUseBox(DarkScreen, 1);
	TextDrawBoxColor(DarkScreen, 0x00000033);
	TextDrawTextSize(DarkScreen, -16.000000, 105.000000);

	RedDeathScreen = TextDrawCreate(727.000000, -2.000000, "~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~");
	TextDrawBackgroundColor(RedDeathScreen, 255);
	TextDrawFont(RedDeathScreen, 3);
	TextDrawLetterSize(RedDeathScreen, 0.500000, 1.000000);
	TextDrawColor(RedDeathScreen, -1);
	TextDrawSetOutline(RedDeathScreen, 1);
	TextDrawSetProportional(RedDeathScreen, 1);
	TextDrawUseBox(RedDeathScreen, 1);
	TextDrawBoxColor(RedDeathScreen, 0x85131333);
	TextDrawTextSize(RedDeathScreen, -16.000000, 105.000000);

	CreateObjectGunmenuTextDraws();

	#if defined _league_included
	CreateLeagueTextDraws();
	#endif
	return 1;
}

ResultTextdrawsCreate()
{
	leftBG =	TextDrawCreate	(	301.200103, 	160.775039, 	"_"			);
	TextDrawLetterSize			(	leftBG, 		0.000000, 		19.997976	);
	TextDrawTextSize			(	leftBG, 		123.411689, 	0.000000	);
	TextDrawAlignment			(	leftBG, 		1							);
	TextDrawColor				(	leftBG, 		0							);
	TextDrawUseBox				(	leftBG, 		true						);
	//TextDrawBoxColor			(	leftBG, 		0xDB535399					);
	TextDrawBoxColor			(	leftBG, 		0x00000099					);
	TextDrawSetShadow			(	leftBG, 		0);
	TextDrawSetOutline			(	leftBG, 		0);
	TextDrawFont				(	leftBG, 		0);

	rightBG = 	TextDrawCreate	(	478.729431, 	161.000000, 	"_"			);
	TextDrawLetterSize			(	rightBG, 		0.000000, 		19.974430	);
	TextDrawTextSize			(	rightBG, 		300.964538, 	0.000000	);
	TextDrawAlignment			(	rightBG, 		1							);
	TextDrawColor				(	rightBG, 		0							);
	TextDrawUseBox				(	rightBG, 		true						);
	//TextDrawBoxColor			(	rightBG,		0x6492D199					);
	TextDrawBoxColor			(	rightBG, 		0x00000099					);
	TextDrawSetShadow			(	rightBG,		0							);
	TextDrawSetOutline			(	rightBG, 		0							);
	TextDrawFont				(	rightBG, 		0							);

	leftUpBG = 	TextDrawCreate	(	302.658935, 	152.633422, 	"_"			);
	TextDrawLetterSize			(	leftUpBG, 		0.000000, 		1.829496	);
	TextDrawTextSize            (	leftUpBG, 		121.435226, 	0.000000	);
	TextDrawAlignment          	(	leftUpBG, 		1							);
	TextDrawColor            	(	leftUpBG, 		0							);
	TextDrawUseBox            	(	leftUpBG, 		true						);
	TextDrawBoxColor            (	leftUpBG, 		0x00000050					);
	TextDrawSetShadow          	(	leftUpBG, 		0							);
	TextDrawSetOutline         	(	leftUpBG, 		0							);
	TextDrawFont            	(	leftUpBG, 		0							);

	rightUpBG = TextDrawCreate  (	480.741516, 	152.291732, 	"_"			);
	TextDrawLetterSize          (	rightUpBG, 		0.000000, 		1.815376	);
	TextDrawTextSize            (	rightUpBG, 		299.411682, 	0.000000	);
	TextDrawAlignment           (	rightUpBG, 		1							);
	TextDrawColor            	(	rightUpBG, 		0							);
	TextDrawUseBox            	(	rightUpBG, 		true						);
	TextDrawBoxColor            (	rightUpBG, 		0x00000050					);
	TextDrawSetShadow          	(	rightUpBG, 		0							);
	TextDrawSetOutline     	  	(	rightUpBG, 		0							);
	TextDrawFont            	(	rightUpBG, 		1							);

	leftHeader = TextDrawCreate	(	302.482940,		153.225158, 	"_"			);
	TextDrawLetterSize         	(	leftHeader, 	0.000000, 		1.711848	);
	TextDrawTextSize            (	leftHeader, 	122.211738,		0.000000	);
	TextDrawAlignment          	(	leftHeader,		1							);
	TextDrawColor            	(	leftHeader,		0							);
	TextDrawUseBox            	(	leftHeader,		true						);
	TextDrawBoxColor            (	leftHeader,		0xFF222280					);
	TextDrawSetShadow          	(	leftHeader,		0							);
	TextDrawSetOutline         	(	leftHeader,		0							);
	TextDrawFont            	(	leftHeader,		0							);

	rightHeader = TextDrawCreate(	480.330291,		153.233322,		"_"			);
	TextDrawLetterSize         	(	rightHeader,	0.000000,		1.707144	);
	TextDrawTextSize           	(	rightHeader,	299.905853,		0.000000	);
	TextDrawAlignment          	(	rightHeader,	1							);
	TextDrawColor            	(	rightHeader,	860159863					);
	TextDrawUseBox            	(	rightHeader,	true						);
	TextDrawBoxColor            (	rightHeader,	0x4444FF80					);
	TextDrawSetShadow          	(	rightHeader,	0							);
	TextDrawSetOutline         	(	rightHeader,	0							);
	TextDrawFont            	(	rightHeader,	0							);

	leftULine = TextDrawCreate 	(	116.105949,		169.166824,		"-"			);
	//leftULine = TextDrawCreate 	(	-100.0,		-100.0,		"-"			);
	TextDrawLetterSize         	(	leftULine,		13.658081,		0.270249	);
	TextDrawAlignment          	(	leftULine,		1							);
	TextDrawColor            	(	leftULine,		0x00000050							);
	TextDrawSetShadow          	(	leftULine,		0							);
	TextDrawSetOutline         	(	leftULine,		10							);
	TextDrawBackgroundColor    	(	leftULine,		0x00000050							);
	TextDrawFont            	(	leftULine,		1							);
	TextDrawSetProportional    	(	leftULine,		1							);

	rightULine = TextDrawCreate	(	290.376525,		169.816665,		"-"			);
	//rightULine = TextDrawCreate 	(	-100.0,		-100.0,		"-"			);
	TextDrawLetterSize         	(	rightULine,		13.662071,		0.257999	);
	TextDrawAlignment          	(	rightULine,		1							);
	TextDrawColor            	(	rightULine,		0x00000050						);
	TextDrawSetShadow          	(	rightULine,		0							);
	TextDrawSetOutline         	(	rightULine,		10							);
	TextDrawBackgroundColor    	(	rightULine,		0x00000050							);
	TextDrawFont            	(	rightULine,		1							);
	TextDrawSetProportional    	(	rightULine,		1							);

	lowerBG = TextDrawCreate   	(	460.823425,		345.199615,		"_"			);
	TextDrawLetterSize         	(	lowerBG,		0.000000,		4.986599	);
	TextDrawTextSize            (	lowerBG,		144.823318,		0.000000	);
	TextDrawAlignment          	(	lowerBG,		1							);
	TextDrawColor            	(	lowerBG,		0							);
	TextDrawUseBox            	(	lowerBG,		true						);
	TextDrawBoxColor            (	lowerBG,		0x00000099					);
	TextDrawSetShadow          	(	lowerBG,		0							);
	TextDrawSetOutline         	(	lowerBG,		0							);
	TextDrawFont            	(	lowerBG,		0							);

	leftUpText = TextDrawCreate(	128.094100,		143.499984,		"~r~~h~~h~Attackers"	);
	TextDrawLetterSize         	(	leftUpText,		0.225058,		1.315831	);
	TextDrawAlignment          	(	leftUpText,		1							);
	TextDrawColor            	(	leftUpText,		-1							);
	TextDrawSetShadow          	(	leftUpText,		0							);
	TextDrawSetOutline         	(	leftUpText,		1							);
	TextDrawBackgroundColor    	(	leftUpText,		51							);
	TextDrawFont            	(	leftUpText,		3							);
	TextDrawSetProportional    	(	leftUpText,		1							);

	rightUpText = TextDrawCreate(	436.282226,		143.499969,		"~b~~h~~h~Defenders"	);
	TextDrawLetterSize         	(	rightUpText,	0.225058,		1.315831	);
	TextDrawAlignment          	(	rightUpText,	1							);
	TextDrawColor            	(	rightUpText,	-1							);
	TextDrawSetShadow          	(	rightUpText,	0							);
	TextDrawSetOutline         	(	rightUpText,	1							);
	TextDrawBackgroundColor    	(	rightUpText,	51							);
	TextDrawFont            	(	rightUpText,	3							);
	TextDrawSetProportional    	(	rightUpText,	1							);

	topTextScore = TextDrawCreate(	302.870422,		111.824943,		"_"			);//~y~~h~TCW~n~~b~~h~~h~Ateam 9 ~w~- ~r~~h~0 Bteam
	TextDrawLetterSize         	(	topTextScore,	0.275128,		1.917916	);
	TextDrawAlignment          	(	topTextScore,	2							);
	TextDrawColor            	(	topTextScore,	-1							);
	TextDrawSetShadow          	(	topTextScore,	1							);
	TextDrawSetOutline         	(	topTextScore,	0							);
	TextDrawBackgroundColor    	(	topTextScore,	0x00000022							);
	TextDrawFont            	(	topTextScore,	2							);
	TextDrawSetProportional    	(	topTextScore,	1							);

	leftText = TextDrawCreate  	(	132.658905,		172.316802,		"Name___________________Kill__HP________Acc________Dmg");
	TextDrawLetterSize         	(	leftText,		0.184588,		0.946666	);
	TextDrawAlignment          	(	leftText,		1							);
	TextDrawColor          		(	leftText,		-1							);
	TextDrawSetShadow          	(	leftText,		0							);
	TextDrawSetOutline         	(	leftText,		1							);
	//TextDrawBackgroundColor     (	leftText,		0xFF003333					);
	TextDrawBackgroundColor     (	leftText,		0xFF222233					);
	TextDrawFont            	(	leftText,		1							);
	TextDrawSetProportional    	(	leftText,		1							);

	rightText = TextDrawCreate 	(	310.459045,		172.850051,		"Name___________________Kill__HP________Acc________Dmg");
	TextDrawLetterSize         	(	rightText,		0.184588,		0.946666	);
	TextDrawAlignment          	(	rightText,		1							);
	TextDrawColor            	(	rightText,		-1							);
	TextDrawSetShadow           (	rightText,		0							);
	TextDrawSetOutline          (	rightText,		1							);
	//TextDrawBackgroundColor    	(	rightText,		0x3344FF33					);
	TextDrawBackgroundColor    	(	rightText,		0x4444FF33					);
	TextDrawFont            	(	rightText,		1							);
	TextDrawSetProportional     (	rightText,		1							);

	lowerULine = TextDrawCreate(	129.505859,		390.541168,		"-"			);
	TextDrawLetterSize         	(	lowerULine,		24.725660,		0.309667	);
	TextDrawAlignment          	(	lowerULine,		1							);
	TextDrawColor          		(	lowerULine,		-1							);
	TextDrawSetShadow          	(	lowerULine,		0							);
	TextDrawSetOutline         	(	lowerULine,		0							);
	TextDrawBackgroundColor    	(	lowerULine,		-1							);
	TextDrawFont           		(	lowerULine,		1							);
	TextDrawSetProportional    	(	lowerULine,		1							);

	teamWonHow = TextDrawCreate	(	304.187988,		345.974914,		"_"			);
	TextDrawLetterSize         	(	teamWonHow,		0.250094,		1.130083	);
	TextDrawAlignment          	(	teamWonHow,		2							);
	TextDrawColor          		(	teamWonHow,		-1							);
	TextDrawSetShadow          	(	teamWonHow,		0							);
	TextDrawSetOutline         	(	teamWonHow,		1							);
	TextDrawBackgroundColor    	(	teamWonHow,		30							);
	TextDrawFont            	(	teamWonHow,		3							);
	TextDrawSetProportional    	(	teamWonHow,		1							);

	leftTop = TextDrawCreate   	(	300.694656,		362.025115,		"_"			);
	TextDrawLetterSize         	(	leftTop,		0.18,			0.9			);
	TextDrawAlignment          	(	leftTop,		2							);
	TextDrawColor            	(	leftTop,		-1264229146					);
	TextDrawSetShadow          	(	leftTop,		0							);
	TextDrawSetOutline         	(	leftTop,		1							);
	TextDrawBackgroundColor    	(	leftTop,		0x00000011					);
	TextDrawFont            	(	leftTop,		1							);
	TextDrawSetProportional    	(	leftTop,		1							);
	TextDrawSetSelectable      	(	leftTop,		true						);

	//left content
	leftNames = TextDrawCreate	(	132.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftNames,		0.194799,		0.942583	);
	TextDrawAlignment          	(	leftNames,		1							);
	TextDrawColor            	(	leftNames,		-1							);
	TextDrawSetShadow          	(	leftNames,		0							);
	TextDrawSetOutline         	(	leftNames,		1							);
	TextDrawBackgroundColor    	(	leftNames,		0xFF003322					);
	TextDrawFont           		(	leftNames,		1							);
	TextDrawSetProportional    	(	leftNames,		1							);
	//left content
	leftKills = TextDrawCreate	(	223.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftKills,		0.194799,		0.942583	);
	TextDrawAlignment          	(	leftKills,		2							);
	TextDrawColor            	(	leftKills,		-1							);
	TextDrawSetShadow          	(	leftKills,		0							);
	TextDrawSetOutline         	(	leftKills,		1							);
	TextDrawBackgroundColor    	(	leftKills,		0xFF003322					);
	TextDrawFont           		(	leftKills,		1							);
	TextDrawSetProportional    	(	leftKills,		1							);
	//left content
	leftHP = TextDrawCreate		(	243.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftHP,			0.194799,		0.942583	);
	TextDrawAlignment          	(	leftHP,			2							);
	TextDrawColor            	(	leftHP,			-1							);
	TextDrawSetShadow          	(	leftHP,			0							);
	TextDrawSetOutline         	(	leftHP,			1							);
	TextDrawBackgroundColor    	(	leftHP,			0xFF003322					);
	TextDrawFont           		(	leftHP,			1							);
	TextDrawSetProportional    	(	leftHP,			1							);

	//left content for End MATCH (WAR)
	leftDeaths = TextDrawCreate		(	236.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftDeaths,			0.194799,		0.942583	);
	TextDrawAlignment          	(	leftDeaths,			2							);
	TextDrawColor            	(	leftDeaths,			-1							);
	TextDrawSetShadow          	(	leftDeaths,			0							);
	TextDrawSetOutline         	(	leftDeaths,			1							);
	TextDrawBackgroundColor    	(	leftDeaths,			0xFF003322					);
	TextDrawFont           		(	leftDeaths,			1							);
	TextDrawSetProportional    	(	leftDeaths,			1							);

	//left content
	leftAcc = TextDrawCreate	(	265.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftAcc,		0.194799,		0.942583	);
	TextDrawAlignment          	(	leftAcc,		2							);
	TextDrawColor            	(	leftAcc,		-1							);
	TextDrawSetShadow          	(	leftAcc,		0							);
	TextDrawSetOutline         	(	leftAcc,		1							);
	TextDrawBackgroundColor    	(	leftAcc,		0xFF003322					);
	TextDrawFont           		(	leftAcc,		1							);
	TextDrawSetProportional    	(	leftAcc,		1							);
	//left content
	leftDmg = TextDrawCreate	(	285.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftDmg,		0.194799,		0.942583	);
	TextDrawAlignment          	(	leftDmg,		2							);
	TextDrawColor            	(	leftDmg,		-1							);
	TextDrawSetShadow          	(	leftDmg,		0							);
	TextDrawSetOutline         	(	leftDmg,		1							);
	TextDrawBackgroundColor    	(	leftDmg,		0xFF003322					);
	TextDrawFont           		(	leftDmg,		1							);
	TextDrawSetProportional    	(	leftDmg,		1							);
	//left content
	leftPlayed = TextDrawCreate	(	248.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftPlayed,		0.194799,		0.942583	);
	TextDrawAlignment          	(	leftPlayed,		2							);
	TextDrawColor            	(	leftPlayed,		-1							);
	TextDrawSetShadow          	(	leftPlayed,		0							);
	TextDrawSetOutline         	(	leftPlayed,		1							);
	TextDrawBackgroundColor    	(	leftPlayed,		0xFF003322					);
	TextDrawFont           		(	leftPlayed,		1							);
	TextDrawSetProportional    	(	leftPlayed,		1							);
    //left content

	//right content
	rightNames = TextDrawCreate	(	310.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightNames,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightNames,		1							);
	TextDrawColor          		(	rightNames,		-1							);
	TextDrawSetShadow          	(	rightNames,		0							);
	TextDrawSetOutline         	(	rightNames,		1							);
	TextDrawBackgroundColor    	(	rightNames,		0x3344FF22					);
	TextDrawFont            	(	rightNames,		1							);
	TextDrawSetProportional    	(	rightNames,		1							);
	//right content
	rightKills = TextDrawCreate(	400.535293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightKills,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightKills,		2							);
	TextDrawColor          		(	rightKills,		-1							);
	TextDrawSetShadow          	(	rightKills,		0							);
	TextDrawSetOutline         	(	rightKills,		1							);
	TextDrawBackgroundColor    	(	rightKills,		0x3344FF22					);
	TextDrawFont            	(	rightKills,		1							);
	TextDrawSetProportional    	(	rightKills,		1							);
    //right content
	rightHP = TextDrawCreate	(	421.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightHP,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightHP,		2							);
	TextDrawColor          		(	rightHP,		-1							);
	TextDrawSetShadow          	(	rightHP,		0							);
	TextDrawSetOutline         	(	rightHP,		1							);
	TextDrawBackgroundColor    	(	rightHP,		0x3344FF22					);
	TextDrawFont            	(	rightHP,		1							);
	TextDrawSetProportional    	(	rightHP,		1							);

	//right content for End MATCH (WAR)
	rightDeaths = TextDrawCreate	(	414.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightDeaths,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightDeaths,		2							);
	TextDrawColor          		(	rightDeaths,		-1							);
	TextDrawSetShadow          	(	rightDeaths,		0							);
	TextDrawSetOutline         	(	rightDeaths,		1							);
	TextDrawBackgroundColor    	(	rightDeaths,		0x3344FF22					);
	TextDrawFont            	(	rightDeaths,		1							);
	TextDrawSetProportional    	(	rightDeaths,		1							);

	//right content
	rightAcc = TextDrawCreate	(	443.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightAcc,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightAcc,		2							);
	TextDrawColor          		(	rightAcc,		-1							);
	TextDrawSetShadow          	(	rightAcc,		0							);
	TextDrawSetOutline         	(	rightAcc,		1							);
	TextDrawBackgroundColor    	(	rightAcc,		0x3344FF22					);
	TextDrawFont            	(	rightAcc,		1							);
	TextDrawSetProportional    	(	rightAcc,		1							);
    //right content
	rightDmg = TextDrawCreate	(	463.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightDmg,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightDmg,		2							);
	TextDrawColor          		(	rightDmg,		-1							);
	TextDrawSetShadow          	(	rightDmg,		0							);
	TextDrawSetOutline         	(	rightDmg,		1							);
	TextDrawBackgroundColor    	(	rightDmg,		0x3344FF22					);
	TextDrawFont            	(	rightDmg,		1							);
	TextDrawSetProportional    	(	rightDmg,		1							);
    //right content
	rightPlayed = TextDrawCreate(	426.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightPlayed,	0.194799,		0.942583	);
	TextDrawAlignment          	(	rightPlayed,	2							);
	TextDrawColor          		(	rightPlayed,	-1							);
	TextDrawSetShadow          	(	rightPlayed,	0							);
	TextDrawSetOutline         	(	rightPlayed,	1							);
	TextDrawBackgroundColor    	(	rightPlayed,	0x3344FF22					);
	TextDrawFont            	(	rightPlayed,	1							);
	TextDrawSetProportional    	(	rightPlayed,	1							);
    //right content
}

RoundTextdrawsCreate()
{
	leftRedBG = TextDrawCreate		(	335.540924, 	401.283630, "-");
	TextDrawLetterSize				(	leftRedBG, 		-28.081052, 7.287504);
	TextDrawAlignment				(	leftRedBG, 		1							);
	TextDrawColor					(	leftRedBG, 		0x00000011					);
	TextDrawSetShadow				(	leftRedBG, 		-1							);
	TextDrawSetOutline				(	leftRedBG, 		0							);
	TextDrawBackgroundColor			(	leftRedBG, 		0xDE000033					);
	TextDrawFont					(	leftRedBG, 		1							);
	TextDrawSetProportional			(	leftRedBG, 		1							);

	rightBlueBG = TextDrawCreate	(	311.741302, 	401.283630, "-"				);
	TextDrawLetterSize				(	rightBlueBG, 	28.770492, 7.287504			);
	TextDrawAlignment				(	rightBlueBG, 	1							);
	TextDrawColor					(	rightBlueBG, 	0x00000011					);
	TextDrawSetShadow				(	rightBlueBG, 	-1							);
	TextDrawSetOutline				(	rightBlueBG,	0							);
	TextDrawBackgroundColor			(	rightBlueBG, 	0x3344FF33					);
	TextDrawFont					(	rightBlueBG, 	1							);
	TextDrawSetProportional			(	rightBlueBG, 	1							);

	timerCenterTD = TextDrawCreate	(	324.140991, 		434.872528, "~w~0:00 / ~r~~h~00");
	TextDrawLetterSize				(	timerCenterTD, 		0.24, 1.34);
	TextDrawTextSize				(	timerCenterTD, 		299.293579, 98.583343	);
	TextDrawAlignment				(	timerCenterTD, 		2						);
	TextDrawColor					(	timerCenterTD, 		-1						);
	TextDrawSetShadow				(	timerCenterTD, 		0						);
	TextDrawSetOutline				(	timerCenterTD, 		1						);
	TextDrawBackgroundColor			(	timerCenterTD,	 	MAIN_BACKGROUND_COLOUR	);
	TextDrawFont					(	timerCenterTD, 		2						);
	TextDrawSetProportional			(	timerCenterTD, 		1						);

	timerCircleTD = TextDrawCreate(281.000000, 509.000000, "ld_pool:ball");
	TextDrawBackgroundColor(timerCircleTD, 255);
	TextDrawFont(timerCircleTD, 4);
	TextDrawLetterSize(timerCircleTD, -0.039999, 18.500000);
	TextDrawColor(timerCircleTD, 0x00000033);
	TextDrawSetOutline(timerCircleTD, 1);
	TextDrawSetProportional(timerCircleTD, 0);
	TextDrawUseBox(timerCircleTD, 1);
	TextDrawBoxColor(timerCircleTD, -1);
	TextDrawTextSize(timerCircleTD, 88.000000, -82.000000);

	leftTeamData = TextDrawCreate	(	255.400375, 		435.060705, "~w~_");
	TextDrawLetterSize				(	leftTeamData, 		0.22, 1.22				);
	TextDrawAlignment				(	leftTeamData, 		2						);
	TextDrawColor					(	leftTeamData, 		-1						);
	TextDrawSetShadow				(	leftTeamData, 		0						);
	TextDrawSetOutline				(	leftTeamData, 		-1						);
	TextDrawBackgroundColor			(	leftTeamData, 		0xDE000011				);
	TextDrawFont					(	leftTeamData, 		1						);
	TextDrawSetProportional			(	leftTeamData, 		1						);

	rightTeamData = TextDrawCreate	(	387.682586, 		435.050573, "~w~_");
	TextDrawLetterSize				(	rightTeamData, 		0.22, 1.22				);
	TextDrawAlignment				(	rightTeamData, 		2						);
	TextDrawColor					(	rightTeamData, 		-1						);
	TextDrawSetShadow				(	rightTeamData, 		0						);
	TextDrawSetOutline				(	rightTeamData, 		-1						);
	TextDrawBackgroundColor			(	rightTeamData, 		0x3344FF11				);
	TextDrawFont					(	rightTeamData, 		1						);
	TextDrawSetProportional			(	rightTeamData, 		1						);

//Qwerty _______________________________________________________________ ~b~~h~~h~Asdfg");
	centerTeamNames = TextDrawCreate(	321.0, 		425.776257, "~r~~h~~h~__- __ -");
	TextDrawLetterSize				(	centerTeamNames, 	0.200000, 	2.000000	);
	TextDrawAlignment				(	centerTeamNames, 	2						);
	TextDrawColor					(	centerTeamNames, 	-1						);
	TextDrawSetShadow				(	centerTeamNames,	0						);
	TextDrawSetOutline				(	centerTeamNames, 	1						);
	TextDrawBackgroundColor			(	centerTeamNames, 	0x00000033				);
	TextDrawFont					(	centerTeamNames,	1						);
	TextDrawSetProportional			(	centerTeamNames, 	1						);

	attackerNameTD = TextDrawCreate	(	190.000000, 428.000000, "~r~~h~~h~__- __ -");
	TextDrawLetterSize				(	attackerNameTD, 	0.200000, 	2.000000	);
	TextDrawAlignment				(	attackerNameTD, 	2						);
	TextDrawColor					(	attackerNameTD, 	-1						);
	TextDrawSetShadow				(	attackerNameTD,	0						);
	TextDrawSetOutline				(	attackerNameTD, 	1						);
	TextDrawBackgroundColor			(	attackerNameTD, 	MAIN_BACKGROUND_COLOUR);
	TextDrawFont					(	attackerNameTD,	1						);
	TextDrawSetProportional			(	attackerNameTD, 	1						);

	defenderNameTD = TextDrawCreate	(	448.000000, 428.000000, "~r~~h~~h~__- __ -");
	TextDrawLetterSize				(	defenderNameTD, 	0.200000, 	2.000000	);
	TextDrawAlignment				(	defenderNameTD, 	2						);
	TextDrawColor					(	defenderNameTD, 	-1						);
	TextDrawSetShadow				(	defenderNameTD,	0						);
	TextDrawSetOutline				(	defenderNameTD, 	1						);
	TextDrawBackgroundColor			(	defenderNameTD, 	MAIN_BACKGROUND_COLOUR);
	TextDrawFont					(	defenderNameTD,	1						);
	TextDrawSetProportional			(	defenderNameTD, 	1						);

	PauseTD = TextDrawCreate(324.000000, 390.000000, "~r~~h~~h~Round paused");
	TextDrawBackgroundColor(PauseTD, MAIN_BACKGROUND_COLOUR);
	TextDrawFont(PauseTD, 1);
	TextDrawLetterSize(PauseTD, 0.280000, 1.500000);
	TextDrawColor(PauseTD, 255);
	TextDrawSetOutline(PauseTD, 1);
	TextDrawSetProportional(PauseTD, 1);
	TextDrawAlignment(PauseTD, 2);

	AttDef_RoundStats = TextDrawCreate(318.0,431.5,"_");
	TextDrawUseBox(AttDef_RoundStats,1);
	TextDrawBoxColor(AttDef_RoundStats,0x0000022);
	TextDrawFont(AttDef_RoundStats, 1);
	TextDrawTextSize(AttDef_RoundStats,14.0,640.0);
	TextDrawLetterSize(AttDef_RoundStats, 0.31, 1.55);
	TextDrawBackgroundColor(AttDef_RoundStats, MAIN_BACKGROUND_COLOUR);
	TextDrawColor(AttDef_RoundStats,-65281);
	TextDrawSetOutline(AttDef_RoundStats,1);
	TextDrawSetShadow(AttDef_RoundStats,0);
    TextDrawAlignment(AttDef_RoundStats,2);
    TextDrawSetProportional(AttDef_RoundStats, 1);

	AttDef_RoundTimer = TextDrawCreate(327.000000, 431.500000, "_");
	TextDrawAlignment(AttDef_RoundTimer, 2);
	TextDrawBackgroundColor(AttDef_RoundTimer, MAIN_BACKGROUND_COLOUR);
	TextDrawFont(AttDef_RoundTimer, 1);
	TextDrawLetterSize(AttDef_RoundTimer, 0.31, 1.55);
	TextDrawColor(AttDef_RoundTimer, -1);
	TextDrawSetOutline(AttDef_RoundTimer, 1);
	TextDrawSetProportional(AttDef_RoundTimer, 1);

    AttDef_ModernRoundStats[0] = TextDrawCreate(513.540893, 374.283630, "-");
	TextDrawBackgroundColor(AttDef_ModernRoundStats[0], 0x000000AA);
	TextDrawFont(AttDef_ModernRoundStats[0], 1);
	TextDrawLetterSize(AttDef_ModernRoundStats[0], -28.081052, 11.987506);
	TextDrawColor(AttDef_ModernRoundStats[0], 34);
	TextDrawSetOutline(AttDef_ModernRoundStats[0], 0);
	TextDrawSetProportional(AttDef_ModernRoundStats[0], 1);
	TextDrawSetShadow(AttDef_ModernRoundStats[0], 1);

	AttDef_ModernRoundStats[1] = TextDrawCreate(306.741302, 396.283630, "-"); // Red Line
	TextDrawBackgroundColor(AttDef_ModernRoundStats[1], 0x90111120);
	TextDrawFont(AttDef_ModernRoundStats[1], 1);
	TextDrawLetterSize(AttDef_ModernRoundStats[1], -28.770492, 8.187503);
	TextDrawColor(AttDef_ModernRoundStats[1], 34);
	TextDrawSetOutline(AttDef_ModernRoundStats[1], 1);
	TextDrawSetProportional(AttDef_ModernRoundStats[1], 1);

	AttDef_ModernRoundStats[2] = TextDrawCreate(331.741302, 395.283630, "-"); // Blue Line
	TextDrawBackgroundColor(AttDef_ModernRoundStats[2], 0x22222020);
	TextDrawFont(AttDef_ModernRoundStats[2], 1);
	TextDrawLetterSize(AttDef_ModernRoundStats[2], 28.770492, 8.187503);
	TextDrawColor(AttDef_ModernRoundStats[2], 860159812);
	TextDrawSetOutline(AttDef_ModernRoundStats[2], 1);
	TextDrawSetProportional(AttDef_ModernRoundStats[2], 1);

	AttDef_ModernRoundStats[3] = TextDrawCreate(211.000000, 429.000000, "Alpha");
	TextDrawAlignment(AttDef_ModernRoundStats[3], 2);
	TextDrawBackgroundColor(AttDef_ModernRoundStats[3], 51);
	TextDrawFont(AttDef_ModernRoundStats[3], 2);
	TextDrawLetterSize(AttDef_ModernRoundStats[3], 0.2000, 1.300000);
	TextDrawColor(AttDef_ModernRoundStats[3], -1440603393);
	TextDrawSetOutline(AttDef_ModernRoundStats[3], 1);
	TextDrawSetProportional(AttDef_ModernRoundStats[3], 1);
	TextDrawSetShadow(AttDef_ModernRoundStats[3], 2);

	AttDef_ModernRoundStats[4] = TextDrawCreate(431.000000, 429.000000, "Beta");
	TextDrawAlignment(AttDef_ModernRoundStats[4], 2);
	TextDrawBackgroundColor(AttDef_ModernRoundStats[4], 51);
	TextDrawFont(AttDef_ModernRoundStats[4], 2);
	TextDrawLetterSize(AttDef_ModernRoundStats[4], 0.2000, 1.300000);
	TextDrawColor(AttDef_ModernRoundStats[4], 1145350911);
	TextDrawSetOutline(AttDef_ModernRoundStats[4], 1);
	TextDrawSetProportional(AttDef_ModernRoundStats[4], 1);
	TextDrawSetShadow(AttDef_ModernRoundStats[4], 2);

	AttDef_ModernRoundStats[5] = TextDrawCreate(320.000000, 435.000000, "01:30");
	TextDrawAlignment(AttDef_ModernRoundStats[5], 2);
	TextDrawBackgroundColor(AttDef_ModernRoundStats[5], 51);
	TextDrawFont(AttDef_ModernRoundStats[5], 2);
	TextDrawLetterSize(AttDef_ModernRoundStats[5], 0.250000, 1.200000);
	TextDrawColor(AttDef_ModernRoundStats[5], -1);
	TextDrawSetOutline(AttDef_ModernRoundStats[5], 1);
	TextDrawSetProportional(AttDef_ModernRoundStats[5], 1);
	TextDrawSetShadow(AttDef_ModernRoundStats[5], 0);

	AttDef_ModernRoundStats[6] = TextDrawCreate(257.000000, 435.000000, "4 [200]");
	TextDrawAlignment(AttDef_ModernRoundStats[6], 2);
	TextDrawBackgroundColor(AttDef_ModernRoundStats[6], 0xFF222233);
	TextDrawFont(AttDef_ModernRoundStats[6], 1);
	TextDrawLetterSize(AttDef_ModernRoundStats[6], 0.250000, 1.200000);
	TextDrawColor(AttDef_ModernRoundStats[6], -1440603393);
	TextDrawSetOutline(AttDef_ModernRoundStats[6], 1);
	TextDrawSetProportional(AttDef_ModernRoundStats[6], 1);
	TextDrawSetShadow(AttDef_ModernRoundStats[6], 2);

	AttDef_ModernRoundStats[7] = TextDrawCreate(387.000000, 435.000000, "4 [200]");
	TextDrawAlignment(AttDef_ModernRoundStats[7], 2);
	TextDrawBackgroundColor(AttDef_ModernRoundStats[7], 0x4444FF33);
	TextDrawFont(AttDef_ModernRoundStats[7], 1);
	TextDrawLetterSize(AttDef_ModernRoundStats[7], 0.250000, 1.200000);
	TextDrawColor(AttDef_ModernRoundStats[7], 1145363967);
	TextDrawSetOutline(AttDef_ModernRoundStats[7], 1);
	TextDrawSetProportional(AttDef_ModernRoundStats[7], 1);
	TextDrawSetShadow(AttDef_ModernRoundStats[7], 2);

	AttHpLose = TextDrawCreate(10.000000, 436.000000, "_");
	TextDrawBackgroundColor(AttHpLose, MAIN_BACKGROUND_COLOUR);
	TextDrawFont(AttHpLose, 1);
	TextDrawLetterSize(AttHpLose, 0.160000, 1.060000);
	TextDrawColor(AttHpLose, 0x222222FF);
	TextDrawSetOutline(AttHpLose, 1);
	TextDrawSetProportional(AttHpLose, 1);
	TextDrawAlignment(AttHpLose,1);
	TextDrawSetShadow(AttHpLose, 0);

	DefHpLose = TextDrawCreate(630.000000, 436.000000, "_");
	TextDrawBackgroundColor(DefHpLose, MAIN_BACKGROUND_COLOUR);
	TextDrawFont(DefHpLose, 1);
	TextDrawLetterSize(DefHpLose, 0.160000, 1.060000);
	TextDrawColor(DefHpLose, 0x222222FF);
	TextDrawSetOutline(DefHpLose, 1);
	TextDrawSetProportional(DefHpLose, 1);
	TextDrawAlignment(DefHpLose,3);
	TextDrawSetShadow(DefHpLose, 0);

	TeamHpLose[0] = TextDrawCreate(255.000000, 412.000000, "_");
	TextDrawAlignment(TeamHpLose[0], 2);
	TextDrawFont(TeamHpLose[0], 2);
	TextDrawLetterSize(TeamHpLose[0], 0.20000, 1.70000);
	TextDrawBackgroundColor(TeamHpLose[0],MAIN_BACKGROUND_COLOUR);
	TextDrawColor(TeamHpLose[0], 0x222222FF);
	TextDrawSetOutline(TeamHpLose[0], 1);
	TextDrawSetProportional(TeamHpLose[0], 1);
	TextDrawSetShadow(TeamHpLose[0],0);

	TeamHpLose[1] = TextDrawCreate(387.000000, 412.000000, "_");
	TextDrawAlignment(TeamHpLose[1], 2);
	TextDrawFont(TeamHpLose[1], 2);
	TextDrawLetterSize(TeamHpLose[1], 0.20000, 1.70000);
	TextDrawBackgroundColor(TeamHpLose[1],MAIN_BACKGROUND_COLOUR);
	TextDrawColor(TeamHpLose[1], 0x222222FF);
	TextDrawSetOutline(TeamHpLose[1], 1);
	TextDrawSetProportional(TeamHpLose[1], 1);
	TextDrawSetShadow(TeamHpLose[1], 0);

	CreateTeamCornerTextDraws();
}

LoadPlayerTextDraws(playerid)
{
	HealthBar[playerid] = CreatePlayerProgressBar(playerid, 547.000000, 67.000000, 64.000000, 6.000000, 0xB4191DFF, 100.000000, BAR_DIRECTION_RIGHT);

	HPTextDraw_TD[playerid] = CreatePlayerTextDraw(playerid,577, 67.1, "_");
	PlayerTextDrawBackgroundColor(playerid, HPTextDraw_TD[playerid], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, HPTextDraw_TD[playerid], 2);
	PlayerTextDrawLetterSize(playerid, HPTextDraw_TD[playerid], 0.2300, 0.7000);
	PlayerTextDrawColor(playerid, HPTextDraw_TD[playerid], 16711935);
	PlayerTextDrawSetOutline(playerid, HPTextDraw_TD[playerid], 0);
	PlayerTextDrawSetProportional(playerid, HPTextDraw_TD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, HPTextDraw_TD[playerid],0);
	PlayerTextDrawAlignment(playerid, HPTextDraw_TD[playerid], 2);

	ArmourTextDraw[playerid] = CreatePlayerTextDraw(playerid,577, 46.0, "_");
	PlayerTextDrawBackgroundColor(playerid, ArmourTextDraw[playerid], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, ArmourTextDraw[playerid], 2);
	PlayerTextDrawLetterSize(playerid, ArmourTextDraw[playerid], 0.2300, 0.7000);
	PlayerTextDrawColor(playerid, ArmourTextDraw[playerid], 16711935);
	PlayerTextDrawSetOutline(playerid, ArmourTextDraw[playerid], 0);
	PlayerTextDrawSetProportional(playerid, ArmourTextDraw[playerid], 1);
	PlayerTextDrawSetShadow(playerid, ArmourTextDraw[playerid],0);
	PlayerTextDrawAlignment(playerid, ArmourTextDraw[playerid], 2);

	BaseID_VS[playerid] = CreatePlayerTextDraw(playerid, 548.000000, 25.000000,"_");
	PlayerTextDrawFont(playerid, BaseID_VS[playerid], 1);
	PlayerTextDrawLetterSize(playerid, BaseID_VS[playerid], 0.26000, 1.500000);
	PlayerTextDrawBackgroundColor(playerid, BaseID_VS[playerid],MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, BaseID_VS[playerid],-65281);
	PlayerTextDrawSetOutline(playerid, BaseID_VS[playerid],1);
	PlayerTextDrawSetProportional(playerid, BaseID_VS[playerid], 1);
	PlayerTextDrawSetShadow(playerid, BaseID_VS[playerid],0);

	HidePlayerProgressBar(playerid, HealthBar[playerid]);
	PlayerTextDrawHide(playerid, HPTextDraw_TD[playerid]);
	PlayerTextDrawHide(playerid, ArmourTextDraw[playerid]);
	PlayerTextDrawHide(playerid, BaseID_VS[playerid]);

    TargetInfoData[playerid][TargetInfoTD] = CreatePlayerTextDraw(playerid, 55.000000, 300.000000, "_");
	PlayerTextDrawBackgroundColor(playerid, TargetInfoData[playerid][TargetInfoTD], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, TargetInfoData[playerid][TargetInfoTD], 1);
	PlayerTextDrawLetterSize(playerid, TargetInfoData[playerid][TargetInfoTD], 0.200000, 1.0);
	PlayerTextDrawColor(playerid, TargetInfoData[playerid][TargetInfoTD], 255);
	PlayerTextDrawUseBox(playerid, TargetInfoData[playerid][TargetInfoTD], 0);
	PlayerTextDrawBoxColor(playerid, TargetInfoData[playerid][TargetInfoTD], 0x00000011);
	PlayerTextDrawSetOutline(playerid, TargetInfoData[playerid][TargetInfoTD], 1);
	PlayerTextDrawSetProportional(playerid, TargetInfoData[playerid][TargetInfoTD], 1);
	PlayerTextDrawTextSize(playerid, TargetInfoData[playerid][TargetInfoTD], 167.000000, 0.000000);

	TD_RoundSpec[playerid] = CreatePlayerTextDraw(playerid, 330.000000, 350.000000,"_");
	PlayerTextDrawFont(playerid, TD_RoundSpec[playerid], 1);
	PlayerTextDrawLetterSize(playerid, TD_RoundSpec[playerid], 0.40000, 2.00000);
	PlayerTextDrawBackgroundColor(playerid, TD_RoundSpec[playerid], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, TD_RoundSpec[playerid], -65281);
	PlayerTextDrawSetOutline(playerid, TD_RoundSpec[playerid], 1);
    PlayerTextDrawAlignment(playerid, TD_RoundSpec[playerid], 2);
    PlayerTextDrawSetShadow(playerid, TD_RoundSpec[playerid], 0);

	FPSPingPacket[playerid] = CreatePlayerTextDraw(playerid,502.0, 1.4, "_");
	PlayerTextDrawBackgroundColor(playerid, FPSPingPacket[playerid], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, FPSPingPacket[playerid], 1);
    PlayerTextDrawLetterSize(playerid, FPSPingPacket[playerid], 0.190000, 0.93000);
	PlayerTextDrawColor(playerid, FPSPingPacket[playerid], 16711935);
	PlayerTextDrawSetOutline(playerid, FPSPingPacket[playerid], 1);
	PlayerTextDrawSetProportional(playerid, FPSPingPacket[playerid], 1);
	PlayerTextDrawAlignment(playerid, FPSPingPacket[playerid], 1);

	RoundKillDmgTDmg[playerid] = CreatePlayerTextDraw(playerid,3.000000, 403.000000, "_");
	PlayerTextDrawFont(playerid, RoundKillDmgTDmg[playerid], 1);
	PlayerTextDrawLetterSize(playerid, RoundKillDmgTDmg[playerid], 0.200000, 0.900000);
	PlayerTextDrawBackgroundColor(playerid, RoundKillDmgTDmg[playerid], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, RoundKillDmgTDmg[playerid], 16711935);
	PlayerTextDrawSetOutline(playerid, RoundKillDmgTDmg[playerid], 1);
	PlayerTextDrawSetProportional(playerid, RoundKillDmgTDmg[playerid], 1);

	// Create visual damage textdraws
	new Float:y = 340.0;

	// Friendly fire textdraws
	FriendlyDamage[playerid][0] = CreatePlayerTextDraw(playerid,170.0,y,"_");
	PlayerTextDrawFont(playerid, FriendlyDamage[playerid][0], 1);
	PlayerTextDrawLetterSize(playerid, FriendlyDamage[playerid][0], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, FriendlyDamage[playerid][0],MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, FriendlyDamage[playerid][0], 16727295);
	PlayerTextDrawSetProportional(playerid, FriendlyDamage[playerid][0], 1);
	PlayerTextDrawSetOutline(playerid, FriendlyDamage[playerid][0],1);
	PlayerTextDrawSetShadow(playerid, FriendlyDamage[playerid][0],0);

	FriendlyDamage[playerid][1] = CreatePlayerTextDraw(playerid,380.0,y,"_");
	PlayerTextDrawFont(playerid, FriendlyDamage[playerid][1], 1);
	PlayerTextDrawLetterSize(playerid, FriendlyDamage[playerid][1], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, FriendlyDamage[playerid][1],MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, FriendlyDamage[playerid][1], 16727295);
	PlayerTextDrawSetProportional(playerid, FriendlyDamage[playerid][1], 1);
	PlayerTextDrawSetOutline(playerid, FriendlyDamage[playerid][1],1);
	PlayerTextDrawSetShadow(playerid, FriendlyDamage[playerid][1],0);

	PlayerTextDrawShow(playerid, FriendlyDamage[playerid][0]);
	PlayerTextDrawShow(playerid, FriendlyDamage[playerid][1]);

	y += DAMAGE_TEXTDRAW_Y_DIFF;

	// Other visual damage textdraws
	for(new i = 0; i < MAX_VISUAL_DAMAGES; i ++)
	{
		VisualDamage[playerid][ShownTakenDamage][i] = false;
		VisualDamage[playerid][ShownGivenDamage][i] = false;

		DoingDamage[playerid][i] = CreatePlayerTextDraw(playerid,170.0,y,"_");
		PlayerTextDrawFont(playerid, DoingDamage[playerid][i], 1);
		PlayerTextDrawLetterSize(playerid, DoingDamage[playerid][i], 0.18000, 0.9);
		PlayerTextDrawBackgroundColor(playerid, DoingDamage[playerid][i],MAIN_BACKGROUND_COLOUR);
		PlayerTextDrawColor(playerid, DoingDamage[playerid][i], 16727295);
		PlayerTextDrawSetProportional(playerid, DoingDamage[playerid][i], 1);
		PlayerTextDrawSetOutline(playerid, DoingDamage[playerid][i],1);
		PlayerTextDrawSetShadow(playerid, DoingDamage[playerid][i],0);

		GettingDamaged[playerid][i] = CreatePlayerTextDraw(playerid,380.0,y,"_");
		PlayerTextDrawFont(playerid, GettingDamaged[playerid][i], 1);
		PlayerTextDrawLetterSize(playerid, GettingDamaged[playerid][i], 0.18000, 0.9);
		PlayerTextDrawBackgroundColor(playerid, GettingDamaged[playerid][i],MAIN_BACKGROUND_COLOUR);
		PlayerTextDrawColor(playerid, GettingDamaged[playerid][i], 16727295);
		PlayerTextDrawSetProportional(playerid, GettingDamaged[playerid][i], 1);
		PlayerTextDrawSetOutline(playerid, GettingDamaged[playerid][i],1);
		PlayerTextDrawSetShadow(playerid, GettingDamaged[playerid][i],0);

		PlayerTextDrawShow(playerid, DoingDamage[playerid][i]);
		PlayerTextDrawShow(playerid, GettingDamaged[playerid][i]);

		y += DAMAGE_TEXTDRAW_Y_DIFF;
	}

    WhoSpec[playerid] = CreatePlayerTextDraw(playerid, 1, 150.00000, "_");
	PlayerTextDrawBackgroundColor(playerid, WhoSpec[playerid], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, WhoSpec[playerid], 1);
	PlayerTextDrawLetterSize(playerid, WhoSpec[playerid], 0.180000, 0.9);
	PlayerTextDrawColor(playerid, WhoSpec[playerid], -1);
	PlayerTextDrawSetOutline(playerid, WhoSpec[playerid], 1);
	PlayerTextDrawSetProportional(playerid, WhoSpec[playerid], 1);
	PlayerTextDrawSetShadow(playerid, WhoSpec[playerid], 0);

	SpecText[playerid][0] = CreatePlayerTextDraw(playerid, 4.333333, 354.251831 - 70.0, "LD_POKE:cd9s");
	PlayerTextDrawLetterSize(playerid, SpecText[playerid][0], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, SpecText[playerid][0], 72.000000, 79);
	PlayerTextDrawAlignment(playerid, SpecText[playerid][0], 1);
	PlayerTextDrawColor(playerid, SpecText[playerid][0], 0x00000033);
	PlayerTextDrawSetShadow(playerid, SpecText[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, SpecText[playerid][0], 0);
	PlayerTextDrawFont(playerid, SpecText[playerid][0], 4);

    SpecText[playerid][1] = CreatePlayerTextDraw(playerid, 40, 350 - 70.0, "_");
	PlayerTextDrawFont(playerid, SpecText[playerid][1], 1);
	PlayerTextDrawLetterSize(playerid, SpecText[playerid][1], 0.20000, 1.000000);
	PlayerTextDrawColor(playerid, SpecText[playerid][1], -65281);
	PlayerTextDrawBackgroundColor(playerid, SpecText[playerid][1], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawSetOutline(playerid, SpecText[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, SpecText[playerid][1], 0);
	PlayerTextDrawAlignment(playerid, SpecText[playerid][1], 2);

	SpecText[playerid][2] = CreatePlayerTextDraw(playerid, 80.333333, 354.251831 - 70.0, "LD_POKE:cd9s");
	PlayerTextDrawLetterSize(playerid, SpecText[playerid][2], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, SpecText[playerid][2], 58.000000, 75);
	PlayerTextDrawAlignment(playerid, SpecText[playerid][2], 1);
	PlayerTextDrawColor(playerid, SpecText[playerid][2], 0x00000033);
	PlayerTextDrawSetShadow(playerid, SpecText[playerid][2], 0);
	PlayerTextDrawSetOutline(playerid, SpecText[playerid][2], 0);
	PlayerTextDrawFont(playerid, SpecText[playerid][2], 4);

    SpecText[playerid][3] = CreatePlayerTextDraw(playerid, 85, 350 - 70.0, "_");
	PlayerTextDrawFont(playerid, SpecText[playerid][3], 1);
	PlayerTextDrawLetterSize(playerid, SpecText[playerid][3], 0.20000, 1.000000);
	PlayerTextDrawColor(playerid, SpecText[playerid][3], -65281);
	PlayerTextDrawBackgroundColor(playerid, SpecText[playerid][3], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawSetOutline(playerid, SpecText[playerid][3], 1);
	PlayerTextDrawSetShadow(playerid, SpecText[playerid][3], 0);
	PlayerTextDrawAlignment(playerid, SpecText[playerid][3], 1);

   	AreaCheckTD[playerid] = CreatePlayerTextDraw(playerid,320.000000, 210.000000, "_");
	PlayerTextDrawAlignment(playerid, AreaCheckTD[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid, AreaCheckTD[playerid], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, AreaCheckTD[playerid], 3);
	PlayerTextDrawLetterSize(playerid, AreaCheckTD[playerid], 0.6, 3.00000);
	PlayerTextDrawColor(playerid, AreaCheckTD[playerid], -65281);
	PlayerTextDrawSetOutline(playerid, AreaCheckTD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, AreaCheckTD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, AreaCheckTD[playerid], 0);

	AreaCheckBG[playerid] = CreatePlayerTextDraw(playerid,645.00000, -5.000000," ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~~n~ ~n~~n~~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~~n~ ~n~~n~~n~~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~~n~ ~n~~n~~n~ ");
    PlayerTextDrawUseBox(playerid, AreaCheckBG[playerid], 1);
    PlayerTextDrawTextSize(playerid, AreaCheckBG[playerid], -5, 645);
    PlayerTextDrawBoxColor(playerid, AreaCheckBG[playerid], 0x00000044);
	PlayerTextDrawSetOutline(playerid, AreaCheckBG[playerid],0);

	DeathText[playerid][0] = CreatePlayerTextDraw(playerid,322.000000, 321.000000, "_");
	PlayerTextDrawBackgroundColor(playerid, DeathText[playerid][0], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, DeathText[playerid][0], 1);
	PlayerTextDrawLetterSize(playerid, DeathText[playerid][0], 0.280000, 1.4000);
	PlayerTextDrawColor(playerid, DeathText[playerid][0], 16711935);
	PlayerTextDrawSetOutline(playerid, DeathText[playerid][0], 1);
	PlayerTextDrawSetProportional(playerid, DeathText[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, DeathText[playerid][0], 0);
	PlayerTextDrawAlignment(playerid, DeathText[playerid][0], 2);

	DeathText[playerid][1] = CreatePlayerTextDraw(playerid,322, 335.000000, "_");
	PlayerTextDrawBackgroundColor(playerid, DeathText[playerid][1], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, DeathText[playerid][1], 1);
	PlayerTextDrawLetterSize(playerid, DeathText[playerid][1], 0.280000, 1.4000);
	PlayerTextDrawColor(playerid, DeathText[playerid][1], 16711935);
	PlayerTextDrawSetOutline(playerid, DeathText[playerid][1], 1);
	PlayerTextDrawSetProportional(playerid, DeathText[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, DeathText[playerid][1], 0);
	PlayerTextDrawAlignment(playerid, DeathText[playerid][1], 2);

	#if defined _league_included
	CreatePlayerLeaguePointTextDraw(playerid);
	#endif
	CreatePlayerWeaponBindTextDraw(playerid);
	CreateMessageBoxTextDraws(playerid);
	return 1;
}

UpdateRoundKillDmgTDmg(playerid)
{
    new iString[160];

	//format(iString, sizeof(iString), "%sKills %s%d~n~%sDamage %s%d~n~%sTotal Dmg %s%d", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][RoundKills], MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][TotalDamage]);
	format(iString, sizeof(iString), "%sKills ~r~%d~n~%sDamage ~r~%d~n~%sTotal Dmg ~r~%d", MAIN_TEXT_COLOUR,Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);

	PlayerTextDrawSetString(playerid, RoundKillDmgTDmg[playerid], iString);
    return 1;
}

UpdateTeamNamesTextdraw()
{
	new str[16];
	format(str, sizeof(str), "~r~~h~~h~%s", TeamName[ATTACKER]);
	TextDrawSetString(attackerNameTD, str);
	TextDrawSetString(AttDef_ModernRoundStats[3], str);
	format(str, sizeof(str), "~b~~h~~h~%s", TeamName[DEFENDER]);
	TextDrawSetString(defenderNameTD, str);
	TextDrawSetString(AttDef_ModernRoundStats[4], str);
	return 1;
}

ShowRoundStats(playerid)
{
	if(!RoundPaused)
		TextDrawHideForPlayer(playerid, PauseTD);
	else
	{
		TextDrawShowForPlayer(playerid, PauseTD);
	}

	switch(Player[playerid][RoundTDStyle])
	{
		/**** Modern Round Textdraws ****/
		case 0:
		{
		    for(new i=0; i < sizeof(AttDef_ModernRoundStats); i++)
			    TextDrawShowForPlayer(playerid,AttDef_ModernRoundStats[i]);
		}
		/**** Bulletproof Gamemode Textdraws ****/
		case 1:
		{
			TextDrawShowForPlayer(playerid,leftRedBG);
			TextDrawShowForPlayer(playerid,rightBlueBG);
			TextDrawShowForPlayer(playerid,timerCenterTD);
			TextDrawShowForPlayer(playerid,timerCircleTD);
			TextDrawShowForPlayer(playerid,leftTeamData);
			TextDrawShowForPlayer(playerid,rightTeamData);
			TextDrawShowForPlayer(playerid,centerTeamNames);
			TextDrawShowForPlayer(playerid,attackerNameTD);
			TextDrawShowForPlayer(playerid,defenderNameTD);
		}
	    /**** Simple Attack-Defend Textdraws ****/
	    case 2:
		{
			TextDrawShowForPlayer(playerid, AttDef_RoundStats);
			TextDrawShowForPlayer(playerid, AttDef_RoundTimer);
		}
	}
}

HideRoundStats(playerid)
{
	switch(Player[playerid][RoundTDStyle])
	{
		/**** Modern Round Textdraws ****/
		case 0:
		{
		    for(new i=0; i < sizeof(AttDef_ModernRoundStats); i++)
			    TextDrawHideForPlayer(playerid,AttDef_ModernRoundStats[i]);
		}
		/**** Bulletproof Gamemode Textdraws ****/
		case 1:
		{
			TextDrawHideForPlayer(playerid,leftRedBG);
			TextDrawHideForPlayer(playerid,rightBlueBG);
			TextDrawHideForPlayer(playerid,timerCenterTD);
			TextDrawHideForPlayer(playerid,timerCircleTD);
			TextDrawHideForPlayer(playerid,leftTeamData);
			TextDrawHideForPlayer(playerid,rightTeamData);
			TextDrawHideForPlayer(playerid,centerTeamNames);
			TextDrawHideForPlayer(playerid,attackerNameTD);
			TextDrawHideForPlayer(playerid,defenderNameTD);
		}
	    /**** Simple Attack-Defend Textdraws ****/
	    case 2:
		{
			TextDrawHideForPlayer(playerid, AttDef_RoundStats);
			TextDrawHideForPlayer(playerid, AttDef_RoundTimer);
		}
	}

	if(!RoundPaused)
		TextDrawHideForPlayer(playerid, PauseTD);
}

ResetRoundTextDraws()
{
	/**** Modern Round Textdraws ****/
	TextDrawSetString(AttDef_ModernRoundStats[3], "_");
	TextDrawSetString(AttDef_ModernRoundStats[4], "_");
	TextDrawSetString(AttDef_ModernRoundStats[5], "_");
	TextDrawSetString(AttDef_ModernRoundStats[6], "_");
	TextDrawSetString(AttDef_ModernRoundStats[7], "_");

	/**** Bulletproof Gamemode Textdraws ****/
	TextDrawColor(timerCircleTD, 0x00000033);
	TextDrawSetString(leftTeamData, "_");
	TextDrawSetString(rightTeamData, "_");
	TextDrawSetString(centerTeamNames, "_");
	TextDrawSetString(timerCenterTD, "_");

    /**** Simple Attack-Defend Textdraws ****/
    TextDrawSetString(AttDef_RoundStats, "_");
	TextDrawSetString(AttDef_RoundTimer, "_");
}

ShowEndRoundTextDraw(playerid)
{
	TextDrawShowForPlayer( playerid, leftBG	 	); 		TextDrawShowForPlayer( playerid, rightBG    	);
	TextDrawShowForPlayer( playerid, leftUpBG	); 		TextDrawShowForPlayer( playerid, rightUpBG  	);
	TextDrawShowForPlayer( playerid, leftHeader );		TextDrawShowForPlayer( playerid, rightHeader 	);
	TextDrawShowForPlayer( playerid, leftULine	); 		TextDrawShowForPlayer( playerid, rightULine 	);
	TextDrawShowForPlayer( playerid, leftUpText ); 		TextDrawShowForPlayer( playerid, rightUpText 	);
	TextDrawShowForPlayer( playerid, leftText	); 		TextDrawShowForPlayer( playerid, rightText	 	);
 	TextDrawShowForPlayer( playerid, leftTop	);		//TextDrawShowForPlayer( playerid, rightTop      	);
 	TextDrawShowForPlayer( playerid, lowerBG	);		TextDrawShowForPlayer( playerid, lowerULine 	);
 	TextDrawShowForPlayer( playerid, topTextScore);

 	//contents:
    TextDrawShowForPlayer( playerid, leftNames	); 		TextDrawShowForPlayer( playerid, rightNames 	);
    TextDrawShowForPlayer( playerid, leftKills	); 		TextDrawShowForPlayer( playerid, rightKills 	);
    if(MatchEnded == false){
		TextDrawHideForPlayer( playerid, leftDeaths );      TextDrawHideForPlayer( playerid, rightDeaths    );
		TextDrawShowForPlayer( playerid, leftHP		); 		TextDrawShowForPlayer( playerid, rightHP		);
	} else {
		TextDrawHideForPlayer( playerid, leftHP 	);      TextDrawHideForPlayer( playerid, rightHP    	);
		TextDrawShowForPlayer( playerid, leftDeaths	); 		TextDrawShowForPlayer( playerid, rightDeaths	);
	}
	TextDrawShowForPlayer( playerid, leftDmg	); 		TextDrawShowForPlayer( playerid, rightDmg	 	);
    TextDrawShowForPlayer( playerid, leftAcc	); 		TextDrawShowForPlayer( playerid, rightAcc	 	);

	if( MatchEnded == true )
	{
		TextDrawShowForPlayer( playerid, leftPlayed 	);
		TextDrawShowForPlayer( playerid, rightPlayed	);

		TextDrawHideForPlayer( playerid, teamWonHow	);
	}
	else
	{
		TextDrawShowForPlayer( playerid, teamWonHow	);
	}

	for(new i = 0; i < 3; i++) {
		PlayerTextDrawSetString(playerid, DoingDamage[playerid][i], "_");
		PlayerTextDrawSetString(playerid, GettingDamaged[playerid][i], "_");
	}

	PlayerTextDrawHide(playerid, DeathText[playerid][0]);
	PlayerTextDrawHide(playerid, DeathText[playerid][1]);

	#if defined _league_included
	if(LeagueMode)
	{
		TextDrawShowForPlayer(playerid, LeagueRoundResultTD);
	}
	#endif

	Player[playerid][TextDrawOnScreen] = true;
	return 1;
}

HideEndRoundTextDraw(playerid)
{
	TextDrawHideForPlayer( playerid, leftBG	 	); 		TextDrawHideForPlayer( playerid, rightBG    	);
	TextDrawHideForPlayer( playerid, leftUpBG	); 		TextDrawHideForPlayer( playerid, rightUpBG  	);
	TextDrawHideForPlayer( playerid, leftHeader );		TextDrawHideForPlayer( playerid, rightHeader 	);
	TextDrawHideForPlayer( playerid, leftULine	); 		TextDrawHideForPlayer( playerid, rightULine 	);
	TextDrawHideForPlayer( playerid, leftUpText ); 		TextDrawHideForPlayer( playerid, rightUpText 	);
	TextDrawHideForPlayer( playerid, leftText	); 		TextDrawHideForPlayer( playerid, rightText	 	);
 	TextDrawHideForPlayer( playerid, leftTop	);		//TextDrawHideForPlayer( playerid, rightTop      	);
 	TextDrawHideForPlayer( playerid, lowerBG	);		TextDrawHideForPlayer( playerid, lowerULine 	);
 	TextDrawHideForPlayer( playerid, topTextScore); 	TextDrawHideForPlayer( playerid, teamWonHow 	);
 	//contents:
    TextDrawHideForPlayer( playerid, leftNames	); 		TextDrawHideForPlayer( playerid, rightNames 	);
    TextDrawHideForPlayer( playerid, leftKills	); 		TextDrawHideForPlayer( playerid, rightKills 	);
    TextDrawHideForPlayer( playerid, leftHP	 	); 		TextDrawHideForPlayer( playerid, rightHP	 	);
    TextDrawHideForPlayer( playerid, leftDeaths); 		TextDrawHideForPlayer( playerid, rightDeaths	);
    TextDrawHideForPlayer( playerid, leftDmg	); 		TextDrawHideForPlayer( playerid, rightDmg	 	);
    TextDrawHideForPlayer( playerid, leftAcc	); 		TextDrawHideForPlayer( playerid, rightAcc	 	);
    TextDrawHideForPlayer( playerid, leftPlayed ); 		TextDrawHideForPlayer( playerid, rightPlayed    );

	#if defined _league_included
	TextDrawHideForPlayer(playerid, LeagueRoundResultTD);
	#endif

    Player[playerid][TextDrawOnScreen] = false;
    return 1;
}

ShowMatchScoreBoard(playerid = -1)
{
	switch(playerid)
	{
		case -1:
		{
			/*TextDrawShowForAll(ScoreBoardBoxTD[0]);
			TextDrawShowForAll(ScoreBoardBoxTD[1]);
			TextDrawShowForAll(RoundsPlayed);
			TextDrawShowForAll(TeamScoreText);
			TextDrawShowForAll(TeamAttackerTD);
			TextDrawShowForAll(TeamDefenderTD);
			TextDrawShowForAll(MatchVersusTD);
			TextDrawShowForAll(MatchScoreBoardSprite);*/
			TextDrawShowForAll(TeamScoreText);
			TextDrawShowForAll(RoundsPlayed);
		}
		default:
		{
			/*TextDrawShowForPlayer(playerid, ScoreBoardBoxTD[0]);
			TextDrawShowForPlayer(playerid, ScoreBoardBoxTD[1]);
			TextDrawShowForPlayer(playerid, RoundsPlayed);
			TextDrawShowForPlayer(playerid, TeamScoreText);
			TextDrawShowForPlayer(playerid, TeamAttackerTD);
			TextDrawShowForPlayer(playerid, TeamDefenderTD);
			TextDrawShowForPlayer(playerid, MatchVersusTD);
			TextDrawShowForPlayer(playerid, MatchScoreBoardSprite);*/
			TextDrawShowForPlayer(playerid, TeamScoreText);
			TextDrawShowForPlayer(playerid, RoundsPlayed);
		}
	}
}

HideMatchScoreBoard(playerid = -1)
{
	switch(playerid)
	{
		case -1:
		{
			/*TextDrawHideForAll(ScoreBoardBoxTD[0]);
			TextDrawHideForAll(ScoreBoardBoxTD[1]);
			TextDrawHideForAll(RoundsPlayed);
			TextDrawHideForAll(TeamScoreText);
			TextDrawHideForAll(TeamAttackerTD);
			TextDrawHideForAll(TeamDefenderTD);
			TextDrawHideForAll(MatchVersusTD);
			TextDrawHideForAll(MatchScoreBoardSprite);*/
			TextDrawHideForAll(TeamScoreText);
			TextDrawHideForAll(RoundsPlayed);
		}
		default:
		{
			/*TextDrawHideForPlayer(playerid, ScoreBoardBoxTD[0]);
			TextDrawHideForPlayer(playerid, ScoreBoardBoxTD[1]);
			TextDrawHideForPlayer(playerid, RoundsPlayed);
			TextDrawHideForPlayer(playerid, TeamScoreText);
			TextDrawHideForPlayer(playerid, TeamAttackerTD);
			TextDrawHideForPlayer(playerid, TeamDefenderTD);
			TextDrawHideForPlayer(playerid, MatchVersusTD);
			TextDrawHideForPlayer(playerid, MatchScoreBoardSprite);*/
			TextDrawHideForPlayer(playerid, TeamScoreText);
			TextDrawHideForPlayer(playerid, RoundsPlayed);
		}
	}
}

UpdateTeamScoreTextDraw()
{
	//TextDrawSetString(TeamScoreText, sprintf("%d     %d", TeamScore[ATTACKER], TeamScore[DEFENDER]));
	new iString[64];
	format(iString, sizeof(iString), "~r~%s %s(~r~%d%s) ~b~~h~%s %s(~b~~h~%d%s)", TeamName[ATTACKER], MAIN_TEXT_COLOUR, TeamScore[ATTACKER], MAIN_TEXT_COLOUR, TeamName[DEFENDER], MAIN_TEXT_COLOUR, TeamScore[DEFENDER], MAIN_TEXT_COLOUR);
    TextDrawSetString(TeamScoreText, iString);
	UpdateRoundsPlayedTextDraw();
}

UpdateTeamNameTextDraw()
{
	/*TextDrawSetString(TeamAttackerTD, sprintf("~r~~h~~h~%s", TeamName[ATTACKER]));
	TextDrawSetString(TeamDefenderTD, sprintf("~b~~h~~h~%s", TeamName[DEFENDER]));*/
	new iString[64];
	format(iString, sizeof(iString), "~r~%s %s(~r~%d%s) ~b~~h~%s %s(~b~~h~%d%s)", TeamName[ATTACKER], MAIN_TEXT_COLOUR, TeamScore[ATTACKER], MAIN_TEXT_COLOUR, TeamName[DEFENDER], MAIN_TEXT_COLOUR, TeamScore[DEFENDER], MAIN_TEXT_COLOUR);
    TextDrawSetString(TeamScoreText, iString);
	UpdateRoundsPlayedTextDraw();
}

UpdateRoundsPlayedTextDraw()
{
	//TextDrawSetString(RoundsPlayed, sprintf( "~h~Ro~h~un~h~ds: ~h~%d/%d", CurrentRound, TotalRounds));
	/*
	if(TeamScore[ATTACKER] == TeamScore[DEFENDER])
	{
		TextDrawSetString(RoundsPlayed, sprintf("%sRounds %d/%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds));
	}
	else if(TeamScore[ATTACKER] > TeamScore[DEFENDER])
	{
		TextDrawSetString(RoundsPlayed, sprintf("%sRounds ~r~~h~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds));
	}
	else if(TeamScore[DEFENDER] > TeamScore[ATTACKER])
	{
		TextDrawSetString(RoundsPlayed, sprintf("%sRounds ~b~~h~~h~%d~b~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds));
	}
	*/
	TextDrawSetString(RoundsPlayed, sprintf("%sRounds ~r~~h~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds));
}

InitPlayerInterface(playerid)
{
	for(new i = 0; i < MAX_PLAYER_INTERFACE_ASPECTS; i ++)
		PlayerInterface[playerid][i] = true;
}

// Toggle gamemode HUD
TogglePlayerInterface(playerid, bool:toggle, interface = -1)
{
	switch(interface)
	{
		case -1: // all
		{
			PlayerInterface[playerid][INTERFACE_SPEC] = toggle;
			PlayerInterface[playerid][INTERFACE_NET] = toggle;
			PlayerInterface[playerid][INTERFACE_HP] = toggle;
			switch(toggle)
			{
				case false:
				{
					PlayerTextDrawHide(playerid, WhoSpec[playerid]);
					PlayerTextDrawHide(playerid, FPSPingPacket[playerid]);
					PlayerTextDrawHide(playerid, HPTextDraw_TD[playerid]);
					PlayerTextDrawHide(playerid, ArmourTextDraw[playerid]);
				}
				case true:
				{
					PlayerTextDrawShow(playerid, WhoSpec[playerid]);
					PlayerTextDrawShow(playerid, FPSPingPacket[playerid]);
					PlayerTextDrawShow(playerid, HPTextDraw_TD[playerid]);
					PlayerTextDrawShow(playerid, ArmourTextDraw[playerid]);
				}
			}
			new str[70];
			format(str, sizeof(str), "UPDATE Players SET InterfaceSpec = %d WHERE Name = '%q'", (PlayerInterface[playerid][INTERFACE_SPEC] == true ? 1 : 0), Player[playerid][Name]);
			db_free_result(db_query(sqliteconnection, str));
			format(str, sizeof(str), "UPDATE Players SET InterfaceNet = %d WHERE Name = '%q'", (PlayerInterface[playerid][INTERFACE_NET] == true ? 1 : 0), Player[playerid][Name]);
			db_free_result(db_query(sqliteconnection, str));
			format(str, sizeof(str), "UPDATE Players SET InterfaceHP = %d WHERE Name = '%q'", (PlayerInterface[playerid][INTERFACE_HP] == true ? 1 : 0), Player[playerid][Name]);
			db_free_result(db_query(sqliteconnection, str));
		}
		case INTERFACE_SPEC:
		{
			PlayerInterface[playerid][INTERFACE_SPEC] = toggle;
			switch(toggle)
			{
				case false:
				{
					PlayerTextDrawHide(playerid, WhoSpec[playerid]);
				}
				case true:
				{
					PlayerTextDrawShow(playerid, WhoSpec[playerid]);
				}
			}
			new str[70];
			format(str, sizeof(str), "UPDATE Players SET InterfaceSpec = %d WHERE Name = '%q'", (PlayerInterface[playerid][INTERFACE_SPEC] == true ? 1 : 0), Player[playerid][Name]);
			db_free_result(db_query(sqliteconnection, str));
		}
		case INTERFACE_NET:
		{
			PlayerInterface[playerid][INTERFACE_NET] = toggle;
			switch(toggle)
			{
				case false:
				{
					PlayerTextDrawHide(playerid, FPSPingPacket[playerid]);
				}
				case true:
				{
					PlayerTextDrawShow(playerid, FPSPingPacket[playerid]);
				}
			}
			new str[70];
			format(str, sizeof(str), "UPDATE Players SET InterfaceNet = %d WHERE Name = '%q'", (PlayerInterface[playerid][INTERFACE_NET] == true ? 1 : 0), Player[playerid][Name]);
			db_free_result(db_query(sqliteconnection, str));
		}
		case INTERFACE_HP:
		{
			PlayerInterface[playerid][INTERFACE_HP] = toggle;
			switch(toggle)
			{
				case false:
				{
					PlayerTextDrawHide(playerid, HPTextDraw_TD[playerid]);
					PlayerTextDrawHide(playerid, ArmourTextDraw[playerid]);
				}
				case true:
				{
					PlayerTextDrawShow(playerid, HPTextDraw_TD[playerid]);
					PlayerTextDrawShow(playerid, ArmourTextDraw[playerid]);
				}
			}
			new str[70];
			format(str, sizeof(str), "UPDATE Players SET InterfaceHP = %d WHERE Name = '%q'", (PlayerInterface[playerid][INTERFACE_HP] == true ? 1 : 0), Player[playerid][Name]);
			db_free_result(db_query(sqliteconnection, str));
		}
	}
}
