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

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dodhooks>

#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>

#define PL_VERSION "0.6.5"

#include "hns/offsets.sp"
#include "hns/hidenseek.sp"
#include "hns/convars.sp"
#include "hns/config.sp"
#include "hns/hooks.sp"
#include "hns/commands.sp"
#include "hns/events.sp"

public Plugin:myinfo =
{
	name = "DoD:S Hide & Seek",
	author = "Andersso, Dave223 & Root",
	description = "Hide & Seek for DoD:S",
	version = PL_VERSION,
	url = "http://www.dodsplugins.com/"
};

public OnPluginStart()
{
	AutoExecConfig(true, "hidenseek_config", "hidenseek");

	LoadHooks();
	LoadEvents();
	LoadOffsets();
	LoadConVars();
	LoadCommands();

	CreateInfoPanel();
}

public OnMapStart()
{
	#if defined _steamtools_included
	if (LibraryExists("SteamTools"))
	{
		Steam_SetGameDescription("DoD:S Hide and Seek");
	}
	#endif

	g_iLastMan = 0;
	g_iNumModels = 0;
	g_iRoundWins = 0;

	g_bHideTime = false;
	g_bModRunning = false;
	g_bRoundActive = false;

	g_hRoundTimer = INVALID_HANDLE;

	PrecacheSound("buttons/blip1.wav", true);

	g_iBeamSprite = PrecacheModel("materials/sprites/laser.vmt", true);
	g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt", true);

	LoadConfig();
	LoadModelsConfig();
}

public OnMapEnd()
{
	g_bModRunning = false;
	g_bRoundActive = false;
}

public OnClientPutInServer(iClient)
{
	if (GetConVarBool(g_ConVar[InfoPanel]))
	{
		g_hInfoPanelTimer[iClient] = CreateTimer(15.0, Timer_SendInfoPanel, iClient, TIMER_FLAG_NO_MAPCHANGE);
	}

	g_bPlayerBlinded[iClient] = false;
}

public OnClientDisconnect(iClient)
{
	if (g_hInfoPanelTimer[iClient] != INVALID_HANDLE)
	{
		KillTimer(g_hInfoPanelTimer[iClient]);
	}

	if (g_bModRunning && g_bRoundActive)
	{
		if (GetTeamClientCount(Team_Seekers) == 0)
		{
			if (GetTeamClientCount(Team_Hiders) >= GetConVarInt(g_ConVar[MinPlayers]))
			{
				SelectSeeker();

				SetPlayerState(g_iSeeker, PlayerState_ObserverMode);
				ChangeClientTeam(g_iSeeker, Team_Seekers);

				PrintHintText(g_iSeeker, "You're now the seeker!");
				PrintToChatAll("%s Player %N is now the seeker.", HIDENSEEK_PREFIX, g_iSeeker);
			}
			else
			{
				RestartRound();
			}
		}
		else
		{
			CheckWin();
		}
	}
}

public Action:RoundTimer_Think(Handle:hTimer)
{
	if (!g_bModRunning || !g_bRoundActive)
	{
		g_hRoundTimer = INVALID_HANDLE;

		return Plugin_Stop;
	}

	new iTimeRemaining = RoundFloat(GetTimeRemaining(g_iRoundTimer)) - 1;

	if (GetConVarBool(g_ConVar[RoundTimerBeacon]))
	{
		if (iTimeRemaining < 120 && iTimeRemaining >= (120 - GetConVarInt(g_ConVar[BeaconTwoMinLeft])))
		{
			PerformBeaconAll();

			return Plugin_Continue;
		}

		if (iTimeRemaining < 60 && iTimeRemaining >= (60 - GetConVarInt(g_ConVar[BeaconOneMinLeft])))
		{
			PerformBeaconAll();

			return Plugin_Continue;
		}
	}

	if (GetConVarBool(g_ConVar[BeaconLastMan]) && ++g_iBeaconTicks >= GetConVarInt(g_ConVar[BeaconLastManInterval]))
	{
		g_iBeaconTicks = 0;

		new iLastMan = GetClientOfUserId(g_iLastMan);

		if (iLastMan != 0)
		{
			PerformBeacon(iLastMan);
		}
	}

	switch (iTimeRemaining)
	{
		case 0:
		{
			if (g_bHideTime)
			{
				SetTimeRemaining(g_iRoundTimer, GetConVarInt(g_ConVar[RoundTime]));

				PrintCenterTextAll(NULL_STRING);
				EmitSoundToAll(g_szGameSound_Start);

				g_bHideTime = false;

				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i))
					{
						if (g_bPlayerBlinded[i])
						{
							BlindPlayer(i, false);
						}

						if (GetClientTeam(i) == Team_Seekers && GetPlayerClass(i) != Class_None)
						{
							RespawnPlayer(i, false);
						}
					}
				}
			}
			else
			{
				if (++g_iRoundWins >= GetConVarInt(g_ConVar[WinLimit]))
				{
					CreateTimer(10.0, Timer_EndGame, _, TIMER_FLAG_NO_MAPCHANGE);
				}
				else
				{
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i))
						{
							EmitSoundToClient(i, g_szGameSound_Win);
							ScreenOverlay(i, g_szOverlay_HidersWin);
						}
					}

					RestartRound();

					g_hRoundTimer = INVALID_HANDLE;
				}

				return Plugin_Stop;
			}
		}

		case 60,120:
		{
			FlashTimer(iTimeRemaining);
		}

		default:
		{
			if (g_bHideTime)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i))
					{
						switch (GetClientTeam(i))
						{
							case Team_Hiders:  PrintCenterText(i, "The seeker will spawn in %i seconds", iTimeRemaining);
							case Team_Seekers: PrintCenterText(i, "You will spawn in %i seconds", iTimeRemaining);
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:OnPlayerRespawn(iClient)
{
	if (g_bModRunning && g_bRoundActive && g_bHideTime && GetClientTeam(iClient) == Team_Seekers)
	{
		if (IsPlayerAlive(iClient))
		{
			SetPlayerState(g_iSeeker, PlayerState_ObserverMode);
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

SelectSeeker()
{
	new iClients[MaxClients], iNumClients = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (i != g_iSeeker && IsClientInGame(i) && GetClientTeam(i) > Team_Spectators)
		{
			iClients[iNumClients++] = i;
		}
	}

	if (iNumClients >= 1)
	{
		g_iSeeker = iClients[GetRandomInt(1, iNumClients) - 1];
	}
	else
	{
		LogError("Error: Unable	to select seeker!");
	}
}

CheckWin()
{
	if (g_bModRunning && g_bRoundActive)
	{
		switch (GetTeamClientCount(Team_Hiders))
		{
			case 0:
			{
				PauseTimer(g_iRoundTimer);

				if (++g_iRoundWins >= GetConVarInt(g_ConVar[WinLimit]))
				{
					CreateTimer(10.0, Timer_EndGame, _, TIMER_FLAG_NO_MAPCHANGE);
				}
				else
				{
					new iTimePassed = GetConVarInt(g_ConVar[RoundTime]) - RoundFloat(GetTimeRemaining(g_iRoundTimer));

					new iTimeMin = iTimePassed / 60;
					new iTimeSec = iTimePassed % 60;

					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i))
						{
							PrintToChat(i, "%s The Seekers won the round after: %i Minutes %i Seconds.", HIDENSEEK_PREFIX, iTimeMin, iTimeSec);
							EmitSoundToClient(i, g_szGameSound_Win);

							ScreenOverlay(i, g_szOverlay_SeekersWin);
						}
					}

					RestartRound();
				}
			}

			case 1:
			{
				if (g_iLastMan == 0)
				{
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i))
						{
							PrintToChat(i, "%s The seekers have beaconed the last man standing!", HIDENSEEK_PREFIX);

							if (GetClientTeam(i) == Team_Hiders)
							{
								g_iLastMan = GetClientUserId(i);

								break;
							}
						}
					}
				}
			}
		}
	}
}

