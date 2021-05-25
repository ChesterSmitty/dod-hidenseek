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

#define MAX_MODELS 100
#define EF_NODRAW  0x020
#define DOD_MAXPLAYERS 33
#define BEACON_COLOR { 255, 75, 75, 255 }
#define HIDENSEEK_PREFIX "\x05Hide & Seek:\x01"

enum
{
	Team_Random		= 0,
	Team_Unssigned	= 0,
	Team_Spectators	= 1,
	Team_Hiders		= 2,
	Team_Seekers	= 3
}

new bool:g_bHideTime;
new bool:g_bModRunning;
new bool:g_bRoundActive;
new bool:g_bPlayerBlinded[DOD_MAXPLAYERS + 1];
new g_iSeeker;
new g_iLastMan;
new g_iRoundWins;
new g_iRoundTimer;
new g_iBeamSprite;
new g_iHaloSprite;
new g_iBeaconTicks;
new g_iModelIndex[MAX_MODELS];

new Handle:g_hInfoPanel;
new Handle:g_hModelMenu;
new Handle:g_hRoundTimer;
new Handle:g_hInfoPanelTimer[DOD_MAXPLAYERS] = {INVALID_HANDLE, ...};

BlindPlayer(iClient, bool:bBlind)
{
	g_bPlayerBlinded[iClient] = bBlind;

	new Handle:hMsg = StartMessageOne("Fade", iClient);

	BfWriteShort(hMsg, -1);
	BfWriteShort(hMsg, -1);

	BfWriteShort(hMsg, bBlind ? 0x0008 : 0x0010);

	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, bBlind ? 255 : 0);

	EndMessage();
}

PerformBeacon(iClient)
{
	decl Float:vecPosition[3];

	GetClientAbsOrigin(iClient, vecPosition);
	vecPosition[2] += 10;

	TE_SetupBeamRingPoint(vecPosition, 10.0, 375.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.6, 10.0, 0.5, BEACON_COLOR, 10, 0);
	TE_SendToAll();

	GetClientEyePosition(iClient, vecPosition);
	EmitAmbientSound("buttons/blip1.wav", vecPosition, iClient, SNDLEVEL_RAIDSIREN);
}

PerformBeaconAll()
{
	decl Float:vecPosition[3];

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == Team_Hiders)
		{
			GetClientAbsOrigin(i, vecPosition);
			vecPosition[2] += 10;

			TE_SetupBeamRingPoint(vecPosition, 10.0, 375.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.6, 10.0, 0.5, BEACON_COLOR, 10, 0);
			TE_SendToAll();

			GetClientEyePosition(i, vecPosition);
			EmitAmbientSound("buttons/blip1.wav", vecPosition, i, SNDLEVEL_RAIDSIREN);
		}
	}
}

ScreenOverlay(iClient, const String:szMaterial[])
{
	ClientCommand(iClient, "r_screenoverlay %s", szMaterial);
}

RemoveScreenOverlay(iClient)
{
	ClientCommand(iClient, "r_screenoverlay 0");
}

RemoveWeapons(iClient)
{
	for (new i = 0, iWeapon; i < 5; i++)
	{
		if ((iWeapon = GetPlayerWeaponSlot(iClient, i)) != -1)
		{
			RemovePlayerItem(iClient, iWeapon);
			RemoveEdict(iWeapon);
		}
	}
}