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

new Handle:RandomItemMenu = INVALID_HANDLE;

static const String:g_szKillEntities[][] =
{
	"dod_scoring",
	"trigger_hurt",
	"func_team_wall",
	"dod_round_timer",
	"dod_bomb_target",
	"dod_capture_area",
	"func_teamblocker"
};

LoadEvents()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team",  Event_PlayerTeam, EventHookMode_Pre);

	HookEvent("dod_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("dod_round_active", Event_RoundActive, EventHookMode_PostNoCopy);
}

public Action:Event_PlayerTeam(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (g_bModRunning)
	{
		new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

		switch (GetEventInt(hEvent, "team"))
		{
			case Team_Hiders:
			{
				PrintToChatAll("*%N joined the Hiders", iClient);

				return Plugin_Handled;
			}

			case Team_Seekers:
			{
				if (g_bHideTime && !g_bPlayerBlinded[iClient])
				{
					BlindPlayer(iClient, true);
				}

				PrintToChatAll("*%N joined the Seekers", iClient);

				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (GetConVarInt(g_ConVar[Enabled]))
	{
		if (!g_bModRunning)
		{
			if (GetTeamClientCount(Team_Hiders) + GetTeamClientCount(Team_Seekers) >= GetConVarInt(g_ConVar[MinPlayers]))
			{
				g_bModRunning = true;

				PrintToChatAll("%s Game commencing in 15 seconds!", HIDENSEEK_PREFIX);
				CreateTimer(15.0, Timer_RestartRound, _, TIMER_FLAG_NO_MAPCHANGE);

				SetRoundState(DoDRoundState_Restart);
			}
		}
		else
		{
			new iUserID = GetEventInt(hEvent, "userid");
			new iClient = GetClientOfUserId(iUserID);

			switch (GetClientTeam(iClient))
			{
				case Team_Hiders:
				{
					ThirdPerson(iClient);
					RemoveWeapons(iClient);

					new iRandomModel = GetRandomInt(1, g_iNumModels) - 1;

					SetEntData(iClient, g_iOffset_ModelIndex, g_iModelIndex[iRandomModel]);
					SetEntityRenderColor(iClient, 255, 255, 255, 255);

					PrintToChat(iClient, "%s You are now disguised as a \x05%s\x01", HIDENSEEK_PREFIX, g_szModelPrintName[iRandomModel]);

					new iWeapon = GivePlayerItem(iClient, "weapon_amerknife");
					SetEntData(iWeapon, g_iOffset_Effects, EF_NODRAW);

					if (g_bRoundActive) CreateTimer(15.0, Timer_ShowModelsMenu, iUserID, TIMER_FLAG_NO_MAPCHANGE);
				}

				case Team_Seekers:
				{
					RemoveWeapons(iClient);
					GivePlayerItem(iClient, "weapon_spade");
				}
			}

			FixViewOffset(iClient);
		}
	}
}

public Event_PlayerDeath(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (g_bRoundActive)
	{
		//new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
		new iUserID = GetEventInt(hEvent, "userid");
		new iClient = GetClientOfUserId(iUserID);

		/* if (GetClientTeam(iAttacker) == Team_Seekers)
		{
			new AttackerWeapon = GetPlayerWeaponSlot(iAttacker, 1);
			if (IsValidEntity(AttackerWeapon))
			{
				AcceptEntityInput(AttackerWeapon, "Kill");
			}

			GivePlayerItem(iAttacker, "weapon_p38");
		} */

		if (iClient > 0 && GetClientTeam(iClient) == Team_Hiders)
		{
			new iRagdoll = GetEntDataEnt2(iClient, g_iOffset_Ragdoll);

			if (iRagdoll != -1)
			{
				AcceptEntityInput(iRagdoll, "Kill");
			}

			CreateTimer(0.1, Timer_SwitchToSeekerTeam, iUserID, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_SwitchToSeekerTeam(Handle:hEvent, any:iClient)
{
	if ((iClient = GetClientOfUserId(iClient)) != 0)
	{
		ChangeClientTeam(iClient, Team_Seekers);
	}

	CheckWin();
}

public Action:Timer_ShowModelsMenu(Handle:hEvent, any:iClient)
{
	if ((iClient = GetClientOfUserId(iClient)) != 0 && GetClientTeam(iClient) == Team_Hiders)
	{
		RandomItemMenu = CreateMenu(MenuHandler, MenuAction_DrawItem|MenuAction_Select);
		SetMenuTitle(RandomItemMenu, "Do you want to change your model?");
		AddMenuItem(RandomItemMenu, "Yes", "Yes, Change my model to random");
		AddMenuItem(RandomItemMenu, "No", "No, I want to keep current model");
		AddMenuItem(RandomItemMenu, "Change", "No, I want to change my model from menu");
		DisplayMenu(RandomItemMenu, iClient, 20);
	}
}

public MenuHandler(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_DrawItem)
	{
		return (param == 2 && !GetConVarBool(g_ConVar[MenuSelection])) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
	}
	else if (action == MenuAction_Select)
	{
		if (param == 0)
		{
			new iRandomModel = GetRandomInt(1, g_iNumModels) - 1;

			SetEntData(client, g_iOffset_ModelIndex, g_iModelIndex[iRandomModel]);
			SetEntityRenderColor(client, 255, 255, 255, 255);
		}
		else if (param == 2)
		{
			if (g_hModelMenu != INVALID_HANDLE)
				DisplayMenu(g_hModelMenu, client, MENU_TIME_FOREVER);
		}
	}

	return 0;
}

public MenuHandler_ChooseModel(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		if (g_bHideTime)
		{
			decl String:number[4];
			GetMenuItem(menu, param, number, sizeof(number));
			SetEntData(client, g_iOffset_ModelIndex, g_iModelIndex[StringToInt(number)]);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			PrintToChat(client, "%s You are now disguised as a \x05%s\x01", HIDENSEEK_PREFIX, g_szModelPrintName[StringToInt(number)]);
		}
		else PrintToChat(client, "%s You can not change your model when hide time is out!", HIDENSEEK_PREFIX);
	}
}


FlashTimer(iTimeRemaining)
{
	new Handle:hEvent = CreateEvent("dod_timer_flash");

	if (hEvent != INVALID_HANDLE)
	{
		SetEventInt(hEvent, "time_remaining", iTimeRemaining);

		FireEvent(hEvent);
	}
}

public Event_RoundStart(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (g_bModRunning && g_bRoundActive)
	{
		SetNumControlPoints(0);

		new iEntity = -1;

		for (new i = 0; i < sizeof(g_szKillEntities); i++)
		{
			while ((iEntity = FindEntityByClassname(iEntity, g_szKillEntities[i])) != -1)
			{
				AcceptEntityInput(iEntity, "Kill");
			}
		}

		if ((iEntity = FindEntityByClassname(iEntity, "dod_bomb_dispenser")) != -1)
		{
			AcceptEntityInput(iEntity, "Disable");
		}

		CreateTimer(0.1, Timer_CreateRoundTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_CreateRoundTimer(Handle:hTimer)
{
	if ((g_iRoundTimer = CreateEntityByName("dod_round_timer")) != -1)
	{
		SetTimeRemaining(g_iRoundTimer, GetConVarInt(g_ConVar[HideTime]));
		PauseTimer(g_iRoundTimer);
	}
	else
	{
		LogError("Error: Unable to create entity: \"dod_round_timer\"!");
	}
}

public Event_RoundActive(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (g_bModRunning && g_bRoundActive && g_iRoundTimer != -1)
	{
		ResumeTimer(g_iRoundTimer);

		g_hRoundTimer = CreateTimer(1.0, RoundTimer_Think, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}