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

LoadHooks()
{
	HookUserMessage(GetUserMessageId("TextMsg"), OnTextMsg, true);
	HookUserMessage(GetUserMessageId("VGUIMenu"), OnVGUIMenu, true);
}

public Action:OnTextMsg(UserMsg:MsgId, Handle:hBf, const iClients[], iNumClients, bool:bReliable, bool:bInit)
{
	if (g_bModRunning && iNumClients == 1 && GetClientTeam(iClients[0]) == Team_Seekers)
	{
		BfReadByte(hBf);

		decl String:szMessage[32];
		BfReadString(hBf, szMessage, sizeof(szMessage));

		if (StrEqual(szMessage, "#game_spawn_as") || StrEqual(szMessage, "#game_respawn_as"))
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:OnVGUIMenu(UserMsg:MsgId, Handle:hBf, const iClients[], iNumClients, bool:bReliable, bool:bInit)
{
	if (g_bRoundActive && iNumClients == 1)
	{
		decl String:szMenuName[32];
		BfReadString(hBf, szMenuName, sizeof(szMenuName));

		if (StrEqual(szMenuName, "class_us") || StrEqual(szMenuName, "class_ger"))
		{
			if (GetPlayerClass(iClients[0]) != Class_None)
			{
				CreateTimer(0.1, Timer_SetPlayerClass, GetClientUserId(iClients[0]), TIMER_FLAG_NO_MAPCHANGE);
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:Timer_SetPlayerClass(Handle:hTimer, any:iClient)
{
	if ((iClient = GetClientOfUserId(iClient)) != 0)
	{
		FakeClientCommand(iClient, "cls_random");
	}
}