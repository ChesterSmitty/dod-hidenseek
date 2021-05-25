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

#define EXTENSION_MDL 0
#define MAX_MATERIALS 10

new String:g_szOverlay_HidersWin[PLATFORM_MAX_PATH];
new String:g_szOverlay_SeekersWin[PLATFORM_MAX_PATH];

new String:g_szGameSound_Win[PLATFORM_MAX_PATH];
new String:g_szGameSound_End[PLATFORM_MAX_PATH];
new String:g_szGameSound_Start[PLATFORM_MAX_PATH];

new g_iNumModels;

new String:g_szModelPrintName[MAX_MODELS][PLATFORM_MAX_PATH];
new String:g_szModelFileName[MAX_MODELS][PLATFORM_MAX_PATH];

static const String:g_szMaterialExtensions[][] = { "vmt", "vtf" };

static const String:g_szModelExtensions[][] =
{
	"mdl",
	"dx80.vtx",
	"dx90.vtx",
	"phy",
	"sw.vtx",
	"vvd"
};

LoadSound(const String:szFile[])
{
	if (szFile[0] != '\0')
	{
		PrecacheSound(szFile, true);

		decl String:szPath[PLATFORM_MAX_PATH];
		Format(szPath, PLATFORM_MAX_PATH, "sound/%s", szFile);

		AddFileToDownloadsTable(szPath);
	}
}

LoadOverlay(const String:szFile[])
{
	if (szFile[0] != '\0')
	{
		decl String:szPath[PLATFORM_MAX_PATH];

		for (new i = 0; i < sizeof(g_szMaterialExtensions); i++)
		{
			Format(szPath, PLATFORM_MAX_PATH, "materials/%s.%s", szFile, g_szMaterialExtensions[i]);

			AddFileToDownloadsTable(szPath);
		}
	}
}

LoadConfig()
{
	decl String:szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, PLATFORM_MAX_PATH, "configs/hidenseek.cfg");

	if (FileExists(szPath))
	{
		new Handle:hKv = CreateKeyValues("hidenseek");

		FileToKeyValues(hKv, szPath);

		if (KvJumpToKey(hKv, "sounds"))
		{
			KvGetString(hKv, "game_win",   g_szGameSound_Win,   PLATFORM_MAX_PATH);
			KvGetString(hKv, "game_end",   g_szGameSound_End,   PLATFORM_MAX_PATH);
			KvGetString(hKv, "game_start", g_szGameSound_Start, PLATFORM_MAX_PATH);

			LoadSound(g_szGameSound_Win);
			LoadSound(g_szGameSound_End);
			LoadSound(g_szGameSound_Start);
		}

		KvRewind(hKv);

		if (KvJumpToKey(hKv, "overlays"))
		{
			KvGetString(hKv, "overlay_hiderswin",  g_szOverlay_HidersWin,  PLATFORM_MAX_PATH);
			KvGetString(hKv, "overlay_seekerswin", g_szOverlay_SeekersWin, PLATFORM_MAX_PATH);

			LoadOverlay(g_szOverlay_HidersWin);
			LoadOverlay(g_szOverlay_SeekersWin);
		}

		CloseHandle(hKv);
	}
	else
	{
		LogError("Error: Unable to open file: %s", szPath);
	}
}

LoadModelsConfig()
{
	decl String:szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, PLATFORM_MAX_PATH, "configs/hidenseek_models.cfg");

	if (FileExists(szPath))
	{
		new Handle:hKv = CreateKeyValues("hidenseek_models");

		FileToKeyValues(hKv, szPath);

		if (g_hModelMenu != INVALID_HANDLE)
		{
			CloseHandle(g_hModelMenu);
			g_hModelMenu = INVALID_HANDLE;
		}
		g_hModelMenu = CreateMenu(MenuHandler_ChooseModel);
		SetMenuTitle(g_hModelMenu, "Choose your model:");

		if (KvGotoFirstSubKey(hKv))
		{
			decl String:szBuffer[PLATFORM_MAX_PATH];

			while (KvGotoNextKey(hKv))
			{
				decl String:number[4];
				IntToString(g_iNumModels, number, sizeof(number));
				KvGetSectionName(hKv, g_szModelPrintName[g_iNumModels], PLATFORM_MAX_PATH);
				KvGetString(hKv, "filename", g_szModelFileName[g_iNumModels], PLATFORM_MAX_PATH);
				AddMenuItem(g_hModelMenu, number, g_szModelPrintName[g_iNumModels]);

				for (new i = 0; i < sizeof(g_szModelExtensions); i++)
				{
					Format(szBuffer, sizeof(szBuffer), "%s.%s", g_szModelFileName[g_iNumModels], g_szModelExtensions[i]);

					if (i == EXTENSION_MDL)
					{
						g_iModelIndex[g_iNumModels] = PrecacheModel(szBuffer, true);
					}

					AddFileToDownloadsTable(szBuffer);
				}

				KvGetString(hKv, "materials", szBuffer, PLATFORM_MAX_PATH);

				if (szBuffer[0] != '\0')
				{
					decl String:szExpBuffer[MAX_MATERIALS][PLATFORM_MAX_PATH];

					new iNumExplodes = ExplodeString(szBuffer, "|", szExpBuffer, MAX_MATERIALS, PLATFORM_MAX_PATH);

					if (iNumExplodes >= 1)
					{
						for (new i = 0; i < iNumExplodes; i++)
						{
							AddFileToDownloadsTable(szExpBuffer[i]);
						}
					}
				}

				if (g_iNumModels++ >= MAX_MODELS)
				{
					LogError("Warning: Maximum amount of models reached! (Max: %i)", MAX_MODELS);

					break;
				}
			}
		}
	}
	else
	{
		LogError("Error: Unable to open file: %s", szPath);
	}
}

			/*
			for (new i = 0; i < MAX_MODELS; i++)
			{
				Format(szBuffer, sizeof(szBuffer), "%i", i);

				if (KvJumpToKey(hKv, szBuffer))
				{
					PrintToServer("JMP KV %s", szBuffer);

					g_iNumModels = i;

					KvGetString(hKv, "printname", g_szModelPrintName[i], PLATFORM_MAX_PATH);
					KvGetString(hKv, "filename",  g_szModelFileName[i],  PLATFORM_MAX_PATH);

					PrintToServer("PRINTNAME: %s", g_szModelPrintName[i]);
					PrintToServer("FILENAME: %s",  g_szModelFileName[i]);

					Format(szBuffer, sizeof(szBuffer), "%s.mdl", g_szModelFileName[i]);

					PrintToServer("PRECACHE: %s", szBuffer);

					g_iModelIndex[i] = PrecacheModel(szBuffer, true);

					for (new x = 0; x < sizeof(g_szModelExtensions); x++)
					{
						Format(szBuffer, sizeof(szBuffer), "models/%s.%s", g_szModelFileName[x], g_szModelExtensions[x]);

						PrintToServer("ADD TO DL-TABLE: %s", szBuffer);

						AddFileToDownloadsTable(szBuffer);
					}

					KvRewind(hKv);
				}
			}*/
