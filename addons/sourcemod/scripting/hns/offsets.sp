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

new g_iOffset_FOV;
new g_iOffset_Ragdoll;
new g_iOffset_Effects;
new g_iOffset_ModelIndex;
new g_iOffset_ViewOffset;
//new g_iOffset_PlayerClass;
new g_iOffset_ObserverMode;
new g_iOffset_DrawViewModel;
new g_iOffset_ObserverTarget;

enum
{
	Class_None = -1,
	Class_Rifleman,
	Class_Assault,
	Class_Support,
	Class_Sniper,
	Class_Machinegunner,
	Class_Rocket
}

LoadOffsets()
{
	if ((g_iOffset_FOV = FindSendPropInfo("CBasePlayer", "m_iFOV")) == -1)
	{
		SetFailState("Fatal Error: Unable to find offset: \"m_iFOV\"!");
	}

	if ((g_iOffset_Ragdoll = FindSendPropOffs("CDODPlayer", "m_hRagdoll")) == -1)
	{
		SetFailState("Fatal Error: Unable to find offset: \"m_hRagdoll\"!");
	}

	if ((g_iOffset_Effects = FindSendPropOffs("CBaseEntity", "m_fEffects")) == -1)
	{
		SetFailState("Fatal Error: Unable to find offset: \"m_fEffects\"!");
	}

	if ((g_iOffset_ModelIndex = FindSendPropOffs("CBaseEntity", "m_nModelIndex")) == -1)
	{
		SetFailState("Fatal Error: Unable to find offset: \"m_nModelIndex\"!");
	}

	if ((g_iOffset_ViewOffset = FindSendPropOffs("CBasePlayer", "m_vecViewOffset[2]")) == -1)
	{
		SetFailState("Fatal Error: Unable to find offset: \"m_vecViewOffset[2]\"!");
	}

	/* if ((g_iOffset_PlayerClass = FindSendPropOffs("CDODPlayer", "m_iPlayerClass")) == -1)
	{
		SetFailState("Fatal Error: Unable to find offset: \"m_iPlayerClass\"!");
	} */

	if ((g_iOffset_ObserverMode = FindSendPropOffs("CBasePlayer", "m_iObserverMode")) == -1)
	{
		SetFailState("Fatal Error: Unable to find offset: \"m_iObserverMode\"!");
	}

	if ((g_iOffset_DrawViewModel = FindSendPropInfo("CBasePlayer", "m_bDrawViewmodel")) == -1)
	{
		SetFailState("Fatal Error: Unable to find offset: \"m_bDrawViewmodel\"!");
	}

	if ((g_iOffset_ObserverTarget = FindSendPropOffs("CBasePlayer", "m_hObserverTarget")) == -1)
	{
		SetFailState("Fatal Error: Unable to find offset: \"m_hObserverTarget\"!");
	}
}

FixViewOffset(iClient)
{
	SetEntData(iClient,	g_iOffset_ViewOffset, 56.0);
}

/* GetPlayerClass(iClient)
{
	return GetEntData(iClient, g_iOffset_PlayerClass);
} */

FirstPerson(iClient)
{
	SetEntData(iClient,	g_iOffset_FOV, 90);
	SetEntData(iClient, g_iOffset_ObserverMode, false);
	SetEntData(iClient, g_iOffset_DrawViewModel, false);
}

ThirdPerson(iClient)
{

	SetEntData(iClient,	g_iOffset_FOV, 115);
	SetEntData(iClient, g_iOffset_ObserverMode, true);
	SetEntData(iClient, g_iOffset_DrawViewModel, false);

	SetEntDataEnt2(iClient,  g_iOffset_ObserverTarget, iClient);
}