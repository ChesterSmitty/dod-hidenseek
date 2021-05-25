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

LoadCommands()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("timeleft", Command_TimeLeft);
	RegConsoleCmd("jointeam", Command_JoinTeam);
	RegConsoleCmd("sm_1st", Command_FirstPerson);
	RegConsoleCmd("sm_3rd", Command_ThirdPerson);

	RegConsoleCmd("joinclass",   Command_JoinClass);
	RegConsoleCmd("cls_garand",  Command_JoinClass);
	RegConsoleCmd("cls_tommy",   Command_JoinClass);
	RegConsoleCmd("cls_bar",     Command_JoinClass);
	RegConsoleCmd("cls_spring",  Command_JoinClass);
	RegConsoleCmd("cls_30cal",   Command_JoinClass);
	RegConsoleCmd("cls_bazooka", Command_JoinClass);
	RegConsoleCmd("cls_random",  Command_JoinClass);
}

public Action:Command_Say(iClient, iArgs)
{
	if (iArgs >= 1)
	{
		decl String:szText[64];
		GetCmdArg(1, szText, sizeof(szText));

		if (StrEqual(szText, "timeleft"))
		{
			ShowTimeleft();
		}
	}
}

public Action:Command_TimeLeft(iClient, iArgs)
{
	ShowTimeleft();

	return Plugin_Handled;
}

ShowTimeleft()
{
	PrintToChatAll("Rounds Won: %i, map changes after %i", g_iRoundWins, GetConVarInt(g_ConVar[WinLimit]));
}

public Action:Command_JoinTeam(iClient, iArgs)
{
	if (iClient && g_bModRunning && iArgs >= 1)
	{
		decl String:szArg[8];
		GetCmdArg(1, szArg, sizeof(szArg));

		switch (StringToInt(szArg))
		{
			case Team_Random:
			{
				PrintCenterText(iClient, "You cannot Auto-Assign");

				ClientCommand(iClient, "changeteam");

				return Plugin_Handled;
			}

			case Team_Hiders:
			{
				switch (GetClientTeam(iClient))
				{
					case Team_Unssigned:
					{
						ChangeClientTeam(iClient, Team_Seekers);

						return Plugin_Handled;
					}

					case Team_Spectators,Team_Seekers:
					{
						PrintCenterText(iClient, "You cannot join Hiders at this time");

						ClientCommand(iClient, "changeteam");

						return Plugin_Handled;
					}
				}
			}

			case Team_Seekers:
			{
				ChangeClientTeam(iClient, Team_Seekers);

				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Command_JoinClass(iClient, iArgs)
{
	return iClient && g_bModRunning && GetClientTeam(iClient) == Team_Hiders && GetPlayerClass(iClient) != Class_None ? Plugin_Handled : Plugin_Continue;
}

public Action:Command_FirstPerson(iClient, iArgs)
{
	if (iClient && g_bRoundActive && GetClientTeam(iClient) == Team_Hiders && IsPlayerAlive(iClient))
	{
		FirstPerson(iClient);
	}
}

public Action:Command_ThirdPerson(iClient, iArgs)
{
	if (iClient && g_bRoundActive && GetClientTeam(iClient) == Team_Hiders && IsPlayerAlive(iClient))
	{
		ThirdPerson(iClient);
	}
}