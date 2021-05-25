/*	=============================================================================
*
*	Hide and Seek for Day of Defeat: Source
*
*	=============================================================================
*
*	This program is free software; you can redistribute it and/or modify it under
*	the terms of the GNU General Public License, version 3.0, as published by the
*	Free Software Foundation.
*
*	This program is distributed in the hope that it will be useful, but WITHOUT
*	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
*	FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
*	details.
*
*	You should have received a copy of the GNU General Public License along with
*	this program. If not, see <http://www.gnu.org/licenses/>
*
* =============================================================================
*/

enum ConVars
{
	Handle:Enabled,
	Handle:WinLimit,
	Handle:HideTime,
	Handle:InfoPanel,
	Handle:MenuSelection,
	Handle:RoundTime,
	Handle:MinPlayers,
	Handle:BeaconLastMan,
	Handle:RoundTimerBeacon,
	Handle:BeaconOneMinLeft,
	Handle:BeaconTwoMinLeft,
	Handle:BeaconLastManInterval
}

new g_ConVar[ConVars];

LoadConVars()
{
	CreateConVar("sm_hidenseek_version", PL_VERSION, "Hide & Seek Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);

	g_ConVar[Enabled] 	            = CreateConVar("sm_hidenseek_enabled",                 "1",   "Enable/Disable Hide & Seek.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_ConVar[WinLimit]	            = CreateConVar("sm_hidenseek_winlimit",                "4",   "Maximum amount of rounds until mapchange.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_ConVar[HideTime]	            = CreateConVar("sm_hidenseek_hidetime",                "90",  "How long time hiders have to hide at roundstart. (In seconds)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_ConVar[InfoPanel]             = CreateConVar("sm_hidenseek_infopanel",               "1",   "Show the info panel to clients when they connect.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_ConVar[MenuSelection]         = CreateConVar("sm_hidenseek_menuselection",           "1",   "Whether or not allow players to select model from menu once.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_ConVar[RoundTime]             = CreateConVar("sm_hidenseek_roundtime",               "360", "How long time each round takes. (In seconds)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 120.0);
	g_ConVar[MinPlayers]            = CreateConVar("sm_hidenseek_minplayers",              "6",   "Minumum amount of people to start Hide & Seek", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 3.0);
	g_ConVar[BeaconLastMan]         = CreateConVar("sm_hidenseek_beacon_lastman",          "1",   "Enable/Disable last man beacon.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_ConVar[RoundTimerBeacon]      = CreateConVar("sm_hidenseek_beacon_roundtimer",       "1",   "Enable/Disable roundtimer beacon.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_ConVar[BeaconOneMinLeft]      = CreateConVar("sm_hidenseek_beacon_oneminleft",       "1",   "Amount of beacons when it's one minute left.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_ConVar[BeaconTwoMinLeft]      = CreateConVar("sm_hidenseek_beacon_twominleft",       "2",   "Amount of beacons when it's two minutes left.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_ConVar[BeaconLastManInterval] = CreateConVar("sm_hidenseek_beacon_lastman_interval", "30",  "Delay between the beacons when it's last man.", FCVAR_PLUGIN|FCVAR_NOTIFY);

	HookConVarChange(g_ConVar[Enabled], ConVarChange_Enabled);
}

public ConVarChange_Enabled(Handle:hConVar, const String:szOldValue[], const String:szNewValue[])
{
	if (StrEqual(szNewValue, "0"))
	{
		g_bModRunning = false;

		SetRoundState(DoDRoundState_Restart);
	}
}