RestartRound()
{
	g_iLastMan = 0;
	g_iBeaconTicks = 0;
	g_bRoundActive = false;

	if (g_hRoundTimer != INVALID_HANDLE)
	{
		KillTimer(g_hRoundTimer);
		g_hRoundTimer = INVALID_HANDLE;
	}

	CreateTimer(10.0, Timer_RestartRound, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_RestartRound(Handle:hTimer)
{
	if (GetTeamClientCount(Team_Hiders) + GetTeamClientCount(Team_Seekers) >= GetConVarInt(g_ConVar[MinPlayers]))
	{
		SelectSeeker();
		BlindPlayer(g_iSeeker, true);

		g_bHideTime = true;
		g_bRoundActive = true;

		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				RemoveScreenOverlay(i);

				if (i != g_iSeeker && GetClientTeam(i) > Team_Spectators)
				{
					SetPlayerState(i, PlayerState_ObserverMode);
					ChangeClientTeam(i, Team_Hiders);
				}
			}
		}

		if (GetClientTeam(g_iSeeker) != Team_Seekers)
		{
			SetPlayerState(g_iSeeker, PlayerState_ObserverMode);
			ChangeClientTeam(g_iSeeker, Team_Seekers);
		}
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				RemoveScreenOverlay(i);
			}
		}

		g_bModRunning = false;
	}

	SetRoundState(DoDRoundState_Restart);
}

public Action:Timer_EndGame(Handle:hTimer)
{
	g_bRoundActive = false;

	new iGameEnd = CreateEntityByName("game_end");

	if (iGameEnd != -1)
	{
		AcceptEntityInput(iGameEnd, "EndGame");
	}
	else
	{
		LogError("Unable to create entity: \"game_end\"!");
	}
}

public Action:Timer_SendInfoPanel(Handle:hTimer, any:iClient)
{
	g_hInfoPanelTimer[iClient] = INVALID_HANDLE;

	SendPanelToClient(g_hInfoPanel, iClient, Handler_Dummy, 10);
}

CreateInfoPanel()
{
	g_hInfoPanel = CreatePanel();

	SetPanelTitle(g_hInfoPanel, "Hide & Seek\n \n");
	DrawPanelText(g_hInfoPanel, "On round start, one player is chosen to be the seeker and");
	DrawPanelText(g_hInfoPanel, "the remaining players become hiders. The hiders disguise");
	DrawPanelText(g_hInfoPanel, "themselves using a wealth of frankly daft objects.\n \n");
	DrawPanelText(g_hInfoPanel, "Commands (Hiders):\n \n");
	DrawPanelText(g_hInfoPanel, "!1st - Switch to firstperson view");
	DrawPanelText(g_hInfoPanel, "!3rd - Switch to thirdperson view\n \n");
	DrawPanelItem(g_hInfoPanel, "Close");
}

public Handler_Dummy(Handle:hPanel, MenuAction:MenAction, iParam1, iParam2)
{
	return;
}
